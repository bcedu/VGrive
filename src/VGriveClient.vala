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
        public string credentials = "";
        public string access_token = "";
        public string refresh_token = "";
        public string client_id = "8532198801-7heceng058ouc4mj495a321s8s96b0e5.apps.googleusercontent.com";
        public string client_secret = "WPZsVURl5HcFD_7DP_jIP24z";
        public string scope = "https://www.googleapis.com/auth/drive";
        public string api_uri = "https://www.googleapis.com/drive/v3";
        public string upload_uri = "https://www.googleapis.com/upload/drive/v3";
        public string redirect = "urn:ietf:wg:oauth:2.0:oob";


        public VGriveClient (AppController controler) {
            this.app_controller = controler;
        }

        public string get_auth_uri() {
            return "https://accounts.google.com/o/oauth2/v2/auth?scope=%s&access_type=offline&redirect_uri=%s&response_type=code&client_id=%s".printf(scope, redirect, client_id);
        }

        public DriveRequestResult request_credentials(string drive_code) {
            string result = "";
            string dirpath = Environment.get_home_dir()+"/.vgrive";
            File file = File.new_for_path(dirpath);
            if (!file.query_exists()) {
                file.make_directory();
            }
            string path = Environment.get_home_dir()+"/.vgrive/credentials.json";
            var session = new Soup.Session ();
            string uri = "https://www.googleapis.com/oauth2/v4/token?grant_type=authorization_code&code=%s&client_id=%s&client_secret=%s&redirect_uri=%s".printf(drive_code, client_id, client_secret, redirect);
            var message = new Soup.Message ("POST", uri);
            message.set_request("", Soup.MemoryUse.COPY, "{}".data);
            session.send_message (message);
            string res = (string) message.response_body.data;
            print(res);
            print("\n");
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
                access_token = json_response.get_string_member("access_token");
                refresh_token = json_response.get_string_member("refresh_token");
                // store them in path
                file = File.new_for_path(path);
                if (file.query_exists()) {
                    stdout.printf("Warning: file %s already exists and it will be deleted.", path);
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
                writer.put_string(res);
                DriveRequestResult aux = DriveRequestResult() {
                    code = 1,
                    message = _("Success")
                };
                return aux;
            }
        }

        public bool has_local_credentials() {
            string path = Environment.get_home_dir()+"/.vgrive/credentials.json";
            File file = File.new_for_path(path);
            if (!file.query_exists()) return false;
            else return true;
        }

        public void load_local_credentials() {
            string res = "";
            string path = Environment.get_home_dir()+"/.vgrive/credentials.json";
            File file = File.new_for_path(path);
            DataInputStream reader = new DataInputStream(file.read());
            string line;
            while ((line=reader.read_line(null)) != null) res = res.concat(line);
            this.credentials = res;
            // parse credentials to get token and refresh token
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object root_obj = parser.get_root().get_object();
            this.access_token = root_obj.get_string_member("access_token");
            this.refresh_token = root_obj.get_string_member("refresh_token");
        }

    }
}
