/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file RevealLabel.vala
 */

 using Gee;
 
 /**
 * @class RevealLabel
 * @brief A custom widget that reveals a label with animation.
 *
 * This class extends Gtk.Revealer to create a label that can be revealed
 * and hidden with smooth transitions.
 *
 * @extends Gtk.Revealer
 */
public class Tuner.CyclingRevealLabel : RevealLabel {

    private const int SUBTITLE_MIN_DISPLAY_SECONDS = 5;

    private uint _max_width = 0;
    private uint _label_cycle_id = 0;
    private int punt;
    private uint16 display_seconds = 1000;   // Mix up the cycle phase start point
    private uint16[] cycle_phases = {11,37,43,47}; // Ttitle, plus three subtitles

    private Gee.Map<uint, string> sublabels = new Gee.HashMap<uint, string>();


    public new string label { 
        get {
            return base.label;
        } 
        set {
            sublabels.set(0,value.strip());
            base.label = value;
            display_seconds = (display_seconds/cycle_phases[0]) - (uint16) SUBTITLE_MIN_DISPLAY_SECONDS;
            _max_width = value.length;
        }
    }


    public void add_sublabel(int position, string sublabel)
    {
        if ( position <= 0 || position >= cycle_phases.length ) return;    // Main label not sublabel, or too deep

        if ( sublabel.strip().length == 0 ) 
        {
            sublabels.unset(position);
        }
        else
        {
            sublabels.set(position,sublabel.strip());
        }
    }

    public void stop()
    {
        if ( _label_cycle_id > 0 ) 
        {
            Source.remove(_label_cycle_id);
            _label_cycle_id = 0;
            _max_width = 0;
        }
    }


    /**
     */
    public void cycle()
    { 
        if ( _label_cycle_id > 0 ) 
        {
            Source.remove(_label_cycle_id);
            _label_cycle_id = 0;
        }

        _label_cycle_id = Timeout.add_seconds_full(Priority.LOW, 1, () => 
        {
            display_seconds++;

            if ( 0 < punt-- )
            {
                return Source.CONTINUE;  
            }

            if ( ! child_revealed ) 
            {
                reveal_child = true;
                punt = SUBTITLE_MIN_DISPLAY_SECONDS;
                return Source.CONTINUE;    // Still processing reveal
            }

            foreach ( var position in sublabels.keys)
            {
                if ( ( display_seconds % cycle_phases[position] == 0 ) && sublabels.get(position) != "" ) 
                {
                    base.label = pad(sublabels.get(position));
                }
            }
   
            return Source.CONTINUE;
        });
    } // recycle




    private string pad( string text)
    {
        var testtext = text.strip();
        if ( testtext.length >= _max_width ) 
        {
            _max_width = testtext.length;
            return testtext;
        }

        uint total_padding = _max_width - testtext.length;
        uint left_padding = total_padding / 2;
        uint right_padding = total_padding - left_padding;
        return "·   %*s%s%*s   ·".printf(left_padding, "", testtext, right_padding, "");
    } // pad
}

