project('com.github.bcedu.vgrive', 'c', 'vala', version: '1.0.0')

gnome = import('gnome')
i18n = import('i18n')

# Set our translation domain
add_project_arguments(
	'-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()),
	language:'c'
)

# Install files listed in gresources
asresources = gnome.compile_resources(
	'as-resources',
	join_paths('data', 'resources', meson.project_name() + '.gresource.xml'),
	source_dir: 'data',
	c_name: 'as'
)

subdir('src')
subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
