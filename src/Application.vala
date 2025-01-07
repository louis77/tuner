/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file Application.vala
 *
 * @brief Main application class and namespace assets for the Tuner radio application
 */

 using GLib;

/**
 * @namespace Tuner
 * @brief Main namespace for the Tuner application
 */
namespace Tuner {


    /*
        Namespace Assets and Methods
    */
    private static Application _instance;


    /**
    * @brief Available themes
    *
    */
    public enum THEME
    {
        SYSTEM,
        LIGHT,
        DARK;

        public unowned string get_name ()
        {
            switch (this) {
                case SYSTEM:
                    return "system";

                case LIGHT:
                    return "light";

                case DARK:
                    return "dark";

                default:
                    assert_not_reached();
            }
        }
    } // THEME


    /**
    * @brief Applys the given theme to the app
    *
    * @return The Application instance
    */
    public static void apply_theme(THEME requested_theme)
    {
        apply_theme_name( requested_theme.get_name() );
    }


    public static void apply_theme_name(string requested_theme)
    {
        if ( requested_theme == THEME.LIGHT.get_name() )
        {
            debug(@"Applying theme: light");           
            Gtk.Settings.get_default().set_property("gtk-theme-name", "Adwaita");
            return;
        }

        if ( requested_theme == THEME.DARK.get_name() )
        {
            debug(@"Applying theme: dark");            
            Gtk.Settings.get_default().set_property("gtk-theme-name", "Adwaita-dark");
            return;
        }

        if ( requested_theme == THEME.SYSTEM.get_name() )
        {
            debug(@"System theme X: $(Application.SYSTEM_THEME())");       
            Gtk.Settings.get_default().set_property("gtk-theme-name", Application.SYSTEM_THEME());
            return;
        }
        assert_not_reached();
    } // apply_theme


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
        Timeout.add (interval, () => {
            nap.callback ();
            return Source.REMOVE;
        }, Priority.LOW);
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


    public static unowned string safestrip( string? text )
    {
        if ( text == null ) return "";
        if ( text.length == 0 ) return "";
        return text._strip();
    } // safestrip


    /*
    
        Application

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
    public class Application : Gtk.Application 
    {

        private static Gtk.Settings GTK_SETTINGS;
        private static string GTK_SYSTEM_THEME = "unset";

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

        /** @brief Connectivity monitoring*/
        private static NetworkMonitor NETMON = NetworkMonitor.get_default ();

        private static Gtk.CssProvider CSSPROVIDER = new Gtk.CssProvider();



        // -------------------------------------


        /** @brief Application settings */
        public Settings settings { get; construct; }  
        
        /** @brief Player controller */
        public PlayerController player { get; construct; }  

        /** @brief Player controller */
        public DirectoryController directory { get; construct; }

        /** @brief Player controller */
        public StarStore stars { get; construct; }
        
        /** @brief API DataProvider */
        public DataProvider.API provider { get; construct; }
        
        /** @brief Cache directory path */
        public string? cache_dir { get; construct; }
        
        /** @brief Data directory path */
        public string? data_dir { get; construct; }

        public Cancellable offline_cancel { get; construct; }

        public static string SYSTEM_THEME() { return GTK_SYSTEM_THEME; }


        /** @brief Are we online */
        public bool is_offline { get; private set; }   
        private bool _is_online = false;
        public bool is_online { 
            get { return _is_online; } 
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
        public Window window { get; private set; }


        /** @brief Action entries for the application */
        private const ActionEntry[] ACTION_ENTRIES = {
            { "resume-window", on_resume_window }
        };

        private uint _monitor_changed_id = 0;
        private bool _has_started = false;


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
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
            Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (GETTEXT_PACKAGE);
            
            // Create required directories and files

            cache_dir = stat_dir(Environment.get_user_cache_dir ());
            data_dir = stat_dir(Environment.get_user_data_dir ());


            /* 
                Starred file and migration of favorites
            */
            var _favorites_file =  File.new_build_filename (data_dir, "favorites.json"); // v1 file
            var _starred_file =  File.new_build_filename (data_dir, Application.STARRED);   // v2 file

            /* Migration not possible with renamed app */
            //  try {
            //      _favorites_file.open_readwrite().close ();   // Try to open, if succeeds it exists, if not err - no migration
            //      _starred_file.create(NONE); // Try to create, if fails starred already exists, if not ok to migrate
            //      _favorites_file.copy (_starred_file, FileCopyFlags.NONE);  // Copy
            //      warning(@"Migrated v1 Favorites to v2 Starred");
            //  }     
            //  catch (Error e) {
            //      // Peconditions not met
            //  }

            /* 
                Create the cancellable.
                Wrap network monitoring into a bool property 
            */
            offline_cancel = new Cancellable();
            NETMON.network_changed.connect((monitor) => {      
                check_online_status();
            });
            is_online = NETMON.get_network_available ();           
            is_offline = !is_online;


            /* 
                Init Tuner assets 
            */
            settings = new Settings ();
            provider = new DataProvider.RadioBrowser(null);
            player = new PlayerController ();
            stars = new StarStore(_starred_file);
            directory = new DirectoryController(provider, stars);

            add_action_entries(ACTION_ENTRIES, this);

            /*
                Hook up voting and counting
            */
            player.state_changed_sig.connect ((station, state) => 
            // Do a provider click when starting to play a sation
            {
                if ( !settings.do_not_vote  && state == PlayerController.Is.PLAYING )
                {
                    provider.click(station.stationuuid);                
                    station.clickcount++;
                    station.clicktrend++;
                }
            });

            player.tape_counter_sig.connect((station) =>
            // Every ten minutes of continuous playing tape counter sigs are emitted
            // Vote and click the station each time as appropriate
            {     
                if ( settings.do_not_vote ) return;
                if ( station.starred ) 
                { 
                    provider.vote(station.stationuuid); 
                    station.votes++;
                }
                provider.click(station.stationuuid);
                station.clickcount++;
                station.clicktrend++;
            });

        } // construct


        /**
        * @brief Getter for the singleton instance
        *
        * @return The Application instance
        */
        public static Application instance {
            get {
                    if (Tuner._instance == null) {  
                    Tuner._instance = new Application ();  
                }
                return Tuner._instance;
            }
        } // instance


        /**
        * @brief Activates the application
        *
        * This method is called when the application is activated. It creates
        * or presents the main window and initializes the DBus connection.
        */
        protected override void activate() 
        {
            if (window == null) { 
                window = new Window (this, player, settings, directory); 
                DBus.initialize (); 
                settings.configure();  

                GTK_SETTINGS = Gtk.Settings.get_default();
                GTK_SYSTEM_THEME = GTK_SETTINGS.gtk_theme_name;
                apply_theme_name( settings.theme_mode);                

                CSSPROVIDER.load_from_resource ("io/github/louis77/tuner/css/Tuner-system.css");
                Gtk.StyleContext.add_provider_for_screen(
                    Gdk.Screen.get_default(),
                    CSSPROVIDER,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );

                add_window (window);
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
            if(_monitor_changed_id > 0) 
            {
                Source.remove(_monitor_changed_id);
                _monitor_changed_id = 0;
            }

            /*
                If change to online from offline state
                wait 1 seconds before setting to online status
                to whatever the state is at that time
            */
            if ( is_offline && NETMON.get_network_available ()  )
            {
                _monitor_changed_id = Timeout.add_seconds( (uint)_has_started, () => 
                {           
                    _monitor_changed_id = 0; // Reset timeout ID after scheduling  
                    is_online = NETMON.get_network_available ();
                    _has_started = true;
                    return Source.REMOVE;
                });

                return;
            }
            // network is unavailable 
            is_online = false;
        } // check_online_status
    } // Application
} // namespace Tuner