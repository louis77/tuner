/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PlayerController.vala
 */

 using Gst;

/**
 * @class Tuner.PlayerController
 * @brief Manages the playback of radio stations.
 *
 * This class handles the player state, volume control, and metadata extraction
 * from the media stream. It emits signals when the station, state, title,
 * or volume changes.
 */
public class Tuner.PlayerController : GLib.Object 
{
    /**
     * @brief the Tuner play state
     *
     * Using our own play state keeps gstreamer deps out of the rest of the code
     */
    public enum Is {
        BUFFERING,
        PAUSED,
        PLAYING,
        STOPPED,        
        STOPPED_ERROR
    } // Is

 
    /** Signal emitted when the station changes. */
    public signal void station_changed_sig (Model.Station station);

    /** Signal emitted when the player state changes. */
    public signal void state_changed_sig (Model.Station station, Is state);

    //  /** Signal emitted when the title changes. */
    public signal void metadata_changed_sig (Metadata metadata);

    /** Signal emitted when the volume changes. */
    public signal void volume_changed_sig (double volume);

    /** Signal emitted every ten minutes that a station has been playing continuously. */
    public signal void tape_counter_sig (Model.Station station);

    /** @brief Signal emitted when the shuffle mode changes   */
    public signal void shuffle_mode_sig(bool shuffle);

    /** @brief Signal emitted when the shuffle is requested   */
    public signal void shuffle_requested_sig();

    /** The error received when playing, if any */
    public bool play_error{ get; private set; }

    private const uint TEN_MINUTES_IN_SECONDS = 606;  // tape counter timer - 10 mins plus 1%
    
    private Player _player;
    private Model.Station _station; 
    private Metadata _metadata;
    private Is _player_state;
    private string _player_state_name;
    private uint _tape_counter_id = 0;


    construct 
    {
        _player = new Player (null, null);

        _player.error.connect ((error) => 
        // There was an error playing the stream
        {
            play_error = true;
            warning (@"player error on url $(_player.uri): $(error.message)");
        });

        _player.media_info_updated.connect ((obj) => 
        // Stream metadata received
        {
            if  (_metadata.process_media_info_update (obj))  metadata_changed_sig (_metadata);
        });

        _player.volume_changed.connect ((obj) => 
        // Volume changed
        {
            volume_changed_sig(obj.volume);
            app().settings.volume =  obj.volume;
        });

        _player.state_changed.connect ((state) => 
        // Play state changed
        {
            // Don't forward flickering between playing and buffering
            if (    !(state == PlayerState.PLAYING && state == PlayerState.BUFFERING) 
                && (_player_state_name != state.get_name ())) 
            {
                _player_state_name = state.get_name ();
                set_play_state (state.get_name ());
            }
        });

    } // construct


    /** 
     * @brief Process the Player play state changes emited from gstreamer.
     * 
     * Actions are set in a seperate thread as attempting UI interaction 
     * on the gstreamer signal results in a seg fault
     */
    private void set_play_state (string state) 
    {
        switch (state) {
            case "playing":
                Gdk.threads_add_idle (() => {
                    player_state = Is.PLAYING;
                    return false;
                });
                break;

            case "buffering":            
                Gdk.threads_add_idle (() => {
                    player_state = Is.BUFFERING;
                    return false;
                });
                break;

            default :       //  STOPPED:
                if ( play_error )
                {
                    Gdk.threads_add_idle (() => {
                        player_state = Is.STOPPED_ERROR;
                        return false;
                    });
                }
                else
                {
                    Gdk.threads_add_idle (() => {
                        player_state = Is.STOPPED;
                        return false;
                    });
                }
                break;
        }
    } // set_reverse_symbol


    /** 
     * @brief Player State getter/setter
     * 
     * Set by player signal. Does the tape counter emit
     */
     public Is player_state { 
        get {
            return _player_state;
        } // get

        private set {
            _player_state = value;
            state_changed_sig( _station, value );

            if ( value == Is.STOPPED || value == Is.STOPPED_ERROR )
            {
                if ( _tape_counter_id > 0 ) 
                {
                    Source.remove(_tape_counter_id);
                    _tape_counter_id = 0;
                }
            } 
            else if ( value == Is.PLAYING )
            {
                _tape_counter_id = Timeout.add_seconds_full(Priority.LOW, TEN_MINUTES_IN_SECONDS, () => 
                {
                    tape_counter_sig(_station);
                    return Source.CONTINUE;
                });
            }
        } // set
    } // player_state


    /** 
     * @brief Station
     * @return The current station being played.
     */
    public Model.Station station {
        get {
            return _station;
        }
        set {
            if ( ( _station == null ) ||  ( _station != value ) )
            {
                _metadata =  new Metadata();
                _station = value;
                play_station (_station);
            }
        }
    } // station


    /** 
     * @brief Volume
     * @return The current volume of the player.
     */
    public double volume {
        get { return _player.volume; }
        set { _player.volume = value; }
    }


    /**
     * @brief Plays the specified station.
     *
     * @param station The station to play.
     */
    public void play_station (Model.Station station) 
    {
        _player.stop ();
        //station_changed_sig (station);
        _player.uri = ( station.urlResolved != null && station.urlResolved != "" ) ? station.urlResolved : station.url; 
        play_error = false;
        _player.play ();
        //  station_changed_sig (station);
    }


    /**
     * @brief Checks if the player has a station to play.
     *
     * @return True if a station is ready to be played
     */
    public bool can_play () {
        return _station != null;
    } // can_play


    /**
     * @brief Toggles play/pause state of the player.
     */
     public void play_pause () {
        switch (_player_state) {
            case Is.PLAYING:
            case Is.BUFFERING:
                _player.stop ();
                break;
            default:
                _player.play ();
                break;
        }
    } // play_pause


    /**
     * @brief Stops the player
     *
     */
    public void stop () {
        _player.stop ();
    } //  stop


    public void shuffle ()
    {
        shuffle_requested_sig();
    } // shuffle
  
    /**
     * @class Metadata
     *
     * @brief Stream Metadata transform
     *
     */
    public class Metadata : GLib.Object
    {
        private static string[,] METADATA_TITLES = 
        // Ordered array of tags and descriptions
        {
            {"title",_("Title")}
            ,{"artist",_("Artist")}
            ,{"album",_("Album")}
            ,{"image",_("Image")}
            ,{"genre",_("Genre")}
            ,{"homepage",_("Homepage")}
            ,{"organization",_("Organization")}
            ,{"location",_("Location")}
            ,{"extended-comment",_("Extended Comment")}
            ,{"bitrate",_("Bitrate")}
            ,{"audio-codec",_("Audio Codec")}
            ,{"channel-mode",_("Channel Mode")}
            ,{"track-number",_("Track Number")}
            ,{"track-count",_("Track Count")}
            ,{"nominal-bitrate",_("Nominal Bitrate")}
            ,{"minimum-bitrate",_("Minimum Bitrate")}
            ,{"maximum-bitrate",_("Maximim Bitrate")}
            ,{"container-format",("Container Format")}
            ,{"application-name",_("Application Name")}
            ,{"encoder",_("Encoder")}
            ,{"encoder-version",_("Encoder Version")}
            ,{"datetime",_("Date Time")}
            ,{"private-data",_("Private Data")}
            ,{"has-crc",_("Has CRC")}
        };  
            
        private static Gee.List<string> METADATA_TAGS =  new Gee.ArrayList<string> ();
    
        static construct  {
    
            uint8 tag_index = 0;
            foreach( var tag in METADATA_TITLES )
            // Replicating the order in METADATA_TITLES
            {
                if ( (tag_index++)%2 == 0) METADATA_TAGS.insert (tag_index/2, tag );
            }
        }

        public string all_tags { get; private set; default = ""; }
        public string title { get; private set; default = ""; }
        public string artist { get; private set; default = ""; }
        public string image { get; private set; default = ""; }
        public string genre { get; private set; default = ""; }
        public string homepage { get; private set; default = ""; }
        public string audio_info { get; private set; default = ""; }
        public string org_loc { get; private set; default = ""; }
        public string pretty_print { get; private set; default = ""; }

        private Gee.Map<string,string> _metadata_values = new Gee.HashMap<string,string>();  // Hope it come out in order

        
        /**
        * Extracts the metadata from the media stream.
        *
        * @param media_info The media information stream
        * @return true if the metadata has changed
        */
        internal bool process_media_info_update (PlayerMediaInfo media_info) 
        {
            var streamlist = media_info.get_stream_list ().copy ();

            title  = ""; 
            artist = "";
            image = "";
            genre  = ""; 
            homepage  = ""; 
            audio_info  = ""; 
            org_loc  = ""; 
            pretty_print  = ""; 

            foreach (var stream in streamlist) // Hopefully just one metadata stream
            {
                var? tags = stream.get_tags (); // Get the raw tags

                if ( tags == null ) break;  // No tags, break on this metadata stream

                if ( all_tags == tags.to_string ()) return false; // Compare to all tags and if no change return false

                all_tags = tags.to_string ();
                debug(@"All Tags: $all_tags");
            
                string? s = null;
                bool b = false;
                uint u = 0;

                tags.foreach ((list, tag) => 
                {
                    var index = METADATA_TAGS.index_of (tag);

                    if ( index == -1 ) 
                    {
                        warning(@"New meta tag: $tag");
                        return;
                    }
                
                    var type = (list.get_value_index(tag, 0)).type();  

                    switch( type )
                    {
                        case  GLib.Type.STRING :
                            list.get_string(tag, out s);
                            _metadata_values.set ( tag,  s);
                            break;
                        case  GLib.Type.UINT :
                            list.get_uint(tag, out u);
                            _metadata_values.set ( tag,  @"$(u/1000)K");
                            break;
                        case  GLib.Type.BOOLEAN :
                            list.get_boolean (tag, out b);
                            _metadata_values.set ( tag,  b.to_string ());
                            break;
                        default :
                            warning(@"New Tag type: $(type.name())");
                            break;
                    }
                }); // tags.foreach

                if ( _metadata_values.has_key ("title" )) _title = _metadata_values.get ("title");
                if ( _metadata_values.has_key ("artist" )) _artist = _metadata_values.get ("artist");
                if ( _metadata_values.has_key ("image" )) _image = _metadata_values.get ("image");
                if ( _metadata_values.has_key ("genre" )) _genre = _metadata_values.get ("genre");
                if ( _metadata_values.has_key ("homepage" )) _homepage = _metadata_values.get ("homepage");

                if ( _metadata_values.has_key ("audio_codec" )) _audio_info = _metadata_values.get ("audio_codec ");
                if ( _metadata_values.has_key ("bitrate" )) _audio_info += _metadata_values.get ("bitrate ");
                if ( _metadata_values.has_key ("channel_mode" )) _audio_info += _metadata_values.get ("channel_mode");
                if ( _audio_info != null && _audio_info.length > 0 ) _audio_info = safestrip(_audio_info);
                
                if ( _metadata_values.has_key ("organization" )) _org_loc = _metadata_values.get ("organization ");
                if ( _metadata_values.has_key ("location" )) _org_loc += _metadata_values.get ("location");
                if ( _org_loc != null && _org_loc.length > 0) org_loc = safestrip(_org_loc);

                StringBuilder sb = new StringBuilder ();
                foreach ( var tag in METADATA_TAGS ) 
                // Pretty print
                {
                    if ( _metadata_values.has_key(tag) ) 
                    {
                        sb.append ( METADATA_TITLES[METADATA_TAGS.index_of (tag),1])
                        .append(" : ")
                        .append( _metadata_values.get (tag) )
                        .append("\n");
                    }
                }
                pretty_print = sb.truncate (sb.len-1).str;
            } // foreach
            
            return true;
        } // process_media_info_update
    } // Metadata
} // PlayerController
