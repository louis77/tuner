/*
* Copyright (c) 2020-2021 Louis Brauer <louis@brauer.family>
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

using Gee;

public class Tuner.ContentBox : Gtk.Box {

    public signal void action_activated ();
    public signal void content_changed ();

    private Gtk.Box header;
    private Gtk.Box _content;
    private AbstractContentList _content_list;
    private Gtk.Stack stack;
    public HeaderLabel header_label;
    
    public ContentBox (Gtk.Image? icon,
                       string title,
                       string? subtitle,
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

        header_label = new HeaderLabel (title);
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

        if (subtitle != null) {
            var subtitle_label = new Gtk.Label (subtitle);
            pack_start (subtitle_label);    
        }

        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);

        _content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        _content.get_style_context ().add_class ("color-light");
        _content.valign = Gtk.Align.START;
        _content.get_style_context().add_class("welcome");

        var scroller = new Gtk.ScrolledWindow (null, null);
        scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroller.add (_content);
        scroller.propagate_natural_height = true;

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
    
    public AbstractContentList content { 
        set {
            var childs = _content.get_children ();
            foreach (var c in childs) {
                c.destroy ();
            }
            stack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);
            _content_list = value;
            _content.add (_content_list);
            _content.show_all ();
            content_changed ();
        }

        get {
            return _content_list;
        }
    }

   
    construct {
        get_style_context ().add_class ("color-dark");
    }

}
