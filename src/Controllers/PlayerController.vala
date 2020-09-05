/*
* Copyright (c) 2020 Louis Brauer (https://github.com/louis77)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Louis Brauer <louis77@member.fsf.org>
*/


public class Tuner.PlayerController : Object {
    private Model.Station _station;
    private Gst.PlayerState? _current_state = Gst.PlayerState.STOPPED;
    public Gst.Player player;

    public signal void station_changed (Model.Station station);
    public signal void state_changed (Gst.PlayerState state);
    public signal void title_changed (string title);

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
