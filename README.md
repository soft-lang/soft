# The Soft Compiler

Soft is not a hard-coded single-language compiler front end.

This document is not only a README but also the install and test script.

## INSTALL

These instructions assume you have a clean installation of Ubuntu Server 16.04.3 LTS.

All database users will be superusers and without any passwords etc.
Only use for local testing.


```sh
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.6

# Trust all connections allowing us to connect as any database user:
sudo perl -s -i -p -e 's/peer/trust/g' /etc/postgresql/9.6/main/pg_hba.conf
sudo service postgresql restart

sudo -u postgres createuser -s $USER
sudo -u postgres createdb -O $USER $USER

# Install and run pgcronjob in a separate terminal window
sudo -u postgres createuser -s pgcronjob
sudo -u postgres createuser -s sudo
git clone https://github.com/trustly/pgcronjob.git
cd pgcronjob
git checkout ShareConnectionsBetweenProcessesInSameConnectionPool
sudo apt-get install libdbi-perl libdbd-pg-perl libdatetime-perl
psql -X -f install.sql
PGUSER=pgcronjob PGDATABASE=$USER ./pgcronjob

# In a separate terminal window:
sudo -u postgres mkdir -p /var/lib/postgresql/9.6/main/github.com/munificent
sudo -u postgres git -C /var/lib/postgresql/9.6/main/github.com/munificent clone https://github.com/munificent/craftinginterpreters.git
echo 'SET search_path TO soft, public, pg_temp;' >> ~/.psqlrc
git clone https://github.com/soft-lang/soft.git
cd soft
# To run the lox tests:
./lox
# To run the monkey tests:
./monkey
# You can edit the debug level by editing
# languages/lox/test.sql and changing
#        _LogSeverity := 'DEBUG5'
# to e.g.
#        _LogSeverity := 'NOTICE'
# to make the tests run faster with less
# output in the terminal where PgCronJob runs.

```

## DATA MODEL

*Show me your flowcharts and conceal your tables, and I shall continue to be mystified. Show me your tables, and I won’t usually need your flowcharts; they’ll be obvious.*

![layout](https://raw.githubusercontent.com/soft-lang/soft/master/doc/data_model.png)


The SQL code is extracted from this file and executed by `./install.pl`.

```sql
ROLLBACK;

\pset pager off
\set ON_ERROR_STOP 1

BEGIN;

SET client_encoding TO 'UTF8';

SET search_path TO soft, public, pg_temp;

```

Support reinstall by first dropping everything:

All core functionality and helper-functions
shared between the compilation phases
reside in the "soft" schema:

```sql
DROP SCHEMA IF EXISTS soft CASCADE;
CREATE SCHEMA soft;
```

Delete any PgCronJob jobs and processes
created by us:
```sql
CREATE TEMP TABLE X AS
SELECT
    cron.Jobs.JobID,
    cron.Processes.ProcessID
FROM cron.Processes
INNER JOIN cron.Jobs ON cron.Jobs.JobID = cron.Processes.JobID
WHERE cron.Jobs.Function = 'soft.run(integer)';

DELETE FROM cron.ErrorLog  WHERE ProcessID IN (SELECT ProcessID FROM X);
DELETE FROM cron.Log       WHERE ProcessID IN (SELECT ProcessID FROM X);
DELETE FROM cron.Processes WHERE ProcessID IN (SELECT ProcessID FROM X);
DELETE FROM cron.Jobs      WHERE JobID     IN (SELECT JobID     FROM X);

DROP TABLE pg_temp.X;
```

Compilation phases have their own schemas
written in ALL CAPS, to make it visually
easy to spot them.

All semantic functionality is implemented
in these schemas:

```sql
DROP SCHEMA IF EXISTS "TOKENIZE" CASCADE;
CREATE SCHEMA "TOKENIZE";

DROP SCHEMA IF EXISTS "EXTRACT_TESTS" CASCADE;
CREATE SCHEMA "EXTRACT_TESTS";

DROP SCHEMA IF EXISTS "DISCARD" CASCADE;
CREATE SCHEMA "DISCARD";

DROP SCHEMA IF EXISTS "PARSE" CASCADE;
CREATE SCHEMA "PARSE";

DROP SCHEMA IF EXISTS "PARSE_ERRORS" CASCADE;
CREATE SCHEMA "PARSE_ERRORS";

DROP SCHEMA IF EXISTS "REDUCE" CASCADE;
CREATE SCHEMA "REDUCE";

DROP SCHEMA IF EXISTS "VALIDATE" CASCADE;
CREATE SCHEMA "VALIDATE";

DROP SCHEMA IF EXISTS "MAP_VARIABLES" CASCADE;
CREATE SCHEMA "MAP_VARIABLES";

DROP SCHEMA IF EXISTS "SHORT_CIRCUIT" CASCADE;
CREATE SCHEMA "SHORT_CIRCUIT";

DROP SCHEMA IF EXISTS "EVAL" CASCADE;
CREATE SCHEMA "EVAL";

DROP SCHEMA IF EXISTS "OPTIMIZE" CASCADE;
CREATE SCHEMA "OPTIMIZE";

DROP SCHEMA IF EXISTS "LLVM_IR" CASCADE;
CREATE SCHEMA "LLVM_IR";

DROP SCHEMA IF EXISTS "BUILT_IN_FUNCTIONS" CASCADE;
CREATE SCHEMA "BUILT_IN_FUNCTIONS";
```

## TYPES

```sql
\ir soft/TYPES/severity.sql
```

Used for logging. Borrows the levels from PostgreSQL.

```sql
\ir soft/TYPES/variablebinding.sql
```

Controls how values are captured.

```sql
\ir soft/TYPES/direction.sql
```

The direction we are traversing the AST, is either `ENTER` or `LEAVE`.

```sql
\ir soft/TYPES/nil.sql
```

Used by languages that need to represent the `nil` value.

```sql
\ir soft/TYPES/batchjobstate.sql
```

Used by `Run()` to tell if we should run it `AGAIN` or if we're `DONE`.

```sql
\ir soft/TYPES/node.sql
```

Used to pass `NodeID` to operator functions when the node doesn't
have a primitive value, i.e. when it's a complex value,
such as a function, array, or some other non-primitive value.
The operator function can then do whatever it want with the passed
`node` arguments, to decide what to return.

## CONTEXTS

```sql
\ir soft/TABLES/contexts.sql
```

## LANGUAGES

```sql
\ir soft/TABLES/languages.sql
\ir soft/FUNCTIONS/new_language.sql
```

A language has a unique Language name, a unique LanguageID,
and multiple semantic settings that all need to be defined.

```sql
SELECT New_Language(
    _Language                    := 'TestLanguage',
    _VariableBinding             := 'CAPTURE_BY_VALUE',
    _ImplicitReturnValues        := TRUE,
    _StatementReturnValues       := TRUE,
    _ZeroBasedNumbering          := TRUE,
    _TruthyNonBooleans           := TRUE,
    _NilIfArrayOutOfBounds       := TRUE,
    _NilIfMissingHashKey         := TRUE,
    _StripZeroes                 := FALSE,
    _NegativeZeroes              := FALSE,
    _ReturnFromTopLevel          := TRUE,
    _ParametersOwnScope          := FALSE,
    _ClassInitializerName        := NULL,
    _Translation                 := NULL,
    _MaxParameters               := NULL
);
SELECT * FROM Languages;
```

## BUILT-IN FUNCTIONS

```sql
\ir soft/TABLES/builtinfunctions.sql
\ir soft/FUNCTIONS/new_built_in_function.sql
```

Languages can have built-in functions such as
functions provided by external libraries
or implemented in the host language of the
interpreter.
Our test language doesn't have any built-ins,
but let's create and drop one just to show
how it's done:

First, create a function for our built-in in the `BUILT_IN_FUNCTIONS` schema.
It *MUST* take exactly one parameter: `_NodeID` integer.
It *MUST* return `void`.
Our example function will be named `NOOP` and it won't do anything.

```sql
CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."NOOP"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
RETURN;
END;
$$;
```

Then, assign an identifier to this function.
The name can be different, to allow reusing the same
functionality between different languages where
the built-in works the same but have different names:

```sql
SELECT New_Built_In_Function(
    _Language               := 'TestLanguage',
    _Identifier             := 'nop',
    _ImplementationFunction := 'NOOP'
);
```

## PHASES

```sql
\ir soft/TABLES/phases.sql
\ir soft/FUNCTIONS/new_phase.sql
```

Different languages have different phases,
so we need to tell the compiler what phases
there are for a language, and in what order
they should be executed.

The order in which we call `New_Phase()` determine
the order the phases they will be executed,
i.e. `ORDER BY PhaseID`:

```sql
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'VALIDATE');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'SHORT_CIRCUIT');
SELECT New_Phase(_Language := 'TestLanguage', _Phase := 'EVAL', _SaveDOTIR := TRUE);
```

The `SaveDOTIR` input param if `TRUE` will make `Walk_Tree()` automatically save
a DOTIR file with the current state of the program in the `DOTIR` format for each step
in the program execution.

The semantic functionality for these phases are installed at the end of
this document under the section `SEMANTIC FUNCTIONALITY`.

## NODE TYPES

```sql
\ir soft/TABLES/nodetypes.sql
\ir soft/FUNCTIONS/new_node_type.sql
\ir soft/FUNCTIONS/change_node_type.sql
```

Different languages might have different syntax for one and the same thing.
This is all fine, but to be able to reuse semantic functionality
we will agree on language agnostic NodeType names, and let any semantic
differences be controlled by the language settings.

NodeType names *MUST* *MATCH*: `^[A-Z_]+$`

Digits are not allowed not only to discourage bad names,
but also makes the parsing algorithm simpler. More on that later.

When implementing a new language, you might need to add new NodeTypes,
if some token or semantic feature is missing, but always first
see if there already is an existing NodeType to maximize reusage.
If the semantic behaviour doesn't match your case, you should
add a new language setting, and modify the existing code for
the NodeType.

For the sake of testing, we will define a simple grammar
for our test language that is only capable of calculating
simple arithmetic expressions using `+ - / * ( )`

Note that the NodeTypes for the various arithmetic tokens
don't have any explicit precedence, but their arithmetic *operators* do,
i.e. the `ADD` operator has it, but not the `PLUS` token.

## ERROR TYPES

```sql
\ir soft/TABLES/errortypes.sql
\ir soft/FUNCTIONS/new_error_type.sql
\ir soft/FUNCTIONS/interpolate.sql
\ir soft/FUNCTIONS/error.sql
\ir soft/FUNCTIONS/operator_symbol.sql
\ir soft/FUNCTIONS/translate.sql
```

To be able to run the official test suites for languages,
it is necessary to generate the exact same warning and error messages
as the test suites.

When an certain type of error occurs in a program, different languages
might handle it completely different. Some might ignore it completely,
intentionally or because the official implementation of the language
cannot detect the type of error. Since we want to mimic the official
implementation exactly, we need a way to specify what to do for each
type of error, and how to represent it.

Each type of error has been assigned a unique `ErrorType`.
When an error occurs, all the bits and pieces to create a customized
text message are included in a `hstore` named `ErrorInfo`.

If the message contains words identical to any of the keys in ErrorInfo,
you need to speicfy a single character `Sigil` and prefix the keys
with it in the message, so that only those placeholders will be replaced
with the keys in ErrorInfo.

Any error types not defined in `error_types.csv` for the language,
will result in an `ERROR` of the given error type, with the error info,
but without any error message, except the `ErrorType`.

## GRAMMAR

The grammar for a language is defined by `NodeTypes`.
The tokenizer uses `NodeTypes` where `Literal` or `LiteralPattern` is defined,
whereas the parser uses `NodeTypes` where `NodePattern` is defined.

### NodeTypes used by TOKENIZE

The tokenizer create new `Nodes` where `PrimitiveValue` is set to the matching text.
The tokenizer begins matching at the first character in the source code,
and tries to match the longest `Literal` first, and then if there is no match
it tries to find a matching `LiteralPattern` instead.


```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'SOURCE_CODE', _PrimitiveType := 'text'::regtype);
```

The node containing the source code of the program stored as text
in `Nodes.PrimitiveValue`.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'ALLOCA', _PrimitiveType := 'void'::regtype);
```

The node per function to which all the function's arguments and local variables are connected.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'RET', _PrimitiveType := 'void'::regtype);
```

The node per function which determines where to continue when we're done executing the function.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'PLUS',     _Literal := '+', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'MINUS',    _Literal := '-', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'ASTERISK', _Literal := '*', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'SLASH',    _Literal := '/', _NodeGroup := 'OPS');
```

Arithmetic tokens defines the `Literal` text that must match exactly in the source code.
We group them together by using the `NodeGroup` feature, which lets us refer to them as a
group later on.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'LPAREN', _Literal := '(');
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'RPAREN', _Literal := ')');
```

These tokens are not part of the NodeGroup `OPS` as we don't want them to match
normal expressions, as they are used by `SUB_EXPRESSION` to match on the left and right
side of the tokens possible inside a normal `EXPRESSION`.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'WHITE_SPACE', _LiteralPattern := '(\s+)');
```

White space is not ignored by default, as there might be languages where white space matters,
such as Python.

Here we make use of the `LiteralPattern` feature for the first time,
so let's explain it before moving on:

* It must contain exactly one capture group, i.e. one `()`.
* If you need multiple parenthesis, use `(?:)` to avoid capturing.
* The text captured is stored as the `Nodes.PrimitiveValue`.

If our test language would have support for double-quotes text string, which it doesn't,
the `LiteralPattern` would be: `"((?:[^"\\]|\\.)*)"`
This would make the double-quotes (") to *NOT* be included in the `PrimitiveValue`,
since the capture group captures whatever is in between the double-quotes.

```sql
SELECT New_Node_Type(
    _Language       := 'TestLanguage',
    _NodeType       := 'INTEGER',
    _PrimitiveType  := 'integer'::regtype,
    _NodeGroup      := 'VALUES',
    _LiteralPattern := '([0-9]+)'
);
```

In our test language we only have support for integers,
but if we would have support for e.g. boolean, text, numeric, etc,
they would also get `NodeGroup := 'VALUES'`, to allow referring to them
as a group in the grammar.

```sql
SELECT New_Node_Type(
    _Language       := 'TestLanguage',
    _NodeType       := 'ILLEGAL',
    _LiteralPattern := '(.)',
    _NodeSeverity   := 'ERROR'::severity
);
```

If we are still tokenizing remaining source code
and no `Literal` or `LitteralPattern` matches
then we have found an illegal character
which in our language is an `ERROR`,
but in other languages illegal characters
might only cause a `WARNING` or some other severity.

## NodeTypes used by PARSE

NodePatterns define what-is-what on an abstract level,
and might be self referring.
These nodes don't have a literal
presence in the source code, and only exist on an
abstract level in the Abstract Syntax Tree (AST).
The parser generates new `Nodes` and inserts `Edges`
to the existing `Nodes` which matched the `NodePattern`
defined for the language.

The parser code is in `PARSE/ENTER_SOURCE_CODE.sql`

How the parser works is out of scope for this install-and-test
document, but we need to at least say something about it
to explain the `NodePattern` concept.

The first thing the parser does is to generate a text
string representing the entire program as a sequence
of the tokens generated by the tokenizer,
on the format: `<[NodeType][NodeID]>`.

For instance, if our program would be `12 + 23 + 34`,
we would get `<INTEGER1><PLUS2><INTEGER3><PLUS4><INTEGER5>`.

Thanks to NodeID being unique, and thanks to <> wrapping
around each node, we are guaranteed that whatever
the NodePattern regex matches, it will match at exactly
one place, which allows us to simply replace
the nodes it matched directly in the text string,
and then start over and see what next NodePattern
that matches the new sequence of nodes.

The string `\d+` is appended to the NodeType names
in NodePatterns, before matching. This is to make
the NodePatterns visually cleaner to the eye.
E.g., the NodePattern `(VALUE PLUS VALUE)`
will be expanded to `(<VALUE\d+><PLUS\d+><VALUE\d+>)`.

Imagine the parser starting and the program is:
`VALUE1 PLUS2 VALUE3 PLUS4 VALUE5`

Imagine only having a single NodePattern defined, named `ADD`:
`(VALUE PLUS VALUE)`

This NodePattern is expanded to:
`(<VALUE\d+><PLUS\d+><VALUE\d+>)`

This will match:
`<VALUE1><PLUS2><VALUE3>`

Thanks to NodeID being unique,
we can simply use `replace()` to replace this snippet
in the text string representing the full program,
since we know it will match only at one place.

The parser will create a new `ADD` node and replace
the nodes that matched the pattern with the NodeType
concatenated with the NodeID, which will get NodeID 6,
since we had five nodes before.

Since `ADD` *grows into* a `VALUE`, the resulting text will be:
`<VALUE6><PLUS4><INTEGER5>`

Next, the same NodePattern will match again,
and a new `ADD` node will be created,
which will be represented as: `<VALUE7>`

The details of how the parsing algorithm works
is out of scope for this document, but hopefully
this will be enough to understand the NodePatterns
in the grammar below.

The order in which you create NodeTypes by calling `New_Node_Type()`
determine their precedence, unless explicitly specified via
the `Precedence` input param.

There might be multiple capture groups, but exactly one (or none) must match.
If you need multiple parentheses, use `(?:)` to avoid capturing them.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'VALUE', _NodePattern := '(VALUES)');
```

This will raise our `INTEGER` to a `VALUE`, which allows
us to define more general NodePatterns dealing with `VALUE` nodes,
instead of having to repeat our selves and define
specific NodePatterns for all our NodeTypes, such as `INTEGER`, `NUMERIC`, `TEXT`, etc,
if we would have had support for more types than just `INTEGER`.

The `(?:^| )` ensures we match either at the beginning of the
sequence of tokens, or right after a previous token.

```sql
SELECT New_Node_Type(
    _Language    := 'TestLanguage',
    _NodeType    := 'SUB_EXPRESSION',
    _NodePattern := '(LPAREN (?:(?:VALUE | OPS))+ RPAREN)',
    _GrowFrom    := 'VALUE',
    _NodeGroup   := 'VALUES'
);
```

This is the first time we make use of the `GrowFrom` input param to `New_Node_Type()`,
so let's explain it here.

`GrowFrom` means the sequence of nodes matching the NodePattern must
be reduced to a single node of the type specified, in this case `VALUE`.

Only NodeTypes with a `GrowInto` equal to the `GrowFrom` value will be considered
when parsing the sequence of nodes.

This is especially useful when matching expressions, as we can easily define
a NodePattern for a sequence of tokens that will match all the different types
of tokens that can be part of a sub expression, but the tokens matched
must then be parsed isolated separately from the main parsing process,
which is achieved by using the `GrowInto` and `GrowFrom` params.

The regex for a sub expression always matches the inner-most parentheses
not containing any sub expressions that have not already been parsed,
thanks to `LPAREN` and `RPAREN` being neither a `VALUE` nor part of the `OPS` node group.
We only want to match at the beginning or right after an operator token. i.e. part of the `OPS` node group.

The sub expression is itself also part of the NodeGroup `VALUES`,
meaning it will also be raised to a `VALUE` in the next parsing iteration
unless consumed by some other NodePattern with higher precedence.

```sql
SELECT New_Node_Type(
    _Language    := 'TestLanguage',
    _NodeType    := 'EXPRESSION',
    _NodePattern := '((?:VALUE | OPS)+)',
    _GrowFrom    := 'VALUE'
);
```

When we reach this node type in the parser,
we can feel confident all sub expression have now been parsed,
and we're ready to parse expressions without any sub expressions.

The `SUB_EXPRESSION` have at this stage been transformed into `VALUE` nodes
in the text with sequence of tokens the parser is parsing.

In our test language, the entire program must be a single expression,
so our NodePattern starts with `^` and ends with `$` as it must
match the entire program.

Just like `SUB_EXPRESSION`, our `EXPRESSION` is grown from `VALUE`s,
i.e. `_GrowFrom := 'VALUE'`.

Next up is the different arithmetic operators, which all have `_GrowInto := 'VALUE'`,
to tell the parser we want these to be considered when matching node patterns
that have `_GrowFrom := 'VALUE'`.

```sql
SELECT New_Node_Type(
    _Language    := 'TestLanguage',
    _NodeType    := 'GROUP',
    _GrowInto    := 'VALUE',
    _NodePattern := '(?:^ | OPS) (LPAREN VALUE RPAREN)'
);
```

This matches a parentheses group and has the highest precedence, since it's the first NodeType for `_GrowInto := 'VALUE'`.

```sql
SELECT New_Node_Type(
    _Language    := 'TestLanguage',
    _NodeType    := 'UNARY_MINUS',
    _GrowInto    := 'VALUE',
    _NodePattern := '(?:^ | (?!(?:VALUE | RPAREN))[A-Z_]+) (MINUS VALUE)'
);
```

The NodePattern might look a bit complicated, so let's explain it:
We want `(MINUS VALUE)` to match, but only if *NOT* preceded by a `VALUE` or a `RPAREN`,
as that would mean it's a `SUBTRACT` operator instead.
Here we make use of the `(?!)` regex feature, which is negative look ahead,
which means we match here if the regex expression inside `(?!)` does *NOT* match
whatever comes after, which in this case is `[A-Z_]+ `.
Thanks to the capture group being only `(MINUS VALUE)`, we don't consume
the text matched before or after, it is merely used to enforce we
match where we want to, also known as Context Sensitive Parsing.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'DIVIDE',   _GrowInto := 'VALUE', _Precedence := 'PRODUCT', _NodePattern := '(VALUE SLASH VALUE)');
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'MULTIPLY', _GrowInto := 'VALUE', _Precedence := 'PRODUCT', _NodePattern := '(VALUE ASTERISK VALUE)');
```

The NodePatterns for `DIVIDE` and `MULTIPLY` are simpler
since they are *context free* meaning they should always match
regardless of what comes before or after.

This is the first time we make use of `Precedence`, so let's explain it here:
Normally, all NodeTypes have a unique precedence, given by their `NodeTypeID`,
that is, the same order as they were created by calling `New_Node_Type()`.
However, sometimes it is necessary that the precedence is the same
as some other NodeType(s), otherwise we wouldn't do `DIVIDE` and `MULTIPLY`
from left-to-right, but all of one or the other first, depending on
what order they are defined.

The first NodeType given a certain `Precedence` will determine the
precedence for all other NodeTypes with the same `Precedence` value,
that is, `MULTIPLY` will get the same precedence as `DIVIDE`.

```sql
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'ADD',      _GrowInto := 'VALUE', _Precedence := 'SUM', _NodePattern := '(VALUE PLUS VALUE)');
SELECT New_Node_Type(_Language := 'TestLanguage', _NodeType := 'SUBTRACT', _GrowInto := 'VALUE', _Precedence := 'SUM', _NodePattern := '(VALUE MINUS VALUE)');
```

`ADD` and `SUBTRACT` are done after `DIVIDE` and `MULTIPLY`,
which is why they are defined after them,
but we need to give them their own precedence group, `SUM`,
otherwise all `ADD` would be computed before `SUBTRACT`,
e.g. if the program is `1 - 2 + 3`, then `2 + 3` would match
first, if we wouldn't specify any precedence, since `ADD`
was defined before `SUBTRACT`.

But, since they *do* have the same precedence `SUM`,
`1 - 2` will match `SUBTRACT` first since it has the
same precedence as `ADD` and if multiple NodePatterns
matches with the same precedence, then the *left-most*
matches first.

The names used for `Precedence` have no special meaning, use any name,
it's the order in which they are defined that determine their precedence.

```sql
SELECT New_Node_Type(
    _Language     := 'TestLanguage',
    _NodeType     := 'INVALID_EXPRESSION',
    _GrowInto     := 'VALUE',
    _NodePattern  := '^(?!VALUE$)((?:[A-Z_]+)+)$',
    _NodeSeverity := 'ERROR'::severity
);
```

If the sequence of nodes for an expression or sub expression
doesn't match any of the NodeTypes defined for `_GrowInto := 'VALUE'` so far,
we know we have an `INVALID_EXPRESSION`, which in our test language is an `ERROR`.
There is no semantic feature implemented for `INVALID_EXPRESSION`,
it is simply a node created allowing the programmer to look at the tree
or the highlighted source code to understand what invalid expressions
there are in the code. We don't want to abort the parsing
since there might be other invalid expressions to be found.

```sql
SELECT New_Node_Type(
    _Language     := 'TestLanguage',
    _NodeType     := 'UNPARSEABLE',
    _NodePattern  := '(?!EXPRESSION | UNPARSEABLE | PROGRAM)([A-Z_]+)',
    _NodeSeverity := 'ERROR'::severity
);
```

If no NodeTypes match up until here,
and we don't have a single `EXPRESSION`,
and we don't have a single `PROGRAM`,
then this node is `UNPARSEABLE`,
unless it's already an `UNPARSEABLE` node that is.
This is to allow continue to parse the program,
even if encountering something that we cannot parse.

If we don't define an `UNPARSEABLE` node this way,
the parser will still work, but will throw
an `Illegal node patterns` exception if
the entire program could not be parsed into a `PROGRAM`.

`UNPARSEABLE` is different from `INVALID_EXPRESSION`,
since `INVALID_EXPRESSION` only detects invalid expressions,
whereas `UNPARSEABLE` detects unparsable nodes in the main parsing
of the program.

```sql
SELECT New_Node_Type(
    _Language    := 'TestLanguage',
    _NodeType    := 'PROGRAM',
    _NodePattern := '((?:EXPRESSION | UNPARSEABLE)+)',
    _Prologue    := 'ALLOCA',
    _Epilogue    := 'RET'
);
```

Finally we arrive at the NodeType defining what a `PROGRAM` is.
Since we might want to allow further compilation phases
even if we encountered something `UNPARSEABLE`,
we allow any number of `UNPARSEABLE` nodes
but exactly one `EXPRESSION`
followed by any number of `UNPARSEABLE` nodes.

Since this is the first time we make use of `Prologue` and `Epilogue`,
let's explain it here.

If a `Prologue` is specified, a `Node` of its type will be
created and connected automatically *before* connecting
the nodes that matched the NodePattern.

If a `Prologue` is specified, a `Node` of its type will be
created and connected automatically *after* connecting
the nodes that matched the NodePattern.

```sql
\ir soft/TABLES/programs.sql
\ir soft/TABLES/environments.sql
\ir soft/FUNCTIONS/new_program.sql

SELECT New_Program(
    _Language    := 'TestLanguage',
    _Program     := 'AddTwoNumbers'
);

```

A program has a name that is unique per language,
that is, multiple programs with one and the same name
can be implemented in different languages.

In this document, we will create two programs.
The first one `AddTwoNumbers` is only to demonstrate
how to directly create Nodes and Edges,
but won't result in a runnable program.

The second program will be defined further down,
and uses `New_Test()` to also run the program.

## ABSTRACT SYNTAX TREE DATA MODEL

```sql
\ir soft/TABLES/nodes.sql
\ir soft/FUNCTIONS/new_node.sql
```

Nodes are of different NodeTypes and can be either
`Literal` nodes created by the tokenizer with `PrimitiveValue`s
originating from the source code, or they can be abstract
nodes created by the parser, where the `PrimitiveValue`s
are computed when evaluating the node,
or they might not have any value at all,
depending on the NodeType.

```sql
ALTER TABLE Programs ADD FOREIGN KEY (NodeID) REFERENCES Nodes(NodeID);
```

Each program has a current NodeID where we're currently at.
This is also known as the *Program Counter* (PC).

```sql
SELECT New_Node(
    _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = 'AddTwoNumbers'),
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'SOURCE_CODE'),
    _PrimitiveType  := 'text'::regtype,
    _PrimitiveValue := '30+70'
);
```

This will create a node with NodeID 1, since it's the first node we create.

Let's simulate what the tokenizer would do, by creating some Nodes for the above source code:

```sql
SELECT New_Node(
    _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = 'AddTwoNumbers'),
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'INTEGER'),
    _PrimitiveType  := 'integer'::regtype,
    _PrimitiveValue := '30'
);

SELECT New_Node(
    _ProgramID  := (SELECT ProgramID  FROM Programs  WHERE Program  = 'AddTwoNumbers'),
    _NodeTypeID := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'PLUS'),
    _PrimitiveType  := 'text'::regtype,
    _PrimitiveValue := '+'
);

SELECT New_Node(
    _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = 'AddTwoNumbers'),
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'INTEGER'),
    _PrimitiveType  := 'integer'::regtype,
    _PrimitiveValue := '70'
);
```

These nodes created will get NodeIDs 2, 3 and 4.

Next, we will simulate what the parser does,
by switching to the `PARSE` phase and
create an `ADD` node with edges to the integer nodes.

This is normally done by the tree walker, but we'll
do it manually here to be able to demonstrate this isolated:

```sql
UPDATE Programs SET PhaseID = (SELECT PhaseID FROM Phases WHERE Phase = 'PARSE')
WHERE Program = 'AddTwoNumbers';
```

```sql
SELECT New_Node(
    _ProgramID  := (SELECT ProgramID  FROM Programs  WHERE Program  = 'AddTwoNumbers'),
    _NodeTypeID := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'ADD')
);
```

The node created will get NodeID 5.

The `ADD` node doesn't have any `PrimitiveType`/`PrimitiveValue` from the beginning
but these are later infered and calculated from its arguments.

```sql
\ir soft/TABLES/edges.sql
\ir soft/FUNCTIONS/new_edge.sql

SELECT New_Edge(
    _ParentNodeID := 2, -- 30
    _ChildNodeID  := 5  -- ADD
);

SELECT New_Edge(
    _ParentNodeID := 4, -- 70
    _ChildNodeID  := 5  -- ADD
);
```

This connects the two `INTEGER` nodes to the `ADD` node.
The order here is important, since it determines
what is the 1st argument to `ADD`,
and what is the 2nd argument to `ADD`.
The argument order is the same as the order the Edges are created,
i.e. the order in which `New_Edge()` is called, i.e. `ORDER BY EdgeID`.

This results in a tree looking like this:

![layout](https://raw.githubusercontent.com/soft-lang/soft/master/doc/example_graph1.png)

## DOTIR SERIALIZATION / DESERIALIZATION (TABLE)

```sql
\ir soft/TABLES/dotir.sql
```

The state of the program is exported in a Graphviz DOT-compatible format,
named DOTIR as in *DOT Intermediate Representation*.

In DOTIR the `Nodes` data is serialized and stored in the node identifier
in JSON format, which is invisible to the user when generating images for the DOT files,
but which we will use to deserialize the file when importing a DOTIR file.

## LOGGING AND DEBUGGING (TABLES)

```sql
\ir soft/TABLES/ansiescapecodes.sql
```

This installs a lookup-table with the ANSI escape codes
for various colors, to make the output from the compiler
a bit more colorful, e.g. fragments in a text can be highlighted
in a different color to make it stand out what part of the
source code we are referring to.

```sql
\ir soft/TABLES/log.sql
```

The Log table is written to by the `Log()` function.
From the input NodeID, which is at what node
the log message happened, we derive the program,
and the current phase, which is stored to Log,
together with the log message, the log severity
and the current time.

This allows us to carefully follow the different compilation
phases and the program execution during eval
at the desired log severity level.

## LLVM IR

```sql
\ir soft/TABLES/llvmir.sql
\ir soft/FUNCTIONS/llvmir.sql
\ir soft/FUNCTIONS/llvmir_run.sql
```

## DOTIR SERIALIZATION / DESERIALIZATION (FUNCTIONS)

```sql
\ir soft/FUNCTIONS/serialize_node.sql
```

Returns all elementary data for a NodeID as a `json` hash.

Useful to serialize the state of the program.

```sql
SELECT Serialize_Node(_NodeID := 2);

\ir soft/FUNCTIONS/node.sql
```

Returns a formatted text string for the NodeID
on the format `[NodeType][NodeType rank]=[PrimitiveValue]`
or if it's referencing a node, the referenced node
is specified with `->`:

Nodes in different lexical environments
but that originate from the same node,
get the same node text label,
but different colors, making it visually
easy for the eye to see what node in
a lexical environment that corresponds
to what other node in a different lexical environment.

```sql
SELECT Node(_NodeID := 2);
```

```sql
\ir soft/VIEWS/view_nodes.sql
```

Human friendly view showing all Nodes

```sql
SELECT * FROM View_Nodes;
```

```sql
\ir soft/VIEWS/view_edges.sql
```

Human friendly view showing all Edges

```sql
SELECT * FROM View_Edges;
```

```sql
\ir soft/VIEWS/view_programs.sql
```

Human friendly view showing all Programs

```sql
SELECT * FROM View_Programs;
```


```sql
\ir soft/FUNCTIONS/get_node_color.sql
```

All nodes in the same lexical environment
are drawn with the same color.

We use the `set312` color scheme from Graphviz,
which provides 12 very distinct colors.

If running out of colors, a unique combination
of two different colors of these 12 will be used,
that is, if the program needs more than 12
lexcial environments.
This makes it easier to visually see what nodes
belong to the same lexical environment,
as if only using single colors, one would have
to look carefully to see the difference between
e.g. two shades of blue, but by combining two
very different colors, it's easy to spot
nodes of the same color mix.

```sql
SELECT Get_Node_Color(_NodeID := 2);
```

```sql
\ir soft/FUNCTIONS/get_node_attributes.sql
```

Returns the node attributes to be used in the DOTIR file.

* Walkable nodes are drawn with shape=ellipse
  and non-walkable nodes i.e. terminal nodes
  are drawn with shape=box.

* The current program node i.e. where we're at,
  is drawn with a thicker pen width around
  the shape, to make it visually easy to see
  where we are in the program.

```sql
SELECT Get_Node_Attributes(_NodeID := 1, _CurrentNodeID := 2, _PrevNodeID := 1);
```

```sql
\ir soft/FUNCTIONS/get_dotir.sql
```

Generates a DOTIR file of the AST and current state of the program.

```sql
SELECT Get_DOTIR(_CurrentNodeID := 2, _PrevNodeID := 1);
```

```sql
\ir soft/FUNCTIONS/save_dotir.sql
```

Calls `Get_DOTIR()` and saves to DOTIR table

```sql
SELECT Save_DOTIR(_NodeID := 1);
```

```sql
\ir soft/VIEWS/view_dotir.sql
```

Human friendly view showing all DOTIR snapshots

```sql
SELECT * FROM View_DOTIR;
```

## LOGGING AND DEBUGGING (FUNCTIONS)

```sql
\ir soft/FUNCTIONS/notice.sql
```

This function simply does a RAISE NOTICE of the input text.
This is needed since we cannot do RAISE NOTICE directly in psql.

```sql
SELECT Notice('Hello world!');
```

```sql
\ir soft/FUNCTIONS/colorize.sql
```

Let's us colorize the input text.

```sql
SELECT Notice(Colorize(_Text := 'Hello green world!', _Color := 'GREEN'));
```

```sql
\ir soft/FUNCTIONS/strip_ansi.sql
```

Strips the ANSI escape codes from a text string.

```sql
SELECT Strip_ANSI(Colorize(_Text := 'Hello green world!', _Color := 'GREEN'));
```

```sql
\ir soft/FUNCTIONS/get_parent_nodes.sql
```

Recursively gets all parent nodes for a node.
Remember the ADD node we created before with NodeID3?
This should return its two parent nodes, 1 and 2, together with itself, 3:

```sql
SELECT Get_Parent_Nodes(_NodeID := 3);
```

```sql
\ir soft/FUNCTIONS/get_source_code_fragment.sql
```

Shows the entire source code and highlights different
parts of the code with the given color,
where the nodes to highlight are specified as a space
separated list of `[NodeType][NodeID]`.
The below will highlight `30` and `70` in `30+70`, but not the `+`:

```sql
SELECT Notice(Get_Source_Code_Fragment(_Nodes := '<INTEGER2> <INTEGER4>', _Color := 'RED'));
```

```sql
\ir soft/FUNCTIONS/one_line.sql
```

Replaces all white space with a single space character
to make log messages containing source code fragments
more compact.

```sql
SELECT One_Line($$1
    +
3$$);
```

```sql
\ir soft/FUNCTIONS/log.sql
```

Logging of compiler messages,
always passing the current NodeID
to know at what node the log event happened.

```sql
SELECT Log(
    _NodeID   := 1,
    _Severity := 'NOTICE',
    _Message  := 'Hello world! This is a log message.'
);
SELECT Log(
    _NodeID   := 1,
    _Severity := 'ERROR',
    _Message  := 'This is an error message!'
);

\ir soft/FUNCTIONS/highlight_characters.sql
```

Let's us colorize specific characters in the input text.

```sql
SELECT Notice(Highlight_Characters(
    _Text       := 'Hello red world!',
    _Characters := ARRAY[7,8,9],
    _Color      := 'RED'
));
```

## REFERENCING AND DEREFERENCING

A node can either have a `PrimitiveType` AND `PrimitiveValue` OR `ReferenceNodeID`,
but it *CANNOT* have both at the same time.

```sql
\ir soft/FUNCTIONS/dereference.sql
```

Recursively calls itself by following `ReferenceNodeID`
until it finds the node where `ReferenceNodeID IS NULL`
and returns the `NodeID`.

```sql
\ir soft/FUNCTIONS/set_reference_node.sql
```

Sets `Nodes.ReferenceNodeID` to `ReferenceNodeID` for the `NodeID`.

```sql
SELECT New_Node(
    _ProgramID  := (SELECT ProgramID  FROM Programs  WHERE Program  = 'AddTwoNumbers'),
    _NodeTypeID := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'ADD')
);
```

Create a new node

```sql
SELECT * FROM View_Nodes;
```

Make this new node point to NodeID 5

```sql
SELECT Set_Reference_Node(_ReferenceNodeID := 5, _NodeID := 6);
SELECT * FROM View_Nodes;
```

As you can see, `Node()` now returns `ADD2->ADD1`
```sql
SELECT Dereference(_NodeID := 6);
```

## VARIOUS HELPER FUNCTIONS

Various helper-functions:

```sql
\ir soft/FUNCTIONS/language.sql
```

Returns all Languages-columns for a NodeID:

```sql
SELECT * FROM Language(_NodeID := 1);
```

```sql
\ir soft/FUNCTIONS/phase.sql
```

Returns the Phase name for a PhaseID

```sql
SELECT Phase(_PhaseID := 1);
```

```sql
\ir soft/FUNCTIONS/node_type.sql
```

Returns the NodeType name for a NodeTypeID

```sql
\ir soft/FUNCTIONS/parent.sql
```

Returns the parent for a node, assumes there is exactly one parent.

```sql
\ir soft/FUNCTIONS/orphan.sql
```

Returns `TRUE` if the node doesn't have any parents.

```sql
\ir soft/FUNCTIONS/child.sql
```

Returns the child for a node, assumes there is exactly one child.

```sql
\ir soft/FUNCTIONS/count_parents.sql
```

Returns the number of parents for a node.

```sql
\ir soft/FUNCTIONS/count_children.sql
```

Returns the number of children for a node.

```sql
\ir soft/FUNCTIONS/has_child.sql
```

Returns `TRUE` if there is exactly one child for the node.
The optional param `IsNthParent` can be used to check which
edge we are connected to the child via, useful to e.g. check
which argument number a node is to `PARAMETERS`.


```sql
\ir soft/FUNCTIONS/edge.sql
```

Returns the edge between a parent and a child, assumes there is exactly one edge.

```sql
\ir soft/FUNCTIONS/left.sql
```

Returns the left node for a node, that is, the node
with a mutual single child and with the maximum EdgeID
but with a lower EdgeID than our edge to the mutual child.

```sql
\ir soft/FUNCTIONS/right.sql
```

Returns the right node for a node, that is, the node
with a mutual single child and with the minimum EdgeID
but with a higher EdgeID than our edge to the mutual child.

```sql
SELECT Node_Type(_NodeID := 1);
```

```sql
\ir soft/FUNCTIONS/primitive_type.sql
```

Returns the PrimitiveType for a node

```sql
SELECT Primitive_Type(_NodeID := 2);
```

```sql
\ir soft/FUNCTIONS/primitive_value.sql
```

Returns the PrimitiveValue for a node
If the node references a node,
the value for the referenced node is returned.

```sql
SELECT Primitive_Value(_NodeID := 2);
```

```sql
\ir soft/FUNCTIONS/node_name.sql
```

Returns the NodeName for a node,
e.g. the name of a variable, function, class, etc.

```sql
\ir soft/FUNCTIONS/truthy.sql
```

Evaluate if a node is boolean true or false.

```sql
\ir soft/FUNCTIONS/explain_node.sql
```

Show AST for node.

```sql
SELECT Explain_Node(_NodeID := 2);
```

```sql
\ir soft/FUNCTIONS/print_node.sql
```

Print node to STDOUT.

```sql
SELECT Print_Node(_NodeID := 2);
```


```sql
\ir soft/FUNCTIONS/strip_zeroes.sql
```

Strips meaningless zeroes at the end from numeric values,
so that e.g. `1.0000` becomes `1`, or `12.34000` becomes `12.34`.

```sql
\ir soft/FUNCTIONS/builtin.sql
```

Returns the language name for a built-in function.

```sql
\ir soft/FUNCTIONS/call_args.sql
```

Returns an array of NodeIDs for the arguments to a function `CALL`.

```sql
\ir soft/FUNCTIONS/retry.sql
```

Helper-function to manually retry running the program upon errors.

```sql
\ir soft/FUNCTIONS/sort_array.sql
```

```sql
\ir soft/FUNCTIONS/set_node_name.sql
```

```sql
\ir soft/FUNCTIONS/get_single_node.sql
```

```sql
\ir soft/FUNCTIONS/data_node.sql
```

## CLONING OF NODES

To clone a node means creating new Nodes with the same `PrimitiveValue`s
and the same NodeTypes, for the node and all its parents, and all
it's parents parents, etc, recursively.

We keep track of what `EdgeID`s we have visited to break out from
possible cycles in the graph.

```sql
\ir soft/FUNCTIONS/new_environment.sql
\ir soft/FUNCTIONS/out_of_scope.sql
\ir soft/FUNCTIONS/clone_node.sql
\ir soft/FUNCTIONS/clone.sql
\ir soft/FUNCTIONS/closure.sql
\ir soft/FUNCTIONS/declared.sql
\ir soft/FUNCTIONS/is_ancestor_to.sql
\ir soft/FUNCTIONS/nthparent.sql
\ir soft/FUNCTIONS/get_closure_nodes.sql
```

Let's clone the ADD node:

```sql
SELECT Clone_Node(_NodeID := 5);
SELECT * FROM View_Nodes;
SELECT * FROM View_Edges;
```

As you can see, the original `ADD` node and its two parent `INTEGER` nodes,
have now been cloned, and you can see the `ClonedFromNode` and `ClonedRootNode`
to see where they originate from.

## KILLING OF NODES

During different compilation phases, nodes that are not necessary anymore
are removed, to simplify the graph. For instance, the `PLUS` node generated
for the plus character `+` in the program `1 + 2` can be removed once
the abstract `ADD` node with its edges have been created.

Before a node can be killed, all its edges must be killed first.

```sql


\ir soft/FUNCTIONS/kill_edge.sql
SELECT Kill_Edge(_EdgeID := 3);
SELECT * FROM View_Edges;

\ir soft/FUNCTIONS/kill_node.sql
SELECT Kill_Node(_NodeID := 6);
SELECT * FROM View_Nodes;

\ir soft/FUNCTIONS/kill_clone.sql
SELECT Kill_Clone(_ClonedRootNodeID := 7);

\ir soft/FUNCTIONS/discard_node.sql
```

This results in killing the cloned node and all its parent Nodes and Edges

```sql
SELECT * FROM View_Nodes;
SELECT * FROM View_Edges;
```

## COPYING OF NODES

```sql
\ir soft/FUNCTIONS/copy_node.sql
```

Copy value from one node to another node,
by making a clone of the FromNodeID
and then changing all Edges pointing to/from the ToNodeID
to instead point to/from the new cloned node,
and then finally killing the ToNodeID.

```sql
SELECT Copy_Node(
    _FromNodeID := 2,
    _ToNodeID   := 4
);
```

Copies the INTEGER node with value 30 to the one with 70

```sql
SELECT * FROM View_Nodes;
```

## PARSER HELPER-FUNCTIONS

Below are some helper-functions used by `"PARSE"."ENTER_SOURCE_CODE"()`:

```sql
\ir soft/FUNCTIONS/expand_node_pattern.sql
```

This expands NodeGroups and appends `\d+` to each NodeType also `[A-Z_]+`
which is the regex pattern to signify *any node type*.

```sql
SELECT Expand_Node_Pattern(
    _NodePattern := NodeTypes.NodePattern,
    _LanguageID  := Languages.LanguageID
)
FROM NodeTypes
INNER JOIN Languages ON Languages.LanguageID = NodeTypes.LanguageID
WHERE Languages.Language = 'TestLanguage'
AND NodeTypes.NodePattern IS NOT NULL;

\ir soft/FUNCTIONS/get_capturing_group.sql
```

Returns what the single capture group matches,
and checks there is exactly one capture group.
If strict, then the pattern must match at exactly one place.
If non strict, the pattern is allowed to match at multiple places,
and if so, the first is returned.

```sql
SELECT Get_Capturing_Group(
    _String  := '<FOO1><BAR2><BAZ3>',
    _Pattern := '<FOO\d+>(<BAR\d+>)<BAZ\d+>',
    _Strict  := TRUE
);

SELECT Get_Capturing_Group(
    _String  := '<FOO1><BAR2><BAZ3><FOO4><BAR5><BAZ6>',
    _Pattern := '<FOO\d+>(<BAR\d+>)<BAZ\d+>',
    _Strict  := FALSE
);

\ir soft/FUNCTIONS/precedence.sql
\ir soft/VIEWS/view_node_types.sql
\ir soft/VIEWS/view_error_types.sql
```

Returns the precedence for the node type.

```sql
SELECT NodeTypeID, Precedence(NodeTypeID), NodeType FROM NodeTypes ORDER BY NodeTypeID;

\ir soft/FUNCTIONS/set_program_node.sql
```

Set's the program's current node.
The ProgramID is resolved from the NodeID.

```sql
SELECT Set_Program_Node(_NodeID := 1);

\ir soft/FUNCTIONS/set_program_phase.sql
```

Set's the program's current phase.

```sql
SELECT Set_Program_Phase(
    _Language := 'TestLanguage',
    _Program  := 'AddTwoNumbers',
    _Phase    := 'TOKENIZE'
);

```

## TREE WALKER

![layout](https://raw.githubusercontent.com/soft-lang/soft/master/doc/tree_walker.gif)

The above animation shows how the tree walker will traverse the example program `ShouldComputeToTen`
under the `TESTING` section further down.

The AST once parsed will strictly speaking not always be a tree any longer,
since there might be self-reference due to e.g. recursive functions,
but let's stick to the term *tree walker* anyways since *graph walker*
sounds awkward.

Walking the tree starts with calling `Enter_Node()` with the NodeID
where the program should start executing, normally the `PROGRAM` node,
which is the only node with no children for a program, i.e. it is the
last node created after having completely parsed the program.

_TODO: Explain the tree walker and the functions_

```sql
\ir soft/FUNCTIONS/determine_return_type.sql
```

Semantic functionality is implemented as database functions.
If such a function returns `anyelement`, the actual type
that will be returned is inferred from the input arg types
in the AST.

```sql
SELECT Determine_Return_Type(
    _InputArgTypes    := ARRAY['boolean', 'anyelement', 'anyelement']::regtype[],
    _ParentValueTypes := ARRAY['boolean', 'integer', 'integer']::regtype[]
);
```

```sql
\ir soft/FUNCTIONS/matching_input_types.sql
```

Similar to `Determine_Return_Type()`, but returns `true` if
the `InputArgTypes` matches the `ParentValueTypes`, and `false` otherwise.

```sql
\ir soft/FUNCTIONS/set_node_value.sql
```

Sets the `PrimitiveType` and `PrimitiveValue` for the node.

```sql
SELECT Set_Node_Value(
    _NodeID         := 2,
    _PrimitiveType  := 'integer'::regtype,
    _PrimitiveValue := '70'
);
```

```sql
\ir soft/FUNCTIONS/enter_node.sql
```

Called when a node is `ENTER`ed.
Sets the `Program Counter` (PC) to the input NodeID.
If there is a matching `[Phase].ENTER_[NodeType]()` function, it is executed.

```sql
SELECT Enter_Node(_NodeID := 2);
```

```sql
\ir soft/FUNCTIONS/eval_node.sql
```

Called when a node is visited and executes `[Phase].[NodeType]()`,
if there is a function declared for the NodeType.

If there *is* a function for the NodeType, then the argument types *MUST* match,
otherwise a *Type mismatch* excpetion is thrown.

The node parent's values are passed as arguments to the function.

The result from the computation is stored in the node's `PrimitiveType` and `PrimitiveValue` columns.

```sql
\ir soft/FUNCTIONS/leave_node.sql
```

Called when `LEAVE`ing a node.
Does *not* set the `Program Counter` (PC), since that must have been done by the caller already.
If there is a matching `[Phase].LEAVE_[NodeType]()` function, it is executed.

```sql
UPDATE Programs SET Direction = 'LEAVE' WHERE Program = 'AddTwoNumbers';
SELECT Leave_Node(_NodeID := 2);

\ir soft/FUNCTIONS/next_node.sql
```

Must only be called when the `Direction` is `LEAVE`.
Walks to the next node on the same level, if there are more nodes
with higher EdgeIDs connected to the same `ParentNode` as the current node,
or if the current node is the last node on the level,
the function will descend the the `ChildNode`,
or if there is no child, it will move on to the next `Phase`,
or if there is no next `Phase`, the program has reached its final `Phase` and will therefore exit.

```sql
SELECT Next_Node(_NodeID := 1);
```


```sql
\ir soft/FUNCTIONS/get_program_node.sql
```

Returns the *program node* for the program,
which might or might not be called `PROGRAM`.

Instead of looking for a node of type `PROGRAM`,
the function looks for a single node that isn't a parent
to any children nodes, meaning it is the one and only
*last* node created, connecting all parts of the graph
via its parent nodes.

To test this function, we will need to get rid of some
unconnected nodes in our first test program,
so that NodeID 5 will be the only node with no children nodes.

*TODO: I just realized the functions Set_Program_Node() and Get_Program_Node()
must be renamed, since Set_Program_Node() actually sets Programs.NodeID,
i.e. the Program Counter (PC), whereras Get_Program_Node() does something
completely different, namely returning the NodeID that is actually the PROGRAM,
which is not the same thing. Set_Program_Counter_Node() would be a better name.*

```sql
SELECT Set_Program_Node(_NodeID := 5);
SELECT Kill_Node(_NodeID := 1);
SELECT Kill_Node(_NodeID := 3);
SELECT Get_Program_Node(1);
```

```sql
\ir soft/FUNCTIONS/set_walkable.sql
```

Sets `Nodes.Walkable` to `true` or `false`.

This is used by the semantic functions to control
if the tree walker should, when getting there,
walk to a node or not.

This is useful e.g. for `IF` expressions/statements
to open/close the `true` or `false` branch
depending on the calculated boolean `condition`
for the `IF`.

This is also used by function calls, to know if we
are returning from a function, or if we're going
to make a new call to the function.

```sql
SELECT Set_Walkable(_NodeID := 5, _Walkable := TRUE);

\ir soft/FUNCTIONS/set_edge_parent.sql
\ir soft/FUNCTIONS/set_edge_child.sql
```

Change the `ParentNodeID` for an existing `EdgeID`.

```sql
SELECT Set_Edge_Parent(_EdgeID := 1, _ParentNodeID := 2);

\ir soft/FUNCTIONS/valid_node_pattern.sql
```

Checks that a `NodePattern` only contain valid `NodeType`s.
This is to reduce the risk for typos when defining the grammar for a language.

```sql
SELECT Valid_Node_Pattern('TestLanguage', '(VALUE PLUS VALUE)');

\ir soft/FUNCTIONS/walk_tree.sql
```

Called in a loop by `Run()` until program exits.

```sql
\ir soft/FUNCTIONS/run.sql
```

Runs the program by calling `Walk_Tree()` until the program exits.

## FINDING NODES IN THE GRAPH

```sql
\ir soft/FUNCTIONS/find_node.sql
```

This is a helper-functions used by the functions
implementing semantic functionality below,
used to from a starting node, find some other node,
by describing the path to it.

The syntax for the path is:

^([`<-`|`->`] `[NodeType]`)+$

`<-` means the right side is a `child`.
`->` means the right side is a `parent`.

The path is expanded to a normal SQL query.

The function supports descending down the
tree to look for nodes matching the pattern,
which is used to map what `VARIABLE` an `IDENTIFIER`
refers to during the `MAP_VARIABLES` phase.

```sql
SELECT Find_Node(
    _NodeID  := 2,
    _Descend := FALSE,
    _Strict  := TRUE,
    _Path    := '-> ADD'
);
```

This means we want to follow an `Edge` where `ParentNodeID=2` and where
the `ChildNodeID` should point to a node of type `ADD`.

```sql
\ir soft/FUNCTIONS/resolve.sql
```

Resolve uses Find_Node() to do name resolution.

## SEMANTIC FUNCTIONALITY

So far we have only implemented the core functionality of the compiler,
but not provided any semantic functionality at all to actually do anything.
We have defined a simple grammar for our language, but for anything
to happen, we need to add functions that will do things when we
`ENTER`, _evaluate_ or `LEAVE` a node.

The functionality provided is more than we need for our test language,
but since this document is the installation script,
we need to add all of it here, even though using some parts of it.

All directories and functions from here on have names in _ALL CAPS_
to visually distinguish them from the core functionality above.

Each `PHASE` has its own _database schema_ and its own _file directory_.

The files are given the same name as the NodeTypes.NodeType
they represent, prefixed with `ENTER_`, `LEAVE_` or no prefix,
to control if the function should be called when you `ENTER`
or `LEAVE` the node.

Functions without any prefix are called when the node is _evaluated_.

Functions are called in this order:
1. `[Phase].ENTER_[NodeType]()`
1. `[Phase].[NodeType]()`
1. `[Phase].LEAVE_[NodeType]()`

Each `Walkable` node is visited exactly _two times_,
once when *entering* the node, and once when *leaving* the node,
i.e. when descending.

### TOKENIZE

```sql
\ir TOKENIZE/ENTER_SOURCE_CODE.sql
```

The `TOKENIZE` phase creates new token Nodes by matching the
`SOURCE_CODE` node's PrimitiveValue text, i.e. the source code,
against all literal NodeTypes Literal or LiteralPattern.

### EXTRACT_TESTS

```sql
\ir EXTRACT_TESTS/ENTER_TEST_EXPECTED_STDOUT.sql
```

For languages where tests are inlined in the code
using a special syntax, such as using comments
with some keyword to indicate something is expected
on STDOUT, e.g.: `// expect: Hello world!`, this phase
can be used to set columns in `Tests` such as `ExpectedSTDOUT`
to the parsed values from the code, before such nodes
are removed just like white space and comments in the
next phase `DISCARD`.

### DISCARD

```sql
\ir DISCARD/LEAVE_WHITE_SPACE.sql
\ir DISCARD/LEAVE_COMMENT.sql
\ir DISCARD/LEAVE_TEST_EXPECTED_STDOUT.sql
\ir DISCARD/LEAVE_ILLEGAL.sql
```

The `DISCARD` phase eliminates `WHITE_SPACE` nodes.
If white space matters in a language,
this phase is simply skipped.

### PARSE

```sql
\ir PARSE/ENTER_SOURCE_CODE.sql
```

The `PARSE` phase creates new an Abstract-Syntax Tree
which means creating new abstract Nodes
and new Edges to connect them to the graph.

This is done by matching the sequence of tokens against
the NodePatterns defined in NodeTypes,
in Precedence order, and if two NodeTypes
of the same Precedence match, then the
left most match is selected.

### PARSE_ERRORS

```sql
\ir PARSE_ERRORS/ENTER_PROGRAM.sql
```

### VALIDATE

```sql
\ir VALIDATE/ENTER_ASSIGNMENT.sql
\ir VALIDATE/ENTER_RETURN_STATEMENT.sql
\ir VALIDATE/ENTER_CALL.sql
\ir VALIDATE/ENTER_WHILE_BODY.sql
\ir VALIDATE/ENTER_FOR_BODY.sql
\ir VALIDATE/ENTER_TRUE_BRANCH.sql
\ir VALIDATE/ENTER_FALSE_BRANCH.sql
```

The `VALIDATE` phase inspects the AST to check for
grammatical errors that were not detected during the
parse phase.

### REDUCE

```sql
\ir REDUCE/ENTER_PROGRAM.sql
\ir REDUCE/ENTER_UNPARSEABLE.sql
```

The `REDUCE` phase shrinks the AST by eliminating
unnecessary middle-men nodes that have exactly
one parent and one child.

### MAP_VARIABLES

```sql
\ir soft/FUNCTIONS/global.sql
```

Returns `TRUE` if the node is not inside a function.

```sql
\ir MAP_VARIABLES/ENTER_IDENTIFIER.sql
\ir MAP_VARIABLES/ENTER_THIS.sql
\ir MAP_VARIABLES/ENTER_SUPER.sql
\ir MAP_VARIABLES/ENTER_DEC_DATA.sql
\ir MAP_VARIABLES/ENTER_DEC_PTR.sql
\ir MAP_VARIABLES/ENTER_INC_DATA.sql
\ir MAP_VARIABLES/ENTER_INC_PTR.sql
\ir MAP_VARIABLES/ENTER_LOOP_IF_DATA_NOT_ZERO.sql
\ir MAP_VARIABLES/ENTER_READ_STDIN.sql
\ir MAP_VARIABLES/ENTER_WRITE_STDOUT.sql
\ir MAP_VARIABLES/LEAVE_FUNCTION_DECLARATION.sql
\ir MAP_VARIABLES/LEAVE_CLASS_DECLARATION.sql
\ir MAP_VARIABLES/LEAVE_IF_EXPRESSION.sql
\ir MAP_VARIABLES/LEAVE_IF_STATEMENT.sql
\ir MAP_VARIABLES/LEAVE_VARIABLE.sql
\ir MAP_VARIABLES/LEAVE_ARGUMENTS.sql
```

The `MAP_VARIABLES` phase looks up what
`VARIABLE` an `IDENTIFIER` refers to,
and connects it by killing the `IDENTIFIER`
node and replacing it with a new `Edge`
to the `VARIABLE`.

### SHORT_CIRCUIT

```sql
\ir SHORT_CIRCUIT/LEAVE_LOGICAL_AND.sql
\ir SHORT_CIRCUIT/LEAVE_LOGICAL_OR.sql
```

The `SHORT_CIRCUIT` phase looks blocks
the path to evaluate the right argument
for the `AND` and `OR` operators,
which will be made walkable again upon
evaluation of the left argument,
depending on if the left argument was
`TRUE` or  `FALSE`.

### EVAL

```sql
\ir EVAL/ADD.sql
\ir EVAL/DIVIDE.sql
\ir EVAL/ENTER_DEC_DATA.sql
\ir EVAL/ENTER_DEC_PTR.sql
\ir EVAL/ENTER_INC_DATA.sql
\ir EVAL/ENTER_INC_PTR.sql
\ir EVAL/ENTER_LOOP_IF_DATA_NOT_ZERO.sql
\ir EVAL/LEAVE_LOOP_IF_DATA_NOT_ZERO.sql
\ir EVAL/ENTER_READ_STDIN.sql
\ir EVAL/ENTER_WRITE_STDOUT.sql
\ir EVAL/ENTER_LOOP_MOVE_DATA.sql
\ir EVAL/ENTER_LOOP_MOVE_PTR.sql
\ir EVAL/ENTER_LOOP_SET_TO_ZERO.sql
\ir EVAL/ENTER_RET.sql
\ir EVAL/ENTER_PARAMETERS.sql
\ir EVAL/ENTER_THIS.sql
\ir EVAL/ENTER_SUPER.sql
\ir EVAL/ENTER_IDENTIFIER.sql
\ir EVAL/EQUAL.sql
\ir EVAL/GREATER_THAN.sql
\ir EVAL/GREATER_THAN_OR_EQUAL_TO.sql
\ir EVAL/LEAVE_ARRAY.sql
\ir EVAL/LEAVE_BLOCK_EXPRESSION.sql
\ir EVAL/LEAVE_BLOCK_STATEMENT.sql
\ir EVAL/LEAVE_CALL.sql
\ir EVAL/LEAVE_HASH.sql
\ir EVAL/LEAVE_GET.sql
\ir EVAL/LEAVE_IF_EXPRESSION.sql
\ir EVAL/LEAVE_IF_STATEMENT.sql
\ir EVAL/LEAVE_FOR_EXIT_CONDITION.sql
\ir EVAL/LEAVE_FOR_INCREMENT_STEP.sql
\ir EVAL/LEAVE_FOR_STATEMENT.sql
\ir EVAL/LEAVE_WHILE_EXIT_CONDITION.sql
\ir EVAL/LEAVE_WHILE_BODY.sql
\ir EVAL/LEAVE_INDEX.sql
\ir EVAL/LEAVE_DECLARATION.sql
\ir EVAL/LEAVE_LOGICAL_AND.sql
\ir EVAL/LEAVE_LOGICAL_OR.sql
\ir EVAL/LEAVE_ASSIGNMENT.sql
\ir EVAL/LEAVE_PROGRAM.sql
\ir EVAL/LEAVE_PRINT_STATEMENT.sql
\ir EVAL/LEAVE_RETURN_STATEMENT.sql
\ir EVAL/LEAVE_STATEMENTS.sql
\ir EVAL/LESS_THAN.sql
\ir EVAL/LESS_THAN_OR_EQUAL_TO.sql
\ir EVAL/MULTIPLY.sql
\ir EVAL/NOT.sql
\ir EVAL/NOT_EQUAL.sql
\ir EVAL/SUBTRACT.sql
\ir EVAL/UNARY_MINUS.sql
\ir EVAL/LEAVE_FALSE_BRANCH.sql
\ir EVAL/LEAVE_TRUE_BRANCH.sql
```

The `EVAL` phase computes the values
for nodes when they are visited.

### OPTIMIZE

```sql
\ir OPTIMIZE/LEAVE_DEC_DATA.sql
\ir OPTIMIZE/LEAVE_DEC_PTR.sql
\ir OPTIMIZE/LEAVE_INC_DATA.sql
\ir OPTIMIZE/LEAVE_INC_PTR.sql
\ir OPTIMIZE/LEAVE_LOOP_IF_DATA_NOT_ZERO.sql
```

### LLVM_IR

```sql
\ir LLVM_IR/ENTER_PROGRAM.sql
\ir LLVM_IR/ENTER_DEC_DATA.sql
\ir LLVM_IR/ENTER_DEC_PTR.sql
\ir LLVM_IR/ENTER_INC_DATA.sql
\ir LLVM_IR/ENTER_INC_PTR.sql
\ir LLVM_IR/ENTER_LOOP_IF_DATA_NOT_ZERO.sql
\ir LLVM_IR/LEAVE_LOOP_IF_DATA_NOT_ZERO.sql
\ir LLVM_IR/ENTER_LOOP_SET_TO_ZERO.sql
\ir LLVM_IR/ENTER_LOOP_MOVE_PTR.sql
\ir LLVM_IR/ENTER_LOOP_MOVE_DATA.sql
\ir LLVM_IR/ENTER_READ_STDIN.sql
\ir LLVM_IR/ENTER_WRITE_STDOUT.sql
\ir LLVM_IR/LEAVE_PROGRAM.sql
```

### BUILT_IN_FUNCTIONS

```sql
\ir BUILT_IN_FUNCTIONS/FIRST.sql
\ir BUILT_IN_FUNCTIONS/LAST.sql
\ir BUILT_IN_FUNCTIONS/LENGTH.sql
\ir BUILT_IN_FUNCTIONS/PUSH.sql
\ir BUILT_IN_FUNCTIONS/PUTS.sql
\ir BUILT_IN_FUNCTIONS/REST.sql
```

The `BUILT_IN_FUNCTIONS` phase contains
functionality that is built-in to languages.

## TESTING

```sql
\ir soft/TABLES/tests.sql
\ir soft/FUNCTIONS/new_test.sql
```

`New_Test()` will create a `SOURCE_CODE` node with the `SourceCode`
and store the other input params in `Tests`,
but it won't actually run the test.

```sql
SELECT New_Test(
    _Language      := 'TestLanguage',
    _Program       := 'ShouldComputeToTen',
    _SourceCode    := '1 + 2 - - 3 * 4 - 15 / (2 + 1)',
    _ExpectedType  := 'integer',
    _ExpectedValue := '10',
    _LogSeverity   := 'DEBUG5'
);
```

```sql
\ir soft/VIEWS/view_tests.sql
```

Human friendly view showing all Tests

```sql
SELECT * FROM View_Tests;
```

```sql
\ir soft/FUNCTIONS/get_files.sql
```

If you want to clean-up all test data written,
you can manually run `TRUNCATE soft.Languages CASCADE` in `psql`,
but in case you want to poke around, they are not truncated by default.

If you want to get a visual idea of exactly what is going on in
the different compilation phases, step by step, instruction by instruction,
you can run `export-dotir`, and images with DOTIR graphs will be
generated by Graphviz. This requires you have Graphviz installed.

```sql
\ir soft/FUNCTIONS/instantiate_superclass.sql
\ir soft/FUNCTIONS/get_field.sql
```

We have reached the end.
We should now be able to compile and run our test program `ShouldComputeToTen`,
and it should produce `10` as output.

Run() will call cron.Register() to assign a ProcessID to the program,
so that it will be executed by PgCronJob.

```sql
SELECT Run(
    _Language := 'TestLanguage',
    _Program  := 'ShouldComputeToTen'
);
```

The overloaded version of Run() taking only ProcessID as input
is the function being called by PgCronJob for each clock cycle
to execute. To simulate that, let's run Run() until it doesn't
return 'AGAIN'.

```sql
DO LANGUAGE plpgsql $$
BEGIN
LOOP
    IF (
        SELECT Run(ProcessID) FROM View_Programs WHERE Language = 'TestLanguage' AND Program = 'ShouldComputeToTen'
    ) = 'DONE' THEN
        EXIT;
    END IF;
END LOOP;

IF (SELECT OK FROM View_Tests WHERE Language = 'TestLanguage' AND Program = 'ShouldComputeToTen') THEN
    RAISE NOTICE '%', Colorize('Installation successful.', 'GREEN');
ELSE
    RAISE NOTICE '%', Colorize('Installation failed.', 'RED');
END IF;
END$$;
```

```sql
COMMIT;
```
