using App.Controllers;
using Gtk;
namespace App.Views {

    public class LogInView : AppView, VBox {

        private Gtk.Entry grive_code;
        private Gtk.Button continue_button;

        public LogInView (AppController controler) {
            Gtk.Box mainbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 30);
            // Create elements to put inside the box
            Gtk.Box step1_box = this.build_step1(controler);
            Gtk.Box step2_box = this.build_step2(controler);
            Gtk.Box step3_box = this.build_step3(controler);
            // Add themto the box
            mainbox.pack_start (step1_box, false, false, 0);
		    mainbox.pack_start (step2_box, false, false, 0);
		    mainbox.pack_start (step3_box, false, false, 0);
		    this.set_center_widget (mainbox);
            this.get_style_context().add_class ("app_view");
            this.show_all();
        }

        private Gtk.Box build_step1(AppController controler) {
            Gtk.Label lb1 = new Gtk.Label (_("1. Click in the following link:"));
            lb1.set_use_markup (true);
            lb1.set_line_wrap (true);
            Gtk.LinkButton lb2 = new Gtk.LinkButton.with_label (controler.vgrive.get_auth_uri (), _("Give acces to eGrive"));
            var box = new Gtk.Box(Orientation.VERTICAL, 10);
            box.pack_start(lb1, false, false, 0);
            box.pack_start(lb2, false, false, 0);
            return box;
        }

        private Gtk.Box build_step2(AppController controler) {
            Gtk.Label lb3 = new Gtk.Label (_("2. Copy the code from the browser and paste it here:"));
		    lb3.set_use_markup (true);
		    lb3.set_line_wrap (true);
            grive_code = new Gtk.Entry ();
            var box = new Gtk.Box(Orientation.VERTICAL, 10);
            box.pack_start(lb3, false, false, 0);
            box.pack_start(grive_code, false, false, 0);
            return box;
        }

        private Gtk.Box build_step3(AppController controler) {
            Gtk.Label lb4 = new Gtk.Label (_("3. Click \"Continue\" and you are done :)"));
		    lb4.set_use_markup (true);
		    lb4.set_line_wrap (true);
            continue_button = new Gtk.Button.with_label (_("Continue"));
            var box = new Gtk.Box(Orientation.VERTICAL, 10);
            box.pack_start(lb4, false, false, 0);
            box.pack_end(continue_button, false, false, 0);
            return box;
        }

        public string get_id() {
            return "login_view";
        }

        public void connect_signals(AppController controler) {
            continue_button.clicked.connect (() => {
                var res = controler.vgrive.request_credentials(grive_code.get_text());
                this.update_view_on_hide (controler);
		    });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.back_button.set_label ("Torna al inici");
        }

        public void update_view_on_hide(AppController controler) {
            if (controler.vgrive.access_token == "") controler.set_registered_view ("init");
            else  controler.set_registered_view ("sync_view");
        }

    }

}
