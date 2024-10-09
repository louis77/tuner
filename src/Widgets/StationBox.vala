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

    // Default icon name for stations without a custom favicon
    private const string DEFAULT_ICON_NAME = "internet-radio";

    // Public properties for the station and its context menu
    public Model.Station station { get; construct; }
    public StationContextMenu menu { get; private set; }

    /**
     * Constructor for the StationBox
     * @param station The radio station to represent
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
     * Construct block for additional initialization
     */
    construct {
        warning (@"StationBox construct $(station.title)");

        //new Thread(load_favicon());
        new Thread<void>("station-box", load_favicon);


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

    private static string make_title (string title, bool starred) {
        if (!starred) return title;
        return Application.STAR_CHAR + title;
    }

    private static string make_tag (string codec, int bitrate) {
        var tag = codec;
        if (bitrate > 0)
        {
            tag = tag + " " + bitrate.to_string() + "k";
        }

        return tag;
    }

    private static string make_description (string location) {
        if (location.length > 0) 
            return _(location);
        else
            return location;
    }

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
