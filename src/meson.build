executable(
    meson.project_name(),
    'Main.vala',
    'Application.vala',
    'Widgets/Window.vala',
    'Widgets/HeaderBar.vala',
    'Widgets/StationBox.vala',
    'Controller/PlayerController.vala',
    'Model/StationModel.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('gstreamer-1.0'),
        dependency('gstreamer-player-1.0')
    ],
    install: true
)
