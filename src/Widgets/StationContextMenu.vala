/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class StationContextMenu
 * @brief A context menu for radio stations.
 *
 * This class represents a context menu that appears when interacting with a radio station.
 * It provides options such as visiting the station's website, copying the stream URL,
 * and starring/unstarring the station.
 *
 * @extends Gtk.Menu
 */
public class Tuner.StationContextMenu : Gtk.Menu {
    /**
     * @property station
     * @brief The radio station associated with this context menu.
     */
    public Model.Station station { get; construct; }

    /**
     * @brief Constructs a new StationContextMenu.
     * @param station The radio station for which this menu is created.
     */
    public StationContextMenu (Model.Station station) {
        Object (
            station: station
        );
    }

    /**
     * @brief Initializes the menu items and sets up event handlers.
     */
    construct {
        var label = new Gtk.MenuItem.with_label (this.station.name);
        label.sensitive = false;
        this.append (label);

        var label2 = new Gtk.MenuItem.with_label (this.station.countrycode);
        label2.sensitive = false;
        this.append (label2);

		this.append (new Gtk.SeparatorMenuItem ());

        if (this.station.homepage != null && this.station.homepage.length > 0) {
            var website_label = new Gtk.MenuItem.with_label (_("Visit Website"));
            this.append (website_label);
            website_label.activate.connect (on_website_handler);
        }

		var label3 = new Gtk.MenuItem.with_label (_("Copy Stream-URL to clipboard"));
		label3.sensitive = true;
		this.append (label3);
		label3.activate.connect (on_streamurl_handler);

        this.append (new Gtk.SeparatorMenuItem ());

        var m1 = new Gtk.MenuItem ();
        set_star_context (m1);
        m1.activate.connect (on_star_handler);
        this.append (m1);

        this.station.notify["starred"].connect ( (sender, property) => {
            set_star_context (m1);
        });
    }

    /**
     * @brief Handles the star/unstar action.
     */
    private void on_star_handler () {
       station.toggle_starred ();
    }

    /**
     * @brief Handles the action to open the station's website.
     */
    private void on_website_handler () {
        try {
            Gtk.show_uri_on_window (app().window, station.homepage, Gdk.CURRENT_TIME);
        } catch (Error e) {
            warning (@"Unable to open website: $(e.message)");
        }

    }

	/**
	 * @brief Handles copying the stream URL to clipboard.
	 */
	private void on_streamurl_handler () {
		Gdk.Display display = Gdk.Display.get_default ();
		Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text (this.station.url, -1);
	}

    /**
     * @brief Updates the star menu item's label based on the station's starred status.
     * @param item The menu item to update.
     */
    private void set_star_context (Gtk.MenuItem item) {
        item.label = station.starred ? Application.UNSTAR_CHAR + _("Unstar this station") : Application.STAR_CHAR + _("Star this station");
    }

}
