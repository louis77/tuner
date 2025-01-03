/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file Window.vala
 *
 * @brief Defines the main application window for the Tuner application.
 *
 * This file contains the Window class, which is responsible for creating and
 * managing the main application window. It handles the major layout, user interface
 * elements, and interactions with other non-display components of the application.
 *
 * The Window class inherits from Gtk.ApplicationWindow and implements various
 * features such as a header bar, main display and player controls.
 * It also manages application settings and handles user actions like playback
 * control, station selection, and theme adjustments.
 *
 * @see Tuner.Application
 * @see Tuner.PlayerController
 * @see Tuner.DirectoryController
 * @see Tuner.HeaderBar
 * @see Tuner.Display
 */


using Gee;
using Granite.Widgets;


/**
 * The main application window for the Tuner app.
 * 
 * This class extends Gtk.ApplicationWindow and serves as the primary container
 * for all other widgets and functionality in the Tuner application.
 */
public class Tuner.Window : Gtk.ApplicationWindow
{

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

	private const string CSS                               = "io/github/louis77/tuner/Application.css";
	private const string NOTIFICATION_PLAYING_BACKGROUND   = _("Playing in background");
	private const string NOTIFICATION_CLICK_RESUME         = _("Click here to resume window. To quit Tuner, pause playback and close the window.");
	private const string NOTIFICATION_APP_RESUME_WINDOW    = "app.resume-window";
	private const string NOTIFICATION_APP_PLAYING_CONTINUE = "continue-playing";

	private const int RANDOM_CATEGORIES = 5;

	private const int GEOMETRY_MIN_HEIGHT = 440;
	private const int GEOMETRY_MIN_WIDTH  = 600;

	private const ActionEntry[] ACTION_ENTRIES = {
		{ ACTION_PAUSE,            on_toggle_playback                         },
		{ ACTION_QUIT,             on_action_quit                             },
		{ ACTION_ABOUT,            on_action_about                            },
		{ ACTION_DISABLE_TRACKING, on_action_disable_tracking, null, "false"  },
		{ ACTION_ENABLE_AUTOPLAY,  on_action_enable_autoplay, null, "false"   },
		{ ACTION_START_ON_STARRED, on_action_start_on_starred, null, "false"  },
		{ ACTION_STREAM_INFO,      on_action_stream_info, null, "true"        },
		{ ACTION_STREAM_INFO_FAST, on_action_stream_info_fast, null, "false"  },
	};

    /*
        Assets
    */

	private HeaderBar _headerbar;
	private Display _display;
    private bool _start_on_starred = false;

	private signal void refresh_saved_searches_sig (bool add, string search_text);


    //  /* Construct Static*/
    //  static construct {
    //      var provider = new Gtk.CssProvider ();
    //      provider.load_from_resource (CSS);
    //      Gtk.StyleContext.add_provider_for_screen (
    //          Gdk.Screen.get_default (),
    //          provider,
    //          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    //      );
    //  } // static construct


    /**
     * @brief Constructs a new Window instance.
     *
     * @param app The Application instance.
     * @param player The PlayerController instance.
     */
    public Window (Application app, PlayerController player, Settings settings, DirectoryController directory ) 
    {
        Object (
            application: app,
            player_ctrl: player,
            settings: settings,
            directory: directory
        );

        add_widgets();
        check_online_status();

        if ( settings.start_on_starred ) choose_starred_stations();  // Start on starred  

        show_all ();

		application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
		application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q"});
		application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>w"});
	} // Window


    /* 
        Construct 
    */
    construct 
    { 
		set_icon_name(Application.APP_ID);
		add_action_entries (ACTION_ENTRIES, this);
		set_title (WINDOW_NAME);
		window_position = Gtk.WindowPosition.CENTER;
		set_geometry_hints (null, Gdk.Geometry() {
			min_height = GEOMETRY_MIN_HEIGHT, min_width = GEOMETRY_MIN_WIDTH
		}, Gdk.WindowHints.MIN_SIZE);
		change_action_state (ACTION_DISABLE_TRACKING, settings.do_not_track);
		change_action_state (ACTION_ENABLE_AUTOPLAY, settings.auto_play);
		change_action_state (ACTION_START_ON_STARRED, settings.start_on_starred);
		change_action_state (ACTION_STREAM_INFO, settings.stream_info);
		change_action_state (ACTION_STREAM_INFO_FAST, settings.stream_info_fast);

               
        /*
            Setup
        */

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
                load_search_stations.begin(text, c5);
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
        if (_settings.auto_play) 
        {
            _directory.load ();
            var source = _directory.load_station_uuid (_settings.last_played_station);

            try
            {
                foreach (var station in source.next_page ())
                {
                    handle_play_station(station);
                    break;
                }
            } catch (SourceError e)
            {
                warning ("Error while trying to autoplay, aborting...");
            }
        }
    } // add_widgets


    /* --------------------------------------------------------
    
        Methods

        ----------------------------------------------------------
    */

    // ----------------------------------------------------------------------
    //
    // Actions
    //
    // ----------------------------------------------------------------------


    /**
     * @brief Handles the quit action.
     */
    private void on_action_quit () 
    {
        close ();
    } // on_action_quit


    /**
     * @brief Handles the about action.
     */
    private void on_action_about () 
    {
        var dialog = new AboutDialog (this);
        dialog.present ();
    } // on_action_about


    /**
     * @brief Toggles playback state.
     */
    public void on_toggle_playback() 
    {
        info (_("Stop Playback requested"));
        player_ctrl.play_pause ();
    } // on_toggle_playback


    /**
     * @brief Handles the disable tracking action.
     * @param action The SimpleAction that triggered this method.
     * @param parameter The parameter passed with the action (unused).
     */
    public void on_action_disable_tracking (SimpleAction action, Variant? parameter) 
    {
        settings.do_not_track = !settings.do_not_track;
        action.set_state (settings.do_not_track);
        debug (@"on_action_disable_tracking: $(settings.do_not_track)");
    } // on_action_disable_tracking


    /**
     * @brief Handles the enable autoplay action.
     * @param action The SimpleAction that triggered this method.
     * @param parameter The parameter passed with the action (unused).
     */
     public void on_action_enable_autoplay (SimpleAction action, Variant? parameter) 
     {
        settings.auto_play = !settings.auto_play;
        action.set_state (settings.auto_play);
        debug (@"on_action_enable_autoplay: $(settings.auto_play)");
    } // on_action_enable_autoplay


    /**
     * @brief Handles the enable autoplay action.
     * @param action The SimpleAction that triggered this method.
     * @param parameter The parameter passed with the action (unused).
     */
     public void on_action_start_on_starred (SimpleAction action, Variant? parameter) 
     {
        settings.start_on_starred = !settings.start_on_starred;
        action.set_state (settings.start_on_starred);
        debug (@"on_action_enable_autoplay: $(settings.auto_play)");
    } // on_action_enable_autoplay


    public void on_action_stream_info (SimpleAction action, Variant? parameter) 
    {
        settings.stream_info = !settings.stream_info;
        action.set_state (settings.stream_info);
        _headerbar.stream_info (action.get_state ().get_boolean ());
    } // on_action_enable_stream_info


    public void on_action_stream_info_fast (SimpleAction action, Variant? parameter) 
    {
        settings.stream_info_fast = !settings.stream_info_fast;
        action.set_state (settings.stream_info_fast);
        _headerbar.stream_info_fast (action.get_state ().get_boolean ());
    } // on_action_stream_info_fast



    // ----------------------------------------------------------------------
    //
    // Handlers
    //
    // ----------------------------------------------------------------------


	/**
	* @brief Handles a station selection and plays the station
	* @param station The selected station.
	*/
	public void handle_play_station (Model.Station station)
	{
		if ( app().is_offline || !_headerbar.update_playing_station(station) )
			return;                                                                                          // Online and not already changing station

        player_ctrl.station = station;
        _settings.last_played_station = station.stationuuid;
        _directory.count_station_click (station);

        set_title (WINDOW_NAME+": "+station.name);
    } // handle_station_click


    // ----------------------------------------------------------------------
    //
    // State management
    //
    // ----------------------------------------------------------------------

	/**
	* @brief Performs cleanup actions before the window is destroyed.
	* @return true if the window should be hidden instead of destroyed, false otherwise.
	*/
	public bool before_destroy ()
	{
        get_size (out _width, out _height); // Echo ending dimensions so Settings can pick them up
        _settings.save ();

        if (player_ctrl.player_state == PlayerController.Is.PLAYING) {
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
	* @brief Checks changes in online state and updates the app accordingly
	*
	*/
	private void check_online_status()
	{
		if (active && app().is_offline)
		/* Present Offline look */
		{
			this.accept_focus = false;
			active            = false;
		}

		if (!active && app().is_online)
		// Online but not active
		{
			this.accept_focus = true;
			active            = true;
		}
        _display.update_state (active, _start_on_starred );
    } // check_online_status
} // Window
