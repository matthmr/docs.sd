<!DOCTYPE html>
<html>
<head>
<title>Documentation - SD</title>
<link rel="alternate icon"
      type="image/png"
      href="/docs.sd/assets/favicon.ico">
</head>

# SD (Programming Language)

### Resources
- [Language source code](https://github.com/matthmr/sd)
- [Website source code](https://github.com/matthmr/docs.sd)
- [Index](/docs.sd/index.html)

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
	1. [Scope](#scope)

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

To define a variable in SD you follow:

```
let? <type> <name> : <value> ;
```

As in:

```
int year : 2022;
string name : "Two Thousand Twenty Two";
```

The `let` keyword is optional when defining variables as their type can often
be infered by a literal. So `int year : 2022;` is the same as `let year : 2022;`.
The same is not true for **structures**, **unions** or **classes**. Say there is a
structure "`Year`" that has `int number, string name` fields, to define such
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

</html>
