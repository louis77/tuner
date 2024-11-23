/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file RadioBrowser.vala
 *
 * @brief Interface to radio-browser.info API and servers
 * 
 */

using Gee;

/**
 * @namespace Tuner.RadioBrowser
 *
 * @brief Interface to radio-browser.info API and servers
 *
 * This namespace provides functionality to interact with the radio-browser.info API.
 * It includes features for:
 * - Retrieving radio station metadata JSON
 * - Executing searches and retrieving radio station metadata JSON
 * - Reporting back user interactions (voting, listen tracking)
 * - Tag and other metadata retrieval
 * - API Server discovery and connection handling from DNS and from round-robin API server
 */
namespace Tuner.Provider {


    /**
     * @struct SearchParams
     * @brief API search parameters 
     * 
     * Defines the search criteria used when querying the radio-browser.info API
     * for stations.
     */
    public struct SearchParams {
        /** @brief Search text to match against station names */
        string text;

        /** @brief List of tags to filter stations by */
        ArrayList<string> tags;

        /** @brief List of specific station UUIDs to retrieve */
        ArrayList<string> uuids;

        /** @brief ISO country code to filter stations by */
        string countrycode;

        /** @brief Sorting criteria for the results */
        SortOrder order;

        /** @brief Whether to reverse the sort order */
        bool reverse;
    }

    /**
     * @brief Error domain for RadioBrowser-related errors
     * 
     */
    public errordomain DataError {
        /** @brief Error parsing API response data */
        PARSE_DATA,

        /** @brief Unable to establish connection to API servers */
        NO_CONNECTION
    }

    /**
     * @enum SortOrder
     * @brief Enumeration of sorting options for station search results
     * 
     */
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

        /**
         * @brief Convert SortOrder enum to string representation
         *
         * @return String representation of the SortOrder
         */
        public string to_string() {
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
                    assert_not_reached();
            }
        }
    }

    /**
     * @class Tag
     *
     * @brief Represents a radio station tag with usage statistics
     * 
     * Encapsulates metadata about a tag used to categorize radio stations,
     * including its name and the number of stations using it.
     */
    public class Tag : Object {
        /** @brief The tag name */
        public string name { get; set; }

        /** @brief Number of stations using this tag */
        public uint stationcount { get; set; }
    }

    /**
     * @brief String comparison utility function
     * 
     * @param a First string to compare
     * @param b Second string to compare
     * @return true if strings are equal, false otherwise
     */
    //  public bool EqualCompareString(string a, string b) {
    //      return a == b;
    //  }

    /**
     * @class Client
     *
     * @brief Main RadioBrowser API client implementation
     * 
     * Provides methods to interact with the radio-browser.info API, including:
     * - Station search and retrieval
     * - User interaction tracking (votes, listens)
     * - Tag management
     * - Server discovery and connection handling
     *
     * Example usage:
     * @code
     * try {
     *     var client = new Client();
     *     var params = SearchParams() {
     *         text = "jazz",
     *         order = SortOrder.NAME
     *     };
     *     var stations = client.search(params, 10);
     * } catch (DataError e) {
     *     error("Failed to search: %s", e.message);
     * }
     * @endcode
     */
    public interface API : Object 
    {
        public enum Status
        {
            OK,
            NO_SERVER_LIST,
            NO_SERVERS_PRESENTED,
            NOT_AVAILABLE,
            UNKNOW_ERROR
        }

        public abstract Status status { get; protected set; }
        public abstract DataError? last_data_error { get; protected set; }
        public virtual void clear_last_error() { last_data_error = null; }


        /**
         * @brief Track a station listen event
         *
         * @param stationuuid UUID of the station being listened to
         */
        public abstract void track(string stationuuid);

        /**
         * @brief Vote for a station
         * @param stationuuid UUID of the station being voted for
         */
         public abstract void vote(string stationuuid) ;



        /**
         * @brief Get all available tags
         *
         * @return ArrayList of Tag objects
         * @throw DataError if unable to retrieve or parse tag data
         */
         public abstract ArrayList<Tag> get_tags() throws DataError;


        /**
         * @brief Get a station by its UUID
         * @param uuid UUID of the station to retrieve
         * @return Station object if found, null otherwise
         * @throw DataError if unable to retrieve or parse station data
         */
         public abstract Model.Station? by_uuid(string uuid) throws DataError;


        /**
         * @brief Search for stations based on given parameters
         *
         * @param params Search parameters
         * @param rowcount Maximum number of results to return
         * @param offset Offset for pagination
         * @return ArrayList of Station objects matching the search criteria
         * @throw DataError if unable to retrieve or parse station data
         */
         public abstract ArrayList<Model.Station> search(SearchParams params, uint rowcount, uint offset = 0) throws DataError;
    }
}