/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */



using Gee;

/**
 * @namespace Tuner.RadioBrowser
 * @brief Interface to radio-browser.info API and servers
 */
namespace Tuner.RadioBrowser {

    /**
     * @class Station
     * @brief Station data subset returned from radio-browser API
     */
    public class Station : Object {
        public string stationuuid { get; set; }
        public string name { get; set; }
        public string url_resolved { get; set; }
        public string country { get; set; }
        public string countrycode { get; set; }
        public string favicon { get; set; }
        public uint clickcount { get; set; }
        public string homepage { get; set; }
        public string codec { get; set; }
        public int bitrate { get; set; }
    }

    /**
     * @struct SearchParams
     * @brief Parameters for searching radio stations
     */
    public struct SearchParams {
        string text;
        ArrayList<string> tags;
        ArrayList<string> uuids;
        string countrycode;
        SortOrder order;
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


    // TODO: Fetch list of servers via DNS query of SRV record for _api._tcp.radio-browser.info
    private const string[] DEFAULT_STATION_SERVERS = {
        "de1.api.radio-browser.info",
    };



    /**
     * @class Tag
     * @brief Represents a tag associated with radio stations
     */
    public class Tag : Object {
        public string name { get; set; }
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
     * @brief Random sort function for strings
     * @param a First string to compare
     * @param b Second string to compare
     * @return Random integer between -1 and 1
     */
    public int RandomSortFunc (string a, string b) {
        return Random.int_range (-1, 1);
    }

    /**
     * @class Client
     * @brief RadioBrowser API Client
     */
    public class Client : Object {
        private string current_server;
        private ArrayList<string> randomized_servers;


        ~Client()  {
            debug ("RadioBrowser Client - Destruct");
        }


        /**
         * @brief Constructor for RadioBrowser Client
         * @throw DataError if unable to initialize the client
         */
        public Client() throws DataError {
            Object();

            string[] servers;
            string _servers = GLib.Environment.get_variable ("TUNER_API");
            if ( _servers != null ){
                servers = _servers.split(":");
            } else {
                servers = DEFAULT_STATION_SERVERS;
            }

            randomized_servers = new ArrayList<string>.wrap (servers, EqualCompareString);
            randomized_servers.sort (RandomSortFunc);

            current_server = @"https://$(randomized_servers[0])";
            debug (@"RadioBrowser Client - Chosen radio-browser.info server: $current_server");
            // TODO: Implement server rotation on error
        }


        /**
         * @brief Track a station listen event
         * @param stationuuid UUID of the station being listened to
         */
        public void track (string stationuuid) {
            debug (@"sending listening event for station $stationuuid");
            uint status_code;
            //var resource = @"json/url/$stationuuid";
            //var message = new Soup.Message ("GET", @"$current_server/$resource");
            try {
                //var resp = _session.send (message);
                HttpClient.GET (@"$current_server/json/url/$stationuuid", out status_code);
               // resp.close ();
            } catch(GLib.Error e) {
                debug ("failed to track()");
            }
            debug (@"response: $(status_code)");
        }


        /**
         * @brief Vote for a station
         * @param stationuuid UUID of the station being voted for
         */
        public void vote (string stationuuid) {
            debug (@"sending vote event for station $stationuuid");
            uint status_code;

            try {
                HttpClient.GET(@"$current_server/json/vote/$stationuuid", out status_code);

            } catch(GLib.Error e) {
                debug("failed to vote()");
            }
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

    }
}