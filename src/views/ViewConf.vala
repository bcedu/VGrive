using App.Controllers;
using Gtk;
using App.Widgets;

namespace App.Views {


    public class ViewConf : AppView, VBox {
        private Gtk.Button conf_button;

        public ViewConf (AppController controler) {
            conf_button = new Gtk.Button.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
            conf_button.tooltip_text = _("Configuration");
            controler.window.headerbar.pack_end(conf_button);
            this.show_all();
        }

        public string get_id() {
            return "conf_view";
        }

        public void connect_signals(AppController controler) {
            conf_button.clicked.connect(() => {
                if (controler.view_controller.get_current_view ().get_id () != "view3") {
                    controler.add_registered_view ("view3");
                }
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.back_button.set_label (_("Save"));
            conf_button.visible = false;
        }

        public void update_view_on_hide(AppController controler) {
                conf_button.visible = true;
        }

    }

}

