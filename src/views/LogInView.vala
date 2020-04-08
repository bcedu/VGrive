using App.Controllers;
using Gtk;
using App.Configs;
namespace App.Views {

    public class LogInView : AppView, VBox {

        private Gtk.Entry grive_code;
        private Gtk.Button continue_button;
        private Gtk.Stack stack;
        private Gtk.Button open_w;
        private Gtk.Switch auto_sync;
        private Gtk.Label selected_folder;
        private Gtk.Button change_folder;
        private bool folder_changed = false;

        public LogInView (AppController controler) {
            Gtk.Box mainbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 30);
            // Create elements to put inside the box
            Gtk.Box step1_box = this.build_step1(controler);
            Gtk.Box step2_box = this.build_step2(controler);
            Gtk.Box step3_box = this.build_step3(controler);

            stack = new Gtk.Stack ();
            stack.expand = true;
            stack.valign = stack.halign = Gtk.Align.CENTER;
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            stack.add_titled (step1_box, "step1_box", _("Give permissions to VGrive"));
            stack.child_set_property (step1_box, "icon-name", "media-record-symbolic");
            stack.add_titled (step2_box, "step2_box", _("Copy code"));
            stack.child_set_property (step2_box, "icon-name", "media-record-symbolic");
            stack.add_titled (step3_box, "step3_box", _("Finish"));
            stack.child_set_property (step3_box, "icon-name", "media-record-symbolic");
            stack.set_homogeneous (false);

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.set_stack (stack);

            var action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            action_area.add (stack_switcher);
            action_area.set_child_non_homogeneous (stack_switcher, true);
            action_area.margin_start = 10;
            action_area.margin_end = 10;
            action_area.expand = true;
            action_area.spacing = 6;
            action_area.valign = Gtk.Align.END;
            action_area.layout_style = Gtk.ButtonBoxStyle.EDGE;

            mainbox.pack_start (stack, true, true, 0);
            mainbox.pack_start (action_area, false, false, 0);

		    this.set_center_widget (mainbox);
            this.show_all();
        }

        private Gtk.Box build_step1(AppController controler) {
            Gtk.Label aux = new Gtk.Label ("");
            open_w = new Gtk.Button.with_label (_("Give permission to VGrive"));
            open_w.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            var box = new Gtk.Box(Orientation.VERTICAL, 10);
            box.pack_start(aux, false, false, 0);
            box.set_center_widget(open_w);
            return box;
        }

        private Gtk.Box build_step2(AppController controler) {
            Gtk.Label lb3 = new Gtk.Label (_("Copy the code from the browser here:"));
		    lb3.set_use_markup (true);
		    lb3.set_line_wrap (true);
            grive_code = new Gtk.Entry ();
            var box = new Gtk.Box(Orientation.VERTICAL, 10);
            box.pack_start(lb3, false, false, 0);
            box.pack_start(grive_code, false, false, 0);
            return box;
        }

        private Gtk.Box build_step3(AppController controler) {
            Gtk.Box baux, mainbox, baux2;
            mainbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);

            Gtk.Label laux;
            laux = this.create_heading(_("Preferences"));
            mainbox.pack_start(laux, false, false, 0);

            baux = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            laux = this.create_label(_("Begin sync when app is started:"));
            baux.pack_start(laux, false, false, 0);
            auto_sync = this.create_switch();
            if (Application.settings.get_int("auto-sync") == 1) auto_sync.set_active (true);
            else auto_sync.set_active (false);
            baux.pack_start(auto_sync, false, false, 0);
            mainbox.pack_start(baux, false, false, 0);

            baux = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            laux = this.create_label(_("vGrive folder:"));
            baux.pack_start(laux, false, false, 0);
            selected_folder = this.create_label(Application.settings.get_string("sync-folder"), 0, Gtk.Align.START);
            change_folder = this.create_button(_("Change folder"));
            baux2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            baux2.halign = Gtk.Align.START;
            baux2.pack_start(selected_folder, false, false, 0);
            baux2.pack_start(change_folder, false, false, 0);
            baux.pack_start(baux2, false, false, 0);
            mainbox.pack_start(baux, false, false, 0);

            continue_button = new Gtk.Button.with_label (_("Continue"));
            continue_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            baux = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            baux.set_center_widget(continue_button);
            mainbox.pack_start(baux, false, false, 10);

            return mainbox;
        }

        public string get_id() {
            return "login_view";
        }

        public void connect_signals(AppController controler) {
            open_w.clicked.connect (() => {
                Gtk.show_uri_on_window (controler.window, controler.vgrive.get_auth_uri (), 10);
                stack.set_visible_child_name ("step2_box");
		    });
            grive_code.activate.connect (() => {
                stack.set_visible_child_name ("step3_box");
            });
            grive_code.paste_clipboard.connect (() => {
                stack.set_visible_child_name ("step3_box");
            });
            continue_button.clicked.connect (() => {
                if (auto_sync.get_active ()) Application.settings.set_int("auto-sync", 1);
                else  Application.settings.set_int("auto-sync", 0);
                if (this.folder_changed) {
                    folder_changed = false;
                    Application.settings.set_string("sync-folder", this.selected_folder.get_label());
                    controler.vgrive.change_main_path(Application.settings.get_string("sync-folder"));
                }
                var res = controler.vgrive.request_and_set_credentials(grive_code.get_text());
                this.update_view_on_hide (controler);
		    });
		    change_folder.clicked.connect(() => {
                this.build_select_sync_folder (controler);
            });
        }

        public void update_view(AppController controler) {
            controler.window.headerbar.set_title (Constants.APP_NAME+ _(": Log In"));
            controler.window.headerbar.back_button.set_label (_("Back"));
            auto_sync.active = (bool) Application.settings.get_int ("auto-sync");
            selected_folder.label = Application.settings.get_string ("sync-folder");
        }

        public void update_view_on_hide(AppController controler) {
            if (!controler.vgrive.has_credentials ()) controler.set_registered_view ("init");
            else  controler.set_registered_view ("sync_view");
            grive_code.set_text("");
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

    }

}
