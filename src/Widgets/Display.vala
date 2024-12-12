/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file Display.vala
 *
 * @brief Defines the below-headerbar display of stations in the Tuner application.
 *
 * This file contains the Display class, which implements various
 * features such as a source list, content stack that display and manage Station
 * settings and handles user actions like station selection.
 *
 * @see Tuner.Application
 * @see Tuner.DirectoryController
 */


using Gee;
using Granite.Widgets;


/**
 * @brief Display class for managing organization and presentation of genres and thier stations
 *
 * Display should be initialized and re-initialized by its owning class
 */
public class Tuner.Display : Gtk.Paned {

    private const int EXPLORE_CATEGORIES = 5;    // How many explore categories to display 


    public signal void selection_changed_sig (Model.Station station);

    public signal void favourites_changed_sig ();

    public signal void refresh_starred_stations_sig ();

    public signal void searched_for_sig(string text);

    public signal void search_focused_sig();


    public Gtk.Stack stack { get; construct; }
    public SourceList source_list { get; construct; }
    public DirectoryController directory { get; construct; }

    /*
        Display Assets
    */

    private SourceList.ExpandableItem _selections_category = new SourceList.ExpandableItem (_("Selections"));
    private SourceList.ExpandableItem _library_category = new SourceList.ExpandableItem (_("Library"));
    private SourceList.ExpandableItem _saved_searches_category = new SourceList.ExpandableItem (_("Saved Searches"));
    private SourceList.ExpandableItem _explore_category = new SourceList.ExpandableItem (_("Explore")); 
    private SourceList.ExpandableItem _genres_category = new SourceList.ExpandableItem (_("Genres"));
    private SourceList.ExpandableItem _subgenres_category = new SourceList.ExpandableItem (_("Sub Genres"));
    private SourceList.ExpandableItem _eras_category = new SourceList.ExpandableItem (_("Eras"));
    private SourceList.ExpandableItem _talk_category = new SourceList.ExpandableItem (_("Talk, News, Sport"));


    private bool first_activation = true;  // display has not been activated before
    private bool active = false;  // display is active

    //  private signal void refresh_saved_searches_sig (bool add, string search_text);



    /* --------------------------------------------------------
    
        Public Methods

       ---------------------------------------------------------- */

    public Display(DirectoryController directory)
    {
        Object(
            directory : directory
        );
    } // Display


    /**
    * Updates the state of the display
    */
    public void update_state( bool activate)
    {
        if ( active && !activate )
        /* Present Offline look */
        {
            active = false;
            return;
        }

        if ( !active && activate )
        // Move from not active to active
        {
            initialize();

            if (first_activation)
            // One time set up - do post initialization
            {
                //  TBD
                first_activation = false;
            }
            active = true;
            show_all();   
        }
    } // update_state


    /**
     * @brief Loads search stations based on the provided text and updates the content box.
     *
     * Async since 1.5.5 so that UI is responsive during long searches
     * @param searchText The text to search for stations.
     * @param search_box The ContentBox to update with the search results.
     */
     private async void load_station_search_results(string searchText, SourceListBox search_box) {

        debug(@"Searching for: $(searchText)");       
        var station_set = _directory.load_search_stations(searchText, 100);
        debug(@"Search done");

        try {
            var stations = station_set.next_page();
            debug(@"Search Next done");
            if (stations == null || stations.size == 0) {
                search_box.show_nothing_found();
            } else {
                debug(@"Search found $(stations.size) stations");
                var _slist = new StationList.with_stations(stations);
                hookup(_slist);
                search_box.content = _slist;
                search_box.parameter = searchText;
            }
        } catch (SourceError e) {
            search_box.show_alert();
        }
    } // load_search_stations


    /* --------------------------------------------------------
    
        Private Methods

       ---------------------------------------------------------- */


    /* Construct */
    construct { 

        var granite_settings = Granite.Settings.get_default ();

        var overlay = new Gtk.Overlay ();   // Use an overlay to allow for background image below the stack
        var background = new Gtk.Image.from_resource("/com/github/louis77/tuner/icons/background");
        background.opacity = 0.1;
        overlay.add (background);

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        overlay.add_overlay(stack);

        // ---------------------------------------------------------------------------

        // Set up the LHS directory structure

        _selections_category.collapsible = false;
        _selections_category.expanded = true;

        _library_category.collapsible = false;
        _library_category.expanded = false;

        _saved_searches_category.collapsible = true;
        _saved_searches_category.expanded = false;

        _explore_category.collapsible = true;
        _explore_category.expanded = false;

        _genres_category.collapsible = true;
        _genres_category.expanded = false;

        _subgenres_category.collapsible = true;
        _subgenres_category.expanded = false;

        _eras_category.collapsible = true;
        _eras_category.expanded = false;

        _talk_category.collapsible = true;
        _talk_category.expanded = false;

        source_list = new SourceList();
        
        source_list.root.add (_selections_category);
        source_list.root.add (_library_category);
        source_list.root.add (_explore_category);
        source_list.root.add (_genres_category);
        source_list.root.add (_subgenres_category);
        source_list.root.add (_eras_category);
        source_list.root.add (_talk_category);

        source_list.ellipsize_mode = Pango.EllipsizeMode.NONE;
        source_list.item_selected.connect  ((item) => {
            var selected_item = item.get_data<string> ("stack_child");
            stack.visible_child_name = selected_item;
        });

        // ---------------------------------------------------------------------------

        pack1 (source_list, false, false);
        pack2 (overlay, true, false);
                    
    } // construct


    /* --------------------------------------------------------
    
        Methods

        ----------------------------------------------------------
    */

    private void initialize()
    {
        _directory.load (); // Initialize the DirectoryController

        /* Initialize the directory contents */

        /* ---------------------------------------------------------------------------
            Discover
        */

        var discover = SourceListBox.create ( stack
            , source_list
            ,  _selections_category
            , "discover"
            , "face-smile"
            , "Discover"
            , "Stations to Explore"
            ,_directory.load_random_stations(20)
            , "Discover more stations"
            , "media-playlist-shuffle-symbolic");
            
        discover.realize.connect (() => {
            if ( app().is_offline ) return;
            try {
                var slist = new StationList.with_stations (discover.next_page ());
                hookup(slist);
                discover.content = slist;
            } catch (SourceError e) {
                discover.show_alert ();
            }
        });
        
        discover.action_activated_sig.connect (() => {
            if ( app().is_offline ) return;
            try {
                var slist = new StationList.with_stations (discover.next_page ());
                hookup(slist);
                discover.content = slist;
            } catch (SourceError e) {
                discover.show_alert ();
            }
        });


        /* ---------------------------------------------------------------------------
            Trending
        */
        create_category_specific
            ( stack
                , source_list
                , _selections_category
                , "trending"
                , "playlist-queue"
                , "Trending"
                , "Trending in the last 24 hours"
                ,_directory.load_trending_stations(40) 
            );

        /* ---------------------------------------------------------------------------
            Popular
        */

        create_category_specific
            ( stack
                , source_list
                , _selections_category
                , "popular"
                , "playlist-similar"
                , "Popular"
                , "Most-listened over 24 hours"
                ,_directory.load_popular_stations(40)
            );
    

        // ---------------------------------------------------------------------------

        jukebox(_selections_category);

        // ---------------------------------------------------------------------------
        // Country-specific stations list
        
        //  var item4 = new Granite.Widgets.SourceList.Item (_("Your Country"));
        //  item4.icon = new ThemedIcon ("emblem-web");
        //  ContentBox c_country;
        //  c_country = create_content_box ("my-country", item4,
        //                      _("Your Country"), null, null,
        //                      stack, source_list, true);
        //  var c_slist = new StationList ();
        //  c_slist.selection_changed.connect (handle_station_click);
        //  c_slist.favourites_changed.connect (handle_favourites_changed);

        // ---------------------------------------------------------------------------

        /* ---------------------------------------------------------------------------
            Starred
        */

        var starred = create_category_predefined
            (   stack
                , source_list
                , _library_category
                , "starred"
                , "starred"
                , _("Starred by You")
                , _("Starred by You")
                ,_directory.get_starred() 
            );

            starred.badge ( @"$(starred.item_count)\t");
            starred.notify["item-count"].connect (()=> {
                starred.badge ( @"$(starred.item_count)\t");
            });


        // ---------------------------------------------------------------------------
        // Search Results Box
        

        var search_results = SourceListBox.create 
        ( stack
        , source_list
        , _library_category
        , "searched"
        , "folder-saved-search"
        , _("Recent Search")
        , _("Search Results")
        , null
        , _("Save this search")
        , "starred-symbolic");

        search_results.tooltip_button.sensitive = false;

        // Add saved search from star press
        search_results.action_activated_sig.connect (() => {
            if ( app().is_offline ) return;                 
            search_results.tooltip_button.sensitive = false;    
            var new_saved_search  = add_saved_search( search_results.parameter, _directory.add_saved_search (search_results.parameter));
            //new_saved_search.list(search_results.content);
            try {
                var slist = new StationList.with_stations (new_saved_search.next_page ());
                hookup(slist);
                new_saved_search.content = slist;
            } catch (SourceError e) {
                new_saved_search.show_alert ();
            }
            search_results.selection_received.connect(() =>
            {
                warning(@"Selected");
            });
            source_list.selected = source_list.get_last_child (_saved_searches_category);
        });

        // ---------------------------------------------------------------------------
        // Saved Searches


        // Add saved searches to category from Directory
        var saved_searches = _directory.load_saved_searches();
        foreach( var search_text in saved_searches.keys)
        {
           add_saved_search( search_text, saved_searches.get (search_text));
        }
        _saved_searches_category.icon = new ThemedIcon ("library-music");
        _library_category.add (_saved_searches_category);   // Added as last item of library category

        // ---------------------------------------------------------------------------

        // Explore Categories category
        // Get random categories and stations in them
        if ( app().is_online)
        {
            uint explore = 0;
            foreach (var tag in _directory.load_random_genres(EXPLORE_CATEGORIES))
            {
            if ( Model.Genre.in_genre (tag.name)) break;  // Predefined genre, ignore
                create_category_specific( stack, source_list, _explore_category
                    , @"$(explore++)"   // tag names can have charaters that are not suitable for name
                    , "playlist-symbolic"
                    , tag.name
                    , tag.name
                    , _directory.load_by_tag (tag.name));
            }
        }

        // ---------------------------------------------------------------------------

        // Genre Boxes
        create_category_genre( stack, source_list, _genres_category, _directory,   Model.Genre.GENRES );

        // Sub Genre Boxes
        create_category_genre( stack, source_list, _subgenres_category, _directory,   Model.Genre.SUBGENRES );

        // Eras Boxes
        create_category_genre( stack, source_list, _eras_category,   _directory, Model.Genre.ERAS );
    
        // Talk Boxes
        create_category_genre( stack, source_list, _talk_category, _directory,   Model.Genre.TALK );
    
        // --------------------------------------------------------------------


        refresh_starred_stations_sig.connect ( () => 
        //
        {
            if ( app().is_offline ) return;
            var _slist = new StationList.with_stations (_directory.get_starred ());
            hookup(_slist);
            starred.content = _slist;
        });


        search_focused_sig.connect (() => 
        // Show searched stack when cursor hits search text area
        {
            stack.visible_child_name = "searched";
        });


        searched_for_sig.connect ( (text) => 
        // process the searched text, stripping it, and sensitizing the save 
        // search star depending on if the search is already saved
        {
            var search = text.strip ();
            if ( search.length > 0 ) {
                load_station_search_results.begin(search, search_results);
                if ( stack.get_child_by_name (@">$search") == null )  // Search names are prefixed with >
                {
                    search_results.tooltip_button.sensitive = true;
                    return;
                }
            }
            else
            {
                search_results.show_nothing_found ();
            }
            search_results.tooltip_button.sensitive = false;
        });

        source_list.selected = source_list.get_first_child (_selections_category);

    } // initialize


    /* -------------------------------------------------

        Helpers

        Shortcuts to configure the source_list and stack

       -------------------------------------------------
    */

    /*
     */
    private void jukebox(SourceList.ExpandableItem category)
    {
        SourceList.Item item = new SourceList.Item(_("Jukebox"));
        item.icon = new ThemedIcon("audio-speakers");
        var station = _directory.load_random_stations(1);
        item.activated.connect(() =>
        {
            try {
                selection_changed_sig(station.next_page().to_array()[0]);
            } 
            catch (SourceError e)
            {
                warning(_(@"Could not get random station: $(e.message)"));
            }
        });
        category.add(item);
    } // jukebox


    private void hookup(StationList slist)
    {
        slist.selection_changed_sig.connect((station) =>
        {
            selection_changed_sig(station);
        });

        slist.favourites_changed_sig.connect(() =>
        {
            refresh_starred_stations_sig();
        });
    } // hookup


    private SourceListBox add_saved_search(string search, StationSet station_set, StationList? content = null)//StationSet station_set)
    {
        var saved_search = create_category_specific 
            ( stack
            , source_list
            , _saved_searches_category
            , @">$search"
            , "playlist-symbolic"
            , search
            , _(@"Saved Search :  $search")
            , station_set
            , _("Remove this saved search")
            , "non-starred-symbolic"
            );

        //saved_search.show_all();
        if ( content != null ) { 
            saved_search.content = content; 
        }

        //saved_search.content.show();

        saved_search.action_activated_sig.connect (() => {
            if ( app().is_offline ) return;
            _directory.remove_saved_search (search);
            saved_search.delist ();
        });

        return saved_search;
    } // refresh_saved_searches
    

    private SourceListBox create_category_predefined
        ( Gtk.Stack stack
        , Granite.Widgets.SourceList source_list
        , Granite.Widgets.SourceList.ExpandableItem category
        , string name
        , string icon
        , string title
        , string subtitle
        , Collection<Model.Station>? stations
        )
    {
        var genre = SourceListBox.create 
            ( stack
            , source_list
            , category
            , name
            , icon
            , title
            , subtitle 
            );

        if (stations != null)
        {    
            var slist = new StationList.with_stations (stations);
            hookup(slist);
            genre.content = slist;
        }

        return genre;
    
    } // create_category_predefined


    private SourceListBox create_category_specific 
        ( Gtk.Stack stack
        , Granite.Widgets.SourceList source_list
        , Granite.Widgets.SourceList.ExpandableItem category
        , string name
        , string icon
        , string title
        , string subtitle
        , StationSet station_set
        , string? action_tooltip_text = null
        , string? action_icon_name = null
        )
    {
        var genre = SourceListBox.create 
            ( stack
            , source_list
            , category
            , name
            , icon
            , title
            , subtitle 
            , station_set
            , action_tooltip_text
            , action_icon_name
            );

        genre.realize.connect (() => {
            if ( app().is_offline ) return;
            try {
                var slist = new StationList.with_stations (genre.next_page ());
                hookup(slist);
                genre.content = slist;
            } catch (SourceError e) {
                genre.show_alert ();
            }
        });        
        return genre;
    } // create_category_specific


    private void create_category_genre
        ( Gtk.Stack stack
        , Granite.Widgets.SourceList source_list
        , Granite.Widgets.SourceList.ExpandableItem category
        , DirectoryController directory
        , string[] genres
        )
    {
        foreach (var genre in genres ) {
            create_category_specific(stack
                , source_list
                , category
                , genre
                , "playlist-symbolic"
                , genre
                , genre
                , directory.load_by_tag (genre.down ()));
        }
    } // create_category_genre
}
