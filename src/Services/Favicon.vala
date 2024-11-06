/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @file Favicon.vala
 * @author technosf
 * @date 2024-10-01
 * @brief Get, cache and serve favicons
 * @version 1.5.4
 *
 * This file contains the Tuner.Favicon class, which handles the retrieval,
 * caching, and serving of favicons for radio stations.
 */

/**
 * @brief Get, cache and serve favicons
 *
 * This class handles the retrieval, caching, and serving of favicons for radio stations.
 * It provides methods to load favicons from cache or fetch them from the internet.
 *
 * @class Tuner.Favicon
 * @extends Object
 */
public class Tuner.Favicon : GLib.Object {

     /**
     * @brief Asynchronously load the favicon for a given station
     *
     * This method attempts to load the favicon from the cache first. If not found in the cache
     * or if forceReload is true, it will fetch the favicon from the internet asynchronously
     * scale it to 48x48 pixels, and save it to a cache file.
     *
     * @param station The station for which to load the favicon
     * @param forceReload If true, bypass the cache and fetch the favicon from the internet
     * @return The loaded favicon as a Gdk.Pixbuf, or null if loading fails
     */
    public static async Gdk.Pixbuf? load_async(Model.Station station, bool forceReload = false)
    {
        if ( station.favicon_url == null || station.favicon_url == "" || station.favicon_load_error ) return null;  // Favicon is erring out, so bypss loading it this session

        var favicon_cache_file = Path.build_filename(Application.instance.cache_dir, station.id);

        // Check if not forcing reload and then if favicon is cached
        if (    !forceReload 
            &&  FileUtils.test(favicon_cache_file, FileTest.EXISTS)) 
            {
            try {
                return new Gdk.Pixbuf.from_file_at_scale(favicon_cache_file, 48, 48, true);
            } catch (Error e) {
                warning(@"Failed to load cached favicon: $(e.message)");
            }
        }

        // If not in cache or force reload, fetch from internet
        uint status_code;

        InputStream? stream = yield HttpClient.GETasync(station.favicon_url, out status_code);

        if ( stream != null && status_code == 200) {
            try {
                var pixbuf = yield new Gdk.Pixbuf.from_stream_async(stream, null);
                var scaled_pixbuf = pixbuf.scale_simple(48, 48, Gdk.InterpType.BILINEAR);

                // Save to cache
                scaled_pixbuf.save(favicon_cache_file, "png");

                return scaled_pixbuf;
            } catch (Error e) {
                warning(@"Failed to process favicon $(station.favicon_url) - $(e.message)");
            }
        }

        // Could not load the favicon, so flag not to try again in this session
        station.favicon_load_error = true;
        return null;
    }
 }