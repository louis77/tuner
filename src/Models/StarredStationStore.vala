/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @file StarredStationStore.vala
 * @brief Class to store and retrieve a collection of favorite stations.
 * 
 * This class manages a collection of stations stored in a JSON file.
 * It provides methods to add, remove, and persist stations.
 */

using Gee;

namespace Tuner.Model {

/**
 * @class StarredStationStore
 * @brief Manages a collection of favorite stations.
 * 
 * This class allows for storing, retrieving, and persisting a list of favorite stations
 * in a JSON file. It uses libgee for data structures.
 */
public class StarredStationStore : Object {
    private ArrayList<Station> _store; ///< Collection of favorite stations.
    private File _favorites_file; ///< File to persist favorite stations.

    /**
     * @brief Constructor for StarredStationStore.
     * @param favorites_path The path to the JSON file where favorites are stored.
     */
    public StarredStationStore (string favorites_path) {
        Object ();
        
        _store = new ArrayList<Station> ();
        _favorites_file = File.new_for_path (favorites_path);
        ensure ();
        load ();
        debug (@"store initialized in path $favorites_path");
    }

    /**
     * @brief Adds a station to the favorites and persists the change.
     * @param station The station to be added.
     */
    public void add (Station station) {
        _add (station);
        persist ();
    }

    /**
     * @brief Internal method to add a station to the collection.
     * @param station The station to be added.
     */
    private void _add (Station station) {
        _store.add (station);
        // TODO Should we do a sorted insert?
    }

    /**
     * @brief Removes a station from the favorites and persists the change.
     * @param station The station to be removed.
     */
    public void remove (Station station) {
        _store.remove (station);
        persist ();
    }

    /**
     * @brief Ensures the favorites file exists.
     * 
     * This method attempts to create the file if it does not exist,
     * ignoring errors if it already exists.
     */
    private void ensure () {
        try {
            var df = _favorites_file.create (FileCreateFlags.PRIVATE);
            df.close ();
            debug (@"store created");
        } catch (Error e) {
            // Ignore, file already existed, which is good
        }
    }

    /**
     * @brief Loads the favorites from the JSON file.
     * 
     * This method reads the JSON file and populates the _store with
     * the favorite stations.
     */
    private void load () {
        debug ("loading store");
        Json.Parser parser = new Json.Parser ();
        
        try {
            var stream = _favorites_file.read ();
            parser.load_from_stream (stream);
            stream.close ();
        } catch (Error e) {
            warning (@"Load failed with error: $(e.message)");
        }

        Json.Node? node = parser.get_root ();

        if ( node == null ) return; // No favorites store    

        Json.Array array = node.get_array ();
        array.foreach_element ((a, i, elem) => {
            //Station station = new Station.deserialize(elem);
            Station station = new Station ( elem) ;
            station.notify["starred"].connect ( (sender, property) => {
                if (station.starred) {
                    this.add (station);
                } else {
                    this.remove (station);
                }
            });
    
            _add (station);
        });

        debug (@"loaded store size: $(_store.size)");
    }

    /**
     * @brief Persists the current state of favorites to the JSON file.
     * 
     * This method serializes the _store and writes it to the favorites file.
     */
    private void persist () {
        debug ("persisting store");
        var data = serialize ();
        
        try {
            _favorites_file.delete ();
            var stream = _favorites_file.create (
                FileCreateFlags.REPLACE_DESTINATION | FileCreateFlags.PRIVATE
            );
            var s = new DataOutputStream (stream);
            s.put_string (data);
            s.flush ();
            s.close (); // closes base stream also
        } catch (Error e) {
            warning (@"Persist failed with error: $(e.message)");
        }
    }

    /**
     * @brief Serializes the current favorites to a JSON string.
     * @return A JSON string representation of the favorites.
     */
    public string serialize () {
        Json.Builder builder = new Json.Builder ();
        builder.begin_array ();
        foreach (var station in _store) {
            var node = Json.gobject_serialize (station);
            builder.add_value (node);
        }
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        string data = generator.to_data (null);
        return data;
    }

    /**
     * @brief Retrieves all favorite stations.
     * @return An ArrayList of favorite stations.
     */
    public ArrayList<Station> get_all () {
        return _store;
    }

    /**
     * @brief Checks if a station is in the favorites.
     * @param station The station to check.
     * @return True if the station is in favorites, false otherwise.
     */
    public bool contains (Station station) {
        foreach (var s in _store) {
            if (s.stationuuid == station.stationuuid) {
                return true;
            }
        }
        return false;
    }
}

} 
