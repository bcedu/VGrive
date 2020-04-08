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

namespace App.Widgets {

    /**
     * The {@code HeaderBar} class is responsible for displaying top bar. Similar to a horizontal box.
     *
     * @see Gtk.HeaderBar
     * @since 1.0.0
     */
    public class AppHeaderBar : Gtk.HeaderBar {

        public Gtk.Button back_button;
        private AppWindow window;

        /**
         * Constructs a new {@code AppHeaderBar} object.
         *
         * @see App.Configs.Properties
         * @see icon_settings
         */
        public AppHeaderBar (bool flat_style, AppWindow w) {
            this.window = w;
            this.set_title (Constants.APP_NAME);
            if (flat_style) this.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            this.show_close_button = true;
            this.has_subtitle = false;
            // Create and config back_button
            back_button = new Gtk.Button ();
            back_button.label = _("Back");
            back_button.get_style_context ().add_class ("back-button");
            this.pack_start(back_button);
            back_button.visible = false;
            back_button.no_show_all = true;
        }

        public void add_dark_mode() {
            var gtk_settings = Gtk.Settings.get_default ();
            var mode_switch = new Granite.ModeSwitch.from_icon_name (
                "display-brightness-symbolic",
                "weather-clear-night-symbolic"
            );
            mode_switch.margin_end = 6;
            mode_switch.primary_icon_tooltip_text = _("Light background");
            mode_switch.secondary_icon_tooltip_text = _("Dark background");
            mode_switch.valign = Gtk.Align.CENTER;

            mode_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");

            if (Application.settings.get_boolean("dark-mode")) {
                this.window.get_style_context ().add_class ("dark");
            }
            Application.settings.bind ("dark-mode", mode_switch, "active", SettingsBindFlags.DEFAULT);

            this.pack_end(mode_switch);
            mode_switch.notify["active"].connect (() => {
                if (gtk_settings.gtk_application_prefer_dark_theme) {
                    this.window.get_style_context ().add_class ("dark");
                } else {
                    this.window.get_style_context ().remove_class ("dark");
                }
            });
        }

    }
}
