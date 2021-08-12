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

 public class Tuner.WelcomeButton : Gtk.Button {

    Gtk.Label button_title;
    Gtk.Label button_tag;
    Gtk.Label button_description;
    Gtk.Image? _icon;
    Gtk.Grid button_grid;

    public string title {
        get { return button_title.get_text (); }
        set { button_title.set_text (value); }
    }

    public string tag {
        get { return button_tag.get_text (); }
        set { 
            button_tag.set_text (value); 
            if (value == null || value.length == 0)
                button_tag.dispose();
        }
    }

    public string description {
        get { return button_description.get_text (); }
        set {
            button_description.set_text (value);
        }
    }

    public Gtk.Image? icon {
        get { return _icon; }
        set {
            if (_icon != null) {
                _icon.destroy ();
            }
            _icon = value;
            if (_icon != null) {
                _icon.set_pixel_size (48);
                _icon.halign = Gtk.Align.CENTER;
                _icon.valign = Gtk.Align.CENTER;
                button_grid.attach (_icon, 0, 0, 1, 2);
            }
        }
    }

    /*
    public WelcomeButton (Gtk.Image? image, string title, string description) {
        Object (title: title, description: description, icon: image);
    }

    public WelcomeButton.with_tag (Gtk.Image? image, string title, string description, string tag) {
        Object (title: title, description: description, icon: image, tag: tag);
    }
*/

    construct {
        // Title label
        button_title = new Gtk.Label (null);
        button_title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        button_title.halign = Gtk.Align.START;
        button_title.valign = Gtk.Align.END;
        button_title.ellipsize = Pango.EllipsizeMode.END;

        // Tag label
        button_tag = new Gtk.Label (null);
        button_tag.halign = Gtk.Align.START;
        button_tag.valign = Gtk.Align.START;
        button_tag.get_style_context ().add_class ("keycap");
        button_tag.get_style_context ().add_class ("tag");

        // Description label
        button_description = new Gtk.Label (null);
        button_description.halign = Gtk.Align.START  | Gtk.Align.FILL;
        button_description.valign = Gtk.Align.CENTER;
        button_description.set_line_wrap (true);
        button_description.set_line_wrap_mode (Pango.WrapMode.WORD);
        button_description.get_style_context ().add_class ("station-button-description");
        button_description.ellipsize = Pango.EllipsizeMode.END;
        button_description.hexpand = true;

        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        // Button contents wrapper
        button_grid = new Gtk.Grid ();
        button_grid.column_spacing = 6;

        button_grid.attach (button_title, 1, 0, 2, 1);
        button_grid.attach (button_tag, 1, 1, 1, 1);
        button_grid.attach (button_description, 2, 1, 1, 1);

        this.add (button_grid);
    }
}
