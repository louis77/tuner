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



    public Settings settings { get; construct; }
    public Gtk.Stack stack { get; set; }
    public PlayerController player { get; construct; }
    public StarredStationController starred { get; construct; }
    public bool active { get; private set; } // Window is active


    /* Private */   

    private const string STACK_SEARCHED = "searched";
    private const string CSS = "com/github/louis77/tuner/Application.css";
    private const string NOTIFICATION_PLAYING_BACKGROUND = "Playing in background";
    private const string NOTIFICATION_CLICK_RESUME = "Click here to resume window. To quit Tuner, pause playback and close the window.";
    private const string NOTIFICATION_APP_RESUME_WINDOW = "app.resume-window";
    private const string NOTIFICATION_APP_PLAYING_CONTINUE = "continue-playing";

    private const int GEOMETRY_MIN_HEIGHT = 440;
    private const int GEOMETRY_MIN_WIDTH = 600;

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

     /** @brief Indicates if the application started online. */
     private bool _started_online = app().is_online;  // Initial online state

    private signal void refresh_favourites_sig ();


    /* Construct Static*/
    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource (CSS);
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
    public Window (Application app, PlayerController player, Settings settings, StarredStationController starred ) {
        Object (
            application: app,
            player: player,
            settings: settings,
            starred: starred
        );

        application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>w"});
    }


    /* Construct */
    construct { // FIXME    Way to complex - should be in activate?
        

        this.set_icon_name(Application.APP_ID);
        add_action_entries (ACTION_ENTRIES, this);
        set_title (WINDOW_NAME);
        window_position = Gtk.WindowPosition.CENTER;
        set_geometry_hints (null, Gdk.Geometry() { min_height = GEOMETRY_MIN_HEIGHT, min_width = GEOMETRY_MIN_WIDTH}, Gdk.WindowHints.MIN_SIZE);
        change_action_state (ACTION_DISABLE_TRACKING, settings.do_not_track);
        change_action_state (ACTION_ENABLE_AUTOPLAY, settings.auto_play);


        /*
            Headerbar
        */
        _headerbar = new HeaderBar ();
        set_titlebar (_headerbar);

        _headerbar.volume_button.value_changed.connect ((value) => {
            player.volume = value;
        });

        _headerbar.search_focused_sig.connect (() => {
            stack.visible_child_name = STACK_SEARCHED;
        });


        /*
            Online checks & behavior

            Keep in mind that network availability is noisy
        */
            app().notify["is-online"].connect(() => {
            check_online_status();
        });


        /* Do an initial check */
        if (app().is_online)
        {
            //initialize();
           active = true;
        }
        else 
        /*
            Starting Offline, so set to look offline
            Initialization will happen when online
        */
        { 
            check_online_status();  
        }

        player.state_changed.connect (handleplayer_state_changed);
        player.station_changed.connect (_headerbar.update_from_station);
        player.title_changed.connect ((title) => {
            _headerbar.subtitle = title;
        });
        player.volume_changed.connect ((volume) => {
            _headerbar.volume_button.value = volume;
        });







        //  adjust_theme();    // TODO Theme management needs research in flatpak as nonfunctional
        //  settings.changed.connect( (key) => {
        //      if (key == "theme-mode") {
        //          debug("theme-mode changed");
        //          adjust_theme();                     
        //      }
        //  });

        var granite_settings = Granite.Settings.get_default ();
        //  granite_settings.notify.connect( (key) => { // FIXME
        //          debug("theme-mode changed");
        //          adjust_theme();
        //  });


       // set_default_size (900, 680);
       // move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));

        //resize (settings.get_int ("window-width"), settings.get_int ("window-height"));


		this.size_allocate.connect(on_window_resize);

        delete_event.connect (e => {
            return before_destroy ();
        });

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        // ---------------------------------------------------------------------------

       // var store = new Model.StarredStationStore ();
        _directory = new DirectoryController (new Provider.RadioBrowser(null),starred);

        var primary_box = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);


        var selections_category = new Granite.Widgets.SourceList.ExpandableItem (_("Selections"));
        selections_category.collapsible = false;
        selections_category.expanded = true;

        var searched_category = new Granite.Widgets.SourceList.ExpandableItem (_("Library"));
        searched_category.collapsible = false;
        searched_category.expanded = true;

        var explore_category = new Granite.Widgets.SourceList.ExpandableItem (_("Explore"));
        explore_category.collapsible = true;
        explore_category.expanded = false;

        var genres_category = new Granite.Widgets.SourceList.ExpandableItem (_("Genres"));
        genres_category.collapsible = true;
        genres_category.expanded = true;

        var subgenres_category = new Granite.Widgets.SourceList.ExpandableItem (_("Sub Genres"));
        subgenres_category.collapsible = true;
        subgenres_category.expanded = false;

        var eras_category = new Granite.Widgets.SourceList.ExpandableItem (_("Eras"));
        eras_category.collapsible = true;
        eras_category.expanded = false;

        var talk_category = new Granite.Widgets.SourceList.ExpandableItem (_("Talk, News, Sport"));
        talk_category.collapsible = true;
        talk_category.expanded = false;

        source_list = new Granite.Widgets.SourceList ();

        
        // ---------------------------------------------------------------------------

        /*
            Discover
        */
        var discover = SourceListBox.create ( stack
            , source_list
            ,  selections_category
            , "discover"
            , "face-smile"
            , "Discover"
            , "Stations to Explore"
            ,_directory.load_random_stations(20)
            , "Discover more stations"
            , "media-playlist-shuffle-symbolic");
        
        stack.add_named (discover, discover.name);
       // var dis_data = _directory.load_random_stations(20);
        discover.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (discover.next_page ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                discover.content = slist;
            } catch (SourceError e) {
                discover.show_alert ();
            }
        });
        
        discover.action_activated_sig.connect (() => {
            try {
                var slist = new StationList.with_stations (discover.next_page ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                discover.content = slist;
            } catch (SourceError e) {
                discover.show_alert ();
            }
        });

        // ---------------------------------------------------------------------------

        /*
            Trending
        */
        var trending = SourceListBox.create ( stack
            , source_list
            ,  selections_category
            , "trending"
            , "playlist-queue"
            , "Trending"
            , "Trending in the last 24 hours"
        ,_directory.load_trending_stations(40));

       // var s2 = _directory.load_trending_stations(40);
        trending.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (trending.next_page ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                trending.content = slist;
            } catch (SourceError e) {
                trending.show_alert ();
            }

        });

        // ---------------------------------------------------------------------------

        /*
            Popular
        */
        var popular = SourceListBox.create ( stack
            , source_list
            ,  selections_category
            , "popular"
            , "playlist-similar"
            , "Popular"
            , "Most-listened over 24 hours"
        ,_directory.load_popular_stations(40));

        popular.realize.connect (() => {
            try {
                var slist = new StationList.with_stations (popular.next_page ());
                slist.selection_changed.connect (handle_station_click);
                slist.favourites_changed.connect (handle_favourites_changed);
                popular.content = slist;
            } catch (SourceError e) {
                popular.show_alert ();
            }
        });

        // ---------------------------------------------------------------------------
        // Country-specific stations list
        
        //  var item4 = new Granite.Widgets.SourceList.Item (_("Your Country"));
        //  item4.icon = new ThemedIcon ("emblem-web");
        //  ContentBox c_country;
        //  c_country = create_content_box ("my-country", item4,
        //                      _("Your Country"), null, null,
        //                      stack, source_list, true);
        //  var c_slist = new StationList ();
        //  c_slist.selection_changed.connect (handle_station_click);
        //  c_slist.favourites_changed.connect (handle_favourites_changed);

        // ---------------------------------------------------------------------------

        /*
            Starred
        */
        var item5 = new Granite.Widgets.SourceList.Item (_("Starred by You"));
        item5.icon = new ThemedIcon ("starred");
        searched_category.add (item5);
        var c4 = create_content_box ("starred", item5,
                            _("Starred by You"), null, null,
                            stack, source_list, true);

        var slist = new StationList.with_stations (_directory.get_starred ());
        slist.selection_changed.connect (handle_station_click);
        slist.favourites_changed.connect (handle_favourites_changed);
        c4.content = slist;

        // ---------------------------------------------------------------------------
        // Search Results Box
        
        var search = new Granite.Widgets.SourceList.Item (_("Recent Search"));
        search.icon = new ThemedIcon ("folder-saved-search");
        searched_category.add (search);
        var search_results = create_content_box (STACK_SEARCHED, search,
                            _("Search"), null, null,
                            stack, source_list, true);

        // ---------------------------------------------------------------------------

        // Explore Categories category

        // Get random categories and stations in them
        Set<Provider.Tag> result = _directory.load_random_genres(3);

        foreach (var a in result)
        {
            var genre = SourceListBox.create ( stack
                , source_list
                , explore_category
                , a.name
                , "playlist-symbolic"
                , a.name
                , a.name);

            var ds = _directory.load_by_tag (a.name);

            genre.realize.connect (() => {
                try {
                    var slist1 = new StationList.with_stations (ds.next_page ());
                    slist1.selection_changed.connect (handle_station_click);
                    slist1.favourites_changed.connect (handle_favourites_changed);
                    genre.content = slist1;
                } catch (SourceError e) {
                    genre.show_alert ();
                }
            });
        }

        // ---------------------------------------------------------------------------

        // Genre Boxes
        category_genre( stack, source_list, _directory, genres_category,   Model.Genre.GENRES );

        // Sub Genre Boxes
        category_genre( stack, source_list, _directory, subgenres_category,   Model.Genre.SUBGENRES );

        // Eras Boxes
        category_genre( stack, source_list, _directory, eras_category,   Model.Genre.ERAS );
    
        // Talk Boxes
        category_genre( stack, source_list, _directory, talk_category,   Model.Genre.TALK );
    

       // ---------------------------------------------------

        _headerbar.star_clicked_sig.connect ( (starred) => {
            player.station.toggle_starred ();
        });

        refresh_favourites_sig.connect ( () => {
            var _slist = new StationList.with_stations (_directory.get_starred ());
            _slist.selection_changed.connect (handle_station_click);
            _slist.favourites_changed.connect (handle_favourites_changed);
            c4.content = _slist;
        });

        source_list.root.add (selections_category);
        source_list.root.add (searched_category);
        source_list.root.add (explore_category);
        source_list.root.add (genres_category);
        source_list.root.add (subgenres_category);
        source_list.root.add (eras_category);
        source_list.root.add (talk_category);

        source_list.ellipsize_mode = Pango.EllipsizeMode.NONE;
        source_list.selected = source_list.get_first_child (selections_category);
        source_list.item_selected.connect  ((item) => {
            var selected_item = item.get_data<string> ("stack_child");
            stack.visible_child_name = selected_item;
        });

        // ---------------------------------------------------------------------------

        _headerbar.searched_for_sig.connect ( (text) => {
            if (text.length > 0) {
                load_search_stations.begin(text, search_results);
            }
        });


        primary_box.pack1 (source_list, false, false);
        primary_box.pack2 (stack, true, false);
        add (primary_box);
        show_all ();

        // Auto-play
        if (_settings.auto_play) {
            debug (@"Auto-play enabled");
            var source = _directory.load_station_uuid (_settings.last_played_station);

            try {
                foreach (var station in source.next_page ()) {   // FIXME  Why
                    handle_station_click(station);  
                    break;
                }
            } catch (SourceError e) {
                warning ("Error while trying to autoplay, aborting...");
            }
        }
    } // construct


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
        bool enable_count = false) 
    {
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
            item.badge = @"$count\t";
        });
    }
    stack.add_named (c, name);

    return c;
    } // create_content_box



    // ----------------------------------------------------------------------
    //
    // Handlers
    //
    // ----------------------------------------------------------------------


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
        settings.do_not_track = !settings.do_not_track;
        action.set_state (settings.do_not_track);
        debug (@"on_action_disable_tracking: $(settings.do_not_track)");
    }


    /**
     * @brief Handles the enable autoplay action.
     * @param action The SimpleAction that triggered this method.
     * @param parameter The parameter passed with the action (unused).
     */
    public void on_action_enable_autoplay (SimpleAction action, Variant? parameter) {
        settings.auto_play = !settings.auto_play;
        action.set_state (settings.auto_play);
        debug (@"on_action_enable_autoplay: $(settings.auto_play)");
    }

    // ----------------------------------------------------------------------
    //
    // Handlers
    //
    // ----------------------------------------------------------------------


    /**
     * @brief Handles a station selection.
     * @param station The selected station.
     */
     public void handle_station_click (Model.Station station) {
        debug (@"handle station click for $(station.name)");
        _directory.count_station_click (station);
        player.station = station;

        debug (@"Storing last played station: $(station.stationuuid)");
        _settings.last_played_station = station.stationuuid;

        set_title (WINDOW_NAME+": "+station.name);
    } // handle_station_click


    /**
     * @brief Handles changes to the favorites list.
     */
    public void handle_favourites_changed () {
        refresh_favourites_sig ();
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
    } // handleplayer_state_changed

    /**
     * @brief Performs cleanup actions before the window is destroyed.
     * @return true if the window should be hidden instead of destroyed, false otherwise.
     */
    public bool before_destroy () {

        _settings.save ();

        if (player.current_state == Gst.PlayerState.PLAYING) {
            hide_on_delete();
            var notification = new GLib.Notification(NOTIFICATION_PLAYING_BACKGROUND);
            notification.set_body(NOTIFICATION_CLICK_RESUME);
            notification.set_default_action(NOTIFICATION_APP_RESUME_WINDOW);
            app().send_notification(NOTIFICATION_APP_PLAYING_CONTINUE, notification);
            return true;
        }

        return false;
    } // before_destroy


    /**
     * @brief Loads search stations based on the provided text and updates the content box.
     * Async since 1.5.5 so that UI is responsive during long searches
     * @param searchText The text to search for stations.
     * @param contentBox The ContentBox to update with the search results.
     */
    private async void load_search_stations(string searchText, ContentBox contentBox) {

        debug(@"Searching for: $(searchText)");        // FIXME warnings to debugs
        var station_source = _directory.load_search_stations(searchText, 100);
        debug(@"Search done");

        try {
            var stations = station_source.next_page();
            debug(@"Search Next done");
            if (stations == null || stations.size == 0) {
                contentBox.show_nothing_found();
            } else {
                debug(@"Search found $(stations.size) stations");
                var _slist = new StationList.with_stations(stations);
                _slist.selection_changed.connect(handle_station_click);
                _slist.favourites_changed.connect(handle_favourites_changed);
                contentBox.content = _slist;
            }
        } catch (SourceError e) {
            contentBox.show_alert();
        }
    } // load_search_stations


    private void check_online_status()
    {
        if ( app().is_offline )
        /* Present Offline look */
        {
            this.accept_focus = false;
            active = false;
            return;
        }

        if ( !active )
        // Online but not active
        {
            if (!_started_online)
            /*
                Window not initialized, refresh
            */
            {
                //  initialize();
                //  show_all();            
                _started_online = true;
            }
            this.accept_focus = true;
            active = true;
        }
    } // check_online_status

    // -------------------------------------------------

    private void category_genre( Gtk.Stack stack
        , Granite.Widgets.SourceList source_list
        , DirectoryController directory
        , Granite.Widgets.SourceList.ExpandableItem category
        , string[] genres)
    {
        foreach (var new_genre in genres ) {

            warning(@"tag: $(new_genre.down())");
            var genre = SourceListBox.create ( stack
                , source_list
                , category
                , new_genre
                , "playlist-symbolic"
                , new_genre
                , new_genre);

            var ds = directory.load_by_tag (new_genre.down ());

            genre.realize.connect (() => {
                try {
                    var slist1 = new StationList.with_stations (ds.next_page ());
                    slist1.selection_changed.connect (handle_station_click);
                    slist1.favourites_changed.connect (handle_favourites_changed);
                    genre.content = slist1;
                } catch (SourceError e) {
                    genre.show_alert ();
                }
            });
        }
    }
}
