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

public class Main {

    private static bool minimized = false;
    private static bool windowed = false;
    private static bool advanced_view = false;
    private static bool auto_sync = false;

    private const GLib.OptionEntry[] options = {
        { "minimized", 'm', 0, OptionArg.NONE, ref minimized, "Start app minimized. If not informed it will start as saved in the configuration.", null },
        { "windowed", 'w', 0, OptionArg.NONE, ref windowed, "Start app showing the window. It has more priority than the --minimized option. If not informed it will start as saved in the configuration.", null },
        { "auto-sync", 's', 0, OptionArg.NONE, ref auto_sync, "Start sync process once app is started. If not informed it will start as saved in the configuration.", null },
        { "advanced-view", 'a', 0, OptionArg.NONE, ref advanced_view, "Start app with advanced view screen. If not informed it will start as saved in the configuration.", null },
        // list terminator
        { null }
	};

    /**
     * Main method. Responsible for starting the {@code Application} class.
     *
     * @see App.Application
     * @return {@code int}
     * @since 1.0.0
     */
    public static int main (string [] args) {
        try {
            var opt_context = new OptionContext ("VGrive" +" "+ "Options");
            opt_context.set_help_enabled (true);
            opt_context.add_main_entries (options, null);
            opt_context.parse (ref args);
        } catch (OptionError e) {
            printerr ("error: %s\n", e.message);
            printerr ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
            return 1;
        }

        var saved_state = AppSettings.get_default();
        if (minimized) {
            saved_state.start_minimized = (int)minimized;
        }
        if (windowed) {
            saved_state.start_minimized = (int)(!windowed);
        }
        if (auto_sync) {
            saved_state.auto_sync = (int)auto_sync;
        }
        if (advanced_view) {
            saved_state.advanced_view = advanced_view;
        }

        var app = new App.Application ();
        app.run (args);
        return 0;
    }

}
