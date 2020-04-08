
srcs = files([
    'configs/Constants.vala',
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
]

libunity_dep = dependency('unity', required : false)
if libunity_dep.found()
    add_project_arguments('-D', 'LIBUNITY', language: 'vala')
    deps += [libunity_dep]
endif

libappindicator_dep = dependency('appindicator3-0.1', required : false)
if libappindicator_dep.found()
    add_project_arguments('-D', 'LIBAPPINDICATOR', language: 'vala')
    deps += [libappindicator_dep]
endif


executable(
    meson.project_name(),
    srcs,
    asresources,
    dependencies: deps,
    install: true
)
