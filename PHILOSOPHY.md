# The Soft Compiler Philosophy

Having a lot of fun and trying to simplify life on Earth.

This project started because I wanted to learn about compilers.

They have always fascinated me because I've never fully understood how they work. Since then I've learned that apparently no one understands them fully, because of their complexity.

I suspected there was something wrong down the stack, because I couldn't
possibly imagine compilers would need to be this complex.

There are many nice tutorials on how to write small compilers for small
languages, but for some reason the complication completely explodes
for more complex languages.

What I have found out are small but important simplifications to different
fundamental parts of a compiler. Most notably, I've designed a new parser,
that can cope with context sensitive languages, without having to write
a hand-written parser, allowing the language designers to focus on the
grammar of the language, and the compiler designers to focus on the
code for the compiler and the semantic functionality provided by it.

## A NEW PARSER

### MOTIVATION

For decades, mankind has struggeled with the basic problem of writing
simple compilers for their own self-invented computer languages.

Modern compilers have hand-written parsers usually found in a single huge file called `parser`.

No single human can ever completely understand these parsers because of
their complexity and size.

This is possibly one of the biggest current problems for mankind today.

If we can't understand our compilers, we can't understand our languages.

We can't just put our faith in test coverage.

We need to understand our compilers so we can develop them without pain.

Developing a language means modifying its compiler.

Mankind are currently wasting enormous energy in this space.

### HOW BAD IS IT?

Compiler | Parser | LoC | Size
-------- | ------ | -------------
WebAssembly | https://github.com/WebAssembly/spec/blob/master/interpreter/text/parser.mly | 753 lines | 23.8 KB
Go | https://github.com/golang/go/blob/master/src/go/parser/parser.go | 2522 lines | 62.3 KB
PL/pgSQL | https://github.com/postgres/postgres/blob/master/src/pl/plpgsql/src/pl_gram.y | 4012 lines | 103 KB
Python | https://github.com/python/cpython/blob/master/Python/ast.c | 5297 lines | 161 KB
Rust | https://github.com/rust-lang/rust/blob/master/src/libsyntax/parse/parser.rs | 6363 lines | 249 KB
C++ | https://github.com/llvm-mirror/clang/blob/master/lib/Parse/ParseDecl.cpp | 6822 lines  | 247 KB
D | https://github.com/dlang/dmd/blob/master/src/ddmd/parse.d | 8594 lines | 268 KB
C# | https://github.com/dotnet/roslyn/blob/master/src/Compilers/CSharp/Portable/Parser/LanguageParser.cs | 11425 lines | 473 KB
 | https://github.com/apple/swift/blob/master/lib/ParseSIL/ParseSIL.cpp | 5951 lines | 207 KB
 | https://github.com/apple/swift/blob/master/lib/Parse/ParseDecl.cpp | 6140 lines | 210 KB
Swift | | 12091 lines | 417 KB
SQL | https://github.com/postgres/postgres/blob/master/src/backend/parser/gram.y | 15926 lines | 421 KB
C++ | https://github.com/gcc-mirror/gcc/blob/master/gcc/cp/parser.c | 39489 lines | 1.2M

### HOW DID WE END UP HERE?

I think the simpliest explanation is lack of thinking and lack of time.

I would guess most compiler designers are also working on some language.

If it's more important to develop the language, then not much time remains
to think about how to design a better compiler, because they are separate
business.

Most compilers come into existence because someone somewhere decided they
needed a new language, and writing a compiler for it was merely a
necessary evil.

### CAN WE DO BETTER?

I think so. The problem is probably that most parsing algorithms are
designed for Context Free Grammars.

Modern programming languages are context sensitive, but there aren't
any algorithms designed for this purpose, or if there are, they are
either not used by the major compilers, or not known to me.

If trying to define a context free grammar for a context sensitive language, you end up with lots of ugly hacks to work arounds problems,
which causes the grammar to explode in complication, and you probably end up
thinking it's better to write a hand-written parser instead.

We will design a way to define a context sensitive grammar with precedence support, to define everything our language consists of, statements, expressions, etc, in one and the same grammar.

To be successful:

* The formal grammar must not exceed the hand-written parsers (see above) in terms of complication and lines of code. (Should be easy)
* The parser must parse the language the same way the humans who write code in it do. (Should be possible)
* Ability to define different grammatical errors directly in the grammar, to provide informative messages to the user. (Difficult but doable)
* Sufficient time and space performance. (Should be possible, if the parser is implemented in a language with a faster compiler than PL/pgSQL, or if the PL/pgSQL compiler is reimplemented to run faster.)



