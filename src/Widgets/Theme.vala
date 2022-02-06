/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

namespace Tuner {
    
public class Theme : Gtk.Widget
{
	private static GLib.Once<Theme> _instance;

	public static unowned Theme instance ()
	{
		return _instance.once (() => { return new Theme (); });
	}

	public bool is_theme_dark()
	{
		var settings = Gtk.Settings.get_default();
		var theme = Environment.get_variable("GTK_THEME");

		var dark = settings.gtk_application_prefer_dark_theme || (theme != null && theme.has_suffix(":dark"));

		if (!dark) {
			var stylecontext = get_style_context();
			Gdk.RGBA rgba;
			var background_set = stylecontext.lookup_color("theme_bg_color", out rgba);

			if (background_set && rgba.red + rgba.green + rgba.blue < 1.0)
			{
				dark = true;
			}
		}

		return dark;
	}
}

}