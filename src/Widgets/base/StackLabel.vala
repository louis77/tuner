/*
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family> 
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/**
 * @class StackLabel
 * @brief A custom label widget for stack headers.
 *
 * This class extends Gtk.Label to create a specialized label
 * for use as stack headers in the application.
 *
 * @extends Gtk.Label
 */
public class Tuner.StackLabel : Gtk.Label
{

	public StackLabel (string label, int xpad = 0, int ypad = 0 )
	{
		Object (
			label: label,
			xpad: xpad,
			ypad: ypad
			);
	}

	construct {
		halign = Gtk.Align.START;
		xalign = 0;
		get_style_context ().add_class ("stack-label");
	}

}
