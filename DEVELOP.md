# ![icon](docs/logo_01.png) Develop, Build and Contribute to Tuner [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0) <!-- omit in toc -->


Discover and Listen to your favourite internet radio stations, and add improve the code!

- [Overview](#overview)
- [Tuner Development](#tuner-development)
  - [Dependencies](#dependencies)
  - [Building the Tuner App From Source](#building-the-tuner-app-from-source)
  - [Readying code for a Pull Request](#readying-code-for-a-pull-request)
  - [NamingConventions](#namingconventions)
- [Building the Tuner Flatpak](#building-the-tuner-flatpak)
- [Debugging](#debugging)
  - [VSCode](#vscode)
  - [Bug Introduction](#bug-introduction)


## Overview

**_Tuner_** is hosted on Github, packaged as a Flatpak and distributed by Flathub. **_Tuner_** is writen in [Vala](https://vala.dev/), a C#/Java/JavaFX-like language with a self-hosting compiler that generates C code and uses the GObject type system and wrapping a number of GTK libraries. It uses [Meson](https://mesonbuild.com/) as its build system.

**_Tuner_** has not undergone a lot of attention in a while, and would benefit from a review with an eye to refactoring and cleaning up the code, while in the short term addressing known bugs and fixing basic functional issues, documentation and also making it easier to build and test.

## Tuner Development
Hosted on Github, the _main_ branch reflects the current stable release. The _development_ branch is the development branch. Pull Requests should be made against the _development_ branch.

### Dependencies

Development dependencies for Tuner are:
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

Install required dependencies (Debian/Ubuntu):
```bash
sudo apt install git valac meson
sudo apt install libgtk-3-dev libgee-0.8-dev libgranite-dev libgstreamer1.0-dev libgstreamer-plugins-bad1.0-dev libsoup-3.0-dev libjson-glib-dev
```

### Building the Tuner App From Source
There are two build configurations: _debug_ and _release_. The _debug_ build (manifest _com.github.louis77.tuner.debug.yml_) is recommended for development, while the _release_ build (manifest _com.github.louis77.tuner.yml_) is for distribution. Build instructions will focus on the _debug_ build.


Clone the repo and drop into the Tuner directory:
```bash
git clone https://github.com/louis77/tuner.git
cd tuner
```

Configure Meson for development debug build, build Tuner with Ninja, and run the result:
```bash
meson setup --buildtype=debug builddir
meson compile -C builddir
meson install -C builddir     # only needed once to get the gschema in place
./builddir/com.github.louis77.tuner
```

Tuner can be deployed to the local system to bypass flatpak if required, however it is _recommended to use flatpak_.To do deploy locally, run the following command:
```bash
meson configure -Dprefix=/usr
sudo ninja install
```

### Readying code for a Pull Request
Before a pull request can be accepted, the code must pass linting. This is done by running the following command:
```bash
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest com.github.louis77.tuner.yml
```

Linting currently produces the following issues (adddressed in ticket #140): 
```json
{
    "errors": [
        "appid-uses-code-hosting-domain"
    ],
    "info": [
        "appid-uses-code-hosting-domain: github.com"
    ],
    "message": "Please consult the documentation at https://docs.flathub.org/docs/for-app-authors/linter"
}
```
Ensure that the CI checks pass before pushing your changes.


### NamingConventions
Going forward, all new code should conform to the following naming conventions:
- Namespaces are named in camel case: NameSpaceName
- Classes are named in camel case: ClassName
- Method names are all lowercase and use underscores to separate words: method_name
- Constants (and values of enumerated types) are all uppercase, with underscores between words: CONSTANT_NAME 
- Public properties are named in camel case: propertyName
- Private member variables are named all lowercase and use underscores to separate words prefixed with an underscore: _var_name

<!---- Signals are named all lowercase and use underscores to separate words postfixed with \_sig: propertyName_sig -->


## Building the Tuner Flatpak
Tuner uses the __elementary.io__ platform, version __8__. To build the tuner flatpak, install the elementry SDK and Platform:
```bash
apt-get install flatpak-builder
flatpak remote-add --user --if-not-exists elementary https://flatpak.elementary.io/repo.flatpakrepo
flatpak install elementary io.elementary.Sdk//8 io.elementary.Platform//8
```

Build the flatpak in the _user_ scope:
```bash
flatpak-builder --force-clean --user --sandbox --install build-dir com.github.louis77.tuner.debug.yml
```

Run the Tuner flatpack:
```bash
flatpak --user run com.github.louis77.tuner
```
Check the app version to ensure that it matches the version in the manifest.

## Debugging 

### VSCode 
Debugging from VSCode using GDB, set up the launch.json file as follows:
```json
{
  "version": "0.2.0",
  "configurations": [    
    {
      "name": "Debug Vala with Meson",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/builddir/com.github.louis77.tuner",
      "args": [],
      "stopAtEntry": false,
      "cwd": "${workspaceFolder}",
      "environment": [],
      "externalConsole": false,
      "MIMode": "gdb",
      "miDebuggerPath": "/usr/bin/gdb",
      "setupCommands": [
        {
          "description": "Enable pretty-printing for gdb",
          "text": "-enable-pretty-printing",
          "ignoreFailures": true
        }
      ],
      "preLaunchTask": "meson build"
    }
  ]
}
```
_Note:_ Variables appear as pointers, and generated code is not found. Please submit a better config if you have one.

### Bug Introduction
Knowing when a bug was introduced requires building previous versions and looking for the aberrent behavior. The following commands can be used to check out previous versions of the code:
```bash
git fetch
git tag
git checkout <tag>
```
After checking out the required version, build and run the app as described above.
