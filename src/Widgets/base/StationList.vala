/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

using Gee;

/**
 * @class StationList
 * @brief A widget for displaying and managing a list of radio stations.
 *
 * The StationList class extends AbstractContentList to provide a specialized
 * widget for displaying radio stations. It manages station selection, favorites,
 * and provides signals for various state changes.
 *
 * @extends AbstractContentList
 */
public class Tuner.StationList : ContentList
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
 * @signal station_count_changed
 *
 * @brief Emitted when the number of stations changes.
 *
 * @param count The new number of stations.
 */
// public signal void station_count_changed_sig (uint count);

/**
 * @signal favourites_changed
 *
 * @brief Emitted when a station's favorite status changes.
 */
	public signal void favourites_changed_sig ();


/**
 * @brief The list of stations to display.
 *
 * When set, this property clears the existing list and populates it with
 * the new stations. It also sets up signal connections for each station.
 */
	public Collection<Model.Station> stations {
		set construct {
			clear ();
			if (value == null)
				return;

			foreach (var s in value)
			{
				s.notify["starred"].connect (() => {
					favourites_changed_sig ();
				});
				var box = new StationButton (s);
				box.clicked.connect (() => {
					station_clicked_sig (box.station);
				});
				add (box);
			}
			item_count = value.size;
		}
	}     // stations

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
	}     // StationList

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
	}     // StationList.with_stations


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
	}     // clear

/**
 * @property item_count
 *
 * @brief The number of stations in the list.
 *
 * This property implements the abstract property from AbstractContentList.
 */
	public override uint item_count { get; set; }
}
