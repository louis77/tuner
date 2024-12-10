/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PlayerController.vala
 */

/**
 * @class Tuner.PlayerController
 * @brief Manages the playback of radio stations.
 *
 * This class handles the player state, volume control, and title extraction
 * from the media stream. It emits signals when the station, state, title,
 * or volume changes.
 */
public class Tuner.PlayerController : Object 
{
    public enum Is {
        BUFFERING,
        PAUSED,
        PLAYING,
        STOPPED,        
        STOPPED_ERROR
    }

    public struct Metadata
    {
        public string title;
        public uint bitrate;
        public string audio_codec;
        public string channel_mode;
        public string track_number;
        public string genre;
        public string homepage;
        public string organization;
        public string location;
        public string private_data;
        public string container_format;
        public string application_name;
        public string encoder;
        public Gst.DateTime  datetime;
        public bool has_crc;
        public uint nominal_bitrate;    // Performance data
        public uint minimum_bitrate;    // Performance data
        public uint maximum_bitrate;    // Performance data

        public static Metadata clear()
        {
            Metadata m =  Metadata();
            m.title = "";
            m.audio_codec = "";
            m.channel_mode = "";
            m.track_number = "";
            m.genre = "";
            m.homepage = "";
            m.organization = "";
            m.location = "";
            m.private_data = "";
            m.container_format = "";
            m.application_name = "";
            m.encoder = "";
            return m;
        }

        public void update(Gst.TagList list, string tag)
        {
            switch(tag)
            {
                case "title" :                   
                    list.get_string(tag, out title);
                    break;

                case "bitrate" :
                    list.get_uint ( tag, out  bitrate);
                    break;

                case "nominal-bitrate" :
                    list.get_uint ( tag, out  nominal_bitrate);
                    break;

                case "minimum-bitrate" :
                    list.get_uint ( tag, out  minimum_bitrate);
                    break;

                case "maximum-bitrate" :
                    list.get_uint ( tag, out  maximum_bitrate);
                    break;
        
                case "audio-codec" :   
                    list.get_string(tag, out audio_codec);
                    break;

                case "channel-mode" :   
                    list.get_string(tag, out channel_mode);
                    break;

                case "genre" :   
                    list.get_string(tag, out genre);
                    break;

                case "homepage" :   
                    list.get_string(tag, out homepage);
                    break;

                case "organization" :   
                    list.get_string(tag, out organization);
                    break;

                case "location" :   
                    list.get_string(tag, out location);
                    break;
    
                case "private-data" :   
                    list.get_string(tag, out private_data);
                    break;
    
                case "container-format" :   
                    list.get_string(tag, out container_format);
                    break;

                case "application-name" :   
                    list.get_string(tag, out application_name);
                    break;

                case "encoder" :   
                    list.get_string(tag, out encoder);
                        break;
    
                case "datetime" :   
                    list.get_date_time (tag, out datetime);    
                    break;                
        
                case "has-crc" :   
                    list.get_boolean (tag, out has_crc);
                    break;

                case "track-number" :
                    uint numbers = 0;
                    list.get_uint ( tag, out numbers); 
                    track_number = (numbers > 0 ? numbers.to_string () : "");
                    break;

                default :
                    warning(@">>Metadata Unknown: >$tag<<<");
                    break;
            }
        }

        /**
            returns digest of non-performance data
        */
        public string digest()
        {
            return @"$title-$audio_codec-$nominal_bitrate-$channel_mode\n$genre-$homepage-$organization-$location-$private_data-$container_format-$application_name-$encoder";
        }
    } // Metadata


    /** Signal emitted when the station changes. */
    public signal void station_changed_sig (Model.Station station);

    /** Signal emitted when the player state changes. */
    public signal void state_changed_sig (Is state);

    /** Signal emitted when the title changes. */
    public signal void metadata_changed_sig (Metadata metadata);

    /** Signal emitted when the volume changes. */
    public signal void volume_changed_sig (double volume);

    /** Signal emitted every ten minutes that a station has been playing continuously. */
    public signal void tape_counter_sig (Model.Station station);

    // public Is playing { get; private set;}

    public bool play_error{ get; private set; }
   // public Is _player_state;

    private const uint TEN_MINUTES_IN_SECONDS = 600;

    private uint _tape_counter_id = 0;
    
    private Gst.Player _player;
    private Model.Station _station; 
    private Metadata _metadata = Metadata.clear ();
    private Is _player_state;
    private string _player_state_name;
   // private string _playing_url;

    construct 
    {
        _player = new Gst.Player (null, null);

        _player.error.connect ((error) => 
        {
            play_error = true;
            warning (@"player error on url $(_player.uri): $(error.message)");
        });

        _player.media_info_updated.connect ((obj) => 
        {
            process_media_info_update (obj);
        });

        _player.volume_changed.connect ((obj) => 
        {
            volume_changed_sig(obj.volume);
            app().settings.volume =  obj.volume;
        });

        _player.state_changed.connect ((state) => 
        {
            debug (@"player.state_changed: $state");
            // Don't forward flickering between playing and buffering
            if (    !(state == Gst.PlayerState.PLAYING && state == Gst.PlayerState.BUFFERING) 
                && (_player_state_name != state.get_name ())) 
            {
                _player_state_name = state.get_name ();
                set_play_state (state.get_name ());
            }
        });
    }

    /*
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
     * @return The current state of the player.
     */
     public Is player_state { 
        get {
            return _player_state;
        }

        set {
            _player_state = value;
            state_changed_sig( value);

            warning (@"Is player_state $_player_state");
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
                    warning (@"Is player_state emitting");
                    tape_counter_sig(_station);
                    return Source.CONTINUE;
                });
            }

        }
    }


    /** 
     * @return The current station being played.
     */
    public Model.Station station {
        get {
            return _station;
        }

        set {
            if ( ( _station == null ) ||  ( _station != value ) )
            {
                _station = value;
                _metadata = Metadata.clear ();
            }
            play_station (_station);
        }
    }

    /** 
     * @return The current volume of the player.
     */
    public double volume {
        get { return _player.volume; }
        set { _player.volume = value; }
    }

    /**
     * Plays the specified station.
     *
     * @param station The station to play.
     */
    public void play_station (Model.Station station) 
    {
        _player.uri = ( station.urlResolved != null && station.urlResolved != "" ) ? station.urlResolved : station.url;
        play_error = false;
        _player.play ();
        station_changed_sig (station);
    }

    /**
     * Checks if the player can play the current station.
     * @return True if a station is set, false otherwise.
     */
    public bool can_play () {
        return _station != null;
    }

    /**
     * Toggles play/pause state of the player.
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
    }

    public void stop () {
        _player.stop ();
    }

    /**
     * Extracts the title from the media stream.
     * @param media_info The media information from which to extract the title.
     * @return The extracted title, or null if not found.
     */
    private void process_media_info_update (Gst.PlayerMediaInfo media_info) 
    {
        var streamlist = media_info.get_stream_list ().copy ();
        foreach (var stream in streamlist) 
        {
            var? tags = stream.get_tags ();

            if ( tags == null ) break;

            var metadata_digest = _metadata.digest ();

            tags.foreach ((list, tag) => 
            {
                _metadata.update ( list,  tag);
            });
            if ( metadata_digest != _metadata.digest () ) metadata_changed_sig (_metadata);
        }
    }
}
