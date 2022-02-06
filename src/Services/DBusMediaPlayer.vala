/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

namespace Tuner.DBus {

    const string ServerName = "org.mpris.MediaPlayer2.Tuner";
    const string ServerPath = "/org/mpris/MediaPlayer2";
    private bool is_initialized = false;

    public void initialize () {
        if (is_initialized) {
            // App is already running, do nothing
            return;
        }

        var owner_id = Bus.own_name(
            BusType.SESSION,
            ServerName,
            BusNameOwnerFlags.NONE,
            onBusAcquired,
            () => {
                is_initialized = true;
            },
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
        info (@"DBus Server is now listening on $ServerName $ServerPath…\n");
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
        private string _playback_status = "Stopped";
        private uint update_metadata_source = 0;
        private uint send_property_source = 0;
        private HashTable<string,Variant> changed_properties = null;

        [DBus (visible = false)]
        public unowned DBusConnection conn { get; construct set; }

        private const string INTERFACE_NAME = "org.mpris.MediaPlayer2.Player";

        public MediaPlayerPlayer (DBusConnection conn) {
            Object (conn: conn);
            Application.instance.player.state_changed.connect ((state) => {
                switch (state) {
                case Gst.PlayerState.PLAYING:
                case Gst.PlayerState.BUFFERING:
                    playback_status = "Playing";
                    break;
                case Gst.PlayerState.STOPPED:
                    playback_status = "Stopped";
                    break;
                case Gst.PlayerState.PAUSED:
                    playback_status = "Paused";
                    break;
                }
            });
        }

        public void next() throws DBusError, IOError {
            // debug ("DBus Next() requested");
        }

        public void previous() throws DBusError, IOError {
            // debug ("DBus Previous() requested");
        }

        public void pause() throws DBusError, IOError {
            //  debug ("DBus Pause() requested");
        }

        public void play_pause() throws DBusError, IOError {
            //  debug ("DBus PlayPause() requested");
            Application.instance.player.play_pause();
        }

        public void stop() throws DBusError, IOError {
            //  debug ("DBus stop() requested");
            Application.instance.player.player.stop();
        }

        public void play() throws DBusError, IOError {
            //  debug ("DBus Play() requested");
            Application.instance.player.play_pause ();
        }

        public void seek(int64 Offset) throws DBusError, IOError {
            //  debug ("DBus Seek() requested");
        }

        public void set_position(ObjectPath TrackId, int64 Position) throws DBusError, IOError {
            //  debug ("DBus SetPosition() requested");
        }

        public void open_uri(string uri) throws DBusError, IOError {
            //  debug ("DBus OpenUri() requested");
        }

        // Already defined in the interface
        // public signal void seeked(int64 Position);

        public string playback_status {
            owned get {
                //  debug ("DBus PlaybackStatus() requested");
                return _playback_status;
            }
            set {
                _playback_status = value;
                trigger_metadata_update ();
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
                //  debug ("DBus metadata requested");
                var table = new HashTable<string, Variant> (str_hash, str_equal);
                table.insert ("xesam:title", "Tuner");

                var station = Application.instance.player.station;
                if (station != null) {
                    var station_title = station.title;
                    table.insert ("xesam:artist", get_simple_string_array (station_title));
                } else {
                    table.insert ("xesam:artist", get_simple_string_array (null));
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
    	        //  debug ("CanGoNext() requested");
	            return false;
	        }
	    }

	    public bool can_go_previous {
	        get {
    	        //  debug ("CanGoPrevious() requested");
	            return false;
	        }
	    }

        public bool can_play {
            get {
                //  debug ("CanPlay() requested");
                return Application.instance.player.can_play ();
            }
        }
	    public bool can_pause {  get; }
	    public bool can_seek {  get; }

	    public bool can_control {
	        get {
                //  debug ("CanControl() requested");
                return true;
            }
        }

        private void trigger_metadata_update () {
            if (update_metadata_source != 0) {
                Source.remove (update_metadata_source);
            }

            update_metadata_source = Timeout.add (300, () => {
                Variant variant = playback_status;

                queue_property_for_notification ("PlaybackStatus", variant);
                queue_property_for_notification ("Metadata", metadata);
                update_metadata_source = 0;
                return false;
            });
        }

        private void queue_property_for_notification (string property, Variant val) {
            if (changed_properties == null) {
                changed_properties = new HashTable<string, Variant> (str_hash, str_equal);
            }

            changed_properties.insert (property, val);

            if (send_property_source == 0) {
                send_property_source = Idle.add (send_property_change);
            }
        }

        private bool send_property_change () {
            if (changed_properties == null) {
                return false;
            }

            var builder = new VariantBuilder (VariantType.ARRAY);
            var invalidated_builder = new VariantBuilder (new VariantType ("as"));

            foreach (string name in changed_properties.get_keys ()) {
                Variant variant = changed_properties.lookup (name);
                builder.add ("{sv}", name, variant);
            }

            changed_properties = null;

            try {
                conn.emit_signal (null,
                                  "/org/mpris/MediaPlayer2",
                                  "org.freedesktop.DBus.Properties",
                                  "PropertiesChanged",
                                  new Variant ("(sa{sv}as)",
                                             INTERFACE_NAME,
                                             builder,
                                             invalidated_builder)
                                 );
            } catch (Error e) {
                debug (@"Could not send MPRIS property change: $(e.message)");
            }
            send_property_source = 0;
            return false;
        }

        private static string[] get_simple_string_array (string? text) {
            if (text == null) {
                return new string[0];
            }
            string[] array = new string[0];
            array += text;
            return array;
        }
    }
}
