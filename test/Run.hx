class Run {

	static function main() {
		mtwin.templo2.Loader.DEBUG = true;
		mtwin.templo2.Loader.TMP_DIR = "";
		try neko.FileSystem.deleteFile("test.mtt.n") catch( e : Dynamic ) {};
		var t = new mtwin.templo2.Loader("test.mtt");
		trace( t.execute({ x : "cou<b>cou</b>" }) );
	}

}