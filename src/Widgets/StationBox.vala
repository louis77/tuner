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
* Authored by: Louis Brauer <louis@brauer.family>
*/

public class Tuner.StationBox : Granite.Widgets.WelcomeButton {

    public Model.StationModel station { get; private set; }

    public StationBox (Model.StationModel station) {
        var title = station.title;
        if (title.length > 30) {
            title = title[0:30] + "...";
        }
        Object (
            description: @"$(station.location) ($(station.clickcount))",
            description: @"$(station.location)",
            title: title,
            icon: new Gtk.Image()
        );

        get_style_context().add_class("station-button");

        this.station = station;
        realize.connect (() => {
            realize_favicon ();
        });

    }

    construct {
        always_show_image = true;
    }

    private void realize_favicon () {
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
                return;
            } catch (Error e) {
                warning (@"unable to read local favicon: %s %s", favicon_cache_file, e.message);
            }
        } else {
            debug (@"favicon cache file doesn't exist: %s", favicon_cache_file);
        }

        // in Vala nullable strings are always empty
        if (station.favicon_url != "") {
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", station.favicon_url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code != 200) {
                    debug (@"Unexpected status code: $(mess.status_code), will not render $(station.favicon_url)");
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
            debug (@"station has no favicon url");
            set_default_favicon ();
        }
    }

    private bool set_favicon_from_stream (InputStream stream) {
        Gdk.Pixbuf pxbuf;

        try {
            pxbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, 48, 48, true, null);
            this.icon.set_from_pixbuf (pxbuf);
            this.icon.set_size_request (48, 48);
            return true;
        } catch (Error e) {
            debug ("Couldn't render favicon: %s (%s)",
                station.favicon_url ?? "unknown url",
                e.message);
            return false;
        }
    }

    private void set_default_favicon () {
        this.icon.set_from_icon_name ("internet-radio", Gtk.IconSize.DIALOG);
    }

}
