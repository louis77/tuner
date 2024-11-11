/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class RevealLabel
 * @brief A custom widget that reveals a label with animation.
 *
 * This class extends Gtk.Revealer to create a label that can be revealed
 * and hidden with smooth transitions.
 *
 * @extends Gtk.Revealer
 */
public class Tuner.RevealLabel : Gtk.Revealer {

    /**
     * @brief Default duration for fade-in animation in milliseconds.
     */
    private const uint DEFAULT_FADEIN_DURATION = 1000u;

    /**
     * @brief Default duration for fade-out animation in milliseconds.
     */
    private const uint DEFAULT_FADEOUT_DURATION = 500u;
    
    /**
     * @property label_child
     * @brief The Gtk.Label widget contained within the revealer.
     */
    public Gtk.Label label_child { get; construct set; }

    /**
     * @property label
     * @brief The text displayed in the label.
     *
     * Setting this property triggers the reveal animation.
     */
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

    /**
     * @brief Initializes the RevealLabel with default properties.
     */
    construct {
        label_child = new Gtk.Label ("test");
        label_child.ellipsize = Pango.EllipsizeMode.MIDDLE;
        child = label_child;
    }



}

