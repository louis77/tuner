/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

 /**
    StationStore 
    
    Store and retrieve a collection of stations in a JSON file, i.e. favorites

    Uses libgee for data structures.
  */

using Gee;

namespace Tuner.Model {

public class StationStore : Object {
    private ArrayList<Station> _store;
    private File _favorites_file;

    public StationStore (string favorites_path) {
        Object ();
        
        _store = new ArrayList<Station> ();
        _favorites_file = File.new_for_path (favorites_path);
        ensure ();
        load ();
        debug (@"store initialized in path $favorites_path");
    }

    public void add (Station station) {
        _add (station);
        persist ();
    }

    private void _add (Station station) {
        _store.add (station);
        // TODO Should we do a sorted insert?
    }

    public void remove (Station station) {
        _store.remove (station);
        persist ();
    }

    private void ensure () {
        // Non-racy approach is to try to create the file first
        // and ignore errors if it already exists
        try {
            var df = _favorites_file.create (FileCreateFlags.PRIVATE);
            df.close ();
            debug (@"store created");
        } catch (Error e) {
            // Ignore, file already existed, which is good
        }
    }

    private void load () {
        debug ("loading store");
        Json.Parser parser = new Json.Parser ();
        
        try {
            var stream = _favorites_file.read ();
            parser.load_from_stream (stream);
            stream.close ();
        } catch (Error e) {
            warning (@"store: unable to load data, does it exist? $(e.message)");
        }

        Json.Node? node = parser.get_root ();

        if ( node == null ) return; // No favorites store    

        Json.Array array = node.get_array ();    // Json-CRITICAL **: 21:02:51.821: json_node_get_array: assertion 'JSON_NODE_IS_VALID (node)' failed
        array.foreach_element ((a, i, elem) => {  // json_array_foreach_element: assertion 'array != NULL' failed
            Station station = Json.gobject_deserialize (typeof (Station), elem) as Station;
            // TODO This should probably not be here but in 
            // DirectoryController
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
            warning (@"store: unable to persist store: $(e.message)");
        }
    }

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

    public ArrayList<Station> get_all () {
        return _store;
    }

    public bool contains (Station station) {
        foreach (var s in _store) {
            if (s.id == station.id) {
                return true;
            }
        }
        return false;
    }
}

} 
