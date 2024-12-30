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

	public const string WINDOW_NAME             = "Tuner";
	public const string ACTION_PREFIX           = "win.";
	public const string ACTION_PAUSE            = "action_pause";
	public const string ACTION_QUIT             = "action_quit";
	public const string ACTION_HIDE             = "action_hide";
	public const string ACTION_ABOUT            = "action_about";
	public const string ACTION_DISABLE_TRACKING = "action_disable_tracking";
	public const string ACTION_ENABLE_AUTOPLAY  = "action_enable_autoplay";
	public const string ACTION_START_ON_STARRED = "action_starred_start";
	public const string ACTION_STREAM_INFO      = "action_stream_info";
	public const string ACTION_STREAM_INFO_FAST = "action_stream_info_fast";


	public Settings settings { get; construct; }
	public PlayerController player_ctrl { get; construct; }
	public DirectoryController directory { get; construct; }

    public bool active { get; private set; } // Window is active
    public int width { get; private set; }
    public int height { get; private set; }


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

	private signal void refresh_saved_searches_sig (bool add, string search_text);


    /* Construct Static*/
    static construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource (CSS);
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    } // static construct


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
        show_all ();

		application.set_accels_for_action (ACTION_PREFIX + ACTION_PAUSE, {"<Control>5"});
		application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q"});
		application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>w"});
	} // Window


    /* 
        Construct 
    */
    construct { 

		/*
		    Theme setup
		    Has to be done from Window
		 */
		GTK_SETTINGS                   = Gtk.Settings.get_default();
		GTK_ORIGINAL_THEME             = GTK_SETTINGS.gtk_theme_name;
		GTK_ORIGINAL_PREFER_DARK_THEME = GTK_SETTINGS.gtk_application_prefer_dark_theme;
		GTK_ALTERNATIVE_THEME          = GTK_ORIGINAL_THEME;
		if (GTK_ALTERNATIVE_THEME.has_suffix("-dark"))
		{
			debug(@"Dark system");
			GTK_DEFAULT_THEME_IS_DARK = true;
			GTK_ALTERNATIVE_THEME     = GTK_ALTERNATIVE_THEME.slice(0,-5);
		}

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

        // Auto-play
        if (_settings.auto_play) 
        {
            warning (@"Auto-play enabled");
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

        /*
            Online checks & behavior

            Keep in mind that network availability is noisy
        */
        app().notify["is-online"].connect(() => 
        {
            check_online_status();
        });
    } // construct


    /**
     * Selects and displays the user's starred (favorite) radio stations.
     * 
     * This method handles the process of showing the user's favorite stations
     * in the station list view. It filters and displays only the stations that
     * have been marked as favorites by the user.
     */
	public void choose_starred_stations()
	{
		if (_active)
			_display.choose_starred_stations();
	} // choose_star


    /**
        Add widgets after Window creation
    */
    private void add_widgets()
    {
        /*
            Headerbar hookups
        */
        _headerbar = new HeaderBar (this);

        _headerbar.search_has_focus_sig.connect (() => 
        // Show searched stack when cursor hits search text area
        {
            _display.search_focused_sig( );
        });

        _headerbar.searching_for_sig.connect ( (text) => 
        // process the searched text, stripping it, and sensitizing the save 
        // search star depending on if the search is already saved
        {
            _display.searched_for_sig( text);
        });

		set_titlebar (_headerbar);

        /*
            Display
        */
        _display = new Display(directory);  
        _display.station_clicked_sig.connect (handle_play_station);  // Station clicked -> change station     
        add (_display);
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
		if (app().is_offline || !_headerbar.update_playing_station(station))
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

        _display.update_state (active);
    } // check_online_status
} // Window
