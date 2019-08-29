using App.Controllers;
using Gtk;
using App.Widgets;
using App.Configs;

namespace App.Views {


    public class ViewConf : AppView, VBox {
        private Gtk.Button conf_button;
        private Gtk.Button sign_out;
        private Gtk.Button empty_trash;
        private Gtk.Switch auto_sync;

        public ViewConf (AppController controler) {
            Gtk.Box mainbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            // Create elements to put inside the box
            var conf_box = this.build_conf_box(controler);
            mainbox.set_center_widget (conf_box);
		    this.set_center_widget (mainbox);
            this.get_style_context().add_class ("app_view");
            // Conf button
            conf_button = new Gtk.Button.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
            conf_button.tooltip_text = _("Configuration");
            controler.window.headerbar.pack_end(conf_button);
            this.show_all();
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
            empty_trash.get_style_context().add_class ("redbutton");
            general_grid.attach (empty_trash, 1, 2, 1, 1);
            laux = this.create_label(_("(note: vGrive doesn't delete any file, they are moved to the \".trash\" folder)"), 0, Gtk.Align.CENTER);
            general_grid.attach (laux, 0, 3, 2, 1);

            laux = this.create_heading(_("Preferences"));
            general_grid.attach (laux, 0, 4, 2, 1);

            laux = this.create_label(_("Begin sync when app is started:"));
            general_grid.attach (laux, 0, 5, 1, 1);
            auto_sync = this.create_switch();
            var saved_state = AppSettings.get_default();
            if (saved_state.auto_sync == 1) auto_sync.set_active (true);
            else auto_sync.set_active (false);
            general_grid.attach (auto_sync, 1, 5, 1, 1);

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
                controler.vgrive.delete_credentials ();
                controler.vgrive.delete_local_credentials ();
                controler.set_registered_view ("init");
                conf_button.visible = true;
            });
            empty_trash.clicked.connect(() => {
                this.build_trash_confirmation_dialog (controler);
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.back_button.set_label (_("Save"));
            conf_button.visible = false;
            controler.window.headerbar.set_title (Constants.APP_NAME+ _(": Configuration"));
        }

        public void update_view_on_hide(AppController controler) {
            conf_button.visible = true;
            var saved_state = AppSettings.get_default();
            if (auto_sync.get_active ()) saved_state.auto_sync = 1;
            else  saved_state.auto_sync = 0;
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

        private void build_trash_confirmation_dialog(AppController controler) {
            Gtk.Window edit_window = new Gtk.Window();
            edit_window.window_position = Gtk.WindowPosition.CENTER;
            edit_window.set_resizable(false);
            var header_bar = new Gtk.HeaderBar ();
            header_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            header_bar.show_close_button = true;
            header_bar.has_subtitle = false;
            edit_window.set_titlebar(header_bar);

            // Create content widgets
            Gtk.Box editBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            editBox.expand = true;
            editBox.margin = 10;

            Gtk.Label lbl = this.create_heading (_("Are you sure tou want to permanently erase the items in the Trash?"), Gtk.Align.START);
            editBox.pack_start (lbl, false, false, 0);
            lbl = this.create_label (_("Trash localted in: %s").printf(controler.vgrive.trash_path), 0, Gtk.Align.START);
            editBox.pack_start (lbl, false, false, 0);

            Gtk.Box btnBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            btnBox.expand = true;
            btnBox.margin = 10;
            Gtk.Button btn = this.create_button (_("Cancel"), Gtk.Align.END);
            btn.clicked.connect(() => {
                edit_window.destroy();
            });
            btnBox.pack_start (btn, false, false, 0);
            btn = this.create_button (_("Empty trash"), Gtk.Align.END);
            btn.get_style_context().add_class ("redbutton");
            btn.clicked.connect(() => {
                controler.vgrive.empty_trash();
                edit_window.destroy();
            });
            btnBox.pack_start (btn, false, false, 10);
            editBox.pack_start (btnBox, false, false, 10);

            edit_window.add(editBox);
            edit_window.show_all();
        }
    }

}

