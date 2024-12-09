
/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PlayButton.vala
 * @author technosf
 * @date 2024-12-01
 * @since 2.0.0
 * @brief Player 'PLAY' button
 */


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
    
    private  Gtk.Image ERROR = new Gtk.Image.from_icon_name (
        "dialog-error-symbolic",
        Gtk.IconSize.LARGE_TOOLBAR
    );
    

    /* Public */


    public PlayButton()
    {
        Object();
        
        image = PLAY;
        sensitive = true;

        app().player.state_changed_sig.connect ((state) => {
            set_inverse_symbol (state);
        });
    }


    /**
    * @brief Set the play button symbol and sensitivity
    *
    * This method is instigated from a Gst.Player state change signal.
    * Performing any UI actions directly while handling the signal 
    * causes a segmentation fault. To get around this, threads_add_idle
    * is used.
    *
    * @param state The new play state string.
    */
    private void set_inverse_symbol (PlayerController.Is state) 
    {
        switch (state) {
            case PlayerController.Is.PLAYING :
                image = STOP;
                sensitive = true;
                break;

            case PlayerController.Is.BUFFERING :       
                image = BUFFERING;
                sensitive = false;
                break;

            case PlayerController.Is.STOPPED_ERROR :    
                image = ERROR;
                sensitive = true;
                break;

            default :       //  STOPPED:
                image = PLAY ;
                sensitive = true;
                break;
        }
    } // set_reverse_symbol
} //  PlayButton