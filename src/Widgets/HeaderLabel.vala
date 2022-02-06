/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.HeaderLabel : Gtk.Label {
    
    public HeaderLabel (string label) {
        Object (
            label: label
        );
    }

    construct {
        halign = Gtk.Align.START;
        xalign = 0;
        get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
    }

}
