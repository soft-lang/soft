# The Soft Compiler Philosophy

Let's have a lot of fun, learn, invent, and simplify life on Earth!

## A NEW PARSER

### MOTIVATION

For decades, mankind has struggeled with the basic problem of writing
simple compilers for their own self-invented computer languages.

Modern compilers have hand-written parsers, usually found in a single huge file called `parser`.

No single human can ever completely understand these parsers because of
their complexity and size.

This is possibly one of the biggest current problems for mankind today.

If we can't understand our compilers, we can't understand our languages.

We can't just put our faith in test coverage.

We need to understand our compilers so we can develop them without pain.

Developing a language means modifying its compiler.

Mankind are currently wasting enormous energy in this space.

### HOW BAD IS IT?

Below is a list of some languages and their parser source code files.
Some languages have the parser splitted up in multiple files,
so it might actually be worse than this.

The list is sorted by lines of code.

Language | Corporation | LoC | Size | Parser
-------- | ----------- | --- | ---- | ------
WebAssembly |  | 753 lines | 23.8 KB | https://github.com/WebAssembly/spec/blob/master/interpreter/text/parser.mly
Go | Google | 2522 lines | 62.3 KB | https://github.com/golang/go/blob/master/src/go/parser/parser.go
PL/pgSQL |  | 4012 lines | 103 KB | https://github.com/postgres/postgres/blob/master/src/pl/plpgsql/src/pl_gram.y
Python |  | 5297 lines | 161 KB | https://github.com/python/cpython/blob/master/Python/ast.c
Rust | Mozilla | 6363 lines | 249 KB | https://github.com/rust-lang/rust/blob/master/src/libsyntax/parse/parser.rs
C++ (Clang) | Apple | 6822 lines  | 247 KB | https://github.com/llvm-mirror/clang/blob/master/lib/Parse/ParseDecl.cpp
D |  | 8594 lines | 268 KB | https://github.com/dlang/dmd/blob/master/src/ddmd/parse.d
C# | Microsoft | 11425 lines | 473 KB | https://github.com/dotnet/roslyn/blob/master/src/Compilers/CSharp/Portable/Parser/LanguageParser.cs
Swift (Part 1) | Apple | 5951 lines | 207 KB | https://github.com/apple/swift/blob/master/lib/ParseSIL/ParseSIL.cpp
Swift (Part 2) | Apple | 6140 lines | 210 KB | https://github.com/apple/swift/blob/master/lib/Parse/ParseDecl.cpp
Swift (Total) | Apple | 12091 lines | 417 KB
SQL |  | 15926 lines | 421 KB | https://github.com/postgres/postgres/blob/master/src/backend/parser/gram.y
C++ (GCC) | N/A | 39489 lines | 1.2M | https://github.com/gcc-mirror/gcc/blob/master/gcc/cp/parser.c

### HOW DID WE END UP HERE?

I think the simpliest explanation is lack of thinking and lack of time.

I would guess most compiler designers are primarily occupied working on some specific *language*.

It's probably a hard sell trying to convince others what we need is a new *compiler* and not a new *language*,
since it's much more exciting to talk about new language features,
than to talk how we can do exactly the same things as before,
but in a simpler way.

Another reason is perhaps the lack of collaboration between languages.

Behind many modern languages stand a big corporations,
and perhaps they are primarily interested in seeing improvements in their
own language and their own compiler.

Most compilers have come into existence because someone somewhere decided we
needed a new language, and writing a compiler for it was merely a side effect,
although of course compilers have gotten better over the years,
but we're still stuck with our hand-written parsers.

### CAN WE DO BETTER?

I think so.

Most popular parsing algorithms are designed for Context Free Grammars (CFGs).

Most modern programming languages, however, are Context Sensitive (CS).

Trying to define a CFG for a CS language is very complicated,
and will require lots of hacks, work arounds, tricks, and
all sorts of ugliness, so that the end result won't be simpler
than writing a hand-written parser.

We will be more fruitful if we define a Context Sensitive Grammar (CSG)
for our language.

Unfortunately, if you try to google for "Context Sensitive Grammar"
you will find a Wikipedia article explaining the theory,
but very few links to any parser algorithms or implementations of such.

It looks like there is an opportunity to be creative and invent our
own way to define Context Sensitive Grammars and construct a new
Parser Algorithm that can parse them!

To be successful:

* The formal grammar must not exceed the hand-written parsers (see above) in terms of complication and lines of code. (Should be easy)
* The parser must parse the language the same way the humans who write code in it do. (Should be possible)
* Ability to define different grammatical errors directly in the grammar, to provide informative messages to the user. (Difficult but doable)
* Sufficient time and space performance. (Should be possible, if the parser is implemented in a language with a faster compiler than PL/pgSQL, or if the PL/pgSQL compiler is reimplemented to run faster.)
