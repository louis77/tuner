/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

/**
 * @brief Error domain for source-related errors.
 */
public errordomain SourceError {
    UNAVAILABLE
}

namespace Tuner {
    /**
    * @brief Delegate type for fetching radio stations.
    * @param offset The starting index for fetching stations.
    * @param limit The maximum number of stations to fetch.
    * @return An ArrayList of RadioBrowser.Station objects.
    * @throws SourceError If the source is unavailable.
    */
    public delegate ArrayList<Model.Station> FetchType(uint offset, uint limit) throws SourceError;

    /**
    * @brief Controller class for managing radio station directories.
    */
    public class DirectoryController : Object {
        public RadioBrowser.Client? provider { get; set; }
        public Model.StarredStationStore starred_stations { get; set; }

        public signal void tags_updated (ArrayList<RadioBrowser.Tag> tags);

        /**
        * @brief Constructor for DirectoryController.
        * @param store The StationStore to use for managing stations.
        */
        public DirectoryController (Model.StarredStationStore store) {
            try {
                var client = new RadioBrowser.Client ();
                this.provider = client;
            } catch (RadioBrowser.DataError e) {
                critical (@"RadioBrowser unavailable");
            }
            
            this.starred_stations = store;

            // migrate from <= 1.2.3 settings to json based store
            //this.migrate_favourites ();
        }

        /**
        * @brief Load a station by its UUID.
        * @param uuid The UUID of the station to load.
        * @return A StationSource object for the requested station.
        */
        public StationSource load_station_uuid (string uuid) {
            string[] lps_arr = { uuid }; 
            var params = RadioBrowser.SearchParams() {
                uuids = new ArrayList<string>.wrap (lps_arr)
            };
            var source = new StationSource(1, params, provider, starred_stations);
            return source;
        }

        /**
        * @brief Load a set of random stations.
        * @param limit The maximum number of stations to load.
        * @return A StationSource object with random stations.
        */
        public StationSource load_random_stations (uint limit) {
            var params = RadioBrowser.SearchParams() {
                text  = "",
                countrycode = "",
                tags  = new ArrayList<string>(),
                order = RadioBrowser.SortOrder.RANDOM
            };
            var source = new StationSource(limit, params, provider, starred_stations);
            return source;
        }

        public StationSource load_trending_stations (uint limit) {
            var params = RadioBrowser.SearchParams() {
                text    = "",
                countrycode = "",
                tags    = new ArrayList<string>(),
                order   = RadioBrowser.SortOrder.CLICKTREND,
                reverse = true
            };
            var source = new StationSource(limit, params, provider, starred_stations);
            return source;
        }

        public StationSource load_popular_stations (uint limit) {
            var params = RadioBrowser.SearchParams() {
                text    = "",
                countrycode = "",
                tags    = new ArrayList<string>(),
                order   = RadioBrowser.SortOrder.CLICKCOUNT,
                reverse = true
            };
            var source = new StationSource(limit, params, provider, starred_stations);
            return source;
        }

        public StationSource load_by_country (uint limit, string countrycode) {
            var params = RadioBrowser.SearchParams () {
                text        = "",
                countrycode = countrycode,
                tags  = new ArrayList<string>(),
                order   = RadioBrowser.SortOrder.CLICKCOUNT,
                reverse = true
            };
            var source = new StationSource(limit, params, provider, starred_stations);
            return source;
        }

        public StationSource load_search_stations (owned string utext, uint limit) {
            var params = RadioBrowser.SearchParams() {
                text    = utext,
                countrycode = "",
                tags    = new ArrayList<string>(),
                order   = RadioBrowser.SortOrder.CLICKCOUNT,
                reverse = true
            };
            var source = new StationSource(limit, params, provider, starred_stations); 
            return source;
        }

        public ArrayList<Model.Station> get_stored () {
            return _starred_stations.get_all ();
        }


        /**
        * @brief Load stations by tags.
        * @param utags An ArrayList of tags to filter stations.
        * @return A StationSource object with stations matching the given tags.
        */
        public StationSource load_by_tags (owned ArrayList<string> utags) {
            var params = RadioBrowser.SearchParams() {
                text    = "",
                countrycode = "",
                tags    = utags,
                order   = RadioBrowser.SortOrder.VOTES,
                reverse = true
            };
            var source = new StationSource(40, params, provider, starred_stations);
            return source;
        }

        /**
        * @brief Count a click for a station.
        * @param station The station that was clicked.
        */
        public void count_station_click (Model.Station station) {
           // if (!Application.instance.settings.get_boolean ("do-not-track")) {
                if (!Application.instance.settings.do_not_track) {
                debug (@"Send listening event for station $(station.stationuuid)");
                provider.track (station.stationuuid);
            } else {
                debug ("do-not-track enabled, will not send listening event");
            }
        }

        /**
        * @brief Load tags from the provider.
        */
        public void load_tags () {
            try {
                var tags = provider.get_tags ();
                tags_updated (tags);
            } catch (RadioBrowser.DataError e) {
                warning (@"Load tags failed with error: $(e.message)");
            }
        }

    }

    /**
    * @brief Source class for managing sets of radio stations.
    */
    public class StationSource : Object {
        private uint _offset = 0;
        private uint _page_size = 20;
        private bool _more = true;
        private RadioBrowser.SearchParams _params;
        private RadioBrowser.Client _client;
        private Model.StarredStationStore _starred_stations;

        /**
        * @brief Constructor for StationSource.
        * @param limit The maximum number of stations to fetch.
        * @param params The search parameters for fetching stations.
        * @param client The RadioBrowser client to use for fetching stations.
        * @param store The StationStore to use for managing stations.
        */
        public StationSource (uint limit, 
                            RadioBrowser.SearchParams params, 
                            RadioBrowser.Client client,
                            Model.StarredStationStore store) {
            Object ();
            // This disables paging for now
            _page_size = limit;
            _params = params;
            _client = client;
            _starred_stations = store;
        }

        /**
        * @brief Fetch the next set of stations.
        * @return An ArrayList of Model.Station objects.
        * @throws SourceError If the source is unavailable.
        */
        public ArrayList<Model.Station>? next () throws SourceError {
            // Fetch one more to determine if source has more items than page size 
            try {
                var raw_stations = _client.search (_params, _page_size + 1, _offset);
                // TODO Place filter here?
                //var filtered_stations = raw_stations.filter (filterByCountry);
                var filtered_stations = raw_stations.iterator ();

                var stations = convert_stations (filtered_stations);
                _offset += _page_size;
                _more = stations.size > _page_size;
                if (_more) stations.remove_at( (int)_page_size);
                return stations;    
            } catch (RadioBrowser.DataError e) {
                throw new SourceError.UNAVAILABLE("Directory Error");
            }
        }

        /**
        * @brief Check if there are more stations to fetch.
        * @return true if there are more stations, false otherwise.
        */
        public bool has_more () {
            return _more;
        }

        /**
        * @brief Convert RadioBrowser.Station objects to Model.Station objects.
        * @param raw_stations An iterator of RadioBrowser.Station objects.
        * @return An ArrayList of converted Model.Station objects.
        */
        private ArrayList<Model.Station> convert_stations (Iterator<Model.Station> raw_stations) {
            var stations = new ArrayList<Model.Station> ();
            
            while (raw_stations.next()) {
            // foreach (var station in raw_stations) {

                var station = raw_stations.get ();

                //  var s = new Model.Station (
                //      station.stationuuid,
                //      station.name,
                //      Model.Countries.get_by_code(station.countrycode, station.country),
                //      station.url_resolved);
                    
                if (_starred_stations.contains (station) && !station.starred) {
                    station.toggle_starred();
                }
                //  s.favicon_url = station.favicon;
                //  s.clickcount = station.clickcount;
                //  s.homepage = station.homepage;
                //  s.codec = station.codec;
                //  s.bitrate = station.bitrate;

                station.notify["starred"].connect ( (sender, property) => {
                    if (station.starred) {
                        _starred_stations.add (station);
                    } else {
                        _starred_stations.remove (station);
                    }
                });
                stations.add (station);
            }
            return stations;
    }
    }
}
