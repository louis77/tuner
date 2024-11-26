/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class Tuner.PlayerController
 * @brief Manages the playback of radio stations.
 *
 * This class handles the player state, volume control, and title extraction
 * from the media stream. It emits signals when the station, state, title,
 * or volume changes.
 */
public class Tuner.PlayerController : Object {
    private Model.Station _station;
    private Gst.PlayerState _current_state = Gst.PlayerState.STOPPED;
    public Gst.Player player;
    public string currentTitle = " ";

    /** Signal emitted when the station changes. */
    public signal void station_changed (Model.Station station);
    /** Signal emitted when the player state changes. */
    public signal void state_changed (Gst.PlayerState state);
    /** Signal emitted when the title changes. */
    public signal void title_changed (string title);
    /** Signal emitted when the volume changes. */
    public signal void volume_changed (double volume);

    construct {
        player = new Gst.Player (null, null);
        player.state_changed.connect ((state) => {
            // Don't forward flickering between playing and buffering
            if (!(current_state == Gst.PlayerState.PLAYING && state == Gst.PlayerState.BUFFERING) && !(state == current_state)) {
                state_changed (state);
                current_state = state;
            }
        });
        player.media_info_updated.connect ((obj) => {
            string? title = extract_title_from_stream (obj);
            if (title != null) {
                debug(@"Got new title from station: $title");
                currentTitle = title;
                title_changed(title);
            }
        });
        player.volume_changed.connect ((obj) => {
            volume_changed(obj.volume);
        });
    }

    /** 
     * @return The current state of the player.
     */
    public Gst.PlayerState current_state { 
        get {
            return _current_state;
        }

        set {
            _current_state = value;
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
            _station = value;
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
        switch (_current_state) {
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
    private string? extract_title_from_stream (Gst.PlayerMediaInfo media_info) {
        string? title = null;
        var streamlist = media_info.get_stream_list ().copy ();
        foreach (var stream in streamlist) {
            var tags = stream.get_tags ();
            tags.foreach ((list, tag) => {
                if (tag == "title") {
                    list.get_string(tag, out title);
                }
            });
        }
        return title;
    }
}
