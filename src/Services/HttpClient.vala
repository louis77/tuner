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
     * user agent string and a timeout of 2 seconds, maximum 30 connections
     * with only one connection per host.
     * 
     *
     * @return The singleton Soup.Session instance
     */
    private static Soup.Session getSession()
    {
        if (_session == null)
        {
            _session = new Soup.Session.with_options(
               "max-conns", 50,
                "max-conns-per-host", 2 ,
                "timeout", 3,
                "user_agent", @"$(Application.APP_ID)/$(Application.APP_VERSION)"
            );
        }
        debug(@"Conns Max: $(_session.get_max_conns()), Conns PH: $(_session.get_max_conns_per_host())");
        return _session;
    }

    /**
     * @brief Perform a GET request to the specified URL
     *
     * @param url_string The URL to send the GET request to
     * @param status_code Output parameter for the HTTP status code of the response
     * @return InputStream containing the response body, or null if the request failed
     * @throws Error if there's an error sending the request or receiving the response
     */
    public static InputStream? GET(string url_string, out uint status_code) 
    {
        status_code = 0;
        
        if (url_string == null || url_string.length < 4) // domains are at least 4 chars
        {
            warning("GET - Invalid URL: %s", url_string ?? "null");
            return null;
        }

        string sanitized_url = ensure_https_prefix(url_string);

        var msg = new Soup.Message("GET", sanitized_url);

        /*
            Ignore all TLS certificate errors
        */
        msg.accept_certificate.connect ((msg, cert, errors) => {
            return true;
        });

        try {

            if (Uri.is_valid(sanitized_url, UriFlags.NONE))
            {
                var inputStream = getSession().send(msg);
                status_code = msg.status_code;
                return inputStream;
            } else {
                debug("GET - Invalid URL format: %s", sanitized_url);
            }
        } catch (Error e) {
            warning("GET - Error accessing URL: %s (%s)",
                sanitized_url,
                e.message);
        }

        return null;
    }

    /**
     * @brief Perform an asynchronous GET request to the specified URL
     *
     * @param url_string The URL to send the GET request to
     * @param status_code Output parameter for the HTTP status code of the response
     * @return InputStream containing the response body, or null if the request failed
     */
    public static async InputStream? GETasync(Uri uri, out uint status_code) 
    {
        status_code = 0;

        var msg = new Soup.Message.from_uri("GET", uri);

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
            warning("GETasync - Couldn't fetch resource: %s (%s)",
            uri.to_string(),
                e.message);
        }

        return null;
    }

    /**
     * @brief Ensures that the given URL has an HTTPS prefix
     *
     * This method checks if the provided URL starts with either "http://" or "https://".
     * If it doesn't have either prefix, it adds "https://" to the beginning of the URL.
     *
     * @param url The input URL string to be checked and potentially modified
     * @return A string representing the URL with an HTTPS prefix
     *
     * @note This method does not validate the URL structure beyond checking for the protocol prefix
     */
    private static string ensure_https_prefix(string url) {
        // Check if the string starts with "http://" or "https://"
        if (!url.has_prefix("http://") && !url.has_prefix("https://")) {
            // If it doesn't, prefix the string with "https://"
            return "https://" + url;
        }
        return url;
    }
}