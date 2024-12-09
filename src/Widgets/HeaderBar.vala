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

 /*
 * @class Tuner.HeaderBar
 *
 * @brief Custom header bar that centrally displays station info and 
 * packs app controls either side. 
 *
 * This class extends Gtk.HeaderBar to create a specialized header bar
 * with play/pause controls, volume control, station information display,
 * search functionality, and preferences menu.
 *
 * @extends Gtk.HeaderBar
 */
public class Tuner.HeaderBar : Gtk.HeaderBar {

    /* Constants    */

    // Default icon name for stations without a custom favicon
    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";

    // Search delay in milliseconds
    private const int SEARCH_DELAY = 400; 

    // Search delay in milliseconds
    private const uint REVEAL_DELAY = 400u; 

    private static Gtk.Image STAR = new Gtk.Image.from_icon_name ("starred", Gtk.IconSize.LARGE_TOOLBAR);
    private static Gtk.Image UNSTAR = new Gtk.Image.from_icon_name ("non-starred", Gtk.IconSize.LARGE_TOOLBAR);


    /* Public */


    // Public properties
    private Gtk.VolumeButton _volume_button = new Gtk.VolumeButton();

    // Signals
    public signal void star_clicked_sig (bool starred);
    public signal void searched_for_sig (string text);
    public signal void search_focused_sig ();

    /*
        Private 
    */


    protected static Gtk.Image FAVICON_IMAGE = new Gtk.Image.from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG);

    /* 
        main display assets 
    */
    private Gtk.Box _tuner = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    private Gtk.Button _star_button = new Gtk.Button.from_icon_name (
        "non-starred",
        Gtk.IconSize.LARGE_TOOLBAR
    );
    private PlayButton _play_button = new PlayButton ();
    private Gtk.MenuButton _prefs_button = new Gtk.MenuButton ();
    private Gtk.SearchEntry _searchentry = new Gtk.SearchEntry ();

    /* 
        secondary display assets 
    */
    private Gtk.Overlay _tuner_icon = new Gtk.Overlay();
    private Gtk.Image _tuner_on = new Gtk.Image.from_icon_name("tuner-on", Gtk.IconSize.DIALOG);

    // data and state variables

    private bool _starred = false;
    private Model.Station _station;
    private Mutex _station_update_lock = Mutex();   // Lock out concurrent updates

    
    // Search-related variables
    private uint _delayed_changed_id;
    private string _searchentry_text = "";

    private Display _display = new Display();


    /**
     * @brief Construct block for initializing the header bar components.
     *
     * This method sets up all the UI elements of the header bar, including
     * station info display, play button, preferences button, search entry,
     * star button, and volume button.
     */
    construct 
    {
        /*
            LHS Controls
        */        

        // Tuner icon
        _tuner_icon.add(new Gtk.Image.from_icon_name("tuner-off", Gtk.IconSize.DIALOG));
        _tuner_icon.add_overlay(_tuner_on);
        _tuner_icon.valign = Gtk.Align.START;

        _tuner.add(_tuner_icon);
        _tuner.set_valign(Gtk.Align.CENTER);
        _tuner.set_margin_bottom(5);   // 20px padding on the right
        _tuner.set_margin_start(5);   // 20px padding on the right
        _tuner.set_margin_end(5);   // 20px padding on the right

        // Volume
        _volume_button.set_valign(Gtk.Align.CENTER);
        _volume_button.value_changed.connect ((value) => {
            app().player.volume = value;
        });
        app().player.volume_changed_sig.connect((value) => {
            _volume_button.value =  value;
        });


        // Star button
        _star_button.valign = Gtk.Align.CENTER;
        _star_button.sensitive = true;
        _star_button.tooltip_text = _("Star this station");
        _star_button.clicked.connect (() => {
            star_clicked_sig (starred);     // FIXME refresh faves?
        });
     
       
        //
        // Create and configure play button
        //
        _play_button.valign = Gtk.Align.CENTER;
        _play_button.action_name = Window.ACTION_PREFIX + Window.ACTION_PAUSE; // Toggles player state

       
        /*
            RHS Controls
        */     

        // Search entry
        _searchentry.valign = Gtk.Align.CENTER;
        _searchentry.placeholder_text = _("Station name");

        _searchentry.changed.connect (() => {
            _searchentry_text = _searchentry.text;
            reset_search_timeout();
        });

        _searchentry.focus_in_event.connect ((e) => {
            search_focused_sig ();
            return true;
        });
        
        // Preferences button
        _prefs_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        _prefs_button.valign = Gtk.Align.CENTER;
        _prefs_button.sensitive = true;
        _prefs_button.tooltip_text = _("Preferences");
        _prefs_button.popover = new Tuner.PreferencesPopover();


       /*
            Layout
        */

       // pack LHS
        pack_start (_tuner);
        pack_start (_volume_button);
        pack_start (_star_button);
        pack_start (_play_button);

        custom_title = _display; // Station display

        // pack RHS
        pack_end (_prefs_button);
        pack_end (_searchentry);

        show_close_button = true;

        /*
            Tuner icon and online/offline behavior    
        */
        app().notify["is-online"].connect(() => {
            check_online_status();
        });      

        check_online_status();
    } // construct


    /* 
        Public 
    */

    /**
     * @brief Handle changes in the current station.
     *
     * This method updates the starred state when the current station changes.
     */
    public void handle_station_change () {
        starred = _station.starred;
    }

    /**
     * @brief Update the header bar with information from a new station.
     *
     * Requires a lock so that too many clicks do not cause a race condition
     *
     * @param station The new station to display information for.
     */
     public async void update_from_station(Model.Station station) 
     {
        if (app().is_offline) return;
        
        if (_station_update_lock.trylock())
        // Lock while changing the station to ensure single threading
        {
            try {        
                // Disconnect previous station signals if any
                if (_station != null) {
                    _station.notify.disconnect(handle_station_change);
                }
        
                yield _display.station_change(station);

                _station = station;
                _station.notify.connect(handle_station_change);    
                starred = _station.starred;
            }
            finally 
            {
                _station_update_lock.unlock();
            }
        }
    } // update_from_station
    


    /**
     * @brief Override of the realize method from Gtk.Widget for an initial animation
     * 
     * Called when the widget is being realized (created and prepared for display).
     * This happens before the widget is actually shown on screen.
     */
    public override void realize() {
        base.realize();
        
        _display.transition_type = Gtk.RevealerTransitionType.SLIDE_UP; // Optional: add animation        
        _display.set_transition_duration(REVEAL_DELAY*3);

        // Use Timeout to delay the reveal animation
        Timeout.add(REVEAL_DELAY*3, () => {
            _display.set_reveal_child(true);
            return Source.REMOVE;
        });
    } // realize


    /* 
        Private 
    */

    /**
     * @brief Custom Display for the HeadeBar based on Revealer
     * 
     * This is the Display for the Player.
     */
    private class Display : Gtk.Revealer
    {
        public Gtk.Label station_label { get; private set; }
        public CyclingRevealLabel title_label { get; private set; }
    
        public Gtk.Image favicon_image = new Gtk.Image.from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG);

        /**
         */
        construct 
        {
            station_label = new Gtk.Label (_("Choose a station"));
            station_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            station_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            title_label = new CyclingRevealLabel ();
           
            var station_info = new Gtk.Grid ();
            station_info.width_request = 200;
            station_info.column_spacing = 10;

            station_info.attach (favicon_image, 0, 0, 1, 2);
            station_info.attach (station_label, 1, 0, 1, 1);
            station_info.attach (title_label, 1, 1, 1, 1);

            add(station_info);
            reveal_child = false; // Make it invisible initially

            app().player.metadata_changed_sig.connect(handle_metadata_changed);
    
        }

        /**
         */
        public async void station_change( Model.Station station )
        {
            transition_duration = REVEAL_DELAY;
            transition_type = Gtk.RevealerTransitionType.CROSSFADE;

            reveal_child = false;
            title_label.stop();

            // Begin favicon update (non-blocking)
            yield station.update_favicon_image(favicon_image, true, DEFAULT_ICON_NAME);
            station_label.label = "";
            title_label.label = "";
            hide();   // Waits for reveal to be hiden

            station_label.label = station.name;
            //  // subtitle = "Buffering";

            show();              
            reveal_child = true;

            title_label.cycle();
        }

        public void handle_metadata_changed ( PlayerController.Metadata metadata )
        {
            title_label.label = metadata.title;
            title_label.add_sublabel(1, @"$(metadata.genre)  $(metadata.homepage)");
            title_label.add_sublabel(2,@"$(metadata.audio_codec)  $(metadata.bitrate/1000)K  $(metadata.channel_mode)");
            title_label.add_sublabel( 3, @"$(metadata.organization)  $(metadata.location)");
        }
    }

    /**
     * @brief Checks and sets per the online status
     *
     * Desensitive when off-line
     */
    private void check_online_status()
    {
        if (app().is_offline) {
            _display.favicon_image.opacity = 0.5;
            _tuner_on.opacity = 0.0;
            _star_button.sensitive = false;
            _play_button.sensitive = false;
            _volume_button.sensitive = false;
        }
        else
        {
            _display.favicon_image.opacity = 1.0;
            _tuner_on.opacity = 1.0;
            _star_button.sensitive = true;
            _play_button.sensitive = true;
            _volume_button.sensitive = true;
        }
    } // check_online_status


    /**
     * @brief Reset the search timeout.
     *
     * This method removes any existing timeout and sets a new one for delayed search.
     */
     private void reset_search_timeout(){
        if(_delayed_changed_id > 0)
            Source.remove(_delayed_changed_id);

            _delayed_changed_id = Timeout.add(SEARCH_DELAY, () => {                   
                _delayed_changed_id = 0; // Reset timeout ID after scheduling               
                searched_for_sig (_searchentry_text); // Emit the custom signal with the search query
                return Source.REMOVE;
            });
    } // reset_search_timeout


    // Property for starred state
    private bool starred {
        get { return _starred; }
        set {
            _starred = value;
            if (!_starred) {
                _star_button.image = UNSTAR;
            } else {
                _star_button.image = STAR;
            }
        }
    } // starred
}
