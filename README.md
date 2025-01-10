# ![icon](docs/logo_01.png) Tuner [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0) [![Translation status](https://hosted.weblate.org/widgets/tuner/-/tuner-ui/svg-badge.svg)](https://hosted.weblate.org/engage/tuner/)

## Minimalist radio station player - V2
Discover and Listen to your favourite internet radio stations.

![Screenshot 01](docs/Tuner_2.0_discover.png?raw=true)

## Contributors wanted!

I've started `Tuner` in May 2020 when COVID-19 began to change our lives and provided me with some time to finally learn things that I couldn't during my life as a professional developer. 

I moved from macOS to Linux as a daily driver, learned a little about Linux programming, and chose Vala as the language for Tuner. At the time I was running elementary OS, and they have excellent documentation for beginning developers on how to build nice-looking apps for elementary. That helped me a lot to get started with all the new stuff.

At the time, I never expected `Tuner` to be installed by the thousands on other great distros, like Arch, MX Linux, Ubuntu, Fedora. In August 2020, I released `Tuner` as a Flatpak app, and it was installed over 18.000 times on Flathub alone ever since! Users began to send me their appreciations but also bug reports and feature requests. Some friendly contributors made Tuner available on MX Linux and Arch AUR repos. 

Maybe it was around this time when I started to feel not only the euphoria that comes with Open Source projects but also the weight of responsibility. I feared to move on because I didn't want to break things, so *I* took a break :-). 

Yet, users keep sending bug reports and feature requests. I want `Tuner` to live on and be the best tiny internet radio receiver for the Linux environment. 

### You can help translate Tuner into your language

Tuner translations are now hosted on [Weblate](https://hosted.weblate.org/engage/tuner/). Please help by translating Tuner into your language or fix any translation issues.

[![Translation status](https://hosted.weblate.org/widgets/tuner/-/tuner/multi-auto.svg)](https://hosted.weblate.org/engage/tuner/)

Thanks to the Weblate team for generously hosting Tuner for free.


**Would you be interested in joining the project as a developer or package maintainer?**

Things I need help with:

- Deeper integration into the GNOME desktop environment (DBus and such)
- Development of new features for Tuner (skills: Vala/C)
- Create and maintain Tuner packages for distros. Do you know how we can get Tuner into some official repos?
- Help me fixing those Flatpak bugs users are reporting
- Translate Tuner into more languages

**Interested?** Please open an issue or drop me an email.

## Installation

### Flathub

Tuner is primarily available as a Flatpak on Flathub:
https://flathub.org/apps/details/com.github.louis77.tuner


### Local Build

Build Tuner localy with the [development doc](DEVELOP.md).


### Other Places
Other packed versions of Tuner are available, but are maintained outside of Tuner itself: Versions may be out of date.

#### elementary OS

Install Tuner via elementary's App store:
https://appcenter.elementary.io/com.github.louis77.tuner

#### Arch Linux / AUR
Arch-based GNU/Linux users can find `Tuner` under the name [tuner-git](https://aur.archlinux.org/packages/tuner-git/) in the **AUR**:

```sh
$ yay -S tuner-git
```
Thanks to [@btd1377](https://github.com/btd1337) for supporting Tuner on Arch Linux!

#### MX Linux
MX Linux users can find `Tuner` by using the MX Package Installer (currently under the MX Test Repo tab for MX-19 and the Stable Repo for MX-21)

Thanks to SwampRabbit for packaging Tuner for MX Linux!

#### Pacstall
Pacstall is a totally new package manager for Ubuntu that provides an AUR-like community-driven repo for package builds. If you already use `pacstall` you can install Tuner:

```sh
$ pacstall -I tuner
```

If you have Ubuntu and want a clean build of Tuner on your system, consider using `pacstall` instead of Flatpak if you don't feat beta software. Get `pacstall` here:

https://pacstall.dev


## Motivation

I love listening to radio while I work. There are tens of tousands of cool internet radio stations available, however I find it hard to "find" new stations by using filters and genres. As of now, this little app takes away all the filtering and just presents me with new radio stations every time I use it.

While I hacked on this App, I discovered so many cool and new stations, which makes it even more enjoyable. I hope you enjoy it too.

## Features

- Uses [radio-browser.info](https://www.radio-browser.info/) radio station catalog
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


## Build, Maintance and Development of Tuner

Building, developing and maintianing **Tuner** is detailed seperately and in detail in the [DEVELOP](DEVELOP.md) markdown.


## Support 

Feature request, observations and Issues can be documented with tickets on [Github](https://github.com/louis77/tuner/issues)


### Known Issues

#### If AAC/AAC+ streams don't play (found on Elementary OS 6) install the following dependency:
```sh
$ sudo apt install gstreamer1.0-libav
```

#### 'Failed to load module "xapp-gtk3-module"'
Running Tuner from the CLI with `flatpak run com.github.louis77.tuner` may produce a message like the following:

`Gtk-Message: 10:01:00.561: Failed to load module "xapp-gtk3-module"`

This relates to Gtk looking for Xapp (which isn't used by Tuner) and can be ignored.


## Credits

- [technosf](https://github.com/technosf) (_Me!_) Louis has been gracious enough to let me rewrite a swarthe of Tuner and create v2
- [faleksandar.com](https://faleksandar.com/) for icons and colors
- [faleksandar.com](https://faleksandar.com/) for icons and colors
- [@NathanBnm](https://github.com/NathanBnm) - French translation
- [@DevAlien](https://github.com/DevAlien) - Italian translation 
- [@albanobattistella](https://github.com/albanobattistella) - Italian translation
- [@Vistaus](https://github.com/Vistaus) - Dutch translation
- [@safak45x](https://github.com/safak45x) - Turkish translation
- [@btd1337](https://github.com/btd1337) - supports Tuner on Arch Linux / AUR
- [@SwampRabbit](https://github.com/SwampRabbit) - supports Tuner on MX Linux

### Free Software Foundation

~~I'm a member of the Free Software Foundation.~~ Without GNU/Linux and all the great
work from people all over the world producing free software, this project would
not have been possible.

*Update 2021-08-01: I'm no longer a member of the Free Software Foundation.*

## Disclaimer

Tuner uses the community-driven radio station catalog radio-browser.info. Tuner
is not responsible for the stations shown or the actual streaming audio content.

