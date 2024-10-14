# ![icon](docs/logo_01.png) Develop, Build and Contribute to Tuner [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)


Discover and Listen to your favourite internet radio stations.

## Overview

Tuner is hosted on Github, and linked to Flathub so as releases are pushed Flathub will automatically update its repositary. It is writen in [Vala](https://vala.dev/), a C#/Java/JavaFX-like language with a self-hosting compiler that generates C code and uses the GObject type system and wrapping a number of GTK libraries. It uses [Meson](https://mesonbuild.com/) as its build system.



### Dependencies

```bash
granite
gstreamer-1.0
gstreamer-player-1.0
gtk+-3.0
json-glib-1.0
libgee-0.8
libsoup-3.0
meson
vala
```

### Building

Make sure you have the dependencies installed:

```bash
sudo apt install git valac meson
sudo apt install libgtk-3-dev libgee-0.8-dev libgranite-dev libgstreamer1.0-dev libgstreamer-plugins-bad1.0-dev libsoup-3.0-dev libjson-glib-dev
```

Clone the repo and drop into the Tuner directory. Configure Meson for development debug build, build Tuner with Ninja, and run the result:

```bash
meson setup --buildtype=debug builddir
ninja -C builddir
./builddir/com.github.louis77.tuner
```


```bash
meson configure -Dprefix=/usr
sudo ninja install
```
