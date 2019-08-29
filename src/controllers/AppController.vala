/*
* Copyright (C) 2018  Eduard Berloso Clarà <eduard.bc.95@gmail.com>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero General Public License for more details.
*
* You should have received a copy of the GNU Affero General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/
using App.Configs;
using App.Widgets;


namespace App.Controllers {

    public class AppController {
        /**
         * Constructs a new {@code AppController} object.
         * The AppControler manages all the elements of the applications.
         */
        public App.Application application;
        public AppWindow window;
        public ViewController view_controller;
        public Unity.LauncherEntry launcher;
        public App.VGriveClient vgrive;
        public bool closed;
        public signal void log_event (string msg);

        public AppController (App.Application application) {
            this.application = application;

            var saved_state = AppSettings.get_default();
            if (saved_state.sync_folder == "null") saved_state.sync_folder = Environment.get_home_dir()+"/vGrive";

            this.vgrive = new App.VGriveClient(this, saved_state.sync_folder);
            // Create the main window
            this.window = new AppWindow (this.application);
            this.application.add_window (this.window);
            // Create the view_controller;
            this.view_controller = new ViewController (this);
            // Connect the signals
            this.connect_signals();
            this.launcher = Unity.LauncherEntry.get_for_desktop_id (Constants.LAUNCHER_ID);
            if (vgrive.has_local_credentials()) {
                if (vgrive.load_local_credentials() == 1) {
                    this.set_registered_view ("sync_view");
                }
            }
        }

        public void activate () {
            this.closed = false;
            this.launcher.progress_visible = false;
            // Show all elements from window
            window.init ();
            // Set current view
            this.update_window_view ();
        }

        public void quit () {
            // Close the window
            window.destroy ();
        }

        public void update_window_view() {
            this.window.clean ();
            this.view_controller.update_views ();
            var aux = this.view_controller.get_current_view ();
            this.window.add (aux);
        }

        public void add_registered_view(string view_id) {
            this.view_controller.add_registered_view (view_id);
            this.update_window_view ();
        }

        public void set_registered_view(string view_id) {
            this.view_controller.set_registered_view (view_id);
            this.update_window_view ();
        }

        private void connect_signals() {
            // Signals of views
            this.view_controller.connect_signals ();
            // Signal for back button
            this.window.headerbar.back_button.clicked.connect (() => {
                this.view_controller.get_current_view ();
                this.view_controller.get_previous_view ();
                this.update_window_view ();
		    });
		    this.window.delete_event.connect (() => {
                if (this.vgrive.is_syncing ()) {
                    this.closed = true;
                    this.notify (_("Sync continues in background"));
                    this.launcher.progress_visible = true;
                    this.launcher.progress = 0;
                    return this.window.hide_on_delete ();
                }else {
                    this.vgrive.stop_syncing ();
                    this.notify (_("Sync stopped"));
                    this.launcher.progress_visible = false;
                    return false;
                }
            });
        }

        public void log_message(string msg) {
            log_event(msg);
        }

        public void notify(string text) {
            var notification = new Notification (Constants.APP_NAME);
            try {
                notification.set_icon ( new Gdk.Pixbuf.from_file (Constants.APP_ICON));
            }catch (GLib.Error e) {
                stdout.printf("Notification logo not found. Error: %s\n", e.message);
            }
            notification.set_body (text);
            this.application.send_notification (this.application.application_id, notification);
        }
    }
}
