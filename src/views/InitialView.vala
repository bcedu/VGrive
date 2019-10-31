using App.Controllers;
using Gtk;
using App.Configs;

namespace App.Views {

    public class InitialView : AppView, VBox {

        private Granite.Widgets.Welcome welcome;
        private int open_index;

        public InitialView (AppController controler) {
            welcome = new Granite.Widgets.Welcome (_("Welcome"), _("Start syncing your Google Drive files"));
            this.pack_start (welcome, true, true, 0);

            welcome.margin_start = welcome.margin_end = 6;
            open_index = welcome.append ("next", _("Log in"), _("Sync your files"));
            this.show_all();
        }

        public string get_id() {
            return "init";
        }

        public void connect_signals (AppController controler) {
            // Connect welcome button activated
            this.welcome.activated.connect ((index) => {
                if (index == open_index) {
                    controler.add_registered_view("login_view");
                }
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.set_title (Constants.APP_NAME);
        }

        public void update_view_on_hide(AppController controler) {
            this.update_view(controler);
        }

    }

}
