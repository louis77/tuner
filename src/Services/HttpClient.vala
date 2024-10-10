/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @file HttpClient.vala
 * @author technosf
 * @date 2024-10-01
 * @since 1.5.4
 * @brief HTTP client implementation using Soup library
 */

using Gee;

/**
 * @class Tuner.HttpClient
 * @brief HTTP functions abstracting Soup library
 *
 * This class provides static methods for making HTTP requests using the Soup library.
 * It includes a singleton Soup.Session instance for efficient request handling.
 */
public class Tuner.HttpClient : Object {

    /**
     * @brief Singleton instance of Soup.Session
     *
     * This private static variable holds the single instance of Soup.Session
     * used for all HTTP requests in the application. It is initialized lazily
     * in the getSession() method.
     */
    private static Soup.Session _session;

    /**
     * @brief Get the singleton Soup.Session instance
     *
     * This method returns the singleton Soup.Session instance, creating it
     * if it doesn't already exist. The session is configured with a custom
     * user agent string and a timeout of 3 seconds.
     *
     * @return The singleton Soup.Session instance
     */
    private static Soup.Session getSession()
    {
        if (_session == null)
        {
            _session = new Soup.Session();
            _session.user_agent = @"$(Application.APP_ID)/$(Application.APP_VERSION)";
            _session.timeout = 5;
        }
        return _session;
    }

    /**
     * @brief Perform a GET request to the specified URL
     *
     * This method sends a GET request to the specified URL using the singleton
     * Soup.Session instance. It returns the response body as an InputStream and
     * outputs the status code of the response.
     *
     * @param url_string The URL to send the GET request to
     * @param status_code Output parameter for the HTTP status code of the response
     * @return InputStream containing the response body
     * @throws Error if there's an error sending the request or receiving the response
     */
    public static InputStream? GET(string url_string, out uint status_code) 
    {
        status_code = 0;
        var msg = new Soup.Message("GET", url_string);

        /*
            Ignore all TLS certificate errors
        */
        msg.accept_certificate.connect ((msg, cert, errors) => {
            return true;
        });

        try {

            if (Uri.is_valid(url_string, NONE))
            {
                var inputStream = getSession().send(msg);
                status_code = msg.status_code;
                return inputStream;
            }
        } catch (Error e) {
                warning ("GET - Error accessing URL: %s (%s)",
                url_string ?? "unknown url",
                    e.message);
            }

        return null;
    }

    /**
     * @brief Perform an asynchronous GET request to the specified URL
     *
     * This method sends an asynchronous GET request to the specified URL using the singleton
     * Soup.Session instance. It returns the response body as an InputStream and
     * outputs the status code of the response.
     *
     * @param url_string The URL to send the GET request to
     * @param status_code Output parameter for the HTTP status code of the response
     * @return InputStream containing the response body, or null if the request failed
     */
    public static async InputStream? GETasync(string url_string, out uint status_code) 
    {
        status_code = 0;

        try {
            /*
                Ignore all URLs that are too short to be valid or dont validate
            */
            if ( url_string != null 
                && url_string.length < 7 
                && !Uri.is_valid(url_string, UriFlags.NONE)) {
                warning("URL Check - Failed for URL: %s", url_string);
                return null;
            }
        } catch (GLib.UriError e) {
            return null;
        }

        var msg = new Soup.Message("GET", url_string);

        /*
            Ignore all TLS certificate errors
        */
        msg.accept_certificate.connect ((msg, cert, errors) => {
            return true;
        });

        try {

            var inputStream = yield getSession().send_async(msg, Priority.DEFAULT, null);
            status_code = msg.status_code;
            return inputStream;

        } catch (Error e) {
            warning ("GETasync - Couldn't render favicon: %s (%s)",
                url_string ?? "unknown url",
                e.message);
        }

        return null;
    }
}