import templo.Loader;

#if neko
import neko.FileSystem;
import neko.io.File;
import neko.Sys;
#else
import php.FileSystem;
import php.io.File;
import php.Sys;
#end

class Test {
	static var tests = [
		{
			name : "empty", test : "emptytest.mtt", macros : "emptymacros.mtt",
			context : {}
		}, {
			name : "simple-var-output", test : "simplevar.mtt", macros : null,
			context : { value : "haXe" }
		}, {
			name : "var-output-html", test : "simplevar.mtt", macros : null,
			context : { value : "<a title='\"' href='a.n?a=a&c=c'>ба&agrave;'\"</a>" }
		}, {
			name : "var-output-html-raw", test : "simplevar.mtt", macros : null,
			context : { value : "<a title='\"' href='a.n?a=a&c=c'>ба&agrave;'\"</a>" }
		}, {
			name : "if-true-else", test : "ifelse.mtt", macros : null,
			context : { vtrue : true }
		}, {
			name : "if-false-else", test : "ifelse.mtt", macros : null,
			context : { vtrue : false }
		}, {
			name : "if-null-else", test : "ifelse.mtt", macros : null,
			context : { vtrue : null }
		}, {
			name : "if-empty-else", test : "ifelse.mtt", macros : null,
			context : { vtrue : '' }
		}, {
			name : "if-zero-else", test : "ifelse.mtt", macros : null,
			context : { vtrue : 0 }
		}, {
			name : "if-one-else", test : "ifelse.mtt", macros : null,
			context : { vtrue : 1 }
		}, {
			name : "cond-compare-empty", test : "compare.mtt", macros : null,
			context : { value : "" }
		}, {
			name : "cond-compare-string", test : "compare.mtt", macros : null,
			context : { value : "a" }
		}, {
			name : "cond-compare-null", test : "compare.mtt", macros : null,
			context : { value : null }
		}, {
			name : "cond-compare-zero", test : "compare.mtt", macros : null,
			context : { value : 0 }
		}, {
			name : "cond-compare-num", test : "compare.mtt", macros : null,
			context : { value : 1 }
		}
	];

	public static function main() {
		var base = Sys.getCwd();
		Loader.BASE_DIR = base + "mtts/";
		Loader.TMP_DIR  = base + "tpl/";

		cleanCache();
		performTests();
		checkTests();
	}

	static function cleanCache() {
		var files = FileSystem.readDirectory(Loader.TMP_DIR);
		for(file in files) {
			if(file == '.' || file == '..') continue;
			FileSystem.deleteFile(Loader.TMP_DIR+file);
		}
	}

	static function checkTests() {
#if php
		php.Lib.print("<pre>");
#end
		for(test in tests) {
			var nfile = "results/neko/"+test.name+".txt";
			var pfile = "results/php/"+test.name+".txt";
			if(!FileSystem.exists(nfile)) {
				trace("Unable to compare '" + test.name + "' because the Neko version is missing");
				continue;
			}
			if(!FileSystem.exists(pfile)) {
				trace("Unable to compare '" + test.name + "' because the PHP version is missing");
				continue;
			}
			var n = File.getContent(nfile);
			var p = File.getContent(pfile);
			if(n == p)
				trace("OK: " + test.name);
			else
				trace("ERROR: " + test.name + " are different!");
		}
	}

	static function performTests() {
		for(test in tests) {
			Loader.MACROS = test.macros;
			var loader = new Loader(test.test);
			var result = loader.execute(test.context);
			var name = #if neko "results/neko/" #else "results/php/" #end+test.name+".txt";
			var f = File.write(name, true);
			f.writeString(result);
			f.close();
		}
	}
}