/*
* Copyright (c) 2020-2022 Louis Brauer <louis@brauer.family>
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
