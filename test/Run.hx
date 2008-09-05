class Run {

	static function main() {
		var dir = neko.Sys.args().pop();
		var p = new neko.io.Process("nekotools",["boot","temploc2.n"]);
		var code = p.exitCode();
		if( code != 0 ) throw "Error while creating bootable executable";
		var exe = if( neko.Sys.systemName() == "Windows" ) "temploc2.exe" else "temploc2";
		neko.io.File.copy(exe,dir+exe);
		neko.FileSystem.deleteFile(exe);
		neko.Lib.println(exe+" is now available in the current directory");
	}

}