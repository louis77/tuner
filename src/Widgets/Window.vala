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

public class Tuner.Window : Gtk.ApplicationWindow {
    public GLib.Settings settings;
    public Gtk.Stack stack { get; set; }

    private Gst.Player _playerController;
    private Tuner.HeaderBar headerbar;

    public Window (Application app) {
        Object (
            application: app
        );
    }

    construct {
        _playerController = new Gst.Player( null, null );
        _playerController.state_changed.connect ((e, state) => {
            switch (state) {
                case Gst.PlayerState.BUFFERING:
                    debug ("player state changed to Buffering");
                    headerbar.subtitle = "Buffering";
                    break;
                case Gst.PlayerState.PAUSED:
                    debug ("player state changed to Paused");
                    headerbar.subtitle = "Paused";
                    break;
                case Gst.PlayerState.PLAYING:
                    debug ("player state changed to Playing");
                    headerbar.subtitle = _("Playing");
                    break;
                case Gst.PlayerState.STOPPED:
                    debug ("player state changed to Stopped");
                    headerbar.subtitle = _("Stopped");
                    break;
            }
        });

        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (350, 80);

        settings = new GLib.Settings ("com.github.louis77.tuner");

        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));
        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        delete_event.connect (e => {
            return before_destroy ();
        });

        var station_list = new Gtk.Grid ();

        Tuner.Model.StationModel[] stations = {
            new Tuner.Model.StationModel ("Barba Radio 1", "Germany", "http://barbaradio.hoerradar.de/barbaradio-live-mp3-hq"),
            new Tuner.Model.StationModel ("Radio 1", "Zurich", "http://radio.nello.tv/128k"),
            new Tuner.Model.StationModel ("SRF 1 General", "Zurich", "http://stream.srg-ssr.ch/m/drs1/mp3_128")
        };

        foreach (var s in stations) {
            var box = new Tuner.StationBox (s);
            box.clicked.connect (() => {
                this.handle_station_click (box.station);
            });
            station_list.add (box);
        }

        add (station_list);

        headerbar = new Tuner.HeaderBar (this);
        headerbar.stop_clicked.connect ( () => {
            handle_stop_playback ();
        });
        set_titlebar (headerbar);

        show_all ();



    }

    public void handle_station_click(Tuner.Model.StationModel station) {
        info (@"handle station click for $(station.title)");
        headerbar.title = station.title;
        headerbar.subtitle = "Connecting";

        _playerController.uri = station.url;
        _playerController.play ();
    }

    public void handle_stop_playback() {
        info ("Stop Playback requested");
        _playerController.stop ();
    }

    public bool before_destroy () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.set_int ("pos-x", x);
        settings.set_int ("pos-y", y);
        settings.set_int ("window-height", height);
        settings.set_int ("window-width", width);

        return false;
    }

}
