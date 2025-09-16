/*
 * Minimal Granite shim implemented with Gtk for cross‑platform builds.
 * Provides: Granite.Widgets.SourceList (subset), AlertView (very small),
 * and Granite.STYLE_CLASS_H3_LABEL constant replacement.
 */

namespace Granite {
    public const string STYLE_CLASS_H3_LABEL = "h3";

    namespace Widgets {
        public class SourceList : Gtk.Box {
            public class Item : Gtk.ListBoxRow {
                public string title { get; set; }
                public GLib.Icon? icon { get; set; }
                public string? tooltip { get; set; }
                public string badge { get; set; default = ""; }

                private Gtk.Label _label;
                private Gtk.Image _image;
                private Gtk.Label _badge_label;

                public signal void activated();

                public Item(string title) {
                    Object();
                    this.title = title;
                    var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
                    _image = new Gtk.Image();
                    _label = new Gtk.Label(title);
                    _label.halign = Gtk.Align.START;
                    _label.ellipsize = Pango.EllipsizeMode.END;
                    _badge_label = new Gtk.Label("");
                    _badge_label.get_style_context().add_class("keycap");
                    box.pack_start(_image, false, false, 0);
                    box.pack_start(_label, true, true, 0);
                    box.pack_end(_badge_label, false, false, 0);
                    add(box);
                    show_all();

                    notify["icon"].connect(() => {
                        if (icon != null) _image.gicon = icon;
                    });
                    notify["badge"].connect(() => {
                        _badge_label.label = badge;
                    });
                }
            }

            public class ExpandableItem : Item {
                public bool collapsible { get; set; default = true; }
                public bool expanded { get; set; default = true; }
                private Gtk.ListBox? _root_parent = null;
                private int _child_count = 0;
                private Item? _first_child = null;
                private Item? _last_child = null;

                public ExpandableItem(string title) {
                    base(title);
                    // Track parent ListBox so we can insert children after this row
                    this.parent_set.connect((old_parent) => {
                        _root_parent = this.get_parent() as Gtk.ListBox;
                    });
                }

                public void add(Item item) {
                    if (_root_parent != null) {
                        // find index of this row in root and insert after it
                        var rows = _root_parent.get_children();
                        int idx = 0;
                        foreach (var w in rows) { if (w == this) break; idx++; }
                        _root_parent.insert(item, idx + 1 + _child_count);
                        _root_parent.show_all();
                    }
                    if (_first_child == null) _first_child = item;
                    _last_child = item;
                    _child_count++;
                }
                public void remove(Item item) {
                    item.destroy();
                    _child_count = _child_count > 0 ? _child_count - 1 : 0;
                    if (_child_count == 0) { _first_child = null; _last_child = null; }
                }

                public Item? get_first_child() { return _first_child; }
                public Item? get_last_child() { return _last_child; }
            }

            public Gtk.ListBox root { get; private set; }
            public Granite.Widgets.SourceList.Item? selected {
                get { return (Granite.Widgets.SourceList.Item?) root.get_selected_row(); }
                set { if (value != null) root.select_row(value); }
            }

            public signal void item_selected(Granite.Widgets.SourceList.Item item);

            public Gtk.SelectionMode selection_mode {
                get { return root.get_selection_mode(); }
                set { root.set_selection_mode(value); }
            }

            public Pango.EllipsizeMode ellipsize_mode { get; set; }

            public SourceList() {
                Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
                root = new Gtk.ListBox();
                root.selection_mode = Gtk.SelectionMode.SINGLE;
                root.row_selected.connect((row) => {
                    if (row != null) item_selected((Granite.Widgets.SourceList.Item) row);
                });
                root.row_activated.connect((row) => {
                    if (row != null) ((Granite.Widgets.SourceList.Item) row).activated();
                });
                pack_start(root, true, true, 0);
                show_all();
            }

            public void add(Granite.Widgets.SourceList.Item item) { root.add(item); }

            public Granite.Widgets.SourceList.Item? get_first_child(ExpandableItem category) { return category.get_first_child(); }
            public Granite.Widgets.SourceList.Item? get_last_child(ExpandableItem category) { return category.get_last_child(); }
        }

        public class AlertView : Gtk.Box {
            public AlertView(string title, string description, string icon_name) {
                Object(orientation: Gtk.Orientation.VERTICAL, spacing: 12);
                var image = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.DIALOG);
                var t = new Gtk.Label("<b>" + title + "</b>");
                t.use_markup = true;
                var d = new Gtk.Label(description);
                d.wrap = true;
                d.max_width_chars = 60;
                d.halign = Gtk.Align.CENTER;
                t.halign = Gtk.Align.CENTER;
                image.halign = Gtk.Align.CENTER;
                pack_start(image, false, false, 0);
                pack_start(t, false, false, 0);
                pack_start(d, false, false, 0);
                show_all();
            }
        }
    }
}
