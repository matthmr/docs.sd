<!DOCTYPE html>
<html>
<head>
<title>Documentation - SD</title>
<link rel="stylesheet"
      href="/docs.sd/styles/source-code.css" >
<link rel="alternate icon"
      type="image/png"
      href="/docs.sd/assets/favicon.ico">
<script type="text/javascript"
      src="/docs.sd/scripts/link-headers.js"
      defer>
</script>
</head>

<!-- begin markdown -->

# SD (Programming Language)

### Resources
- [Language source code](https://github.com/matthmr/sd)
- [Website source code](https://github.com/matthmr/docs.sd)
- [Index](/docs.sd/index.html#index)

This documents the inner workings of the [SD language](https://github.com/matthmr/sd): the
language paradigms and syntax. Not going into too much detail
about implementation.

For in-depth documentation about the language implementation,
go to the [plain text documentation](https://github.com/matthmr/sd/tree/master/docs/txt/README) on the SD repository. Do notice,
however, that documents there are **not** hyperlinked and go into
detail about the language stack rather than the language syntax.

## Index

1. [Main Paradigm](#main-paradigm)
2. [Running SD](#running-sd)
3. [Syntax](#syntax)
	1. [Variable assignment](#assignment)
	2. [Expression flow](#flow-control)
	3. [Expression terminator](#expression-terminator)
	4. [Functions](#functions)
	5. [Arrays](#arrays)
	6. [Expression grouping](#groups)
	7. [Expression casting](#casts)
	8. [Branching](#branches)
	9. [Modules](#modules)
	10. [Stack statement](#statement-return)
	11. [Qualifiers](#qualifiers)
	12. [Literal Syntax](#ast-object)
4. [Keywords](#)
5. [Examples](#)
6. [Modules](#)
7. [Compiling](#)
8. [Embedding](#)

## Main paradigm

In the SD programming language, the main paradigm is that objects are
treat as being **resolved** or **structured**. To SD, an object is just
an entry of its object table (which itself is a segment of the
process' heap) that contains some raw data and some type metadata.
If the data is considered "resolved", that means no further processing
may be needed on that piece of data other than referencing and
dereferencing. An example of that would be an `int`, `char[]`, etc.

However, if the data is considered "structured" or "unresolved", its
content could be that of an **executable**, **class**, **type**, or any other set
of operations (including general [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) branches) that don't have a return
value yet. That in turn makes the object table a sort of *virtual memory*
for the SD language, with the "resolved" section being the equivalent
of the `.data` section and the "structured" section being the equivalent
of the `.text` section but much more general because the parsing of the
source code is done at runtime because the language is interpreted.

## Running SD

SD is an **interpreted** language which means it needs an interpreter to
execute its source code, in that sense SD could be used as more of a
scripting language like python rather than a general purpose like C or
rust. The default interpreter is `sd` (a symbolic link to `sdread`) which
is a compilation result from `make parser` (see the [compilation guide](https://github.com/matthmr/sd#building)).

A dump of SD's object table can be written to a file and read by `sd`
passing the `-s` flag. As per convention, SD source code files have `.sd`
as extension and object table dumps called *object files* have `.sdo`
as extension. SD object files are compiled by `sdc`, another result
of `make parser`.

## Syntax

SD has a unique syntax for a scripting language because:

1. Its variables are strongly typed.
2. There is a distinction between variable declaring / initializing and
   (re)assignment.

### Assignment

To define a variable in SD you follow:

```
let? <type> <name> : <value> ;
```

As in:

```
int year : 2022;
<char> name : "Two Thousand Twenty Two";
```

The `let` keyword is optional when defining variables as their type can often
be infered by a literal. So `int year : 2022;` is the same as `let year : 2022;`.
The same is not true for **structures**, **unions** or **classes**. Say there is a
structure "`Year`" that has `int number, <char> name` fields, to define such
variable one could write:

```
Year year : [ 2022, "Two Thousand Twenty Two" ];
# or
Year year : {
	$number : 2022;
	$name   : "Two Thousand Twenty Two";
};
```

Field dereference has syntax similar to a directory path, for instance:

```
year/@number; # 2022
year/@name;   # "Two Thousand Twenty Two";
```

As oposed to traditional '`.`' notation (`year.number`, `year.name`).

Also, as you might have noticed, the '`@`' operator is used to dereference
variables in SD. By default, if a variable is referenced **without** the '`@`'
operator, it is passed **by path**. That is, it is the equivalent of a
*pass-by-reference* instead of a *pass-by-value* operation.

For instance, in this code:

```
let year : 2022;
let current_year : year;
let current_year_number : @year;
```

`current_year` is an **alias** to `year`, so any changes to `current_year` also change
`year`: they point to the same entry in the object table. In contrast `current_year_number`
holds the **value** of `year`: it has a complete separate entry in the object table.

The use of '`@`' is not needed in expressions *other than* pass-by-value assignment.
For example, the boolean:

```
let year_is_current_year: year = current_year;
```

Has the same value of:
```
let year_is_current_year: @year = @current_year;
```

### Flow control

SD has two tokens designed for flow control:

- `?` : the equivalent of the `if` keyword
- `!` : the equivalent of the `while` keyword

To make an *if* or *while* statement block, it follows this syntax:
```
# if
<expr> ? {<body>};

# while
<expr> ! {<body>};
```

SD implements **expressions hooks** so that *if* and/or *while* statements can be tied together if one
expression fails. This is the equivalent of an *else* statement.

For example, the following:

```
import "std/io" <puts>

let year: 2022;
let unix_epoch: 1970;
let unix_epoch_32b_lim: 2038;

year = unix_epoch ? {
	(puts "Welcome to the begining of time!");
}

year = unix_epoch_32b_lim ? {
	(puts "Welcome to the end of time!");
}

? {
	(puts "Time is ticking out...");
};
```

Has the equivalent python code:
```
year = 2022
unix_epoch = 1970
unix_epoch_32b_lim = 2038

if year == unix_epoch:
	print ("Welcome to the begining of time!")
elif year == unix_epoch_32b_lim:
	print ("Welcome to the end of time!")
else:
	print ("Time is ticking out...")
```

Expression hooks work by making an expression body (the code enclosed by curly braces)
not have an **expression terminator** (the semicolon). In SD, almost all expressions **must** have an
expression terminator. If the don't have one **and** the expression is **not** an *if* or *while* statement,
the compiler (or interpreter) will throw a syntax error.

For example, in this code:
```
<expr1>? {<body>}
<expr2>? {<body>};
<expr3>? {<body>};
```

`expr2`'s code will **not** execute if `expr1` is true and `expr3`'s code does not depend on `expr1`'s code
to be true to execute.

As for *while* statements, the same syntax applies. For instance:

(code from [Wikipedia](https://en.wikipedia.org/wiki/Euclidean_algorithm#Implementations))
```
int a: 128;
int b: 48;

b != 0 !{
	a > b ?
		a: a - b;
	?
		b: b - a;;
};

sync: @a;
```

Has the equivalent pseudocode:
```
a = 128
b = 47

while b != 0:
    if a > b:
        a := a - b
    else:
        b := b - a
return a
```

Also, for always-true *if* or *while* statements, the respective token can be used without an expression **or**
the token can be doubled, for instance:

```
??
	(puts "I always execute!");;
```

and

```
?
	(puts "I always execute!");;
```

Have the same output.

### Expression terminator

As you might have noticed from the previous section, expression must be terminated with an
expression terminator. However much like C that's not true if the body of an expression is one
expression long. In this case the braces that enclose the expression body could be ommited.
For instance:

```
??
	(puts "I always execute!");;
```

and

```
?? {
	(puts "I always execute!");
};
```

Have the same output.

In the case they are ommited, the expression terminator that would go to the expression body
enclosure instead compounds with the terminator of the expression **inside** that enclosure.

That's why one-line *if* statements that close an expression hook have two semicolons:
the first closes the one-line expression and the second closes the hook chain.

*while* statements can also have a hook expression the same way *if* statements can. For instance:

```
import "std/C/io" <printf>;

int a: 10;
int b: 20;

a != 0 ! {
	(printf "Iterating from a: %d", a);
	a--;
}
b != 0 ! {
	(printf "Iterating from b: %d", b);
	b--;
};

```

Has the equivalent python code:

```
a = 10
b = 20
while a != 0:
	print ("Iterating from a: ", a)
	a -= 1
while b != 0:
	print ("Iterating from b: ", b)
	b -= 1

```

### Functions

To define a function in SD you follow:

```
proc? <rettype> <name> : [<args>] { <body> } ;
```

As in:

```
int sum : [int a, int b] {
	sync: a + b;
};
```

To call a function in SD you follow:

```
(<name> <args>);
```

As in:

```
int sum_2_plus_3: (sum 2, 3);
```

If a function is a child of an object, the dereference happens **before** the '`()`' token. As in:
```
let MathOperations: {
	int sum : [int a, int b] {
		sync: a + b;
	};
};
MathOperations/(sum 2, 3);
```

The `proc` keyword is optional when defining functions if their return type is
explicitly defined. However, unlike variables, SD does **not** infer the return
type of a function, therefore only use bare `proc <name>` if the function doesn't
return anything.

Functions (also called *procedures* in SD) return a value by using the `sync` keyword.
As functions are structured by default, they double as classes using the `new` keyword.
For example:

```
import "std/C/io" <printf>;

proc person : [<char> name, int age] {
	proc speak : {
		(printf "Hello, I am %s. I have %d years-old", ../name, ../age);
	};
};
new person bob : ["Bob", 21];

bob/(speak);
```

The same rule about expression terminators also work in procedures: they don't have to have braces
if their statement body is one line long.

Function arguments can also be other functions, in which case the syntax for that argument
inherits the syntax of the function being passed. For instance, in this
example:

```
import "std/io" <puts>

proc wrap : [proc fn[]] {
	(puts "Hello from wrap");
	(fn);
}

proc wrap_different_syntax : [void fn[]] {
	(puts "Hello from wrap_different_syntax");
	(fn);
}

proc fn:
	(puts "Hello from fn");

(wrap fn);
(wrap_different_syntax fn);
```

`wrap` and `wrap_different_syntax` have the same output.

Function arguments *may* be written without commas (if the context is obvious).
For instance, if a variable is **not** a type and **not** a hook, the use of
commas is completly optional. For example:

```
int sum : [int a, int b]
	sync: a + b;

(sum 1, 2);
```

and

```
int sum : [int a, int b]
	sync: a + b;

(sum 1 2);
```

Have the same output.

Functions can also have **key arguments**. Key arguments are passed the
same way they're passed in arrays or objects: using '`$`' notation.

For example:
```
int div : [int a, int b]
	sync: a // b;
```

can be called as

```
(div $a: 10, $b : 20);
```

and

```
(div $b : 10, $a: 20);
```

and they'd have **different** results.

This type of variable passing is called *pass-by-faux* in SD.

Functions can be passed as *lambda* using the '`[]`' notation. Lambda notation
follows:

```
<rettype>? [<args>] { <body> } ;
```

The only difference from normal function notation being the lack of a name.
For instance, in this example:

```
proc wrap : [int fn[int,int]] {
	int a : 10;
	int b : 20;
	(puts "Hello from wrap");
	(fn @a, @b);
};
(wrap
	int [int a, int b] {
		(puts "Hello from lambda");
		(printf "The sum is %d", a + b);
	}
);
```

The call to `wrap` outputs:

```
Hello from wrap
Hello from lambda
The sum is 30
```

### Arrays

To define an array in SD you follow:

```
<<type>> <name> : {<array body>} ;
```

As in:

```
<int> unix_epoch_32b_bounds : { 1970, 2038 };
```

The definition using plain angle braces only works if the array is being
initialised as an **array literal**. If it is so, SD can easily infer the
size by just couting how many objects there are. However to initialise a
**fixed size array** you'd follow:

```
<<type>.<elem count>> <name> ;
```

As in:

```
<int.2> unix_epoch_32b_bounds;
```

This array gets indexed in the object table and gets allocated uninitialized
heap or stack space.

To declare a nested array, you can either add another '`.`' after the first
one *or* after a nested guard. For instance:

```
<int.2.2> _2x2_matrix;
```

and

```
<<int.2>.2> _2x2_matrix;
```

Have the same output.

You can also nest them using their guards if the array is being initialised by
an array literal, as in:

```
<<int>> _2x2_matrix : {
	{ 1, 2 },
	{ 3, 4 },
};
```

However, if nested using an array literal, the length of the biggest array
element **per index** becomes that index's size. For example:

```
<<char>> names: {
	"Alice Smith",
	"Bob Martin",
};
```

Would be equivalent to `<char.12.2>`, and the smaller element, `"Bob Martin"`,
would have its remaing bytes filled to zero.

That's in contrast to using a *referenced array*, in which case the elements
*decay to a pointer*, like in C. For instance:

```
<char> name1 : "Alice Smith";
<char> name2 : "Bob Martin";

<<char>.2> names : {
	name1,
	name2,
};
```

Has the equivalent C code:

```
char name1[] = "Alice Smith";
char name2[] = "Bob Martin";

char* names[2] = {
	name1,
	name2,
};
```

Akin to C, SD does not care if there is an "extra" comma in an initialiser
element: `<int> array : { 1 }` and `<int> array : { 1, }` result in the same
object.

To partially or sporadically initialise an array, you'd use '`$`' notation with
the array element number as the identifier. For example:

```
<int.2.2> _2x2_matrix;

_2x2_matrix = {
	$0.1 : 2,
	$1.0 : 3,
	$1.1 : 4,
	$0.0 : 1,
}
```

and

```
<int.2> _2_vec;

_2_vec: {
	$1 : 2,
	$0 : 1,
};
```

are all valid SD code.

To index an array, you'd use **dot-notation** plus **dash-notation**, as in:

```
<int> years : {
	2022,
	1984,
};

int _1984 : years/@1;
```

The '`@`' sign here means the same thing it means to regular variables. If we
don't include it, `_1984` would be treated as a pointer to `years/1`.
The elements are **0-indexed**.

### Groups

In SD, grouping means the expression enclosed by *group matchers* has a bigger
precedence than its sibbling's object's expressions. In other languages this
is achieved by enclosing the expression with '`()`', for instance `1+2*3`
resolutes to `7` and `(1+2)*3` resolutes to `9`. In SD this is done using the
`[]` matching tokens. That means that `[1+2]*3` would result in `9` in this case.


### Casts

To cast a variable into another type in SD you follow:

```
<name>.<type> ;
```

For example:

```
int highest_bit_on = 0b80000000;
(print "%d\n%d", highest_bit_on.[signed int], highest_bit_on.[unsigned int]);
```

outputs

```
-0
2147483648
```

Qualified types may be enclosed by '`[]`'.

Also, for casting qualification of the same type, the type itself can be ommited. For instance, the
previous example could've been written like:

```
int highest_bit_on = 0b80000000;
(print "%d\n%d", highest_bit_on.signed, highest_bit_on.unsigned);
```

As both their types still are `int`.

Casts can have a size and a format size be explicitly defined **in bytes**. As in:

```
char c : 20;
c.4; # equivalent to c.int
```

or
```
int all_bits_on_in_4bytes: 0xffffffff;
all_bits_on_in_4bytes.<char.4> # equivalent to { 0xff, 0xff, 0xff, 0xff }
```

The compiler (or interpreter) will do some rounding to fit the machine bit address.

Casts with bigger size get their value pushed close to the least significant bit. For example:

```
char c;
c : 20;  # 0x14        # 1 byte
c.int    # 0x00000014  # 4 bytes
```

Casts with smaller size truncate the output close to the least significant bit. For example:

```
int c;
c : 20;  # 0x00000014  # 4 bytes
c.char;  # 0x14        # 1 byte
```


Casts can be applied to literals.

### Branches

Compiled SD code (and to some extent interpreted SD code) can make use of
**branches**. They are defined as follows:

```
branch <name> : { <body> } ;
```

To jump to a branch use the `jump` keyword. As in:

```
proc count_down_to_0 : [int upper_bound] {
	upper_bound > 0 !:
		upper_bound--;
	!jump finish;;
	
	branch finish:
		(puts "Finished");
};
```

However, it is also possible to *stack-jump* to a branch in SD using the `goto`
keyword, then pop using the `ret` keyword. For instance, this example:

```
proc count_down_to_0 : [int upper_bound] {
	upper_bound > 0 !:
		upper_bound--;
	!{
		goto finish;
		(puts "Back from goto");
		end;
	};
	
	branch finish: {
		(puts "Finished");
		ret;
	};
};
```

outputs

```
Finished
Back from goto
```

If a branch doesn't have a `ret` statement, the code continues execution with
the expression rigth after the branch. If that branched was jumped into using
*goto*, it will pop the stack but not send the parser to the callee, it will
continue executing sequentially.

If *jump* is used without a name, it will jump to the begining of its parent
object **or** the closest hook it finds, for instance, in this example:

```
proc guess : {
	int mistery_number : 42;
	int guess;
	!{
		guess : (random_int_between 0, 100);
		guess != mistery_number? jump;
		?? end;;
	};
};
```

*jump* will jump to the while loop rather than the `guess` procedure.

The *branch* keyword can also hook against conditional hooks using the
following syntax:

```
branch <name> :: <expr> <hook token> { <body> } ;?
```

For example, in this code:

```
int a : 42;
int b : 20;
int iter_number: 10;
int _iter_number: @iter_number;

<char> message : ""

branch got_to_42 :: a = b ?{
	(puts "Got it!");
}

branch overshot :: a < b ?{
	(puts "Overshot!");
}

branch loop :: _iter_number > 0 !{
	_iter_number--;
	b++;
	jump;
}

? {
	_iter_number: @iter_number;
	jump loop;
};
```

we use two *if* hooks and one *while* hook within the same hook chain. The node
in the hook chain we go to is marked by the *branch*es.

SD also implements object resolution flow, which is similar to plain code flow
but focus more on objects themselves. In this example above, we use the `end`
keyword, which ends the resolution of an object **or** hook. If *end* is used
on data-like objects it will stop parsing and seek for the end of that object.
If *end* is used on text-like objects it will seek for the end of that object.

The *end* keyword can be used as an alternative to `break` and the *jump* as
an alternative to `continue` in other languages.

### Modules

To define a module in SD you follow:

```
import "<module file>" <<module object>> ;
```

As in:

```
import "std/io" <puts>;
```

The string after the module keyword represents a **file path** to the module.
If the module is a directory with name `dir`, said directory must have a
`dir.sd` file (aka a file with the same name) telling SD how its submodules
should export. If there is a '`/`' character in the import string, the fields
before are assumed to be directories and the last field is assumed to be a
file.

After finding the file, it is possible to only import a submodule or a
single object. To do so, we use the name of the module or object in angle
braces after the file path.

The import keyword returns a pointer to the module. The module name can be
changed by assigning it to another variable, as in:

```
let local_module : import "module";
```

or by using the `as` keyword, as in:

```
import "module" as local_module;
```

The difference between the two is that the first one still has the name
`module` being used by the local_module, as well as `local_module`, and the
second one does not have `module` as the name of the module but instead
`local_module`.

After a **wrapped** module has been imported, we can unwrap it with the
`unwrap` keyword. As in:

```
unwrap import "std/io";
```

<!-- TODO: add a wrap keyword -->
In this case, all functions, objects, branches, etc, of the `std/io` module
get their own entry in the program's object table and the name `io` does not.

As with every SD object, the module does not scope to their sibblings. To do
so, use the `scope` keyword, as in:

```
scope import "std/io" <puts>;

proc print_hello:
	(puts "Hello!");
```

Now `puts` can be used from any object down its node.

<!-- TODO: style this -->
Made by [mH](https://github.com/matthmr).

<!-- end markdown -->
</html>
