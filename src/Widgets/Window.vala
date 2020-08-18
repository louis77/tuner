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

using Gee;

public class Tuner.Window : Gtk.ApplicationWindow {
    public GLib.Settings settings;
    public Gtk.Stack stack { get; set; }

    private PlayerController _player;
    private DirectoryController _directory;
    private HeaderBar headerbar;
    private Granite.Widgets.SourceList source_list;
    
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_PAUSE = "action_pause";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_ABOUT = "action_about";
    public const string ACTION_DISABLE_TRACKING = "action_disable_tracking";

    private signal void refresh_favourites ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_PAUSE, on_toggle_playback },
        { ACTION_QUIT , on_action_quit },
        { ACTION_ABOUT, on_action_about },
        { ACTION_DISABLE_TRACKING, on_action_disable_tracking, null, "false" }
    };

    public Window (Application app, PlayerController player) {
        Object (application: app);

        application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q", "<Control>w"});

        _player = player;
        _player.state_changed.connect (handle_player_state_changed);
        _player.station_changed.connect (headerbar.update_from_station);

        var dark = new Theme ().is_theme_dark ();
        warning (@"Theme settings: $dark");
    }

    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/louis77/tuner/Application.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), 
            provider, 
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (800, 540);
        settings = Application.instance.settings;
        change_action_state (ACTION_DISABLE_TRACKING, settings.get_boolean ("do-not-track"));
        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));

        set_geometry_hints (null, Gdk.Geometry() {min_height = 440, min_width = 800}, Gdk.WindowHints.MIN_SIZE);
        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        delete_event.connect (e => {
            return before_destroy ();
        });

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        headerbar = new HeaderBar (this);
        set_titlebar (headerbar);

        var data_file = Path.build_filename (Application.instance.data_dir, "favorites.json");
        var store = new Model.StationStore (data_file);
        _directory = new DirectoryController (store);

        var primary_box = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);


        var selections_category = new Granite.Widgets.SourceList.ExpandableItem (_("Selections"));
        selections_category.collapsible = false;
        selections_category.expanded = true;

        var searched_category = new Granite.Widgets.SourceList.ExpandableItem (_("Search"));
        searched_category.collapsible = false;
        searched_category.expanded = true;

        var genres_category = new Granite.Widgets.SourceList.ExpandableItem (_("Genres"));
        genres_category.collapsible = true;
        genres_category.expanded = true;
        
        source_list = new Granite.Widgets.SourceList ();


        var c1 = create_content_box ("discover", _("Discover"), "face-smile",
                            _("Discover Stations"), "media-playlist-shuffle-symbolic",
                            _("Discover more stations"),
                            stack, selections_category, source_list);
        var s1 = _directory.load_random_stations(10);
        c1.realize.connect (() => {
            try {
                var slist = new StationList (s1.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c1.content = slist;
            } catch (SourceError e) {
                c1.show_alert ();
            }
        });
        c1.action_activated.connect (() => {
            try {
                var slist = new StationList (s1.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c1.content = slist;
            } catch (SourceError e) {
                c1.show_alert ();
            }
        });

        var c2 = create_content_box ("trending", _("Trending"), "playlist-queue",
                            _("Trending in the last 24 hours"), null, null,
                            stack, selections_category, source_list);
        var s2 = _directory.load_trending_stations(40);
        c2.realize.connect (() => {
            try {
                var slist = new StationList (s2.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c2.content = slist;
            } catch (SourceError e) {
                c2.show_alert ();
            }

        });
        
        var c3 = create_content_box ("popular", _("Popular"), "playlist-similar",
                            _("Most-listened over 24 hours"), null, null,
                            stack, selections_category, source_list);
        var s3 = _directory.load_popular_stations(40);
        c3.realize.connect (() => {
            try {
                var slist = new StationList (s3.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c3.content = slist;
            } catch (SourceError e) {
                c3.show_alert ();
            }
        });

        var c4 = create_content_box ("starred", _("Starred by You"), "starred",
                            _("Starred by You"), null, null,
                            stack, selections_category, source_list, true);
        
        var slist = new StationList (_directory.get_stored ());
        slist.selection_changed.connect (handle_station_click);
        slist.favourites_changed.connect (handle_favourites_changed);
        c4.content = slist;

        var c5 = create_content_box ("searched", _("Search Result"), "folder-saved-search",
                            _("Search"), null, null,
                            stack, searched_category, source_list, true);

        var c6 = create_content_box ("excluded_countries", _("Excluded Countries"), "folder-saved-search",
        _("Excluded Countries"), null, null,
        stack, searched_category, source_list, true);
        c6.content = new CountryList ();


        foreach (var genre in Model.genres ()) {
            var cb = create_content_box (genre.name, genre.name, "playlist-symbolic", 
                genre.name, null, null, stack, genres_category, source_list);
            var tags = new ArrayList<string>.wrap (genre.tags);
            var ds = _directory.load_by_tags (tags);
            cb.realize.connect (() => {
                try {
                    var slist1 = new StationList (ds.next ());
                    slist1.selection_changed.connect (handle_station_click);
                    slist1.favourites_changed.connect (handle_favourites_changed);
                    cb.content = slist1;
                } catch (SourceError e) {
                    cb.show_alert ();
                }
            });
        }

        headerbar.star_clicked.connect ( (starred) => {
            _player.station.toggle_starred ();
        });

        refresh_favourites.connect ( () => {
            var _slist = new StationList (_directory.get_stored ()); 
            _slist.selection_changed.connect (handle_station_click);
            _slist.favourites_changed.connect (handle_favourites_changed);
            c4.content = _slist;
        });

        source_list.root.add (selections_category);
        source_list.root.add (searched_category);
        source_list.root.add (genres_category);

        source_list.set_size_request (-1, -1);
        source_list.selected = source_list.get_first_child (selections_category);
        source_list.item_selected.connect  ((item) => {
            var selected_item = item.get_data<string> ("stack_child");
            stack.visible_child_name = selected_item;
        });

        headerbar.searched_for.connect ( (text) => {
            if (text.length > 0) {
                string mytext = text;
                var s5 = _directory.load_search_stations (mytext, 100); 
                try {
                    var stations = s5.next ();
                    if (stations == null || stations.size == 0) {
                        c5.show_nothing_found ();
                    } else {
                        var _slist = new StationList (stations);
                        _slist.selection_changed.connect (handle_station_click);
                        _slist.favourites_changed.connect (handle_favourites_changed);
                        c5.content = _slist;
                    }
                } catch (SourceError e) {
                    c5.show_alert ();
                }    
            }
        });

        headerbar.search_focused.connect (() => {
            stack.visible_child_name = "searched";
        });

        primary_box.pack1 (source_list, true, false);
        primary_box.pack2 (stack, true, false);
        add (primary_box);
        show_all ();
    }

    private ContentBox create_content_box (
             string name,
             string list_title,
             string list_icon_name,
             string full_title,
             string? action_icon_name,
             string? action_tooltip_text,
             Gtk.Stack stack,
             Granite.Widgets.SourceList.ExpandableItem category_item,
             Granite.Widgets.SourceList source_list,
             bool enable_count = false) {
        var item = new Granite.Widgets.SourceList.Item (list_title);
        item.icon = new ThemedIcon (list_icon_name);
        item.set_data<string> ("stack_child", name);
        category_item.add (item);
        var c = new ContentBox (
            null,
            full_title,
            action_icon_name,
            action_tooltip_text
        );
        c.map.connect (() => {
            source_list.selected = item;
        });
        if (enable_count) {
            c.content_changed.connect (() => {
                var count = c.content.item_count;
                var badge = @"$count";
                if (count >= 100) {
                    badge = "99+";
                }
                item.badge = badge;
            });
        }
        stack.add_named (c, name);

        return c;
    }
    
    private void on_action_quit () {
        close ();
    }

    private void on_action_about () {
        var dialog = new AboutDialog (this);
        dialog.present ();
    }

    public void handle_station_click (Tuner.Model.Station station) {
        info (@"handle station click for $(station.title)");
        _directory.count_station_click (station);
        _player.station = station;
    }

    public void handle_favourites_changed () {
        refresh_favourites ();
    }

    public void on_toggle_playback() {
        info ("Stop Playback requested");
        _player.play_pause ();
    }

    public void on_action_disable_tracking (SimpleAction action, Variant? parameter) {
        var new_state = !settings.get_boolean ("do-not-track");
        action.set_state (new_state);
        settings.set_boolean ("do-not-track", new_state);
        debug (@"on_action_disable_tracking: $new_state");
    }

    public void handle_player_state_changed (Gst.PlayerState state) {
        switch (state) {
            case Gst.PlayerState.BUFFERING:
                debug ("player state changed to Buffering");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Buffering");
                    headerbar.set_playstate (HeaderBar.PlayState.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.PAUSED:
                debug ("player state changed to Paused");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Paused");
                    if (_player.can_play()) {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_ACTIVE);
                    } else {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_INACTIVE);
                    }
                    return false;
                });
                break;;
            case Gst.PlayerState.PLAYING:
                debug ("player state changed to Playing");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Playing");
                    headerbar.set_playstate (HeaderBar.PlayState.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.STOPPED:
                debug ("player state changed to Stopped");
                Gdk.threads_add_idle (() => {
                    headerbar.subtitle = _("Stopped");
                    if (_player.can_play()) {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_ACTIVE);
                    } else {
                        headerbar.set_playstate (HeaderBar.PlayState.PLAY_INACTIVE);
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
