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
    public signal void metadata_changed_sig (Model.Station station, Model.Metadata metadata);

    /** Signal emitted when the volume changes. */
    public signal void volume_changed_sig (double volume);

    /** Signal emitted every ten minutes that a station has been playing continuously. */
    public signal void tape_counter_sig (Model.Station station);

    /** @brief Signal emitted when the shuffle is requested   */
    public signal void shuffle_requested_sig();

    /** The error received when playing, if any */
    public bool play_error{ get; private set; }

    private const uint TEN_MINUTES_IN_SECONDS = 606;  // tape counter timer - 10 mins plus 1%
    
    private Player _player;
    private Model.Station _station; 
    private Model.Metadata _metadata;
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
            info (@"player error on url $(_player.uri): $(error.message)");
        });

		_player.media_info_updated.connect ((obj) =>
		// Stream metadata received
		{
			if (_metadata.process_media_info_update (obj))
				metadata_changed_sig (_station, _metadata);
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

			if (value == Is.STOPPED || value == Is.STOPPED_ERROR)
			{
				if (_tape_counter_id > 0)
				{
					Source.remove(_tape_counter_id);
					_tape_counter_id = 0;
				}
			}
			else if (value == Is.PLAYING)
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
                _metadata =  new Model.Metadata();
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
        _station = station;
        station_changed_sig (_station);
		_player.uri = (_station.urlResolved != null && _station.urlResolved != "") ? _station.urlResolved : _station.url;
		play_error  = false;
		Timeout.add (500, () =>
		// Wait a half of a second to play the station to help flush metadata
		{
			_player.play ();
			return Source.REMOVE;
		});
	}     // play_station


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


    /**
     * Shuffles the current playlist.
     *
     * This method randomizes the order of the tracks in the current playlist.
     */
	public void shuffle ()
	{
		shuffle_requested_sig();
	} // shuffle
} // PlayerController
