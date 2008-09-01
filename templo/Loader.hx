/*
 * Copyright (c) 2006-2008, Motion-Twin
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY MOTION-TWIN "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package templo;

private typedef Iter = {
	var __it : Iterator<Dynamic>;
	var current : Dynamic;
	var index : Int;
	var number : Int;
	var first : Bool;
	var last : Bool;
	var odd : Bool;
	var even : Bool;
	var size : Null<Int>;
};

private extern enum Buffer {
}

class Loader {

	public static var BASE_DIR = "";
	public static var TMP_DIR = "/tmp/";
	public static var MACROS = "macros.mtt";
	public static var OPTIMIZED = false;
	public static var DEBUG = false;

	var run : Buffer -> Dynamic -> String;
	var macros : Dynamic -> Void;

	public function new( file:String ) {
		if( !OPTIMIZED )
			compileTemplate(file);
		loadTemplate(tmpFileId(file));
	}

	public function execute( ctx : Dynamic ) {
		var buf = buffer_new();
		var cache = saveCache();
		run(buf,ctx);
		restoreCache(cache);
		return neko.NativeString.toString(buffer_string(buf));
	}

	function tmpFileId( path:String ) : String {
		if( path.charAt(0) == "/" ) path = path.substr(1);
		path = path.split("/").join("__");
		path = path.split("\\").join("__");
		path = path.split(":").join("__");
		path = path.split("____").join("__");
		return TMP_DIR + path + ".n";
	}

	function compileTemplate( path:String ) : Void {
		var tmpFile = tmpFileId(path);
		if( neko.FileSystem.exists(tmpFile) ) {
			var macroStamp = if( neko.FileSystem.exists(BASE_DIR+MACROS) ) neko.FileSystem.stat(BASE_DIR+MACROS).mtime.getTime() else null;
			var sourceStamp = neko.FileSystem.stat(BASE_DIR+path).mtime.getTime();
			var stamp = neko.FileSystem.stat(tmpFile).mtime.getTime();
			if( stamp >= sourceStamp && (macroStamp == null || macroStamp < stamp) )
				return;
		}
		var result = 0;
		var args = new Array();
		if( MACROS != null ) {
			args.push("-macros");
			args.push(MACROS);
		}
		if( DEBUG )
			args.push("-debug");
		args.push("-cp");
		args.push(BASE_DIR);
		args.push("-output");
		args.push(TMP_DIR);
		args.push(path);
		var p = new neko.io.Process("temploc2",args);
		if( p.exitCode() != 0 )
			throw "Temploc compilation of "+path+" failed : "+p.stderr.readAll();
	}

	function loadTemplate( nPath:String ) {
		var loader : Dynamic = untyped __dollar__loader;
		loader.__templo = API;
		var cache = saveCache();
		var exports : Dynamic = loader.loadmodule(neko.NativeString.ofString(nPath), loader);
		restoreCache(cache);
		run = exports.execute;
		macros = exports.macros;
	}

	function saveCache() : Dynamic {
		return untyped __dollar__new(__dollar__loader.cache);
	}

	function restoreCache( c : Dynamic ) {
		untyped __dollar__loader.cache = c;
	}

	static var buffer_new : Dynamic = neko.Lib.load("std","buffer_new",0);
	static var buffer_add : Dynamic = neko.Lib.load("std","buffer_add",2);
	static var buffer_string : Dynamic = neko.Lib.load("std","buffer_string",1);
	static var string_split : Dynamic = neko.Lib.load("std","string_split",2);

	static var API = {
		open : buffer_new,
		add : buffer_add,
		close : buffer_string,
		split : string_split,
		String : String,
		Array : Array,
		iter : function( data : Dynamic ) : Iter {
			var it : Iterator<Dynamic>;
			var size : Null<Int> = null;
			if( data == null )
				throw "Cannot iterate on null";
			if( data.iterator != null ) {
				untyped if( __dollar__typeof(data.length) == __dollar__tint ) size = data.length;
				it = data.iterator();
			} else if( data.hasNext != null && data.next != null )
				it = data;
			else
				throw "The value must be iterable";
			return {
				__it : it,
				current : null,
				index : 0,
				number : 1,
				first : true,
				last : false,
				odd : true,
				even : false,
				size : size,
			};
		},
		loop : function( i : Iter, callb, b, ctx ) {
			var it = i.__it;
			var k = 1;
			var even = false;
			while( it.hasNext() ) {
				var v = it.next();
				i.current = v;
				callb(v,b,ctx);
				// update fields
				i.first = false;
				i.index = k;
				k++;
				i.number = k;
				i.last = (k == i.size);
				i.odd = even;
				even = !even;
				i.even = even;
			}
		},
		use : function( file : String, buf : Buffer, ctx : Dynamic, content : Buffer -> Dynamic -> Void ) {
			var tmp = buffer_new();
			content(tmp,ctx);
			var old = ctx.__content__;
			ctx.__content__ = neko.NativeString.toString( buffer_string(tmp) );
			tmp = null;
			new Loader(file).run(buf,ctx);
			ctx.__content__ = old;
		},
		macros : function( file : String, m : Dynamic ) {
			new Loader(file).macros(m);
		}
	};

}
