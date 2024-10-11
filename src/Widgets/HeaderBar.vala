/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class Tuner.HeaderBar
 * @brief Custom header bar for the Tuner application.
 *
 * This class extends Gtk.HeaderBar to create a specialized header bar
 * with play/pause controls, volume control, station information display,
 * search functionality, and preferences menu.
 *
 * @extends Gtk.HeaderBar
 */
public class Tuner.HeaderBar : Gtk.HeaderBar {

    // Default icon name for stations without a custom favicon
    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";

    /**
     * @enum PlayState
     * @brief Enumeration of possible play states for the play button.
     */
    public enum PlayState {
        PAUSE_ACTIVE,
        PAUSE_INACTIVE,
        PLAY_ACTIVE,
        PLAY_INACTIVE
    }

    // Public properties
    public Gtk.Button play_button { get; set; }
    public Gtk.VolumeButton volume_button;

    // Private member variables
    private Gtk.Button star_button;
    private bool _starred = false;
    private Model.Station _station;
    private Gtk.Label _title_label;
    private RevealLabel _subtitle_label;
    private Gtk.Image _favicon_image;

    // Signals
    public signal void star_clicked (bool starred);
    public signal void searched_for (string text);
    public signal void search_focused ();
    
    // Search-related variables
    private int search_delay = 250; // search delay in milliseconds (ms)
    private uint delayed_changed_id;
    private string searchentry_text = "";

    /**
     * @brief Reset the search timeout.
     *
     * This method removes any existing timeout and sets a new one for delayed search.
     */
    private void reset_timeout(){
        if(delayed_changed_id > 0)
            Source.remove(delayed_changed_id);
        delayed_changed_id = Timeout.add(search_delay, timeout);
    }

    /**
     * @brief Timeout function for delayed search.
     *
     * This method is called when the search delay timeout expires.
     *
     * @return bool Returns false to stop the timeout.
     */
    private bool timeout(){
        // perform search
        searched_for (searchentry_text);
        delayed_changed_id = 0;
        return false;
    }

    /**
     * @brief Construct block for initializing the header bar components.
     *
     * This method sets up all the UI elements of the header bar, including
     * station info display, play button, preferences button, search entry,
     * star button, and volume button.
     */
    construct {
        show_close_button = true;

        // Create and configure station info display
        var station_info = new Gtk.Grid ();
        station_info.width_request = 200;
        station_info.column_spacing = 10;

        _title_label = new Gtk.Label (_("Choose a station"));
        _title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        _title_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
        _subtitle_label = new RevealLabel ();
        _favicon_image = new Gtk.Image.from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG);

        station_info.attach (_favicon_image, 0, 0, 1, 2);
        station_info.attach (_title_label, 1, 0, 1, 1);
        station_info.attach (_subtitle_label, 1, 1, 1, 1);

        custom_title = station_info;

        // Create and configure play button
        play_button = new Gtk.Button ();
        play_button.valign = Gtk.Align.CENTER;
        play_button.action_name = Window.ACTION_PREFIX + Window.ACTION_PAUSE;
        pack_start (play_button);

        // Create and configure preferences button
        var prefs_button = new Gtk.MenuButton ();
        prefs_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        prefs_button.valign = Gtk.Align.CENTER;
        prefs_button.sensitive = true;
        prefs_button.tooltip_text = _("Preferences");
        prefs_button.popover = new Tuner.PreferencesPopover();;
        pack_end (prefs_button);

        // Create and configure search entry
        var searchentry = new Gtk.SearchEntry ();
        searchentry.valign = Gtk.Align.CENTER;
        searchentry.placeholder_text = _("Station name");
        searchentry.changed.connect (() => {
            searchentry_text = searchentry.text;
            reset_timeout();
        });
        searchentry.focus_in_event.connect ((e) => {
            search_focused ();
            return true;
        });
        pack_end (searchentry);

        // Create and configure star button
        star_button = new Gtk.Button.from_icon_name (
            "non-starred",
            Gtk.IconSize.LARGE_TOOLBAR
        );
        star_button.valign = Gtk.Align.CENTER;
        star_button.sensitive = true;
        star_button.tooltip_text = _("Star this station");
        star_button.clicked.connect (() => {
            star_clicked (starred);
        });
        pack_start (star_button);

        // Create and configure volume button
        volume_button = new Gtk.VolumeButton ();
        volume_button.value = Application.instance.settings.get_double ("volume");
        volume_button.value_changed.connect ((value) => {
            Application.instance.settings.set_double ("volume", value);
        });
        pack_start (volume_button);

        set_playstate (PlayState.PAUSE_INACTIVE);
    }

    // Properties for title and subtitle
    public new string title {
        get { return _title_label.label; }
        set { _title_label.label = value; }
    }

    public new string subtitle {
        get { return _subtitle_label.label; }
        set { _subtitle_label.label = value; }
    }

    public Gtk.Image favicon {
        get { return _favicon_image; }
        set { _favicon_image = value; }
    }

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
     * @param station The new station to display information for.
     */
    public void update_from_station (Model.Station station) {
        if (_station != null) {
            _station.notify.disconnect (handle_station_change);
        }
        _station = station;
        _station.notify.connect ( (sender, property) => {
            handle_station_change ();
        });
        title = station.title;
        subtitle = _("Playing");
        load_favicon (station); 
        starred = station.starred;
    }

    // Property for starred state
    private bool starred {
        get { return _starred; }
        set {
            _starred = value;
            if (!_starred) {
                star_button.image = new Gtk.Image.from_icon_name ("non-starred", Gtk.IconSize.LARGE_TOOLBAR);
            } else {
                star_button.image = new Gtk.Image.from_icon_name ("starred", Gtk.IconSize.LARGE_TOOLBAR);
            }
        }
    }


    /**
     * @brief Set the play state of the header bar.
     *
     * This method updates the play button icon and sensitivity based on the new play state.
     *
     * @param state The new play state to set.
     */
    public void set_playstate (PlayState state) {
        switch (state) {
            case PlayState.PLAY_ACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-start-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = true;
                star_button.sensitive = true;
                break;
            case PlayState.PLAY_INACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-start-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = false;
                star_button.sensitive = false;
                break;
            case PlayState.PAUSE_ACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-stop-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = true;
                star_button.sensitive = true;
                break;
            case PlayState.PAUSE_INACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-stop-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = false;
                star_button.sensitive = false;
                break;
        }
    }

    /**
     * @brief Load and display the favicon for a station.
     *
     * This method asynchronously loads the favicon anew for 
     * the given station and updates the favicon image.
     *
     * @param station The station whose favicon should be loaded.
     */
    private void load_favicon(Model.Station station)
    {
        Favicon.load_async.begin (station, true, (favicon, res) => {
            var pxbuf = Favicon.load_async.end (res);
            if (pxbuf != null) {
                this.favicon.set_from_pixbuf (pxbuf);  
            } else {
                // If favicon is not available, use default icon
                this.favicon.set_from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG);
            }
            this.favicon.set_size_request (48, 48);
        });
    }
}