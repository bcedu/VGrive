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
using App.Controllers;

namespace App {

    public struct DriveRequestResult {
        public int code;
        public string message;
    }

    /**
     * The {@code AppController} class.
     *
     * @since 1.0.0
     */
    public class VGriveClient {


        private AppController app_controller;
        // API realted attributes
        public string access_token = "";
        public string refresh_token = "";
        public string client_id = "8532198801-7heceng058ouc4mj495a321s8s96b0e5.apps.googleusercontent.com";
        public string client_secret = "WPZsVURl5HcFD_7DP_jIP24z";
        public string scope = "https://www.googleapis.com/auth/drive";
        public string api_uri = "https://www.googleapis.com/drive/v3";
        public string upload_uri = "https://www.googleapis.com/upload/drive/v3";
        public string redirect = "urn:ietf:wg:oauth:2.0:oob";
        // SYNC related sttributes
        public string main_path;
        public string trash_path;
        public bool syncing = false;

        public VGriveClient (AppController? controler=null, owned string? main_path=null, owned string? trash_path=null) {
            this.app_controller = controler;

            if (main_path == null) {
                main_path = Environment.get_home_dir()+"/vGrive";
            }
            this.main_path = main_path;
            File file = File.new_for_path(main_path);
            if (!file.query_exists()) {
                file.make_directory();
            }

            if (trash_path == null) {
                trash_path = Environment.get_home_dir()+"/vGrive/.trash";
            }
            this.trash_path = trash_path;
            file = File.new_for_path(trash_path);
            if (!file.query_exists()) {
                file.make_directory();
            }
        }

        public string get_auth_uri() {
            return "https://accounts.google.com/o/oauth2/v2/auth?scope=%s&access_type=offline&redirect_uri=%s&response_type=code&client_id=%s".printf(scope, redirect, client_id);
        }

        public void log_message(string msg) {
            if (this.app_controller != null) {
                this.app_controller.log_message(msg);
            }
        }
////////////////////////////////////////////////////////////////////////////////
/*
 *
 * SYNC RELATED METHODS
 *
*/
////////////////////////////////////////////////////////////////////////////////

    public void start_syncing() {
        // Starts the process to sync files.
        // If the sync was already started (`syncing` is True), nothing is done.
        // The attributes `access_token` and `refresh_token` must be set with `request_credentials` or `load_local_credentials`
        if (!this.syncing && this.has_credentials ()) {
            this.syncing = true;
            this.log_message("Start syncing files on %s".printf(this.main_path));
            File maindir = File.new_for_path(this.main_path);
            if (!maindir.query_exists()) {
                maindir.make_directory();
                this.log_message("Directory created: %s".printf(this.main_path));
            }
            File trashdir = File.new_for_path(this.trash_path);
            if (!trashdir.query_exists()) trashdir.make_directory();
            // Start sync
            Thread<int> thread = new Thread<int>.try ("Sync thread", this.sync_files);
        }
    }

    public int sync_files() {
        // Check if we have changes in files and sync them
        this.log_message("Syncing...");
/*
        if (this.library == null) {
            this.library = this.create_library();
            // Download all files that doesn't exist locally
            this.download_remote_files(this.sync_dir, "");
            // Upload all files that doesn't exist in remote
            this.upload_local_files(this.sync_dir, "root");
            // Initial sync is done
            this.save_library();
            this.app.client_status_log("Everything is up to date :)");
        }

        // Start watching for changes in local
        this.watch_local_changes();

        // Start watching for changes in remote
        this.watch_remote_changes();
*/
        return 1;
    }

////////////////////////////////////////////////////////////////////////////////
/*
 *
 * CREDENTIALS RELATED METHODS
 *
*/
////////////////////////////////////////////////////////////////////////////////


        public DriveRequestResult request_credentials(string drive_code) {
            // Request credentials to Drive API.
            // If success, returns code 1 and message=credentials.
            // Else returns code=-1 ans message=error_description
            string result = "";
            var session = new Soup.Session ();
            string uri = "https://www.googleapis.com/oauth2/v4/token?grant_type=authorization_code&code=%s&client_id=%s&client_secret=%s&redirect_uri=%s".printf(drive_code, client_id, client_secret, redirect);
            var message = new Soup.Message ("POST", uri);
            message.set_request("", Soup.MemoryUse.COPY, "{}".data);
            session.send_message (message);
            string res = (string) message.response_body.data;
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            // Check if we had an error
            if (json_response.get_member("error") != null) {
                result = "Error trying to get acces token: \n%s\n".printf(res);
                stdout.printf(result);
                DriveRequestResult aux = DriveRequestResult() {
                    code = -1,
                    message = result
                };
                return aux;
            }else {
                DriveRequestResult aux = DriveRequestResult() {
                    code = 1,
                    message = res
                };
                return aux;
            }
        }

        public DriveRequestResult request_and_set_credentials(string drive_code, bool store_credentials=true, owned string? credentials_file_path=null) {
            // Request credentials to Drive API.
            // If success, returns code 1 and message=credentials and the attributes `access_token` and `refresh_token` are set. Also if `store_credentials` is True, the credentials are written in the `credentials_file_path`
            // Else returns code=-1 ans message=error_description
            var res = this.request_credentials (drive_code);
            if (res.code == 1) {
                var parser = new Json.Parser ();
                parser.load_from_data (res.message, -1);
                Json.Object json_response = parser.get_root().get_object();
                // Check if we had an error
                if (json_response.get_member("error") != null) {
                    string result = "Error trying to get acces token: \n%s\n".printf(res.message);
                    stdout.printf(result);
                    DriveRequestResult aux = DriveRequestResult() {
                        code = -1,
                        message = result
                    };
                    return aux;
                }else {
                    this.access_token = json_response.get_string_member("access_token");
                    this.refresh_token = json_response.get_string_member("refresh_token");
                    if (store_credentials) {
                        File file;
                        if (credentials_file_path == null) {
                            credentials_file_path = Environment.get_home_dir()+"/.vgrive/credentials.json";
                            string dirpath = Environment.get_home_dir()+"/.vgrive";
                            file = File.new_for_path(dirpath);
                            if (!file.query_exists()) {
                                file.make_directory();
                            }
                        }
                        // store them in path
                        file = File.new_for_path(credentials_file_path);
                        if (file.query_exists()) {
                            stdout.printf("Warning: file %s already exists and it will be deleted.", credentials_file_path);
                        try {
                            file.delete ();
                        } catch (Error e) {
                            print ("Error: %s\n", e.message);
                        }
                        }
                        file.create(FileCreateFlags.NONE);
                        FileIOStream io = file.open_readwrite();
                        io.seek (0, SeekType.END);
                        var writer = new DataOutputStream(io.output_stream);
                        writer.put_string(res.message);
                    }
                    return res;
                }
            } else {
                return res;
            }
        }

        public bool has_local_credentials(owned string? path=null) {
            // Check if the there are local credentials.
            // They are search in the path definded in `path`, by default "~/.vgrive/credentials.json"
            if (path == null) path = Environment.get_home_dir()+"/.vgrive/credentials.json";
            File file = File.new_for_path(path);
            if (!file.query_exists()) return false;
            else return true;
        }

        public int load_local_credentials(owned string? path=null) {
            // Loads local credentials.
            // They are search in the path definded in `path`, by default "~/.vgrive/credentials.json"
            // If they are loaded succesfully the attributes `access_token` and `refresh_token` are set and `1` is returned to indicate de success.
            // Else `-1` is returned
            if (path == null) path = Environment.get_home_dir()+"/.vgrive/credentials.json";
            if (!this.has_local_credentials (path)) {
                return -1;
            }
            string res = "";
            File file = File.new_for_path(path);
            DataInputStream reader = new DataInputStream(file.read());
            string line;
            while ((line=reader.read_line(null)) != null) res = res.concat(line);
            // parse credentials to get token and refresh token
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object root_obj = parser.get_root().get_object();
            this.access_token = root_obj.get_string_member("access_token");
            this.refresh_token = root_obj.get_string_member("refresh_token");
            return 1;
        }

        public bool has_credentials () {
            // Returns True if attribures `access_token` and `refresh_token` are set.
            // Else False
            return this.access_token != "" && this.refresh_token != "";
        }
    }
}
