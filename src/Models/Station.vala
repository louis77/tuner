/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file Station.vala
 *
 * @brief Station metadata and related cachable objects
 * 
 */

using Gee;

/**
 * @class Station
 * @brief Represents a radio station with various properties.
 */
public class Tuner.Model.Station : Object {

    // ----------------------------------------------------------
    // statics
    // ----------------------------------------------------------

    // Stations with Favicons that failed to load
    private static Set<string> STATION_FAILING_FAVICON = new HashSet<string>();

    // Core set of all station so far retrieved
    private static Map<string,Station> STATIONS = new HashMap<string,Station>();

    private const int FADE_MS = 400;

    // Signals
    public signal void station_star_sig(bool starred);  // Station starred state has changed

    // ----------------------------------------------------------
    // Properties
    // ----------------------------------------------------------

    /** @property {string} changeuuid - Unique identifier for the change. */
    public string 	changeuuid	{ get; private set; }
    /** @property {string} stationuuid - Unique identifier for the station. */
    public string   stationuuid	{ get; private set; }
    /** @property {string} name - Name of the station. */
    public string	name	{ get; private set; }
    /** @property {string} url - URL of the station stream. */
    public string	url	{ get; private set; }
    /** @property {string} url_resolved - Resolved URL of the station stream. Camel case so goobject serialize is OK*/
    public string	urlResolved	{ get; private set; }
    /** @property {string} homepage - Homepage of the station. */
    public string	homepage	{ get; private set; }
    /** @property {string} favicon - Favicon URL of the station. */
    public string	favicon	{ get; private set ; }
    /** @property {string} tags - Tags associated with the station. */
    public string	tags	{ get; private set ; }
    /** @property {string} country - Country where the station is located. */
    public string	country	{ get; private set ; }
    /** @property {string} countrycode - Country code of the station. */
    public  string	countrycode	{ get; private set ; }
    /** @property {string} iso_3166_2 - ISO 3166-2 code for the station's location. */
    public string	iso_3166_2  { get; private set ; }
    /** @property {string} state - State where the station is located. */
    public string	state	{ get; private set ; }
    /** @property {string} language - Language of the station. */
    public string	language	{ get; private set ; }
    /** @property {string} languagecodes - Language codes associated with the station. */
    public string	languagecodes	{ get; private set ; }
    /** @property {string} codec - Audio codec used by the station. */
    public string	codec	{ get; private set ; }
    /** @property {int} bitrate - Bitrate of the station stream. */
    public int	bitrate { get; private set ; }
    /** @property {int} hls - HLS status of the station. */
    public int	hls { get; private set ; }


    // ----------------------------------------------------------
    // Non-Properties
    // ----------------------------------------------------------

    /** @property {int} votes - Number of votes for the station. */
    public int	votes;
    /** @property {string} lastchangetime - Last change time of the station. */
    public string	lastchangetime;
    /** @property {string} lastchangetime_iso8601 - Last change time in ISO 8601 format. */
    public string	lastchangetime_iso8601;
    /** @property {int} lastcheckok - Status of the last check (0 or 1). */
    public int    lastcheckok;
    /** @property {string} lastchecktime - Last check time of the station. */
    public string	lastchecktime;
    /** @property {string} lastchecktime_iso8601 - Last check time in ISO 8601 format. */
    public string	lastchecktime_iso8601;
    /** @property {string} lastcheckoktime - Last successful check time. */
    public string	lastcheckoktime	;
    /** @property {string} lastcheckoktime_iso8601 - Last successful check time in ISO 8601 format. */
    public string	lastcheckoktime_iso8601;
    /** @property {string} lastlocalchecktime - Last local check time. */
    public string	lastlocalchecktime;
    /** @property {string} lastlocalchecktime_iso8601 - Last local check time in ISO 8601 format. */
    public string	lastlocalchecktime_iso8601;
    /** @property {string} clicktimestamp - Timestamp of the last click. */
    public string	clicktimestamp;
    /** @property {string} clicktimestamp_iso8601 - Last click timestamp in ISO 8601 format. */
    public string	clicktimestamp_iso8601;
    /** @property {int} clickcount - Number of clicks on the station. */
    public int	clickcount;
    /** @property {int} clicktrend - Trend of clicks on the station. */
    public int	clicktrend;
    /** @property {int} ssl_error - SSL error status. */
    public int    ssl_error;
    /** @property {string} geo_lat - Latitude of the station's location. */
    public string	geo_lat;
    /** @property {string} geo_long - Longitude of the station's location. */
    public string	geo_long;
    /** @property {bool} has_extended_info - Indicates if extended info is available. */
    public bool	    has_extended_info;
    
    private bool _starred;
    /** @property {bool} starred - Indicates if the station is starred. Only set by Favorites*/
    public bool starred { 
        get { return _starred; }
        set { 
            if ( _starred == value ) return;
            _starred = value; 
            station_star_sig(value);
        }
    }
    
    /** @property {int} favicon_loaded - Indicates the number of times the favicon has been loaded from cache or internet.*/
    public int favicon_loaded; // { get; private set; }

    public bool is_in_index;
    public bool is_up_to_date;
   public string up_to_date_difference = _("Station no longer in the index");


    //  public uint clickcount = 0;


    // ----------------------------------------------------------
    // Privates
    // ----------------------------------------------------------
    
    private Uri _favicon_uri;
    private Gdk.Pixbuf _favicon_pixbuf; // Favicon for this station
    private string _favicon_cache_file;


    // ----------------------------------------------------------
    // Functions
    // ----------------------------------------------------------

    /**
     * @brief Returns a unique, initiated Station instance for a given JSON node.
     * 
     * If station has already been initiated based on stationuuid, returns the existing Station
     *
     * @param {Json.Node} json_node - The JSON node containing station data.
     * @return {Station} The created Station instance.
     */
    public static Station make(Json.Node json_node)
    {
        Station station = new Station.basic(json_node);
        station.is_in_index = true;
        station.is_up_to_date = true; // Assume loaded from the provider as we're adding this to the list
        station.up_to_date_difference = "";

        if ( !STATIONS.has_key(station.stationuuid)) 
        /*
            Add station to the index and kickoff async load of the favicon
        */
        {
            STATIONS.set(station.stationuuid,station);
           // station.load_favicon_async.begin();
        }

        return STATIONS.get(station.stationuuid);
    } // make

    
     /**
     * @brief Constructor a basic Station instance from a JSON node.
     *
     * @param {Json.Node} json_node - The JSON node containing station data.
     */
     public Station.basic(Json.Node json_node) 
     {
        Object();   

        if ( json_node == null )
        {
            warning(@"Station - no JSON");
            return;
        }

        Json.Object json_object = json_node.get_object();

        //
        // Json is noisy as fields may/may not be returned. Turn off the logging while parsing.
        //
        var log_handler_1 = GLib.Log.set_handler(
                 "Json",
                 GLib.LogLevelFlags.LEVEL_CRITICAL,
                 (log_domain, log_level, message) => {
                     // Ignore the warnings
                 }
             );

        var log_handler_2 = GLib.Log.set_handler(
            null,
                GLib.LogLevelFlags.LEVEL_CRITICAL,
                (log_domain, log_level, message) => {
                    // Ignore the warnings
                }
            );

         try {     
            // Deserialize properties manually
            // Put in a try/finally as much for visuals as anything
            changeuuid = json_object.get_string_member("changeuuid").strip();
            stationuuid = json_object.get_string_member("stationuuid").strip();
            name = json_object.get_string_member("name").strip();
            url = json_object.get_string_member("url").strip();
            urlResolved = json_object.get_string_member("url_resolved").strip();
            homepage = json_object.get_string_member("homepage").strip();
            favicon = json_object.get_string_member("favicon").strip();
            tags = json_object.get_string_member("tags").strip();
            country = json_object.get_string_member("country").strip();
            countrycode = json_object.get_string_member("countrycode").strip();
            iso_3166_2 = json_object.get_string_member("iso_3166_2").strip();
            state = json_object.get_string_member("state").strip();
            language = json_object.get_string_member("language").strip();
            languagecodes = json_object.get_string_member("languagecodes").strip();
            votes = (int)json_object.get_int_member("votes");
            lastchangetime = json_object.get_string_member("lastchangetime").strip();
            lastchangetime_iso8601 = json_object.get_string_member("lastchangetime_iso8601").strip();
            codec = json_object.get_string_member("codec").strip();
            bitrate = (int)json_object.get_int_member("bitrate");
            hls = (int)json_object.get_int_member("hls");
            lastcheckok = (int)json_object.get_int_member("lastcheckok");
            lastchecktime = json_object.get_string_member("lastchecktime").strip();
            lastchecktime_iso8601 = json_object.get_string_member("lastchecktime_iso8601").strip();
            lastcheckoktime = json_object.get_string_member("lastcheckoktime").strip();
            lastcheckoktime_iso8601 = json_object.get_string_member("lastcheckoktime_iso8601").strip();
            lastlocalchecktime = json_object.get_string_member("lastlocalchecktime").strip();
            lastlocalchecktime_iso8601 = json_object.get_string_member("lastlocalchecktime_iso8601").strip();
            lastlocalchecktime_iso8601 = json_object.get_string_member("has_extended_info").strip();
            clicktimestamp = json_object.get_string_member("clicktimestamp").strip();
            clicktimestamp_iso8601 = json_object.get_string_member("clicktimestamp_iso8601").strip();
            clickcount = (int)json_object.get_int_member("clickcount");
            clicktrend = (int)json_object.get_int_member("clicktrend");
            ssl_error = (int)json_object.get_int_member("ssl_error");
            geo_lat = json_object.get_string_member("geo_lat").strip();
            geo_long = json_object.get_string_member("geo_long").strip();
            has_extended_info = json_object.get_boolean_member("has_extended_info");   
            
            var go_serial_fudge = json_object.get_string_member("urlResolved").strip();  // Serialization camelcase fudge
            if ( go_serial_fudge != null && go_serial_fudge != "" ) 
            {
                urlResolved = go_serial_fudge;
            }
         
            // Process favorites
            if (json_object.has_member("starred") )
            {
                _starred = json_object.get_boolean_member("starred");
            }             

            /* -----------------------------------------------------------------------
                Process v1 Attribute, if any, from old Favorites format
            ----------------------------------------------------------------------- */

            if (json_object.has_member("id") )
            {
                stationuuid = json_object.get_string_member("id").strip();
            }             

            if (json_object.has_member("favicon-url") )
            {                
                favicon = json_object.get_string_member("favicon-url").strip();
            }       

            if (json_object.has_member("location") )
            {                
                country = json_object.get_string_member("location").strip();
            }        

            if (json_object.has_member("title") )
            {                
                name = json_object.get_string_member("title").strip();
            }        
        } finally {
            GLib.Log.remove_handler(null, log_handler_2);
            GLib.Log.remove_handler("Json", log_handler_1);
        }

        is_in_index = false; // Basic station creation - assume not in provider index
        is_up_to_date = false; // Basic station creation - assume not up-to-date with provider

        /*
            Favicon setup
        */
        favicon_loaded =  0;    // Used to notify that favicon loaded
        _favicon_cache_file = Path.build_filename(Application.instance.cache_dir, stationuuid);

        if ( favicon == null || favicon.length == 0 )
        {
            STATION_FAILING_FAVICON.add(stationuuid);
            debug(@"$(stationuuid) - Favicon missing");
            return;
        }
                    
        try {
            debug(@"$(stationuuid) - constructed - Start parse favicon URL: $(favicon)");
            _favicon_uri = Uri.parse(favicon, NONE);
         } catch (GLib.UriError e) {
            warning(@"$(stationuuid) - Failed to parse favicon URL: $(e.message)");
            STATION_FAILING_FAVICON.add(stationuuid);
        }  

        load_favicon_async.begin();
    } // Station.basic


    /**
     * @brief Toggles the Starred status of the station
     * @return {bool} True if Station is Starred.
     */
    public bool toggle_starred()
    {
        starred = !starred;
        return _starred;
    } // toggle_starred


    /**
     * @brief Returns a string representation of the station.
     * @return {string} A string in the format "[id] title".
     */
    public string to_string() {
        return @"[$(stationuuid)] $(name)";
    } // to_string


    /**
     * @brief Asynchronously loads the favicon for the station.
     *
     * Loads from cache is not requesting reload and cache exists
     * Otherwise async calls to the website to download the favicon,
     * then stores it in the cache and replaces the Station favicon
     *
     * @param {bool} reload - Whether to force reload the favicon.
     */
    private async void load_favicon_async( bool reload = false )
    {
        debug(@"$(stationuuid) - Start - load_favicon_async for favicon: $(favicon)");

        /*  
            Get favicon from cache file if file is in cache AND
            Not requesting reload Or favicon is currently failing
        */
        if (    ( !reload || STATION_FAILING_FAVICON.contains(stationuuid) )
            &&  FileUtils.test(_favicon_cache_file, FileTest.EXISTS)) 
            {
            try {
                var pixbuf = new Gdk.Pixbuf.from_file_at_scale(_favicon_cache_file, 48, 48, true);
                _favicon_pixbuf = pixbuf;              
                debug(@"$(stationuuid) - Complete - load_favicon_async from cache stored in file://$(_favicon_cache_file)");
                favicon_loaded++;
                return;
            } catch (Error e) {
                warning(@"$(stationuuid) - Failed to load cached favicon: $(e.message)");
            }
        }

        if ( _favicon_uri == null ) return; // First load or reload requested and favicon is not failing

        uint status_code;

        InputStream? stream = yield HttpClient.GETasync(_favicon_uri, Priority.LOW, out status_code); // Will automatically try several times

        if ( stream != null && status_code == 200 ) 
        /*
            Input stream OK
        */
        {
            try {
                var pixbuf = yield new Gdk.Pixbuf.from_stream_at_scale_async(stream, 48, 48, true,null);
                pixbuf.save(_favicon_cache_file, "png");
                _favicon_pixbuf = pixbuf;
                debug(@"$(stationuuid) - Complete - load_favicon_async from internet for $(_favicon_uri.to_string())\nStored in file://$(_favicon_cache_file)");
                favicon_loaded++;
                return;

            } catch (Error e) {
                debug(@"$(stationuuid) - Failed to process favicon $(_favicon_uri.to_string()) - $(e.message)");
            }
        }
        warning(@"$(stationuuid) - Failed to load favicon $(_favicon_uri.to_string()) - Status code: $(status_code)");
        STATION_FAILING_FAVICON.add(stationuuid);
    } // load_favicon_async


    /**
     * @brief Asynchronously sets the given image to the station favicon, if available.
     *
     * Load the known icons first, and if reload, go around after trying the favicon url
     *
     * @param {Image} favicon_image - The favicon image to be updated.
     * @param {bool} reload - Whether to force reload the favicon from source.
     * @return {bool} True if the favicon was available and the image updated.
     */
    public async bool update_favicon_image( Gtk.Image favicon_image, bool reload = false, string defaulticon = "")
    {
        bool reloading = false;

        do {           
            try{
                if ( _favicon_pixbuf == null || STATION_FAILING_FAVICON.contains(stationuuid)) 
                {
                    yield fade(favicon_image, FADE_MS, false);
                    favicon_image.set_from_icon_name(defaulticon,Gtk.IconSize.DIALOG);
                    yield fade(favicon_image, FADE_MS, true);
                }
                else{

                    yield fade(favicon_image, FADE_MS, false);
                    favicon_image.set_from_pixbuf(_favicon_pixbuf);
                    yield fade(favicon_image, FADE_MS, true);
                }
            } finally {
                favicon_image.opacity = 1;
                reloading = false;
            }
            
            if ( reload && favicon_loaded < 2 ) 
            /*
                Reload requested, and favicon has not had reload requested before
            */
            { 
                STATION_FAILING_FAVICON.remove(stationuuid);    // Give possible 2nd chance
                yield load_favicon_async(true); // Wait for load_favicon_async to complete
                reloading = true;
                reload = false;
            }
        } while ( reloading );
        return true;
    } // update_favicon_image


    /**
     */
    public bool set_up_to_date_with(Station? p) 
    { 
        if ( p == null || this.stationuuid != p.stationuuid) return false;
        if ( (this.changeuuid == p.changeuuid) 
            && ( this.url == p.url) 
            && (this.bitrate == p.bitrate) 
            && ( this.codec == p.codec)) 
        { 
            is_up_to_date = true; 
            up_to_date_difference = "";
        }
        else
        {   
            StringBuilder sb = new StringBuilder();
            if ( this.url != p.url) sb.append(@"Url: $(this.url) > $(p.url)\n");
            if ( this.bitrate != p.bitrate) sb.append(@"Bitrate: $(this.bitrate) > $(p.bitrate)\n");
            if ( this.codec != p.codec) sb.append(@"Codec: $(this.codec) > $(p.codec)\n");
            if (this.changeuuid != p.changeuuid) sb.append("Other minor items have changed");
            up_to_date_difference = sb.str;
            is_up_to_date = false;
        }
        return true;
    }

    /**
     */
    public Station updated()
    {
        return STATIONS.get(stationuuid);
    } 
}
