# ![icon](docs/logo_01.png) Tuner

## Minimalist radio station player
Discover and Listen to your favourite internet radio stations.

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
![Screenshot 01](docs/screen_dark_1.3.0.png?raw=true)

## Contributors wanted!

I've started `Tuner` in May 2020 when COVID-19 began to change our lives and provided me with some time to finally learn things that I couldn't during my life as a professional developer. 

I moved from macOS to Linux as a daily driver, learned a little about Linux programming, and chose Vala as the language for Tuner. At the time I was running elementary OS, and they have excellent documentation for beginning developers on how to build nice-looking apps for elementary. That helped me a lot to get started with all the new stuff.

At the time, I never expected `Tuner` to be installed by the thousands on other great distros, like Arch, MX Linux, Ubuntu, Fedora. In August 2020, I released `Tuner` as a Flatpak app, and it was installed over 18.000 times on Flathub alone ever since! Users began to send me their appreciations but also bug reports and feature requests. Some friendly contributors made Tuner available on MX Linux and Arch AUR repos. 

Maybe it was around this time when I started to feel not only the euphoria that comes with Open Source projects but also the weight of responsibility. I feared to move on because I didn't want to break things, so *I* took a break :-). 

Yet, users keep sending bug reports and feature requests. I want `Tuner` to live on and be the best tiny internet radio receiver for the Linux environment. 

**Would you be interested in joining the project as a developer or package maintainer?**

Things I need help with:

- Deeper integration into the GNOME desktop environment (DBus and such)
- Development of new features for Tuner (skills: Vala/C)
- Create and maintain Tuner packages for distros. Do you know how we can get Tuner into some official repos?
- Help me fixing those Flatpak bugs users are reporting
- Translate Tuner into more languages

**Interested?** Send me an email or get in touch with me on Freenode `louis771`.

## Installation

### Flathub

Tuner is available on Flathub, but there are some known bugs:
https://flathub.org/apps/details/com.github.louis77.tuner

### elementary OS

Install Tuner via elementary's App store:
https://appcenter.elementary.io/com.github.louis77.tuner

### Arch Linux / AUR
Arch-based GNU/Linux users can find `Tuner` under the name [tuner-git](https://aur.archlinux.org/packages/tuner-git/) in the **AUR**:

```sh
$ yay -S tuner-git
```
Thanks to [@btd1377](https://github.com/btd1337) for supporting Tuner on Arch Linux!

### MX Linux
MX Linux users can find `Tuner` by using the MX Package Installer (currently under the MX Test Repo tab)

Thanks to SwampRabbit for packaging Tuner for MX Linux!

### Pacstall
Pacstall is a totally new package manager for Ubuntu that provides an AUR-like community-driven repo for package builds. If you already use `pacstall` you can install Tuner:

```sh
$ sudo pacstall -I tuner
```

If you have Ubuntu and want a clean build of Tuner on your system, consider using `pacstall` instead of Flatpak if you don't feat beta software. Get `pacstall` here:

https://henryws.github.io/pacstall/


## Motivation

I love listening to radio while I work. There are tens of tousands of cool internet radio stations available, however I find it hard to "find" new stations by using filters and genres. As of now, this little app takes away all the filtering and just presents me with new radio stations every time I use it.

While I hacked on this App, I discovered so many cool and new stations, which makes it even more enjoyable. I hope you enjoy it too.

## Features

- Uses radio-browser.info catalog
- Presets various selection of stations (random, top, trending, genres)
- Save favourite stations
- Sends a click count to radio-browser.info on station click
- Sends a vote count to radio-browser.info when you star a station
- DBus integration to pause/resume playing and show station info in Wingpanel

## Upcoming

- More selection screens (Popular networks, Country-specific)
- More filter options (country)
- Community-listening: see what other users are listening to right now
- Other ideas? Create an issue!

## Environment Variables

* `TUNER_API` - a `:` separated list of API servers to read from, e.g.
    * `export TUNER_API="de1.api.radio-browser.info:nl1.api.radio-browser.info"; com.github.louis77.tuner`

## Dependencies

```bash
granite
gtk+-3.0
gstreamer-1.0
gstreamer-player-1.0
libsoup-2.4
json-glib-1.0
libgee-0.8
libgeoclue-2-0
libgeocode-glib0
meson
vala
```

## Building

Make sure you have the dependencies installed:

```bash
sudo apt install git valac meson
sudo apt install libgtk-3-dev libgee-0.8-dev libgranite-dev libgstreamer1.0-dev libgstreamer-plugins-bad1.0-dev libsoup2.4-dev libjson-glib-dev libgeoclue-2-dev libgeocode-glib-dev
```

Then clone this repo and build it locally:

```bash
meson build && cd build
meson configure -Dprefix=/usr
sudo ninja install
```

## Credits

- [faleksandar.com](https://faleksandar.com/) for icons and colors
- [radio-browser.info](http://www.radio-browser.info) for providing a free radio station directory
- [@NathanBnm](https://github.com/NathanBnm) - French translation
- [@DevAlien](https://github.com/DevAlien) - Italian translation 
- [@albanobattistella](https://github.com/albanobattistella) - Italian translation
- [@Vistaus](https://github.com/Vistaus) - Dutch translation
- [@safak45x](https://github.com/safak45x) - Turkish translation
- [@btd1337](https://github.com/btd1337) - supports Tuner on Arch Linux / AUR
- [@SwampRabbit](https://github.com/SwampRabbit) - supports Tuner on MX Linux

### Free Software Foundation

![FSF Member badge](https://static.fsf.org/nosvn/associate/crm/4989673.png)

I'm a member of the Free Software Foundation. Without GNU/Linux and all the great
work from people all over the world producing free software, this project would
not have been possible.

Consider joining the FSF, [here is why](https://my.fsf.org/join?referrer=4989673).

## Disclaimer

Tuner uses the community-driven radio station catalog radio-browser.info. Tuner
is not responsible for the stations shown or the actual streaming audio content.

