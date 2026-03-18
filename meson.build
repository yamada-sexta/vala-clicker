project('vala-clicker', 'vala', 'c',
  version: '0.1.0',
  meson_version: '>= 0.62.0',
)

gnome = import('gnome')

install_data('data/com.github.yamada.vala-clicker.desktop',
  install_dir: get_option('datadir') / 'applications'
)

install_data('data/com.github.yamada.vala-clicker.svg',
  install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps'
)

subdir('src')
