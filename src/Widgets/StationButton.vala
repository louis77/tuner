/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file StationBox.vala
 *
 * @brief Station representation
 */

/**
 * @class StationBox
 *
 * @brief A custom button widget representing a radio station.
 * 
 * The StationBox class extends the WelcomeButton class to create a specialized
 * button for displaying radio station information. It includes the station's
 * title, location, codec, bitrate, and favicon.
 * 
 * @extends Tuner.WelcomeButton
 */
public class Tuner.StationButton : Tuner.DisplayButton {


    private const string DEFAULT_ICON_NAME = "internet-radio";

    /**
     * @property station
     * @brief The radio station represented by this StationBox.
     */
    public Model.Station station { get; construct; }
   //public Gtk.Image favicon { get; construct; }
    //public Gtk.Image favicon_image { get; private set; }

    /**
     * @property menu
     * @brief The context menu associated with this StationBox.
     */
    public StationContextMenu menu { get; private set; }

    private Gtk.Overlay _overlay; // Declare an overlay

    /**
     * @brief Constructs a new StationBox instance.
     * @param station The radio station to represent.
     */
    public StationButton (Model.Station station) {
        Object (
            description: make_description (station.countrycode),
            title: make_title (station.name, station.starred),
            tag: make_tag (station.codec, station.bitrate),
            favicon_image: new Gtk.Image.from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG),
            station: station
        );

        //warning (@"StationBox faveicon $(_favicon == null)");
        //station.update_favicon_image.begin(_favicon_image);
    }

    /**
     * @brief Additional initialization for the StationBox.
     *
     * This method is automatically called after construction and sets up
     * the favicon, style context, and event handling for the StationBox.
     */
    construct {
        debug (@"StationBox construct $(station.name)");

        get_style_context().add_class("station-button");
        always_show_image = true;

        this.station.notify["starred"].connect ( (sender, prop) => {
            this.title = make_title (this.station.name, this.station.starred);
        });

        event.connect ((e) => {
            if (e.type == Gdk.EventType.BUTTON_PRESS && e.button.button == 3) {
                // Optimization:
                // Create menu on demand not on construction
                // because it is rarely used for all stations
                if (menu == null) {
                    menu = new StationContextMenu (this.station);
                    menu.attach_to_widget (this, null);
                    menu.show_all ();
                }

                menu.popup_at_pointer ();
                return true;
            }
            return false;
        });

        /*
            Set the button image. Connect to the flag that the Station has loaded the favicon
            and when it set, update the image. Check that if its already loaded, load now.
        */        
        station.notify["favicon-loaded"].connect((s, p) => {
            station.update_favicon_image.begin (_favicon_image);
        });
        if ( station.favicon_loaded > 0 ) 
        {
            station.update_favicon_image.begin (_favicon_image);
        }

        // Initialize the overlay
        _overlay = new Gtk.Overlay();
        add(_overlay); // Add the overlay to the window

        // Create your main content (e.g., Gtk.Paned)
        var primary_box = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
        _overlay.add(primary_box); // Add the primary box to the overlay

        // Show all widgets in the overlay
        _overlay.show_all();
    }


    /**
     * @brief Creates a title string for the station.
     * @param title The station's title.
     * @param starred Whether the station is starred (favorited).
     * @return The formatted title string.
     */
    private static string make_title (string title, bool starred) {
        if (!starred) return title;
        return Application.STAR_CHAR + title;
    }

    /**
     * @brief Creates a tag string combining codec and bitrate information.
     * @param codec The station's codec.
     * @param bitrate The station's bitrate.
     * @return The formatted tag string.
     */
    private static string make_tag (string codec, int bitrate) {
        var tag = codec;
        if (bitrate > 0)
        {
            tag = tag + " " + bitrate.to_string() + "k";
        }

        return tag;
    }

    /**
     * @brief Creates a description string based on the station's location.
     * @param location The station's location.
     * @return The formatted description string.
     */
    private static string make_description (string? location) {
        if ( location != null && location.length > 0) 
            return _(location);
        else
            return location;
    }

    /**
     * @brief Dims the window and its contents.
     * @param dim Whether to apply the dim effect (true) or remove it (false).
     */
    public void set_dim(bool dim) {
        if (dim) {
            // Create a dimming overlay
            var overlay = new Gtk.EventBox();
            overlay.set_size_request(get_allocated_width(), get_allocated_height());
            overlay.set_opacity(0.5); // Set the opacity to 50%
            overlay.set_sensitive(false); // Make it non-interactive
            _overlay.add_overlay(overlay); // Add the overlay to the Gtk.Overlay
        } else {
            // Remove the dimming overlay if it exists
            foreach (var child in _overlay.get_children()) {
                if (child is Gtk.EventBox) {
                    child.destroy(); // Remove the overlay
                }
            }
        }
    }
}