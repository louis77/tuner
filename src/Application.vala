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

namespace Tuner {


    /*
        Namespace Assets and Methods
    */
    private static Application _instance;

    /**
    * @brief Getter for the singleton instance
    *
    * @return The Application instance
    */
    public static Application app() {
            return _instance;
    } // app

    /**
    * @brief Send the calling method for a nap
    *
    * @param interval the time to nap
    * @param priority priority of chacking nap is over
    */
    public static async void nap (uint interval) {
        GLib.Timeout.add (interval, () => {
            nap.callback ();
            return GLib.Source.REMOVE;
        }, GLib.Priority.LOW);
        yield;
    } // nap


    /**
    * @brief Asynchronously transitions the image with a fade effect.
    * 
    * @param {Gtk.Image} image - The image to transition.
    * @param {uint} duration_ms - Duration of the fade effect in milliseconds.
    * @param {Closure} callback - Optional callback function to execute after fading.
    */
    public static async void fade(Gtk.Image image, uint duration_ms, bool fading_in) 
    {
        double step = 0.05; // Adjust opacity in 5% increments
        uint interval = (uint) (duration_ms / (1.0 / step)); // Interval based on duration

        while ( ( !fading_in && image.opacity != 0 ) || (fading_in && image.opacity != 1) ) 
        {      
            double op = image.opacity + (fading_in ? step : -step); 
            image.opacity = op.clamp(0, 1); 
            yield nap (interval);
        }
    } // fade


    /*
        Application
    */

    public class Application : Gtk.Application {


        /** @brief Application version */
        public const string APP_VERSION = VERSION;
        
        /** @brief Application ID */
        public const string APP_ID = "com.github.louis77.tuner";
        
        /** @brief Unicode character for starred items */
        public const string STAR_CHAR = "★ ";
        
        /** @brief Unicode character for unstarred items */
        public const string UNSTAR_CHAR = "☆ ";

        /** @brief Unicode character for out-of-date items */
        public const string EXCLAIM_CHAR = "⚠ ";

        /** @brief File name for starred station sore */
        public const string STARRED = "starred.json";


        /** @brief Singleton instance of the Application */
        //private static Application _instance = null;

        /** @brief Connectivity monitoring*/
        private static NetworkMonitor monitor = NetworkMonitor.get_default ();
        private uint _monitor_changed_id = 0;


        // -------------------------------------


        /** @brief Application settings */
        public Settings settings { get; construct; }  
        
        /** @brief Player controller */
        public PlayerController player { get; construct; }  

        /** @brief Player controller */
        public DirectoryController directory { get; construct; }
        
        /** @brief API DataProvider */
        public DataProvider.API provider { get; construct; }
        
        /** @brief Cache directory path */
        public string? cache_dir { get; construct; }
        
        /** @brief Data directory path */
        public string? data_dir { get; construct; }

        public GLib.Cancellable offline_cancel { get; construct; }

        /** @brief Are we online */
        public bool is_offline { get; private set; }   
        private bool _is_online = false;
        public bool is_online { get { return _is_online; } 
                                private set {
                                        if ( value ) 
                                        { 
                                            _offline_cancel.reset (); 
                                        }
                                        else 
                                        { 
                                            _offline_cancel.cancel (); 
                                        }
                                        _is_online = value;
                                        is_offline = !value;
                                    }
                                }   


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

        //  static construct {

        //      Tuner._instance = new Application ();
        //  }

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


            warning(@"Directories $(cache_dir) to $(data_dir) - online: $(monitor.get_network_available ())");

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

            /* 
                Create the cancellable.
                Wrap network monitoring into a bool property 
            */
            offline_cancel = new GLib.Cancellable();
            monitor.network_changed.connect((monitor) => {
                check_online_status();
            });
            is_online = monitor.get_network_available ();


            /* 
                Init Tuner assets 
            */
            provider = new DataProvider.RadioBrowser(null);
            settings = new Settings ();
            player = new PlayerController ();
            var stars = new StarStore(_starred_file);
            directory = new DirectoryController(provider, stars);

            add_action_entries(ACTION_ENTRIES, this);
        } // construct


        /**
        * @brief Getter for the singleton instance
        *
        * @return The Application instance
        */
        public static Application instance {
            get {
                //Tuner._instance = new Application ();
                //if (_instance == null) {
                    if (Tuner._instance == null) {
                    //  _instance = new Application ();
                    //_instance = new Application ();
                    Tuner._instance = new Application ();
                   // return Tuner._instance;
                }
                //return _instance;
                return Tuner._instance;
            }
        } // instance


        /**
        * @brief Activates the application
        *
        * This method is called when the application is activated. It creates
        * or presents the main window and initializes the DBus connection.
        */
        protected override void activate() {
            if (window == null) {
                window = new Window (this, player, settings, directory);
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

        /**
        * @brief Set the network availability
        *
        * If going offline, set immediately.
        * Going online - wait a second to allow network to stabilize
        * This method removes any existing timeout and sets a new one 
        * reduces network state bouncyness
        */
        private void check_online_status()
        {
            if(_monitor_changed_id > 0) Source.remove(_monitor_changed_id);

            /*
                If change to online from offline state
                wait 2 seconds before setting to online status
                to whatever the state is at that time
            */
            if ( is_offline && monitor.get_network_available ()  )
            {
                _monitor_changed_id = Timeout.add( 2000, () => 
                {           
                    _monitor_changed_id = 0; // Reset timeout ID after scheduling  
                    is_online = monitor.get_network_available ();
                    return Source.REMOVE;
                });

                return;
            }
            // network is unavailable 
            is_online = false;
        } // check_online_status
    }
}