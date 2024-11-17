/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

/**
 * @class Station
 * @brief Represents a radio station with various properties.
 */
public class Tuner.Model.Station : Object {

    //  public class Double
    //  {
    //      double _
    //  }

    // ----------------------------------------------------------
    // Properties
    // ----------------------------------------------------------

    //v2 
    public string	changeuuid	{ get; private set; }
    public string	stationuuid	{ get; private set; }
    public string	name	{ get; private set; }
    public string	url	{ get; private set; }
    public string	url_resolved	{ get; private set; }
    public string	homepage	{ get; private set; }
    public string	favicon	{ get; private set ; }
    public string	tags	{ get; private set ; }
    public string	country	{ get; private set ; }
    public string	countrycode	{ get; private set ; }
    public string	iso_3166_2  { get; private set ; }
    public string	state	{ get; private set ; }
    public string	language	{ get; private set ; }
    public string	languagecodes	{ get; private set ; }
    public int	votes { get; private set; }
    public string	lastchangetime	{ get; private set ; }
    public string	lastchangetime_iso8601	{ get; private set ; }
    public string	codec	{ get; private set ; }
    public int	bitrate { get; private set ; }
    public int	hls { get; private set ; }
    public int    lastcheckok { get; private set ; }
    public string	lastchecktime	{ get; private set ; }
    public string	lastchecktime_iso8601	{ get; private set ; }
    public string	lastcheckoktime	{ get; private set ; }
    public string	lastcheckoktime_iso8601	{ get; private set ; }
    public string	lastlocalchecktime	{ get; private set ; }
    public string	lastlocalchecktime_iso8601	{ get; private set ; }
    public string	clicktimestamp	{ get; private set ; }
    public string	clicktimestamp_iso8601 { get; private set ; }
    public int	clickcount { get; private set ; }
    public int	clicktrend { get; private set ; }
    public int    ssl_error { get; private set ; }
    public string	geo_lat { get; private set ; }
    public string	geo_long { get; private set ; }
    public bool	    has_extended_info { get; private set ; }
    
    /** @property {bool} starred - Indicates if the station is starred. Only set by Favorites*/
    public bool starred { get; private set; }
    
    public Gdk.Pixbuf favicon_image;

    //  public uint clickcount = 0;


    // ----------------------------------------------------------
    // Privates
    // ----------------------------------------------------------
    
    // Stations with Favicons that failed to load
    private static HashSet<string> STATION_FAILING_FAVICON = new HashSet<string>();

    private Uri favicon_uri;


    // ----------------------------------------------------------
    // Functions
    // ----------------------------------------------------------


    /**
     * @brief Deserializes the station's properties from JSON.
     * @param {Json.Node} json - The JSON representation of the station.
     */
     public Station(Json.Node json_node) 
     {
        Object();         

        //if (json_node.get_node_type() == Json.NodeType.OBJECT) {
        Json.Object json_object = json_node.get_object();

        // Deserialize properties manually
        changeuuid = json_object.get_string_member("changeuuid");
        stationuuid = json_object.get_string_member("stationuuid");
        name = json_object.get_string_member("name");
        url = json_object.get_string_member("url");
        url_resolved = json_object.get_string_member("url_resolved");
        homepage = json_object.get_string_member("homepage");
        favicon = json_object.get_string_member("favicon");
        tags = json_object.get_string_member("tags");
        country = json_object.get_string_member("country");
        countrycode = json_object.get_string_member("countrycode");
        iso_3166_2 = json_object.get_string_member("iso_3166_2");
        state = json_object.get_string_member("state");
        language = json_object.get_string_member("language");
        languagecodes = json_object.get_string_member("languagecodes");
        votes = (int)json_object.get_int_member("votes");
        lastchangetime = json_object.get_string_member("lastchangetime");
        lastchangetime_iso8601 = json_object.get_string_member("lastchangetime_iso8601");
        codec = json_object.get_string_member("codec");
        bitrate = (int)json_object.get_int_member("bitrate");
        hls = (int)json_object.get_int_member("hls");
        lastcheckok = (int)json_object.get_int_member("lastcheckok");
        lastchecktime = json_object.get_string_member("lastchecktime");
        lastchecktime_iso8601 = json_object.get_string_member("lastchecktime_iso8601");
        lastcheckoktime = json_object.get_string_member("lastcheckoktime");
        lastcheckoktime_iso8601 = json_object.get_string_member("lastcheckoktime_iso8601");
        lastlocalchecktime = json_object.get_string_member("lastlocalchecktime");
        lastlocalchecktime_iso8601 = json_object.get_string_member("lastlocalchecktime_iso8601");
        lastlocalchecktime_iso8601 = json_object.get_string_member("has_extended_info");
        clicktimestamp = json_object.get_string_member("clicktimestamp");
        clicktimestamp_iso8601 = json_object.get_string_member("clicktimestamp_iso8601");
        clickcount = (int)json_object.get_int_member("clickcount");
        clicktrend = (int)json_object.get_int_member("clicktrend");
        ssl_error = (int)json_object.get_int_member("ssl_error");
        geo_lat = json_object.get_string_member("geo_lat");
        geo_long = json_object.get_string_member("geo_long");
        has_extended_info = json_object.get_boolean_member("has_extended_info");   
        
        // Process favorites
        if (json_object.has_member("starred") )
        {
            starred = json_object.get_boolean_member("starred");
        }             

        // Process v1 Attribute, if any, from Favorites
        if (json_object.has_member("id") )
        {
            stationuuid = json_object.get_string_member("id");
        }             

        if (json_object.has_member("favicon-url") )
        {                
            favicon = json_object.get_string_member("favicon-url");
        }       

        if (json_object.has_member("location") )
        {                
            country = json_object.get_string_member("location");
        }        

        if (json_object.has_member("title") )
        {                
            name = json_object.get_string_member("title");
        }         

        // Attempt to load parse and Favicon
        try {
            warning(@"Start parse favicon URL for Station: $(stationuuid) URL: $(favicon)");
            favicon_uri = Uri.parse(favicon, NONE);
            warning(@"End parse favicon URL for Station: $(stationuuid) URL: $(favicon_uri.to_string())");
            load_favicon_async.begin();
        } catch (GLib.UriError e) {
            warning(@"Failed to parse favicon URL for Station: $(stationuuid) URL: $(e.message)");
            STATION_FAILING_FAVICON.add(stationuuid);
        }
    } 

    /**
     * @brief Retrieves the favicon image.
     * @return {Gdk.Pixbuf} The favicon image.
     */
    public Gdk.Pixbuf get_favicon_image()
    {
        warning(@"get_favicon_image for Station: $(name)))");
        return favicon_image; 
    }

    /**
     * @brief Asynchronously retrieves the favicon URI.
     * @param {bool} reload - Whether to force reload the favicon.
     * @return {Uri?} The favicon URI, or null if unavailable.
     */
    public async Uri? get_favicon_uri( bool reload = false )
    {
        warning("Station get_favicon_uri 1");
        if (reload) { 
            yield load_favicon_async( true ); 
        }
        warning(@"Getting Fav Icon Uri $(favicon_uri.to_string())");
        return favicon_uri;
    }

    /**
     * @brief Sets the favicon URI to unavailable.
     */
    //  public void set_favicon_unavailable()
    //  {
    //      favicon_uri =  null;
    //  }

    /**
     * @brief Toggles the starred status of the station.
     */
    public void toggle_starred () {
        _starred = !_starred;
    }

    /**
     * @brief Returns a string representation of the station.
     * @return {string} A string in the format "[id] title".
     */
    //  public string to_string() {
    //      return @"[$(this.stationuuid)] $(this.name)";
    //  }

    /**
     * @brief Deserializes the station's UUID to JSON.
     * @return {Json.Node} A JSON representation of the station UUID.
     */
    public Json.Node? deserialize() {
        try {
            return Json.from_string(stationuuid); // Serializes all properties
        } catch (GLib.Error e) {
            warning(@"Serialization error: $(e.message)"); // Log the error message
            return null; // Return null or handle the error as needed
        }
    }



    /**
     * @brief Asynchronously loads the favicon for the station.
     * @param {bool} reload - Whether to force reload the favicon.
     */
    private async void load_favicon_async( bool reload = false )
    {

        warning(@"load_favicon_async for Station $(stationuuid) favicon: $(favicon)))");

        // Get favicon from cache file
        var favicon_cache_file = Path.build_filename(Application.instance.cache_dir, stationuuid);

        // Check if not forcing reload and then if favicon is cached
        if ( !reload && FileUtils.test(favicon_cache_file, FileTest.EXISTS)) 
            {
            try {
                favicon_image = new Gdk.Pixbuf.from_file(favicon_cache_file);
                //favicon_image = new Gdk.Pixbuf.from_file_at_scale(favicon_cache_file, 48, 48, true);
               
        warning(@"load_favicon_async from cache for Station: $(stationuuid)))");
                return;
            } catch (Error e) {
                warning(@"Failed to load cached favicon for Station $(stationuuid) : $(e.message)");
            }
        }

        if ( favicon_uri == null || (!reload && STATION_FAILING_FAVICON.contains(stationuuid)) ) return; // Favicon is erring out, so bypass loading it this session

        // If not in cache or force reload, fetch from internet
        uint status_code;

        InputStream? stream = yield HttpClient.GETasync(favicon_uri, out status_code);

        if ( stream != null && status_code == 200) {
            try {
                favicon_image = yield new Gdk.Pixbuf.from_stream_at_scale_async(stream, 48, 48, true,null);
                favicon_image.save(favicon_cache_file, "png");

        warning(@"load_favicon_async from internet for Station: $(stationuuid)))");
            } catch (Error e) {
                warning(@"Failed to process favicon for Station $(stationuuid) : $(favicon_uri) - $(e.message)");
                favicon_uri = null; // Flag to not try reloading the favicon
            }
        }
    }

    public string to_string() {
        StringBuilder builder = new StringBuilder();
        builder.append("{ ");

        // Use this.get_class() to retrieve the class of the instance
        unowned ObjectClass object_class = (ObjectClass) this.get_class();
        foreach (ParamSpec param in object_class.list_properties()) {
            string property_name = param.name;
           
                // Create a GLib.Value to hold the property value
                var value = Value(typeof(void));
                get_property(property_name, ref value);
                // Convert the value to a string representation

                // Append property name and value to the string
                builder.append_printf("%s: %s, ", property_name, value.strdup_contents());
            } 
        

        // Remove the trailing ", " if any properties were appended
        if (builder.len > 10) { // Length of "Example { "
            builder.truncate(builder.len - 2);
        }

        builder.append(" }");
        return builder.str;
    }
}
