/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */


using Gee;

/**
 * @namespace Tuner.RadioBrowser
 * @brief Interface to radio-browser.info API and servers
 *
 * This namespace provides functionality to interact with the radio-browser.info API,
 * including searching for stations, retrieving station information, and managing user actions
 * such as voting and tracking listens.
 */
namespace Tuner.RadioBrowser {

    private const string SRV_SERVICE = "api";
    private const string SRV_PROTOCOL = "tcp";
    private const string SRV_DOMAIN = "radio-browser.info";
    private const string ALL_API = "https://all.api.radio-browser.info";

    /**
     * @class Station
     * @brief Station data subset returned from radio-browser API
     *
     * This class represents a radio station with its properties as returned by the radio-browser API.
     */
    public class Station : Object {
        /** @brief Unique identifier for the station */
        public string stationuuid { get; set; }
        /** @brief Name of the station */
        public string name { get; set; }
        /** @brief Resolved URL of the station's stream */
        public string url_resolved { get; set; }
        /** @brief Country where the station is located */
        public string country { get; set; }
        /** @brief Country code of the station's location */
        public string countrycode { get; set; }
        /** @brief URL of the station's favicon */
        public string favicon { get; set; }
        /** @brief Number of clicks/listens for the station */
        public uint clickcount { get; set; }
        /** @brief URL of the station's homepage */
        public string homepage { get; set; }
        /** @brief Audio codec used by the station */
        public string codec { get; set; }
        /** @brief Bitrate of the station's stream */
        public int bitrate { get; set; }
    }

    /**
     * @struct SearchParams
     * @brief Parameters for searching radio stations
     *
     * This struct defines the parameters used for searching radio stations.
     */
    public struct SearchParams {
        /** @brief Text to search for in station names */
        string text;
        /** @brief List of tags to filter stations */
        ArrayList<string> tags;
        /** @brief List of station UUIDs to retrieve */
        ArrayList<string> uuids;
        /** @brief Country code to filter stations */
        string countrycode;
        /** @brief Sort order for the search results */
        SortOrder order;
        /** @brief Whether to reverse the sort order */
        bool reverse;
    }

    /**
     * @brief Error domain for data-related errors
     */
    public errordomain DataError {
        PARSE_DATA,
        NO_CONNECTION
    }

    /**
     * @enum SortOrder
     * @brief Enumeration of sorting options for station search results
     */
    public enum SortOrder {
        NAME,
        URL,
        HOMEPAGE,
        FAVICON,
        TAGS,
        COUNTRY,
        STATE,
        LANGUAGE,
        VOTES,
        CODEC,
        BITRATE,
        LASTCHECKOK,
        LASTCHECKTIME,
        CLICKTIMESTAMP,
        CLICKCOUNT,
        CLICKTREND,
        RANDOM;

        /**
         * @brief Convert SortOrder enum to string representation
         * @return String representation of the SortOrder
         */
        public string to_string () {
            switch (this) {
                case NAME:
                    return "name";
                case URL:
                    return "url";
                case HOMEPAGE:
                    return "homepage";
                case FAVICON:
                    return "favicon";
                case TAGS:
                    return "tags";
                case COUNTRY:
                    return "country";
                case STATE:
                    return "state";
                case LANGUAGE:
                    return "language";
                case VOTES:
                    return "votes";
                case CODEC:
                    return "codec";
                case BITRATE:
                    return "bitrate";
                case LASTCHECKOK:
                    return "lastcheckok";
                case LASTCHECKTIME:
                    return "lastchecktime";
                case CLICKTIMESTAMP:
                    return "clicktimestamp";
                case CLICKCOUNT:
                    return "clickcount";
                case CLICKTREND:
                    return "clicktrend";
                case RANDOM:
                    return "random";
                default:
                    assert_not_reached ();
            }
        }
    }

    /**
     * @class Tag
     * @brief Represents a tag associated with radio stations
     */
    public class Tag : Object {
        /** @brief Name of the tag */
        public string name { get; set; }
        /** @brief Number of stations associated with this tag */
        public uint stationcount { get; set; }
    }

    /**
     * @brief Compare two strings for equality
     * @param a First string to compare
     * @param b Second string to compare
     * @return True if strings are equal, false otherwise
     */
    public bool EqualCompareString (string a, string b) {
        return a == b;
    }

    /**
     * @class Client
     * @brief RadioBrowser API Client
     *
     * This class provides methods to interact with the RadioBrowser API, including
     * searching for stations, retrieving station information, and managing user actions.
     */
    public class Client : Object {
        private string current_server;

        /**
         * @brief Constructor for RadioBrowser Client
         * @throw DataError if unable to initialize the client
         */
        public Client() throws DataError {
            Object();

            ArrayList<string> servers;
            string _servers = GLib.Environment.get_variable ("TUNER_API");
            if ( _servers != null ){
                servers = new Gee.ArrayList<string>.wrap(_servers.split(":"));
            } else {
                //servers = DEFAULT_STATION_SERVERS;
                servers = get_api_servers();
            }

            if ( servers.size == 0 ) {
                throw new DataError.NO_CONNECTION ("Unable to resolve API servers for radio-browser.info");
            }

            var chosen_server =  Random.int_range(0, servers.size);

            current_server = @"https://$(servers[chosen_server])";
            debug (@"RadioBrowser Client - Chosen radio-browser.info server: $current_server");
        }

        /**
         * @brief Track a station listen event
         * @param stationuuid UUID of the station being listened to
         */
        public void track (string stationuuid) {
            debug (@"sending listening event for station $stationuuid");
            uint status_code;
            HttpClient.GET (@"$current_server/json/url/$stationuuid", out status_code);
            debug (@"response: $(status_code)");
        }

        /**
         * @brief Vote for a station
         * @param stationuuid UUID of the station being voted for
         */
        public void vote (string stationuuid) {
            debug (@"sending vote event for station $stationuuid");
            uint status_code;
            HttpClient.GET(@"$current_server/json/vote/$stationuuid", out status_code);
            debug (@"response: $(status_code)");
        }

        /**
         * @brief Get stations from a specific API resource
         * @param resource API resource path
         * @return ArrayList of Station objects
         * @throw DataError if unable to retrieve or parse station data
         */
        public ArrayList<Station> get_stations (string resource) throws DataError {
            debug (@"RB $resource");

            Json.Node rootnode;

            try {
                uint status_code;
                var response = HttpClient.GET(@"$current_server/$resource", out status_code);

                debug (@"Response from 'radio-browser.info': $(status_code)");

                try {
                    var parser = new Json.Parser();
                    parser.load_from_stream (response, null);
                    rootnode = parser.get_root();
                } catch (Error e) {
                    throw new DataError.PARSE_DATA (@"Unable to parse JSON response: $(e.message)");
                }
                var rootarray = rootnode.get_array ();

                var stations = jarray_to_stations (rootarray);
                return stations;
            } catch (GLib.Error e) {
                warning (@"Unknown error: $(e.message)");
            }

            return new ArrayList<Station>();
        }

        /**
         * @brief Search for stations based on given parameters
         * @param params Search parameters
         * @param rowcount Maximum number of results to return
         * @param offset Offset for pagination
         * @return ArrayList of Station objects matching the search criteria
         * @throw DataError if unable to retrieve or parse station data
         */
        public ArrayList<Station> search (SearchParams params,
                                        uint rowcount,
                                        uint offset = 0) throws DataError {
            // by uuids
            if (params.uuids != null) {
                var stations = new ArrayList<Station> ();
                foreach (var uuid in params.uuids) {
                    var station = this.by_uuid(uuid);
                    if (station != null) {
                        stations.add (station);
                    }
                }
                return stations;
            }

            // by text or tags
            var resource = @"json/stations/search?limit=$rowcount&order=$(params.order)&offset=$offset";
            if (params.text != null && params.text != "") { 
                resource += @"&name=$(params.text)";
            }
            if (params.tags == null) {
                warning ("param tags is null");
            }
            if (params.tags.size > 0 ) {
                string tag_list = params.tags[0];
                if (params.tags.size > 1) {
                    tag_list = string.joinv (",", params.tags.to_array());
                }
                resource += @"&tagList=$tag_list&tagExact=true";
            }
            if (params.countrycode.length > 0) {
                resource += @"&countrycode=$(params.countrycode)";
            }
            if (params.order != SortOrder.RANDOM) {
                // random and reverse doesn't make sense
                resource += @"&reverse=$(params.reverse)";
            }
            return get_stations (resource);
        }

        /**
         * @brief Get a station by its UUID
         * @param uuid UUID of the station to retrieve
         * @return Station object if found, null otherwise
         * @throw DataError if unable to retrieve or parse station data
         */
        public Station? by_uuid (string uuid) throws DataError {
            var resource = @"json/stations/byuuid/$uuid";
            var result = get_stations (resource);
            if (result.size == 0) {
                return null;
            }
            return result[0];
        }

        /**
         * @brief Get all available tags
         * @return ArrayList of Tag objects
         * @throw DataError if unable to retrieve or parse tag data
         */
        public ArrayList<Tag> get_tags () throws DataError {

            Json.Node rootnode;

            try {
                uint status_code;
                var stream = HttpClient.GET(@"$current_server/json/tags", out status_code);

                debug (@"response from radio-browser.info: $(status_code)");
                
                try {
                    var parser = new Json.Parser();
                    parser.load_from_stream (stream);
                    rootnode = parser.get_root ();
                } catch (Error e) {
                    throw new DataError.PARSE_DATA (@"unable to parse JSON response: $(e.message)");
                }
                var rootarray = rootnode.get_array ();

                var tags = jarray_to_tags (rootarray);
                return tags;
            } catch(GLib.Error e) {
                debug("cannot get_tags()");
            }

            return new ArrayList<Tag>();
        }

        /**
         */
        private Station jnode_to_station (Json.Node node) {
            return Json.gobject_deserialize (typeof (Station), node) as Station;
        }

        /**
         */
        private ArrayList<Station> jarray_to_stations (Json.Array data) {
            var stations = new ArrayList<Station> ();

            data.foreach_element ((array, index, element) => {
                Station s = jnode_to_station (element);
                stations.add (s);
            });

            return stations;
        }

        /**
         */
        private Tag jnode_to_tag (Json.Node node) {
            return Json.gobject_deserialize (typeof (Tag), node) as Tag;
        }

        /**
         */
        private ArrayList<Tag> jarray_to_tags (Json.Array data) {
            var tags = new ArrayList<Tag> ();

            data.foreach_element ((array, index, element) => {
                Tag s = jnode_to_tag (element);
                tags.add (s);
            });

            return tags;
        }

        /**
        * @brief Get all radio-browser.info API servers
        *
        * Gets server list from 
        *
        * @since 1.5.4
        * @return ArrayList of strings containing the resolved hostnames
        * @throw DataError if unable to resolve DNS records
        */
        private ArrayList<string> get_api_servers() throws DataError {
        
            var results = new ArrayList<string>();
    
            try             
            /*
                DNS SRV record lookup 
            */
            {
                var srv_targets = GLib.Resolver.get_default().
                lookup_service( SRV_SERVICE, SRV_PROTOCOL, SRV_DOMAIN, null );
                foreach (var target in srv_targets) {
                    results.add(target.get_hostname());
                }
            } catch (GLib.Error e) {
                @warning(@"Unable to resolve SRV records: $(e.message)");
            }
    
            if (results.is_empty) 
            /*
                JSON API server lookup as SRV record lookup failed
            */
            {
    
                try {
                    uint status_code;
                    var stream = HttpClient.GET(@"$ALL_API/json/servers", out status_code);
    
                    debug (@"response from $(ALL_API)/json/servers: $(status_code)");
    
                    if (status_code == 200) {
    
                        Json.Node root_node;
    
                        try {
                            var parser = new Json.Parser();
                            parser.load_from_stream (stream);
                            root_node = parser.get_root ();
                        } catch (Error e) {
                            throw new DataError.PARSE_DATA (@"unable to parse JSON response: $(e.message)");
                        }
        
                        if (root_node != null && root_node.get_node_type() == Json.NodeType.ARRAY) {
                
                            root_node.get_array().foreach_element((array, index_, element_node) => {
                                var object = element_node.get_object();
                                if (object != null) {
                                    var name = object.get_string_member("name");
                                    if (name != null && !results.contains (name)) {
                                        results.add(name);
                                    }
                                }
                            });
            
                        }
                    }
                } catch (Error e) {
                    warning("Failed to parse API ServersJSON: $(e.message)");
                }                
            }
    
            return results;
        }
    }
}