# Packaging instructions for various platform

## General

### Desktop Menu

The desktop file must be validated using this command:

```
$ desktop-file-validate [name-of-desktop-file]
```

### AppData

The AppData.xml must be validated using this command:

```
$ flatpak run org.freedesktop.appstream-glib validate [path-to-xml]

```

### Test different languages

```
$ LANGUAGE=de_DE ./com.github.louis77.tuner

```

## Flatpak

The flathub build manifest can be found here:
https://github.com/louis77/flathub/tree/com.github.louis77.tuner

- [ ] Move over to a non-elementary base image
