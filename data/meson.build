#
# Data meson build file
#
# Icons, desktop file, appdata and schema
#

#
# Install icons
#
message('Installing Icons...')

icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data (
        join_paths ('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths (get_option ('datadir'), 'icons','hicolor', i + 'x' + i, 'apps'),
        install_tag: 'icons'
    )
    install_data (
        join_paths ('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths (get_option ('datadir'), 'icons','hicolor', i + 'x' + i + '@2', 'apps'),
        install_tag: 'icons'
    )
endforeach


message('Installed icons\n')


#
# Install desktop file
#
message('Installing desktop file...')
# Translate and install our .desktop file so the Applications Menu will see it
i18n.merge_file (
    input: meson.project_name () + '.desktop.in',
    output: meson.project_name () + '.desktop',
    po_dir: join_paths (meson.project_source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'applications'),
    install_tag: 'applications'
)

message('Installed desktop file\n')


#
# Install appdata
#
message('Installing appdata...')

# Translate and install our .appdata.xml file so AppCenter will see it
i18n.merge_file (
    input: meson.project_name () + '.appdata.xml.in',
    output: meson.project_name () + '.appdata.xml',
    po_dir: join_paths (meson.project_source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths (get_option ('datadir'), 'metainfo'),
    install_tag: 'metainfo'
)

message('Installed appdata\n')


#
# Install schema
#
message('Installing schema...')

schemas_dir = join_paths (get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas')

settings_schemas = [ meson.project_name() + '.gschema.xml' ]

install_data(settings_schemas, install_dir: schemas_dir)

meson.add_install_script(
    'glib-compile-schemas',
    '--targetdir=' + meson.project_build_root(),
    schemas_dir,
    install_tag: 'schemas'
)


message('Installed schema\n')
