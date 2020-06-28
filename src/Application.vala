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

public class Tuner.Application : Gtk.Application {
    public GLib.Settings settings;
    public PlayerController player;
    public Window window;
    public string? cache_dir;

    public Application () {
        Object (
            application_id: "com.github.louis77.tuner",
            flags: ApplicationFlags.FLAGS_NONE
        );

        settings = new GLib.Settings (this.application_id);
        player = new PlayerController ();
        ensure_cache_dir ();
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

    private void ensure_cache_dir () {
        var user_cache_dir = Environment.get_user_cache_dir ();
        cache_dir = Path.build_filename (user_cache_dir, application_id);

        debug (@"App Cache Dir: $cache_dir");
        var f_cache_dir = File.new_for_path (cache_dir);
        
        try {
            debug (@"Ensuring cache_dir exists...");
            f_cache_dir.make_directory ();

        } catch (Error e) {
            if (!(e is IOError.EXISTS)) {
                warning (@"cache_dir couldn't be created: %s", e.message);
                cache_dir = null;
            }
        }
    }

}

