class Run {

	static function main() {
		templo.Loader.DEBUG = true;
		templo.Loader.TMP_DIR = "";
		try neko.FileSystem.deleteFile("test.mtt.n") catch( e : Dynamic ) {};
		var t = new templo.Loader("test.mtt");
		trace( t.execute({ x : "cou<b>cou</b>" }) );
	}

}