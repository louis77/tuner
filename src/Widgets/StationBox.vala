/*
* Copyright (c) 2020-2021 Louis Brauer <louis77@member.fsf.org>
*
* This file is part of Tuner.
*
* Tuner is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Tuner is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Tuner.  If not, see <http://www.gnu.org/licenses/>.
*
*/

public class Tuner.StationBox : Tuner.WelcomeButton {

    public Model.Station station { get; construct; }
    public StationContextMenu menu { get; private set; }

    public StationBox (Model.Station station) {
        Object (
            description: make_description (station.location),
            title: make_title (station.title, station.starred),
            tag: make_tag (station.codec, station.bitrate),
            icon: new Gtk.Image(),
            station: station
        );
    }

    construct {
        get_style_context().add_class("station-button");

        this.station.notify["starred"].connect ( (sender, prop) => {
            this.title = make_title (this.station.title, this.station.starred);
        });

        // TODO Use a AsyncQueue with limited threads
        new Thread<int>("station-box", realize_favicon);


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
        always_show_image = true;
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

    private int realize_favicon () {
        // TODO: REFACTOR in separate class
        var favicon_cache_file = Path.build_filename (Application.instance.cache_dir, station.id);
        if (FileUtils.test (favicon_cache_file, FileTest.EXISTS | FileTest.IS_REGULAR)) {
            var file = File.new_for_path (favicon_cache_file);
            try {
                var favicon_stream = file.read ();
                if (!set_favicon_from_stream (favicon_stream)) {
                    set_default_favicon ();
                };
                favicon_stream.close ();
                return 0;
            } catch (Error e) {
                warning (@"unable to read local favicon: %s %s", favicon_cache_file, e.message);
            }
        } else {
            // debug (@"favicon cache file doesn't exist: %s", favicon_cache_file);
        }

        // in Vala nullable strings are always empty
        if (station.favicon_url != "") {
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", station.favicon_url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code != 200) {
                    //debug (@"Unexpected status code: $(mess.status_code), will not render $(station.favicon_url)");
                    set_default_favicon ();
                    return;
                }

                var data_stream = new MemoryInputStream.from_data (mess.response_body.data);
                //set_favicon_from_stream (data_stream);

                var file = File.new_for_path (favicon_cache_file);
                try {
                    var stream = file.create_readwrite (FileCreateFlags.PRIVATE);
                    stream.output_stream.splice (data_stream, 0);
                    stream.close ();
                } catch (Error e) {
                    // File already created by another stationbox
                    // TODO: possible race condition
                    // TODO: Create stationboxes as singletons?
                }

                try {
                    var favicon_stream = file.read ();
                    if (!set_favicon_from_stream (favicon_stream)) {
                        set_default_favicon ();
                    };
                } catch (Error e) {
                    warning (@"Error while reading icon file stream: $(e.message)");
                }
            });

        } else {
            set_default_favicon ();
        }

        Thread.exit (0);
        return 0;
    }

    private bool set_favicon_from_stream (InputStream stream) {
        Gdk.Pixbuf pxbuf;

        try {
            pxbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, 48, 48, true, null);
            this.icon.set_from_pixbuf (pxbuf);
            this.icon.set_size_request (48, 48);
            return true;
        } catch (Error e) {
            //debug ("Couldn't render favicon: %s (%s)",
            //    station.favicon_url ?? "unknown url",
            //    e.message);
            return false;
        }
    }

    private void set_default_favicon () {
        this.icon.set_from_icon_name ("internet-radio", Gtk.IconSize.DIALOG);
    }

}
