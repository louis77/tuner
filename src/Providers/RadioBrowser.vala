/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file RadioBrowser.vala
 *
 * @brief Interface to radio-browser.info API and servers
 * 
 */

using Gee;

/**
 * @namespace Tuner.RadioBrowser
 *
 * @brief Interface to radio-browser.info API and servers
 *
 * This namespace provides functionality to interact with the radio-browser.info API.
 * It includes features for:
 * - Retrieving radio station metadata JSON
 * - Executing searches and retrieving radio station metadata JSON
 * - Reporting back user interactions (voting, listen tracking)
 * - Tag and other metadata retrieval
 * - API Server discovery and connection handling from DNS and from round-robin API server
 */
namespace Tuner.Provider {

    private const string SRV_SERVICE    = "api";
    private const string SRV_PROTOCOL   = "tcp";
    private const string SRV_DOMAIN     = "radio-browser.info";

    private const string RBI_ALL_API    = "https://all.api.radio-browser.info";    // Round-robin API address
    private const string RBI_SERVERS    = "json/servers";

    // RB Queries
    private const string RBI_STATION    = "json/url/$stationuuid";
    private const string RBI_SEARCH     = "json/stations/search";
    private const string RBI_VOTE       = "json/vote/$stationuuid";
    private const string RBI_UUID       = "json/stations/byuuid";
    private const string RBI_TAGS       = "json/tags";
    


    /**
     * @class Client
     *
     * @brief Main RadioBrowser API client implementation
     * 
     * Provides methods to interact with the radio-browser.info API, including:
     * - Station search and retrieval
     * - User interaction tracking (votes, listens)
     * - Tag management
     * - Server discovery and connection handling
     *
     * Example usage:
     * @code
     * try {
     *     var client = new Client();
     *     var params = SearchParams() {
     *         text = "jazz",
     *         order = SortOrder.NAME
     *     };
     *     var stations = client.search(params, 10);
     * } catch (DataError e) {
     *     error("Failed to search: %s", e.message);
     * }
     * @endcode
     */
    public class RadioBrowser : Object, Provider.API 
    {

        public Status status { get; set; }

        public DataError? last_data_error { get; set; }


        private string _current_server;

        /**
         * @brief Constructor for RadioBrowser Client
         *
         * @throw DataError if unable to initialize the client
         */
        public RadioBrowser(string? optionalservers ) 
        {
            Object();

            ArrayList<string> servers;
 
            if (optionalservers != null) 
            // Run time server parameter was passed in
            {
                servers = new Gee.ArrayList<string>.wrap(optionalservers.split(":"));
            } else 
            // Identify servers from DNS or API
            {
                try {
                    servers = get_srv_api_servers();
                } catch (DataError e) {
                    last_data_error = new DataError.NO_CONNECTION(@"Failed to retrieve API servers: $(e.message)");
                    status = NO_SERVER_LIST;
                    return;
                }
            }

            if (servers.size == 0) {
                last_data_error = new DataError.NO_CONNECTION("Unable to resolve API servers for radio-browser.info");
                status = NO_SERVERS_PRESENTED;
                return;
            }

            // Randomize API server to use
            // TODO Test server, choose another if necessary
            var chosen_server = Random.int_range(0, servers.size);
            _current_server = @"https://$(servers[chosen_server])";
            warning(@"RadioBrowser Client - Chosen radio-browser.info server: $_current_server");

            status = OK;
            clear_last_error();
        }

        /**
         * @brief Track a station listen event
         *
         * @param stationuuid UUID of the station being listened to
         */
        public void track(string stationuuid) {
            debug(@"sending listening event for station $(stationuuid)");
            uint status_code;
            HttpClient.GET(@"$(_current_server)/$(RBI_STATION)/$(stationuuid)", out status_code);
            debug(@"response: $(status_code)");
        }

        /**
         * @brief Vote for a station
         * @param stationuuid UUID of the station being voted for
         */
        public void vote(string stationuuid) {
            debug(@"sending vote event for station $(stationuuid)");
            uint status_code;
            HttpClient.GET(@"$(_current_server)/$(RBI_VOTE)/$(stationuuid)", out status_code);
            debug(@"response: $(status_code)");
        }



        /**
         * @brief Get all available tags
         *
         * @return ArrayList of Tag objects
         * @throw DataError if unable to retrieve or parse tag data
         */
         public ArrayList<Tag> get_tags() throws DataError {
            Json.Node rootnode;

            try {
                uint status_code;
                var stream = HttpClient.GET(@"$(_current_server)/$(RBI_TAGS)", out status_code);

                debug(@"response from radio-browser.info: $(status_code)");

                try {
                    var parser = new Json.Parser();
                    parser.load_from_stream(stream);
                    rootnode = parser.get_root();
                } catch (Error e) {
                    throw new DataError.PARSE_DATA(@"unable to parse JSON response: $(e.message)");
                }
                var rootarray = rootnode.get_array();
                var tags = jarray_to_tags(rootarray);
                return tags;
            } catch (GLib.Error e) {
                debug("cannot get_tags()");
            }

            return new ArrayList<Tag>();
        }


        /**
         * @brief Get a station by its UUID
         * @param uuid UUID of the station to retrieve
         * @return Station object if found, null otherwise
         * @throw DataError if unable to retrieve or parse station data
         */
         public Model.Station? by_uuid(string uuid) throws DataError {
            var result = station_query(@"$(RBI_UUID)/$(uuid)");
            if (result.size == 0) {
                return null;
            }
            return result[0];
        }


        /**
         * @brief Search for stations based on given parameters
         *
         * @param params Search parameters
         * @param rowcount Maximum number of results to return
         * @param offset Offset for pagination
         * @return ArrayList of Station objects matching the search criteria
         * @throw DataError if unable to retrieve or parse station data
         */
         public ArrayList<Model.Station> search(SearchParams params, uint rowcount, uint offset = 0) throws DataError {
            // by uuids
            if (params.uuids != null) {
                var stations = new ArrayList<Model.Station>();
                foreach (var uuid in params.uuids) {
                    var station = this.by_uuid(uuid);
                    if (station != null) {
                        stations.add(station);
                    }
                }
                return stations;
            }

            // by text or tags
            var resource = @"$(RBI_SEARCH)?limit=$rowcount&order=$(params.order)&offset=$offset";

            debug(@"Search: $(resource)");
            if (params.text != "") {
                resource += @"&name=$(params.text)";
            }

            if (params.tags.size > 0) {
                string tag_list = params.tags[0];
                if (params.tags.size > 1) {
                    tag_list = string.joinv(",", params.tags.to_array());
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

            warning(@"Search: $(resource)");
            return station_query(resource);
        }


        /*  ---------------------------------------------------------------
            Private
            ---------------------------------------------------------------*/

        /**
         * @brief Get stations by querying the API
         *
         * @param query the API query
         * @return ArrayList of Station objects
         * @throw DataError if unable to retrieve or parse station data
         */
        private ArrayList<Model.Station> station_query(string query) throws DataError {
            warning(@"RB $query");

            Json.Node rootnode;

            try {
                uint status_code;

                debug(@"Requesting from 'radio-browser.info' $(_current_server)/$(query)");
                var response = HttpClient.GET(@"$(_current_server)/$(query)", out status_code);
                debug(@"Response from 'radio-browser.info': $(status_code)");

                try {
                    var parser = new Json.Parser();
                    parser.load_from_stream(response, null);
                    rootnode = parser.get_root();
                } catch (Error e) {
                    throw new DataError.PARSE_DATA(@"Unable to parse JSON response: $(e.message)");
                }
                var rootarray = rootnode.get_array();
                var stations = jarray_to_stations(rootarray);
                return stations;
            } catch (Error e) {
                warning(@"Error retrieving stations 1: $(e.message)");
            }

            warning(@"Error retrieving stations 2");
            return new ArrayList<Model.Station>();
        }


        /**
         * @brief Marshals JSON array data into an array of Station
         *
         * @param data JSON array containing station data
         * @return ArrayList of Station objects
         */
        private ArrayList<Model.Station> jarray_to_stations(Json.Array data) {
            var stations = new ArrayList<Model.Station>();

            data.foreach_element((array, index, element) => {
                Model.Station s = Model.Station.make(element);
                stations.add(s);
            });

            return stations;
        } // jarray_to_stations

        /**
         * @brief Converts a JSON node to a Tag object
         *
         * @param node JSON node representing a tag
         * @return Tag object
         */
        private Tag jnode_to_tag(Json.Node node) {
            return Json.gobject_deserialize(typeof(Tag), node) as Tag;
        } // jnode_to_tag

        /**
         * @brief Marshals JSON tag data into an array of Tag
         *
         * @param data JSON array containing tag data
         * @return ArrayList of Tag objects
         */
        private ArrayList<Tag> jarray_to_tags(Json.Array data) {
            var tags = new ArrayList<Tag>();

            data.foreach_element((array, index, element) => {
                Tag s = jnode_to_tag(element);
                tags.add(s);
            });

            return tags;
        }   // jarray_to_tags


        /**
         * @brief Get all radio-browser.info API servers
         * 
         * Gets server list from Radio Browser DNS SRV record, 
         * and failing that, from the API
         *
         * @since 1.5.4
         * @return ArrayList of strings containing the resolved hostnames
         * @throw DataError if unable to resolve DNS records
         */
        private ArrayList<string> get_srv_api_servers() throws DataError 
        {
            var results = new ArrayList<string>();

            try {
                /*
                    DNS SRV record lookup 
                */
                var srv_targets = GLib.Resolver.get_default().lookup_service(SRV_SERVICE, SRV_PROTOCOL, SRV_DOMAIN, null);
                foreach (var target in srv_targets) {
                    results.add(target.get_hostname());
                }
            } catch (GLib.Error e) {
                @warning(@"Unable to resolve Radio-Browser SRV records: $(e.message)");
            }

            if (results.is_empty) {
                /*
                    JSON API server lookup as SRV record lookup failed
                    Get the servers from the API itself from a round-robin server
                */
                try {
                    uint status_code;
                    var stream = HttpClient.GET(@"$(RBI_ALL_API)/$(RBI_SERVERS)", out status_code);

                    warning(@"response from $(RBI_ALL_API)/$(RBI_SERVERS): $(status_code)");

                    if (status_code == 200) {
                        Json.Node root_node;

                        try {
                            var parser = new Json.Parser();
                            parser.load_from_stream(stream);
                            root_node = parser.get_root();
                        } catch (Error e) {
                            throw new DataError.PARSE_DATA(@"RBI API get servers - unable to parse JSON response: $(e.message)");
                        }

                        if (root_node != null && root_node.get_node_type() == Json.NodeType.ARRAY) {
                            root_node.get_array().foreach_element((array, index_, element_node) => {
                                var object = element_node.get_object();
                                if (object != null) {
                                    var name = object.get_string_member("name");
                                    if (name != null && !results.contains(name)) {
                                        results.add(name);
                                    }
                                }
                            });
                        }
                    }
                } catch (Error e) {
                    warning("Failed to parse RBI APIs JSON response: $(e.message)");
                }
            }

            debug(@"Results $(results.size)");
            return results;
        }
    }   // get_srv_api_servers
}