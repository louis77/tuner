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
* Authored by: Louis Brauer <louis@brauer.family>
*/

using Gee;

// TODO: handle failures
// TODO: use async
// TODO: this should not know anything about other widgets or models
//       Move that to the DirectoryController

class Tuner.Services.RadioBrowserDirectory : Object, IDirectoryProvider {

    // TODO: choose local server from server list
    private const string API_BASE_URL = "http://de1.api.radio-browser.info";
    private Soup.Session _session;

    public RadioBrowserDirectory() {
        _session = new Soup.Session ();
        // TODO: Get Application ID dynamically
        _session.user_agent = "com.github.louis77.tuner/0.1";
    }

    public ArrayList<Model.StationModel> random () throws DataError {
        var data = load (10, "random");
        if (data == null) {
            throw new DataError.PARSE_DATA("Unable to retrieve data");
        }

        var stations = new ArrayList<Model.StationModel>();

        data.foreach_element ((array, index, element) => {
            var obj = element.get_object ();
            var id = obj.get_string_member ("stationuuid") ?? "unknown id";
            var name = obj.get_string_member("name") ?? "unknown name";
            var url = obj.get_string_member("url_resolved") ?? "unknown url";
            var location = obj.get_string_member("country") ?? "unknown country";
            var favicon = obj.get_string_member("favicon");

            var s = new Model.StationModel (id, name, location, url);
            s.favicon_url = favicon;
            stations.add(s);
        });

        return stations;

    }

    public ArrayList<Model.StationModel> trending () throws DataError {
        var data = load (10, "clicktrend");
        if (data == null) {
            throw new DataError.PARSE_DATA("Unable to retrieve data");
        }

        var stations = new ArrayList<Model.StationModel>();

        data.foreach_element ((array, index, element) => {
            var obj = element.get_object ();
            var id = obj.get_string_member ("stationuuid") ?? "unknown id";
            var name = obj.get_string_member("name") ?? "unknown name";
            var url = obj.get_string_member("url_resolved") ?? "unknown url";
            var location = obj.get_string_member("country") ?? "unknown country";
            var favicon = obj.get_string_member("favicon");

            var s = new Model.StationModel (id, name, location, url);
            s.favicon_url = favicon;
            stations.add(s);
        });

        return stations;

    }


    public void track (Model.StationModel station) {
        debug (@"sending listening event for station $(station.id)");
        var resource = @"json/url/$(station.id)";
        var message = new Soup.Message ("GET", @"$API_BASE_URL/$resource");
        var response_code = _session.send_message (message);
        debug (@"response: $(response_code)");
    }

    public void vote (Model.StationModel station) {
        debug (@"sending vote event for station $(station.id)");
        var resource = @"json/vote/$(station.id)";
        var message = new Soup.Message ("GET", @"$API_BASE_URL/$resource");
        var response_code = _session.send_message (message);
        debug (@"response: $(response_code)");
    }

    // TODO: don't use blocking calls here
    private Json.Array? load (uint rowcount, string order) {
        //var resource = @"json/stations/topclick/$rowcount";

        debug ("trying to fetch data from radio-browser");
        var resource = @"json/stations/search?language=en&limit=$rowcount&order=$order";
        var message = new Soup.Message ("GET", @"$API_BASE_URL/$resource");
        Json.Node rootnode;

        var response_code = _session.send_message (message);
        debug (@"response from radio-browser.info: $response_code");
        var body = (string) message.response_body.data;

        try {
            rootnode = Json.from_string (body);
        } catch (Error e) {
            warning ("unable to parse JSON response: %s", e.message);
            return null;
        }
        var rootarray = rootnode.get_array ();

        return rootarray;
    }

}
