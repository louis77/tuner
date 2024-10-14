/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class CountryList
 * @brief A widget for displaying a list of countries.
 *
 * This class extends AbstractContentList to create a specialized list
 * for displaying countries, potentially for selecting radio stations by country.
 *
 * @extends AbstractContentList
 */
public class Tuner.CountryList : AbstractContentList {

    /**
     * @brief Constructs a new CountryList.
     *
     * Initializes the CountryList with specific layout properties.
     */
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

    /**
     * @brief Initializes the CountryList with a sample button.
     */
    construct {
        var button = new Gtk.Button ();
        button.label = "a country";

        add (button);
    }

    /**
     * @property item_count
     * @brief The number of items (countries) in the list.
     *
     * This property implements the abstract property from AbstractContentList.
     */
    public override uint item_count { get; set; }

}
