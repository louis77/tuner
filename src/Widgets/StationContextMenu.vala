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

        // Info
        var name = new Gtk.MenuItem.with_label (this.station.name);
        name.sensitive = false;

        var country = new Gtk.MenuItem.with_label (this.station.countrycode);
        country.sensitive = false;

        var not_up_to_date = new Gtk.MenuItem.with_label (_("Station info updated Online - View changes"));
        var make_up_to_date = new Gtk.MenuItem.with_label (_("Update Station from Online"));

        var website = new Gtk.MenuItem.with_label (_("Visit Website"));
        if (this.station.homepage != null && this.station.homepage.length > 0) {
            website.activate.connect (on_website_handler);
        }

		var stream_url = new Gtk.MenuItem.with_label (_("Copy Stream-URL to clipboard"));
		stream_url.sensitive = true;
		stream_url.activate.connect (on_streamurl_handler);


        // Star
        var star = new Gtk.MenuItem ();
        set_star_context (star);
        star.activate.connect (on_star_handler);

        this.station.notify["starred"].connect ( (sender, property) => {
            set_star_context (star);
        });

        // Layout


        this.append (name);
        this.append (country);
        this.append (new Gtk.SeparatorMenuItem ());
        if ( !station.is_up_to_date )
        {
            append (not_up_to_date);
            append (make_up_to_date);
            append (new Gtk.SeparatorMenuItem ());
        }
        append (website);
		append (stream_url);
        append (star);
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


    //  private void on_show_changes_handler()
    //  {
        
    //  }


    //  private void on_update_station_handler()
    //  {
        
    //  }

	/**
	 * @brief Handles copying the stream URL to clipboard. UrlResolved is the stream url, url can be playlists
	 */
	private void on_streamurl_handler () {
		Gdk.Display display = Gdk.Display.get_default ();
		Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text (( station.urlResolved == null || station.urlResolved == "" ) ? station.url : station.urlResolved, -1);
	}

    /**
     * @brief Updates the star menu item's label based on the station's starred status.
     * @param item The menu item to update.
     */
    private void set_star_context (Gtk.MenuItem item) {
        item.label = station.starred ? Application.UNSTAR_CHAR + _("Unstar this station") : Application.STAR_CHAR + _("Star this station");
    }

}
