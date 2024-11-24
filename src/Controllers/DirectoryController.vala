/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file DirectoryController.vala
 *
 * @brief Station Directories and their population
 * 
 */

using Gee;

/**
 * @brief Error domain for source-related errors.
 */
public errordomain SourceError {
    UNAVAILABLE
}

/**
 * @brief Delegate type for fetching radio stations.
 *
 * @param offset The starting index for fetching stations.
 * @param limit The maximum number of stations to fetch.
 * @return An ArrayList of RadioBrowser.Station objects.
 * @throws SourceError If the source is unavailable.
 */
public delegate ArrayList<Model.Station> Tuner.FetchType(uint offset, uint limit) throws SourceError;


/**
 * @brief Controller class for managing radio station directories.
 */
public class Tuner.DirectoryController : Object {

    //private RadioBrowser.Client? _provider { get; set; }
    private Provider.API _provider;
    private StarredStationController _starred;
    private bool _loaded = false;

    public signal void tags_updated (ArrayList<Provider.Tag> tags);

    /**
     * @brief Constructor for DirectoryController.
     *
     * @param store The StationStore to use for managing stations.
     */
    public DirectoryController (Provider.API provider, StarredStationController starred) {  
       // try {
            _provider = provider;
            _starred = starred;
        //  } catch (Provider.DataError e) {
        //      critical (@"RadioBrowser unavailable");
        //  }
        _starred.load();        // Load needs to happen after Application creation
        _provider.initialize ();
    } // DirectoryController

    public void load()
    {
        if (_loaded) return;

        _provider.initialize();
        _starred.load();
        _loaded = true;
    } // load

    /**
     * @brief Get a collection of Station station by its UUID.
     *
     * @param uuid The UUID of the station to load.
     * @return A StationSet object for the requested station.
     * @todo radio-browser should handle multiple UUID on a query, but is broken
     */
     public Set<Tuner.Model.Station> get_stations_by_uuid (Collection<string> uuids) {

        Set<Tuner.Model.Station> stations = new HashSet<Tuner.Model.Station>();
        foreach (var uuid in uuids)
        {
            try {
                stations.add (_provider.by_uuid(uuid));
            } catch (Tuner.Provider.DataError e) {
                critical (@"RadioBrowser unavailable");
            }
        }
        return stations;
    } // get_stations_by_uuid

    /**
     * @brief Load a station by its UUID.
     *
     * @param uuid The UUID of the station to load.
     * @return A StationSet object for the requested station.
     */
    public StationSet load_station_uuid (string uuid) {
        string[] lps_arr = { uuid }; 
        var params = Provider.SearchParams() {
            uuids = new ArrayList<string>.wrap (lps_arr)
        };
        var source = new StationSet(1, params, _provider, _starred);
        return source;
    } // load_station_uuid

    /**
     * @brief Load a set of random stations.
     *
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with random stations.
     */
    public StationSet load_random_stations (uint limit) {
        var params = Provider.SearchParams() {
            text  = "",
            countrycode = "",
            tags  = new ArrayList<string>(),
            order = Provider.SortOrder.RANDOM
        };
        var source = new StationSet(limit, params, _provider, _starred);
        return source;
    } // load_random_stations

    /**
     * @brief Load trending stations.
     *
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with trending stations.
     */
    public StationSet load_trending_stations (uint limit) {
        var params = Provider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = new ArrayList<string>(),
            order   = Provider.SortOrder.CLICKTREND,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _starred);
        return source;
    }

    /**
     * @brief Load popular stations.
     *
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with popular stations.
     */
    public StationSet load_popular_stations (uint limit) {
        var params = Provider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = new ArrayList<string>(),
            order   = Provider.SortOrder.CLICKCOUNT,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _starred);
        return source;
    }

    /**
     * @brief Load stations by country code.
     *
     * @param limit The maximum number of stations to load.
     * @param countrycode The country code to filter stations.
     * @return A StationSet object with stations from the specified country.
     */
    public StationSet load_by_country (uint limit, string countrycode) {
        var params = Provider.SearchParams () {
            text        = "",
            countrycode = countrycode,
            tags  = new ArrayList<string>(),
            order   = Provider.SortOrder.CLICKCOUNT,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _starred);
        return source;
    }

    /**
     * @brief Load stations based on search text.
     *
     * @param utext The search text to filter stations.
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with stations matching the search text.
     */
    public StationSet load_search_stations (owned string utext, uint limit) {
        var params = Provider.SearchParams() {
            text    = utext,
            countrycode = "",
            tags    = new ArrayList<string>(),
            order   = Provider.SortOrder.CLICKCOUNT,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _starred); 
        return source;
    }

    /**
     * @brief Get all stored stations.
     *
     * @return An ArrayList of stored Model.Station objects.
     */
    public Collection<Model.Station> get_starred () {
        return _starred.get_all();
    }

    /**
     * @brief Load stations by tags.
     *
     * @param utags An ArrayList of tags to filter stations.
     * @return A StationSet object with stations matching the given tags.
     */
    public StationSet load_by_tags (owned ArrayList<string> utags) {
        var params = Provider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = utags,
            order   = Provider.SortOrder.VOTES,
            reverse = true
        };
        var source = new StationSet(40, params, _provider, _starred);
        return source;
    }

    /**
     * @brief Count a click for a station.
     *
     * @param station The station that was clicked.
     */
    public void count_station_click (Model.Station station) {
        // if (!Application.instance.settings.get_boolean ("do-not-track")) {
            if (!Application.instance.settings.do_not_track) {
            debug (@"Send listening event for station $(station.stationuuid)");
            _provider.track (station.stationuuid);
        } else {
            debug ("do-not-track enabled, will not send listening event");
        }
    }

    /**
     * @brief Load tags from the _provider.
     */
    public void load_tags () {
        try {
            var tags = _provider.get_tags ();
            tags_updated (tags);
        } catch (Provider.DataError e) {
            warning (@"Load tags failed with error: $(e.message)");
        }
    } // load_tags
} // DirectoryController

/**
 * @brief A pagable set of Stations
 */
public class Tuner.StationSet : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private bool _more = true;
    private Provider.SearchParams _params;
    private Provider.API _provider;
    private StarredStationController _starred;

    /**
     * @brief Constructor for StationSet.
     *
     * @param limit The maximum number of stations to fetch.
     * @param params The search parameters for fetching stations.
     * @param client The RadioBrowser client to use for fetching stations.
     * @param starred The StationStore to use for managing stations.
     */
    public StationSet (uint limit, 
                        Provider.SearchParams params, 
                        Provider.API client,
                        StarredStationController starred) {
        Object ();
        // This disables paging for now
        _page_size = limit;
        _params = params;
        _provider = client;
        _starred = starred;
    }

    /**
     * @brief Fetch the next set of stations.
     *
     * @return An ArrayList of Model.Station objects.
     * @throws SourceError If the source is unavailable.
     */
    public ArrayList<Model.Station>? next_page () throws SourceError {
        // Fetch one more to determine if source has more items than page size 
        try {
            var raw_stations = _provider.search (_params, _page_size + 1, _offset);
            // TODO Place filter here?
            // var filtered_stations = raw_stations.filter (filterByCountry);
            var filtered_stations = raw_stations.iterator ();

            var stations = convert_stations (filtered_stations);
            _offset += _page_size;
            _more = stations.size > _page_size;
            if (_more) stations.remove_at( (int)_page_size);
            return stations;    
        } catch (Provider.DataError e) {
            throw new SourceError.UNAVAILABLE("Directory Error");
        }
    }

    /**
     * @brief Check if there are more stations to fetch.
     *
     * @return true if there are more stations, false otherwise.
     */
    public bool has_more () {
        return _more;
    }

    /**
     * @brief Convert RadioBrowser.Station objects to Model.Station objects.
     *
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
                
            //  if (_starred.contains (station) && !station.starred) {
            //      station.toggle_starred();
            //  }

            //  s.favicon_url = station.favicon;
            //  s.clickcount = station.clickcount;
            //  s.homepage = station.homepage;
            //  s.codec = station.codec;
            //  s.bitrate = station.bitrate;

            station.notify["starred"].connect ( (sender, property) => {
                if (station.starred) {
                    _starred.add (station);
                } else {
                    _starred.remove (station);
                }
            });
            stations.add (station);
        }
        return stations;
    } // convert_stations

    public bool has_property(Json.Node node, string property_name) {
        // Check if the node is of type OBJECT
        if (node.get_node_type() == Json.NodeType.OBJECT) {
            Json.Object json_object = node.get_object();
    
            // Check if the JSON object has the specified property
            return json_object.has_member(property_name);
        }
    
        return false; // Not an object, so no properties exist
    } // has_property
} // StationSet
