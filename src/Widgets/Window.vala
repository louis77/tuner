/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */
/**
 * @file Window.vala
 * @brief Defines the main application window for the Tuner application.
 *
 * This file contains the Window class, which is responsible for creating and
 * managing the main application window. It handles the layout, user interface
 * elements, and interactions with other components of the application.
 *
 * The Window class inherits from Gtk.ApplicationWindow and implements various
 * features such as a header bar, source list, content stack, and player controls.
 * It also manages application settings and handles user actions like playback
 * control, station selection, and theme adjustments.
 *
 * @see Tuner.Application
 * @see Tuner.PlayerController
 * @see Tuner.DirectoryController
 */


using Gee;

/**
    Window
*/
public class Tuner.Window : Gtk.ApplicationWindow {

    /* Public */

    public const string WINDOW_NAME = "Tuner";
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_PAUSE = "action_pause";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_HIDE = "action_hide";
    public const string ACTION_ABOUT = "action_about";
    public const string ACTION_DISABLE_TRACKING = "action_disable_tracking";
    public const string ACTION_ENABLE_AUTOPLAY = "action_enable_autoplay";


    public GLib.Settings settings { get; construct; }
    public Gtk.Stack stack { get; set; }
    public PlayerController player { get; construct; }


    /* Private */   

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_PAUSE, on_toggle_playback },
        { ACTION_QUIT , on_action_quit },
        { ACTION_ABOUT, on_action_about },
        { ACTION_DISABLE_TRACKING, on_action_disable_tracking, null, "false" },
        { ACTION_ENABLE_AUTOPLAY, on_action_enable_autoplay, null, "false" }
    };

    private DirectoryController _directory;
    private HeaderBar _headerbar;
    private Granite.Widgets.SourceList source_list;

    private signal void refresh_favourites_sig ();


    /* Construct Static*/
    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/louis77/tuner/Application.css");
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }


    /**
     * @brief Constructs a new Window instance.
     * @param app The Application instance.
     * @param player The PlayerController instance.
     */
    public Window (Application app, PlayerController player) {
        Object (
            application: app,
            player: player,
            settings: Application.instance.settings
        );

        application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>w"});
    }


    /* Construct */
    construct {
        this.set_icon_name("com.github.louis77.tuner");
		this.size_allocate.connect(on_window_resize);

        _headerbar = new HeaderBar ();
        set_titlebar (_headerbar);
        set_title (WINDOW_NAME);

        player.state_changed.connect (handleplayer_state_changed);
        player.station_changed.connect (_headerbar.update_from_station);
        player.title_changed.connect ((title) => {
            _headerbar.subtitle = title;
        });
        player.volume_changed.connect ((volume) => {
            _headerbar.volume_button.value = volume;
        });
        _headerbar.volume_button.value_changed.connect ((value) => {
            player.volume = value;
        });

        adjust_theme();
        settings.changed.connect( (key) => {
            if (key == "theme-mode") {
                warning("theme-mode changed");
                adjust_theme();

            }
        });

        var granite_settings = Granite.Settings.get_default ();
        granite_settings.notify.connect( (key) => {
                warning("theme-mode changed");
                adjust_theme();
        });

        add_action_entries (ACTION_ENTRIES, this);

        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (900, 680);
        change_action_state (ACTION_DISABLE_TRACKING, settings.get_boolean ("do-not-track"));
        change_action_state (ACTION_ENABLE_AUTOPLAY, settings.get_boolean ("auto-play"));
        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));

        set_geometry_hints (null, Gdk.Geometry() {min_height = 440, min_width = 600}, Gdk.WindowHints.MIN_SIZE);
        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        delete_event.connect (e => {
            return before_destroy ();
        });

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        var favorites_file = Path.build_filename (Application.instance.data_dir, "favorites.json");
        var store = new Model.StationStore (favorites_file);
        _directory = new DirectoryController (store);

        var primary_box = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);


        var selections_category = new Granite.Widgets.SourceList.ExpandableItem (_("Selections"));
        selections_category.collapsible = false;
        selections_category.expanded = true;

        var searched_category = new Granite.Widgets.SourceList.ExpandableItem (_("Library"));
        searched_category.collapsible = false;
        searched_category.expanded = true;

        var genres_category = new Granite.Widgets.SourceList.ExpandableItem (_("Genres"));
        genres_category.collapsible = true;
        genres_category.expanded = true;

        source_list = new Granite.Widgets.SourceList ();

        // Discover Box
        var item1 = new Granite.Widgets.SourceList.Item (_("Discover"));
        item1.icon = new ThemedIcon ("face-smile");
        selections_category.add (item1);

        var c1 = create_content_box ("discover", item1,
                            _("Discover Stations"), "media-playlist-shuffle-symbolic",
                            _("Discover more stations"),
                            stack, source_list);
        var s1 = _directory.load_random_stations(20);
        c1.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (s1.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c1.content = slist;
            } catch (SourceError e) {
                c1.show_alert ();
            }
        });
        c1.action_activated_sig.connect (() => {
            try {
                var slist = new StationList.with_stations (s1.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c1.content = slist;
            } catch (SourceError e) {
                c1.show_alert ();
            }
        });

        // Trending Box
        var item2 = new Granite.Widgets.SourceList.Item (_("Trending"));
        item2.icon = new ThemedIcon ("playlist-queue");
        selections_category.add (item2);

        var c2 = create_content_box ("trending", item2,
                            _("Trending in the last 24 hours"), null, null,
                            stack, source_list);
        var s2 = _directory.load_trending_stations(40);
        c2.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (s2.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c2.content = slist;
            } catch (SourceError e) {
                c2.show_alert ();
            }

        });

        // Popular Box
        var item3 = new Granite.Widgets.SourceList.Item (_("Popular"));
        item3.icon = new ThemedIcon ("playlist-similar");
        selections_category.add (item3);

        var c3 = create_content_box ("popular", item3,
                            _("Most-listened over 24 hours"), null, null,
                            stack, source_list);
        var s3 = _directory.load_popular_stations(40);
        c3.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (s3.next ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                c3.content = slist;
            } catch (SourceError e) {
                c3.show_alert ();
            }
        });

        // Country-specific stations list
        var item4 = new Granite.Widgets.SourceList.Item (_("Your Country"));
        item4.icon = new ThemedIcon ("emblem-web");
        ContentBox c_country;
        c_country = create_content_box ("my-country", item4,
                            _("Your Country"), null, null,
                            stack, source_list, true);
        var c_slist = new StationList ();
        c_slist.selection_changed.connect (handle_station_click);
        c_slist.favourites_changed.connect (handle_favourites_changed);

        // Favourites Box
        var item5 = new Granite.Widgets.SourceList.Item (_("Starred by You"));
        item5.icon = new ThemedIcon ("starred");
        searched_category.add (item5);
        var c4 = create_content_box ("starred", item5,
                            _("Starred by You"), null, null,
                            stack, source_list, true);

        var slist = new StationList.with_stations (_directory.get_stored ());
        slist.selection_changed.connect (handle_station_click);
        slist.favourites_changed.connect (handle_favourites_changed);
        c4.content = slist;

        // Search Results Box
        var item6 = new Granite.Widgets.SourceList.Item (_("Recent Search"));
        item6.icon = new ThemedIcon ("folder-saved-search");
        searched_category.add (item6);
        var c5 = create_content_box ("searched", item6,
                            _("Search"), null, null,
                            stack, source_list, true);

        // Genre Boxes
        foreach (var genre in Model.genres ()) {
            var item8 = new Granite.Widgets.SourceList.Item (_(genre.name));
            item8.icon = new ThemedIcon ("playlist-symbolic");
            genres_category.add (item8);
            var cb = create_content_box (genre.name, item8,
                genre.name, null, null, stack, source_list);
            var tags = new ArrayList<string>.wrap (genre.tags);
            var ds = _directory.load_by_tags (tags);
            cb.realize.connect (() => {
                try {
                    var slist1 = new StationList.with_stations (ds.next ());
                    slist1.selection_changed.connect (handle_station_click);
                    slist1.favourites_changed.connect (handle_favourites_changed);
                    cb.content = slist1;
                } catch (SourceError e) {
                    cb.show_alert ();
                }
            });
        }

        _headerbar.star_clicked_sig.connect ( (starred) => {
            player.station.toggle_starred ();
        });

        refresh_favourites_sig.connect ( () => {
            var _slist = new StationList.with_stations (_directory.get_stored ());
            _slist.selection_changed.connect (handle_station_click);
            _slist.favourites_changed.connect (handle_favourites_changed);
            c4.content = _slist;
        });

        source_list.root.add (selections_category);
        source_list.root.add (searched_category);
        source_list.root.add (genres_category);

        source_list.ellipsize_mode = Pango.EllipsizeMode.NONE;
        source_list.selected = source_list.get_first_child (selections_category);
        source_list.item_selected.connect  ((item) => {
            var selected_item = item.get_data<string> ("stack_child");
            stack.visible_child_name = selected_item;
        });

        _headerbar.searched_for_sig.connect ( (text) => {
            if (text.length > 0) {
                string mytext = text;
                var s5 = _directory.load_search_stations (mytext, 100);
                try {
                    var stations = s5.next ();
                    if (stations == null || stations.size == 0) {
                        c5.show_nothing_found ();
                    } else {
                        var _slist = new StationList.with_stations (stations);
                        _slist.selection_changed.connect (handle_station_click);
                        _slist.favourites_changed.connect (handle_favourites_changed);
                        c5.content = _slist;
                    }
                } catch (SourceError e) {
                    c5.show_alert ();
                }
            }
        });

        _headerbar.search_focused_sig.connect (() => {
            stack.visible_child_name = "searched";
        });

        primary_box.pack1 (source_list, false, false);
        primary_box.pack2 (stack, true, false);
        add (primary_box);
        show_all ();

        // Auto-play
        if (settings.get_boolean("auto-play")) {
            warning (@"Auto-play enabled");
            var last_played_station = settings.get_string("last-played-station");
            warning (@"Last played station is: $last_played_station");

            var source = _directory.load_station_uuid (last_played_station);

            try {
                foreach (var station in source.next ()) {
                    handle_station_click(station);
                    break;
                }
            } catch (SourceError e) {
                warning ("Error while trying to autoplay, aborting...");
            }

        }
    }


    /**
     * @brief Handles window resizing.
     * @param self The widget being resized.
     * @param allocation The new allocation for the widget.
     */
    private void on_window_resize (Gtk.Widget self, Gtk.Allocation allocation) {
		int width = allocation.width;
		int height = allocation.height;

		debug (@"Window resized: w$(width) h$(height)");
	}


    /**
     * @brief Creates a new ContentBox and adds it to the stack.
     * @param name The name of the content box.
     * @param item The SourceList item associated with the content box.
     * @param full_title The full title of the content box.
     * @param action_icon_name The name of the action icon (or null if none).
     * @param action_tooltip_text The tooltip text for the action (or null if none).
     * @param stack The Gtk.Stack to add the content box to.
     * @param source_list The SourceList to update when the content box is selected.
     * @param enable_count Whether to enable item counting for the content box.
     * @return The created ContentBox.
     */
    private ContentBox create_content_box (
             string name,
             Granite.Widgets.SourceList.Item item,
             string full_title,
             string? action_icon_name,
             string? action_tooltip_text,
             Gtk.Stack stack,
             Granite.Widgets.SourceList source_list,
             bool enable_count = false) {
        item.set_data<string> ("stack_child", name);
        var c = new ContentBox (
            null,
            full_title,
            null,
            action_icon_name,
            action_tooltip_text
        );
        c.map.connect (() => {
            source_list.selected = item;
        });
        if (enable_count) {
            c.content_changed_sig.connect (() => {
                if (c.content == null) return;
                var count = c.content.item_count;
                item.badge = @"$count";
            });
        }
        stack.add_named (c, name);

        return c;
    }


    /**
     * @brief Adjusts the application theme based on user settings.
     */
    private static void adjust_theme() {
        var theme = Application.instance.settings.get_string("theme-mode");
        info(@"current theme: $theme");

        var gtk_settings = Gtk.Settings.get_default ();
        var granite_settings = Granite.Settings.get_default ();
        if (theme != "system") {
            gtk_settings.gtk_application_prefer_dark_theme = (theme == "dark");
        } else {
            gtk_settings.gtk_application_prefer_dark_theme = (granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK);
        }
    }


    /**
     * @brief Handles the quit action.
     */
    private void on_action_quit () {
        close ();
    }


    /**
     * @brief Handles the about action.
     */
    private void on_action_about () {
        var dialog = new AboutDialog (this);
        dialog.present ();
    }


    /**
     * @brief Handles a station selection.
     * @param station The selected station.
     */
    public void handle_station_click (Tuner.Model.Station station) {
        info (@"handle station click for $(station.title)");
        _directory.count_station_click (station);
        player.station = station;

        warning (@"storing last played station: $(station.id)");
        settings.set_string("last-played-station", station.id);

        set_title (WINDOW_NAME+": "+station.title);
    }


    /**
     * @brief Handles changes to the favorites list.
     */
    public void handle_favourites_changed () {
        refresh_favourites_sig ();
    }

    /**
     * @brief Toggles playback state.
     */
    public void on_toggle_playback() {
        info ("Stop Playback requested");
        player.play_pause ();
    }


    /**
     * @brief Handles the disable tracking action.
     * @param action The SimpleAction that triggered this method.
     * @param parameter The parameter passed with the action (unused).
     */
    public void on_action_disable_tracking (SimpleAction action, Variant? parameter) {
        var new_state = !settings.get_boolean ("do-not-track");
        action.set_state (new_state);
        settings.set_boolean ("do-not-track", new_state);
        debug (@"on_action_disable_tracking: $new_state");
    }


    /**
     * @brief Handles the enable autoplay action.
     * @param action The SimpleAction that triggered this method.
     * @param parameter The parameter passed with the action (unused).
     */
    public void on_action_enable_autoplay (SimpleAction action, Variant? parameter) {
        var new_state = !settings.get_boolean ("auto-play");
        action.set_state (new_state);
        settings.set_boolean ("auto-play", new_state);
        debug (@"on_action_enable_autoplay: $new_state");
    }


    /**
     * @brief Handles player state changes.
     * @param state The new player state.
     */
    public void handleplayer_state_changed (Gst.PlayerState state) {
        switch (state) {
            case Gst.PlayerState.BUFFERING:
                debug ("player state changed to Buffering");
                Gdk.threads_add_idle (() => {
                    _headerbar.set_playstate (HeaderBar.PlayState.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.PAUSED:
                debug ("player state changed to Paused");
                Gdk.threads_add_idle (() => {
                    if (player.can_play()) {
                        _headerbar.set_playstate (HeaderBar.PlayState.PLAY_ACTIVE);
                    } else {
                        _headerbar.set_playstate (HeaderBar.PlayState.PLAY_INACTIVE);
                    }
                    return false;
                });
                break;;
            case Gst.PlayerState.PLAYING:
                debug ("player state changed to Playing");
                Gdk.threads_add_idle (() => {
                    _headerbar.set_playstate (HeaderBar.PlayState.PAUSE_ACTIVE);
                    return false;
                });
                break;;
            case Gst.PlayerState.STOPPED:
                debug ("player state changed to Stopped");
                Gdk.threads_add_idle (() => {
                    if (player.can_play()) {
                        _headerbar.set_playstate (HeaderBar.PlayState.PLAY_ACTIVE);
                    } else {
                        _headerbar.set_playstate (HeaderBar.PlayState.PLAY_INACTIVE);
                    }
                    return false;
                });
                break;
        }

        return;
    }


    /**
     * @brief Performs cleanup actions before the window is destroyed.
     * @return true if the window should be hidden instead of destroyed, false otherwise.
     */
    public bool before_destroy () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.set_int ("pos-x", x);
        settings.set_int ("pos-y", y);
        settings.set_int ("window-height", height);
        settings.set_int ("window-width", width);

        if (player.current_state == Gst.PlayerState.PLAYING) {
            hide_on_delete();
            var notification = new GLib.Notification("Playing in background");
            notification.set_body("Click here to resume window. To quit Tuner, pause playback and close the window.");
            notification.set_default_action("app.resume-window");
            Application.instance.send_notification("continue-playing", notification);
            return true;
        }

        return false;
    }

}