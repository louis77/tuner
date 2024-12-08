
/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PlayButton.vala
 * @author technosf
 * @date 2024-12-01
 * @since 2.0.0
 * @brief HTTP client implementation using Soup library
 */

//using Tuner.PlayerController;

public class Tuner.PlayButton : Gtk.Button {

    /* Constants    */

    private  Gtk.Image PLAY = new Gtk.Image.from_icon_name (
        "media-playback-start-symbolic",
        Gtk.IconSize.LARGE_TOOLBAR
    );

    private  Gtk.Image BUFFERING = new Gtk.Image.from_icon_name (
        "media-playback-pause-symbolic",
        Gtk.IconSize.LARGE_TOOLBAR
    );

    private  Gtk.Image STOP = new Gtk.Image.from_icon_name (
        "media-playback-stop-symbolic",
        Gtk.IconSize.LARGE_TOOLBAR
    );

    /* Public */

    public PlayButton()
    {
        Object();

       // set_reverse_symbol(app().player.current_state);
        app().player.state_changed.connect ((state) => {
          //  set_reverse_symbol (state);
        });
    }

    /**
    * @brief Set the play state of the header bar.
    *
    * This method updates the play button icon and sensitivity based on the new play state.
    *
    * @param state The new play state to set.
    */
    private  void set_reverse_symbol (Gst.PlayerState state) {
        switch (state) {
            case Gst.PlayerState.PLAYING:
                image = STOP;
                sensitive = true;
                break;

            case Gst.PlayerState.BUFFERING:
                sensitive = false;
                image = BUFFERING;
                break;

            default :       //PlayerController.State.STOPPED:
                image = PLAY;
                sensitive = true;
                break;
        }
    } // set_playstate
} //  PlayButton