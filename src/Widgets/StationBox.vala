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

public class Tuner.StationBox : Gtk.Button {

    public Tuner.Model.StationModel station { get; private set; }

    public StationBox (Tuner.Model.StationModel station) {
        label = station.title;
        this.station = station;

    /*
        border_width = 20;
        var style_context = get_style_context();
        style_context.add_class (Granite.STYLE_CLASS_CARD);

        var label = new Gtk.Label (station.title);
        pack_start (label);

        var sublabel = new Gtk.Label (station.location);
        pack_start (sublabel);
        */
    }

    construct {
    }

}
