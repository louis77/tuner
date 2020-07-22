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

using Gee;

namespace Tuner.RadioBrowser {

public struct SearchParams {
    string text;
    ArrayList<string> tags;
    ArrayList<string> uuids;
    SortOrder order;
    bool reverse;
}

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
    public uint clickcount { get; set; }
}

public class Tag : Object {
    public string name { get; set; }
    public uint stationcount { get; set; }
}

public class Client : Object {

    // TODO: choose local server from server list
    private const string API_BASE_URL = "https://de1.api.radio-browser.info";
    private Soup.Session _session;

    public Client() {
        _session = new Soup.Session ();
        // TODO: Automatically find mirror list
        _session.user_agent = "com.github.louis77.tuner/1.2";

        /*
        Resolver resolver = Resolver.get_default ();
        GLib.ArrayList<InetAddress> addresses = resolver.lookup_by_name ("all.api.radio-browser.info");
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

    private Tag jnode_to_tag (Json.Node node) {
        return Json.gobject_deserialize (typeof (Tag), node) as Tag;
    }

    private ArrayList<Tag> jarray_to_tags (Json.Array data) {
        var tags = new ArrayList<Tag> ();

        data.foreach_element ((array, index, element) => {
            Tag s = jnode_to_tag (element);
            tags.add (s);
        });

        return tags;
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

    public ArrayList<Station> get_stations (string resource) throws DataError {
        debug (@"RB $resource");

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

    public ArrayList<Station> search (SearchParams params,
                                      uint rowcount,
                                      uint offset = 0) throws DataError {
        // by uuids
        if (params.uuids != null) {
            var stations = new ArrayList<Station> ();
            foreach (var uuid in params.uuids) {
                var station = this.by_uuid(uuid);
                if (station != null) {
                    stations.add (station);
                }
            }
            return stations;
        }

        // by text or tags
        var resource = @"json/stations/search?limit=$rowcount&order=$(params.order)&offset=$offset";
        if (params.text != null && params.text != "") { 
            resource += @"&name=$(params.text)";
        }
        if (params.tags == null) {
            warning ("param tags is null");
        }
        if (params.tags.size > 0 ) {
            string tag_list = params.tags[0];
            if (params.tags.size > 1) {
                tag_list = string.joinv (",", params.tags.to_array());
            }
            resource += @"&tagList=$tag_list&tagExact=true";
        }
        if (params.order != SortOrder.RANDOM) {
            // random and reverse doesn't make sense
            resource += @"&reverse=$(params.reverse)";
        }
        return get_stations (resource);
    }

    public Station? by_uuid (string uuid) throws DataError {
        var resource = @"json/stations/byuuid/$uuid";
        var result = get_stations (resource);
        if (result.size == 0) {
            return null;
        }
        return result[0];
    }

    public ArrayList<Tag> get_tags () throws DataError {
        var resource = @"json/tags";
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

        var tags = jarray_to_tags (rootarray);
        return tags;

    }

}
}
