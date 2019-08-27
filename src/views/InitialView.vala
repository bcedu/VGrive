using App.Controllers;
using Gtk;

namespace App.Views {

    public class InitialView : AppView, VBox {

        private Granite.Widgets.Welcome welcome;
        private int open_index;

        public InitialView (AppController controler) {
            welcome = new Granite.Widgets.Welcome (_("Welcome"), _("Start syncing your Google Drive files"));
            this.set_center_widget (welcome);

            welcome.margin_start = welcome.margin_end = 6;
            open_index = welcome.append ("next", _("Log in"), _("Sync your files"));

            this.get_style_context().add_class ("app_view");
            this.show_all();
        }

        public string get_id() {
            return "init";
        }

        public void connect_signals (AppController controler) {
            // Connect welcome button activated
            this.welcome.activated.connect ((index) => {
                if (index == open_index) {
                    controler.view_controller.add_registered_view("login_view");
                    controler.update_window_view ();
                }
            });
        }

        public void update_view(AppController controler) {

        }

        public void update_view_on_hide(AppController controler) {
            this.update_view(controler);
        }

    }

}
