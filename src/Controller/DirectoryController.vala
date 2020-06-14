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

    public RadioBrowser.Client provider { get; set; }

    public signal void stations_updated (ContentBox target, ArrayList<Model.StationModel> stations);

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
            stations.add (s);
        }
        return stations;
    }

    private void augment_with_userinfo (ArrayList<Model.StationModel> stations) {
        var settings = Application.instance.settings;
        var starred = settings.get_strv ("starred-stations");

        foreach (Model.StationModel station in stations) {
            foreach (string id in starred) {
                station.starred = id == station.id;
            }
        }
    }


    public void load_and_update (ContentBox target, ArrayList<RadioBrowser.Station> raw_stations) {
        try {
            var stations = convert_stations (raw_stations);
            augment_with_userinfo (stations);
            stations_updated (target, stations);
        } catch (RadioBrowser.DataError e) {
            warning ("unable to fetch stations from directory: %s", e.message);
        }
    }

    public void load_random_stations (ContentBox target) {
        load_and_update (target, provider.load (10, RadioBrowser.SortOrder.RANDOM));
    }

    public void load_trending_stations (ContentBox target) {
        load_and_update (target, provider.load (10, RadioBrowser.SortOrder.CLICKTREND));
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

}
