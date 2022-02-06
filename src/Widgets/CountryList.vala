/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.CountryList : AbstractContentList {

    public CountryList () {
        Object (
            homogeneous: false,
            min_children_per_line: 2,
            max_children_per_line: 2,
            column_spacing: 5,
            row_spacing: 5,
            border_width: 20,
            valign: Gtk.Align.START,
            selection_mode: Gtk.SelectionMode.NONE
        );
    }

    construct {
        var button = new Gtk.Button ();
        button.label = "a country";

        add (button);
    }

    public override uint item_count { get; set; }

}