executable(
    meson.project_name(),
    'Main.vala',
    'Application.vala',
    'Widgets/Window.vala',
    'Widgets/HeaderBar.vala',
    'Widgets/StationBox.vala',
    'Widgets/HeaderLabel.vala',
    'Controller/PlayerController.vala',
    'Controller/DirectoryController.vala',
    'Model/StationModel.vala',
    'Services/IDirectoryProvider.vala',
    'Services/LocalDirectory.vala',
    'Services/RadioBrowserDirectory.vala',
    code_resources,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('gee-0.8'),
        dependency('granite'),
        dependency('gstreamer-1.0'),
        dependency('gstreamer-player-1.0'),
        dependency('libsoup-2.4'),
        dependency('json-glib-1.0')
    ],
    install: true
)
