/*
* Copyright (c) 2020-2021 Louis Brauer <louis@brauer.family>
*
* This file is part of Tuner.
*
* Tuner is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Tuner is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Tuner.  If not, see <http://www.gnu.org/licenses/>.
*
*/

public class Tuner.LocationDiscovery : Object {

    public static async string country_code () throws GLib.Error {
        warning (@"Starting Geo Location service...");
        var geoclueClient = yield new GClue.Simple (
            Application.APP_ID,
            GClue.AccuracyLevel.COUNTRY,
            null
        );

        var location = geoclueClient.location;
        warning (@"Got heading: $(location.heading)");

        var geoLocation = new Geocode.Location (location.latitude, location.longitude);
        var geocodeClient = new Geocode.Reverse.for_location (geoLocation);
        var place = yield geocodeClient.resolve_async ();

        warning (@"Country code: $(place.country_code)"); 
        return place.country_code;
    }
}
