/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class Tuner.DisplayButton
 * @brief A button widget that displays a title, tag, description, and an optional favicon.
 *
 * This class extends Gtk.Button and is used to represent a display button
 * in the tuner application, showing relevant information about a station.
 */
public class Tuner.DisplayButton : Gtk.Button {

    private const int TITLE_WIDTH =  30;

    /**
     * @brief Default icon name for stations without a custom favicon.
     */
    Gtk.Label button_title; ///< The label displaying the title of the button.
    Gtk.Label button_tag; ///< The label displaying the tag of the button.
    Gtk.Label button_description; ///< The label displaying the description of the button.
    Gtk.Grid button_grid; ///< The grid layout for organizing button contents.

    protected Gtk.Image _favicon_image; ///< The image displayed as the favicon. Updated by derived classes

    /**
     * @brief Gets or sets the title of the button.
     * @return The current title of the button.
     */
    public string title {
        get { return button_title.get_text (); }
        set { button_title.set_text (value); }
    }

    /**
     * @brief Gets or sets the tag of the button.
     * @return The current tag of the button.
     */
    public string tag {
        get { return button_tag.get_text (); }
        set { 
            button_tag.set_text (value); 
            if (value == null || value.length == 0)
                button_tag.dispose();
        }
    }

    /**
     * @brief Gets or sets the description of the button.
     * @return The current description of the button.
     */
    public string description {
        get { return button_description.get_text (); }
        set { button_description.set_text (value); }
    }

    /**
     * @brief Gets the favicon image.
     * @return The current favicon image.
     */
    public Gtk.Image favicon_image 
    { 
        protected get { return _favicon_image; }
        construct { _favicon_image = value;  } 
    }

    /**
     * @brief Constructs a new DisplayButton instance.
     *
     * This constructor initializes the button's labels and layout,
     * setting up the grid and adding the necessary styles.
     */
    construct {
        
        // Favicon
        _favicon_image.set_pixel_size (48);
        _favicon_image.halign = Gtk.Align.CENTER;
        _favicon_image.valign = Gtk.Align.CENTER;

        // Title label
        button_title = new Gtk.Label (null);
        button_title.set_max_width_chars (TITLE_WIDTH);
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
        button_grid.attach (_favicon_image, 0, 0, 1, 2);

        this.add (button_grid);
    }

}
