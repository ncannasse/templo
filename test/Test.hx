enum E {
	A;
	B;
	C;
	D( v : Int );
	E;
	F;
}

class Test {

	static function main() {
		templo.Loader.TMP_DIR = "";
		try sys.FileSystem.deleteFile("test.mtt.n") catch( e : Dynamic ) {};
		var t = new templo.Loader("test.mtt");
		//trace( t.execute({ values : -1...7 }) );
		trace( t.execute({ values : [A,B,C,D(55),E,F] }) );
	}

}