/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**

    @file HttpClient.vala
    @author technosf
    @date 2024-10-01
    @since 1.5.4

*/
using Gee;

/**
 * @brief HTTP functions abstracting Soup library
 *
 */
public class Tuner.HttpClient : Object {

    private static Soup.Session _session;

    static Soup.Session getSession()
    {
        if ( _session == null )
        {
            _session = new Soup.Session ();
            _session.user_agent = @"$(Application.APP_ID)/$(Application.APP_VERSION)";
            _session.timeout = 3;
        }
        return _session;
    }

    public static InputStream GET( string url_string, out uint status_code ) throws Error {
        var msg = new Soup.Message ("GET", url_string);
        var inputStream = getSession().send( msg );
        status_code = msg.status_code;
        return inputStream;
    }
}