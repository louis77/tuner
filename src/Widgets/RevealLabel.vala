/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
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

