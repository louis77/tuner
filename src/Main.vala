public static int main (string[] args) {
    Gst.init (ref args);

    var app = new Application ();

    return app.run (args);
}
