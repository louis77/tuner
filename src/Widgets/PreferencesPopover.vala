/*
* Copyright (c) 2020-2021 Louis Brauer <louis@brauer.family>
*
* This file is part of Tuner.
*
* Tuner is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Tuner is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Tuner.  If not, see <http://www.gnu.org/licenses/>.
*
*/

public class Tuner.PreferencesPopover : Gtk.Popover {

    construct {
        var about_menuitem = new Gtk.ModelButton ();
        about_menuitem.text = _("About");
        about_menuitem.action_name = Window.ACTION_PREFIX + Window.ACTION_ABOUT;

        var disable_tracking_item = new Gtk.ModelButton ();
        disable_tracking_item.text = _("Do not track");
        disable_tracking_item.action_name = Window.ACTION_PREFIX + Window.ACTION_DISABLE_TRACKING;
        disable_tracking_item.tooltip_text = _("If enabled, we will not send usage info to radio-browser.org");

        var gtk_settings = Gtk.Settings.get_default ();
        var mode_switch = new Granite.ModeSwitch.from_icon_name (
            "display-brightness-symbolic",
            "weather-clear-night-symbolic"
        );
        mode_switch.primary_icon_tooltip_text = _("Light mode");
        mode_switch.secondary_icon_tooltip_text = _("Dark mode");
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.bind_property ("active", gtk_settings, "gtk-application-prefer-dark-theme", GLib.BindingFlags.BIDIRECTIONAL);
        mode_switch.bind_property ("active", this, "enable-dark-mode", GLib.BindingFlags.BIDIRECTIONAL);
        mode_switch.active = Application.instance.enable_dark_mode;

        var autoplay_item = new Gtk.ModelButton ();
        autoplay_item.text = _("Auto-play last station");
        autoplay_item.action_name = Window.ACTION_PREFIX + Window.ACTION_ENABLE_AUTOPLAY;
        autoplay_item.tooltip_text = _("If enabled, when Tuner starts it will automatically start to play the last played station");

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.margin_top = 5;
        menu_grid.margin_start = 3;
        menu_grid.margin_end = 3;
        menu_grid.row_spacing = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.attach (mode_switch, 1, 0);
        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, 1, 3, 1);
        menu_grid.attach (autoplay_item, 0, 2, 3, 1);
        menu_grid.attach (disable_tracking_item, 0, 3, 3, 1);
        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, 4, 3, 1);
        menu_grid.attach (about_menuitem, 0, 5, 3, 1);
        menu_grid.show_all ();

        this.add (menu_grid);
    }



}