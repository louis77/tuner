public class Tuner.Window : Gtk.ApplicationWindow {
    public GLib.Settings settings;
    public Gtk.Stack stack { get; set; }

    public Window (Application app) {
        Object (
            application: app
        );
    }

    construct {
        window_position = Gtk.WindowPosition.CENTER;
        set_default_size (350, 80);

        settings = new GLib.Settings ("com.github.louis77.tuner");

        move (settings.get_int ("pos-x"), settings.get_int ("pos-y"));
        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        delete_event.connect (e => {
            return before_destroy ();
        });

        var station_label = new Gtk.Label (_("Station Name"));
        var player_state_label = new Gtk.Label ("Player State");

        var station_list = new Gtk.Grid ();

        var station1 = new Tuner.StationBox ("Barba Radio 1", "Germany");
        station_list.add (station1);

        var station2 = new Tuner.StationBox ("Radio 1", "Zurich");
        station_list.add (station2);

        var station3 = new Tuner.StationBox ("SWF 3", "Schaffhausen");
        station_list.add (station3);

        add (station_list);

        var headerbar = new Tuner.HeaderBar (this);
        set_titlebar (headerbar);

        show_all ();
    }

    public bool before_destroy () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.set_int ("pos-x", x);
        settings.set_int ("pos-y", y);
        settings.set_int ("window-height", height);
        settings.set_int ("window-width", width);

        return false;
    }

}
