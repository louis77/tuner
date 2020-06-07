public class Application : Gtk.Application {

    public Application () {
        Object (
            application_id: "com.github.louis77.tuner",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate() {
        var window = new Tuner.Window (this);

        add_window (window);
    }

}

