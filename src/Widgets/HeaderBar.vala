public class Tuner.HeaderBar : Gtk.HeaderBar {
    public Tuner.Window main_window { get; construct; }

    public HeaderBar (Tuner.Window window) {
        Object (
            main_window: window
        );
    }

    construct {
        show_close_button = true;
        title = "Barba Radio FM Germany";
        subtitle = "Paused";

        var menu_button = new Gtk.Button.from_icon_name (
            "media-playback-start",
            Gtk.IconSize.LARGE_TOOLBAR
        );
        menu_button.valign = Gtk.Align.CENTER;

        pack_end (menu_button);
    }

    public void open_dialog () {
        var dialog = new Gtk.Dialog.with_buttons (
            "Add a new station",
            main_window,
            Gtk.DialogFlags.DESTROY_WITH_PARENT |
                Gtk.DialogFlags.MODAL,
            "Custom Button", 1,
            "Second Button", 2,
            null
        );

        var label = new Gtk.Label ("This is the content of the dialog.");
        var content_area = dialog.get_content_area ();
        content_area.add (label);

        dialog.show_all ();
        dialog.present ();
    }

}
