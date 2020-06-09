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
    private HeaderBar headerbar;

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

        settings = Application.instance.settings;

        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));
        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        delete_event.connect (e => {
            return before_destroy ();
        });


        var station_list = new Gtk.FlowBox ();
        station_list.column_spacing = 5;
        station_list.row_spacing = 5;
        station_list.border_width = 20;
        station_list.valign = Gtk.Align.START;

        var directory = new Model.RadioBrowserDirectory();
        var stations = directory.all();

        foreach (var s in stations) {
            var box = new StationBox (s);
            box.clicked.connect (() => {
                this.handle_station_click (box.station);
            });
            station_list.add (box);
        }

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content.valign = Gtk.Align.START;
        var station_list_title = new Granite.HeaderLabel ("Top Stations");
        station_list_title.xpad = 20;
        station_list_title.ypad = 10;
        content.pack_start (station_list_title);
        content.pack_start (station_list);

        add (content);

        headerbar = new HeaderBar (this);
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
