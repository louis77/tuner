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
        PLAYING,
        BUFFERING,
        STOPPED,
        PAUSED
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

        /**
            returns digest of non-performance data
        */
        public string digest()
        {
            return @"$title-$audio_codec-$nominal_bitrate-$channel_mode\n$genre-$homepage-$organization-$location-$private_data-$container_format-$application_name-$encoder";
        }
    } // Metadata


    /** Signal emitted when the station changes. */
    public signal void station_changed (Model.Station station);

    /** Signal emitted when the player state changes. */
    public signal void state_changed (Gst.PlayerState state);

    /** Signal emitted when the title changes. */
   // public signal void title_changed (string title);

    /** Signal emitted when the title changes. */
    public signal void metadata_changed (Metadata metadata);

    /** Signal emitted when the volume changes. */
    public signal void volume_changed (double volume);

   // public Is playing { get; private set;}
    
    private Model.Station? _station;
    private Gst.PlayerState _player_state;
    public Gst.Player player;
    private Metadata _metadata = Metadata.clear ();

    construct 
    {
        player = new Gst.Player (null, null);

        player.error.connect ((error) => 
        {
            warning (@"player.error: $(error.message)");
        });

        player.state_changed.connect ((state) => 
        {
            warning (@"player.state_changed: $state");
            // Don't forward flickering between playing and buffering
            if (!(current_state == Gst.PlayerState.PLAYING && state == Gst.PlayerState.BUFFERING) && !(state == current_state)) 
            {
                state_changed (state);
                current_state = state;
            }
        });

        player.media_info_updated.connect ((obj) => 
        {
            process_media_info_update (obj);
        });

        player.volume_changed.connect ((obj) => 
        {
            volume_changed(obj.volume);
        });
    }

    /** 
     * @return The current state of the player.
     */
    public Gst.PlayerState current_state { 
        get {
            return _player_state;
        }

        set {
            _player_state = value;
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
        get { return player.volume; }
        set { player.volume = value; }
    }

    /**
     * Plays the specified station.
     * @param station The station to play.
     */
    public void play_station (Model.Station station) {
        player.uri = station.url;
        player.play ();
        station_changed (station);
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
            case Gst.PlayerState.PLAYING:
            case Gst.PlayerState.BUFFERING:
                player.stop ();
                break;
            default:
                player.play ();
                break;
        }
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

            uint numbers = 0;
            var metadata_digest = _metadata.digest ();

            tags.foreach ((list, tag) => 
            {
                switch(tag)
                {
                    case "title" :                   
                        list.get_string(tag, out _metadata.title);
                        break;

                    case "bitrate" :
                        list.get_uint ( tag, out  _metadata.bitrate);
                        break;

                    case "nominal-bitrate" :
                        list.get_uint ( tag, out  _metadata.nominal_bitrate);
                        break;

                    case "minimum-bitrate" :
                        list.get_uint ( tag, out  _metadata.minimum_bitrate);
                        break;

                    case "maximum-bitrate" :
                        list.get_uint ( tag, out  _metadata.maximum_bitrate);
                        break;
            
                    case "audio-codec" :   
                        list.get_string(tag, out _metadata.audio_codec);
                        break;

                    case "channel-mode" :   
                        list.get_string(tag, out _metadata.channel_mode);
                        break;

                    case "genre" :   
                        list.get_string(tag, out _metadata.genre);
                        break;

                    case "homepage" :   
                        list.get_string(tag, out _metadata.homepage);
                        break;

                    case "organization" :   
                        list.get_string(tag, out _metadata.organization);
                        break;

                    case "location" :   
                        list.get_string(tag, out _metadata.location);
                        break;
        
                    case "private-data" :   
                        list.get_string(tag, out _metadata.private_data);
                        break;
        
                    case "container-format" :   
                        list.get_string(tag, out _metadata.container_format);
                        break;
    
                    case "application-name" :   
                        list.get_string(tag, out _metadata.application_name);
                        break;

                    case "encoder" :   
                        list.get_string(tag, out _metadata.encoder);
                            break;
        
                    case "datetime" :   
                        list.get_date_time (tag, out _metadata.datetime);    
                        break;                
            
                    case "has-crc" :   
                        list.get_boolean (tag, out _metadata.has_crc);
                        break;

                    case "track-number" :
                        list.get_uint ( tag, out numbers); 
                        _metadata.track_number = (numbers > 0 ? numbers.to_string () : "");
                        break;
   
                    default :
                        warning(@">>Unknown Metadata: >$tag<");
                        break;
                }
            });
            if ( metadata_digest != _metadata.digest () ) metadata_changed (_metadata);
        }
    }

    //  private static Is playstate (Gst.PlayerState state) {
    //      warning(@"playstate ...");
    //      warning(@"playstate State:$(state)");
    //      switch (state) {
    //          case  Gst.PlayerState.PLAYING:
    //              return Is.PLAYING;
    //          case  Gst.PlayerState.BUFFERING:
    //              return Is.BUFFERING;
    //          case Gst.PlayerState.STOPPED:
    //              return Is.STOPPED;
    //          case Gst.PlayerState.PAUSED:
    //              return Is.STOPPED;
    //          default:
    //          warning(@"Problemo ...");
    //              assert_not_reached();
    //      }
    //  }
}
