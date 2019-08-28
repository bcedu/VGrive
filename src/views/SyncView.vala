using App.Controllers;
using Gtk;
using App.Configs;
namespace App.Views {

    public class SyncView : AppView, VBox {

        private Gtk.TextView log_text;
        private Gtk.Button start_stop_btn;

        public SyncView (AppController controler) {
            Gtk.Box mainbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            // Create elements to put inside the box
            //Gtk.Box title_box = this.build_title(controler);
            Gtk.Box log_box = this.build_log(controler);
            Gtk.Box start_stop_box = this.build_start_stop_buttons(controler);
            // Add themto the box
            //mainbox.pack_start (title_box, false, false, 0);
            mainbox.pack_start (log_box, true, true, 0);
		    mainbox.pack_start (start_stop_box, false, false, 0);
		    this.pack_start (mainbox, true, true, 0);
            this.get_style_context().add_class ("app_view");
            this.show_all();
        }

        public string get_id() {
            return "sync_view";
        }

        private Gtk.Box build_log(AppController controler) {
            log_text = new Gtk.TextView ();
            log_text.create_buffer ();
            log_text.set_editable (false);
            log_text.get_style_context().add_class ("log_text");
            var box = new Gtk.Box(Orientation.VERTICAL, 0);
            var scroll_w = new Gtk.ScrolledWindow (null, null);
            scroll_w.add (log_text);
            box.pack_start(scroll_w, true, true, 0);
            box.get_style_context().add_class ("log_box");
            return box;
        }

        private Gtk.Box build_title(AppController controler) {
            Gtk.Label title_lbl = new Gtk.Label(_("Google Drive Sync"));
            title_lbl.get_style_context().add_class ("sync_title");
            var box = new Gtk.Box(Orientation.VERTICAL, 0);
		    box.pack_start (title_lbl, false, false, 0);
            return box;
        }

        private Gtk.Box build_start_stop_buttons(AppController controler) {
            this.start_stop_btn = new Gtk.Button.with_label (_("Stop"));
            this.start_stop_btn.get_style_context().add_class ("redbutton");
            var box = new Gtk.Box(Orientation.VERTICAL, 0);
		    box.pack_start (start_stop_btn, false, false, 0);
            return box;
        }

        public void connect_signals(AppController controler) {
            controler.log_event.connect ((msg) => {
                // Log to console
                print("LOG: "+msg);
                print("\n");
                // Log to TextView
                Gtk.TextBuffer buffer = log_text.get_buffer ();
                Gtk.TextIter iter;
                buffer.get_start_iter (out iter);
                buffer.insert (ref iter, msg+"\n", -1);
            });
            this.start_stop_btn.clicked.connect (() => {
                if (controler.vgrive.is_syncing ()) {
                    controler.vgrive.stop_syncing ();
                    this.start_stop_btn.get_style_context().remove_class ("redbutton");
                    this.start_stop_btn.get_style_context().add_class ("greenbutton");
                    this.start_stop_btn.set_label (_("Start"));
                } else {
                    controler.vgrive.start_syncing ();
                    this.start_stop_btn.get_style_context().remove_class ("greenbutton");
                    this.start_stop_btn.get_style_context().add_class ("redbutton");
                    this.start_stop_btn.set_label (_("Stop"));
                }
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.set_title (Constants.APP_NAME+ _(": Syncing with Google Drive"));
            if (!controler.vgrive.is_syncing ()) {
                this.start_stop_btn.get_style_context().remove_class ("redbutton");
                this.start_stop_btn.get_style_context().add_class ("greenbutton");
                this.start_stop_btn.set_label (_("Start"));
            } else {
                this.start_stop_btn.get_style_context().remove_class ("greenbutton");
                this.start_stop_btn.get_style_context().add_class ("redbutton");
                this.start_stop_btn.set_label (_("Stop"));
            }
        }


        public void update_view_on_hide(AppController controler) {
            print("view2 says: Adeu!\n");
        }

    }

}
