/*
* Copyright (C) 2018  Eduard Berloso Clarà <eduard.bc.95@gmail.com>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero General Public License for more details.
*
* You should have received a copy of the GNU Affero General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/
using App.Configs;
using App.Widgets;
using App.Views;

namespace App.Controllers {

    /**
     * The {@code AppController} class.
     *
     * @since 1.0.0
     */
    public class ViewController {

        private Gee.ArrayQueue<AppView> views_stack;
        private Gee.HashMap<string, AppView> registered_views;
        private AppController app_controller;

        public ViewController (AppController controler) {
            this.app_controller = controler;
            this.views_stack = new Gee.ArrayQueue<AppView>();
            this.registered_views = new Gee.HashMap<string, AppView>();
            // REGISTER ALL VIEWS
            // initial view
            InitialView initv = new InitialView(controler);
            this.register_view (initv);
            // second view
            SyncView view2 = new SyncView(controler);
            this.register_view (view2);
            // login view
            LogInView view3 = new LogInView(controler);
            this.register_view (view3);
            // conf view
            ViewConf view4 = new ViewConf(controler);
            this.register_view (view4);
            // ADD INITIAL VIEW TO STACK
            this.add_view (initv);
        }

        public AppView get_current_view() {
            var aux = views_stack.peek_tail ();
            return aux;
        }

        public AppView get_previous_view() {
            if (this.views_stack.size > 1) {
                var aux = views_stack.poll_tail ();
                aux.update_view_on_hide (app_controller);
                return aux;
            } else {
                return this.get_current_view ();
            }
        }

        public void add_view(AppView new_view) {
            if (new_view.get_id() != get_current_view().get_id()) {
                this.views_stack.add (new_view);
                this.update_views ();
            }
        }

        public void set_view(AppView new_view) {
            if (new_view.get_id() != get_current_view().get_id()) {
                this.views_stack = new Gee.ArrayQueue<AppView>();
                this.views_stack.add (new_view);
                this.update_views ();
            }
        }

        public void add_registered_view(string identifier) {
            this.add_view (registered_views[identifier]);
        }

        public void set_registered_view(string identifier) {
            this.set_view (registered_views[identifier]);
            this.update_views ();
        }

        public void register_view(AppView new_view) {
            this.registered_views.set(new_view.get_id (), new_view);
        }

        public void update_views() {
            foreach (AppView v in views_stack) {
                v.update_view (app_controller);
            }
            if (this.views_stack.size > 1) {
                app_controller.window.headerbar.back_button.visible = true;
            } else {
                app_controller.window.headerbar.back_button.visible = false;
            }
        }

        public void connect_signals() {
            // Signals for each view
            var it = registered_views.map_iterator ();
            for (var has_next = it.next (); has_next; has_next = it.next ()) {
                it.get_value().connect_signals(app_controller);
            }
        }

    }
}
