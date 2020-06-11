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
* Authored by: Louis Brauer <louis@brauer.family>
*/

namespace Tuner.DBus {

    const string ServerName = "org.mpris.MediaPlayer2.Tuner";
    const string ServerPath = "/org/mpris/MediaPlayer2";

    public void initialize () {
        var owner_id = Bus.own_name(
            BusType.SESSION,
            ServerName,
            BusNameOwnerFlags.NONE,
            onBusAcquired,
            () => {},
            () => warning (@"Could not acquire name $ServerName, the DBus interface will not be available")
        );

        if (owner_id == 0) {
            warning ("Could not initialize MPRIS session.\n");
        }
    }

    void onBusAcquired (DBusConnection conn) {
        try {
            conn.register_object<IMediaPlayer2> (ServerPath, new MediaPlayer ());
            conn.register_object<IMediaPlayer2Player> (ServerPath, new MediaPlayerPlayer (conn));
        } catch (IOError e) {
            error (@"Could not acquire path $ServerPath: $(e.message)");
        }
        info (@"DBus Server is now listening on $ServerName $ServerPath...\n");
    }

    public class MediaPlayer : Object, DBus.IMediaPlayer2 {
        public void raise() throws DBusError, IOError {
            debug ("DBus Raise() requested");
            var now = new DateTime.now_local ();
            var timestamp = (uint32) now.to_unix ();
            Application.instance.window.present_with_time (timestamp);
        }

        public void quit() throws DBusError, IOError {
            debug ("DBus Quit() requested");
        }

        public bool can_quit {
            get {
                return true;
            }
        }

        public bool can_raise {
            get {
                return true;
            }
        }

        public bool has_track_list {
            get {
                return false;
            }
        }

        public string desktop_entry {
            owned get {
                return ((Gtk.Application) GLib.Application.get_default ()).application_id;
            }
        }

        public string identity {
            owned get {
                return "tuner@exe";
            }
        }

        public string[] supported_uri_schemes {
            owned get {
                return {"http", "https"};
            }
        }

        // TODO
        public string[] supported_mime_types {
            owned get {
                return {"audio/mp3"};
            }
        }

        public bool fullscreen { get; set; default = false; }
        public bool can_set_fullscreen {
            get {
                debug ("CanSetFullscreen() requested");
                return true;
            }
        }
    }


    public class MediaPlayerPlayer : Object, DBus.IMediaPlayer2Player {
        [DBus (visible = false)]
        public unowned DBusConnection conn { get; construct set; }

        private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";

        public MediaPlayerPlayer (DBusConnection conn) {
            Object (conn: conn);
        }

        public void next() throws DBusError, IOError {
            debug ("DBus Next() requested");
        }

        public void previous() throws DBusError, IOError {
            debug ("DBus Previous() requested");
        }

        public void pause() throws DBusError, IOError {
            debug ("DBus Pause() requested");
        }

        public void play_pause() throws DBusError, IOError {
            debug ("DBus PlayPause() requested");
            Application.instance.player.player.stop();
        }

        public void stop() throws DBusError, IOError {
            debug ("DBus stop() requested");
            Application.instance.player.player.stop();
        }

        public void play() throws DBusError, IOError {
            debug ("DBus Play() requested");
        }

        public void seek(int64 Offset) throws DBusError, IOError {
            debug ("DBus Seek() requested");
        }

        public void set_position(ObjectPath TrackId, int64 Position) throws DBusError, IOError {
            debug ("DBus SetPosition() requested");
        }

        public void open_uri(string uri) throws DBusError, IOError {
            debug ("DBus OpenUri() requested");
        }

        // Already defined in the interface
        // public signal void seeked(int64 Position);

        public string playback_status {
            owned get {

                var state = Application.instance.player.current_state ?? Gst.PlayerState.STOPPED;

                switch (state) {
                case Gst.PlayerState.PLAYING:
                case Gst.PlayerState.BUFFERING:
                    return "Playing";
                case Gst.PlayerState.STOPPED:
                    return "Stopped";
                case Gst.PlayerState.PAUSED:
                    return "Paused";
                }

                return "Stopped";
            }
        }

        public string loop_status {
            owned get {
                return "None";
            }
        }

        public double rate { get; set; }
        public bool shuffle { get; set; }

        public HashTable<string, Variant>? metadata {
            owned get {
                debug ("DBus metadata requested");
                var table = new HashTable<string, Variant> (str_hash, str_equal);

                var station = Application.instance.player.station;
                if (station != null) {
                    table.insert ("xesam:title", station.title);
                } else {
                    table.insert ("xesam:title", "Tuner");
                }

                return table;
            }
        }
        public double volume { owned get; set; }
        public int64 position { get; }
        public double minimum_rate {  get; set; }
	    public double maximum_rate {  get; set; }

	    public bool can_go_next {
	        get {
    	        debug ("CanGoNext() requested");
	            return false;
	        }
	    }

	    public bool can_go_previous {
	        get {
    	        debug ("CanGoPrevious() requested");
	            return false;
	        }
	    }

        public bool can_play {
            get {
                debug ("CanPlay() requested");
                return Application.instance.player.can_play ();
            }
        }
	    public bool can_pause {  get; }
	    public bool can_seek {  get; }

	    public bool can_control {
	        get {
                debug ("CanControl() requested");
                return true;
            }
        }

    }
}
