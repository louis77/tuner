/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.StationContextMenu : Gtk.Menu {
    public Model.Station station { get; construct; }

    public StationContextMenu (Model.Station station) {
        Object (
            station: station
        );
    }

    construct {
        var label = new Gtk.MenuItem.with_label (this.station.title);
        label.sensitive = false;
        this.append (label);

        var label2 = new Gtk.MenuItem.with_label (this.station.location);
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

    private void on_star_handler () {
       station.toggle_starred ();
    }

    private void on_website_handler () {
        try {
            Gtk.show_uri_on_window (Application._instance.window, station.homepage, Gdk.CURRENT_TIME);
        } catch (Error e) {
            warning (@"Unable to open website: $(e.message)");
        }

    }

	private void on_streamurl_handler () {
		Gdk.Display display = Gdk.Display.get_default ();
		Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text (this.station.url, -1);
	}

    private void set_star_context (Gtk.MenuItem item) {
        item.label = station.starred ? Application.UNSTAR_CHAR + _("Unstar this station") : Application.STAR_CHAR + _("Star this station");
    }

}