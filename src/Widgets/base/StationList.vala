/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file StationList.vala
 */

using Gee;

/**
 * @class StationList
 * @brief A widget for displaying and managing a list of radio stations.
 *
 * The StationList class extends ListFlowBox to provide a specialized
 * widget for displaying radio stations. It manages station selection.
 *
 * @extends ListFlowBox
 */
public class Tuner.StationList : ListFlowBox
{

	/**
	* @signal selection_changed
	*
	* @brief Emitted when a station is selected.
	*
	* @param station The selected Model.Station.
	*/
	public signal void station_clicked_sig (Model.Station station);


	/**
	* @brief Constructs a new StationList instance.
	*
	* Initializes the StationList with default properties for layout and behavior.
	*/
	public StationList ()
	{
		Object (
			homogeneous: false,
			min_children_per_line: 1,
			max_children_per_line: 3,
			column_spacing: 5,
			row_spacing: 5,
			border_width: 20,
			valign: Gtk.Align.START,
			selection_mode: Gtk.SelectionMode.NONE
			);
	} // StationList


	/**
	* @brief Constructs a new StationList instance with a predefined list of stations.
	*
	* @param stations The ArrayList of Model.Station objects to populate the list.
	*/
	public static StationList? with_stations (Gee.Collection<Model.Station>? stations)
	{
		if (stations == null)
			return null;
		StationList list = new StationList ();
		list.stations = stations;
		return list;
	} // StationList.with_stations


	/**
	* @brief The list of stations to display.
	*
	* When set, this property clears the existing list and populates it with
	* the new stations. It also sets up signal connections for each station.
	*/
	public Collection<Model.Station> stations 
	{
		set construct {
			clear ();
			if (value == null)
				return;

			foreach (var station in value)
			{
				var box = new StationButton (station);
				box.clicked.connect (() => {
					station_clicked_sig (box.station);
				});
				add (box);
			}
			item_count = value.size;
		}
	} // stations


	/**
	* @brief Clears all stations from the list.
	*
	* This method removes and destroys all child widgets from the StationList.
	*/
	public void clear ()
	{
		var childs = get_children();
		foreach (var c in childs)
		{
			c.destroy();
		}
	} // clear
} // StationList
