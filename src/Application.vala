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

public class Tuner.Application : Gtk.Application {

    public GLib.Settings settings { get; construct; }
    public PlayerController player { get; construct; }
    public string? cache_dir { get; construct; }
    public string? data_dir { get; construct; }

    public Window window;

    public const string APP_VERSION = "1.3.1";
    public const string APP_ID = "com.github.louis77.tuner";
    public const string STAR_CHAR = "★ ";
    public const string UNSTAR_CHAR = "☆ ";

    public Application () {
        Object (
            application_id: APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        settings = new GLib.Settings (this.application_id);
        player = new PlayerController ();

        cache_dir = Path.build_filename (Environment.get_user_cache_dir (), application_id);
        ensure_dir (cache_dir);

        data_dir = Path.build_filename (Environment.get_user_data_dir (), application_id);
        ensure_dir (data_dir);
    }

    public static Application _instance = null;

    public static Application instance {
        get {
            if (_instance == null) {
                _instance = new Application ();
            }
            return _instance;
        }
    }

    protected override void activate() {
        if (window == null) {
            window = new Window (this, player);
            add_window (window);
            DBus.initialize ();
        } else {
            window.present ();
        }

    }

    private void ensure_dir (string path) {
        var dir = File.new_for_path (path);
        
        try {
            debug (@"Ensuring dir exists: $path");
            dir.make_directory ();

        } catch (Error e) {
            // TODO not enough error handling
            // What should happen when there is another IOERROR?
            if (!(e is IOError.EXISTS)) {
                warning (@"dir couldn't be created: %s", e.message);
            }
        }
    }

}

