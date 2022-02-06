/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
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
