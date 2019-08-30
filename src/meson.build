
srcs = files([
    'configs/Constants.vala',
    'configs/Settings.vala',
    'widgets/HeaderBar.vala',
    'views/AppView.vala',
    'views/InitialView.vala',
    'views/LogInView.vala',
    'views/SyncView.vala',
    'views/ViewConf.vala',
    'VGriveClient.vala',
    'controllers/ViewController.vala',
    'controllers/AppController.vala',
    'Application.vala',
    'Window.vala',
    'Main.vala'
])


# Dependences
deps = [
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    dependency('granite'),
    dependency('gee-0.8'),
    dependency('json-glib-1.0'),
    dependency('libsoup-2.4'),
    dependency('unity')
]


executable(
    meson.project_name(),
    srcs,
    asresources,
    dependencies: deps,
    install: true
)