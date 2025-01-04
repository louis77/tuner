/**
 * @file Application.vala
 * @brief Contains the main Application class for the Tuner application
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */


public class Tuner.Settings : GLib.Settings 
{  
    private const string SETTINGS_AUTO_PLAY = "auto-play";
    private const string SETTINGS_DO_NOT_VOTE = "do-not-vote";
    private const string SETTINGS_LAST_PLAYED_STATION = "last-played-station";
    private const string SETTINGS_POS_X = "pos-x";
    private const string SETTINGS_POS_Y = "pos-y";
    private const string SETTINGS_START_ON_STARRED = "start-on-starred";
    private const string SETTINGS_STREAM_INFO = "stream-info";
    private const string SETTINGS_STREAM_INFO_FAST = "stream-info-fast";
    private const string SETTINGS_THEME_MODE = "theme-mode";
    private const string SETTINGS_VOLUME = "volume";
    private const string SETTINGS_WINDOW_HEIGHT = "window-height";
    private const string SETTINGS_WINDOW_WIDTH = "window-width";

    public bool auto_play { get; set; }
    public bool do_not_vote { get; set; }
    public string last_played_station { get; set; }
    public bool start_on_starred { get; set; }
    public bool stream_info { get; set; }
    public bool stream_info_fast { get; set; }
    public string theme_mode { get; set; }
    public double volume { get; set; }

    private int _pos_x;
    private int _pos_y;
    private int _window_height;
    private int _window_width;


    public Settings() {
       Object(
            schema_id : Application.APP_ID
       );

        _pos_x = get_int(SETTINGS_POS_X);
        _pos_y = get_int(SETTINGS_POS_Y);
        _window_height = get_int(SETTINGS_WINDOW_HEIGHT);
        _window_width = get_int(SETTINGS_WINDOW_WIDTH);

        auto_play = get_boolean(SETTINGS_AUTO_PLAY);
        do_not_vote = get_boolean(SETTINGS_DO_NOT_VOTE);
        last_played_station = get_string(SETTINGS_LAST_PLAYED_STATION);
        start_on_starred = get_boolean(SETTINGS_START_ON_STARRED);
        stream_info = get_boolean(SETTINGS_STREAM_INFO);
        stream_info_fast = get_boolean(SETTINGS_STREAM_INFO_FAST);
        theme_mode = get_string(SETTINGS_THEME_MODE);
        volume = get_double(SETTINGS_VOLUME);
    } // Settings

    
    public void configure()
    {        
        app().window.resize(_window_width, _window_height);
        app().window.move(_pos_x, _pos_y);
        app().player.volume = _volume;     
        
    } // configure


    public void save()
    {
        app().window.get_position(out _pos_x, out _pos_y);
        if ( _pos_x !=0 && _pos_y != 0 )
        {
            set_int(SETTINGS_POS_X, _pos_x);
            set_int(SETTINGS_POS_Y, _pos_y);
        }

        set_int(SETTINGS_WINDOW_HEIGHT, app().window.height);
        set_int(SETTINGS_WINDOW_WIDTH, app().window.width);

        set_boolean(SETTINGS_AUTO_PLAY, auto_play);
        set_boolean(SETTINGS_DO_NOT_VOTE, do_not_vote);
        set_string(SETTINGS_LAST_PLAYED_STATION, last_played_station);
        set_boolean(SETTINGS_START_ON_STARRED, start_on_starred);
        set_boolean(SETTINGS_STREAM_INFO, stream_info);
        set_boolean(SETTINGS_STREAM_INFO_FAST, stream_info_fast);
        set_string(SETTINGS_THEME_MODE, theme_mode);
        set_double(SETTINGS_VOLUME, app().player.volume);
    } // save
} // Tuner.Settings
