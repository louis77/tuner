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


public class Tuner.DirectoryController : Object {
    public RadioBrowser.Client provider { get; set; }

    public signal void tags_updated (ArrayList<RadioBrowser.Tag> tags);

    public DirectoryController (RadioBrowser.Client provider) {
        this.provider = provider;
    }


    public StationSource load_random_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search ("", {}, limit, RadioBrowser.SortOrder.RANDOM, false, offset);
            return raw_stations;
        });
        return source;
    }

    public StationSource load_trending_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search ("", {}, limit, RadioBrowser.SortOrder.CLICKTREND, true, offset);
            return raw_stations;
        });
        return source;
    }

    public StationSource load_popular_stations (uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search ("", {}, limit, RadioBrowser.SortOrder.CLICKCOUNT, true, offset);
            return raw_stations;
        });
        return source;
    }

    public StationSource load_search_stations (string utext, uint limit) {
        var source = new StationSource(limit);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search (utext, {}, limit, RadioBrowser.SortOrder.CLICKCOUNT, true, offset);
            return raw_stations;
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
                try {
                var result = provider.by_uuid (s);
                if (result.size == 1) {
                    raw_stations.add (result[0]);
                }
                } catch (RadioBrowser.DataError e) {
                    warning (@"Station $s could not be loaded: $(e.message)");
            }
            }

            return raw_stations;
        });
        return source;
    }

    public StationSource load_by_tags (string[] utags) {
        var tags = utags;
        var source = new StationSource(40);
        source.fetch.connect( (offset, limit) => {
            var raw_stations = provider.search ("", tags, limit, RadioBrowser.SortOrder.VOTES, true, offset);
            return raw_stations;
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
        try {
        var tags = provider.get_tags ();
        tags_updated (tags);
        } catch (RadioBrowser.DataError e) {
            warning (@"unable to load tags: $(e.message)");
    }
    }

}

public class Tuner.StationSource : Object {
    private uint _offset = 0;
    private uint _page_size = 20;
    private bool _more = true;
    public signal ArrayList<RadioBrowser.Station> fetch(uint offset, uint limit);

    public StationSource (uint limit) {
        Object ();
        // This disables paging for now
        _page_size = limit;
    }

    public ArrayList<Model.StationModel>? next () throws Error {
        // Fetch one more to determine if source has more items than page size
        var raw_stations = fetch (_offset, _page_size + 1);
        var stations = convert_stations (raw_stations);
        augment_with_userinfo (stations);
        _offset += _page_size;
        _more = stations.size > _page_size;
        if (_more) stations.remove_at( (int)_page_size);
        return stations;
    }

    public bool has_more () {
        return _more;
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

    private void augment_with_userinfo (ArrayList<Model.StationModel> stations) {
        var settings = Application.instance.settings;
        var starred = settings.get_strv ("starred-stations");

        foreach (Model.StationModel station in stations) {
            foreach (string id in starred) {
                var is_starred = (id == station.id);
                if (is_starred) {
                    station.starred = (id == station.id);
                    break;
                }
            }
        }
    }
}
