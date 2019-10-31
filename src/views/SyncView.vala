using App.Controllers;
using Gtk;
using App.Configs;
namespace App.Views {

    public class SyncView : AppView, VBox {

        private Gtk.TextView log_text;
        private Gtk.Button start_stop_btn;
        private bool initial_action = true;
        private Gtk.Box log_box;
        private Gtk.Box simple_view_box;
        private Gtk.Label status_lb;
        private Gtk.Spinner spinner;
        private Gtk.CheckButton change_view;
        private Gtk.Label last_log;

        public SyncView (AppController controler) {
            Gtk.Grid mainbox = new Gtk.Grid ();
            mainbox.margin = 12;
            mainbox.column_spacing = 12;
            mainbox.row_spacing = 6;
            // Create elements to put inside the box
            //Gtk.Box title_box = this.build_title(controler);
            log_box = this.build_log(controler);
            simple_view_box = this.build_simple_view_box(controler);
            Gtk.Box start_stop_box = this.build_start_stop_buttons(controler);
            // Add themto the box
            //mainbox.pack_start (title_box, false, false, 0);
            mainbox.attach (simple_view_box, 0, 0, 20, 2);
            mainbox.attach (log_box, 0, 0, 20, 2);
            mainbox.attach (start_stop_box, 10, 2, 1, 1);
		    this.pack_start (mainbox, true, true, 0);
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
            box.expand = true;
            return box;
        }

        private Gtk.Box build_simple_view_box(AppController controler) {
            status_lb = new Gtk.Label (_("Not syncing"));
            status_lb.get_style_context().add_class ("status_lb");
            spinner = new Gtk.Spinner ();
            spinner.get_style_context().add_class ("spinner");
            if (controler.vgrive.is_syncing ()) {
                spinner.start ();
                status_lb.set_label (_("Syncing"));
            }
            this.last_log = new Gtk.Label ("");
            var box = new Gtk.Box(Orientation.VERTICAL, 0);
            box.pack_start(status_lb, false, false, 20);
            box.pack_start(spinner, false, false, 10);
            box.pack_start(last_log, false, false, 10);
            box.get_style_context().add_class ("log_box");
            box.expand = true;
            var boxc = new Gtk.Box(Orientation.VERTICAL, 0);
            boxc.set_center_widget (box);
            return boxc;
        }

        private Gtk.Box build_title(AppController controler) {
            Gtk.Label title_lbl = new Gtk.Label(_("Google Drive Sync"));
            title_lbl.get_style_context().add_class ("sync_title");
            var box = new Gtk.Box(Orientation.VERTICAL, 0);
		    box.pack_start (title_lbl, false, false, 0);
            return box;
        }

        private Gtk.Box build_start_stop_buttons(AppController controler) {
            this.change_view = new CheckButton.with_label (_("Advanced View"));

            this.start_stop_btn = new Gtk.Button.with_label (_("Stop"));
            this.start_stop_btn.get_style_context().add_class ("redbutton");
            var box = new Gtk.Box(Orientation.VERTICAL, 10);
		    box.pack_start (start_stop_btn, false, false, 0);
		    box.pack_start (change_view, false, false, 0);
            box.expand = false;
            var boxc = new Gtk.Box(Orientation.VERTICAL, 0);
            boxc.set_center_widget (box);
            boxc.expand = false;
            return boxc;
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
                this.last_log.set_text (msg);
            });
            this.start_stop_btn.clicked.connect (() => {
                if (controler.vgrive.is_syncing ()) {
                    controler.vgrive.stop_syncing ();
                    this.start_stop_btn.get_style_context().remove_class ("redbutton");
                    this.start_stop_btn.get_style_context().add_class ("greenbutton");
                    this.start_stop_btn.set_label (_("Start"));
                    this.status_lb.set_label (_("Not syncing"));
                    this.spinner.stop ();
                } else {
                    controler.vgrive.start_syncing ();
                    this.start_stop_btn.get_style_context().remove_class ("greenbutton");
                    this.start_stop_btn.get_style_context().add_class ("redbutton");
                    this.start_stop_btn.set_label (_("Stop"));
                    this.status_lb.set_label (_("Syncing"));
                    this.spinner.start ();
                }
            });
            this.change_view.clicked.connect(() => {
                this.switch_log_views (controler);
            });
        }

        public void update_view(AppController controler) {
            var saved_state = AppSettings.get_default();
            if (initial_action) {
                initial_action = false;
                if (saved_state.auto_sync == 1 && !controler.vgrive.is_syncing ()) {
                    controler.vgrive.start_syncing ();
                    this.start_stop_btn.get_style_context().remove_class ("greenbutton");
                    this.start_stop_btn.get_style_context().add_class ("redbutton");
                    this.start_stop_btn.set_label (_("Stop"));
                    this.status_lb.set_label (_("Syncing"));
                    this.spinner.start ();
                } else {
                    controler.log_message (_("Sync is stopped. Press start to begin."));
                }
            }
            controler.window.headerbar.set_title (Constants.APP_NAME);
            if (!controler.vgrive.is_syncing ()) {
                this.start_stop_btn.get_style_context().remove_class ("redbutton");
                this.start_stop_btn.get_style_context().add_class ("greenbutton");
                this.start_stop_btn.set_label (_("Start"));
            } else {
                this.start_stop_btn.get_style_context().remove_class ("greenbutton");
                this.start_stop_btn.get_style_context().add_class ("redbutton");
                this.start_stop_btn.set_label (_("Stop"));
            }
            this.update_log_views (controler);
        }

        private void switch_log_views(AppController controler) {
            if (this.log_box.visible && this.simple_view_box.visible) {
                this.log_box.visible = false;
                this.simple_view_box.visible = true;
            }else if (this.log_box.visible) {
                this.log_box.visible = false;
                this.simple_view_box.visible = true;
            }else {
                this.log_box.visible = true;
                this.simple_view_box.visible = false;
            }
        }

        private void update_log_views(AppController controler) {
            if (this.change_view.get_active ()) {
                this.log_box.visible = true;
                this.simple_view_box.visible = false;
            }else {
                this.log_box.visible = false;
                this.simple_view_box.visible = true;
            }
        }

        public void update_view_on_hide(AppController controler) {
        }

    }

}
