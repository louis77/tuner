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

using Gee;

public class Tuner.ContentBox : Gtk.Box {

    public delegate void ActionFunc (ContentBox target);
    public delegate void StationFunc (Model.StationModel station);

    private StationFunc _station_func;
    private Gtk.Box header;
    public Gtk.Box content;

    public ContentBox (Gtk.Image? icon,
                       string title,
                       ActionFunc action,
                       string action_icon_name,
                       string action_tooltip_text,
                       StationFunc sfunc) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );

        _station_func = sfunc;

        header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header.homogeneous = false;

        if (icon != null) {
            header.pack_start (icon, false, false, 20);
        }

        var header_label = new HeaderLabel (title);
        header_label.xpad = 20;
        header_label.ypad = 20;
        header.pack_start (header_label, false, false);

        var shuffle_button = new Gtk.Button.from_icon_name (
            action_icon_name,
            Gtk.IconSize.LARGE_TOOLBAR
        );
        shuffle_button.valign = Gtk.Align.CENTER;
        shuffle_button.tooltip_text = action_tooltip_text;
        shuffle_button.clicked.connect (() => {
            action (this);
        });
        header.pack_start (shuffle_button, false, false);

        pack_start (header, false, false);
        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content.get_style_context ().add_class ("color-light");
        content.valign = Gtk.Align.START;
        content.get_style_context().add_class("welcome");
        action (this);
        add (content);
    }

    public ArrayList<Model.StationModel> stations {
        set {
            clear_content ();
            var station_list = new Gtk.FlowBox ();
            station_list.homogeneous = false;
            station_list.min_children_per_line = 2;
            station_list.column_spacing = 5;
            station_list.row_spacing = 5;
            station_list.border_width = 20;
            station_list.valign = Gtk.Align.START;
            station_list.selection_mode = Gtk.SelectionMode.NONE;

            foreach (var s in value) {
                var box = new StationBox (s);
                box.clicked.connect (() => {
                    _station_func (box.station);
                });
                station_list.add (box);
            }

            content.add (station_list);
            station_list.unselect_all ();
        }
    }

    private void clear_content () {
        var childs = content.get_children();
        foreach (var c in childs) {
            c.destroy();
        }
    }

    construct {
        get_style_context ().add_class ("color-dark");
    }

}
