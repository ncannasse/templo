class Run {

	static function main() {
		var dir = neko.Sys.args().pop();
		var p = new neko.io.Process("nekotools",["boot","temploc2.n"]);
		var code = p.exitCode();
		if( code != 0 ) throw "Error while creating bootable executable";
		var sys = neko.Sys.systemName();
		var exe = if( sys == "Windows" ) "temploc2.exe" else "temploc2";
		neko.io.File.copy(exe,dir+exe);
		if( sys != "Windows" )
			neko.Sys.command("chmod +x "+dir+exe);
		neko.FileSystem.deleteFile(exe);
		neko.Lib.println(exe+" is now available in the current directory");
	}

}