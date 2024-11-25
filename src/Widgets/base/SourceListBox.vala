/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */
/**
 * @file SourceListBox.vala
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
using Granite.Widgets;

/**
 * @class SourceListBox
 * @brief A custom Gtk.Box widget for displaying content with a header and action button.
 *
 * The ContentBox class is a versatile widget used to present various types of content
 * within the Tuner application. It features a header with an optional icon and action
 * button, and a content area that can display different views based on the current state.
 *
 * @extends Gtk.Box
 */
public class Tuner.SourceListBox : Gtk.Box {
    
    //  public string ident { get; construct; }

   // public StationSet data { get; construct; }

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

    // -----------------------------------
    
    private SourceList.Item _list_item;
    private ThemedIcon _icon;
    private Gtk.Box _header = base_header();
    private Gtk.Box _content = base_content();
    private AbstractContentList _content_list;
    private Gtk.Stack _substack = new Gtk.Stack ();
    private StationSet? _data;


    
    /**
     * @brief Constructs a new ContentBox instance.
     *
     * @param icon The optional icon to display in the header.
     * @param title The title text for the header.
     * @param subtitle An optional subtitle to display below the header.
     * @param action_icon_name The name of the icon for the action button.
     * @param action_tooltip_text The tooltip text for the action button.
     */
    private SourceListBox (
        Gtk.Stack stack,
        SourceList source_list,
        SourceList.ExpandableItem category,
        string name,
        string icon,
        string title,
        string subtitle,
        StationSet? data,
        string? action_tooltip_text,
        string? action_icon_name,
        bool enable_count) 
    {
        Object (
            name:name,
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );

        _data = data;

        _icon = new ThemedIcon (icon);
        _list_item = new Granite.Widgets.SourceList.Item (title);
        _list_item.icon = _icon;
        _list_item.set_data<string> ("stack_child", name);  

        var alert = new AlertView (_("Nothing here"), _("Something went wrong loading radio stations data from radio-browser.info. Please try again later."), "dialog-warning");
        //  /*
        //  alert.show_action ("Try again");
        //  alert.action_activated.connect (() => {
        //      realize ();
        //  });
        //  */

        _substack.add_named (alert, "alert");

        var no_results = new Granite.Widgets.AlertView (_("No stations found"), _("Please try a different search term."), "dialog-warning");
        _substack.add_named (no_results, "nothing-found");

        _header.pack_start (new HeaderLabel (subtitle, 20, 20 ), false, false);

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

        pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);

        _substack.add_named (content_scroller(_content), "content");
        add (_substack);
        
        show.connect (() => {   
            _substack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);            
        });

        map.connect (() => {
            source_list.selected = _list_item;
        });

        //  if (enable_count) {
        //      content_changed_sig.connect (() => {
        //          if (content == null) return;
        //          var count = content.item_count;
        //          category.badge = count.to_string ();
        //      });
        //  }
        category.add (_list_item);  
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


    public ArrayList<Model.Station>? next_page () throws SourceError
    {
        return _data.next_page();
    }

    /**
     * @brief Displays the alert view in the content area.
     */
    public void show_alert () {
        _substack.set_visible_child_full ("alert", Gtk.StackTransitionType.NONE);
    }


    /**
     * @brief Displays the "nothing found" view in the content area.
     */
    public void show_nothing_found () {
        _substack.set_visible_child_full ("nothing-found", Gtk.StackTransitionType.NONE);
    }
    

    /**
     * @property content
     * @brief Gets or sets the content list displayed in the ContentBox.
     *
     * When setting this property, it replaces the current content with the new
     * AbstractContentList and emits the content_changed_sig signal.
     */
    public AbstractContentList content { 
        set {
        
            foreach (var child in _content.get_children ()) { child.destroy (); }

            _substack.set_visible_child_full ("content", Gtk.StackTransitionType.NONE);
            _content_list = value;
            _content.add (_content_list);
            _content.show_all ();
            content_changed_sig ();
        }

        get {
            return _content_list; 
        }
    } // SourceListBox

    // -----------------------------------------------

    
    private static Gtk.Box base_header()
    {
        var header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header.homogeneous = false;
        return header;
    }    

    private static Gtk.Box base_content()
    {
        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content.get_style_context ().add_class ("color-light");
        content.valign = Gtk.Align.START;
        content.get_style_context().add_class("welcome");
        return content;
    }

    private static Gtk.ScrolledWindow content_scroller(Gtk.Box content)
    {
        var scroller = new Gtk.ScrolledWindow (null, null);
        scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroller.add (content);
        scroller.propagate_natural_height = true;        
        return scroller;
    }

    // --------------------------------------------------


    public static SourceListBox create(
        Gtk.Stack stack,
        SourceList source_list,
        SourceList.ExpandableItem category,
        string name,
        string icon,
        string title,
        string subtitle,
        StationSet? data = null,
        string? action_tooltip_text = null,
        string? action_icon_name = null) 
        {
            var slb = new SourceListBox(
                 stack,
                 source_list,
                 category,
                 name,
                 icon,
                 title,
                 subtitle,
                 data,
                action_tooltip_text,
                action_icon_name,
                false);

            stack.add_named (slb, name);

            return slb;
        }    

    public static SourceListBox create_count(
        Gtk.Stack stack,
        SourceList source_list,
        SourceList.ExpandableItem category,
        string name,
        string icon,
        string title,
        string subtitle,
        StationSet? data = null,
        string? action_tooltip_text = null,
        string? action_icon_name = null) 
        {
            var slb = new SourceListBox(
                    stack,
                    source_list,
                    category,
                    name,
                    icon,
                    title,
                    subtitle,
                    data,
                action_tooltip_text,
                action_icon_name,
                true);

                slb.content_changed_sig.connect (() => {
                if (slb.content == null) return;
                var count = slb.content.item_count;
                category.badge = count.to_string ();
            });
            

            stack.add_named (slb, name);

            return slb;
        }

}
