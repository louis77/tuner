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

namespace Tuner.RadioBrowser {

public errordomain DataError {
    PARSE_DATA
}

public enum SortOrder {
    NAME,
    URL,
    HOMEPAGE,
    FAVICON,
    TAGS,
    COUNTRY,
    STATE,
    LANGUAGE,
    VOTES,
    CODEC,
    BITRATE,
    LASTCHECKOK,
    LASTCHECKTIME,
    CLICKTIMESTAMP,
    CLICKCOUNT,
    CLICKTREND,
    RANDOM;

    public string to_string () {
        switch (this) {
            case NAME:
                return "name";
            case URL:
                return "url";
            case HOMEPAGE:
                return "homepage";
            case FAVICON:
                return "favicon";
            case TAGS:
                return "tags";
            case COUNTRY:
                return "country";
            case STATE:
                return "state";
            case LANGUAGE:
                return "language";
            case VOTES:
                return "votes";
            case CODEC:
                return "codec";
            case BITRATE:
                return "bitrate";
            case LASTCHECKOK:
                return "lastcheckok";
            case LASTCHECKTIME:
                return "lastchecktime";
            case CLICKTIMESTAMP:
                return "clicktimestamp";
            case CLICKCOUNT:
                return "clickcount";
            case CLICKTREND:
                return "clicktrend";
            case RANDOM:
                return "random";
            default:
                assert_not_reached ();
        }
    }
}

public class Station : Object {
    public string stationuuid { get; set; }
    public string name { get; set; }
    public string url_resolved { get; set; }
    public string country { get; set; }
    public string favicon { get; set; }
}

public class Client : Object {

    // TODO: choose local server from server list
    private const string API_BASE_URL = "https://de1.api.radio-browser.info";
    private Soup.Session _session;

    public Client() {
        _session = new Soup.Session ();
        // TODO: Automatically generate this
        _session.user_agent = "com.github.louis77.tuner/0.1";

        /*
        Resolver resolver = Resolver.get_default ();
        GLib.List<InetAddress> addresses = resolver.lookup_by_name ("all.api.radio-browser.info");
        foreach (var address in addresses) {
            var host = resolver.lookup_by_address (address);
            debug (@"Found RB host: $address with name $host");
        }
        */
    }

    private Station jnode_to_station (Json.Node node) {
        return Json.gobject_deserialize (typeof (Station), node) as Station;
    }

    private ArrayList<Station> jarray_to_stations (Json.Array data) {
        var stations = new ArrayList<Station> ();

        data.foreach_element ((array, index, element) => {
            Station s = jnode_to_station (element);
            stations.add (s);
        });

        return stations;
    }

    public void track (string stationuuid) {
        debug (@"sending listening event for station $stationuuid");
        var resource = @"json/url/$stationuuid";
        var message = new Soup.Message ("GET", @"$API_BASE_URL/$resource");
        var response_code = _session.send_message (message);
        debug (@"response: $(response_code)");
    }

    public void vote (string stationuuid) {
        debug (@"sending vote event for station $stationuuid");
        var resource = @"json/vote/$stationuuid)";
        var message = new Soup.Message ("GET", @"$API_BASE_URL/$resource");
        var response_code = _session.send_message (message);
        debug (@"response: $(response_code)");
    }

    // TODO: don't use blocking calls here
    public async ArrayList<Station> load (uint rowcount,
                                    SortOrder order,
                                    bool reverse = false,
                                    uint offset = 0) throws DataError {
        debug ("trying to fetch data from radio-browser");

        var resource = @"json/stations/search?language=en&limit=$rowcount&order=$order&reverse=$reverse&offset=$offset";
        var message = new Soup.Message ("GET", @"$API_BASE_URL/$resource");
        Json.Node rootnode;

        var response_code = _session.send_message (message);
        debug (@"response from radio-browser.info: $response_code");
        var body = (string) message.response_body.data;

        try {
            rootnode = Json.from_string (body);
        } catch (Error e) {
            throw new DataError.PARSE_DATA (@"unable to parse JSON response: $(e.message)");
        }
        var rootarray = rootnode.get_array ();

        var stations = jarray_to_stations (rootarray);
        return stations;
    }

}
}
