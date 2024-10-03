/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

/**
    RadioBrowser

    Interface to https://www.radio-browser.info/ API and servers

    Retrieves Station info for display and play, sends user station tagging info back 

*/
namespace Tuner.RadioBrowser {

    /**
        Station data subset returned from radio-browser API
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

    public struct SearchParams {
        string text;
        ArrayList<string> tags;
        ArrayList<string> uuids;
        string countrycode;
        SortOrder order;
        bool reverse;
    }

    public errordomain DataError {
        PARSE_DATA,
        NO_CONNECTION
    }

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



    public class Tag : Object {
        public string name { get; set; }
        public uint stationcount { get; set; }
    }

    public bool EqualCompareString (string a, string b) {
        return a == b;
    }

    public int RandomSortFunc (string a, string b) {
        return Random.int_range (-1, 1);
    }

    /**
        RadioBrowser API Client
    */
    public class Client : Object {
        private string current_server;
        private ArrayList<string> randomized_servers;


        ~Client()  {
            debug ("RadioBrowser Client - Destruct");
        }


        /**
            Constructor
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
            Vote
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
         */
        public ArrayList<Station> get_stations (string resource) throws DataError {
            debug (@"RB $resource");

            Json.Node rootnode;

            try {
                uint status_code;
                var response = HttpClient.GET(@"$current_server/$resource", out status_code);

                warning (@"response from radio-browser.info: $(status_code)");

                try {
                    var parser = new Json.Parser();
                    parser.load_from_stream (response, null);
                    rootnode = parser.get_root();
                } catch (Error e) {
                    throw new DataError.PARSE_DATA (@"unable to parse JSON response: $(e.message)");
                }
                var rootarray = rootnode.get_array ();

                var stations = jarray_to_stations (rootarray);
                return stations;
            } catch (GLib.Error e) {
                warning (@"response from radio-browser.info: $(e.message)");
            }

            return new ArrayList<Station>();
        }


        /**
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

    }
}
