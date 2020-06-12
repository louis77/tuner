# ![icon](docs/logo_01.png) Tuner

## Minimalist radio station player

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

Discover and Listen to random radio stations while you work.

![Screenshot 01](docs/screen_04.png?raw=true)

## Motivation

I love listening to radio while I work. There are tens of tousands of cool internet radio stations available, however I find it hard to "find" new stations by using filters and genres. As of now, this little app takes away all the filtering and just presents me with new radio stations every time I use it.

While I hacked on this App, I discovered so many cool and new stations, which makes it even more enjoyable. I hope you enjoy it too.


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
