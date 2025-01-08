#
# PO meson build file
#

message('Installing translations...')

# Generate POT file if not a snapshot build

pot = custom_target('pot',
    input: 'POTFILES',
    output: meson.project_name() + '.pot',
    command: [
        'xgettext',
        '--files-from=@INPUT@',
        '--output=' + meson.current_source_dir() + '/' + meson.project_name() + '.pot',  # Output to source dir
        '--from-code=UTF-8',
        '--package-name=' + meson.project_name(),
        '--package-version=' + meson.project_version(),
        '--keyword=_',
        '--keyword=N_',
        '--keyword=C_:1c,2',
        '--keyword=NC_:1c,2',
        '--add-comments=TRANSLATORS',
        '--sort-output',
        '--width=80',
        '--foreign-user',
        '--directory=' + meson.project_source_root(),
    ]
)

# Install translations - process each .po file
translations = []
foreach lang : run_command('cat', 'LINGUAS', check: true).stdout().strip().split('\n')
    po_file = lang + '.po'
    if run_command('test', '-f', po_file, check: false).returncode() == 0
        translations += custom_target('translation-' + lang,
            input: po_file,
            output: lang + '.mo',
            command: [
                find_program('msgfmt'),
                '-c',  # check for format string issues
                '-v',  # verbose output
                '@INPUT@',
                '-o', '@OUTPUT@'
            ],
            build_by_default: true,
            install: true,
            install_dir: join_paths(get_option('localedir'), lang, 'LC_MESSAGES')
        )
    endif
endforeach

i18n.gettext(meson.project_name(),
    args: [
        '--directory=' + meson.project_source_root(),
        '--from-code=UTF-8',
        '-cTRANSLATORS'
    ],
    preset: 'glib'
)

subdir('extra')

message('Installed translations')
