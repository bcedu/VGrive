using App;

// https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/drive&access_type=offline&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=8532198801-7heceng058ouc4mj495a321s8s96b0e5.apps.googleusercontent.com

class TestVGrive : Gee.TestCase {

    private VGriveClient client;
    private string mainpath = GLib.Environment.get_current_dir()+"/.testbuild/VGriveTEST";
    private string access_token = "ya29.Il-1B3LBSkPsLym3fwBYl5yB0oDJ8VMNiP1Rr3CLRPxPtxiVYWBEpRIVhxMVWcx7FAOZVVRR5tNC6lXk-0OmZ6hHjEJH3qrd7cIn0DLruxiHRe8VbpVmHvu5RImxOpSAsg";
    private string refresh_token = "1//03FuFl61Tq1JyCgYIARAAGAMSNwF-L9IrZksc48dnu3Bfid3-2h2XtW-zl-s1DaPSvVNoL3bq_IjRUhiqsixywVSq22VoO8_zDUg";

    public TestVGrive() {
        // assign a name for this class
        base("TestVGrive");
        // add test methods
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
        add_test(" * Test starting a new sync process and stop it (test_start_and_stop_syncing)", test_start_and_stop_syncing);
    }

    public override void set_up () {
        if (this.client == null) this.client = new VGriveClient (null, this.mainpath, null);
        this.client.access_token = this.access_token;
        this.client.refresh_token = this.refresh_token;
    }

    public override void tear_down () {
        if (this.client.is_syncing ()) this.client.stop_syncing ();
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
        assert (s1 == s2);
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
         *   |- doctest.docx
         *   |- exceltest.xlsx
         *   |- presentaciotest.pptx
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
         *
         * */
        string google_apps_id = "";
        string muse_id = "";
        Gee.HashMap<string, bool> files_to_check = new Gee.HashMap<string, bool>();
        files_to_check.set("GoogleApps", false);
        files_to_check.set("doctest.docx", false);
        files_to_check.set("exceltest.xlsx", false);
        files_to_check.set("presentaciotest.pptx", false);
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

}

