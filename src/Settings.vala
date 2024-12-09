/**
 * @file Application.vala
 * @brief Contains the main Application class for the Tuner application
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 */


public class Tuner.Settings : Object 
{  
    private const string SETTINGS_AUTO_PLAY = "auto-play";
    private const string SETTINGS_DO_NOT_TRACK = "do-not-track";
    private const string SETTINGS_LAST_PLAYYED_STATION = "last-played-station";
    private const string SETTINGS_POS_X = "pos-x";
    private const string SETTINGS_POS_Y = "pos-y";
    private const string SETTINGS_THEME_MODE = "theme-mode";
    private const string SETTINGS_VOLUME = "volume";
    private const string SETTINGS_WINDOW_HEIGHT = "window-height";
    private const string SETTINGS_WINDOW_WIDTH = "window-width";

    public bool auto_play { get; set; }
    public bool do_not_track { get; set; }
    public string last_played_station { get; set; }
    public double volume { get; set; }

    private int _pos_x;
    private int _pos_y;
    private int _window_height;
    private int _window_width;

    private static GLib.Settings _settings ;
    
    static construct  {
        _settings = new GLib.Settings (Application.APP_ID);
    }

    construct {
        _pos_x = _settings.get_int(SETTINGS_POS_X);
        _pos_y = _settings.get_int(SETTINGS_POS_Y);
        _window_height = _settings.get_int(SETTINGS_WINDOW_HEIGHT);
        _window_width = _settings.get_int(SETTINGS_WINDOW_WIDTH);
        _volume = _settings.get_double(SETTINGS_VOLUME);
        auto_play = _settings.get_boolean(SETTINGS_AUTO_PLAY);
        do_not_track = _settings.get_boolean(SETTINGS_DO_NOT_TRACK);
        last_played_station = _settings.get_string(SETTINGS_LAST_PLAYYED_STATION);
    }


    public void configure()
    {
        app().window.resize(_window_width, _window_height);
        app().window.move(_pos_x, _pos_y);
        app().player.volume = _volume;        
    }


    public void save()
    {
        app().window.get_position(out _pos_x, out _pos_y);
        if ( _pos_x !=0 && _pos_y != 0 )
        {
            _settings.set_int(SETTINGS_POS_X, _pos_x);
            _settings.set_int(SETTINGS_POS_Y, _pos_y);
        }

        _settings.set_int(SETTINGS_WINDOW_HEIGHT, app().window.height);
        _settings.set_int(SETTINGS_WINDOW_WIDTH, app().window.width);

        _settings.set_double(SETTINGS_VOLUME, app().player.volume);

        _settings.set_boolean(SETTINGS_AUTO_PLAY, auto_play);
        _settings.set_boolean(SETTINGS_DO_NOT_TRACK, do_not_track);
        _settings.set_string(SETTINGS_LAST_PLAYYED_STATION, last_played_station);
    }
}
