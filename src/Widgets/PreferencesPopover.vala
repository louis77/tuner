/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PreferencesPopover.vala
 *
 * @brief Tuner preferences and selections.
 */

public class Tuner.PreferencesPopover : Gtk.Popover {

    construct {
        var about_menuitem = new Gtk.ModelButton ();
        about_menuitem.text = _("About");
        about_menuitem.action_name = Window.ACTION_PREFIX + Window.ACTION_ABOUT;

        // Voting
        var disable_tracking_item = new Gtk.ModelButton ();
        disable_tracking_item.text = _("Do not participate in Station voting");
        disable_tracking_item.action_name = Window.ACTION_PREFIX + Window.ACTION_DISABLE_TRACKING;
        disable_tracking_item.tooltip_text = _("If checked, your starred and streamed stations will not be fed back to the Station index popularity vote, and will not be used to calculate popular and trending stations");

        //Theme
        var theme_combo = new Gtk.ComboBoxText ();
        theme_combo.append(THEME.SYSTEM.get_name (), _("Use System"));  
        theme_combo.append(THEME.LIGHT.get_name (), _("Light mode"));
        theme_combo.append(THEME.DARK.get_name (), _("Dark mode"));
        theme_combo.halign = Gtk.Align.CENTER;
        theme_combo.active_id = app().settings.theme_mode;   // Initial state from settings

        theme_combo.changed.connect ((elem) => {
            apply_theme(elem.active_id);
            app().settings.theme_mode = elem.active_id;
        });

        var theme_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        theme_box.pack_end (theme_combo, true, true, 5);
        theme_box.pack_end (new Gtk.Label(_("Theme")), false, false, 12);

        // Autoplay
        var autoplay_item = new Gtk.ModelButton ();
        autoplay_item.text = _("Auto-play last station on startup");
        autoplay_item.action_name = Window.ACTION_PREFIX + Window.ACTION_ENABLE_AUTOPLAY;
        autoplay_item.tooltip_text = _("If enabled, when Tuner starts it will automatically start to play the last played station");


        // Play Display 
        var stream_info = new Gtk.ModelButton ();
        stream_info.text = _("Show stream info when playing");
        stream_info.action_name = Window.ACTION_PREFIX + Window.ACTION_STREAM_INFO;
        stream_info.tooltip_text = _("Cycle through the metadata from the playing stream");


        var stream_info_fast = new Gtk.ModelButton ();
        stream_info_fast.text = _("Faster cycling through stream info");
        stream_info_fast.action_name = Window.ACTION_PREFIX + Window.ACTION_STREAM_INFO_FAST;
        stream_info_fast.tooltip_text = _("Fast cycle through the metadata from the playing stream if show stream info is enabled");
        

        // Export starred
        var export_starred = new Gtk.ModelButton ();
        export_starred.text = _("Export Starred Sations");
        export_starred.button_press_event.connect (() =>
        {
           app().stars.export_m3u8 ();
        });

        // Layout
        uint8 vpos = 0;
        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 10;
        menu_grid.margin_top = 10;
        menu_grid.margin_start = 5;
        menu_grid.margin_end = 5;
        menu_grid.row_spacing = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;

        menu_grid.attach (theme_box, 0, vpos++);

        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, vpos++, 4, 1);

        menu_grid.attach (autoplay_item, 0, vpos++, 4, 1);
        menu_grid.attach (disable_tracking_item, 0, vpos++, 4, 1);
        menu_grid.attach (stream_info, 0, vpos++, 4, 1);
        menu_grid.attach (stream_info_fast, 0, vpos++, 4, 1);

        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, vpos++, 4, 1);

        menu_grid.attach (export_starred, 0, vpos++, 4, 1);

        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, vpos++, 4, 1);
        menu_grid.attach (about_menuitem, 0, vpos++, 4, 1);
        menu_grid.show_all ();

        this.add (menu_grid);
    }



}