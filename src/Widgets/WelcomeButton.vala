/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

 public class Tuner.WelcomeButton : Gtk.Button {

    Gtk.Label button_title;
    Gtk.Label button_tag;
    Gtk.Label button_description;
    Gtk.Image? _favicon_image;
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

    public Gtk.Image? favicon {
        get { return _favicon_image; }
        set {
            if (_favicon_image != null) {
                _favicon_image.destroy ();
            }
            _favicon_image = value;
            if (_favicon_image != null) {
                _favicon_image.set_pixel_size (48);
                _favicon_image.halign = Gtk.Align.CENTER;
                _favicon_image.valign = Gtk.Align.CENTER;
                button_grid.attach (_favicon_image, 0, 0, 1, 2);
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
        button_description.ellipsize = Pango.EllipsizeMode.MIDDLE;
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
