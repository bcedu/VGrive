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

namespace App.Configs {

    /**
     * The {@code Constants} class is responsible for defining all
     * the constants used in the application.
     *
     * @since 1.0.0
     */
    public class Constants {
        public abstract const string ID = "com.github.bcedu.vgrive";
        public abstract const string APP_ICON = "com.github.bcedu.vgrive";
        public abstract const string APP_NAME = _("vGrive");
        public abstract const string LAUNCHER_ID = "com.github.bcedu.vgrive.desktop";
        public const string FILES_DBUS_ID = "org.freedesktop.FileManager1";
        public const string FILES_DBUS_PATH = "/org/freedesktop/FileManager1";
    }
}
