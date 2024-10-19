/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */

/**
 * @class PreferencesPopover
 * @brief A popover widget for displaying and managing application preferences.
 *
 * This class extends Gtk.Popover and provides a user interface for various
 * application settings such as theme selection, autoplay, and tracking options.
 */
public class Tuner.PreferencesPopover : Gtk.Popover {

    /**
     * @brief Constructs the PreferencesPopover widget.
     *
     * This method sets up the layout and adds various preference options
     * to the popover menu.
     */
    construct {

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 10;
        menu_grid.margin_top = 10;
        menu_grid.margin_start = 5;
        menu_grid.margin_end = 5;
        menu_grid.row_spacing = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.attach (prefer_dark_theme(), 0, 0);
        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, 1, 3, 1);
        menu_grid.attach (autoplay_item(), 0, 2, 3, 1);
        menu_grid.attach (disable_tracking_item(), 0, 3, 3, 1);
        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, 4, 3, 1);
        menu_grid.attach (about_menuitem(), 0, 5, 3, 1);
        menu_grid.show_all ();

        this.add (menu_grid);
    }


    /**
     * @brief Creates and returns a Gtk.ModelButton for the "About" menu item.
     *
     * @return Gtk.ModelButton The configured "About" menu item.
     */
    private static Gtk.ModelButton about_menuitem ()
    {        
        var about_menuitem = new Gtk.ModelButton ();
        about_menuitem.text = _("About");
        about_menuitem.action_name = Window.ACTION_PREFIX + Window.ACTION_ABOUT;
        return about_menuitem;
    }
        
    /**
     * @brief Creates and returns a Gtk.ModelButton for the "Do not track" option.
     *
     * @return Gtk.ModelButton The configured "Do not track" menu item.
     */
    private static Gtk.ModelButton disable_tracking_item ()
    {              
        var disable_tracking_item = new Gtk.ModelButton ();
        disable_tracking_item.text = _("Do not track");
        disable_tracking_item.action_name = Window.ACTION_PREFIX + Window.ACTION_DISABLE_TRACKING;
        disable_tracking_item.tooltip_text = _("If enabled, we will not send usage info to radio-browser.org");

        return disable_tracking_item;
    }

    /**
     * @brief Creates and returns a Gtk.ModelButton for the "Auto-play last station" option.
     *
     * @return Gtk.ModelButton The configured "Auto-play last station" menu item.
     */
     private static Gtk.ModelButton autoplay_item ()
     {
         var autoplay_item = new Gtk.ModelButton ();
         autoplay_item.text = _("Auto-play last station");
         autoplay_item.action_name = Window.ACTION_PREFIX + Window.ACTION_ENABLE_AUTOPLAY;
         autoplay_item.tooltip_text = _("If enabled, when Tuner starts it will automatically start to play the last played station");
         return autoplay_item;
     }

    /**
     * @brief Creates and returns a Gtk.ModelButton for the "Prefer dark theme" option.
     *
     * @return Gtk.ModelButton The configured "Prefer dark theme" menu item.
     */
     private static Gtk.ModelButton prefer_dark_theme ()
     {
         var prefer_dark_theme = new Gtk.ModelButton ();
         prefer_dark_theme.text = _("Prefer dark theme");
         prefer_dark_theme.action_name = Window.ACTION_PREFIX + Window.ACTION_PREFER_DARK_MODE;
         prefer_dark_theme.tooltip_text = _("If enabled, when Tuner starts it will use the dark theme");
         return prefer_dark_theme;
     }
  
    /**
     * @brief Creates and returns a Gtk.Box containing the theme selection combo box.
     *
     * This method sets up a combo box for selecting the application theme
     * (System, Light, or Dark) and handles theme change events.
     *
     * @return Gtk.Box A box containing the theme selection combo box and label.
     */
    //  private static Gtk.Box theme_box () 
    //  {
    //      var theme_combo = new Gtk.ComboBoxText ();
    //      theme_combo.halign = Gtk.Align.CENTER;

    //      theme_combo.append(Application.Theme.SYSTEM.to_string(), _("Use System"));  
    //      theme_combo.append(Application.Theme.LIGHT.to_string(), _("Light mode"));
    //      theme_combo.append(Application.Theme.DARK.to_string(), _("Dark mode"));
    //      theme_combo.active_id = Application.instance.theme.to_string();
 
    //      theme_combo.changed.connect ((elem) => {
    //          warning(@"Theme changed: $(elem.active_id)");
    //          Application.instance.theme = Application.theme_from_string(elem.active_id);
    //      });

    //      var theme_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
    //      theme_box.pack_end (theme_combo, true, true, 5);
    //      theme_box.pack_end (new Gtk.Label(_("Theme")), false, false, 12);
    //      return theme_box;
    //  }

}
