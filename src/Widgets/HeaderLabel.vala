/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class HeaderLabel
 * @brief A custom label widget for headers.
 *
 * This class extends Gtk.Label to create a specialized label
 * for use as headers in the application.
 *
 * @extends Gtk.Label
 */
public class Tuner.HeaderLabel : Gtk.Label {
    
    public HeaderLabel (string label, int xpad = 0, int ypad = 0 ) {
        Object (
            label: label,
            xpad: xpad,
            ypad: ypad
        );
    }

    construct {
        halign = Gtk.Align.START;
        xalign = 0;
        get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
    }

}
