/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file HeaderBar.vala
 *
 * @brief HeaderBar classes
 *
 */

using Gtk;

/*
 * @class Tuner.HeaderBar
 *
 * @brief Custom header bar that centrally displays station info and
 * packs app controls either side.
 *
 * This class extends HeaderBar to create a specialized header bar
 * with play/pause controls, volume control, station information display,
 * search functionality, and preferences menu.
 *
 * @extends HeaderBar
 */
public class Tuner.HeaderBar : Gtk.HeaderBar
{

    /* Constants    */

    // Default icon name for stations without a custom favicon
    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";

	// Search delay in milliseconds
	private const int SEARCH_DELAY = 400;

	// Search delay in milliseconds
	private const uint REVEAL_DELAY = 400u;

	private static Image STAR   = new Image.from_icon_name ("starred", IconSize.LARGE_TOOLBAR);
	private static Image UNSTAR = new Image.from_icon_name ("non-starred", IconSize.LARGE_TOOLBAR);


    /* Public */


    // Public properties

    // Signals
    public signal void searching_for_sig (string text);
    public signal void search_has_focus_sig ();


    /*
        Private 
    */


	protected static Image FAVICON_IMAGE = new Image.from_icon_name (DEFAULT_ICON_NAME, IconSize.DIALOG);

	private const string STREAM_METADATA = _("Stream Metadata");

	/*
		main display assets
	*/
	private Fixed _tuner        = new Fixed();
	private Button _star_button = new Button.from_icon_name (
		"non-starred",
		IconSize.LARGE_TOOLBAR
		);
	private PlayButton _play_button  = new PlayButton ();
	private MenuButton _prefs_button = new MenuButton ();
	private SearchEntry _search_entry = new SearchEntry ();
	private ListButton _list_button  = new ListButton.from_icon_name ("mark-location-symbolic", IconSize.LARGE_TOOLBAR);

	/*
		secondary display assets
	*/
	private Overlay _tuner_icon = new Overlay();
	private Image _tuner_on     = new Image.from_icon_name("tuner-on", IconSize.DIALOG);

    // data and state variables

	private Model.Station _station;
	private Mutex _station_update_lock = Mutex();       // Lock out concurrent updates
	private bool _station_locked       = false;
	private ulong _station_handler_id  = 0;

    private VolumeButton _volume_button = new VolumeButton();
    
    // Search-related variables
    private uint _delayed_changed_id;
    private string _searchentry_text = "";

	private PlayerInfo _player_info;

	/** @property {bool} starred - Station starred. */
	private bool _starred = false;
	private bool starred {
		get { return _starred; }
		set {
			_starred = value;
			if (!_starred)
			{
				_star_button.image = UNSTAR;
			}
			else
			{
				_star_button.image = STAR;
			}
		}
	}     // starred


    /**
     * @brief Construct block for initializing the header bar components.
     *
     * This method sets up all the UI elements of the header bar, including
     * station info display, play button, preferences button, search entry,
     * star button, and volume button.
     */
    public HeaderBar(Window window)
    {
        Object();

        /*
            LHS Controls
        */        

        // Tuner icon
        _tuner_icon.add(new Image.from_icon_name("tuner-off", IconSize.DIALOG));
        _tuner_icon.add_overlay(_tuner_on);
        _tuner_icon.valign = Align.START;

		_tuner.add(_tuner_icon);
		_tuner.set_valign(Align.CENTER);
		_tuner.set_margin_bottom(5);   // 20px padding on the right
		_tuner.set_margin_start(5);   // 20px padding on the right
		_tuner.set_margin_end(5);   // 20px padding on the right
		_tuner.tooltip_text = _("Data Provider");
		_tuner.query_tooltip.connect((x, y, keyboard_tooltip, tooltip) =>
		{
			if (app().is_offline)
				return false;
			tooltip.set_text(_(@"Data Provider: $(window.directory.provider())"));
			return true;
		});

        // Volume
        _volume_button.set_valign(Align.CENTER);
        _volume_button.value_changed.connect ((value) => {
            app().player.volume = value;
        });
        app().player.volume_changed_sig.connect((value) => {
            _volume_button.value =  value;
        });


		// Star button
		_star_button.valign       = Align.CENTER;
		_star_button.sensitive    = true;
		_star_button.tooltip_text = _("Star this station");
		_star_button.clicked.connect (() => 
		{
			if (_station == null)
				return;
			_station.starred = !_starred;
			starred          =_station.starred;
		});


		//
		// Create and configure play button
		//
		_play_button.valign      = Align.CENTER;
		_play_button.action_name = Window.ACTION_PREFIX + Window.ACTION_PAUSE; // Toggles player state

       
        /*
            RHS Controls
        */     

		// Search entry
		_search_entry.valign           = Align.CENTER;
		_search_entry.placeholder_text = _("Station name");

		_search_entry.changed.connect (() => {
			_searchentry_text = _search_entry.text;
			reset_search_timeout();
		});

		_search_entry.focus_in_event.connect ((e) => {
			search_has_focus_sig ();
			return true;
		});

		// Preferences button
		_prefs_button.image  = new Image.from_icon_name ("open-menu", IconSize.LARGE_TOOLBAR);
		_prefs_button.valign = Align.CENTER;
		//  _prefs_button.sensitive = true;
		_prefs_button.tooltip_text = _("Preferences");
		_prefs_button.popover      = new Tuner.PreferencesPopover();

		_list_button.valign       = Align.CENTER;
		_list_button.tooltip_text = _("History");

       /*
            Layout
        */

       // pack LHS
        pack_start (_tuner);
        pack_start (_volume_button);
        pack_start (_star_button);
        pack_start (_play_button);

        _player_info = new PlayerInfo(window);
        custom_title = _player_info; // Station display

		// pack RHS
		pack_end (_prefs_button);
		pack_end (_list_button);

		/* Test fixture */
		//  private Button _off_button       = new Button.from_icon_name ("list-add", IconSize.LARGE_TOOLBAR);
		//  pack_end (_off_button);
		//  _off_button.clicked.connect (() => {
		//  	app().is_online = !app().is_online;
		//  });

		pack_end (_search_entry);
		show_close_button = true;


		/*
		    Tuner icon and online/offline behavior
		 */
		app().notify["is-online"].connect(() => {
			check_online_status();
		});

        check_online_status();

		/*
		    Hook up title to metadata as tooltip
		 */
		custom_title.tooltip_text = STREAM_METADATA;
		custom_title.query_tooltip.connect((x, y, keyboard_tooltip, tooltip) =>
		{
			if (_station == null)
				return false;
			tooltip.set_text(_(@"Votes: $(_station.votes)\t Clicks: $(_station.clickcount)\t Trend: $(_station.clicktrend)\n\n$(_player_info.metadata)"));
			return true;
		});

		_player_info.info_changed_completed_sig.connect(() =>
		                                                // _player_info is going to signal when it has completed and the lock can be released
		{
			if (!_station_locked)
				return;
			_station_update_lock.unlock();
			_station_locked = false;
		});


		app().player.metadata_changed_sig.connect ((metadata) =>
		{
			_list_button.append_station_title_pair(_station, metadata.title);
		});

		_list_button.item_station_selected_sig.connect((station) =>
		{
			window.handle_play_station(station);
		});

	} // HeaderBar


    /* 
        Public 
    */


	/**
	* @brief Update the header bar with information from a new station.
	*
	* Requires a lock so that too many clicks do not cause a race condition
	*
	* @param station The new station to display information for.
	*/
	public bool update_playing_station(Model.Station station)
	{
		if (app().is_offline || _station == station)
			return false;

		if (_station_update_lock.trylock())
		// Lock while changing the station to ensure single threading.
		// Lock is released when the info is updated on emit of info_changed_completed_sig
		{
			_station_locked       = true;
			_player_info.metadata = STREAM_METADATA;

			Idle.add (() =>
			          // Initiate the fade out on a non-UI thread
			{

				if (_station_handler_id > 0)
				// Disconnect the old station starred handler
				{
					_station.disconnect(_station_handler_id);
					_station_handler_id = 0;
				}

				_player_info.change_station.begin(station, () =>
				{

			warning(@"change_station Starring $(station.name) $(station.starred)");
					_station            = station;
					starred             = _station.starred;
					_station_handler_id = _station.station_star_sig.connect((starred) => 
					{
						this.starred = starred;
					});
				});

				return Source.REMOVE;
			},Priority.HIGH_IDLE);

			return true;
		} // if
		return false;
	} // update_playing_station


	/**
	* @brief Override of the realize method from Widget for an initial animation
	*
	* Called when the widget is being realized (created and prepared for display).
	* This happens before the widget is actually shown on screen.
	*/
	public override void realize()
	{
		base.realize();

		_player_info.transition_type = RevealerTransitionType.SLIDE_UP; // Optional: add animation
		_player_info.set_transition_duration(REVEAL_DELAY*3);

		// Use Timeout to delay the reveal animation
		Timeout.add(REVEAL_DELAY*3, () => {
			_player_info.set_reveal_child(true);
			return Source.REMOVE;
		});
	}     // realize


    /**
     */
    public void stream_info(bool show)
    {
        _player_info.title_label.show_metadata = show;        
    } // stream_info


    /**
     */
    public void stream_info_fast(bool fast)
    {
        _player_info.title_label.metadata_fast_cycle = fast;          
    } // stream_info_fast


	/*
		Private
	*/
	
	/**
	* @brief Checks and sets per the online status
	*
	* Desensitive when off-line
	*/
	private void check_online_status()
	{
		if (app().is_offline)
		{
			_player_info.favicon_image.opacity = 0.5;
			_tuner_on.opacity                  = 0.0;
			_star_button.sensitive             = false;
			_play_button.sensitive             = false;
			_play_button.opacity               = 0.5;
			_volume_button.sensitive           = false;
			_list_button.sensitive             = false;
			_search_entry.sensitive             = false;

		}
		else
		{
			_player_info.favicon_image.opacity = 1.0;
			_tuner_on.opacity                  = 1.0;
			_star_button.sensitive             = true;
			_play_button.sensitive             = true;
			_play_button.opacity               = 1.0;
			_volume_button.sensitive           = true;
			_list_button.sensitive             = true;
			_search_entry.sensitive             = true;
		}
	}     // check_online_status


    /**
    * @brief Reset the search timeout.
    *
    * This method removes any existing timeout and sets a new one for delayed search.
    */
    private void reset_search_timeout()
    {
        if(_delayed_changed_id > 0)
            Source.remove(_delayed_changed_id);

        _delayed_changed_id = Timeout.add(SEARCH_DELAY, () => 
        {                   
            _delayed_changed_id = 0; // Reset timeout ID after scheduling               
            searching_for_sig (_searchentry_text); // Emit the custom signal with the search query
            return Source.REMOVE;
        });
    } // reset_search_timeout


    /**
     * @brief Custom PlayerInfo for the HeadeBar based on Revealer
     * 
     * This is the PlayerInfo for the Player.
     */
    private class PlayerInfo : Revealer
    {
        public Label station_label { get; private set; }
        public CyclingRevealLabel title_label { get; private set; }
        public StationContextMenu menu { get; private set; }    
        public Image favicon_image = new Image.from_icon_name (DEFAULT_ICON_NAME, IconSize.DIALOG);
        public string metadata { get; internal set; }

        private Model.Station _station;
        private uint grid_min_width = 0;

        internal signal void info_changed_completed_sig ();
        


		/**
		 * Creates a new PlayerInfo widget.
		 * 
		 * @param window The parent window this header bar belongs to
		 *
		 * @since 1.0
		 */
        public PlayerInfo(Window window)
        {
            Object();

			transition_duration = REVEAL_DELAY;
			transition_type     = RevealerTransitionType.CROSSFADE;

			station_label = new Label ( "Tuner" );
			station_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
			station_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

			title_label                     = new CyclingRevealLabel (window,100);
			title_label.halign              = Align.CENTER;
			title_label.valign              = Align.CENTER;
			title_label.show_metadata       = window.settings.stream_info;
			title_label.metadata_fast_cycle =window.settings.stream_info_fast;

			var station_grid = new Grid ();
			station_grid.column_spacing = 10;
			station_grid.set_halign(Align.FILL);
			station_grid.set_valign(Align.CENTER);

			station_grid.attach (favicon_image, 0, 0, 1, 2);
			station_grid.attach (station_label, 1, 0, 1, 1);
			station_grid.attach (title_label, 1, 1, 1, 1);

			station_grid.size_allocate.connect((allocate) =>
			{
				if (grid_min_width == 0)
					grid_min_width = allocate.width;
			});

			add(station_grid);
			reveal_child = false;     // Make it invisible initially

			metadata = STREAM_METADATA;
			app().player.metadata_changed_sig.connect (handle_metadata_changed);

        } // PlayerInfo


        /**
        * @brief Handles display transition as station is changed
        *
        * Desensitive when off-line
        */
        internal async void change_station( Model.Station station )
        {
            reveal_child = false;

			Idle.add(() =>
			{
				Timeout.add (5*REVEAL_DELAY/3, () =>
				             // Clear the info well after the fade has completed
				{
					favicon_image.clear();
					title_label.clear();
					station_label.label = "";
					_metadata           = STREAM_METADATA;
					return Source.REMOVE;
				});

				Timeout.add (5*REVEAL_DELAY/2, () =>
				             // Redisplay after fade out and clear have completed
				{
					station.update_favicon_image.begin(favicon_image, true, DEFAULT_ICON_NAME,() =>
					{
						_station            = station;
						station_label.label = station.name;
						reveal_child        = true;
						title_label.cycle();

						info_changed_completed_sig();
					});
					return Source.REMOVE;
				});
				return Source.REMOVE;
			}, Priority.HIGH_IDLE);
		}         // change_station


		/**
		* @brief Processes changes to stream metadata as they come in
		*
		* Desensitive when off-line
		*/
		public void handle_metadata_changed ( PlayerController.Metadata metadata )
		{
			if (_metadata == metadata.pretty_print)
				return;                                                                  // No change

            _metadata = metadata.pretty_print;
            // Empty metadata stream
            if ( _metadata == "" ) 
            {
                _metadata = STREAM_METADATA;
                return;
            }

            //  title_label.set_text( metadata.title );
            title_label.add_sublabel(1, metadata.genre,metadata.homepage);
            title_label.add_sublabel(2,metadata.audio_info);
            title_label.add_sublabel( 3, (metadata.org_loc) );
            
            if ( !title_label.set_text( metadata.title ) )
            {
                Timeout.add_seconds (3, () => 
                // Redisplay after fade out and clear have completed
                {                
                    title_label.set_text( metadata.title );
                    return Source.REMOVE;
                });   
            } // if
        } // handle_metadata_changed
    } // PlayerInfo
} // Tuner.HeaderBar
