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

public class Tuner.StationContextMenu : Gtk.Menu {
    public Model.Station station;

    public StationContextMenu (Model.Station station) {
        Object ();
        this.station = station;

        var label = new Gtk.MenuItem.with_label (this.station.title);
        label.sensitive = false;
        this.append (label);

        var label2 = new Gtk.MenuItem.with_label (this.station.location);
        label2.sensitive = false;
        this.append (label2);

        this.append (new Gtk.SeparatorMenuItem ());

        var m1 = new Gtk.MenuItem ();
        set_star_context (m1);
        m1.activate.connect (on_star_handler);
        this.append (m1);

        this.station.notify["starred"].connect ( (sender, property) => {
            set_star_context (m1);
        });
    }

    private void on_star_handler () {
       station.toggle_starred ();
    }

    private void set_star_context (Gtk.MenuItem item) {
        item.label = station.starred ? _("Unstar this station") : _("Star this station");
    }

}