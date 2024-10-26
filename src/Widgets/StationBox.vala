/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class StationBox
 * @brief A custom button widget representing a radio station.
 * 
 * The StationBox class extends the WelcomeButton class to create a specialized
 * button for displaying radio station information. It includes the station's
 * title, location, codec, bitrate, and favicon.
 * 
 * @extends Tuner.WelcomeButton
 */
public class Tuner.StationBox : Tuner.WelcomeButton {

    /**
     * @brief Default icon name for stations without a custom favicon.
     */
    private const string DEFAULT_ICON_NAME = "internet-radio";

    /**
     * @property station
     * @brief The radio station represented by this StationBox.
     */
    public Model.Station station { get; construct; }

    /**
     * @property menu
     * @brief The context menu associated with this StationBox.
     */
    public StationContextMenu menu { get; private set; }

    /**
     * @brief Constructs a new StationBox instance.
     * @param station The radio station to represent.
     */
    public StationBox (Model.Station station) {
        Object (
            description: make_description (station.location),
            title: make_title (station.title, station.starred),
            tag: make_tag (station.codec, station.bitrate),
            favicon: new Gtk.Image.from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG),
            station: station
        );
    }

    /**
     * @brief Additional initialization for the StationBox.
     *
     * This method is automatically called after construction and sets up
     * the favicon, style context, and event handling for the StationBox.
     */
    construct {
        debug (@"StationBox construct $(station.title)");

        load_favicon();

        get_style_context().add_class("station-button");
        always_show_image = true;

        this.station.notify["starred"].connect ( (sender, prop) => {
            this.title = make_title (this.station.title, this.station.starred);
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
    private static string make_description (string location) {
        if (location.length > 0) 
            return _(location);
        else
            return location;
    }

    /**
     * @brief Asynchronously loads the station's favicon.
     *
     * This method attempts to load the station's custom favicon and
     * updates the StationBox's icon if successful.
     */
    private void load_favicon()
    {
        Favicon.load_async.begin (station, false, (favicon, res) => {
            var pxbuf = Favicon.load_async.end (res);
            if (pxbuf != null) {
                this.favicon.set_from_pixbuf (pxbuf);  
                this.favicon.set_size_request (48, 48);  
            }
        });
    }

}
