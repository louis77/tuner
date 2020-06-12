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

    private Gtk.Button star_button;
    private bool _starred = false;
    private Model.StationModel _station;

    public signal void stop_clicked ();
    public signal void star_clicked (bool starred);

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

        star_button = new Gtk.Button.from_icon_name (
            "non-starred",
            Gtk.IconSize.LARGE_TOOLBAR
        );
        star_button.valign = Gtk.Align.CENTER;
        star_button.sensitive = true;
        star_button.tooltip_text = "Star this station to see it more often";
        star_button.clicked.connect (() => {
            starred = !starred;
            star_clicked (starred);
        });

        pack_end (star_button);
    }

    public void update_from_station (Model.StationModel station) {
        _station = station;
        title = station.title;
        subtitle = "Connecting";
        starred = station.starred;
        debug (@"Station $(title) starred? $starred");
    }

    private bool starred {
        get {
            return _starred;
        }

        set {
            _starred = value;
            if (!_starred) {
                star_button.image = new Gtk.Image.from_icon_name ("non-starred",    Gtk.IconSize.LARGE_TOOLBAR);
            } else {
                star_button.image = new Gtk.Image.from_icon_name ("starred",    Gtk.IconSize.LARGE_TOOLBAR);
            }
        }
    }

}
