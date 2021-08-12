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

public class Tuner.RevealLabel : Gtk.Revealer {

    private const uint DEFAULT_FADEIN_DURATION = 1000u;
    private const uint DEFAULT_FADEOUT_DURATION = 500u;
    
    public Gtk.Label label_child { get; construct set; }

    public string label { 
        get {
            return label_child.label;
        } 
        set {
            // Prevent transition if same title is submitted multiple times
            if (label_child.label == value) return;

            GLib.Idle.add (() => {
                transition_duration = DEFAULT_FADEOUT_DURATION; // milliseconds
                reveal_child = false;
                return GLib.Source.REMOVE;
            });

            GLib.Timeout.add (1000u, () => {
                transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
                transition_duration = DEFAULT_FADEIN_DURATION; // milliseconds
                label_child.label = value;
                reveal_child = true;

                return GLib.Source.REMOVE;
            });
        }
    }

    construct {
        label_child = new Gtk.Label ("test");
        label_child.ellipsize = Pango.EllipsizeMode.MIDDLE;
        child = label_child;
    }



}

