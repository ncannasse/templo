# Haxe Templo Template Engine

The templo Template class provides advanced templating support.

_Works in Haxe sys, neko and php_

### Installation

Install the library via [haxelib](http://lib.haxe.org/p/templo)
``` 
haxelib install templo 
```

### Usage
```
var loader = new Loader(file);
var template = loader.execute(ctx);
```

### Examples

Templo directives start with two double-dots: `::directive`.

The best way is to learn using the examples, which can be found here: 
https://github.com/ncannasse/templo/tree/master/comparisons/bin/mtts
