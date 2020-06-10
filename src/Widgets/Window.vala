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

    private Gst.Player _playerController;
    private DirectoryController _directory;
    private HeaderBar headerbar;
    private Gtk.Box content_area;
    private Gtk.Box content;

    public Window (Application app) {
        Object (
            application: app
        );
    }

    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/louis77/tuner/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider,                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    construct {
        _playerController = new Gst.Player( null, null );
        _playerController.state_changed.connect (handle_player_state_changed);

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
        headerbar.shuffle_clicked.connect ( () => {
            debug (@"Shuffle Button Clicked");
            var childs = content.get_children();
            foreach (var c in childs) {
                c.destroy();
            }
            _directory.load_top_stations ();
        });
        set_titlebar (headerbar);

        var content_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_header.homogeneous = false;

        var station_list_icon = new Gtk.Image.from_icon_name ("folder-music-symbolic", Gtk.IconSize.DIALOG);
        content_header.pack_start (station_list_icon, false, false, 20);

        var station_list_title = new Tuner.HeaderLabel ("Discover");
        station_list_title.xpad = 20;
        station_list_title.ypad = 20;
        content_header.pack_start (station_list_title, false, false);

        content_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_area.get_style_context ().add_class ("color-dark");
        content_area.pack_start (content_header, false, false);
        content_area.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content.get_style_context ().add_class ("color-light");
        content.valign = Gtk.Align.START;
        content.get_style_context().add_class("welcome");
        content_area.add (content);

        add (content_area);

        show_all ();

        _directory = new DirectoryController (new Services.RadioBrowserDirectory());
        _directory.stations_updated.connect (handle_updated_stations);
        _directory.load_top_stations();

    }

    public void handle_updated_stations (ArrayList<Model.StationModel> stations) {
        debug ("entering handle_updated_stations");
        var station_list = new Gtk.FlowBox ();
        station_list.homogeneous = false;
        station_list.min_children_per_line = 2;
        station_list.column_spacing = 5;
        station_list.row_spacing = 5;
        station_list.border_width = 20;
        station_list.valign = Gtk.Align.START;
        station_list.selection_mode = Gtk.SelectionMode.NONE;

        foreach (var s in stations) {
            var box = new StationBox (s);
            box.clicked.connect (() => {
                this.handle_station_click (box.station);
            });
            station_list.add (box);
        }

        content.add (station_list);
        station_list.unselect_all ();



        // Main content area
        set_geometry_hints (null, null, Gdk.WindowHints.MIN_SIZE);
        show_all ();
        // var scrolled_window = new Gtk.ScrolledWindow (null, null);
        // scrolled_window.add (content);
        // add (scrolled_window);

        debug ("exiting handle_updated_stations");
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

    public void handle_player_state_changed (Gst.Player player, Gst.PlayerState state) {
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
