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

        // in Vala nullable strings are always empty
        if (station.favicon_url != "") {
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", station.favicon_url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code != 200) {
                    warning (@"Unexpected status code: $(mess.status_code), will not render $(station.favicon_url)");
                    this.icon.set_from_icon_name ("folder-music-symbolic", Gtk.IconSize.DIALOG);
                    return;
                }

                var data_stream = new MemoryInputStream.from_data (mess.response_body.data);
                Gdk.Pixbuf pxbuf;

                try {
                    pxbuf = new Gdk.Pixbuf.from_stream_at_scale (data_stream, 48, 48, true, null);
                } catch (Error e) {
                    warning ("Couldn't render favicon: %s (%s)",
                        station.favicon_url ?? "unknown url",
                        e.message);
                    this.icon.set_from_icon_name ("folder-music-symbolic", Gtk.IconSize.DIALOG);
                    return;
                }

                this.icon.set_from_pixbuf (pxbuf);
            });

        }
    }

    construct {
        always_show_image = true;
    }

}
