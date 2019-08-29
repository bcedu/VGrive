
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
    dependency('granite'),
    dependency('libsoup-2.4'),
    dependency('json-glib-1.0')
]


executable(
    meson.project_name(),
    srcs,
    asresources,
    dependencies: deps,
    install: true
)