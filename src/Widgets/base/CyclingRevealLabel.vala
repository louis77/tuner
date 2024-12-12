/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file CyclingRevealLabel.vala
 */

 using Gee;
 
 /**
 * @class CyclingRevealLabel
 * @brief A custom widget that reveals a cycling label with animation.
 *
 * This class extends Tuner.RevealLabel to add cycling through of label text
 * and with damping between the different labels so grids do not bounce too much
 *
 * @extends Tuner.RevealLabel
 */
public class Tuner.CyclingRevealLabel : RevealLabel {

    private const int SUBTITLE_MIN_DISPLAY_SECONDS = 5;

    private int _label_max_width = 0;
    private int _label_available_width = 0;
    private uint _label_cycle_id = 0;
    private int _min_count_down;
    private uint16 display_seconds = 1000;   // Mix up the cycle phase start point
    private uint16[] cycle_phases_fast = {5,11,17,19,23}; // Fast cycle times - primes so everyone gets a chance
    private uint16[] cycle_phases_slow = {23,37,43,47,53}; // Ttitle, plus three subtitles
    private uint16[] cycle_phases;  
    private uint8 fast_cycle = 1;

    private Gee.Map<uint, string> sublabels = new Gee.HashMap<uint, string>();


    construct 
    {            
        cycle_phases = cycle_phases_fast;
       // cycle_phases = cycle_phases_slow;

        // Calculate avalable width in chars as the label size varies 
        var context = label_child.get_pango_context();
        var layout = new Pango.Layout(context);
        label_child.size_allocate.connect((allocation) => {   
            // Set the text of the layout (not necessary for metrics but good practice)
            layout.set_text(label_child.label,label_child.label.length);

            // Get font metrics from the layout's context
            var metrics = context.get_metrics(layout.get_font_description(), null);
            if (metrics != null) {
                // Approximate width of a single character
                var char_width = metrics.get_approximate_char_width() / Pango.SCALE;

                // Calculate the number of characters that fit in the allocated width
                _label_available_width = (allocation.width / char_width);
            }
        });
    } // construct


    /**
     * @brief gets/Sets the label
     *
     */
    public new string label { 
        get {
            return base.label;
        } 
        set {
            if ( value == null ) return;
            sublabels.set(0,value.strip());
            base.label = value;
            display_seconds = (display_seconds/cycle_phases[0]) - (uint16) SUBTITLE_MIN_DISPLAY_SECONDS;
            _label_max_width = value.length;
        }
    } // label


    /**
     * @brief Toggles between fast and slow cycle times
     *
     */
    public bool toggle_cycle_time()
    {
        if ( fast_cycle == 0 )
        // slow>fast
        {
            fast_cycle = 1;
            cycle_phases = cycle_phases_fast;
            return true;
        }
        else
        // fast>slow
        {
            fast_cycle = 0;
            cycle_phases = cycle_phases_slow;
            return false;
        }
    } // toggle_cycle_time


    /**
     * @brief Adds a sublabel at the given position
     *
     */
     public void add_sublabel(int position, string? sublabel1, string? sublabel2 = null)
     {
         if ( position <= 0 || position >= cycle_phases.length ) return;    // Main label not sublabel, or too deep
 
         if ( sublabel1 == null || sublabel1.strip().length == 0 ) 
         {
             sublabels.unset(position);
         }
         else
         {
            sublabels.set(position, (sublabel2 == null || sublabel2.strip() == "" ) ? sublabel1.strip() : sublabel1.strip()+" - "+sublabel2.strip() );
         }
     } // add_sublabel
 

    /**
     * @brief Adds a sublabel at the given position
     *
     */
     public void add_stacked_sublabel(int position, string? sublabel1, string? sublabel2 = null)
     {
         if ( position <= 0 || position >= cycle_phases.length ) return;    // Main label not sublabel, or too deep
 
         if ( sublabel1 == null || sublabel1.strip().length == 0 ) 
         {
             sublabels.unset(position);
         }
         else
         {
            sublabels.set(position, (sublabel2 == null || sublabel2.strip() == "" ) ? sublabel1.strip() : sublabel1.strip()+"\n"+sublabel2.strip() );
         }
     } // add_sublabel
 
  
    /**
     * @brief Stops cycling the labels
     *
     */
    public void stop()
    {
        if ( _label_cycle_id > 0 ) 
        {
            Source.remove(_label_cycle_id);
            _label_cycle_id = 0;
            _label_max_width = 0;
            _label_available_width = 0;
        }
    } // stop


    /**
     * @brief Cycles the labels
     *
     */
    public void cycle()
    { 
        if ( _label_cycle_id > 0 ) 
        // Remove any prior timer
        {
            Source.remove(_label_cycle_id);
            _label_cycle_id = 0;
        }

        _label_cycle_id = Timeout.add_seconds_full(Priority.LOW, 1, () => 
        // New label timer
        {
            display_seconds++;

            if ( 0 < _min_count_down-- )
            {
                return Source.CONTINUE;  
            }

            if ( ! child_revealed ) 
            {
                reveal_child = true;
                _min_count_down = SUBTITLE_MIN_DISPLAY_SECONDS;
                return Source.CONTINUE;    // Still processing reveal
            }

            foreach ( var position in sublabels.keys)
            {
                if ( ( display_seconds % cycle_phases[position] == 0 ) && sublabels.get(position) != "" ) 
                {
                    base.label = damper(sublabels.get(position));
                }
            }
   
            return Source.CONTINUE; // Leave timer to be recalled
        });
    } // cycle



    /**
        Dampens the change in label length by padding for center alignment
    */
    private string damper( string text)
    {
        var limit = int.min( _label_available_width, _label_max_width );
        var testtext = text.strip();
        if ( testtext.length >= limit )
        {
            _label_max_width = testtext.length;
            return testtext;
        }

        int total_padding = limit - testtext.length;   // Actual non-space characters
        int factor = 3*limit/(2*total_padding);         // Factor bigger space impact on smaller label widths
        uint left_padding =  int.max(0,total_padding - factor);

       if ( left_padding == 0 ) return testtext;

        return "·%*s%s%*s·".printf(left_padding, "", testtext, left_padding, "");
    } // damper
}

