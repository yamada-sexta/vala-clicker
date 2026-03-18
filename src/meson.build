dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('gio-2.0'),
  meson.get_compiler('c').find_library('m', required: false),
]

sources = files(
  'main.vala',
  'window.vala',
  'progression.vala',
)

executable('vala-clicker',
  sources,
  dependencies: [
    dependency('gtk4'),
    dependency('libadwaita-1'),
    meson.get_compiler('c').find_library('m', required: false),
  ],
  install: true,
)
