/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later 
 *
 * @file RevealLabel.vala
 */

 using Gtk;
 using GLib;

/**
 * @class RevealLabel
 * @brief A custom widget that reveals a label with animation.
 *
 * This class extends Gtk.Revealer to create a label that can be revealed
 * and hidden with smooth transitions.
 * Uses Gtk.Label get_text and set_text for label text
 *
 * @extends Gtk.Revealer
 */
public class Tuner.RevealLabel : Gtk.Revealer {

    public signal void reveal_true_called_sig();   // Signals that the reveal call has been initiated
    public signal void reveal_false_called_sig();   // Signals that the reveal call has been initiated


    private Mutex _set_text_lock = Mutex();   // Lock out concurrent updates

    /**
     * @brief Default duration for fade-in animation in milliseconds.
     */
    private const uint DEFAULT_FADE_DURATION = 1200u;

    
    /**
     * @property label_child
     * @brief The Gtk.Label widget contained within the revealer.
     */
    public Label label_child { get; construct set; }

    
    /** @property {string} label - Label text. Setting this property triggers the reveal animation. */
    public string label {
        get { return get_text(); }
        set { set_text ( value ); }
    } // label


    /**
     * @brief The text displayed in the label.
     *
     */
    public unowned string get_text() {
            return label_child.label;
    } // get_text

    
    /**
     * @brief The text to display in the label.
     *
     * Setting this text triggers the reveal animation.
     */
    public void set_text ( string text ) 
    {
        // Prevent transition if same title is submitted multiple times
        if ( label_child.label == text) return;      
        
        if ( _set_text_lock.trylock() == false ) return;

        warning(@"set_text: $text - Setup");

        reveal_child = false;

        if ( label_child.label == "" ) 
        {
            warning(@"set_text: $text - Reveal from Clear");
            label_child.label = text;
            reveal_child = true;
            reveal_true_called_sig();
            _set_text_lock.unlock ();
            return;
        }

        Timeout.add (DEFAULT_FADE_DURATION+100, () => 
        // Clear the text after fade has completed
        {
            warning(@"set_text: $text - Clear");
            reveal_false_called_sig();
            label_child.label = "";
            return Source.REMOVE;
        },Priority.HIGH_IDLE
        );  

        Timeout.add (3*DEFAULT_FADE_DURATION/2, () => 
        // Update and reveal new text after fade and clear have completed
        {
            warning(@"set_text: $text - Reveal");
            label_child.label = text;
            reveal_child = true;
            reveal_true_called_sig();
            _set_text_lock.unlock ();
            return Source.REMOVE;
        }, Priority.DEFAULT_IDLE);       
    } // set_text


    /**
     * @brief Initializes the RevealLabel with default properties.
     */
    construct {
        label_child = new Label ("");
        label_child.ellipsize = Pango.EllipsizeMode.MIDDLE;
        child = label_child;
        transition_type = RevealerTransitionType.CROSSFADE;
        transition_duration = DEFAULT_FADE_DURATION; 
    } // construct
}

