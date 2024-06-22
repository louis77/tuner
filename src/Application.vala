/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

public class Tuner.Application : Gtk.Application {

    public GLib.Settings settings { get; construct; }
    public PlayerController player { get; construct; }
    public string? cache_dir { get; construct; }
    public string? data_dir { get; construct; }

    public Window window;

    public const string APP_VERSION = "1.5.2";
    public const string APP_ID = "com.github.louis77.tuner";
    public const string STAR_CHAR = "★ ";
    public const string UNSTAR_CHAR = "☆ ";

    private const ActionEntry[] ACTION_ENTRIES = {
        { "resume-window", on_resume_window }
    };

    public Application () {
        Object (
            application_id: APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        GLib.Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (GETTEXT_PACKAGE);

        settings = new GLib.Settings (this.application_id);
        player = new PlayerController ();

        cache_dir = Path.build_filename (Environment.get_user_cache_dir (), application_id);
        ensure_dir (cache_dir);

        data_dir = Path.build_filename (Environment.get_user_data_dir (), application_id);
        ensure_dir (data_dir);

        add_action_entries(ACTION_ENTRIES, this);
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

    private void on_resume_window() {
        window.present();
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

