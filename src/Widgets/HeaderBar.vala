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

public class Tuner.HeaderBar : Gtk.HeaderBar {

    public Tuner.Window main_window { get; construct; }
    public Gtk.Button play_button { get; set; }

    public signal void stop_clicked ();

    public HeaderBar (Tuner.Window window) {
        Object (
            main_window: window
        );
    }

    construct {
        show_close_button = true;
        title = "Choose a station";
        subtitle = "Paused";

        play_button = new Gtk.Button.from_icon_name (
            "media-playback-pause-symbolic",
            Gtk.IconSize.LARGE_TOOLBAR
        );
        play_button.valign = Gtk.Align.CENTER;
        play_button.sensitive = false;
        play_button.clicked.connect (() => { stop_clicked (); });

        pack_start (play_button);
    }

    public void update_from_station (Model.StationModel station) {
        title = station.title;
        subtitle = "Connecting";
    }

}
