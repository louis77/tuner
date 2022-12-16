/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */


public class Tuner.PlayerController : Object {
    private Model.Station _station;
    private Gst.PlayerState? _current_state = Gst.PlayerState.STOPPED;
    public Gst.Player player;
	public string currentTitle = " ";

    public signal void station_changed (Model.Station station);
    public signal void state_changed (Gst.PlayerState state);
    public signal void title_changed (string title);
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

    public Gst.PlayerState? current_state { 
        get {
            return _current_state;
        }

        set {
            _current_state = value;
        }
    }

    public Model.Station station {
        get {
            return _station;
        }

        set {
            _station = value;
            play_station (_station);
        }
    }

    public double volume {
        get { return player.volume; }
        set { player.volume = value; }
    }

    public void play_station (Model.Station station) {
        player.uri = station.url;
        player.play ();
        station_changed (station);
    }

    public bool can_play () {
        return _station != null;
    }

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
