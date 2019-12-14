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
        add_test(" * Test list files (test_list_files)", test_list_files);
        add_test(" * Test search files and encode for q (test_search_files_and_encode_for_q)", test_search_files_and_encode_for_q);
        add_test(" * Test get file ID and then get its content (test_get_file_id_and_test_get_file_content)", test_get_file_id_and_test_get_file_content);
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

}

