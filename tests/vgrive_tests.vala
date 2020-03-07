using App;

// https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/drive&access_type=offline&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=8532198801-7heceng058ouc4mj495a321s8s96b0e5.apps.googleusercontent.com

class TestVGrive : Gee.TestCase {

    private VGriveClient client;
    private string mainpath = GLib.Environment.get_current_dir()+"/.testbuild/VGriveTEST";
    private string access_token = "ya29.Il_BB3zFXkNQ22kLVBhaPUQlSNBK0PEH2B6BYW9v1kW_PzfD7r9wDw_QGDgsEXeCxwo2keeXWFgQQk-04NN9yvUstc4K-Lr0QwEGpdR4BsB5J0KHkGQGAXQAF14ToPjTOw";
    private string refresh_token = "1//03IU2IIEPTdKeCgYIARAAGAMSNwF-L9IrnsAzIRFCLUjFKG7JQGknE2jswVrNfSMkI4GX53J8GS0eJcVrfC68zRFGKIrmWb9_OLk";

    public TestVGrive() {
        // assign a name for this class
        base("TestVGrive");
        // add test methods
        add_test(" * Test is regular file to be synced (test_is_regular_file)", test_is_regular_file);
        add_test(" * Test a file exists in local file system (test_local_file_exists)", test_local_file_exists);
        add_test(" * Test has credentials (test_has_credentials)", test_has_credentials);
        add_test(" * Test get auth uri (test_get_auth_uri)", test_get_auth_uri);
        add_test(" * Test if is in syncing process (test_is_syncing)", test_is_syncing);
        add_test(" * Test change the main path of vgrive (test_change_main_path)", test_change_main_path);
        add_test(" * Test list files (test_list_files)", test_list_files);
        add_test(" * Test search files and encode for q (test_search_files_and_encode_for_q)", test_search_files_and_encode_for_q);
        add_test(" * Test get file ID and then get its content (test_get_file_id_and_test_get_file_content)", test_get_file_id_and_test_get_file_content);
        add_test(" * Test get file ID of main path and returns root (test_get_file_id_of_main_path)", test_get_file_id_of_main_path);
        add_test(" * Test upload a new file to google drive (main path) and then delete it (test_upload_file_and_delete_file_main_path)", test_upload_file_and_delete_file_main_path);
        add_test(" * Test upload a new file to google drive (subpath) and then delete it (test_upload_file_and_delete_file_other_path)", test_upload_file_and_delete_file_other_path);
        add_test(" * Test upload new version of a file that already exists (test_upload_file_update)", test_upload_file_update);
        add_test(" * Test upload a new directory to google drive (main path) and delete it (test_upload_dir_main_path)", test_upload_dir_main_path);
        add_test(" * Test upload a new directory to google drive (subpath) and delete it (test_upload_dir_other_path)", test_upload_dir_other_path);
        add_test(" * Test if some files are google documents or not (test_is_google_doc_and_is_google_mime_type)", test_is_google_doc_and_is_google_mime_type);
        add_test(" * Test get google drive information of file (test_get_file_info)", test_get_file_info);
        add_test(" * Test get google drive extra information of file (test_get_file_info_extra)", test_get_file_info_extra);
        add_test(" * Test check if there are pending changes in google drive (test_has_remote_changes_and_request_page_token)", test_has_remote_changes_and_request_page_token);
        add_test(" * Test starting a new sync process and stop it (test_start_and_stop_syncing)", test_start_and_stop_syncing);
        add_test(" * Test starting the sync process to check deleted files (test_check_deleted_files)", test_check_deleted_files);
    }

    public override void set_up () {
        if (this.client == null) this.client = new VGriveClient (null, this.mainpath, null);
        this.client.access_token = this.access_token;
        this.client.refresh_token = this.refresh_token;
    }

    public override void tear_down () {
        if (this.client.is_syncing ()) this.client.stop_syncing ();
    }

    private DriveFile add_file_to_drive (string fixture_path, string drive_path="", string drive_id="root") {
        DriveFile res = this.client.upload_file (fixture_path, drive_id);
        string full_path = this.mainpath+"/"+drive_path+fixture_path.split("/")[fixture_path.split("/").length-1];
        File f = File.new_for_path (fixture_path);
        File f2 = File.new_for_path(full_path);
        f.copy (f2, 0, null, null);
        if (this.client.library == null)  this.client.library = this.client.load_library ();
        this.client.library.set(res.id, full_path);
        return res;
    }

    private uint8[]  get_fixture_content(string path, bool delete_final_byte) {
        string abs_path = Environment.get_variable("TESTDIR")+"/fixtures/" + path;
        File file = File.new_for_path (abs_path);
        var file_stream = file.read ();
        var data_stream = new DataInputStream (file_stream);
        uint8[]  contents;
        try {
            try {
                string etag_out;
                file.load_contents (null, out contents, out etag_out);
            }catch (Error e){
                error("%s", e.message);
            }
        }catch (Error e){
            error("%s", e.message);
        }
        if (delete_final_byte) return contents[0:contents.length-1];
        else return contents;
    }

    public void assert_strings(uint8[] res1, uint8[] res2) {
        string s1 = (string)res1;
        string s2 = (string)res2;
        if (s1 == null) s1 = " ";
        if (s2 == null) s2 = " ";
        s1 = s1.strip();
        s2 = s2.strip();
        print("|"+s1+"|"+s2+"|\n");
        assert (s1 == s2);
    }

    public void test_local_file_exists() {
        assert (this.client.local_file_exists(GLib.Environment.get_current_dir()+"/tests/fixtures/.muse.txt") == true);
        assert (this.client.local_file_exists(GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt") == true);
        assert (this.client.local_file_exists(GLib.Environment.get_current_dir()+"/tests/fixtures/muse_no_existeix.txt") == false);
    }

    public void test_is_regular_file() {
        assert (this.client.is_regular_file(".trash") == false);
        assert (this.client.is_regular_file(".vgrive_library") == false);
        assert (this.client.is_regular_file(".page_token") == false);
        assert (this.client.is_regular_file(".muse.txt") == false);
        assert (this.client.is_regular_file("muse.txt") == true);
    }

    public void test_has_credentials () {
        assert (this.client.access_token != "");
        assert (this.client.refresh_token != "");
        assert (this.client.has_credentials () == true);
    }

    public void test_get_auth_uri () {
        string res = this.client.get_auth_uri ();
        assert (res == "https://accounts.google.com/o/oauth2/v2/auth?scope=%s&access_type=offline&redirect_uri=%s&response_type=code&client_id=%s".printf (this.client.scope, this.client.redirect, this.client.client_id));
    }

    public void test_is_syncing () {
        // When it's started is not syncing
        bool is_syncing = this.client.is_syncing ();
        assert (is_syncing == false);
        // Start sync process
        this.client.syncing = true;
        is_syncing = this.client.is_syncing ();
        assert (is_syncing == true);
        // Stop sync process
        this.client.syncing = false;
        is_syncing = this.client.is_syncing ();
        assert (is_syncing == false);
    }

    public void test_change_main_path () {
        /*
         * Test que canvia el directori principal de vgrive a "VGriveTEST_ALT". Al canviar el directori principal es fan les següents accions:
         * - Es posa l'atribut 'syncing' a false
         * - Es canvia l'atribut 'main_path'
         * - Es canvia l'atribut 'trash_path'
         * - Es posa l'atribut 'library' a null
         *
         * Un cop canviat el torna a canviar al original (VGriveTEST)
         * */
        // Primer posem el syncing a true per comprovar realment que el metode el posa a false
        this.client.syncing = true;
        // Ara canviem el directori principal
        this.client.change_main_path (mainpath+"_ALT");
        assert(this.client.syncing == false);
        assert(this.client.main_path == mainpath+"_ALT");
        assert(this.client.trash_path == mainpath+"_ALT/.trash");
        assert(this.client.get_library () == null);
        this.client.change_main_path (mainpath);
        assert(this.client.syncing == false);
        assert(this.client.main_path == mainpath);
        assert(this.client.trash_path == mainpath+"/.trash");
        assert(this.client.get_library () == null);
    }

    public void test_list_files () {
        /*
         * Test que comprova que quan demanem un llistst de fitxers a la API ens retorna lo esperat, que es:
         *
         * GoogleApps/
         *   |- doctest
         *   |- exceltest
         *   |- presentaciotest
         *
         * Muse/
         *   |- Millors/
         *   |    |- 01. Uprising.mp3
         *   |    |- 02. Madness.mp3
         *   |    |- muse.txt
         *   |- Muse - Can't Take My Eyes Off You.mp3
         *
         * test 1 .pdf
         * test é 6 è.png
         * test_ 2_.jpg
         * test' 4'.ods
         * test@ 3@.deb
         * test& 5&.txt.torrent
         * muse.txt
         *
         * */
        string google_apps_id = "";
        string muse_id = "";
        Gee.HashMap<string, bool> files_to_check = new Gee.HashMap<string, bool>();
        files_to_check.set("GoogleApps", false);
        files_to_check.set("doctest", false);
        files_to_check.set("exceltest", false);
        files_to_check.set("presentaciotest", false);
        files_to_check.set("Muse", false);
        files_to_check.set("Millors", false);
        files_to_check.set("Muse - Can't Take My Eyes Off You.mp3", false);
        files_to_check.set("test 1 .pdf", false);
        files_to_check.set("test é 6 è.png", false);
        files_to_check.set("test_ 2_.jpg", false);
        files_to_check.set("test' 4'.ods", false);
        files_to_check.set("test@ 3@.deb", false);
        files_to_check.set("test& 5&.txt.torrent", false);
        files_to_check.set("muse.txt", false);
        // List all files in root
        DriveFile[] all_files = this.client.list_files(-1, "", -1);
        foreach (DriveFile f in all_files) {
            assert (files_to_check.has_key (f.name));
            files_to_check[f.name] = true;
            if (f.name == "GoogleApps") google_apps_id = f.id;
            else if (f.name == "Muse") muse_id = f.id;
        }
        // List files in GoogleApps
        all_files = this.client.list_files(-1, google_apps_id, -1);
        foreach (DriveFile f in all_files) {
            assert (files_to_check.has_key (f.name));
            files_to_check[f.name] = true;
        }
        // List files in GoogleApps
        all_files = this.client.list_files(-1, muse_id, -1);
        foreach (DriveFile f in all_files) {
            assert (files_to_check.has_key (f.name));
            files_to_check[f.name] = true;
        }
        var it = files_to_check.map_iterator ();
        for (var has_next = it.next (); has_next; has_next = it.next ()) {
            assert(it.get_value());
        }
    }

    public void test_search_files_and_encode_for_q () {
        /*
         * Test que busca tots els fitxers amb la paraula "test" i després busca especificament el fitxer amb nom 'test& 5&.txt.torrent'
         *
         * */
        // Tots els fitxers amb la paraula test
        Gee.HashMap<string, bool> files_to_check = new Gee.HashMap<string, bool>();
        files_to_check.set("test 1 .pdf", false);
        files_to_check.set("test é 6 è.png", false);
        files_to_check.set("test_ 2_.jpg", false);
        files_to_check.set("test' 4'.ods", false);
        files_to_check.set("test@ 3@.deb", false);
        files_to_check.set("test& 5&.txt.torrent", false);
        DriveFile[] all_files = this.client.search_files("trashed = False and name contains 'test'");
        foreach (DriveFile f in all_files) {
            assert (files_to_check.has_key (f.name));
            files_to_check[f.name] = true;
        }
        var it = files_to_check.map_iterator ();
        for (var has_next = it.next (); has_next; has_next = it.next ()) {
            assert(it.get_value());
        }
        // El fitxer de nom test& 5&.txt.torrent
        all_files = this.client.search_files("trashed = False and name = '%s'".printf(this.client.encode_for_q ("test& 5&.txt.torrent")));
        assert (all_files[0].name == "test& 5&.txt.torrent");
        assert (all_files.length == 1);
    }

    public void test_get_file_id_and_test_get_file_content () {
        /*
         * Test que obte el ID de un fitxer i després obté el seu contingut.
         *
         * */
        // Fitxer a una subcarpeta
        string file_id = this.client.get_file_id (this.mainpath+"/Muse/Millors/muse.txt");
        assert (file_id != "");
        uint8[] content = this.client.get_file_content (file_id);
        assert_strings (content, get_fixture_content ("muse.txt", false));
        // Fitxer a root
        file_id = this.client.get_file_id (this.mainpath+"/muse.txt");
        assert (file_id != "");
        content = this.client.get_file_content (file_id);
        assert_strings (content, get_fixture_content ("muse.txt", false));
    }

    public void test_get_file_id_of_main_path () {
        /*
         * Test que obte el ID del directori arrel principal. Hauria de retornar 'root'.
         *
         * */
        // Fitxer a una subcarpeta
        string file_id = this.client.get_file_id (this.mainpath);
        assert (file_id == "root");
    }

    public void test_upload_file_and_delete_file_main_path () {
        /*
         * Test que puja el fitxer muse_new_to_upload.txt al Drive. El puja al directori arrel.
         *
         * Després elimina el fitxer pujat.
         *
         * */
        // Pujem el fitxer a root
        var res = this.client.upload_file (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt", "root");
        assert (res.name == "muse_new_to_upload.txt");
        assert (res.id != null);
        assert (res.trashed == false);
        assert (res.parent_id == "root");
        // Fem unes cerques per asegurarnos que si que esta al drive
        DriveFile[] found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res.name));
        assert (found_files.length == 1);
        assert (found_files[0].id == res.id);
        // Eliminem el fitxer
        this.client.delete_file (res.id);
        // Comprovar que s'ha eliminat
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res.name));
        assert (found_files.length == 0);
    }

    public void test_upload_file_and_delete_file_other_path () {
        /*
         * Test que puja el fitxer muse_new_to_upload.txt al Drive. El puja al directori "Muse/Millors".
         *
         * Després elimina el fitxer pujat.
         *
         * */
        // Pujem el fitxer a root
        string muse_parent = this.client.get_file_id (this.mainpath+"/Muse/Millors");
        var res = this.client.upload_file (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt", muse_parent);
        assert (res.name == "muse_new_to_upload.txt");
        assert (res.id != null);
        assert (res.trashed == false);
        assert (res.parent_id == muse_parent);
        // Fem unes cerques per asegurarnos que si que esta al drive
        DriveFile[] found_files = this.client.search_files ("trashed = False and name = '%s' and '%s' in parents".printf (res.name, muse_parent));
        assert (found_files.length == 1);
        assert (found_files[0].id == res.id);
        // Eliminem el fitxer
        this.client.delete_file (res.id);
        // Comprovar que s'ha eliminat
        found_files = this.client.search_files ("trashed = False and name = '%s' and '%s' in parents".printf (res.name, muse_parent));
        assert (found_files.length == 0);
    }

    public void test_upload_file_update () {
        /*
         * Test que puja el fitxer muse_new_to_upload.txt al Drive, després puja el fitxer muse_new_to_upload.v2.txt com a actualitzacio del fitxer muse_new_to_upload.txt.
         *
         * Després elimina el fitxer pujat.
         *
         * */
        // Pujem el fitxer a root
        var res = this.client.upload_file (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt", "root");
        assert (res.name == "muse_new_to_upload.txt");
        assert (res.id != null);
        assert (res.trashed == false);
        assert (res.parent_id == "root");
        // Obtenim el contingut per asegurarnos que la versio es l'antiga
        uint8[] content = this.client.get_file_content (res.id);
        assert_strings (content, get_fixture_content ("muse_new_to_upload.txt", false));
        // Pujem la nova versio
        this.client.upload_file_update (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.v2.txt", res.id);
        // Obtenim el contingut per asegurarnos que la versio es la nova
        content = this.client.get_file_content (res.id);
        assert_strings (content, get_fixture_content ("muse_new_to_upload.v2.txt", false));
        // Eliminem el fitxer
        this.client.delete_file (res.id);
    }

    public void test_upload_dir_main_path () {
        /*
         * Test que puja el directori NewDir al Drive. El puja al directori arrel.
         *
         * Després l'elimina.
         *
         * */
        // Pujem el fitxer a root
        var res = this.client.upload_dir ("NewDir", "root");
        assert (res.name == "NewDir");
        assert (res.id != null);
        assert (res.trashed == false);
        assert (res.parent_id == "root");
        // Fem unes cerques per asegurarnos que si que esta al drive
        DriveFile[] found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res.name));
        assert (found_files.length == 1);
        assert (found_files[0].id == res.id);
        // Eliminem el fitxer
        this.client.delete_file (res.id);
        // Comprovar que s'ha eliminat
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res.name));
        assert (found_files.length == 0);
    }

    public void test_upload_dir_other_path () {
        /*
         * Test que puja el directori NewDir al Drive. El puja al directori "Muse/Millors".
         *
         * Després l'elimina.
         *
         * */
        // Pujem el fitxer a root
        string muse_parent = this.client.get_file_id (this.mainpath+"/Muse/Millors");
        var res = this.client.upload_dir ("NewDir", muse_parent);
        assert (res.name == "NewDir");
        assert (res.id != null);
        assert (res.trashed == false);
        assert (res.parent_id == muse_parent);
        // Fem unes cerques per asegurarnos que si que esta al drive
        DriveFile[] found_files = this.client.search_files ("trashed = False and name = '%s' and '%s' in parents".printf (res.name, muse_parent));
        assert (found_files.length == 1);
        assert (found_files[0].id == res.id);
        // Eliminem el fitxer
        this.client.delete_file (res.id);
        // Comprovar que s'ha eliminat
        found_files = this.client.search_files ("trashed = False and name = '%s' and '%s' in parents".printf (res.name, muse_parent));
        assert (found_files.length == 0);
    }

    public void test_is_google_doc_and_is_google_mime_type () {
        string file_id;
        // Fitxers que no ho son
        // .txt
        file_id = this.client.get_file_id (this.mainpath+"/muse.txt");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .pdf
        file_id = this.client.get_file_id (this.mainpath+"/test 1 .pdf");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .png
        file_id = this.client.get_file_id (this.mainpath+"/test é 6 è.png");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .jpg
        file_id = this.client.get_file_id (this.mainpath+"/test_ 2_.jpg");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .ods
        file_id = this.client.get_file_id (this.mainpath+"/test' 4'.ods");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .deb
        file_id = this.client.get_file_id (this.mainpath+"/test@ 3@.deb");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .torrent
        file_id = this.client.get_file_id (this.mainpath+"/test& 5&.txt.torrent");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // .mp3
        file_id = this.client.get_file_id (this.mainpath+"/Muse/Muse - Can't Take My Eyes Off You.mp3");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // Un directori tampoc ho es
        file_id = this.client.get_file_id (this.mainpath+"/Muse");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == false);
        // Fitxer que si que ho son
        // .docx
        file_id = this.client.get_file_id (this.mainpath+"/GoogleApps/doctest");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == true);
        // .xlsx
        file_id = this.client.get_file_id (this.mainpath+"/GoogleApps/exceltest");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == true);
        // .pptx
        file_id = this.client.get_file_id (this.mainpath+"/GoogleApps/presentaciotest");
        assert (file_id != null);
        assert (file_id != "");
        assert (this.client.is_google_doc (file_id) == true);
    }

    public void test_get_file_info() {
        /*
         * Test que obte la informacio del drive de un fitxer. Donat un nom i un paremt_id retorna un DriveFile amb la infor del fitxer.
         *
         * Primer s'obte la info de un fitxer a l'arrel, després de un fitxer a Muse/, després de un dorectori i finalment de un google doc.
         *
         * */
        DriveFile f;
        // Fitxer a root
        f = this.client.get_file_info ("test& 5&.txt.torrent");
        assert (f.kind == "drive#file");
        assert (f.id != null);
        assert (f.name == "test& 5&.txt.torrent");
        assert (f.mimeType == "application/x-bittorrent");
        assert (f.parent_id != null);
        assert (f.modifiedTime != null);
        assert (f.createdTime != null);
        assert (f.trashed == false);
        // Fitxer a subdirectori
        string parent_id = this.client.get_file_id (this.mainpath+"/Muse");
        f = this.client.get_file_info ("Muse - Can't Take My Eyes Off You.mp3", parent_id);
        assert (f.kind == "drive#file");
        assert (f.id != null);
        assert (f.name == "Muse - Can't Take My Eyes Off You.mp3");
        assert (f.mimeType == "audio/mp3");
        assert (f.parent_id != null);
        assert (f.modifiedTime != null);
        assert (f.createdTime != null);
        assert (f.trashed == false);
        // Carpeta
        f = this.client.get_file_info ("Muse");
        assert (f.kind == "drive#file");
        assert (f.id != null);
        assert (f.name == "Muse");
        assert (f.mimeType == "application/vnd.google-apps.folder");
        assert (f.parent_id != null);
        assert (f.modifiedTime != null);
        assert (f.createdTime != null);
        assert (f.trashed == false);
        // Google doc
        parent_id = this.client.get_file_id (this.mainpath+"/GoogleApps");
        f = this.client.get_file_info ("doctest", parent_id);
        assert (f.kind == "drive#file");
        assert (f.id != null);
        assert (f.name == "doctest");
        assert (f.mimeType == "application/vnd.google-apps.document");
        assert (f.parent_id != null);
        assert (f.modifiedTime != null);
        assert (f.createdTime != null);
        assert (f.trashed == false);
    }

    public void test_get_file_info_extra() {
        /*
         * Test que obte informacio extra de un fitxer.
         * Pregunta els atributs "modifiedTime" i "mimeType" junts i per separat de un fitxer i un directori.
         *
         * */
        DriveFile f;
        string file_id;
        // Fitxer a root
        file_id = this.client.get_file_id (this.mainpath+"/test& 5&.txt.torrent");
        f = this.client.get_file_info_extra (file_id, "modifiedTime");
        assert (f.modifiedTime != null);
        f = this.client.get_file_info_extra (file_id, "mimeType");
        assert (f.mimeType == "application/x-bittorrent");
        f = this.client.get_file_info_extra (file_id, "modifiedTime,mimeType");
        assert (f.modifiedTime != null);
        assert (f.mimeType == "application/x-bittorrent");
        // Fitxer a subdirectori
        file_id = this.client.get_file_id (this.mainpath+"/Muse/Muse - Can't Take My Eyes Off You.mp3");
        f = this.client.get_file_info_extra (file_id, "modifiedTime");
        assert (f.modifiedTime != null);
        f = this.client.get_file_info_extra (file_id, "mimeType");
        assert (f.mimeType == "audio/mp3");
        f = this.client.get_file_info_extra (file_id, "modifiedTime,mimeType");
        assert (f.modifiedTime != null);
        assert (f.mimeType == "audio/mp3");
        // Carpeta
        file_id = this.client.get_file_id (this.mainpath+"/Muse");
        f = this.client.get_file_info_extra (file_id, "modifiedTime");
        assert (f.modifiedTime != null);
        f = this.client.get_file_info_extra (file_id, "mimeType");
        assert (f.mimeType == "application/vnd.google-apps.folder");
        f = this.client.get_file_info_extra (file_id, "modifiedTime,mimeType");
        assert (f.modifiedTime != null);
        assert (f.mimeType == "application/vnd.google-apps.folder");
        // Google doc
        file_id = this.client.get_file_id (this.mainpath+"/GoogleApps/doctest");
        f = this.client.get_file_info_extra (file_id, "modifiedTime");
        assert (f.modifiedTime != null);
        f = this.client.get_file_info_extra (file_id, "mimeType");
        assert (f.mimeType == "application/vnd.google-apps.document");
        f = this.client.get_file_info_extra (file_id, "modifiedTime,mimeType");
        assert (f.modifiedTime != null);
        assert (f.mimeType == "application/vnd.google-apps.document");
    }

    public void test_has_remote_changes_and_request_page_token() {
        /*
         * Test comprova si hi ha canvis al google drive:
         * - Es demana un pageToken inicial amb el qual es comprova si hi ha canvis.
         * - No n'hi hauria d'haver ja que acavem de obtenir el pageToken per tant apunta a la versio més recent.
         * - Es puja un nou fitxer. Ho ha de detectar com a canvis
         * - Es torna a preguntar i ha de dir que no hi ha més canvis.
         * - Es puja una nova versio del fitxer i es torna a preguntar si hi ha canvis. N'hi hauria de haver.
         * - Tornem a preguntar si hi ha canvis i ja no n'hi hauria de haver.
         * - Eliminem el fitxer, ho ha de detectar com a canvis.
         * - Tornem a preguntar i ja no hauria de haver canvis
         *
         * */
        string pageToken = this.client.request_page_token ();
        assert (pageToken != null);
        this.client.page_token = pageToken;
        // Com que en els tests es fan canvis es possible que el primer cop que demanem ens digui que hi ha canvis pendents desde l'ultim cop que vam preguntar
        this.client.has_remote_changes (this.client.page_token);
        // Quan preguntem per primer cop no hi ha canvis
        assert (this.client.has_remote_changes (this.client.page_token) == false);
        // Pujem un canvi i tornem a preguntar, ho hauria de detectar
        var res = this.client.upload_file (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt", "root");
        assert (this.client.has_remote_changes (this.client.page_token) == true);
        assert (this.client.has_remote_changes (this.client.page_token) == false);
        // Pujem una nova versio del fitxer, ha de haverhi canvis
        this.client.upload_file_update (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.v2.txt", res.id);
        assert (this.client.has_remote_changes (this.client.page_token) == true);
        assert (this.client.has_remote_changes (this.client.page_token) == false);
        // Eliminem el fitxer pujat, ho ha de detectar com a canvis (a mes aixi deixem net el google drive)
        this.client.delete_file (res.id);
        assert (this.client.has_remote_changes (this.client.page_token) == true);
        assert (this.client.has_remote_changes (this.client.page_token) == false);
        // Fem varis canvis alhora i ho ha de detectar el primer cop nomes
        res = this.client.upload_file (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt", "root");
        this.client.upload_file_update (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.v2.txt", res.id);
        assert (this.client.has_remote_changes (this.client.page_token) == true);
        assert (this.client.has_remote_changes (this.client.page_token) == false);
        this.client.delete_file (res.id);
        assert (this.client.has_remote_changes (this.client.page_token) == true);
        assert (this.client.has_remote_changes (this.client.page_token) == false);
    }

    public void test_start_and_stop_syncing () {
        /*
         * Test que inicia el proces de sincronitzacio. Al iniciarse es fa el següent:
         * - Es posa a true la variable 'syncing'
         * - Crea el directori main_path si no existeix
         * - Crea el directori trash_path si no existeix
         * - Inicialitza la llibreria (atribut 'library')
         * - Inicia un nou thread que executa el métode 'sync_files'. Aquest thread es guarda al atribut 'thread'.
         *
         *
         * Després es comprova que no hi hagi hagut cap canvi, ja que nongu ha tocat res es suposa.
         *
         * Finalment atura el procés amb 'stop_syncing'. Al fer-ho es fan les següents accions:
         * - Es posa a false la variable 'syncing'
         * - Es fa el join amb el thread del atribut 'thread'
         *
         * */
        // Primer eliminem els directoris main_path i trash_path perque es tornin a crear despres.
        // Ja existien perque al crear el VGriveClient es crean.
        File mainDir = File.new_for_path (mainpath);
        File trashDir = File.new_for_path (mainpath+"/.trash");
        assert (mainDir.query_exists () == true);
        assert (trashDir.query_exists () == true);
        try {
            trashDir.delete ();
            mainDir.delete ();
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }
        assert (mainDir.query_exists () == false);
        assert (trashDir.query_exists () == false);
        // Iniciem la sincronitzacio. Comprovarem que fa les 5 accions que esperem
        this.client.start_syncing ();
        assert (this.client.syncing == true);
        assert (mainDir.query_exists () == true);
        assert (trashDir.query_exists () == true);
        assert (this.client.get_library () != null);
        assert (this.client.thread != null);
        // Comprovem que no hi hagi hagut cap canvi detectat
        assert (this.client.change_detected == false);
        // Parem de sincronitzar i comprovem que ha fet les dos accions que ha de realitzar
        this.client.stop_syncing ();
        assert (this.client.syncing == false);
        assert (this.client.thread == null);
    }

    public void test_check_deleted_files () {
        /*
         * Test que comprova que es sincornitzin correctament els fitxers eliminats:
         * Es puja 3 fitxers nous:
         *    - muse_new_to_upload.txt
         *    - muse_new_to_upload.v2.txt
         *    - muse_new_to_upload.v3.txt
         *
         * S'elimina el fitxer local muse_new_to_upload.v3.txt
         * S'elimina el fitxer remot muse_new_to_upload.v2.txt
         *
         * S'executa el check_deleted_files
         * - El métode ha de eliminar el fitxer remot muse_new_to_upload.v3.txt
         * - El métode ha de eliminar el fitxer local muse_new_to_upload.v2.txt
         * - El fitxer muse_new_to_upload.txt ha de continuar existint als dos llocs
         *
         * Després s'elimina el muse_new_to_upload.txt per deixar-ho net
         *
         * */
        // Ho preparem tot
        DriveFile res = this.add_file_to_drive (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.txt", "", "root");
        DriveFile res2 = this.add_file_to_drive (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.v2.txt", "", "root");
        DriveFile res3 = this.add_file_to_drive (GLib.Environment.get_current_dir()+"/tests/fixtures/muse_new_to_upload.v3.txt", "", "root");
        this.client.move_local_file_to_trash(this.mainpath+"/muse_new_to_upload.v3.txt");
        this.client.delete_file(res2.id);

        File f = File.new_for_path(this.mainpath+"/muse_new_to_upload.txt");
        assert(f.query_exists() == true);
        DriveFile[] found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res.name));
        assert (found_files.length == 1);

        f = File.new_for_path(this.mainpath+"/muse_new_to_upload.v2.txt");
        assert(f.query_exists() == true);
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res2.name));
        assert (found_files.length == 0);

        f = File.new_for_path(this.mainpath+"/muse_new_to_upload.v3.txt");
        assert(f.query_exists() == false);
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res3.name));
        assert (found_files.length == 1);

        // Executem el metode
        this.client.syncing = true;
        this.client.check_deleted_files ();

        // Comprovem que hagi passat el que esperavem
        f = File.new_for_path(this.mainpath+"/muse_new_to_upload.txt");
        assert(f.query_exists() == true);
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res.name));
        assert (found_files.length == 1);

        f = File.new_for_path(this.mainpath+"/muse_new_to_upload.v2.txt");
        assert(f.query_exists() == false);
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res2.name));
        assert (found_files.length == 0);

        f = File.new_for_path(this.mainpath+"/muse_new_to_upload.v3.txt");
        assert(f.query_exists() == false);
        found_files = this.client.search_files ("trashed = False and name = '%s' and 'root' in parents".printf (res3.name));
        assert (found_files.length == 0);

        // Netegem fitxers
        this.client.delete_file (res.id);
    }
}

