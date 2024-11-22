/**
 * @file Application.vala
 * @brief Main application class for the Tuner radio application
 * @copyright Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * @copyright Copyright © 2024 technosf <https://github.com/technosf>
 * @license GPL-3.0-or-later
 */

/**
 * @namespace Tuner
 * @brief Main namespace for the Tuner application
 */

/**
 * @class Application
 * @brief Main application class implementing core functionality
 * @ingroup Tuner
 * 
 * The Application class serves as the primary entry point and controller for the Tuner
 * application. It manages:
 * - Window creation and presentation
 * - Settings management
 * - Player control
 * - Directory structure
 * - DBus initialization
 * 
 * @note This class follows the singleton pattern, accessible via Application.instance
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

    /** @brief File name for starred station sore */
    public const string STARRED = "favorites-test2.json";


    /** @brief Singleton instance of the Application */
    private static Application _instance = null;


    // -------------------------------------


    /** @brief Application settings */
    public Settings settings { get; construct; }  
    
    /** @brief Player controller */
    public PlayerController player { get; construct; }  

    /** @brief Player controller */
    public StarredStationController starred { get; construct; }
    
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
    private Application () {
        Object (
            application_id: APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    /**
     * @brief Construct block for initializing the application
     */
    construct 
    {
        GLib.Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (GETTEXT_PACKAGE);
        
        // Create required directories and files

        cache_dir = stat_dir(Environment.get_user_cache_dir ());
        data_dir = stat_dir(Environment.get_user_data_dir ());


        warning(@"Directories $(cache_dir) to $(data_dir)");

        /* 
            Starred file and migration of favorites
        */
        var _favorites_file =  File.new_build_filename (data_dir, "favorites.json"); // v1 file
        var _starred_file =  File.new_build_filename (data_dir, Application.STARRED);   // v2 file

        warning(@"Migrate $(_favorites_file.get_path ()) to $(_starred_file.get_path ())");

        try {
            _favorites_file.open_readwrite().close ();   // Try to open, if succeeds it exists, if not err - no migration
            _starred_file.create(NONE); // Try to create, if fails starred already exists, if not ok to migrate
            _favorites_file.copy (_starred_file, FileCopyFlags.NONE);  // Copy
            warning(@"Migrated v1 Favorites to v2 Starred");
        }     
        catch (Error e) {
            // Peconditions not met
        }


        starred = new StarredStationController(_starred_file);
        settings = new Settings (this);
        player = new PlayerController ();

        add_action_entries(ACTION_ENTRIES, this);
    } // construct


    /**
     * @brief Getter for the singleton instance
     *
     * @return The Application instance
     */
    public static Application instance {
        get {
            if (_instance == null) {
                _instance = new Application ();
            }
            return _instance;
        }
    } // instance


    /**
     * @brief Send the calling method for a nap
     *
     * @param interval the time to nap
     * @param priority priority of chacking nap is over
     */
    public static async void nap (uint interval, int priority = GLib.Priority.LOW) {
        GLib.Timeout.add (interval, () => {
            nap.callback ();
            return false;
          }, priority);
        yield;
    } // nap


    /**
     * @brief Activates the application
     *
     * This method is called when the application is activated. It creates
     * or presents the main window and initializes the DBus connection.
     */
    protected override void activate() {
        if (window == null) {
            window = new Window (this, player, settings, starred);
            add_window (window);
            DBus.initialize ();
        } else {
            window.present ();
        }
    } // activate


    /**
     * @brief Resumes the window
     *
     * This method is called to bring the main window to the foreground.
     */
    private void on_resume_window() {
        window.present();
    }

    /**
     * @brief Create directory structure quietly
     *
     */
    private string? stat_dir (string dir)
    {
        var _dir = File.new_build_filename (dir, application_id);
        try {
            _dir.make_directory_with_parents ();
        } catch (IOError.EXISTS e) {
        } catch (Error e) {
            warning(@"Stat Directory failed $(e.message)");
            return null;
        }
        return _dir.get_path ();

    } // stat_dir
}
