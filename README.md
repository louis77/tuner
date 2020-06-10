# Tuner

## Minimalist radio station player

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Discover and Listen to random radio stations while you work.

![Screenshot 01](docs/screen_03.png?raw=true)

## Dependencies

```bash
granite
gtk+-3.0
gstreamer-1.0
gstreamer-player-1.0
libsoup-2.4
json-glib-1.0
libgee-0.8
meson
vala
```

## Building

Simply clone this repo, then:

```bash
meson build && cd build
meson configure -Dprefix=/usr
sudo ninja install
```

## Credits

- [radio-browser.info](http://www.radio-browser.info) for providing a free radio station directory
- [elementary.io](https://elementary.io) for making Linux enjoyable on the desktop
- [Vala](https://wiki.gnome.org/Projects/Vala) - a great programming language
