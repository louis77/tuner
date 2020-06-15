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

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_PAUSE = "action_pause";
    public const string ACTION_QUIT = "action_quit";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_PAUSE, handle_stop_playback },
        { ACTION_QUIT, action_quit }
    };

    public Window (Application app, PlayerController player) {
        Object (application: app);

        application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q", "<Control>w"});

        _player = player;
        _player.state_changed.connect (handle_player_state_changed);
        _player.station_changed.connect (headerbar.update_from_station);
    }

    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/louis77/tuner/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider,                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (350, 80);
        settings = Application.instance.settings;
        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));
        resize (default_width, default_height);

        delete_event.connect (e => {
            return before_destroy ();
        });

        headerbar = new HeaderBar (this);
        headerbar.stop_clicked.connect ( () => {
            handle_stop_playback ();
        });
        headerbar.star_clicked.connect ( (starred) => {
            _directory.star_station (_player.station, starred);
        });
        set_titlebar (headerbar);

        _directory = new DirectoryController (new RadioBrowser.Client ());
        _directory.stations_updated.connect (handle_updated_stations);

        var primary_box = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        var c1 = new ContentBox (
            // new Gtk.Image.from_icon_name ("face-smile-symbolic", Gtk.IconSize.DIALOG),
            null,
            "Discover Stations",
            _directory.load_random_stations,
            "media-playlist-shuffle-symbolic",
            "Discover more stations",
            handle_station_click
        );
        stack.add_titled (c1, "discover", "Discover");

        var c2 = new ContentBox (
            // new Gtk.Image.from_icon_name ("playlist-queue-symbolic", Gtk.IconSize.DIALOG),
            null,
            "Trending Stations",
            _directory.load_trending_stations,
            "go-next",
            "Load more stations",
            handle_station_click
        );
        stack.add_titled (c2, "trending", "Trending");

        var c3 = new ContentBox (
            // new Gtk.Image.from_icon_name ("playlist-similar-symbolic", Gtk.IconSize.DIALOG),
            null,
            "Popular Stations",
            _directory.load_popular_stations,
            "go-next",
            "Load more stations",
            handle_station_click
        );
        stack.add_titled (c3, "popular", "Popular");

        var c4 = new ContentBox (
            // new Gtk.Image.from_icon_name ("playlist-automatic-symbolic", Gtk.IconSize.DIALOG),
            null,
            "Starred by You",
            _directory.load_favourite_stations,
            "view-refresh-symbolic",
            "Refresh",
            handle_station_click
        );
        stack.add_titled (c4, "starred", "Starred by You");

        var sidebar = new Gtk.StackSidebar ();
        sidebar.set_stack (stack);

        var selections_category = new Granite.Widgets.SourceList.ExpandableItem ("Selections");
        selections_category.collapsible = false;
        selections_category.expanded = true;

        var discover_item = new Granite.Widgets.SourceList.Item ("Discover");
        discover_item.icon = new ThemedIcon ("face-smile-symbolic");
        discover_item.set_data<string> ("stack_child", "discover");
        selections_category.add (discover_item);

        var trending_item = new Granite.Widgets.SourceList.Item ("Trending");
        trending_item.icon = new ThemedIcon ("playlist-queue");
        trending_item.set_data<string> ("stack_child", "trending");
        selections_category.add (trending_item);

        var popular_item = new Granite.Widgets.SourceList.Item ("Popular");
        popular_item.icon = new ThemedIcon ("playlist-similar");
        popular_item.set_data<string> ("stack_child", "popular");
        selections_category.add (popular_item);

        var starred_item = new Granite.Widgets.SourceList.Item ("Starred by You");
        starred_item.icon = new ThemedIcon ("starred");
        starred_item.set_data<string> ("stack_child", "starred");
        selections_category.add (starred_item);

        var source_list = new Granite.Widgets.SourceList ();
        source_list.root.add (selections_category);
        source_list.set_size_request (150, -1);
        source_list.item_selected.connect  ((item) => {
            var selected_item = item.get_data<string> ("stack_child");
            debug (@"selected $selected_item");
            stack.visible_child_name = selected_item;

        });

        primary_box.pack1 (source_list, true, false);
        primary_box.pack2 (stack, true, false);
        add (primary_box);
        show_all ();
    }

    private void action_quit () {
        destroy ();
    }

    public void handle_updated_stations (ContentBox target, ArrayList<Model.StationModel> stations) {
        debug ("entering handle_updated_stations");
        target.stations = stations;

        // set_geometry_hints (null, null, Gdk.WindowHints.MIN_SIZE);
        show_all ();
        resize (default_width, default_height);
        // var scrolled_window = new Gtk.ScrolledWindow (null, null);
        // scrolled_window.add (content);
        // add (scrolled_window);
    }

    public void handle_station_click(Tuner.Model.StationModel station) {
        info (@"handle station click for $(station.title)");
        _directory.count_station_click (station);
        _player.station = station;
    }

    public void handle_stop_playback() {
        info ("Stop Playback requested");
        _player.play_pause ();
    }

    public void handle_player_state_changed (Gst.PlayerState state) {
        switch (state) {
            case Gst.PlayerState.BUFFERING:
                debug ("player state changed to Buffering");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = "Buffering";
                    headerbar.set_playstate (headerbar.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.PAUSED:
                debug ("player state changed to Paused");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = "Paused";
                    if (_player.can_play()) {
                        headerbar.set_playstate (headerbar.PLAY_ACTIVE);
                    } else {
                        headerbar.set_playstate (headerbar.PLAY_INACTIVE);
                    }
                    return false;
                });
                break;;
            case Gst.PlayerState.PLAYING:
                debug ("player state changed to Playing");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Playing");
                    headerbar.set_playstate (headerbar.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.STOPPED:
                debug ("player state changed to Stopped");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Stopped");
                    if (_player.can_play()) {
                        headerbar.set_playstate (headerbar.PLAY_ACTIVE);
                    } else {
                        headerbar.set_playstate (headerbar.PLAY_INACTIVE);
                    }
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
