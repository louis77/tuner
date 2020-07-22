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

using Gee;

public class Tuner.ContentBox : Gtk.Box {

    public signal void selection_changed (Model.Station station);
    public signal void action_activated ();
    public signal void station_count_changed (uint count);
    public signal void favourites_changed ();

    private Gtk.Box header;
    private Gtk.Stack stack;
    public Gtk.Box content;
    public Model.Station selected_station;
    
    public ContentBox (Gtk.Image? icon,
                       string title,
                       string? action_icon_name,
                       string? action_tooltip_text) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );

        stack = new Gtk.Stack ();

        var alert = new Granite.Widgets.AlertView (_("Nothing here"), _("Something went wrong loading radio stations data from radio-browser.info. Please try again later."), "dialog-warning");
        /* 
        alert.show_action ("Try again");
        alert.action_activated.connect (() => {
            // alert.hide_action ();
            realize ();
        });
        */
        stack.add_named (alert, "alert");

        var no_results = new Granite.Widgets.AlertView (_("No stations found"), _("Please try a different search term."), "dialog-warning");
        stack.add_named (no_results, "nothing-found");

        header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header.homogeneous = false;

        if (icon != null) {
            header.pack_start (icon, false, false, 20);
        }

        var header_label = new HeaderLabel (title);
        header_label.xpad = 20;
        header_label.ypad = 20;
        header.pack_start (header_label, false, false);

        if (action_icon_name != null && action_tooltip_text != null) {
            var shuffle_button = new Gtk.Button.from_icon_name (
                action_icon_name,
                Gtk.IconSize.LARGE_TOOLBAR
            );
            shuffle_button.valign = Gtk.Align.CENTER;
            shuffle_button.tooltip_text = action_tooltip_text;
            shuffle_button.clicked.connect (() => { action_activated (); });
            header.pack_start (shuffle_button, false, false);            
        }

        pack_start (header, false, false);
        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content.get_style_context ().add_class ("color-light");
        content.valign = Gtk.Align.START;
        content.get_style_context().add_class("welcome");

        var scroller = new Gtk.ScrolledWindow (null, null);
        scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroller.add (content);
        scroller.propagate_natural_height = true;

        /* not a fan right now
        scroller.edge_reached.connect ((pos_type) => {
            if (pos_type == Gtk.PositionType.BOTTOM) {
                action_activated ();
            }
        });
        */
        stack.add_named (scroller, "content");
        add (stack);
        
        show.connect (() => {
            stack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);            
        });
    }

    public void show_alert () {
        stack.set_visible_child_full ("alert", Gtk.StackTransitionType.NONE);
    }

    public void show_nothing_found () {
        stack.set_visible_child_full ("nothing-found", Gtk.StackTransitionType.NONE);
    }
    
    public ArrayList<Model.Station> stations {
        set {
            stack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);
            clear_content ();
            var station_list = new Gtk.FlowBox ();
            station_list.homogeneous = false;
            station_list.min_children_per_line = 2;
            station_list.max_children_per_line = 2;
            station_list.column_spacing = 5;
            station_list.row_spacing = 5;
            station_list.border_width = 20;
            station_list.valign = Gtk.Align.START;
            station_list.selection_mode = Gtk.SelectionMode.NONE;

            foreach (var s in value) {
                s.notify["starred"].connect ( () => {
                    favourites_changed ();
                });
                var box = new StationBox (s);
                box.clicked.connect (() => {
                    selection_changed (box.station);
                    selected_station = box.station;
                });
                station_list.add (box);
            }
            content.add (station_list);
            station_list.unselect_all ();
            content.show_all ();
            station_count_changed (value.size);
        }
    }
    
    public void clear_content () {
        var childs = content.get_children();
        foreach (var c in childs) {
            c.destroy();
        }
    }

    construct {
        get_style_context ().add_class ("color-dark");
    }

}
