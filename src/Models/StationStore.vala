/*
* Copyright (c) 2020 Louis Brauer (https://github.com/louis77)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Louis Brauer <louis77@member.fsf.org>
*/

// StationStore can store and retrieve a collection of stations
// in a JSON file

using Gee;

namespace Tuner.Model {

public class StationStore : Object {
    private ArrayList<Station> _store;
    private File _data_file;

    public StationStore (string data_path) {
        Object ();
        
        _store = new ArrayList<Station> ();
        _data_file = File.new_for_path (data_path);
        debug (@"store initialized in path $data_path");
        load ();
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

    private void load () {
        debug ("loading store");
        Json.Parser parser = new Json.Parser ();
        
        try {
            var stream = _data_file.read ();
            parser.load_from_stream (stream);
            stream.close ();
        } catch (Error e) {
            warning (@"store: unable to load data, does it exist? $(e.message)");
        }

        Json.Node node = parser.get_root ();
        Json.Array array = node.get_array ();
        array.foreach_element ((a, i, elem) => {
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
            _data_file.delete ();
            var stream = _data_file.create (
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