/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PreferencesPopover.vala
 */


 /**
 *
 * @brief Tuner preferences and selections.
 */
public class Tuner.PreferencesPopover : Gtk.Popover {

	construct {
		var about_menuitem = new Gtk.ModelButton ();
		about_menuitem.text        = _("About");
		about_menuitem.action_name = Window.ACTION_PREFIX + Window.ACTION_ABOUT;

        // Voting
        var disable_tracking_item = new Gtk.ModelButton ();
        disable_tracking_item.text = _("Do not track");
        disable_tracking_item.action_name = Window.ACTION_PREFIX + Window.ACTION_DISABLE_TRACKING;
        disable_tracking_item.tooltip_text = _("If enabled, we will not send usage info to radio-browser.org");

        //Theme
        var theme_combo = new Gtk.ComboBoxText ();
        theme_combo.append("system", _("Use System"));  
        theme_combo.append("light", _("Light mode"));
        theme_combo.append("dark", _("Dark mode"));
        theme_combo.halign = Gtk.Align.CENTER;
        theme_combo.active_id = Application.instance.settings.get_string("theme-mode");

		theme_combo.changed.connect ((elem) => {
			apply_theme_name(elem.active_id);
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

        // Export starred
        var export_starred = new Gtk.ModelButton ();
        export_starred.text = _("Export Starred Sations to Playlist");
        export_starred.button_press_event.connect (() =>
        {
           export_m3u8 ();
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

        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, vpos++, 4, 1);

        menu_grid.attach (export_starred, 0, vpos++, 4, 1);

        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, vpos++, 4, 1);
        menu_grid.attach (about_menuitem, 0, vpos++, 4, 1);
        menu_grid.show_all ();

        this.add (menu_grid);
    } // construct


    /**
    * @brief Export Starred Stations as a m3u playlist
    *
    *
    */
    public void export_m3u8()
    {
        try {
            string temp_file;
            GLib.FileUtils.open_tmp ("XXXXXX.starred.m3u8", out temp_file);
            GLib.FileUtils.set_contents(temp_file, Application._instance.window.store.export_m3u8 ());
    
        // Create the file chooser dialog for saving
        var dialog = new Gtk.FileChooserDialog(
            "Save File",
            null,
            Gtk.FileChooserAction.SAVE
        );

        // Add buttons to the dialog
        dialog.add_button("_Cancel", Gtk.ResponseType.CANCEL);
        dialog.add_button("_Save", Gtk.ResponseType.ACCEPT);
    
        // Suggest a default filename
        dialog.set_current_name("tuner-starred.m3u8");

        if (dialog.run() == Gtk.ResponseType.ACCEPT) 
        {
            string save_path = dialog.get_filename();
            // Copy the temp file to the chosen location
            var source_file = GLib.File.new_for_path(temp_file);
            var dest_file = GLib.File.new_for_path(save_path);
            source_file.copy(dest_file, GLib.FileCopyFlags.OVERWRITE);  // Overwrite
        }

        dialog.destroy();

        } catch (GLib.Error e) {
            warning("Error: $(e.message)");
        }
    } // export_m3u8
} // PreferencesPopover
