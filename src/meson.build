dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk4'),
  meson.get_compiler('c').find_library('m', required: false),
]

sources = files(
  'main.vala',
  'window.vala',
  'upgrade.vala',
)

executable('vala-clicker',
  sources,
  dependencies: dependencies,
  install: true,
)
