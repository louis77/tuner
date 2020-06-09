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

class Tuner.Model.RadioBrowserDirectory : IDirectoryProvider {

    // TODO: choose local server from server list
    private const string URL = "http://de1.api.radio-browser.info/json/stations/topclick/9";
    private Soup.Session _session;

    public RadioBrowserDirectory() {
        _session = new Soup.Session ();
        _session.user_agent = "com.github.louis77.tuner.RadioBrowserDirectory/0.1";
    }

    public ArrayList<StationModel> all() {
        var data = load_topclick();
        var stations = new ArrayList<StationModel>();

        data.foreach_element ((array, index, element) => {
            var obj = element.get_object ();
            var name = obj.get_string_member("name");
            var url = obj.get_string_member("url_resolved");
            var location = obj.get_string_member("country");

            stations.add(new StationModel (name, location, url));

            print(@"$index - $name\n");
        });

        return stations;

    }

    // TODO: don't use blocking calls here
    private Json.Array load_topclick() {
        var message = new Soup.Message ("GET", URL);
        _session.send_message (message);
        var body = (string) message.response_body.data;
        var rootnode = Json.from_string (body);
        var rootarray = rootnode.get_array ();

        return rootarray;
    }

}
