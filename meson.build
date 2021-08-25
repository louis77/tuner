# Project name, programming language and version
project (
    'com.github.louis77.tuner',
    'vala', 'c',
    version: '1.4.2'
)

# if meson.get_compiler ('vala').get_id() == 'valac'
#     extra_args = ['-g', '--save_temps']
# endif

# Translation module
i18n = import ('i18n')

# GNOME module
gnome = import('gnome')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

# Compiling resources
asresources = gnome.compile_resources (
    'as-resources',
    join_paths ('data', meson.project_name ()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('gtk+-3.0'),
    dependency ('gee-0.8'),
    dependency ('gio-2.0'),
    dependency ('granite'),
    dependency ('gstreamer-1.0'),
    dependency ('gstreamer-player-1.0'),
    dependency ('libsoup-2.4'),
    dependency ('json-glib-1.0'),
    dependency ('libgeoclue-2.0'),
    dependency ('geocode-glib-1.0')
]

subdir ('src')

# Executable
executable (
    meson.project_name (),
    asresources,
    config_file,
    sources,
    dependencies: dependencies,
    install: true
)

subdir ('data')
subdir ('po')

meson.add_install_script ('meson/post_install.py')

