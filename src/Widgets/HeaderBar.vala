/*
* Copyright (c) 2020 Louis Brauer (https://github.com/louis77)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Louis Brauer <louis77@member.fsf.org>
*/

public class Tuner.HeaderBar : Gtk.HeaderBar {

    private const string DEFAULT_ICON_NAME = "internet-radio-symbolic";
    public enum PlayState {
        PAUSE_ACTIVE,
        PAUSE_INACTIVE,
        PLAY_ACTIVE,
        PLAY_INACTIVE
    }

    public Tuner.Window main_window { get; construct; }
    public Gtk.Button play_button { get; set; }

    private Gtk.Button star_button;
    private bool _starred = false;
    private Model.Station _station;
    private Gtk.Label _title_label;
    private Gtk.Label _subtitle_label;
    private Gtk.Image _favicon_image;

    public signal void star_clicked (bool starred);
    public signal void searched_for (string text);
    public signal void search_focused ();

    public HeaderBar (Tuner.Window window) {
        Object (
            main_window: window
        );

        show_close_button = true;

        var station_info = new Gtk.Grid ();
        station_info.column_spacing = 10;

        _title_label = new Gtk.Label (_("Choose a station"));
        _title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        _subtitle_label = new Gtk.Label (_("Paused"));
        _favicon_image = new Gtk.Image.from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG);

        station_info.attach (_favicon_image, 0, 0, 1, 2);
        station_info.attach (_title_label, 1, 0, 1, 1);
        station_info.attach (_subtitle_label, 1, 1, 1, 1);

        custom_title = station_info;
        play_button = new Gtk.Button ();
        play_button.valign = Gtk.Align.CENTER;
        play_button.action_name = Window.ACTION_PREFIX + Window.ACTION_PAUSE;
        pack_start (play_button);

        var about_menuitem = new Gtk.ModelButton ();
        about_menuitem.text = _("About");
        about_menuitem.action_name = Window.ACTION_PREFIX + Window.ACTION_ABOUT;

        var disable_tracking_item = new Gtk.ModelButton ();
        disable_tracking_item.text = _("Do not track");
        disable_tracking_item.action_name = Window.ACTION_PREFIX + Window.ACTION_DISABLE_TRACKING;
        disable_tracking_item.tooltip_text = _("If enabled, we will not send usage info to radio-browser.org");

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.attach (disable_tracking_item, 0, 0, 3, 1);
        menu_grid.attach (about_menuitem, 0, 1, 3, 1);
        menu_grid.show_all ();

        var menu = new Gtk.Popover (null);
        menu.add (menu_grid);

        var prefs_button = new Gtk.MenuButton ();
        prefs_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        prefs_button.valign = Gtk.Align.CENTER;
        prefs_button.sensitive = true;
        prefs_button.tooltip_text = _("Preferences");
        prefs_button.popover = menu;
        pack_end (prefs_button);

        var searchentry = new Gtk.SearchEntry ();
        searchentry.valign = Gtk.Align.CENTER;
        searchentry.placeholder_text = _("Station name");
        searchentry.search_changed.connect (() => {
            searched_for (searchentry.text);
        });
        searchentry.focus_in_event.connect ((e) => {
            search_focused ();
            return true;
        });
        pack_end (searchentry);

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
        set_playstate (PlayState.PAUSE_INACTIVE);
    }

    public new string title {
        get {
            return _title_label.label;
        }
        set {
            _title_label.label = value;
        }
    }

    public new string subtitle {
        get {
            return _subtitle_label.label;
        }
        set {
            _subtitle_label.label = value;
        }
    }

    public Gtk.Image favicon {
        get {
            return _favicon_image;
        }
        set {
            _favicon_image = value;
        }
    }

    public void handle_station_change () {
        starred = _station.starred;
    }

    public void update_from_station (Model.Station station) {
        if (_station != null) {
            _station.notify.disconnect (handle_station_change);
        }
        _station = station;
        _station.notify.connect ( (sender, property) => {
            handle_station_change ();
        });
        var short_title = station.title;
        if (short_title.length > 50) {
            short_title = short_title[0:30] + "…";
        }
        title = short_title;
        subtitle = _("Connecting");
        load_favicon (station.favicon_url);
        starred = station.starred;
    }

    private bool starred {
        get {
            return _starred;
        }

        set {
            _starred = value;
            if (!_starred) {
                star_button.image = new Gtk.Image.from_icon_name ("non-starred",    Gtk.IconSize.LARGE_TOOLBAR);
            } else {
                star_button.image = new Gtk.Image.from_icon_name ("starred",    Gtk.IconSize.LARGE_TOOLBAR);
            }
        }
    }

    private void load_favicon (string url) {
        // Set default icon first, in case loading takes long or fails
        favicon.set_from_icon_name (DEFAULT_ICON_NAME, Gtk.IconSize.DIALOG);
        if (url.length == 0) {
            return;
        }

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", url);

        session.queue_message (message, (sess, mess) => {
            if (mess.status_code != 200) {
                warning (@"Unexpected status code: $(mess.status_code), will not render $(url)");
                return;
            }

            var data_stream = new MemoryInputStream.from_data (mess.response_body.data);
            Gdk.Pixbuf pxbuf;

            try {
                pxbuf = new Gdk.Pixbuf.from_stream_at_scale (data_stream, 48, 48, true, null);
            } catch (Error e) {
                warning ("Couldn't render favicon: %s (%s)",
                    url ?? "unknown url",
                    e.message);
                return;
            }

            favicon.set_from_pixbuf (pxbuf);
            favicon.set_size_request (48, 48);
        });
    }

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
                    "media-playback-pause-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = true;
                star_button.sensitive = true;
                break;
            case PlayState.PAUSE_INACTIVE:
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-pause-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.sensitive = false;
                star_button.sensitive = false;
                break;
        }
    }

}
