/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */
/**
 * @file ContentBox.vala
 * @brief Defines the ContentBox widget for displaying content with a header and action button.
 *
 * This file contains the implementation of the ContentBox class, which is a custom
 * Gtk.Box widget used to display content with a header, optional icon, and an
 * optional action button. It provides a flexible layout for presenting various
 * types of content within the Tuner application.
 *
 * @namespace Tuner
 * @class ContentBox
 * @extends Gtk.Box
 */

using Gee;

/**
 * @class ContentBox
 * @brief A custom Gtk.Box widget for displaying content with a header and action button.
 *
 * The ContentBox class is a versatile widget used to present various types of content
 * within the Tuner application. It features a header with an optional icon and action
 * button, and a content area that can display different views based on the current state.
 *
 * @extends Gtk.Box
 */
public class Tuner.ContentBox : Gtk.Box {

    /**
     * @property header_label
     * @brief The label displayed in the header of the ContentBox.
     */
    public HeaderLabel header_label;

    /**
     * @signal action_activated_sig
     * @brief Emitted when the action button is clicked.
     */
    public signal void action_activated_sig ();

    /**
     * @signal content_changed_sig
     * @brief Emitted when the content of the ContentBox is changed.
     */
    public signal void content_changed_sig ();


    private Gtk.Box _header;
    private Gtk.Box _content;
    private ContentList _content_list;
    private Gtk.Stack _stack;

    
    /**
     * @brief Constructs a new ContentBox instance.
     *
     * @param icon The optional icon to display in the header.
     * @param title The title text for the header.
     * @param subtitle An optional subtitle to display below the header.
     * @param action_icon_name The name of the icon for the action button.
     * @param action_tooltip_text The tooltip text for the action button.
     */
    public ContentBox (Gtk.Image? icon,
                       string title,
                       string? subtitle,
                       string? action_icon_name,
                       string? action_tooltip_text) 
    {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );

        _stack = new Gtk.Stack ();

        var alert = new Granite.Widgets.AlertView (_("Nothing here"), _("Something went wrong loading radio stations data from radio-browser.info. Please try again later."), "dialog-warning");
        /*
        alert.show_action ("Try again");
        alert.action_activated.connect (() => {
            realize ();
        });
        */

        _stack.add_named (alert, "alert");

        var no_results = new Granite.Widgets.AlertView (_("No stations found"), _("Please try a different search term."), "dialog-warning");
        _stack.add_named (no_results, "nothing-found");

        _header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        _header.homogeneous = false;

        if (icon != null) {
            _header.pack_start (icon, false, false, 20);
        }

        //  header_label = new HeaderLabel (title);
        //  header_label.xpad = 20;
        //  header_label.ypad = 20;
        //  _header.pack_start (header_label, false, false);
        _header.pack_start (new HeaderLabel (title, 20, 20 ), false, false);

        if (action_icon_name != null && action_tooltip_text != null) {
            var shuffle_button = new Gtk.Button.from_icon_name (
                action_icon_name,
                Gtk.IconSize.LARGE_TOOLBAR
            );
            shuffle_button.valign = Gtk.Align.CENTER;
            shuffle_button.tooltip_text = action_tooltip_text;
            shuffle_button.clicked.connect (() => { action_activated_sig (); });
            _header.pack_start (shuffle_button, false, false);            
        }

        pack_start (_header, false, false);

        if (subtitle != null) {
            var subtitle_label = new Gtk.Label (subtitle);
            pack_start (subtitle_label);    
        }

        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);

        _content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        _content.get_style_context ().add_class ("color-light");
        _content.valign = Gtk.Align.START;
        _content.get_style_context().add_class("welcome");

        var scroller = new Gtk.ScrolledWindow (null, null);
        scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroller.add (_content);
        scroller.propagate_natural_height = true;

        _stack.add_named (scroller, "content");
        add (_stack);
        
        show.connect (() => {   
            _stack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);            
        });
    } // ContentBox

       
    /**
     * @brief Initializes the ContentBox instance.
     *
     * This method is called automatically by the Vala compiler and sets up
     * the initial style context for the widget.
     */
     construct {
        get_style_context ().add_class ("color-dark");
    }


    /**
     * @brief Displays the alert view in the content area.
     */
    public void show_alert () {
        _stack.set_visible_child_full ("alert", Gtk.StackTransitionType.NONE);
    }


    /**
     * @brief Displays the "nothing found" view in the content area.
     */
    public void show_nothing_found () {
        _stack.set_visible_child_full ("nothing-found", Gtk.StackTransitionType.NONE);
    }
    

    /**
     * @property content
     * @brief Gets or sets the content list displayed in the ContentBox.
     *
     * When setting this property, it replaces the current content with the new
     * AbstractContentList and emits the content_changed_sig signal.
     */
    public ContentList content { 
        set {
        
            foreach (var child in _content.get_children ()) { child.destroy (); }

            _stack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);
            _content_list = value;
            _content.add (_content_list);
            _content.show_all ();
            content_changed_sig ();
        }

        get {
            return _content_list; 
        }
    }



}
