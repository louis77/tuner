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
 * @brief DataProvider implementation for radio-browser.info API and servers
 *
 * This namespace provides functionality to interact with the radio-browser.info API.
 * It includes features for:
 * - Retrieving radio station metadata JSON
 * - Executing searches and retrieving radio station metadata JSON
 * - Reporting back user interactions (voting, listen tracking)
 * - Tag and other metadata retrieval
 * - API Server discovery and connection handling from DNS and from round-robin API server
 */
namespace Tuner.DataProvider {

    private const string SRV_SERVICE    = "api";
    private const string SRV_PROTOCOL   = "tcp";
    private const string SRV_DOMAIN     = "radio-browser.info";

    private const string RBI_ALL_API    = "all.api.radio-browser.info";    // Round-robin API address
    private const string RBI_STATS      = "/json/stats";
    private const string RBI_SERVERS    = "/json/servers";

    // RB Queries
    private const string RBI_STATION    = "/json/url/$stationuuid";
    private const string RBI_SEARCH     = "/json/stations/search";
    private const string RBI_VOTE       = "/json/vote/$stationuuid";
    private const string RBI_UUID       = "/json/stations/byuuid";
    private const string RBI_URL        = "/json/stations/byurl";
    private const string RBI_TAGS       = "/json/tags";
    


    /**
     * A data provider implementation for the Radio Browser API.
     * 
     * RadioBrowser class implements the DataProvider.API interface to fetch
     * radio station data from the Radio Browser service.
     * 
     * See https://www.radio-browser.info/ for API details.
     */
    public class RadioBrowser : Object, DataProvider.API 
    {
        private const int DEGRADE_CAPITAL = 100;
        private const int DEGRADE_COST = 7;

        private string? _optionalservers;
        private ArrayList<string> _servers;
        private string _current_server;
        private int _degrade = DEGRADE_CAPITAL;
        private int _available_tags = 1000;     // default guess


        public string name()
        {
            return @"RadioBrowser 2.0\n\nServer: $_current_server"; 
        } 


        public Status status { get; protected set; }

        public DataError? last_data_error { get; set; }

		public int available_tags()
		{
			return _available_tags;
		}


        /**
        * @brief Constructor for RadioBrowser Client
        *
        * @throw DataError if unable to initialize the client
        */
		public RadioBrowser(string? optionalservers )
		{
			Object( );
			_optionalservers = optionalservers;
			status           = NOT_AVAILABLE;
		}         // RadioBrowser


        /**
         * @brief Builds a Glib Uri from path and query
         *
         * Uses Glib Uri Parse with encoding to correctly check and encode the query
         *
         * @return the Uri if successful
         */
        private Uri? build_uri(string path, string query = "")
        {          
            debug(@"http://$_current_server$path?$query");
            try {
                if (query == "") 
                { 
                    return Uri.parse(@"http://$_current_server$path",UriFlags.ENCODED);
                }
                else
                {
                    return Uri.parse(@"http://$_current_server$path?$query",UriFlags.ENCODED);
                }
            } catch (UriError e)
            {
                warning(@"Server: $_current_server  Path: $path  Query: $query  Error: $(e.message)");
            }
            return null;
        } // build_uri


        /**
         * @brief Initialize the DataProvider implementation
         *
         * @return true if initialization successful
        */
        public bool initialize()
        {
            if ( app().is_offline ) return false;
            
            if (_optionalservers != null) 
            // Run time server parameter was passed in
            {
                _servers = new Gee.ArrayList<string>.wrap(_optionalservers.split(":"));
            } else 
            // Identify servers from DNS or API
            {
                try {
                    _servers = get_srv_api_servers();
                } catch (DataError e) {
                    last_data_error = new DataError.NO_CONNECTION(@"Failed to retrieve API servers: $(e.message)");
                    status = NO_SERVER_LIST;
                    return false;
                }
            }

			if (_servers.size == 0)
			{
				last_data_error = new DataError.NO_CONNECTION("Unable to resolve API servers for radio-browser.info");
				status          = NO_SERVERS_PRESENTED;
				return false;
			}

            choose_server();
            status = OK;
            clear_last_error();
            stats();
            return true;
        } // initialize


        /**
         * @brief Track a station listen event
         *
         * @param stationuuid UUID of the station being listened to
         */
        public void click(string stationuuid) {
            debug(@"sending listening event for station $(stationuuid)");
            uint status_code;
            HttpClient.GET(build_uri(RBI_STATION, stationuuid), out status_code);
            debug(@"response: $(status_code)");
        } // track


        /**
         * @brief Vote for a station
         * @param stationuuid UUID of the station being voted for
         */
        public void vote(string stationuuid) {
            debug(@"sending vote event for station $(stationuuid)");
            uint status_code;
            //var uri = Uri.build(NONE, "http", null, _current_server, -1, RBI_VOTE, stationuuid, null);
            HttpClient.GET(build_uri(RBI_VOTE, stationuuid), out status_code);            
            //HttpClient.GET(@"$(_current_server)/$(RBI_VOTE)/$(stationuuid)", Priority.HIGH, out status_code);
            //  HttpClient.GETasync(@"$(_current_server)/$(RBI_VOTE)/$(stationuuid)", out status_code);
            debug(@"response: $(status_code)");
        } // vote


        /**
         * @brief Get all available tags
         *
         * @return ArrayList of Tag objects
         * @throw DataError if unable to retrieve or parse tag data
         */
         public Set<Tag> get_tags(int offset, int limit) throws DataError {
            Json.Node rootnode;
            try {
                uint status_code;
                var query = "";
                if (offset > 0) query = @"offset=$offset";
                if (limit > 0) query = @"$query&limit=$limit";

				var uri    = build_uri(RBI_TAGS, query);
				var stream = HttpClient.GET(uri, out status_code);

                if ( status_code != 0 && stream != null)
                {
                    try {
                        var parser =  new Json.Parser();
                        parser.load_from_stream(stream);
                        rootnode = parser.get_root();
                    } catch (Error e) {
                        throw new DataError.PARSE_DATA(@"unable to parse JSON response: $(e.message)");
                    }
                    var rootarray = rootnode.get_array();
                    var tags = jarray_to_tags(rootarray);
                    return tags;
                }
            } catch (GLib.Error e) {
                debug("cannot get_tags()");
            }
            return new HashSet<Tag>();
        } // get_tags


        /**
         * @brief Get a station or stations by UUID
         *
         * @param uuids comma seperated lists of the stations to retrieve
         * @return Station object if found, null otherwise
         * @throw DataError if unable to retrieve or parse station data
         */
         public Set<Model.Station> by_uuid(string uuid) throws DataError {
            if ( app().is_offline || safestrip(uuid).length == 0 ) return new HashSet<Model.Station>();
            var result = station_query(RBI_UUID,@"uuids=$uuid");
            return result;
        } // by_uuid


        /**
         * @brief Get a station or stations by UUIDs
         *
         * @param a collection of uuids of the stations to retrieve
         * @return Station object if found, null otherwise
         * @throw DataError if unable to retrieve or parse station data
         */
        public Set<Model.Station> by_uuids(Collection<string> uuids) throws DataError {
            StringBuilder sb = new StringBuilder();
            foreach ( var uuid in uuids) { sb.append(uuid).append(","); }
            return by_uuid(sb.str);
        } // by_uuid


        /**
            Not implemented
        */
        public Set<Model.Station> by_url(string url) throws DataError {
            if ( app().is_offline || safestrip(url).length == 0 ) return new HashSet<Model.Station>();
            var result = station_query(RBI_URL,@"$url");
            return result;
        } // by_url


        /**
        * @brief Search for stations based on given parameters
        *
        * @param params Search parameters
        * @param rowcount Maximum number of results to return
        * @param offset Offset for pagination
        * @return ArrayList of Station objects matching the search criteria
        * @throw DataError if unable to retrieve or parse station data
        */
		public Set<Model.Station> search(SearchParams params, uint rowcount, uint offset = 0) throws DataError
		{
			// by uuids
			if (params.uuids != null)
			{
				return by_uuids(params.uuids);
			}

            // OR

			// by text or tags
			var query = get_search_query_params(params,rowcount, offset);

			debug(@"Search: $(query)");
			return station_query(RBI_SEARCH, query);
		}         // search


        /**
        * @brief Search for stations based on given parameters
        *
        * @param params Search parameters
        * @param rowcount Maximum number of results to return
        * @param offset Offset for pagination
        * @return ArrayList of Station objects matching the search criteria
        * @throw DataError if unable to retrieve or parse station data
        */
		public async Set<Model.Station> search_async(SearchParams params, uint rowcount, uint offset = 0) throws DataError
		{
			// by uuids
			if (params.uuids != null)
			{
				return by_uuids(params.uuids);
			}

			// OR

			// by text or tags
			var query = get_search_query_params(params, rowcount, offset);

            debug(@"Search: $(query)");
            return  yield station_query_async(RBI_SEARCH, query);
        } // search



        /*  ---------------------------------------------------------------
            Private
            ---------------------------------------------------------------*/

        /**
         * @brief Get all available tags
         *
         * @return ArrayList of Tag objects
         * @throw DataError if unable to retrieve or parse tag data
         */
        private void choose_server()
        {
            var random_server = Random.int_range(0, _servers.size);

            for (int a = 0; a < _servers.size; a++)
            /* Randomly start checking servers, break on first good one */
            {
                uint status = 0;
                var server =  (random_server + a) %_servers.size;
                _current_server = _servers[server];
                try {
                    var uri = Uri.parse(@"http://$_current_server/json/stats",UriFlags.NONE);  
                    //status = HttpClient.HEAD(uri);  // RB doesn't support HEAD
                    HttpClient.GET(uri,out status);
                } catch (UriError e)
                {
                    debug(@"Server - bad Uri from $_current_server");
                }
                if ( status == 200 ) break;   // Check the server
            }
            debug(@"RadioBrowser Client - Chosen radio-browser.info server: $_current_server");
        } // choose_server
    

        /**
         * @brief Manages tracking server degradation and new server selection
         *
         * Tracks degraded server responses and at a certain level will choose 
         * a new server if possible 
         */
        private void degrade(bool degraded = true )
        {
            if ( !degraded ) 
            // Track nominal result
            {
                _degrade += ((_degrade > DEGRADE_CAPITAL) ? 0 : 1);
            }
            else
            // Degraded result
            {
                warning(@"RadioBrowser degrading server: $_current_server");
                _degrade =- DEGRADE_COST;
                if ( _degrade < 0 ) 
                // This server degraded to zero
                {
                    choose_server();
                    _degrade = DEGRADE_CAPITAL;
                }
            }
        } // degrade

    
        /**
         * @brief Retrieve server stats
         *
         */
         private void stats() 
         {
            uint status_code;
            Json.Node rootnode;

            var stream = HttpClient.GET(build_uri(RBI_STATS), out status_code);

            if ( status_code != 0 && stream != null)
            {
                try {
                    var parser = new Json.Parser();
                    parser.load_from_stream(stream, null);
                    rootnode = parser.get_root();
                    Json.Object json_object = rootnode.get_object();
                    _available_tags = (int)json_object.get_int_member("tags");

                } catch (Error e) {
                    warning(@"Could not get server stats: $(e.message)");
                }
            }
            debug(@"response: $(status_code) - Tags: $(_available_tags)");
        } // stats

            
        /**
         * @brief Get stations by querying the API
         *
         * @param query the API query
         * @return ArrayList of Station objects
         * @throw DataError if unable to retrieve or parse station data
         */
        private Set<Model.Station> station_query(string path, string query) throws DataError {

            
            debug(@"station_query - $(path) $(query)");

            uint status_code;
            var uri = build_uri(path, query);  
            debug(@"station_query - $(uri.to_string())");
                
            var stream =  HttpClient.GET(uri,  out status_code);                

			if (status_code == 200 && stream != null)
			{
				degrade(false);
				try
				{
					var stations = parse_json_response(stream);
					return stations;
				} catch (Error e)
				{
					debug(@"JSON error \"$(e.message)\" for uri $(uri)");
				}
			}
			else
			{
				warning(@"Response from 'radio-browser.info': $(status_code) for url: $(uri.to_string())");
				degrade();
			}
			return new HashSet<Model.Station>();
		} // station_query


        /**
        * @brief Get stations by querying the API
        *
        * @param query the API query
        * @return ArrayList of Station objects
        * @throw DataError if unable to retrieve or parse station data
        */
		private async Set<Model.Station> station_query_async(string path, string query) throws DataError
		{
			debug(@"station_query - $(path) $(query)");

			uint status_code;
			var  uri = build_uri(path, query);
			debug(@"station_query - $(uri.to_string())");

			var stream =  yield HttpClient.GETasync(uri,  Priority.HIGH_IDLE, out status_code);

			if (status_code == 200 && stream != null)
			{
				degrade(false);
				try
				{
					var stations = parse_json_response(stream);
					return stations;
				} catch (Error e)
				{
					debug(@"JSON error \"$(e.message)\" for uri $(uri)");
				}
			}
			else
			{
				warning(@"Response from 'radio-browser.info': $(status_code) for url: $(uri.to_string())");
				degrade();
			}
			return new HashSet<Model.Station>();
		} // station_query_async



        /**
         * Generates query parameters string for radio-browser API search requests.
         *
         * @param params    SearchParams object containing search criteria
         * @param rowcount  Maximum number of results to return
         * @param offset    Starting position in the result set
         *
         * @return String containing formatted query parameters
         */
        private string get_search_query_params(SearchParams params, uint rowcount, uint offset)
        {
                        // by text or tags
            var query = @"limit=$rowcount&order=$(params.order)&offset=$offset";

            if (params.text != "") {
                query += @"&name=$(encode_text(params.text))";  // Encode text for ampersands etc
            }
            if (params.countrycode.length > 0) {
                query += @"&countrycode=$(params.countrycode)";
            }
            if (params.order != SortOrder.RANDOM) {
                // random and reverse doesn't make sense
                query += @"&reverse=$(params.reverse)";
            }
            // Put tags last
            if (params.tags.size > 0) {
                string tag_list = params.tags.to_array()[0];
                if (params.tags.size > 1) {
                    tag_list = string.joinv(",", params.tags.to_array());
                }
                query += @"&tagExact=false&tagList=$(encode_text(tag_list))"; // Encode text for ampersands etc
            }
            return query;
        } // get_search_query_params


        /**
         * Parses JSON response from Radio Browser API into a set of stations.
         *
         * @param stream The input stream containing JSON data to be parsed
         *
         * @return Set<Model.Station> A set of Station objects parsed from the JSON
         *
         * @throws Error If there is an error parsing the JSON or processing the data
         */
         private Set<Model.Station> parse_json_response(InputStream stream) throws Error
         {
             var parser = new Json.Parser.immutable_new ();
             parser.load_from_stream(stream, null);
             var rootnode = parser.get_root();
             var rootarray = rootnode.get_array();
             return jarray_to_stations(rootarray);
         } // parse_json_response


        /**
        * @brief Marshals JSON array data into an array of Station
        *
        * Not knowing what the produce did, allow null data
        *
        * @param data JSON array containing station data
        * @return ArrayList of Station objects
        */
		private Set<Model.Station> jarray_to_stations(Json.Array data)
		{
			var stations = new HashSet<Model.Station>();

            if ( data != null )
            {
                data.foreach_element((array, index, element) => {
                    Model.Station s = Model.Station.make(element);
                    stations.add(s);
                });
            }
            return stations;
        } // jarray_to_stations


        /**
        * @brief Converts a JSON node to a Tag object
        *
        * @param node JSON node representing a tag
        * @return Tag object
        */
		private Tag jnode_to_tag(Json.Node node)
		{
			return Json.gobject_deserialize(typeof(Tag), node) as Tag;
		} // jnode_to_tag


        /**
        * @brief Marshals JSON tag data into an array of Tag
        *
        * Not knowing what the produce did, allow null data
        *
        * @param data JSON array containing tag data
        * @return ArrayList of Tag objects
        */
		private Set<Tag> jarray_to_tags(Json.Array? data)
		{
			var tags = new HashSet<Tag>();

            if ( data != null )
            {
                data.foreach_element((array, index, element) => {
                    Tag s = jnode_to_tag(element);
                    tags.add(s);
                });
            }

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

            if ( app().is_offline ) return results;

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
                   // Uri uri = Uri.build(GLib.UriFlags flags, string scheme, string? userinfo, string? host, int port, string path, string? query, string? fragment)
                    
                    var stream = HttpClient.GET(build_uri(@"$(RBI_ALL_API)/$(RBI_SERVERS)"), out status_code);

                    debug(@"response from $(RBI_ALL_API)/$(RBI_SERVERS): $(status_code)");

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
        } // get_srv_api_servers


        /**
        * Encodes a text string for use in RadioBrowser API requests.
        *
        * This method ensures that the text is properly encoded for use in URLs
        * by converting special characters into their URL-safe equivalents.
        *
        * @param tag The text string to be encoded
        * @return A URL-encoded string representation of the input text
        */
		private static string encode_text(string tag)
		{

            string output = tag;
            string[,] x = new string[,]
            {    
                {"%","%25"}
                ,{":","%3B"}
                ,{"/","%2F"}
                ,{"#","%23"}
                ,{"?","%3F"}
                ,{"&","%26"}
                ,{"@","%40"}
                ,{"+","%2B"}
                ,{" ","%20"}
            };

            for (int a = 0 ; a < 9; a++)
            {   
                output = output.replace(x[a,0], x[a,1]);
            }
            return output;
        } // encode_tag
    }   // RadioBrowser
}