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

public class Tuner.Window : Gtk.ApplicationWindow {
    public GLib.Settings settings;
    public Gtk.Stack stack { get; set; }

    private PlayerController _player;
    private DirectoryController _directory;
    private HeaderBar headerbar;
    private ContentBox content_area;

    public Window (Application app, PlayerController player) {
        Object (
            application: app
        );
        _player = player;
        _player.state_changed.connect (handle_player_state_changed);
        _player.station_changed.connect (headerbar.update_from_station);
    }

    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/tuner-elementary/tuner/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider,                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    construct {
        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (350, 80);
        settings = Application.instance.settings;
        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));
        // TODO: disable resizing for now
        // resize (settings.get_int ("window-width"), settings.get_int ("window-height"));
        delete_event.connect (e => {
            return before_destroy ();
        });

        headerbar = new HeaderBar (this);
        headerbar.stop_clicked.connect ( () => {
            handle_stop_playback ();
        });
        set_titlebar (headerbar);

        _directory = new DirectoryController (new Services.RadioBrowserDirectory());
        _directory.stations_updated.connect (handle_updated_stations);

        content_area = new ContentBox (
            new Gtk.Image.from_icon_name ("playlist-queue-symbolic", Gtk.IconSize.DIALOG),
            "Discover",
            _directory.load_top_stations,
            handle_station_click
        );

        add (content_area);
        show_all ();

        _directory.load_top_stations();
    }

    public void handle_updated_stations (ArrayList<Model.StationModel> stations) {
        debug ("entering handle_updated_stations");
        content_area.stations = stations;
        set_geometry_hints (null, null, Gdk.WindowHints.MIN_SIZE);
        show_all ();

        // var scrolled_window = new Gtk.ScrolledWindow (null, null);
        // scrolled_window.add (content);
        // add (scrolled_window);
    }

    public void handle_station_click(Tuner.Model.StationModel station) {
        info (@"handle station click for $(station.title)");
        _player.station = station;
    }

    public void handle_stop_playback() {
        info ("Stop Playback requested");
        _player.player.stop ();
    }

    public void handle_player_state_changed (Gst.PlayerState state) {
        switch (state) {
            case Gst.PlayerState.BUFFERING:
                debug ("player state changed to Buffering");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = "Buffering";
                    headerbar.play_button.sensitive = true;
                    return false;
                });
                break;;
            case Gst.PlayerState.PAUSED:
                debug ("player state changed to Paused");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = "Paused";
                    headerbar.play_button.sensitive = false;
                    return false;
                });
                break;;
            case Gst.PlayerState.PLAYING:
                debug ("player state changed to Playing");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Playing");
                    headerbar.play_button.sensitive = true;
                    return false;
                });
                break;;
            case Gst.PlayerState.STOPPED:
                debug ("player state changed to Stopped");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Stopped");
                    headerbar.play_button.sensitive = false;
                    return false;
                });
                break;
        }

        return;
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
