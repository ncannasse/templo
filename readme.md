# Haxe Templo Template Engine

The templo Template class provides advanced templating support.

_Works in Haxe sys, neko and php_

### Installation

Install the library via [haxelib](http://lib.haxe.org/p/templo)
``` 
haxelib install templo 
```

## Usage example 

Templo directives start with two double-dots: `::directive`.

The best way is to learn using the examples, which can be found here: 
https://github.com/ncannasse/templo/tree/master/comparisons/bin/mtts


```haxe
// set some parameters
templo.Loader.BASE_DIR = "/home/user/project/tpl/";
templo.Loader.TMP_DIR = "/home/user/project/tmp/";
templo.Loader.MACROS = null; // no macro file

// the template context which will be available 
var context = { 
  userName  : "Nestor",
  lovesHaxe : true,
  data      : [1,2,3,4,5]
};

// loads template 
var t = new templo.Loader("mypage.mtt");
var r = t.execute(context);
neko.Lib.print(r);
```

> Templo is a template engine designed to generate XHTML in neko.

# Templates syntax

Templates contain expressions delimited by `:: ::` just like the `haxe.Template` syntax.

Here comes the first template example :
```html
<html>
    <head>
        <title>Foo</title>
    </head>
    <body>
        <h1>This is my home page</h1>

        ::if user.isLogged::
            <div>Welcome ::user.login::</div>
        ::elseif specialOffer::
            <div>I have something special for you today</div>
        ::else::
            <div>I don't know you but you look cool</div>
        ::end::

        <h2>List of connected users</h2>
        <ul>
        ::foreach connectedUser listOfConnectedUsers::
            <li><a href="/user/::connectedUser.id::">::connectedUser.login::</a></li>
        ::end::
        </ul>
    </body>
</html>
```
### print
The default behaviour of `::exp::` is to print the content of `exp` inside the template.

For instance `::login::` may produce "Jackson".

Because templo tries to be smart, it will automatically escape your output to produce clean XHTML.

| In haxe   | In the template  | Will produce | 
|---|---|---|
| `context.message = " is a < b or b > c, maybe is should include <p> in this ?";` | `::message::` | `is a &lt; b or b &gt; c, maybe is should include &lt;p&gt; in this ?` |

Each expression is a Neko one, the syntax is close to the Haxe syntax but there is no private/protected protection nor magic getter/setter because neko is not Haxe.

You may call methods, access fields, arrays, etc... starting for the context provided by the haxe application.
```html
His last message was : ::someUser.lastMessage()::
```

### raw
If you want to print some pre-produced XHTML inside your template, you can prefix the expression with raw :

| In haxe   | In the template  | Will produce | 
|---|---|---|
| `context.myMessage = "<p>Hello haxe</p>";` | `before : ::myMessage:: after : ::raw myMessage::` | `before : &lt;p&gt;Hello haxe&lt;/p&gt;after : <p>Hello haxe</p>` |

### if
This is the usual condition you find everywhere in the world (or nearly) :

```html
::if <somecondition>::
write xhtml
::end::
elseif
::if <somecondition>::
write xhtml
::elseif <someothercondition>::
write xhtml
::end::
else
::if <somecondition>::
write xhtml
::elseif <someothercondition>::
write xhtml
::else::
write default xhtml
::end::
```

### cond
This is a small improvement of `::if::`. Sometimes it is cleaner and nice to put the `::if::` inside the element. Templo will understand this as write this element only if the `::cond::` evals to `true`.
```html
<ul id="userMenu" ::cond user.isLogged::>
    <li><a href="/logout">Log out</a></li>
    <li><a href="/account">My account</li>
</ul>
```

### switch
If you have the following enum

```haxe
enum QuestItem {
     ITEM(id:Int);
     MONEY(amount:Int);
     XP(amount:Int);
}
```

You can use a switch statement this way :

```html
::switch myEnum::
   DEFAULT VALUE
::case::
   Item ::args[0]::
::case::
   ::args[0]:: gold
::case::
   ::args[0]:: XP
::end::
```

Please note that cases are in the same order that your enum declaration.

### foreach
Repeat over some iterable.

```html
::foreach value iterable::
    You can use ::value:: there
::end::
```

For example if the context provides `listOfNumbers = [0,2,5,6]`, you can use :

```html
::foreach n listOfNumbers::
    Number = ::n::
::end::
```

### repeat
This is the same as a ::foreach:: but inside the element, just like `::cond::`, templo will understand a `::repeat::` like print this element and its content for each element in the iterable.
```html
<ul>
    <li ::repeat user listOfConnectedUsers::>
        <a href="/user/::user.id::">::user.name::</a>
    </li>
</ul>
```

### repeat and foreach context

Because template design often requires loop data, templo creates for each repeat or foreach an information context accessible using `repeat.<itemName>.*` :

* `repeat.<item>.index` : an integer starting from 0 to length - 1
* `repeat.<item>.number` : an integer starting from 1 to length
* `repeat.<item>.odd` : true if index is odd
* `repeat.<item>.even` : true if index is even
* `repeat.<item>.first` : true if current element is the first element
* `repeat.<item>.last` : true if current element is the last element (when size is available)
* `repeat.<item>.size` : the data length (when available)

```html
<table>
    <tbody>
        ::foreach user listOfConnectedUsers::
        <tr class="odd::repeat.user.odd::">
            <td>::repeat.user.number::</td>
            <td>::user.name::</td>
        </tr>
        ::end::
    </tbody>
</table>
```

May produce something like :

```
<table>
    <tbody>
        <tr class="oddfalse">
            <td>1</td>
            <td>Joe White</th>
        </tr>
        <tr class="oddtrue">
            <td>2</td>
            <td>Janet Red</td>
        </tr>
        <tr class="oddfalse">
            <td>3</td>    
            <td>Diana Tres</td>
        </tr>
    </tbody>
</table>
```

### set
This operation allows you to create a variable inside your template :
```html
::set myVar = myValue::
```

Useful to simplify conditions, create loop sums, etc...
```html
::set isLogged = (user != null) && (user.id != null)::

::set sum = 0::
::foreach i listOfNumbers::
    number = ::i::
    ::eval sum = sum + i::
::end::
Sum = ::sum::
```

### fill

The `::fill::` acts quite like a `::set::` but allows you to capture some xhtml and put it into a variable:

```html
::fill navigation::
<div>
    <a href="/previous">Previous</a> |
    ::foreach page resultPages::
    <a href="/page/::page::">::page::</a> |
    ::end::
    <a href="/next">Next</a>
</div>
::end::
<!-- we use the filled variable -->
::raw navigation::

<table>
    <thead>
        <tr>
            <th>#</th>
            <th>name</th>
        </tr>
    </thead>
    <tbody>
        ::foreach name listOfNames::
        <tr>
            <th>::startIndex + repeat.name.index::</th>
            <th>::name::</th>
        </tr>
    </tbody>
</table>

<!-- we reuse the filled variable to avoid executing the loop twice -->

::raw navigation::
::fill:: also provides some interesting features in coordination with ::use::, as explained below.
```

### use
The organization of your templates often requires splitting things in different files for reuse. The `::use::` clause allows you to call an external template from the current template. The called template will share its context with the current template.

**userMenu.mtt**

```html
<div id="userMenu">
    <div>Logged as ::user.login::</div>
    <ul>
        <li><a href="/logout">Log out</a></li>
        <li><a href="/account">My account</a></li>
    </ul>
</div>
```

**myPage.mtt**

```html
<html>
    <head>
        ...
    </head>
    <body>
        ...

        <!-- show the menu two times, ::end:: is requires there (explained later) -->
        ::use 'userMenu.mtt'::::end::
        ::use 'userMenu.mtt'::::end::
    
        ...
    </body>
</html>
```

**design.mtt**

```html
<html>
    <head>
        <title>My title</title>
    </head>
    <body>
        <h1>My title</h1>

        <!-- assume the template which will use design.mtt fills the content variable -->
        ::raw content::
    </body>
</html>
```

**mypage.mtt**

```html
::use 'design.mtt'::

    ::fill content::
        <h2>My page</h2>
        some data here
    ::end::

::end::
```

Because the `::use X:: ::fill content:: ::end:: ::end::` syntax is quite repetitive and the design.mtt approach to website templating is really useful, each `::use::` defines a `__content__` variable which is filled with the content of the `::use::` up to `::end::`.

This means that the following usages are equivalent :

```html
::use 'design.mtt'::
    ::fill __content__::
    <h2>The content to write in design.mtt</h2>
    ::end::
::end::

::use 'design.mtt'::
    <h2>The content to write in design.mtt</h2>
::end::
```

And the new design.mtt will look like :

```html
<html>
    <head>
        <title>My title</title>
    </head>
    <body>
        <h1>My title</h1>

        <!-- assume the template which will use design.mtt fills the content variable -->
        ::raw __content__::
    </body>
</html>
```

In the above examples, you can see that each used template files named is quoted `::use 'design.mtt'::`. This is because the use syntax is a regular neko expression. This means that the following code works :

```html
::use theme+'.mtt'::
...
::end::
```

Providing `__theme__` is a context variable set to the string 'design', templo will use the 'design.mtt' file, changing the variable to 'blueDesign' will tell templo to use 'blueDesign.mtt' instead.

### attr
This is a pseudo attribute which may be used as follows :

```html
<ul>
::foreach link links::
    <li><a ::attr title link.title; href link.href::>::link.title::</a></li>
::end::
</ul>
```

which may produce :

```html
<ul>
    <li><a href="http://www.google.com" title="google search">google search</a></li>
    <li><a href="http://www.haxe.org" title="Haxe">Haxe</a></li>
</ul>
```

Please note that it is the same as writing :

```html
<ul>
::foreach link links::
    <li><a href="::link.href::" title="::link.title::">::link.title::</a></li>
::end::
</ul>
```

The real interest of `::attr::` resides in forms select/option and input elements :

```html
<!-- add the checked="checked" attribute only if someCondition evals to true -->
<input type="checkbox" value="some value" ::attr checked someCondition::/>

<select>
    ::foreach opt availableOptions::
    <option value="::opt.value::" ::attr selected (opt.value == currentValue)::>::opt.name::</option>
    ::end::
</select>
```

### conditional attribute
Attribute can be set or using the following syntaxe :

```html
::attr attributeName if( someCondition ) "A" else "B"::
//or
::attr attributeName if( someCondition ) "A"::
```
actually if the value returned by `::attr::` expression is `null`, no attribute is added.

**Example:**

```html
<div ::attr class if( someCondition ) "A" else "B"::>...</div>
```
It will produce the following html, if `someCondition` is `true` :

```html
<div class="A">...</div>
```
if `someCondition` is `false`:

```html
<div class="B">...</div>
```
Also setting `null` value for the else case could be of great help with CSS, you can use

```html
<div ::attr class if(hiddenCondition) "hidden"::>...</div>
```

css content :

```css
.hidden {
    visibility : hidden;
}
```

Only element matching the `hiddenCondition` will be hidden.

### The usage of macros
Macros are stored in *one xml file*, usually macros.mtt in your template base dir.

A macro file looks like :

```html
<macros>

  <!-- shows a user -->
  <macro name="userView(user)">
    <div id="user">
      <div class="name">::user.name::</div>
      <div class="lastLog">::user.lastLogDate::</div>
    </div>
  </macro>

  <!-- presents a date without hours -->
  <macro name="date(d)">::d.toString().substr(0,10)::</macro>

</macros>
```

And these macros must be used inside your templates like follows :

```html
  ::foreach u userList::
  $$userView(::u::)
  ::end::
  <div>Last modification date : $$date(::lastModDate::)</div>
```
Macros are not processed as functions, they are written inside the template during pre-processing phase.

Thus after pre-processing, the above example will look like :

```html
  ::foreach u userList::
    <div id="user">
      <div class="name">::u.name::</div>
      <div class="lastLog">::u.lastLogDate::</div>
    </div>
  ::end::

  <div>Last modification date : ::lastModDate.toString().substr(0,10)::</div>
```
Macros are used by the preprocessor to write XHTML in your template, they do not understand `::::` expressions. That's why you can pass any string to a macro call and you must add `::var::` instead of just passing the var parameters.

Let's examine the following example :

```html
<macro name="showText(style, someText)">
  <div class="textBox ::style::">
    ::someText::
  </div>
</macro>

.... other file ....

<!-- 

calls the showText macro using the string 'icyBox' as style 
and some html string as someText.

Because we may use some coma and parenthesis inside this parameters, 
we put it inside {} to delimit real macro call parameters.

-->

$$showText(icyBox, {
<p>This is the first time you enter our website, welcome and enjoy the trip</p>
<p>You may come back any time</p>
})
```
This produces :

```html
<div class="textBox icyBox">
<p>This is the first time you enter our website, welcome and enjoy the trip</p>
<p>You may come back any time</p>  
</div>
```

While creating macros, you must ensure that their usage will produce well formed XML or the template won't compile.

For instance, a macro may produce onclick attributes :

```html
<macro name="confirm(confirmMessage)">onclick="return confirm('::confirmMessage::');"</macro>
```
Used like this :

```html
<a href="someurl" $$confirm(Really go to there ?)>somewhere</a>
```
Is legal and will work.

But the following usage is dangerous :

```html
<a href="someurl" $$confirm(What about '" characters ?)>somewhere</a>
```
Because it will produce the following html :

```html
<a href="someurl" onclick="return confirm('What about '" characters ?');">somewhere</a>
```

### Optimized mode
During website development, you will want templo to check files for modification and automatic recompilation of templates when required.

But most of the time, when your website is deployed on the production server, your templates won't change and making the server check modification time of each file isn't required.

Templo provides and Optimized mode (ie: Production mode) which assume that your templates are all existing and pre-compiled. It will ignore template sources and will jump straight to neko modules.

This feature have some benefits :

- faster (no modification time check)
- safer (you compile all your templates before deploying the project, if one template fails to compile you know it before upload)
- you do not have to distribute your template sources, only compiled modules

Usually, during production you do not set the `templo.Loader.OPTIMIZED` flag to `true`.

When your project is complete, you can put a flag in some config file which will set this flag on once on your production server.

Then before deploying you ensure that all your templates are compiled using a command looking like this :

```
// unix command example
temploc -m tpl/macros.mtt -r tpl/ -o bintpl/ `find tpl -name *.mtt`
```

After reading this document, you should understand the temploc parameters :

Usage: `temploc -o </destination/dir> -m <macrofile.mtt> -r </templates/repository> <files...>`

They are matching what you may call inside you haxe code :
```haxe
templo.Loader.TMP_DIR = </destionation/dir>
templo.Loader.MACROS = <macrofile.mtt>
templo.Loader.BASE_DIR = </templates/repository>
```
In your application, add
```
templo.Loader.OPTIMIZED = true;
```
### License
Templo
Copyright (c)2008 Motion-Twin

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
