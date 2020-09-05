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
* Authored by: Louis Brauer <louis77@member.fsf.org>
*/

using Gee;

public class Tuner.StationList : AbstractContentList {

    public signal void selection_changed (Model.Station station);
    public signal void station_count_changed (uint count);
    public signal void favourites_changed ();

    public Model.Station selected_station;
    
    public ArrayList<Model.Station> stations {
        set construct {
            clear ();
            if (value == null) return;
            
            foreach (var s in value) {
                s.notify["starred"].connect ( () => {
                    favourites_changed ();
                });
                var box = new StationBox (s);
                box.clicked.connect (() => {
                    selection_changed (box.station);
                    selected_station = box.station;
                });
                add (box);
            }
            item_count = value.size;
        }
    }

    public StationList () {
        Object (
            homogeneous: false,
            min_children_per_line: 2,
            max_children_per_line: 2,
            column_spacing: 5,
            row_spacing: 5,
            border_width: 20,
            valign: Gtk.Align.START,
            selection_mode: Gtk.SelectionMode.NONE
        );
    }

    public StationList.with_stations (Gee.ArrayList<Model.Station> stations) {
        this ();
        this.stations = stations;
    }

    
    public void clear () {
        var childs = get_children();
        foreach (var c in childs) {
            c.destroy();
        }
    }

    public override uint item_count { get; set; }
}
