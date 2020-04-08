using App.Controllers;
using Gtk;
using App.Widgets;
using App.Configs;

namespace App.Views {

    [DBus (name = "org.freedesktop.FileManager1")]
    interface DBus.Files : Object {
        public abstract void show_items (string[] uris, string startup_id) throws IOError, DBusError;
        public abstract void show_folders (string[] uris, string startup_id) throws IOError, DBusError;
    }

    public class ViewConf : AppView, VBox {
        private Gtk.Button conf_button;
        private Gtk.Button cancel_button;
        private Gtk.Button sign_out;
        private Gtk.Button empty_trash;
        private Gtk.Button change_folder;
        private Gtk.Label selected_folder;
        private Gtk.Switch auto_sync;
        private Gtk.Switch start_minimized;
        private bool folder_changed = false;

        public ViewConf (AppController controler) {
            Gtk.Box mainbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            // Create elements to put inside the box
            var conf_box = this.build_conf_box(controler);
            mainbox.set_center_widget (conf_box);
		    this.set_center_widget (mainbox);
            // Conf button
            conf_button = new Gtk.Button.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
            conf_button.tooltip_text = _("Configuration");
            controler.window.headerbar.pack_end(conf_button);
            // Cancel button
            cancel_button = new Gtk.Button.with_label (_("Cancel"));
            cancel_button.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            controler.window.headerbar.pack_start(cancel_button);
            this.show_all();
            cancel_button.visible = false;
            cancel_button.no_show_all = true;
            if (start_minimized.active) {
                controler.send_to_background = true;
            }
        }

        private Gtk.Grid build_conf_box(AppController controler) {
            Gtk.Grid general_grid = new Gtk.Grid ();
            general_grid.get_style_context().add_class ("conf_box");
            general_grid.margin = 12;
            general_grid.hexpand = true;
            general_grid.column_spacing = 12;
            general_grid.row_spacing = 6;

            Gtk.Label laux;

            laux = this.create_heading(_("Actions"));
            general_grid.attach (laux, 0, 0, 2, 1);

            laux = this.create_label(_("Change Google Drive account:"));
            general_grid.attach (laux, 0, 1, 1, 1);
            sign_out = this.create_button(_("Sign Out"));
            general_grid.attach (sign_out, 1, 1, 1, 1);

            laux = this.create_label(_("Delete all files from \".trash\":"));
            general_grid.attach (laux, 0, 2, 1, 1);
            empty_trash = this.create_button(_("Empty the trash"));
            empty_trash.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            general_grid.attach (empty_trash, 1, 2, 1, 1);
            laux = this.create_label(_("(note: vGrive doesn't delete any file, they are moved to the \".trash\" folder)"), 0, Gtk.Align.CENTER);
            general_grid.attach (laux, 0, 3, 2, 1);

            laux = this.create_heading(_("Preferences"));
            general_grid.attach (laux, 0, 4, 2, 1);

            laux = this.create_label(_("Begin sync when app is started:"));
            general_grid.attach (laux, 0, 5, 1, 1);
            auto_sync = this.create_switch();
            if (Application.settings.get_int("auto-sync") == 1) auto_sync.set_active (true);
            else auto_sync.set_active (false);
            general_grid.attach (auto_sync, 1, 5, 1, 1);

            laux = this.create_label(_("Start minimized:"));
            general_grid.attach (laux, 0, 6, 1, 1);
            start_minimized = this.create_switch();
            if (Application.settings.get_int("start-minimized") == 1) start_minimized.set_active (true);
            else start_minimized.set_active (false);
            general_grid.attach (start_minimized, 1, 6, 1, 1);

            laux = this.create_label(_("vGrive folder:"));
            general_grid.attach (laux, 0, 7, 1, 1);
            selected_folder = this.create_label(Application.settings.get_string("sync-folder"), 0, Gtk.Align.START);
            change_folder = this.create_button(_("Change folder"));
            Gtk.Box baux = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            baux.halign = Gtk.Align.START;
            baux.pack_start(selected_folder, false, false, 0);
            baux.pack_start(change_folder, false, false, 0);
            general_grid.attach (baux, 1, 7, 1, 1);

            return general_grid;
        }

        public string get_id() {
            return "conf_view";
        }

        public void connect_signals(AppController controler) {
            conf_button.clicked.connect(() => {
                if (controler.view_controller.get_current_view ().get_id () != "conf_view") {
                    controler.add_registered_view ("conf_view");
                }
            });
            sign_out.clicked.connect(() => {
                controler.vgrive.stop_syncing ();
                controler.vgrive.delete_credentials ();
                controler.vgrive.delete_local_credentials ();
                controler.set_registered_view ("init");
                conf_button.visible = true;
                cancel_button.visible = false;
            });
            empty_trash.clicked.connect(() => {
                this.build_trash_confirmation_dialog (controler);
            });
            change_folder.clicked.connect(() => {
                this.build_select_sync_folder (controler);
            });
            cancel_button.clicked.connect(() => {
                controler.view_controller.get_current_view ();
                controler.view_controller.get_previous_view (false);

                controler.update_window_view ();

                conf_button.visible = true;
                cancel_button.visible = false;
                this.folder_changed = false;

            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.back_button.set_label (_("Save"));
            conf_button.visible = false;
            cancel_button.visible = true;
            controler.window.headerbar.set_title (Constants.APP_NAME+ _(": Configuration"));
            auto_sync.active = (bool) Application.settings.get_int("auto-sync");
            start_minimized.active = (bool) Application.settings.get_int("start-minimized");
            selected_folder.label = Application.settings.get_string("sync-folder");
        }

        public void update_view_on_hide(AppController controler) {
            conf_button.visible = true;
            cancel_button.visible = false;
            if (auto_sync.get_active ()) Application.settings.set_int("auto-sync", 1);
            else  Application.settings.set_int("auto-sync", 0);
            if (start_minimized.get_active ()) Application.settings.set_int("start-minimized", 1);
            else  Application.settings.set_int("start-minimized", 0);
            if (this.folder_changed) {
                folder_changed = false;
                Application.settings.set_string("sync-folder", this.selected_folder.get_label());
                controler.vgrive.change_main_path(Application.settings.get_string("sync-folder"));
            }
        }

        private Gtk.Label create_label (string text, int margin=20, Gtk.Align alg=Gtk.Align.END) {
            var label = new Gtk.Label (text);
            label.hexpand = true;
            label.halign = alg;
            label.margin_start = margin;
            return label;
        }

        private Gtk.Switch create_switch (Gtk.Align alg=Gtk.Align.START) {
            var toggle = new Gtk.Switch ();
            toggle.halign = alg;
            toggle.hexpand = true;
            return toggle;
        }

        private Gtk.Button create_button (string text, Gtk.Align alg=Gtk.Align.START) {
            var toggle = new Gtk.Button.with_label (text);
            toggle.halign = alg;
            toggle.hexpand = true;
            return toggle;
        }

        private Gtk.Label create_heading (string text, Gtk.Align alg=Gtk.Align.CENTER) {
            var label = new Gtk.Label (text);
            label.get_style_context ().add_class ("h4");
            label.halign = alg;
            return label;
        }

        private void build_select_sync_folder(AppController controler) {
            Gtk.FileChooserDialog file_chooser = new Gtk.FileChooserDialog (
                _("Select a folder"), controler.window, Gtk.FileChooserAction.SELECT_FOLDER, _("Cancel"),
                Gtk.ResponseType.CANCEL, _("Open"), Gtk.ResponseType.ACCEPT
            );

            // Connect folder selected
            file_chooser.response.connect((response) => {
                if (response == Gtk.ResponseType.ACCEPT) {
                    string? sel = file_chooser.get_filename ();
                    if (sel != null && this.selected_folder.get_label () != sel) {
                        this.selected_folder.set_label(sel);
                        this.folder_changed = true;
                    }
                    file_chooser.destroy ();
                } else {
                    file_chooser.destroy();
                }
            });

            file_chooser.run ();
        }

        private void build_trash_confirmation_dialog(AppController controler) {
            // New window
            Gtk.Window edit_window = new Gtk.Window();
            edit_window.window_position = Gtk.WindowPosition.CENTER;
            edit_window.set_resizable(false);
            // New header
            var header_bar = new Gtk.HeaderBar ();
            header_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            header_bar.show_close_button = true;
            header_bar.has_subtitle = false;
            edit_window.set_titlebar(header_bar);

            // Main Box
            Gtk.Box editBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            editBox.expand = true;
            editBox.margin = 10;

            // Labels with info
            Gtk.Label lbl = this.create_heading (_("Are you sure you want to permanently erase the items in the Trash?"), Gtk.Align.START);
            editBox.pack_start (lbl, false, false, 0);
            lbl = this.create_label (_("Trash localted in: %s").printf(controler.vgrive.trash_path), 0, Gtk.Align.START);
            editBox.pack_start (lbl, false, false, 0);

            // Buttons Box
            Gtk.Box btnBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            btnBox.expand = true;
            btnBox.margin = 10;

            // Cancel button
            Gtk.Button btn = this.create_button (_("Cancel"), Gtk.Align.CENTER);
            btn.clicked.connect(() => {
                edit_window.destroy();
            });
            btnBox.pack_start (btn, false, false, 0);

            // Show in Files button
            btn = this.create_button (_("Show In File Browser"), Gtk.Align.CENTER);
            btn.clicked.connect(() => {
                DBus.Files files;
                try {
                    files = Bus.get_proxy_sync (BusType.SESSION, Constants.FILES_DBUS_ID, Constants.FILES_DBUS_PATH);
                    var path = controler.vgrive.trash_path;
                    var file = File.new_for_path (path);
                    if (file.query_exists ()) {
                        info (file.get_uri ());
                        files.show_items ({ file.get_uri () }, Constants.APP_NAME);
                    }
                } catch (IOError e) {
                    warning ("Unable to connect to FileManager1 interface to show file. Error: %s", e.message);
                    return;
                }
            });
            btnBox.pack_start (btn, false, false, 0);

            // Empty Trash Button
            btn = this.create_button (_("Empty the trash"), Gtk.Align.CENTER);
            btn.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            btn.clicked.connect(() => {
                controler.vgrive.empty_trash();
                edit_window.destroy();
            });
            btnBox.pack_start (btn, false, false, 0);

            // Pack everything
            editBox.pack_start (btnBox, false, false, 10);
            edit_window.add(editBox);
            edit_window.show_all();
        }
    }

}

