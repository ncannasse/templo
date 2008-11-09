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

#if neko

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
	var cache : Bool;

	public function new( file:String, ?cache : Bool ) {
		if( !OPTIMIZED )
			compileTemplate(file);
		this.cache = cache;
		loadTemplate(tmpFileId(file));
	}

	public function execute( ctx : Dynamic ) {
		var buf = buffer_new();
		var cache = saveCache();
		try {
			run(buf,ctx);
		} catch( e : Dynamic ) {
			restoreCache(cache);
			neko.Lib.rethrow(e);
		}
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
		var output = p.stderr.readAll();
		if( p.exitCode() != 0 )
			throw "Temploc compilation of "+path+" failed : "+output;
	}

	function loadTemplate( nPath:String ) {
		var loader : Dynamic = untyped __dollar__loader;
		loader.__templo = API;
		var cache = saveCache();
		var exports : Dynamic = null;
		try {
			exports = loader.loadmodule(neko.NativeString.ofString(nPath), loader);
		} catch( e : Dynamic ) {
			restoreCache(cache);
			neko.Lib.rethrow(e);
		}
		restoreCache(cache);
		run = exports.execute;
		macros = exports.macros;
	}

	function saveCache() : Dynamic {
		if( cache ) return null;
		return untyped __dollar__new(__dollar__loader.cache);
	}

	function restoreCache( c : Dynamic ) {
		if( !cache )
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
			new Loader(file,true).run(buf,ctx);
			ctx.__content__ = old;
		},
		macros : function( file : String, m : Dynamic ) {
			new Loader(file,true).macros(m);
		}
	};

}

#elseif php

class Loader {

	public static var BASE_DIR = "";
	public static var TMP_DIR = "/tmp/";
	public static var MACROS = "macros.mtt";
	public static var OPTIMIZED = false;
	public static var DEBUG = false;

	var file : String;
	var templatename : String;

	public function new( file:String ) {
		if( !OPTIMIZED )
			compileTemplate(file);
		this.templatename = file;
		this.file = tmpFileId(file);
	}

	public function execute( ctx : Dynamic ) : String {
		if(ctx == null) ctx = {};
		cache_macro_functions = new Hash();

		if(MACROS != null && MACROS != '') {
			var macrosfiles = MACROS.split(' ');
			if( !OPTIMIZED ) {
				for(mf in macrosfiles)
					compileTemplate(mf);
			}
			for(mf in macrosfiles)
				untyped __call__("require_once", tmpFileId(mf));
			macrosprefixes = getMacroPrefixes([templatename].concat(macrosfiles));
		} else {
			macrosprefixes = getMacroPrefixes([templatename]);
		}

		var container = null;
		bufferReset();
		bufferCreate();
		untyped __call__("require", file);
		return bufferPop();
	}

	var buf : String;
	var b : Array<String>;
	var content : String;
	function bufferReset() {
		b = [];
		content = null;
	}

	function bufferCreate() {
		var len = b.length;
		if(len > 0) {
			b[len-1] += buf;
			buf = '';
		}
		b.push('');
	}

	function bufferPop() {
		var len = b.length;
		b[len-1] += buf;
		buf = '';
		return b.pop();
	}

	function includeTemplate( file : String, container : String, ctx : Dynamic ) {
		var old_content = content;
		content = bufferPop();
		if( !OPTIMIZED )
			compileTemplate(file);
		untyped __call__("require", tmpFileId(file));
		content = old_content;
	}

	function tmpFileId( path:String ) : String {
		if( path.charAt(0) == "/" ) path = path.substr(1);
		path = (~/[\/:\\]+/g).replace(path, "__");
		return TMP_DIR + path + ".php";
	}

	function getMacroPrefixes( paths : Array<String> ) : Array<String> {
		var prefixes = [];
		var re = new EReg("[/:.\\-]+", "g");
		for(path in paths) {
			if( path.charAt(0) == "/" ) path = path.substr(1);
			prefixes.push(re.replace(path, "__"));
		}
		return prefixes;
	}

	var cache_macro_functions : Hash<String>;
	var macrosprefixes : Array<String>;
	function macro(name : String, args : Dynamic) {
		if(cache_macro_functions.exists(name))
			return untyped __call__("call_user_func_array", cache_macro_functions.get(name), args);

		for(pre in macrosprefixes) {
			var n = pre+'_'+name;
			if(untyped __call__("function_exists", n)) {
				cache_macro_functions.set(name, n);
				return untyped __call__("call_user_func_array", n, args);
			}
		}
		throw "invalid macro call to " + name;
	}

	function compileTemplate( path:String ) : Void {
		var tmpFile = tmpFileId(path);
		if( php.FileSystem.exists(tmpFile) ) {
			var macroStamp = MACROS != null && php.FileSystem.exists(BASE_DIR+MACROS) ? php.FileSystem.stat(BASE_DIR+MACROS).mtime.getTime() : null;
			var sourceStamp = php.FileSystem.stat(BASE_DIR+path).mtime.getTime();
			var stamp = php.FileSystem.stat(tmpFile).mtime.getTime();
			if( stamp >= sourceStamp && (macroStamp == null || macroStamp < stamp) )
				return;
		}
		var result = 0;
		var args = new Array();
		args.push("-php");
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
		var p = new php.io.Process("temploc2",args);
		var code = p.exitCode();
		if( code != 0 )
			throw "Temploc compilation of "+path+" failed : "+p.stderr.readAll().toString();
	}

	static function __init__() {
		untyped __php__("
function _hxtemplo_substr($s, $p) {
	if(is_string($s)) {
		return _hx_substr($s, $p[0], count($p) > 1 ? $p[1] : null);
	} else {
		return call_user_func_array(array($s, 'substr'), $p);
	}
}

function _hxtemplo_charAt($s, $p) {
	if(is_string($s)) {
		return substr($s, $p[0], 1);
	} else {
		return call_user_func_array(array($s, 'charAt'), $p);
	}
}

function _hxtemplo_cca($s, $p) {
	if(is_string($s)) {
		return ord($s{$p[0]});
	} else {
		return call_user_func_array(array($s, 'cca'), $p);
	}
}

function _hxtemplo_charCodeAt($s, $p) {
	if(is_string($s)) {
		return _hx_char_code_at($s, $p[0]);
	} else {
		return call_user_func_array(array($s, 'charCodeAt'), $p);
	}
}

function _hxtemplo_indexOf($s, $p) {
	if(is_string($s)) {
		return _hx_index_of($s, $p[0]);
	} else {
		return call_user_func_array(array($s, 'indexOf'), $p);
	}
}

function _hxtemplo_lastIndexOf($s, $p) {
	if(is_string($s)) {
		return _hx_last_index_of($s, $p[0]);
	} else {
		return call_user_func_array(array($s, 'lastIndexOf'), $p);
	}
}

function _hxtemplo_length($v) {
	if(is_string($v)) {
		return str_len($v);
	} else {
		return $v->length;
	}
}

function _hxtemplo_split($s, $p) {
	if(is_string($s)) {
		return new _hx_array(explode($p[0], $s));
	} else {
		return call_user_func_array(array($s, 'split'), $p);
	}
}

function _hxtemplo_toLowerCase($s, $p) {
	if(is_string($s)) {
		return strtolower($s);
	} else {
		return call_user_func_array(array($s, 'toLowerCase'), $p);
	}
}

function _hxtemplo_toUpperCase($s, $p) {
	if(is_string($s)) {
		return strtoupper($s);
	} else {
		return call_user_func_array(array($s, 'toUpperCase'), $p);
	}
}

function _hxtemplo_toString($s, $p) {
	if(is_string($s)) {
		return $s;
	} else if(is_array($s)) {
		return '['.join(', ',$s).']';
	} else {
		return call_user_func_array(array($s, 'toString'), $p);
	}
}

function _hxtemplo_is_true($v) { return $v !== null && $v !== false; }

function _hxtemplo_string($s) {
	if($s === true)
		return 'true';
	else if($s === false)
		return 'false';
	else if($s === 0)
		return '0';
	else if($s === null)
		return 'null';
	else if(is_array($s)) {
		return htmlspecialchars('['.join(', ',$s).']');
	} else if(is_object($s))
		if(method_exists($s, 'toString'))
			return htmlspecialchars($s->toString());
		else
			return htmlspecialchars(''.$s);
	else
		return htmlspecialchars($s);
}

function _hxtemplo_repeater($it) {
	if($it == null)
		//TODO: is this correct or it should return an error?
		return new _hxtemplo_repeater_decorator(new _hx_array(array()));
	else
		return new _hxtemplo_repeater_decorator($it);
}

function _hxtemplo_add($v1, $v2) {
	if(is_null($v1)) $v1 = 'null';
	if(is_null($v2)) $v2 = 'null';

	if(is_numeric($v1) && is_numeric($v2))
		return $v1+$v2;
	return $v1.$v2;
}

class _hxtemplo_repeater_decorator {
	var $it;
	var $index = -1;
	var $number = 0;
	var $odd = false;
	var $even = true;
	var $first = true;
	var $last = false;
	var $size = null;
	function __construct($it) {
		if(isset($it->length)) {
			$this->size = $it->length;
		} else if(method_exists($it, 'get_length')) {
			$this->size = $it->get_length();
		} else if(method_exists($it, 'size')) {
			$this->size = $it->size();
		}
		if(method_exists($it, 'iterator'))
			$this->it = $it->iterator();
		else
			$this->it = $it;
	}

	function hasNext() {
		return $this->it->hasNext();
	}

	function next() {
		$this->index++;
		$this->number++;
		$this->odd = !$this->odd;
		$this->even = !$this->even;
		$this->first = $this->index == 0;
		$this->last = $this->size == $this->number;
		return $this->it->next();
	}
}
");
	}
}
#end