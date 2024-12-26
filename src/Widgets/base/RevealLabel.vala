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
public class Tuner.RevealLabel : Gtk.Fixed {

    public signal void reveal_true_called_sig();   // Signals that the reveal call has been initiated
    public signal void reveal_false_called_sig();   // Signals that the reveal call has been initiated

    private bool _revealer;
    private Revealer[] _revealers = new Revealer[2];   // Array of two revealers for cross-fading
    private Label[] _labels = new Label[2];   // Array of two labels for cross-fading
    private Mutex _set_text_lock = Mutex();   // Lock out concurrent updates
    //  private string _next_text;

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
    //  public string label {
    //      get { return _labels[(int) _revealer].label; }
    //      set { set_text ( value ); }
    //  } // label


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
    public bool set_text ( string text ) 
    {
        // Prevent transition if same title is submitted multiple times
        if ( _labels[(int) _revealer].label == text) return true;    

        _labels[(int) !_revealer].label = text;

        //  warning(@"RL set_text - Try Lock: $text");
        if ( _set_text_lock.trylock() == false ) return false;

        _revealers[(int) _revealer].reveal_child = false;
        _revealers[(int) !_revealer].reveal_child = true;
        _revealer = !_revealer;

        _set_text_lock.unlock ();

        //  if ( label_child.label == "" && text != "") 
        //  {
        //      //  warning(@"RL set_text - Reveal from Clear & Unlock: $text");
        //      label_child.label = _next_text;
        //      reveal_child = true;
        //      reveal_true_called_sig();
        //      _set_text_lock.unlock ();
        //      return true;
        //  }

        //  Timeout.add (DEFAULT_FADE_DURATION+100, () => 
        //  // Clear the text after fade has completed
        //  {
        //      reveal_false_called_sig();
        //      label_child.label = "";
        //      //  warning(@"RL set_text - Clear: $text");
        //      return Source.REMOVE;
        //  },Priority.HIGH_IDLE);  

        //  Timeout.add (3*DEFAULT_FADE_DURATION/2, () => 
        //  // Update and reveal new text after fade and clear have completed
        //  {
        //      label_child.label = _next_text;
        //      reveal_child = true;
        //      reveal_true_called_sig();
        //      _set_text_lock.unlock ();
        //      //  warning(@"RL set_text - Reveal & Unlock: $text");
        //      return Source.REMOVE;
        //  }, Priority.DEFAULT_IDLE);    
        
        return true;
    } // set_text


    /**
     * @brief Initializes the RevealLabel with default properties.
     */
    construct {
        label_child = new Label ("");
        label_child.ellipsize = Pango.EllipsizeMode.MIDDLE;
        child = label_child;
        _revealers[0] = new Revealer ();
        _revealers[1] = new Revealer ();
        _revealers[0].transition_type = RevealerTransitionType.CROSSFADE;
        _revealers[0].transition_duration = DEFAULT_FADE_DURATION; 
        _labels[0] = new Label ("");
        _revealers[0].add (_labels[0]);
        _revealers[1].transition_type = RevealerTransitionType.CROSSFADE;
        _revealers[1].transition_duration = DEFAULT_FADE_DURATION; 
        _labels[1] = new Label ("");
        _revealers[1].add (_labels[1]);
        add (_revealers[0]);
        add (_revealers[1]);
    } // construct
}

