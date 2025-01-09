/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file SearchController.vala
 *
 * @since 2.0.0
 *
 * @brief Defines the below-headerbar display of stations in the Tuner application.
 *
 * This file contains the Display class, which implements various
 * features such as a source list, content stack that display and manage Station
 * settings and handles user actions like station selection.
 *
 * @see Tuner.DirectoryController
 * @see Tuner.StationListHookup
 * @see Tuner.StationListBox
 */

using Gee;

/**
 * A controller class that handles searching functionality within the Tuner application.
 *
 * This class manages search operations and provides an interface for performing
 * searches within the application.
 */
public class Tuner.SearchController : Object
{
	private const uint SEARCH_DELAY = 333;
	public signal void search_for_sig(string text);

	private DirectoryController _directory;
	private StationListBox _station_list_box;
	private StationListHookup _station_list_hookup;
	private uint _max_search_results;
	private uint _search_handler_id = 0;
	private string _current_search_term;

	/**
	* Controller class for handling station search functionality.
	*
	* @param dc The directory controller instance to manage station directories
	* @param slh The station list hookup instance for station data binding
	* @param slb The station list box widget instance to display search results
	* @param max_search_results Maximum number of search results to display (defaults to 100)
	*/
	public SearchController(DirectoryController dc, StationListHookup slh, StationListBox slb, uint max_search_results = 100)
	{
		Object();
		_directory           = dc;
		_station_list_hookup = slh;
		_station_list_box    = slb;
		_max_search_results  = max_search_results;
	}     // SearchController

	/**
	* @brief Handles a search request.
	*
	* This method is called when the user types in the search entry.
	* It cancels any ongoing search and starts a new search after a brief delay.
	*
	* @param search_term The search term to search for.
	*/
	public void handle_search_for(string search_term)
	{
		var search = search_term.strip();
		if (search.length == 0 || _current_search_term == search)
			return;                                                                               // No new search

		_current_search_term = search;

		if (_search_handler_id > 0)
		// Cancel any ongoing search
		{
			Source.remove(_search_handler_id);			
			_search_handler_id = 0;
		}

		_search_handler_id = Timeout.add(SEARCH_DELAY, () =>
		                                 // After a brief delay, start the search
		{
            _search_handler_id = 0;
			load_station_search_results.begin(search, _station_list_box);
			return Source.REMOVE;
		}); // _search_handler_id
	} // handle_search_for

	/**
	* @brief Loads search stations based on the provided text and updates the content box.
	*
	* Async since 1.5.5 so that UI is responsive during long searches
	* @param search_term The text to search for stations.
	* @param results_box The ContentBox to update with the search results.
	*/
	private async void load_station_search_results(string search_term, StationListBox results_box)
		throws SourceError
	{
		var station_set = _directory.load_search_stations(search_term, 100);

		try
		{
			var stations = yield station_set.next_page_async(); // Loads results using async call

			if (stations == null || stations.size == 0)
			{
				results_box.show_nothing_found();
			}
			else
			{
				var _slist = StationList.with_stations(stations);
				_station_list_hookup.station_list_hookup(_slist);
				results_box.parameter = search_term;	// set parameter first as content sets off a signal
				results_box.content   = _slist;
			}
		} catch (SourceError e)
		{
			results_box.show_alert();
		}
		results_box.show_all();
	} // load_search_stations
} // SearchController
