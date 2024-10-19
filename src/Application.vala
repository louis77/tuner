/**
 * @file Application.vala
 * @brief Contains the main Application class for the Tuner application
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class Tuner.Application
 * @brief Main application class for Tuner
 * @extends Gtk.Application
 *
 * This class serves as the entry point for the Tuner application.
 * It handles application initialization, window management, and theme settings.
 */
public class Tuner.Application : Gtk.Application {

    /** @brief Application version */
    public const string APP_VERSION = VERSION;
    
    /** @brief Application ID */
    public const string APP_ID = "com.github.louis77.tuner";
    
    /** @brief Unicode character for starred items */
    public const string STAR_CHAR = "★ ";
    
    /** @brief Unicode character for unstarred items */
    public const string UNSTAR_CHAR = "☆ ";

    //  /**
    //   * @enum Theme
    //   * @brief Enumeration of available themes
    //   */
    //  public enum Theme {
    //      SYSTEM,
    //      LIGHT,
    //      DARK
    //  }

    /** @brief Application settings */
    public GLib.Settings settings { get; construct; }
    
    /** @brief Player controller */
    public PlayerController player { get; construct; }
    
    /** @brief Cache directory path */
    public string? cache_dir { get; construct; }
    
    /** @brief Data directory path */
    public string? data_dir { get; construct; }

    /** @brief Main application window */
    public Window window;

    /** @brief Action entries for the application */
    private const ActionEntry[] ACTION_ENTRIES = {
        { "resume-window", on_resume_window }
    };

    /**
     * @brief Constructor for the Application
     */
    public Application () {
        Object (
            application_id: APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    /**
     * @brief Construct block for initializing the application
     */
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

    /** @brief Singleton instance of the Application */
    public static Application _instance = null;

    /**
     * @brief Getter for the singleton instance
     * @return The Application instance
     */
    public static Application instance {
        get {
            if (_instance == null) {
                _instance = new Application ();
            }
            return _instance;
        }
    }

    //  /**
    //   * @brief Current theme of the application
    //   */
    //  public bool prefer_dark_theme { 
    //      get {
    //          return settings.get_boolean("prefer-dark-theme");
    //      }
    //      set {
    //          var gtk_settings = Gtk.Settings.get_default();
    //          if (gtk_settings == null) {
    //              warning("Failed to get GTK settings");
    //          }
    //          else {
    //              gtk_settings.gtk_application_prefer_dark_theme = value;
    //          }
    //          settings.set_boolean("prefer-dark-theme", value);
    //      }
    //  }



    /**
     * @brief Activates the application
     *
     * This method is called when the application is activated. It creates
     * or presents the main window and initializes the DBus connection.
     */
    protected override void activate() {
        if (window == null) {
            window = new Window (this, player);
            add_window (window);
            DBus.initialize ();
        } else {
            window.present ();
        }
    }

    /**
     * @brief Resumes the window
     *
     * This method is called to bring the main window to the foreground.
     */
    private void on_resume_window() {
        window.present();
    }

    /**
     * @brief Ensures a directory exists
     * @param path The directory path to ensure
     *
     * This method creates the specified directory if it doesn't exist.
     */
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

    //  /**
    //   * @brief Converts a string to a Theme enum value
    //   * @param theme The theme string to convert
    //   * @return The corresponding Theme enum value
    //   */
    //  public static Theme theme_from_string(string theme_string) {

    //      warning(@"Theme requested: $(theme_string)");
    //      switch (theme_string) {
    //          case "TUNER_APPLICATION_THEME_LIGHT": return Theme.LIGHT;
    //          case "TUNER_APPLICATION_THEME_DARK": return Theme.DARK;
    //          default: return Theme.SYSTEM;
    //      }
    //  }

}
