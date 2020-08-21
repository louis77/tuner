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