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

    public struct ResponseObject {
        Soup.MessageHeaders headers;
        string response;
        uint8[] bresponse;
    }

    public struct RequestParam {
        public string field_name;
        public string field_value;
    }

    public struct RequestContent {
        public string content_type;
        public uint8[] content;
    }

    public struct DriveFile {
        public string kind;
        public string id;
        public string name;
        public uint8[] content;
        public string mimeType;
        public string parent_id;
        public string modifiedTime;
        public string createdTime;
        public bool trashed;
        public string[] parents;
        public string local_path;
    }

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/*
 * CLASS VGriveClient
*/
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
    public class VGriveClient {


        private AppController app_controller;
        public int log_level = 1;
        private Soup.Session session = null;
        // API realted attributes
        public string access_token = "";
        public string refresh_token = "";
        public string client_id = "8532198801-7heceng058ouc4mj495a321s8s96b0e5.apps.googleusercontent.com";
        public string client_secret = "WPZsVURl5HcFD_7DP_jIP24z";
        public string scope = "https://www.googleapis.com/auth/drive";
        public string api_uri = "https://www.googleapis.com/drive/v3";
        public string upload_uri = "https://www.googleapis.com/upload/drive/v3";
        public string redirect = "urn:ietf:wg:oauth:2.0:oob";
        string page_token = "";
        // SYNC related sttributes
        public string main_path;
        public string trash_path;
        public bool syncing = false;
        public bool change_detected = false;
        public int changes_check_period = 10;
        private Gee.HashMap<string,string>? library;

        Thread<int> thread;

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
                trash_path = main_path+"/.trash";
            }
            this.trash_path = trash_path;
            file = File.new_for_path(trash_path);
            if (!file.query_exists()) {
                file.make_directory();
            }
            // Init Soup Session
            this.get_current_session ();
        }

        public string get_auth_uri() {
            return "https://accounts.google.com/o/oauth2/v2/auth?scope=%s&access_type=offline&redirect_uri=%s&response_type=code&client_id=%s".printf(scope, redirect, client_id);
        }

        public void log_message(string msg, int level=1) {
            if (this.app_controller != null && level >= log_level) {
                this.app_controller.log_message(msg);
            }
        }

        public void change_main_path(string new_path) {
            this.stop_syncing ();
            this.main_path = new_path;
            this.trash_path = main_path+"/.trash";
            this.library = null;
            this.log_message (_("Main folder changed to %s").printf(new_path));
        }
////////////////////////////////////////////////////////////////////////////////
/*
 *
 * SYNC RELATED METHODS
 *
*/
////////////////////////////////////////////////////////////////////////////////

        private Soup.Session get_current_session() {
            if (this.session == null) {
                this.session = new Soup.Session ();
            }
            return this.session;
        }

        public bool is_syncing() {
            return this.syncing;
        }

        public void start_syncing() {
            // Starts the process to sync files.
            // If the sync was already started (`syncing` is True), nothing is done.
            // The attributes `access_token` and `refresh_token` must be set with `request_credentials` or `load_local_credentials`
            if (!this.is_syncing () && this.has_credentials ()) {
                this.syncing = true;
                this.log_message(_("Start syncing files on %s ").printf(this.main_path));
                File maindir = File.new_for_path(this.main_path);
                if (!maindir.query_exists()) {
                    maindir.make_directory();
                    this.log_message(_("Directory created: %s ").printf(this.main_path));
                }
                File trashdir = File.new_for_path(this.trash_path);
                if (!trashdir.query_exists()) trashdir.make_directory();
                if (this.library == null) {
                    this.library = this.load_library();
                }
                // Start sync
                this.thread = new Thread<int>.try ("Sync thread", this.sync_files);
                //GLib.Timeout.add_seconds (1, sync_files);
                //this.sync_files ();
            }
        }

        public void stop_syncing() {
            this.syncing = false;
            int result = this.thread.join ();
            this.log_message(_("Syncing stopped by user request"));
            //this.save_library();
            //this.thread.exit(1);
            //this.log_message(_("Syncing stopped by user request"));
        }

        public int sync_files() {
            // Check if we have changes in files and sync them
            if (this.is_syncing ()) {
                this.log_level=0;
                //this.check_deleted_files ();
                // Made some changes that does not require check_deleted_files(). Check out
                this.check_remote_files (this.main_path);
                this.check_local_files (this.main_path);
                this.log_level=1;
                
                if(this.is_syncing ()){
                    this.log_message (_("Everything is up to date!"));
                    // trigger per revisar canvis quan canvia algo local
                    this.watch_local_changes ();
                    // trigger per revisar canvis quan canvia algo remot
                    this.watch_remote_changes ();
                
                    while (this.is_syncing ()) {
                        Thread.usleep (this.changes_check_period*1000000);
                        this.process_changes ();
                    }
                }
                
                return 1;
            }else {
                return -1;
            }
        }

        public bool process_changes() {
            if (this.is_syncing ()) {
                if (this.change_detected) {
                    this.log_message(_("Change detected. Updating files..."));
                    //this.check_deleted_files ();
                    this.check_local_files (this.main_path);
                    this.check_remote_files (this.main_path);
                    this.change_detected = false;
                    this.log_message (_("Everything is up to date!"));
                }
                return true;
            }else {
                return false;
            }
        }
        
        /* check_deleted_files is DEPRECATED */   
        private void check_deleted_files () {
            // Mira els fitxers que hi ha a la llibreria
            // Si no existeixen en local o en remot, el treu de la llibreria i l'elimina de on encara hi sigui
            if (!this.is_syncing ()) return;
            
            var it = this.library.map_iterator ();
            bool exist_local, exist_remote, must_delete = false;
            DriveFile[] remote_files;
            string remote_id, filename, aux, lpath;
            Array<string> to_delete = new Array<string> ();
            
            for (var has_next = it.next (); has_next; has_next = it.next ()) {
                if(this.is_syncing ()){
                    // Check local exists
                    lpath = it.get_value();
                    aux = it.get_key();
                    filename = lpath.split("/")[lpath.split("/").length-1];
                    exist_local = this.local_file_exists(lpath);

                    // Check remote exists
                    remote_id = this.get_file_id(lpath);
                    exist_remote = remote_id != null && remote_id != "";

                    // Si fa falta, l'eliminem de on sigui (fa falta si en un dels dos llocs s'ha de eliminar
                    must_delete = !exist_local || !exist_remote;
                    if (must_delete) {
                        to_delete.append_val(aux);
                        if (exist_local) {
                            this.log_message (_("DELETE LOCAL FILE: %s").printf (filename));
                            this.move_local_file_to_trash(lpath);
                        }
                        if (exist_remote) {
                            if (!this.is_google_doc (remote_id)) {
                                this.log_message (_("DELETE REMOTE FILE: %s").printf (filename));
                                this.delete_file(remote_id);
                            }
                        }
                    }else {
                        this.log_message (_("INFO: %s not deleted/moved").printf (filename), 0);
                    }
                }
            }
            for (int i = 0; i < to_delete.length ; i++) {
		        this.library.unset(to_delete.index (i));
	        }
            this.save_library ();
        }
//----------------------------------

        private void delete_files (string type, string file_id, string current_path = ""){
        /*
        This function should be used to do the changes already checked in check function.
        To use it you must enter the type of your action, the file id in the remote server and the current path of the file.
        Current_path default is root.

        TYPES:
            REMOTE = Do a delete action remotelly
            LOCAL = Do a delete action locally
            
        IMPORTANT:
        if type is LOCAL, you should enter the FILENAME in var file_id. For example: this.delete_files("LOCAL", filename, lpath);
        if type is REMOTE, you should enter the FILE_ID in var file_id. For example: this.delete_files("REMOTE", remote_file.id, lpath);
        */

            var it = this.library.map_iterator ();
            string aux, filename = "";
            string to_delete = "";

            if(!this.is_syncing ()) return;
            
            if(type == "LOCAL"){
                // Updating library
                for (var has_next = it.next (); has_next; has_next = it.next ()) {
                    aux = it.get_value();
                    if(aux == current_path+"/"+file_id){
                        to_delete = it.get_key();
                    }
                }

                this.library.unset(to_delete);
                this.save_library ();
                
                // Deleting file in local
                this.log_message (_("DELETE LOCAL FILE: %s").printf (file_id));
                this.move_local_file_to_trash(current_path+"/"+file_id);
            } else if (type == "REMOTE"){
                // Updating library
                for (var has_next = it.next (); has_next; has_next = it.next ()) {
                    aux = it.get_key();
                    if(aux == file_id){
                        to_delete = aux;
                        filename = it.get_value();
                    }
                }

                this.library.unset(to_delete);
                this.save_library ();
                
                // Deleting file in remote
                this.log_message (_("DELETE REMOTE FILE: %s").printf (filename));
                this.delete_file(file_id);
            }
        }

        private void check_remote_files (string current_path, string root_id="") {
        /*
        This function should check files to sync in remote server.
        If it detects missing files in local, should check for delete or download action.
        If the files were deleted call the function to delete, if weren't, download.
        */
        
        if (!this.is_syncing ()) return;

        DriveFile[] res = this.list_files(-1, root_id, -1);
        
            foreach (DriveFile f in res) {
                if (!this.is_syncing ()) return;
                
                // If file is not listed in the library, should be a new file, so sync it. Otherwise should be a deleted file, so delete it.
                if(!this.library.has_key(f.id)){                    
                    if (f.mimeType == "application/vnd.google-apps.folder") {
                        // Check if this file is a folder, then create if doesn't exist
                        if (!this.local_file_exists(current_path+"/"+f.name)) {
                            this.log_message(_("NEW REMOTE DIRECTORY: %s downloading...").printf(f.name), 0);
                            this.create_local_file(f, current_path);
                            this.log_message(_("NEW REMOTE DIRECTORY: %s downloaded ✓").printf(f.name), 0);
                            
                            // Set the folder in the library with this notation: folder.id;folder.local.path/filename
                            this.library.set(f.id, current_path+"/"+f.name);
                        }
                        // Check files inside the folder
                        this.check_remote_files(current_path+"/"+f.name, f.id);
                    } else if(this.is_google_mime_type (f.mimeType)){
                        // It's a google document. We don't want to download them
                        this.log_message(_("INFO: %s ignored").printf(f.name), 0);
                    } else {
                        // It's a file. Download it if it doesn't exist
                        if (!this.local_file_exists(current_path+"/"+f.name)) {
                            this.download_new_remote_file(f, current_path);
                            
                            // Set the file in the library with this notation: file.id;file.local.path/filename
                            this.library.set(f.id, current_path+"/"+f.name);
                        }
                    }
                } else if (this.library.has_key(f.id) && this.local_file_exists(current_path+"/"+f.name)) {
                    // Detect if the remote version is newer than the local one.
                    // If it's the case, move the local versio to .trash and download remote
                    DriveFile extra_info_file = this.get_file_info_extra(f.id, "modifiedTime");
                    if (this.compare_files_write_time(extra_info_file.modifiedTime, current_path+"/"+f.name) == -1) {
                        this.log_message(_("FILE MODIFIED REMOTELY: %s updating...").printf(f.name), 0);
                        this.download_new_version_remote_file(f, current_path);
                        this.log_message(_("FILE MODIFIED REMOTELY: %s updated ✓").printf(f.name), 0);
                    } else this.log_message(_("INFO: %s not changed").printf(f.name), 0);
                } else {
                    delete_files("REMOTE", f.id, current_path);
                }
            }
            this.save_library ();
        }

        private void check_local_files (string current_path, string root_id="") {
            /*
            This function should check files to sync in local.
            If it detects missing files in remote server, should check for delete or upload action.
            If the files were deleted call the function to delete, if weren't, upload.
            */
            
            if (!this.is_syncing ()) return;
            try {
            var directory = File.new_for_path (current_path);
            bool has_in_lib = false;
            var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo info;
            DriveFile remote_file, new_remote_file;
            
            while ((info = enumerator.next_file ()) != null) {
                if (!this.is_syncing ()) return;
                var it = this.library.map_iterator ();
                
                if (this.is_regular_file(info.get_name())) {
                    remote_file = this.get_file_info(info.get_name(), root_id, -1);

                    if(remote_file.id == null){
                        for (var has_next = it.next (); has_next; has_next = it.next ()) {
                            if(it.get_value() == current_path+"/"+info.get_name()){
                                has_in_lib = true;
                                break;
                            }
                        }
                    }

                    // If file is not listed in the library, should be a new file, so sync it. Otherwise should be a deleted file, so delete it.
                    if(!has_in_lib){
                        if (info.get_file_type () == FileType.DIRECTORY) {
                            if (remote_file.id == null) {
                                // Create DIR
                                this.log_message(_("NEW LOCAL DIRECTORY: %s uploading...").printf(info.get_name()));
                                remote_file = this.upload_new_local_dir(current_path+"/"+info.get_name(), root_id);
                                this.log_message(_("NEW LOCAL DIRECTORY: %s uploaded ✓").printf(remote_file.name));
                            } else {
                                this.log_message(_("INFO: %s not changed").printf(remote_file.name), 0);
                            }

                            // Set the file in the library with this notation: file.id;file.local.path/filename
                            new_remote_file = this.get_file_info(info.get_name(), root_id, -1);
                            this.library.set(new_remote_file.id, current_path+"/"+info.get_name());

                            this.check_local_files(current_path+"/"+info.get_name(), remote_file.id);
                        } else {
                            if (remote_file.id == null) {
                                // Create File
                                remote_file = this.upload_new_local_file(current_path+"/"+info.get_name(), root_id);
                            }
                        }
                    } else if (has_in_lib && remote_file.id != null) {
                        // Detect if the local version is newer than the remote one.
                        // If it's the case, upload local one
                        DriveFile extra_info_file = this.get_file_info_extra(remote_file.id, "modifiedTime");
                        if (this.compare_files_write_time(extra_info_file.modifiedTime, current_path+"/"+remote_file.name) == 1) {
                            this.upload_local_file_update(current_path+"/"+info.get_name(), remote_file.id);
                        } else this.log_message(_("INFO: %s not changed").printf(remote_file.name), 0);
                    } else {
                        delete_files("LOCAL", info.get_name(), current_path);
                    }
                }
            }

            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
            this.save_library ();
        }

        private void watch_local_changes() {
            try {
                string[] dirs_to_watch = this.get_all_dirs(this.main_path);

                foreach (string dir_to_watch in dirs_to_watch) {
                    new Thread<int>.try ("Watch %s thread".printf(dir_to_watch), () => {
                        File dir_to_watch_file = File.new_for_path (dir_to_watch);
                        FileMonitor monitor = dir_to_watch_file.monitor (FileMonitorFlags.WATCH_MOVES, null);
                        monitor.changed.connect ((changed_file, other_file, event_type) => {
                            if (this.is_regular_file (changed_file.get_basename ())) this.change_detected = true;
                        });
                        new MainLoop ().run ();
                        return 1;
                    });
                }
            } catch (Error err) {
                stdout.printf ("Error: %s\n", err.message);
            }
        }

        private void watch_remote_changes () {
            this.page_token = this.request_page_token();
            try {
                new Thread<int>.try ("Watch remote thread", () => {
                    while (this.is_syncing ()) {
                        Thread.usleep (this.changes_check_period*1000000);
                        this.change_detected = this.check_remote_changes (this.page_token);
                    }
                    new MainLoop ().run ();
                    return 1;
                });
            } catch (Error err) {
                stdout.printf ("Error: %s\n", err.message);
            }
        }

        private bool check_remote_changes(string token) {
            return this.has_remote_changes (token);
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
            var session = this.get_current_session();
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
                result = "Error trying to get access token: \n%s\n".printf(res);
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
                    string result = "Error trying to get access token: \n%s\n".printf(res.message);
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

        public void delete_local_credentials(owned string? path=null) {
            if (path == null) path = Environment.get_home_dir()+"/.vgrive/credentials.json";
            if (this.has_local_credentials (path)) {
                File file = File.new_for_path(path);
                file.delete ();
            }
        }

        public void delete_credentials() {
            this.access_token = "";
            this.refresh_token = "";
        }

        public bool has_credentials () {
            // Returns True if attribures `access_token` and `refresh_token` are set.
            // Else False
            return this.access_token != "" && this.refresh_token != "";
        }


////////////////////////////////////////////////////////////////////////////////
/*
 *
 * GOOGLE DRIVE API RELATED METHODS
 *
*/
////////////////////////////////////////////////////////////////////////////////

        public ResponseObject make_request(string method, string uri, RequestParam[]? params_list=null, RequestParam[]? request_headers=null, RequestContent? request_content=null, bool without_acces_token=false) {
            // Fa una petició HTTP a la API de Google Drive amb els paràmetres proporcionats
            var session = this.get_current_session();
            string uri_auth;
            if (without_acces_token) uri_auth = uri;
            else uri_auth = uri + "?access_token=%s".printf(this.access_token);
            if (params_list != null) foreach (RequestParam param in params_list) uri_auth = uri_auth.concat("&", param.field_name, "=", param.field_value);
            uri_auth = encode_uri(uri_auth);
            //stdout.printf("Request: %s %s\n", method, uri_auth);
            var message = new Soup.Message (method, uri_auth);
            string res;
            uint8[] bres;
            Soup.MessageHeaders res_header;
            try {
                // send the HTTP request and wait for response
                if (request_headers != null) foreach (RequestParam param in request_headers) message.request_headers.append(param.field_name, param.field_value);
                if (request_content != null) message.set_request(request_content.content_type, Soup.MemoryUse.COPY, request_content.content);
                session.send_message (message);
                bres = message.response_body.data;
                res = (string) message.response_body.data;
                res_header = message.response_headers;
                // Parse response
                var parser = new Json.Parser ();
                parser.load_from_data (res, -1);
                Json.Object json_response = parser.get_root().get_object();
                // Check if we had an error
                if (json_response.get_member("error") != null) {
                    Json.Object error_obj = json_response.get_object_member("error");
                    // Check if it's Auth error.
                    if (error_obj.get_string_member("message") == "Invalid Credentials") {
                        // If it's auth error we will try to refresh the token
                        string refresh_uri = "https://www.googleapis.com/oauth2/v4/token?refresh_token=%s&client_id=%s&client_secret=%s&grant_type=refresh_token".printf(this.refresh_token, this.client_id, this.client_secret);
                        message = new Soup.Message ("POST", refresh_uri);
                        message.set_request("", Soup.MemoryUse.COPY, "{}".data);
                        stdout.printf("Authentication error. Refreshing token. Request: POST %s\n", refresh_uri);
                        session.send_message (message);
                        string refresh_res = (string) message.response_body.data;
                        parser = new Json.Parser ();
                        parser.load_from_data (refresh_res, -1);
                        json_response = parser.get_root().get_object();
                        if (json_response.get_member("access_token") != null) {
                            // Retry request with new token
                            this.access_token = json_response.get_string_member("access_token");
                            if (without_acces_token) uri_auth = uri;
                            else uri_auth = uri + "?access_token=%s".printf(this.access_token);
                            if (params_list != null) foreach (RequestParam param in params_list) uri_auth = uri_auth.concat("&", param.field_name, "=", param.field_value);
                            uri_auth = encode_uri(uri_auth);
                            stdout.printf("Retrying request: %s %s\n", method, uri_auth);
                            message = new Soup.Message (method, uri_auth);
                            if (request_headers != null) foreach (RequestParam param in request_headers) message.request_headers.append(param.field_name, param.field_value);
                            if (request_content != null) message.set_request(request_content.content_type, Soup.MemoryUse.COPY, request_content.content);
                            session.send_message (message);
                            bres = message.response_body.data;
                            res = (string) message.response_body.data;
                            res_header = message.response_headers;
                            return {res_header, res, bres};
                        } else {
                            // Refresh token failure
                            stdout.printf("Error trying to refresh token\n");
                            return {res_header, res, bres};
                        }
                    }else {
                        // Unknown error. Return recived response
                        return {res_header, res, bres};
                    }
                }
            } catch (Error e) {
                if (res == null || res == "") res = e.message;
            }
            return {res_header, res, bres};
        }

        public DriveFile[] list_files(int number, string parent_id, int trashed) {
        /*
            * number: number of files to list. If it's set to -1, list all files
            * parent_id: id of directory where listed files are. If it's set to "", list files from root directory
            * trashed: -1 = list non trashed files, 0 = list both trashed and non trashed files, 1 = list trashed files
            Returns a list {number} DriveFile files in {parent_id} with the following information:
              * kind: usually drive#file
              * id: unic resource identifier
              * name
              * mimeType
              * parent_id
        */
            RequestParam[] params = new RequestParam[2];

            int pageSize = 1000;
            if (number > -1 && number <= 1000) pageSize = number;
            params[0] = {"pageSize", pageSize.to_string()};

            string q = "";
            if (parent_id == "") q = q.concat("'root' in parents");
            else if (parent_id != "") q = q.concat("'%s' in parents".printf(parent_id));
            if (trashed < 0) q = q.concat(" and trashed = False");
            else if (trashed > 0) q = q.concat(" and trashed = True");
            params[1] = {"q", q};

            string res = this.make_request("GET", this.api_uri+"/files", params, null, null, false).response;
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            if (json_response.get_member("error") != null) {
                stdout.printf("%s\n", res);
                return new DriveFile[0];
            }
            int nfiles = 0;
            DriveFile[] results = new DriveFile[pageSize];
            Json.Array json_files = json_response.get_member("files").get_array ();
            unowned Json.Object obj;
            foreach (unowned Json.Node item in json_files.get_elements ()) {
                obj = item.get_object ();
                results[nfiles] = {
                    obj.get_string_member("kind"), // kind
                    obj.get_string_member("id"), // id
                    obj.get_string_member("name"), // name
                    "".data, // content
                    obj.get_string_member("mimeType"), // mimeType
                    parent_id, // parent_id
                    obj.get_string_member("modifiedTime"),
                    obj.get_string_member("createdTime"),
                    obj.get_boolean_member("trashed"),
                    new string[0]
                };
                nfiles += 1;
                if (nfiles == results.length) results.resize(results.length*2);
            }

            bool files_left = json_response.get_member("nextPageToken") != null && (number < 0 || nfiles < number);
            RequestParam[] params2 = new RequestParam[3];
            while (files_left) {
                params2[0] = params[0];
                params2[1] = params[1];
                params2[2] = {"pageToken", json_response.get_string_member("nextPageToken")};
                res = this.make_request("GET", this.api_uri+"/files", params2, null, null, false).response;
                parser.load_from_data (res, -1);
                json_response = parser.get_root().get_object();
                if (json_response.get_member("error") != null) {
                    stdout.printf("%s\n", res);
                    return results[0:nfiles];
                }
                json_files = json_response.get_member("files").get_array ();
                foreach (unowned Json.Node item in json_files.get_elements ()) {
                    obj = item.get_object ();
                    results[nfiles] = {
                        obj.get_string_member("kind"), // kind
                        obj.get_string_member("id"), // id
                        obj.get_string_member("name"), // name
                        "".data, // content
                        obj.get_string_member("mimeType"), // mimeType
                        parent_id, // parent_id
                        obj.get_string_member("modifiedTime"),
                        obj.get_string_member("createdTime"),
                        obj.get_boolean_member("trashed"),
                        new string[0]
                    };
                    nfiles += 1;
                    if (nfiles == results.length) results.resize(results.length*2);
                }
                files_left = json_response.get_member("nextPageToken") != null && (number < 0 || nfiles < number);
            }

            if (number > -1 && nfiles > number) nfiles = number;

            return results[0:nfiles];
        }

        public DriveFile upload_file(string filepath, string parent_id) {
            /*
                Update the file identified by {filepath}
                    * {filepath} is the complet path of the file to be uploaded
                      with the {sync_dir} as root. It must exist locally.
                File doesn't exist in remote
            */
            string filename = filepath.split("/")[filepath.split("/").length-1];
            RequestParam[] params = new RequestParam[1];
            params[0] = {"uploadType", "resumable"};
            RequestContent body = {"application/json; charset=UTF-8", ("{\"name\": \"%s\", \"parents\": [\"%s\"]}".printf(filename, parent_id)).data};
            RequestParam[] headers = new RequestParam[2];
            headers[0] = {"Content-Type", "application/json; charset=UTF-8"};
            headers[1] = {"Content-Length", body.content.length.to_string()};
            ResponseObject res = this.make_request("POST", this.upload_uri+"/files", params, headers, body, false);

            string location = res.headers.get_one("Location");
            try {
                File file = File.new_for_path(filepath);
                var dis = new DataInputStream (file.read ());
                dis.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
                int bytes_readed = 0;
                uint8[] content = new uint8[64];
                uint8 readed;
                try {
                    readed = dis.read_byte(null);
                    while (true) {
                        if (content.length <= bytes_readed) content.resize(bytes_readed*2);
                        content[bytes_readed] = readed;
                        bytes_readed += 1;
                        readed = dis.read_byte(null);
                    }
                }catch (Error e) {}

                RequestContent file_content = {"", content[0:bytes_readed]};

                headers = new RequestParam[1];
                headers[0] = {"Content-Length", bytes_readed.to_string()};

                ResponseObject res2 = this.make_request("PUT", location, null, headers, file_content, true);
                var parser = new Json.Parser ();
                parser.load_from_data (res2.response, -1);
                Json.Object json_response = parser.get_root().get_object();
                if (json_response.get_member("error") != null) {
                    stdout.printf("%s\n", res2.response);
                    return {};
                }
                return {
                    json_response.get_string_member("kind"), // kind
                    json_response.get_string_member("id"), // id
                    json_response.get_string_member("name"), // name
                    "".data, // content
                    json_response.get_string_member("mimeType"), // mimeType
                    parent_id, // parent_id
                    json_response.get_string_member("modifiedTime"),
                    json_response.get_string_member("createdTime"),
                    json_response.get_boolean_member("trashed"),
                    new string[0]
                };
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
                return  {};
            }
        }

        public DriveFile upload_file_update(string filepath, string file_id) {
            /*
                Update the file identified by {filepath}
                    * {filepath} is the complet path of the file to be uploaded
                      with the {sync_dir} as root. It must exist locally.
                File exists in remote with id {file_id}
            */

            string filename = filepath.split("/")[filepath.split("/").length-1];

            RequestParam[] params = new RequestParam[1];
            params[0] = {"uploadType", "resumable"};
            RequestParam[] headers = new RequestParam[2];
            headers[0] = {"Content-Type", "application/json; charset=UTF-8"};
            headers[1] = {"Content-Length", "0"};
            ResponseObject res = this.make_request("PATCH", this.upload_uri+"/files/"+file_id, params, headers, null, false);

            string location = res.headers.get_one("Location");
            try {
                File file = File.new_for_path(filepath);
                var dis = new DataInputStream (file.read ());
                dis.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
                int bytes_readed = 0;
                uint8[] content = new uint8[64];
                uint8 readed;
                try {
                    readed = dis.read_byte(null);
                    while (true) {
                        if (content.length <= bytes_readed) content.resize(bytes_readed*2);
                        content[bytes_readed] = readed;
                        bytes_readed += 1;
                        readed = dis.read_byte(null);
                    }
                }catch (Error e) {}

                RequestContent file_content = {"", content[0:bytes_readed]};

                headers = new RequestParam[1];
                headers[0] = {"Content-Length", bytes_readed.to_string()};

                ResponseObject res2 = this.make_request("PUT", location, null, headers, file_content, true);
                var parser = new Json.Parser ();
                parser.load_from_data (res2.response, -1);
                Json.Object json_response = parser.get_root().get_object();
                if (json_response.get_member("error") != null) {
                    stdout.printf("%s\n", res2.response);
                    return {};
                }
                return {
                    json_response.get_string_member("kind"), // kind
                    json_response.get_string_member("id"), // id
                    json_response.get_string_member("name"), // name
                    "".data, // content
                    json_response.get_string_member("mimeType"), // mimeType
                    "", // parent_id
                    json_response.get_string_member("modifiedTime"),
                    json_response.get_string_member("createdTime"),
                    json_response.get_boolean_member("trashed"),
                    new string[0]
                };
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
                return  {};
            }
        }

        public DriveFile upload_dir(string path, string parent_id) {
            string dirname = path.split("/")[path.split("/").length-1];

            RequestParam[] params = new RequestParam[1];
            params[0] = {"uploadType", "resumable"};
            RequestContent body = {"application/json; charset=UTF-8", ("{\"name\": \"%s\", \"mimeType\": \"application/vnd.google-apps.folder\", \"parents\": [\"%s\"]}".printf(dirname, parent_id)).data};
            RequestParam[] headers = new RequestParam[2];
            headers[0] = {"Content-Type", "application/json; charset=UTF-8"};
            headers[1] = {"Content-Length", body.content.length.to_string()};
            ResponseObject res = this.make_request("POST", this.upload_uri+"/files", params, headers, body, false);

            string location = res.headers.get_one("Location");
            RequestContent file_content = {"", new uint8[0]};

            headers = new RequestParam[1];
            headers[0] = {"Content-Length", "0"};

            ResponseObject res2 = this.make_request("PUT", location, null, headers, file_content, true);
            var parser = new Json.Parser ();
            parser.load_from_data (res2.response, -1);
            Json.Object json_response = parser.get_root().get_object();
            if (json_response.get_member("error") != null) {
                stdout.printf("%s\n", res2.response);
                return {};
            }
            return {
                json_response.get_string_member("kind"), // kind
                json_response.get_string_member("id"), // id
                json_response.get_string_member("name"), // name
                "".data, // content
                json_response.get_string_member("mimeType"), // mimeType
                parent_id, // parent_id
                json_response.get_string_member("modifiedTime"),
                json_response.get_string_member("createdTime"),
                json_response.get_boolean_member("trashed"),
                new string[0]
            };
        }

        public DriveFile[] search_files(string q) {
            RequestParam[] params = new RequestParam[1];
            params[0] = {"q", q};

            string res = this.make_request("GET", this.api_uri+"/files", params, null, null, false).response;
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            if (json_response.get_member("error") != null) {
                stdout.printf("%s\n%s\n", res, q);
                return new DriveFile[0];
            }
            int nfiles = 0;
            DriveFile[] results = new DriveFile[5];
            Json.Array json_files = json_response.get_member("files").get_array ();
            unowned Json.Object obj;
            foreach (unowned Json.Node item in json_files.get_elements ()) {
                obj = item.get_object ();
                results[nfiles] = {
                    obj.get_string_member("kind"), // kind
                    obj.get_string_member("id"), // id
                    obj.get_string_member("name"), // name
                    "".data, // content
                    obj.get_string_member("mimeType"), // mimeType
                    "", // parent_id
                    obj.get_string_member("modifiedTime"),
                    obj.get_string_member("createdTime"),
                    obj.get_boolean_member("trashed"),
                    new string[0]
                };
                nfiles += 1;
                if (nfiles == results.length) results.resize(results.length*2);
            }

            bool files_left = json_response.get_member("nextPageToken") != null;
            params = new RequestParam[2];
            while (files_left) {
                params[0] = {"q", q};
                params[1] = {"pageToken", json_response.get_string_member("nextPageToken")};
                res = this.make_request("GET", this.api_uri+"/files", params, null, null, false).response;
                parser.load_from_data (res, -1);
                json_response = parser.get_root().get_object();
                if (json_response.get_member("error") != null) {
                    stdout.printf("%s\n", res);
                    return results[0:nfiles];
                }
                json_files = json_response.get_member("files").get_array ();
                foreach (unowned Json.Node item in json_files.get_elements ()) {
                    obj = item.get_object ();
                    results[nfiles] = {
                        obj.get_string_member("kind"), // kind
                        obj.get_string_member("id"), // id
                        obj.get_string_member("name"), // name
                        "".data, // content
                        obj.get_string_member("mimeType"), // mimeType
                        "", // parent_id
                        obj.get_string_member("modifiedTime"),
                        obj.get_string_member("createdTime"),
                        obj.get_boolean_member("trashed"),
                        new string[0]
                    };
                    nfiles += 1;
                    if (nfiles == results.length) results.resize(results.length*2);
                }
                files_left = json_response.get_member("nextPageToken") != null;
            }
            return results[0:nfiles];
        }

        public uint8[] get_file_content(string file_id) {
            RequestParam[] params = new RequestParam[1];
            params[0] = {"alt", "media"};
            return this.make_request("GET", this.api_uri+"/files/"+file_id, params, null, null, false).bresponse;
        }

        public bool is_google_doc(string file_id) {
            DriveFile f = this.get_file_info_extra (file_id, "mimeType");
            return this.is_google_mime_type(f.mimeType);
        }

        public bool is_google_mime_type(string mimeType) {
            return mimeType.has_prefix ("application/") && mimeType.contains("google-apps") && mimeType != "application/vnd.google-apps.folder";
        }

        public DriveFile get_file_info(string name, string parent_id, int trashed) {
            RequestParam[] params = new RequestParam[1];

            string q = "";
            if (parent_id == "") q = q.concat("'root' in parents");
            else if (parent_id != "") q = q.concat("'%s' in parents".printf(parent_id));
            if (trashed < 0) q = q.concat(" and trashed = False");
            else if (trashed > 0) q = q.concat(" and trashed = True");
            q = q.concat(" and name = \'%s\'".printf(this.encode_for_q(name)));
            params[0] = {"q", q};

            string res = this.make_request("GET", this.api_uri+"/files", params, null, null, false).response;
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            if (json_response.get_member("error") != null) {
                stdout.printf("%s\n", res);
                return {};
            }
            DriveFile result = {};
            Json.Array json_files = json_response.get_member("files").get_array ();
            unowned Json.Object obj;
            foreach (unowned Json.Node item in json_files.get_elements ()) {
                obj = item.get_object ();
                result = {
                    obj.get_string_member("kind"), // kind
                    obj.get_string_member("id"), // id
                    obj.get_string_member("name"), // name
                    "".data, // content
                    obj.get_string_member("mimeType"), // mimeType
                    parent_id, // parent_id
                    obj.get_string_member("modifiedTime"),
                    obj.get_string_member("createdTime"),
                    obj.get_boolean_member("trashed"),
                    new string[0]
                };
            }
            return result;
        }

        public DriveFile get_file_info_extra(string file_id, string fields) {
            RequestParam[1] params = new RequestParam[1];
            params[0] = {"fields", fields};
            string res = this.make_request("GET", this.api_uri+"/files/"+file_id, params, null, null, false).response;
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            if (json_response.get_member("error") != null) {
                stdout.printf("%s\n", res);
                return {};
            }
            string[] parents = new string[2];
            uint nparents = 0;
            Json.Array json_parents = json_response.get_member("parents").get_array ();
            foreach (unowned Json.Node item in json_parents.get_elements ()) {
                parents[nparents] = json_parents.get_string_element(nparents);
                nparents += 1;
                if (parents.length >= nparents) parents.resize(parents.length*2);
            }
            return {
                json_response.get_string_member("kind"), // kind
                json_response.get_string_member("id"), // id
                json_response.get_string_member("name"), // name
                "".data, // content
                json_response.get_string_member("mimeType"), // mimeType
                "", // parent_id
                json_response.get_string_member("modifiedTime"),
                json_response.get_string_member("createdTime"),
                json_response.get_boolean_member("trashed"),
                parents[0:nparents]
            };
        }

        public string get_file_id(string path) {
            if (path == this.main_path) return "root";
            else {
                string current_file = path.split("/")[path.split("/").length-1];
                string new_path = path.substring(0, path.length-current_file.length-1);
                string parent_id = this.get_file_id(new_path);
                if (parent_id == "") parent_id = "root";

                // Escapem caracters especials del nom del fitxer
                current_file = this.encode_for_q (current_file);

                string q = "trashed = False and name = '%s' and '%s' in parents".printf(current_file, parent_id);
                DriveFile[] res = this.search_files(q);
                if (res.length != 1) return "";
                else return res[0].id;
            }
        }

        public void delete_file(string file_id) {
            this.make_request("DELETE", this.api_uri+"/files/%s".printf(file_id), null, null, null);
        }

        public string request_page_token() {
            string res = this.make_request("GET", this.api_uri+"/changes/startPageToken", null, null, null, false).response;
            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            return json_response.get_string_member("startPageToken");
        }

        public bool has_remote_changes(string pageToken) {
            RequestParam[] params = new RequestParam[1];
            params[0] = {"pageToken", pageToken};
            string res = this.make_request("GET", this.api_uri+"/changes", params, null, null, false).response;

            var parser = new Json.Parser ();
            parser.load_from_data (res, -1);
            Json.Object json_response = parser.get_root().get_object();
            if (json_response.get_member("error") != null) {
                stdout.printf("%s\n", res);
                return false;
            }
            // Mirem si hi ha 1 element com a minim al llistat de canvis. Si n'hi ha, vol dir que hi ha algun canvi per processar
            Json.Array json_files = json_response.get_member("changes").get_array ();
            bool final_res = json_files.get_length () > 0;

            // Acavem de demanar tota la resta de canvis perqué quan hi tornem ja no els ens torni a ensenyar
            string nextToken = "";
            if (json_response.get_member("newStartPageToken") != null) nextToken = json_response.get_string_member("newStartPageToken");

            bool changes_left = json_response.get_member("nextPageToken") != null;
            while (changes_left) {
                params[0] = {"pageToken", json_response.get_string_member("nextPageToken")};
                res = this.make_request("GET", this.api_uri+"/changes", params, null, null, false).response;
                parser.load_from_data (res, -1);
                json_response = parser.get_root().get_object();
                if (json_response.get_member("error") != null) {
                    stdout.printf("%s\n", res);
                    return false;
                }
                if (json_response.get_member("newStartPageToken") != null) nextToken = json_response.get_string_member("newStartPageToken");
                changes_left = json_response.get_member("nextPageToken") != null;
            }

            if (nextToken != "" && nextToken != null) this.page_token = nextToken;
            return final_res;
        }

////////////////////////////////////////////////////////////////////////////////
/*
 *
 * LIBRARY RELATED METHODS
 *
*/
////////////////////////////////////////////////////////////////////////////////

        public Gee.HashMap<string,string>? load_library() {
            File f = File.new_for_path(this.main_path+"/.vgrive_library");
            if (!f.query_exists()) {
                f.create(FileCreateFlags.NONE);
                return new Gee.HashMap<string,string>();
            }
            else {
                Gee.HashMap<string,string>? aux = new Gee.HashMap<string,string> ();
                DataInputStream reader = new DataInputStream(f.read());
                string line;
                while ((line=reader.read_line(null)) != null) aux.set(line.split(";")[0], line.split(";")[1]);
                return aux;
            }
        }

        public void save_library() {
            File f = File.new_for_path(this.main_path+"/.vgrive_library");
            if (f.query_exists()) f.delete();
            f.create(FileCreateFlags.NONE);
            FileIOStream io = f.open_readwrite();
            var writer = new DataOutputStream(io.output_stream);
            foreach (var entry in this.library.entries) {
                writer.put_string("%s;%s\n".printf(entry.key, entry.value));
            }
        }

        public void download_new_remote_file(DriveFile f, string path) {
            this.log_message(_("NEW REMOTE FILE: %s downloading...").printf(f.name));
            f.content = this.get_file_content(f.id);
            this.create_local_file(f, path);
            DriveFile extra_info_file = this.get_file_info_extra(f.id, "modifiedTime");
            this.update_local_write_date(extra_info_file.modifiedTime, path+"/"+f.name);
            this.log_message(_("NEW REMOTE FILE: %s downloaded ✓").printf(f.name));
        }

        public void download_new_version_remote_file(DriveFile f, string path) {
            this.log_message(_("CHANGE IN REMOTE FILE: %s downloading newest version...").printf(f.name));
            f.content = this.get_file_content(f.id);
            this.move_local_file_to_trash(path+"/"+f.name);
            this.create_local_file(f, path);
            this.update_local_write_date(f.modifiedTime, path+"/"+f.name);
            this.log_message(_("CHANGE IN REMOTE FILE: %s downloaded ✓").printf(f.name));
        }

        public void upload_local_file_update(string path, owned string? file_id) {
            string filename = path.split("/")[path.split("/").length-1];
            this.log_message(_("CHANGE IN LOCAL FILE: %s uploading newest version...").printf(filename));
            if (file_id == null) file_id = this.get_file_id(path);
            DriveFile remote_file = this.upload_file_update(path, file_id);
            this.update_local_write_date(remote_file.modifiedTime, path);
            this.log_message(_("CHANGE IN LOCAL FILE: %s uploaded ✓").printf(remote_file.name));
        }

        public DriveFile upload_new_local_dir(string path, string? parent_id) {
            string parent = parent_id;
            if (parent_id == null || parent_id == "") {
                string current_file = path.split("/")[path.split("/").length-1];
                string new_path = path.substring(0, path.length-current_file.length-1);
                parent = this.get_file_id(new_path);
            }
            DriveFile dfile = this.upload_dir(path, parent);
            if (!this.library.has_key(dfile.id)) this.library.set(dfile.id, path);
            return dfile;
        }

        public DriveFile upload_new_local_file(string path, string? parent_id) {
            string filename = path.split("/")[path.split("/").length-1];
            this.log_message(_("NEW LOCAL FILE: %s uploading...").printf(filename));
            string parent = parent_id;
            if (parent == null || parent == "") {
                string partial_path = "";
                foreach (string aux in path.strip().split("/")) {
                    if (aux != filename && aux != "") partial_path = partial_path+"/"+aux;
                }
                parent = this.get_file_id(partial_path);
            }
            DriveFile remote_file = this.upload_file(path, parent);
            DriveFile extra_info_file = this.get_file_info_extra(remote_file.id, "modifiedTime");
            this.update_local_write_date(extra_info_file.modifiedTime, path);
            this.log_message(_("NEW LOCAL FILE: %s uploaded ✓").printf(remote_file.name));
            if (!this.library.has_key(remote_file.id)) this.library.set(remote_file.id, path);
            return remote_file;
        }

        public void create_local_file(DriveFile dfile, string path) {
            File file = File.new_for_path(path+"/"+dfile.name);
            if (dfile.mimeType == "application/vnd.google-apps.folder") {
                if (!file.query_exists()) file.make_directory();
            }
            else {
                // It shouldn't exist, we checked it...
                if (!file.query_exists()) file.create(FileCreateFlags.NONE);
                FileIOStream io = file.open_readwrite();
                var writer = new DataOutputStream(io.output_stream);
                foreach (uint8 b in dfile.content) writer.put_byte(b);
            }
        }

        public bool is_regular_file(string fname) {
            return fname != ".trash" && fname != ".page_token" && fname != ".vgrive_library";
        }
////////////////////////////////////////////////////////////////////////////////
/*
 *
 * UTILS METHODS
 *
*/
////////////////////////////////////////////////////////////////////////////////

        public void empty_trash(string? current_path=null) {
            if (current_path == null) current_path = this.trash_path;
            FileInfo info;
            File f = File.new_for_path(current_path);
            File auxf;
            var enumerator = f.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            while ((info = enumerator.next_file ()) != null) {
                if (info.get_file_type () == FileType.DIRECTORY) {
                    this.empty_trash (current_path+"/"+info.get_name());
                }
                auxf = File.new_for_path(current_path+"/"+info.get_name());
                auxf.delete();
            }
        }

        private string encode_uri(string param) {
            string aux = Soup.URI.encode(param, null);
            return param;
        }

        private string encode_for_q(string param) {
            /*
                Replaces:
                 * \ -> \\
                 * ' -> \'
                 * # -> \#
                 * & -> %26
                 * spaces -> +
            */
            string aux = param.replace("\\", "\\\\");
            aux = aux.replace("'", "\\'");
            aux = aux.replace("#", "\\#");
            aux = aux.replace("&", "%26");
            aux = aux.replace(" ", "+");
            return aux;
        }

        public bool local_file_exists(string path) {
            File file = File.new_for_path(path);
            return file.query_exists();
        }

        public void update_local_write_date(string? date, string filepath) {
            string? aux = date;
            if (aux == null) {
                //this.log_message("WARNING: No date for %s. Asking to api...".printf(filepath));
                string fid = this.get_file_id(filepath);
                var dfile = this.get_file_info_extra (fid, "modifiedTime");
                aux = dfile.modifiedTime;
                //this.log_message("New date: %s".printf(aux));
            }
            if (aux == null) {
                //this.log_message("ERROR: No date for %s.".printf(filepath));
            }
            File f = File.new_for_path(filepath);
            FileInfo fileinfo = f.query_info ("*", FileQueryInfoFlags.NONE);
            TimeVal tv = new TimeVal();
            tv.from_iso8601(aux);
            fileinfo.set_modification_time(tv);
            f.set_attributes_from_info(fileinfo, FileQueryInfoFlags.NONE);
        }

        public void move_local_file_to_trash(string filepath) {
            File f = File.new_for_path(filepath);
            DateTime dt = new DateTime.now_utc();
            File dest = File.new_for_path(this.trash_path+"/"+dt.to_string()+"_"+filepath.split("/")[filepath.split("/").length-1]);
            f.move(dest, FileCopyFlags.NONE);
        }

        public int compare_files_write_time(string dfile_write_date, string filepath) {
            /*
                Compare the write date of dfile with the write date of filepath,
                drivefile is newest -> -1
                drivefile == filepath -> 0
                filepath is newest -> 1
            */
            File lfile = File.new_for_path(filepath);
            FileInfo fileinfo = lfile.query_info ("*", FileQueryInfoFlags.NONE);
            TimeVal lfile_wdate = fileinfo.get_modification_time();

            string year, month, day, hour, minutes, seconds,timezone;
            string strtime = lfile_wdate.to_iso8601();
            year =  strtime.split("-")[0];
            month =  strtime.split("-")[1];
            day =  strtime.split("-")[2].split("T")[0];
            hour = strtime.split("T")[1].split(":")[0];
            minutes = strtime.split("T")[1].split(":")[1];
            seconds = strtime.split("T")[1].split(":")[2].substring(0, 2);
            timezone = strtime.substring(strtime.last_index_of_char('Z'), 1);
            DateTime local =  new DateTime (new TimeZone(timezone), year.to_int(), month.to_int(), day.to_int(), hour.to_int(), minutes.to_int(), seconds.to_double());

            strtime = dfile_write_date;
            year =  strtime.split("-")[0];
            month =  strtime.split("-")[1];
            day =  strtime.split("-")[2].split("T")[0];
            hour = strtime.split("T")[1].split(":")[0];
            minutes = strtime.split("T")[1].split(":")[1];
            seconds = strtime.split("T")[1].split(":")[2].substring(0, 2);
            timezone = strtime.substring(strtime.last_index_of_char('Z'), 1);
            DateTime remote =  new DateTime (new TimeZone(timezone), year.to_int(), month.to_int(), day.to_int(), hour.to_int(), minutes.to_int(), seconds.to_double());
            return local.compare(remote);
        }

        public string[] get_all_dirs(string path) {
            File file =  File.new_for_path(path);
            var enumerator = file.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            string[] dirs = new string[5];
            dirs[0] = path;
            int ndirs = 1;
            FileInfo info;
            string new_path;
            string[] new_dirs;
            while ((info = enumerator.next_file ()) != null) {
                new_path = path+"/"+info.get_name();
                if (info.get_file_type () == FileType.DIRECTORY && new_path.split("/")[new_path.split("/").length-1] != ".trash") {
                    new_dirs = this.get_all_dirs(new_path);
                    foreach (string new_dir in new_dirs) {
                        dirs[ndirs] = new_dir;
                        ndirs += 1;
                        if (ndirs >= dirs.length) dirs.resize(ndirs*2);
                    }
                }
                if (ndirs >= dirs.length) dirs.resize(ndirs*2);
            }
            return dirs[0:ndirs];
        }

    }

}
