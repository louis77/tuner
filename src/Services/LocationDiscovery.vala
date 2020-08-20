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

public class Tuner.LocationDiscovery : Object {

    public static async string country_code () {
        warning (@"Starting Geo Location service...");
        var geoclueClient = yield new GClue.Simple (
            Application.APP_ID,
            GClue.AccuracyLevel.COUNTRY,
            null
        );

        warning ("Created geoclueClient");
        var location = geoclueClient.location;
        warning (@"Got country: $(location.heading)");

        var geoLocation = new Geocode.Location (location.latitude, location.longitude);
        var geocodeClient = new Geocode.Reverse.for_location (geoLocation);
        var place = yield geocodeClient.resolve_async ();

        warning (@"Country code: $(place.country_code)"); 
        return place.country_code;
    }
}