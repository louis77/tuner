/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
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
            min_children_per_line: 1,
            max_children_per_line: 3,
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
