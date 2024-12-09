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
 * @brief Controller class for managing radio station directories.
 */
public class Tuner.DirectoryController : Object {

    private const uint DIRECTORY_LIMIT = 41;

    private DataProvider.API _provider;
    private StarStore _star_store;
    private bool _loaded = false;

    public signal void tags_updated (Set<DataProvider.Tag> tags);

    public string provider_name() { return _provider.name; }

    /**
     * @brief Constructor for DirectoryController.
     *
     * @param store The StationStore to use for managing stations.
     */
    public DirectoryController (DataProvider.API provider, StarStore star_store) {  
        Object();
        _provider = provider;
        _star_store = star_store;
    } // DirectoryController

        
    /**
     * @brief Loads 
     *
     */
    public void load()
    {
        if (_loaded || app().is_offline ) return;

        _provider.initialize();
        _star_store.load.begin();
        _loaded = true;
    } // load


    /**
     * @brief Get a collection of Station station by its UUID.
     *
     * @param uuid The UUID of the station to load.
     * @return A StationSet object for the requested station.
     * @todo radio-browser should handle multiple UUID on a query, but is broken
     */
     public Set<Model.Station>? get_stations_by_uuid (Collection<string> uuids) {
        try {
            return _provider.by_uuids(uuids);
        } catch (Tuner.DataProvider.DataError e) {
            critical (@"$(_provider.name) unavailable");
        }
        return new HashSet<Model.Station>();
    } // get_stations_by_uuid

    
    /**
     * @brief Load a station by its UUID.
     *
     * @param uuid The UUID of the station to load.
     * @return A StationSet object for the requested station.
     */
    public StationSet load_station_uuid (string uuid) {
        warning(@"LBU UUID: $uuid ");
        var params = DataProvider.SearchParams() {
            uuids = new HashSet<string>()
        };
        params.uuids.add (uuid);
        var source = new StationSet(1, params, _provider, _star_store);
        return source;
    } // load_station_uuid


    /**
     * @brief Load a set of random stations.
     *
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with random stations.
     */
    public StationSet load_random_stations (uint limit) {
        var params = DataProvider.SearchParams() {
            text  = "",
            countrycode = "",
            tags  = new HashSet<string>(),
            order = DataProvider.SortOrder.RANDOM
        };
        var source = new StationSet(limit, params, _provider, _star_store);
        return source;
    } // load_random_stations


    /**
     * @brief Load trending stations.
     *
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with trending stations.
     */
    public StationSet load_trending_stations (uint limit) {
        var params = DataProvider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = new HashSet<string>(),
            order   = DataProvider.SortOrder.CLICKTREND,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _star_store);
        return source;
    }


    /**
     * @brief Load popular stations.
     *
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with popular stations.
     */
    public StationSet load_popular_stations (uint limit) {
        var params = DataProvider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = new HashSet<string>(),
            order   = DataProvider.SortOrder.CLICKCOUNT,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _star_store);
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
        var params = DataProvider.SearchParams () {
            text        = "",
            countrycode = countrycode,
            tags  = new HashSet<string>(),
            order   = DataProvider.SortOrder.CLICKCOUNT,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _star_store);
        return source;
    }


    /**
     * @brief Load stations based on search text.
     *
     * @param utext The search text to filter stations.
     * @param limit The maximum number of stations to load.
     * @return A StationSet object with stations matching the search text.
     */
    public StationSet load_search_stations (string utext, uint limit) {
        var params = DataProvider.SearchParams() {
            text    = utext,
            countrycode = "",
            tags    = new HashSet<string>(),
            order   = DataProvider.SortOrder.CLICKCOUNT,
            reverse = true
        };
        var source = new StationSet(limit, params, _provider, _star_store); 
        return source;
    }


    /**
     * @brief Get all starred stations.
     *
     * @return An Collection of starred Model.Station objects.
     */
    public Collection<Model.Station> get_starred () {
        return _star_store.get_all_stations();
    }


    // --------------------------------------------------

    public StationSet add_saved_search( string search_text)
    {
        _star_store.add_saved_search ( search_text);
        return load_search_stations(search_text,DIRECTORY_LIMIT);
    }

    public void remove_saved_search( string search_text)
    {
        _star_store.remove_saved_search ( search_text);
    }


    public Map<string, StationSet> load_saved_searches()
    {
        Map<string, StationSet> searches = new HashMap<string, StationSet>();
        foreach( var search in _star_store.get_all_searches ())
        {
            searches.set (search, load_search_stations(search,DIRECTORY_LIMIT));
        }
        return searches;
    }


    // -------------------------------------------------

    /**
     * @brief Load stations by tags.
     *
     * @param utags An ArrayList of tags to filter stations.
     * @return A StationSet object with stations matching the given tags.
     */
    public StationSet load_by_tag (string utag) {
        var t =new HashSet<string>();
        t.add (utag.down());
        var params = DataProvider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = t,
            order   = DataProvider.SortOrder.VOTES,
            reverse = true
        };
        var source = new StationSet(40, params, _provider, _star_store);
        return source;
    }


    public StationSet load_by_tag_set (Set<string> utags) {
        var params = DataProvider.SearchParams() {
            text    = "",
            countrycode = "",
            tags    = utags,
            order   = DataProvider.SortOrder.VOTES,
            reverse = true
        };
        var source = new StationSet(40, params, _provider, _star_store);
        return source;
    }


    /**
     * @brief Count a click for a station.
     *
     * @param station The station that was clicked.
     */
    public void count_station_click (Model.Station station) {
            if (!app().settings.do_not_track) {
            debug (@"Send listening event for station $(station.stationuuid)");
            _provider.click (station.stationuuid);
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
        } catch (DataProvider.DataError e) {
            warning (@"Load tags failed with error: $(e.message)");
        }
    } // load_tags

    
    public Set<DataProvider.Tag> load_random_genres(int genres)
    {
        Set<DataProvider.Tag> result = new HashSet<DataProvider.Tag>();

        while (app().is_online && result.size < genres)
        {
            try {
                var offset = Random.int_range(0, _provider.available_tags());
                var tag = _provider.get_tags (offset,1); // Get a random tag
                result.add_all (tag);
            } catch ( Error e) {}
        }
        return result;
    }
} // DirectoryController


/**
 * @brief A pagable set of Stations
 */
public class Tuner.StationSet : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private bool _more = true;
    private DataProvider.SearchParams _params;
    private DataProvider.API _provider;
    private StarStore _star_store;

    /**
     * @brief Constructor for StationSet.
     *
     * @param limit The maximum number of stations to fetch.
     * @param params The search parameters for fetching stations.
     * @param client The RadioBrowser client to use for fetching stations.
     * @param star_store The StationStore to use for managing stations.
     */
    public StationSet (uint limit, 
                        DataProvider.SearchParams params, 
                        DataProvider.API client,
                        StarStore star_store) {
        Object ();
        // This disables paging for now
        _page_size = limit;
        _params = params;
        _provider = client;
        _star_store = star_store;
    }


    /**
     * @brief Fetch the next set of stations.
     *
     * @return An ArrayList of Model.Station objects.
     * @throws SourceError If the source is unavailable.
     */
    public Set<Model.Station>? next_page () throws SourceError {
        
        if ( app().is_offline) return null;

        // Fetch one more to determine if source has more items than page size 
        try {
            var raw_stations = _provider.search (_params, _page_size + 1, _offset);
            // TODO Place filter here?
            // var filtered_stations = raw_stations.filter (filterByCountry);
            var filtered_stations = raw_stations.iterator ();

            var stations = convert_stations (filtered_stations);
            _offset += _page_size;
            _more = stations.size > _page_size;
            if (_more) stations.remove(stations.to_array ()[(int)_page_size]);
            return stations;    
        } catch (DataProvider.DataError e) {
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
    private Set<Model.Station> convert_stations (Iterator<Model.Station> raw_stations) {
        var stations = new HashSet<Model.Station> ();
        
        while (raw_stations.next()) {
        // foreach (var station in raw_stations) {

            var station = raw_stations.get ();

            station.notify["starred"].connect ( (sender, property) => {
                if (station.starred) {
                    _star_store.add_station (station);
                } else {
                    _star_store.remove_station (station);
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
