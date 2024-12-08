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
    private const uint DEFAULT_FADE_DURATION = 1200u;

    /**
     * @brief Default duration for fade-out animation in milliseconds.
     */
   // private const uint DEFAULT_FADEOUT_DURATION = 850u;
    
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
                reveal_child = false;
                return GLib.Source.REMOVE;
            });

            GLib.Timeout.add (DEFAULT_FADE_DURATION, () => {
                label_child.label = value;
                return GLib.Source.REMOVE;
            });            
            
            GLib.Timeout.add (3*DEFAULT_FADE_DURATION, () => {
                reveal_child = true;
                return GLib.Source.REMOVE;
            });
        }
    }

    /**
     * @brief Initializes the RevealLabel with default properties.
     */
    construct {
        label_child = new Gtk.Label ("");
        label_child.ellipsize = Pango.EllipsizeMode.MIDDLE;
        child = label_child;
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        transition_duration = DEFAULT_FADE_DURATION; 
    }



}

