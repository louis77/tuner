public class Tuner.StationBox : Gtk.Box {

    public StationBox (string title, string subtitle) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0
        );

        border_width = 20;
        var style_context = get_style_context();
        style_context.add_class (Granite.STYLE_CLASS_CARD);

        var label = new Gtk.Label (title);
        pack_start (label);

        var sublabel = new Gtk.Label (subtitle);
        pack_start (sublabel);
    }

    construct {
    }

}
