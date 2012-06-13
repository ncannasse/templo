class Run {

	static function main() {
		var dir = Sys.args().pop();
		var p = new sys.io.Process("nekotools",["boot","temploc2.n"]);
		var code = p.exitCode();
		if( code != 0 ) throw "Error while creating bootable executable";
		var system = Sys.systemName();
		var exe = if( system == "Windows" ) "temploc2.exe" else "temploc2";
		sys.io.File.copy(exe,dir+exe);
		if( system != "Windows" )
			Sys.command("chmod +x "+dir+exe);
		sys.FileSystem.deleteFile(exe);
		Sys.println(exe+" is now available in the current directory");
	}

}