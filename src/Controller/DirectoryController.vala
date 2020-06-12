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

    public IDirectoryProvider provider { get; set; }

    public signal void stations_updated (ArrayList<Model.StationModel> stations);

    public DirectoryController (IDirectoryProvider provider) {
        this.provider = provider;
    }

    public void load_top_stations() {
        try {
            var stations = provider.all();
            if (stations != null) {
                augment_with_userinfo (stations);
                stations_updated (stations);
            }
        } catch (DataError e) {
            warning ("unable to fetch stations from directory: %s", e.message);
        }
    }

    public void augment_with_userinfo (ArrayList<Model.StationModel> stations) {
        var settings = Application.instance.settings;
        var starred = settings.get_strv ("starred-stations");

        foreach (Model.StationModel station in stations) {
            foreach (string id in starred) {
                if (id == station.id) {
                    debug (@"Station STARRED: $(station.title)");
                    station.starred = true;
                } else {
                    debug (@"Station UNSTARRED: $(station.title)");
                }
            }
        }
    }

    public void star_station (Model.StationModel station, bool starred) {
        var settings = Application.instance.settings;
        var starred_stations = settings.get_strv ("starred-stations");

        if (starred) {
            starred_stations += station.id;
            settings.set_strv ("starred-stations", starred_stations);
            station.starred = true;
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
}
