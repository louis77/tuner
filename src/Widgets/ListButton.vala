/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file ListButton.vala
 *
 * @brief ListButton classes
 *
 */

using Gtk;

/**
 * @class ListButton
 * @brief A custom button with a dropdown menu for station selection and context actions
 *
 * The ListButton class provides a button that displays a dropdown menu of stations
 * and allows for context actions such as copying the list to the clipboard or clearing
 * all items from the menu.
 *
 * @extends Gtk.Button
 */
public class Tuner.ListButton : Gtk.Button
{
/**
 * @signal item_station_selected_sig
 * @brief Emitted when a station is selected from the dropdown menu.
 * @param station The selected station.
 */
	public signal void item_station_selected_sig(Model.Station station);

	private Gtk.Menu dropdown_menu;
	private Gtk.Menu context_menu;
	private List<Gtk.MenuItem> menu_items;
	private StringBuilder clipboard_text = new StringBuilder();

	Model.Station last_station;
	string last_title;
	Gtk.MenuItem last_menu_item;

/**
 * @brief Constructs a new ListButton with an icon.
 * @param icon_name The name of the icon to display on the button.
 * @param size The size of the icon.
 */
	public ListButton.from_icon_name(string? icon_name,  IconSize size = IconSize.BUTTON)
	{
		Object();
		var image = new Image.from_icon_name(icon_name, size);
		this.set_image(image);
		this.dropdown_menu = new Gtk.Menu();
		this.clicked.connect(() => {
			if (menu_items.length() > 0)
			{
				this.dropdown_menu.popup_at_widget(this, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null);
				limit_dropdown_menu_width();
			}
		});
		initialize_context_menu();
	}

/**
 * @brief Constructs a new ListButton without an icon.
 */
	public ListButton()
	{
		Object();
		this.dropdown_menu = new Gtk.Menu();
		this.clicked.connect(() => {
			if (menu_items.length() > 0)
			{
				this.dropdown_menu.popup_at_widget(this, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null);
				limit_dropdown_menu_width();
			}
		});
		initialize_context_menu();
	}


/**
 * @brief Initializes the context menu with copy and clear actions.
 */
	private void initialize_context_menu()
	{
		menu_items   = new List<Gtk.MenuItem>();
		context_menu = new Gtk.Menu();

		var copy_item = new Gtk.MenuItem.with_label("Copy List to Clipboard");
		copy_item.activate.connect(() => {
			copy_list_to_clipboard();
			context_menu.popdown();
			dropdown_menu.popdown();
		});
		context_menu.append(copy_item);

		var clear_item = new Gtk.MenuItem.with_label("Clear All Items");
		clear_item.activate.connect(() => {
			clear_all_items();
			context_menu.popdown();
			dropdown_menu.popdown();
		});
		context_menu.append(clear_item);
		context_menu.show_all();
	}

/**
 * @brief Copies the list of menu items to the clipboard.
 */
	private void copy_list_to_clipboard()
	{
		var clipboard = Gtk.Clipboard.get_default(Gdk.Display.get_default());
		clipboard.set_text(clipboard_text.str, -1);
	}

/**
 * @brief Clears all items from the dropdown menu.
 */
	private void clear_all_items()
	{
		foreach (var item in menu_items)
		{
			dropdown_menu.remove(item);
		}
		menu_items     = new List<Gtk.MenuItem>();
		last_menu_item = null;
		last_station   = null;
		last_title     = "";
		clipboard_text.truncate();
	}

/**
 * @brief Appends a station-title pair to the dropdown menu.
 * @param station The station to add.
 * @param title The title associated with the station.
 */
	public void append_station_title_pair(Model.Station station, string title)
	{
		if (station == last_station && title == last_title)
			return;
		if (station == last_station && "" == last_title && last_menu_item != null)
		{
			dropdown_menu.remove(last_menu_item);
			int pos = clipboard_text.str.index_of("\n", clipboard_text.str.index_of("\n") + 1) + 1;
			clipboard_text.erase(0, pos);
		}
		var label = station.name + "\n\t" + title;
		var item  = new Gtk.MenuItem.with_label(label);
		menu_items.append(item);

		item.button_press_event.connect((event) => {
			if (event.button == 1)   // Left click
			{
				item_station_selected_sig(station);
				dropdown_menu.popdown();
				return true;
			}
			else if (event.button == 3)   // Right click
			{
				context_menu.popup_at_pointer(event);
				return true;
			}
			return false;
		});

		item.show();
		dropdown_menu.prepend(item);
		last_menu_item = item;
		last_station   = station;
		last_title     = title;
		clipboard_text.prepend(label + "\n");
	}

/**
 * @brief Limits the width of the dropdown menu to 2/3 of the header bar width.
 */
	private void limit_dropdown_menu_width()
	{
		var header_bar = this.get_toplevel() as Gtk.HeaderBar;
		if (header_bar != null)
		{
			var max_width = header_bar.get_allocated_width() * 2 / 3;
			dropdown_menu.set_size_request(max_width, -1);
		}
	}
}
