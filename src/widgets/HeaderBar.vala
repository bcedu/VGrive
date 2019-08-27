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

        /**
         * Constructs a new {@code AppHeaderBar} object.
         *
         * @see App.Configs.Properties
         * @see icon_settings
         */
        public AppHeaderBar (bool flat_style) {
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

    }
}
