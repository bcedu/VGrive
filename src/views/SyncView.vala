using App.Controllers;
using Gtk;
namespace App.Views {

    public class SyncView : AppView, VBox {


        public SyncView (AppController controler) {
            this.pack_start (new Label("**SOC LA VISTA 2**"), true, true, 0);
            this.get_style_context().add_class ("app_view");
            this.show_all();
        }

        public string get_id() {
            return "sync_view";
        }

        public void connect_signals(AppController controler) {
            controler.log_event.connect ((msg) => {
                print("LOG: "+msg);
                print("\n");
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.back_button.set_label ("Torna al inici");
            controler.vgrive.start_syncing();
        }


        public void update_view_on_hide(AppController controler) {
            print("view2 says: Adeu!\n");
        }

    }

}
