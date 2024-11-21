/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file StationStore.vala
 *
 * @brief Store and retrieve a collection of favorite stations.
 * 
 * Manages a collection of stations stored in a JSON file.
 * Provides methods to add, remove, and persist stations.
 * The JSON file store a subset of station data - the minimum
 * to be able to play a station without retrieving its information]
 * from radio-browser
 */

using Gee;
using Tuner.Model;


/**
 * @class StationStore
 *
 * @brief Manages a collection of favorite stations.
 * 
 * This class allows for storing, retrieving, and persisting a 
 * list of favorite stations in a JSON file. It uses libgee for data structures.
 *
 * DirectoryController uses StationStore to load the starred stations from RadioBrowser
 */

 // TODO Make a Singleton
public class Tuner.StarredStationController : Object {

    private const string FAVORITES_PROPERTY_APP = "app";
    private const string FAVORITES_PROPERTY_FILE = "file";
    private const string FAVORITES_PROPERTY_SCHEMA = "schema";
    private const string FAVORITES_PROPERTY_STATIONS = "stations";

    private const string FAVORITES_SCHEMA_VERSION = "2.0";

    private const string M3U8 = "#EXTM3U\n#EXTENC:UTF-8\n#PLAYLIST:Tuner\n";

   // public Set<Station> stations { get; construct; }

   // private ArrayList<Station> _store; ///< Collection of favorite stations.

    private File _starred_file; ///< File to persist favorite stations.
    private Map<string,Station> _starred; ///< Collection of favorite station UUIDs.


    // ----------------------------------------------------------
    // Under dev
    // ----------------------------------------------------------

    public string export_m3u8()
    {
        StringBuilder playlist = new StringBuilder(M3U8);
        foreach ( var station in _starred.values)
        {
            playlist.append (@"#EXTINF:-1,$(station.name) - logo=\"$(station.favicon)\"\n$(station.url)\n");
        }
        return playlist.str;
    }


    // ----------------------------------------------------------
    // Publics
    // ----------------------------------------------------------

    /**
     * @brief Constructor for StationStore.
     * @param favorites_path The path to the JSON file where favorites are stored.
     */
    public StarredStationController () {
        Object ();

        _starred = new HashMap<string, Station> ();

        var starred_file = Path.build_filename (Application.instance.data_dir, Application.STARRED);
        _starred_file = File.new_for_path (starred_file);

        load ();

        debug (@"store initialized in path $(starred_file)");
    }

    /**
     * @brief Adds a station to the favorites and persists the change.
     * @param station The station to be added.
     */
    public void add (Station station) {
        if (_starred.has_key (station.stationuuid)) return;
        _starred.set (station.stationuuid, station);
        persist ();
    }


    /**
     * @brief Removes a station from the favorites and persists the change.
     *
     * @param station The station to be removed.
     */
    public void remove (Station station) {
        _starred.unset (station.stationuuid);
        persist ();
    }

    /**
     * @brief Deserializes the starred station JSON into Station objects.
     * @return {Json.Node} A JSON representation of the starred station.
     */
    //  public static Gee.List<Station> deserialize(Json.Array array) {

    //      Gee.List<Station> ss = new Gee.ArrayList<Station>();
    //          // Define the function to process each element in the array
    //      array.foreach_element((a, i, elem) => {
    //                  ss.add(Json.gobject_deserialize(typeof(Station), elem) as Station);         
    //      });
    //      return ss;
    //  }

    /**
     * @brief Serializes the current favorites to a JSON string.
     *
     * @return A JSON string representation of the favorites.
     */
     public string serialize () 
     {
        Json.Builder builder = new Json.Builder ();
        builder.begin_object ();
	    builder.set_member_name (FAVORITES_PROPERTY_APP);
	    builder.add_string_value (Application.APP_ID);
	    builder.set_member_name (FAVORITES_PROPERTY_FILE);
	    builder.add_string_value (Application.STARRED);
	    builder.set_member_name (FAVORITES_PROPERTY_SCHEMA);
	    builder.add_string_value (FAVORITES_SCHEMA_VERSION);

	    builder.set_member_name (FAVORITES_PROPERTY_STATIONS);
        builder.begin_array ();
        foreach (var ss in _starred.values) {
            var node = Json.gobject_serialize (ss);
            builder.add_value (node);
            //builder.add_string_value (ss.serialize ().get_string () );
        }
        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        string data = generator.to_data (null);
        return data;
    }


    /**
     * @brief Retrieves all favorite stations.
     *
     * @return An ArrayList of favorite stations.
     */
    public Collection<Station> get_all () {
        return _starred.values;
    }

    /**
     * @brief Checks if a station is in the favorites.
     *
     * @param station The station to check.
     * @return True if the station is in favorites, false otherwise.
     */
    public bool contains (Station station) {
        return _starred.has_key (station.stationuuid);
    }


    // ----------------------------------------------------------
    // Privates
    // ----------------------------------------------------------


    /**
     * @brief Loads the favorites from the JSON file.
     * 
     * This method reads the JSON file and populates the _store with
     * the favorite stations.
     */
    private void load () {

        debug ("store file initial creation");
        try 
        // Create file if it does not already exist
        {
            _starred_file.create (FileCreateFlags.PRIVATE).close ();
            //df.close ();
            debug (@"store created");
        } catch (Error e) {
            // File already existes
        }

        debug ("loading store");
        Json.Parser parser = new Json.Parser.immutable_new ();
        
        try {
            var stream = _starred_file.read ();
            parser.load_from_stream (stream);
            stream.close ();
        } catch (Error e) {
            warning (@"Load failed with error: $(e.message)");
        }

        Json.Node? root = parser.get_root ();

        if ( root == null ) return; // No favorites stored  

        //Set<Station> starred_stations = new HashSet<Station>();
        Json.Array jarray;

        if ( get_member( root, FAVORITES_PROPERTY_SCHEMA) == null ) 
        /*
            v1 Schema
        */
        {
            jarray = root.get_array ();
        }
        else
        /*
            v2+ Schema
        */
        {
            var stations = get_member( root, FAVORITES_PROPERTY_STATIONS);
            jarray = stations.get_array ();
        }
        
        jarray.foreach_element ((a, i, elem) => {           
            var s = new Station.basic(elem); // v
            _starred.set (s.stationuuid, s ); // v1 captures multiple datums. We want id
            if (!s.starred)  s.toggle_starred ();
            warning(@"UUID:$(s.stationuuid)   Name:$(s.name)  Stared:$(s.starred)");
        });

        foreach ( var ss in _starred.values)
        /*
            Add starred notify on each starred station.
        */
        {
            //ss.starred = true;    //TODO Confirm
            ss.notify["starred"].connect ( (sender, property) => {
                if (ss.starred) {
                    warning (@"Fav add: $(ss.stationuuid)");
                    this.add (ss);
                } else {
                    warning (@"Fav remove: $(ss.stationuuid)");
                    this.remove (ss);
                }
            });
        }
    } // load
      




    /**
     * @brief Persists the current state of favorites to the JSON file.
     * 
     * This method serializes the _store and writes it to the favorites file.
     */
    private void persist () 
    {
        debug ("persisting store");

        try {
            _starred_file.delete ();  // FIXME file names
            var stream = _starred_file.create (
                FileCreateFlags.REPLACE_DESTINATION | FileCreateFlags.PRIVATE
            );
            var s = new DataOutputStream (stream);
            s.put_string ( serialize () );
            s.flush ();
            s.close (); // closes base stream also
        } catch (Error e) {
            warning (@"Persist failed with error: $(e.message)");
        }
    }


    private static Json.Node? get_member(Json.Node node, string property_name) {
        // Check if the node is of type OBJECT
        if (node.get_node_type() == Json.NodeType.OBJECT) {
            Json.Object json_object = node.get_object();
    
            // Check if the JSON object has the specified property
            if ( json_object.has_member(property_name) ) 
                return json_object.get_member (property_name);
        }
        return null; // Not an object, so no properties exist
    }
}
