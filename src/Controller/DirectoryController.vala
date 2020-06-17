/*
* Copyright (c) 2020 Louis Brauer (https://github.com/louis77)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Louis Brauer <louis@brauer.family>
*/

using Gee;

// TODO: Provide cache facility for favicons

public class Tuner.DirectoryController : Object {

    private const uint PAGE_SIZE = 10;

    public RadioBrowser.Client provider { get; set; }

    public signal void stations_updated (ContentBox target, ArrayList<Model.StationModel> stations);
    public signal void tags_updated (ArrayList<RadioBrowser.Tag> tags);

    public DirectoryController (RadioBrowser.Client provider) {
        this.provider = provider;
    }

    private ArrayList<Model.StationModel> convert_stations (ArrayList<RadioBrowser.Station> raw_stations) {
        var stations = new ArrayList<Model.StationModel> ();
        foreach (var station in raw_stations) {
            var s = new Model.StationModel (
                station.stationuuid,
                station.name,
                station.country,
                station.url_resolved);
            s.favicon_url = station.favicon;
            s.clickcount = station.clickcount;
            stations.add (s);
        }
        return stations;
    }

    private void augment_with_userinfo (ArrayList<Model.StationModel> stations, bool star_always = false) {
        var settings = Application.instance.settings;
        var starred = settings.get_strv ("starred-stations");

        foreach (Model.StationModel station in stations) {
            foreach (string id in starred) {
                station.starred = star_always || id == station.id;
            }
        }
    }


    public void load_and_update (ContentBox target, ArrayList<RadioBrowser.Station> raw_stations, bool star_always = false) {
        try {
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations, star_always);
            stations_updated (target, stations);
        } catch (RadioBrowser.DataError e) {
            warning ("unable to fetch stations from directory: %s", e.message);
        }
    }

    public StationSource load_random_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search ("", limit, RadioBrowser.SortOrder.RANDOM, false, offset);
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations, false);
            return stations;
        });
        return source;
    }

    public StationSource load_trending_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search (null, limit, RadioBrowser.SortOrder.CLICKTREND, true, offset);
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations, false);
            return stations;
        });
        return source;
    }

    public StationSource load_popular_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search (null, limit, RadioBrowser.SortOrder.CLICKCOUNT, true, offset);
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations, false);
            return stations;
        });
        return source;
    }

    public StationSource load_search_stations (string utext, uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var l2text = "info";
            var raw_stations = provider.search (utext, limit, RadioBrowser.SortOrder.CLICKCOUNT, true, offset);
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations, false);
            return stations;
        });
        return source;
    }

    public StationSource load_favourite_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            // TODO Implement offset
            var settings = Application.instance.settings;
            var starred_stations = settings.get_strv ("starred-stations");
            var raw_stations = new ArrayList<RadioBrowser.Station> ();

            debug (@"Number of favourite stations: $(starred_stations.length)");

            foreach (var s in starred_stations) {
                var result = provider.by_uuid (s);
                if (result.size == 1) {
                    raw_stations.add (result[0]);
                }
            }
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations, true);
            return stations;
        });
        return source;
    }

    public void star_station (Model.StationModel station, bool starred) {
        var settings = Application.instance.settings;
        var starred_stations = settings.get_strv ("starred-stations");

        if (starred) {
            starred_stations += station.id;
            settings.set_strv ("starred-stations", starred_stations);
            station.starred = true;
            provider.vote (station.id);
        } else {
            string[] new_starred = {};
            foreach (string id in starred_stations) {
                if (id != station.id) {
                    new_starred += id;
                }
            }
            settings.set_strv ("starred-stations", new_starred);
            station.starred = false;
        }
    }

    public void count_station_click (Model.StationModel station) {
        provider.track (station.id);
    }

    public void load_tags () {
        var tags = provider.get_tags ();
        tags_updated (tags);
    }

}

public class Tuner.StationSource : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private uint _page = 0;
    private bool _more = true;
    public signal ArrayList<Model.StationModel> fetch(uint offset, uint limit);

    public StationSource (uint limit) {
        Object ();
        // This disables paging for now
        _page_size = limit;
    }

    public ArrayList<Model.StationModel>? next () {
        // Fetch one more to determine if source has more items than page size
        var stations = fetch (_offset, _page_size + 1);
        _offset += _page_size;
        _more = stations.size > _page_size;
        if (_more) stations.remove_at( (int)_page_size);
        return stations;
    }

    public bool has_more () {
        return _more;
    }
}