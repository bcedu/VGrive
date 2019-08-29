using App.Controllers;
using Gtk;
using App.Widgets;
using App.Configs;

namespace App.Views {


    public class ViewConf : AppView, VBox {
        private Gtk.Button conf_button;
        private Gtk.Button sign_out;
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

            laux = this.create_label(_("Change account:"));
            general_grid.attach (laux, 0, 0, 1, 1);
            sign_out = this.create_button(_("Sign Out"));
            general_grid.attach (sign_out, 1, 0, 1, 1);


            laux = this.create_label(_("Begin sync when app is started:"));
            general_grid.attach (laux, 0, 1, 1, 1);
            auto_sync = this.create_switch();
            general_grid.attach (auto_sync, 1, 1, 1, 1);

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
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.back_button.set_label (_("Save"));
            conf_button.visible = false;
            controler.window.headerbar.set_title (Constants.APP_NAME+ _(": Configuration"));
        }

        public void update_view_on_hide(AppController controler) {
            conf_button.visible = true;
        }

        private Gtk.Label create_label (string text) {
            var label = new Gtk.Label (text);
            label.hexpand = true;
            label.halign = Gtk.Align.END;
            label.margin_start = 20;
            return label;
        }

        private Gtk.Switch create_switch () {
            var toggle = new Gtk.Switch ();
            toggle.halign = Gtk.Align.START;
            toggle.hexpand = true;
            return toggle;
        }

        private Gtk.Button create_button (string text) {
            var toggle = new Gtk.Button.with_label (text);
            toggle.halign = Gtk.Align.START;
            toggle.hexpand = true;
            return toggle;
        }
    }

}

