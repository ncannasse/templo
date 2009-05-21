enum E {
	A;
	B;
	C;
	D;
	E;
	F;
}

class Test {

	static function main() {
		templo.Loader.DEBUG = true;
		templo.Loader.TMP_DIR = "";
		try neko.FileSystem.deleteFile("test.mtt.n") catch( e : Dynamic ) {};
		var t = new templo.Loader("test.mtt");
		//trace( t.execute({ values : -1...7 }) );
		trace( t.execute({ values : [A,B,C,D,E,F] }) );
	}

}