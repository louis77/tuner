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
 * This file contains the Display class, which implements visual elements for
 * features such as a source list, content stack that display and manage Station
 * settings and handles user actions like station selection.
 *
 * @since 2.0.0
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
public class Tuner.Display : Gtk.Paned, StationListHookup {

	private const string BACKGROUND_TUNER                               = "/io/github/louis77/tuner/icons/background-tuner";
	private const string BACKGROUND_JUKEBOX                             = "/io/github/louis77/tuner/icons/background-jukebox";
	private const int EXPLORE_CATEGORIES                                = 5;     // How many explore categories to display
	private const double BACKGROUND_OPACITY                             = 0.15;
	private const int BACKGROUND_TRANSITION_TIME_MS                     = 1500;
	private const Gtk.RevealerTransitionType BACKGROUND_TRANSITION_TYPE = Gtk.RevealerTransitionType.CROSSFADE;


    /**
     * @brief Signal emitted when a station is clicked.
     * @param station The clicked station.
     */
    public signal void station_clicked_sig (Model.Station station);


    /**
     * @brief Signal emitted when the favourites list changes.
     */
    public signal void favourites_changed_sig ();


    /**
     * @brief Signal emitted to refresh starred stations.
     */
    public signal void refresh_starred_stations_sig ();


    /**
     * @brief Signal emitted when a search is performed.
     * @param text The search text.
     */
    public signal void searched_for_sig(string text);


    /**
     * @brief Signal emitted when the search is focused.
     */
     public signal void search_focused_sig();


    /**
     * @property stack
     * @brief The stack widget for managing different views.
     */
    public Gtk.Stack stack { get; construct; }


    /**
     * @property source_list
     * @brief The source list widget for displaying categories.
     */
    public SourceList source_list { get; construct; }


    /**
     * @property directory
     * @brief The directory controller for managing station data.
     */
    public DirectoryController directory { get; construct; }


    /*
        Display Assets
    */

	private SourceList.ExpandableItem _selections_category     = new SourceList.ExpandableItem (_("Selections"));
	private SourceList.ExpandableItem _library_category        = new SourceList.ExpandableItem (_("Library"));
	private SourceList.ExpandableItem _saved_searches_category = new SourceList.ExpandableItem (_("Saved Searches"));
	private SourceList.ExpandableItem _explore_category        = new SourceList.ExpandableItem (_("Explore"));
	private SourceList.ExpandableItem _genres_category         = new SourceList.ExpandableItem (_("Genres"));
	private SourceList.ExpandableItem _subgenres_category      = new SourceList.ExpandableItem (_("Sub Genres"));
	private SourceList.ExpandableItem _eras_category           = new SourceList.ExpandableItem (_("Eras"));
	private SourceList.ExpandableItem _talk_category           = new SourceList.ExpandableItem (_("Talk, News, Sport"));


	private bool _first_activation           = true;     // display has not been activated before
	private bool _active                     = false;     // display is active
	private bool _shuffle                    = false;     // Shuffle mode
	private Gtk.Revealer _background_tuner   = new Gtk.Revealer();     // Background image
	private Gtk.Revealer _background_jukebox = new Gtk.Revealer();      // Background image
	private Gtk.Overlay _overlay             = new Gtk.Overlay ();
	private StationSet jukebox_station_set;      // Jukebox station set
	private SearchController _search_controller;      // Search controller



    /* --------------------------------------------------------
    
        Public Methods

       ---------------------------------------------------------- */

    /**
     * @brief Constructs a new Display instance.
     * @param directory The directory controller to use.
     */
    public Display(DirectoryController directory)
    {
        Object(
            directory : directory,
            source_list : new SourceList(),
            stack : new Gtk.Stack ()
        );

		jukebox_station_set = _directory.load_random_stations(1);
		app().player.shuffle_requested_sig.connect(() =>
		{
			if (_shuffle)
				jukebox_shuffle.begin();
		});

		var tuner = new Gtk.Image.from_resource (BACKGROUND_TUNER);
		tuner.opacity                         = BACKGROUND_OPACITY;
		_background_tuner.transition_duration = BACKGROUND_TRANSITION_TIME_MS;
		_background_tuner.transition_type     = BACKGROUND_TRANSITION_TYPE;
		_background_tuner.reveal_child        = true;
		_background_tuner.child               = tuner;

		var jukebox = new Gtk.Image.from_resource (BACKGROUND_JUKEBOX);
		jukebox.opacity                         = BACKGROUND_OPACITY;
		_background_jukebox.transition_duration = BACKGROUND_TRANSITION_TIME_MS;
		_background_jukebox.transition_type     = BACKGROUND_TRANSITION_TYPE;
		_background_jukebox.reveal_child        = false;
		_background_jukebox.child               = jukebox;

		var background = new Gtk.Fixed();
		background.add(_background_tuner);
		background.add(_background_jukebox);
		background.halign = Gtk.Align.CENTER;
		background.valign = Gtk.Align.CENTER;
		_overlay.add (background);


		stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
		_overlay.add_overlay(stack);

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

        
        source_list.root.add (_selections_category);
        source_list.root.add (_library_category);
        source_list.root.add (_explore_category);
        source_list.root.add (_genres_category);
        source_list.root.add (_subgenres_category);
        source_list.root.add (_eras_category);
        source_list.root.add (_talk_category);

		source_list.ellipsize_mode = Pango.EllipsizeMode.NONE;
		source_list.item_selected.connect  ((item) =>
		// Syncs Item choice to Stack view
		{
			if (item is StationListItem)
				((StationListItem)item).populate( this );
			var selected_item   = item.get_data<string> ("stack_child");
			stack.visible_child_name    = selected_item;
		});

		pack1 (source_list, false, false);
		pack2 (_overlay, true, false);
		set_position(200);

	} // Display


    /* --------------------------------------------------------
    
        Public

        ----------------------------------------------------------
    */

    /**
    * @brief Asynchronously shuffles to a new random station in jukebox mode
    *
    * If shuffle mode is active, selects and plays a new random station
    * from the jukebox station set.
    */
	public async void jukebox_shuffle(){
		if (!_shuffle)
			return;
		try
		{
            var station = jukebox_station_set.next_page().to_array()[0];
			station_clicked_sig(station);
		}
		catch (SourceError e)
		{
			warning(_(@"Could not get random station: $(e.message)"));
		}
	} // jukebox_shuffle


    /**
    * @brief Updates the display state based on activation status
    * @param activate Whether to activate (true) or deactivate (false) the display
    * 
    * Manages the display's active state and performs first-time initialization
    * when needed.
    */
    public void update_state( bool activate)
    {        
        if ( _active && !activate )
        /* Present Offline look */
        {
            _active = false;
            return;
        }

        if ( !_active && activate )
        // Move from not active to active
        {
            if (_first_activation)
            // One time set up - do post initialization
            {
                //  TBD
                _first_activation = false;
                initialize.begin();  
            }
            _active = true;
            show_all();   
        }
    } // update_state


    /**
     * @brief Selects the starred stations view in the source list
     * 
     * Changes the current view to show the user's starred stations by selecting
     * the first child of the library category.
     */
     public void choose_starred_stations()
     {
         source_list.selected = source_list.get_first_child (_library_category);
     } // choose_star
 
 

    /* --------------------------------------------------------
    
        Private Methods

       ---------------------------------------------------------- */

    /**
    * @brief Asynchronously initializes the display components
    *
    * Sets up all categories, loads initial station data, and configures
    * signal handlers for various display components.
    */
	private async void initialize(){
		_directory.load (); // Initialize the DirectoryController

        /* Initialize the directory contents */

        /* ---------------------------------------------------------------------------
            Discover
        */

        var discover = StationListBox.create ( stack
            , source_list
            ,  _selections_category
            , "discover"
            , "face-smile"
            , "Discover"
            , "Stations to Explore"
            , false
            ,_directory.load_random_stations(20)
            , "Discover more stations"
            , "media-playlist-shuffle-symbolic");
        
        discover.action_button_activated_sig.connect (() => {
            discover.item.populate( this, true );
        });


		/* ---------------------------------------------------------------------------
		    Trending
		 */
		create_category_specific
		        ( stack,
		        source_list,
		        _selections_category,
		        "trending",
		        "playlist-queue",
		        "Trending",
		        "Trending in the last 24 hours",
		        _directory.load_trending_stations(40)
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
                , _("Starred by You :")
                ,_directory.get_starred() 
            );

            starred.badge ( @"$(starred.item_count)\t");
            starred.parameter = @"$(starred.item_count)";
            
            starred.item_count_changed_sig.connect (( item_count ) =>
            {
                starred.badge ( @"$(starred.item_count)\t");
                starred.parameter = @"$(starred.item_count)";
            });


        // ---------------------------------------------------------------------------
        // Search Results Box
        

        var search_results = StationListBox.create 
        ( stack
        , source_list
        , _library_category
        , "searched"
        , "folder-saved-search"
        , _("Recent Search")
        , _("Search Results")
        , false
        , null
        , _("Save this search")
        , "starred-symbolic");

		search_results.tooltip_button.sensitive = false;
		_search_controller = new SearchController(directory,this,search_results );

        search_results.item_count_changed_sig.connect (( item_count, parameter ) =>
        {
            if ( parameter.length > 0 && stack.get_child_by_name (parameter) == null )  // Search names are prefixed with >
            {
                search_results.tooltip_button.sensitive = true;
                return;
            }
            search_results.tooltip_button.sensitive = false;
        });


		// Add saved search from star press
		search_results.action_button_activated_sig.connect (() =>
		{
			if (app().is_offline)
				return;
			search_results.tooltip_button.sensitive = false;
			var new_saved_search= 
                add_saved_search( search_results.parameter, _directory.add_saved_search (search_results.parameter));
			new_saved_search.list(search_results.content);
			source_list.selected = source_list.get_last_child (_saved_searches_category);
		});


        // ---------------------------------------------------------------------------
        // Saved Searches


        // Add saved searches to category from Directory
        var saved_searches = _directory.load_saved_searches();
        foreach( var search_term in saved_searches.keys)
        {
           add_saved_search( search_term, saved_searches.get (search_term));
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


        app().stars.starred_stations_changed_sig.connect ((station) =>
        /*
        * Refresh the starred stations list when a station is starred or unstarred
         */
        {
			if (app().is_offline && _directory.get_starred ().size > 0)
				return;
			var _slist = StationList.with_stations (_directory.get_starred ());
			station_list_hookup(_slist);
			starred.content = _slist;
            starred.parameter = @"$(starred.item_count)";
            starred.show_all();
		});


		search_focused_sig.connect (() =>
		/* Show searched stack when cursor hits search text area */
		{
			stack.visible_child_name = "searched";
		});


		searched_for_sig.connect ((text) =>
        /* process the searched text, stripping it, and sensitizing the save
        search star depending on if the search is already saved */
		{
            search_results.tooltip_button.sensitive = false;
			_search_controller.handle_search_for(text);
		});

        source_list.selected = source_list.get_first_child(_selections_category);

		show();
	} // initialize


    /* -------------------------------------------------

        Helpers

        Shortcuts to configure the source_list and stack

       -------------------------------------------------
    */

    /**
     * @brief Configures the jukebox mode for a category.
     * @param category The category to configure.
     */
    private void jukebox(SourceList.ExpandableItem category)
    {
        SourceList.Item item = new SourceList.Item(_("Jukebox"));
        item.icon = new ThemedIcon("jukebox");
        item.activated.connect(() =>
        {
                _shuffle = true;
                jukebox_shuffle.begin();
                app().player.shuffle_mode_sig(true);
                _background_tuner.reveal_child = false;    
                _background_jukebox.reveal_child = true; 
        });

		app().player.tape_counter_sig.connect((oldstation) =>
		{
			if (_shuffle)
				jukebox_shuffle.begin();
		});
		category.add(item);
	} // jukebox


    /**
    * @brief Hooks up signals for a StationList.
    * @param station_list The StationList to hook up.
    *
    * Configures signal handlers for station clicks and favorites changes.
    */
	internal void station_list_hookup(StationList station_list)
    {
		station_list.station_clicked_sig.connect((station) =>
		{
			station_clicked_sig(station);
            if ( _shuffle ) 
            {
                _shuffle = false;
                app().player.shuffle_mode_sig(false);
                _background_jukebox.reveal_child = false;
                _background_tuner.reveal_child   = true;
            } // if
		});
	}  // station_list_hookup



    /**
     * Adds a saved search to the display with the specified search term and station set.
     * 
     * @param search      The search term to be saved
     * @param station_set The set of stations to associate with this search
     * @param content    Optional station list to be used as content. If null, a new list will be created
     * 
     * @return Returns a StationListBox widget containing the search results
     */
    private StationListBox add_saved_search(string search, StationSet station_set, StationList? content = null)//StationSet station_set)
    {
        var saved_search = create_category_specific 
            ( stack
            , source_list
            , _saved_searches_category
            , search
            , "playlist-symbolic"
            , search
            , _(@"Saved Search :  $search")
            , station_set
            , _("Remove this saved search")
            , "non-starred-symbolic"
            );

        if ( content != null ) { 
            saved_search.content = content; 
        }

        saved_search.action_button_activated_sig.connect (() => {
            if ( app().is_offline ) return;
            _directory.remove_saved_search (search);
            saved_search.delist ();
        });

        return saved_search;
    } // refresh_saved_searches
    

    /**
     * @brief Creates a predefined category in the source list.
     * @param stack The stack widget.
     * @param source_list The source list widget.
     * @param category The category to add to.
     * @param name The name of the category.
     * @param icon The icon for the category.
     * @param title The title of the category.
     * @param subtitle The subtitle of the category.
     * @param stations The collection of stations for the category.
     * @return The created SourceListBox for the category.
     */
    private StationListBox create_category_predefined
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
        var genre = StationListBox.create 
            ( stack
            , source_list
            , category
            , name
            , icon
            , title
            , subtitle 
            , true
            );

		if (stations != null)
		{
			var slist = StationList.with_stations (stations);
			station_list_hookup(slist);
			genre.content = slist;
		}

        return genre;
    
    } // create_category_predefined


	/**
	* @brief Creates a specific category in the source list.
	* @param stack The stack widget.
	* @param source_list The source list widget.
	* @param category The category to add to.
	* @param name The name of the category.
	* @param icon The icon for the category.
	* @param title The title of the category.
	* @param subtitle The subtitle of the category.
	* @param station_set The set of stations for the category.
	* @param action_tooltip_text Optional tooltip text for the action.
	* @param action_icon_name Optional icon name for the action.
	* @return The created SourceListBox for the category.
	*/
	private StationListBox create_category_specific
	        ( Gtk.Stack stack,
	        Granite.Widgets.SourceList source_list,
	        Granite.Widgets.SourceList.ExpandableItem category,
	        string name,
	        string icon,
	        string title,
	        string subtitle,
	        StationSet station_set,
	        string? action_tooltip_text = null,
	        string? action_icon_name    = null
	        )
    {
		var genre = StationListBox.create
		                    ( stack,
		                    source_list,
		                    category,
		                    name,
		                    icon,
		                    title,
		                    subtitle,
		                    false,
		                    station_set,
		                    action_tooltip_text,
		                    action_icon_name
		                    );

		return genre;
	} // create_category_specific


	/**
	* @brief Creates genre-specific categories in the source list.
	* @param stack The stack widget.
	* @param source_list The source list widget.
	* @param category The category to add to.
	* @param directory The directory controller.
	* @param genres The array of genres.
	*/
	private void create_category_genre
	        ( Gtk.Stack stack,
	        Granite.Widgets.SourceList source_list,
	        Granite.Widgets.SourceList.ExpandableItem category,
	        DirectoryController directory,
	        string[] genres
	        ){
		foreach (var genre in genres )
		{
			create_category_specific(stack,
			                         source_list,
			                         category,
			                         genre,
			                         "playlist-symbolic",
			                         genre,
			                         genre,
			                         directory.load_by_tag (genre.down ()));
		}
	} // create_category_genre
} // Display
