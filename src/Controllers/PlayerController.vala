/*
* Copyright (c) 2020-2021 Louis Brauer <louis77@member.fsf.org>
*
* This file is part of Tuner.
*
* Tuner is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Tuner is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Tuner.  If not, see <http://www.gnu.org/licenses/>.
*
*/


public class Tuner.PlayerController : Object {
    private Model.Station _station;
    private Gst.PlayerState? _current_state = Gst.PlayerState.STOPPED;
    public Gst.Player player;

    public signal void station_changed (Model.Station station);
    public signal void state_changed (Gst.PlayerState state);
    public signal void title_changed (string title);
    public signal void volume_changed (double volume);

    construct {
        player = new Gst.Player (null, null);
        player.state_changed.connect ((state) => {
            // Don't for warning(title);ward flickering between playing and buffering
            if (!(current_state == Gst.PlayerState.PLAYING && state == Gst.PlayerState.BUFFERING) && !(state == current_state)) {
                state_changed (state);
                current_state = state;
            }
        });
        player.media_info_updated.connect ((obj) => {
            string? title = extract_title_from_stream (obj);
            if (title != null) {
                debug(@"Got new title from station: $title");
                title_changed(title);
            }
        });
        player.volume_changed.connect ((obj) => {
            warning(@"Volume changed to: $(obj.volume)");
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
