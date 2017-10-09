ROLLBACK;

SET client_encoding TO 'UTF8';

\set AUTOCOMMIT OFF

BEGIN;

SET search_path TO soft;

-- Support reinstall by first dropping everything:

-- All core functionality and helper-functions
-- shared between the compilation phases
-- reside in the "soft" schema:

DROP SCHEMA IF EXISTS soft CASCADE;
CREATE SCHEMA soft;

-- Compilation phases have their own schemas
-- written in ALL CAPS, to make it visually
-- easy to spot them.
--
-- All semantic functionality is implemented
-- in these schemas:

DROP SCHEMA IF EXISTS "TOKENIZE" CASCADE;
CREATE SCHEMA "TOKENIZE";

DROP SCHEMA IF EXISTS "DISCARD" CASCADE;
CREATE SCHEMA "DISCARD";

DROP SCHEMA IF EXISTS "PARSE" CASCADE;
CREATE SCHEMA "PARSE";

DROP SCHEMA IF EXISTS "REDUCE" CASCADE;
CREATE SCHEMA "REDUCE";

DROP SCHEMA IF EXISTS "MAP_VARIABLES" CASCADE;
CREATE SCHEMA "MAP_VARIABLES";

DROP SCHEMA IF EXISTS "EVAL" CASCADE;
CREATE SCHEMA "EVAL";

DROP SCHEMA IF EXISTS "BUILT_IN_FUNCTIONS" CASCADE;
CREATE SCHEMA "BUILT_IN_FUNCTIONS";

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

\ir soft/TYPES/severity.sql
-- Used for logging and borrows the levels from PostgreSQL.
-- DEBUG5..1, INFO, NOTICE, WARNING, ERROR, LOG, FATAL, PANIC

\ir soft/TYPES/variablebinding.sql
-- Controls how values are captured.
-- CAPTURE_BY_REFERENCE, CAPTURE_BY_VALUE

\ir soft/TYPES/direction.sql
-- Controls if walking up or down the tree.
-- ENTER, LEAVE

-- Used by languages to represent the 'nil' value.
\ir soft/TYPES/nil.sql

\ir soft/TYPES/batchjobstate.sql
-- Used by Run_Test() to tell if we should run it AGAIN or if we're DONE.
-- AGAIN, DONE

-------------------------------------------------------------------------------
-- LANGUAGES
-------------------------------------------------------------------------------

\ir soft/TABLES/languages.sql
\ir soft/FUNCTIONS/new_language.sql
-- A language has a unique Language name, a unique LanguageID,
-- and multiple semantic settings that all need to be defined.
SELECT New_Language(
    _Language              := 'foo',
    _LogSeverity           := 'NOTICE',
    _VariableBinding       := 'CAPTURE_BY_VALUE',
    _ImplicitReturnValues  := TRUE,
    _StatementReturnValues := TRUE,
    _ZeroBasedNumbering    := TRUE,
    _TruthyNonBooleans     := TRUE,
    _NilIfArrayOutOfBounds := TRUE,
    _NilIfMissingHashKey   := TRUE
);
SELECT * FROM Languages;

-------------------------------------------------------------------------------
-- BUILT-IN FUNCTIONS
-------------------------------------------------------------------------------

\ir soft/TABLES/builtinfunctions.sql
\ir soft/FUNCTIONS/new_built_in_function.sql
-- Languages can have built-in functions such as
-- functions provided by external libraries
-- or implemented in the host language of the
-- interpreter.
-- Our test language doesn't have any built-ins,
-- but let's create and drop one just to show
-- how it's done:

-- First, create a function for our built-in in the BUILT_IN_FUNCTIONS schema.
-- It MUST take exactly one parameter: _NodeID integer.
-- It MUST return void.
--
-- Our example function will be named "NOOP" and it won't do anything.
CREATE OR REPLACE FUNCTION "BUILT_IN_FUNCTIONS"."NOOP"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
RETURN;
END;
$$;

-- Then, assign an identifier to this function.
-- The name can be different, to allow reusing the same
-- functionality between different languages where
-- the built-in works the same but have different names:
SELECT New_Built_In_Function(
    _Language               := 'foo',
    _Identifier             := 'puts',
    _ImplementationFunction := 'PUTS'
);

-------------------------------------------------------------------------------
-- PHASES
-------------------------------------------------------------------------------

\ir soft/TABLES/phases.sql
\ir soft/FUNCTIONS/new_phase.sql
-- Different languages have different phases,
-- so we need to tell the compiler what phases
-- there are for a language, and in what order
-- they should be executed.
--
-- The order in which we call New_Phase() determine
-- the order the phases they will be executed,
-- i.e. ORDER BY PhaseID:
SELECT New_Phase(_Language := 'foo', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'foo', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'foo', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'foo', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'foo', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'foo', _Phase := 'EVAL');

-------------------------------------------------------------------------------
-- NODE TYPES
-------------------------------------------------------------------------------

\ir soft/TABLES/nodetypes.sql
\ir soft/FUNCTIONS/new_node_type.sql
-- Different languages might have different syntax for one and the same thing.
-- This is all fine, but to be able to reuse semantic functionality
-- we will agree on language agnostic NodeType names, and let any semantic
-- differences be controlled by the language settings.
--
-- NodeType names MUST MATCH: ^[A-Z_]+$
--
-- Digits are not allowed not only to discourage bad names,
-- but also made the parsing algorithm simpler. More on that later.
--
-- When implementing a new language, you might need to add new NodeTypes,
-- if some token or semantic feature is missing, but always first
-- see if there already is an existing NodeType to maximize reusage.
-- If the semantic behaviour doesn't match your case, you should
-- add a new language setting, and modify the existing code for
-- the NodeType.
--
-- For the sake of testing, we will define a simple grammar
-- for our "foo" language that is only capable of calculating
-- simple arithmetic expressions using + - / * ( )
--
-- Note that the NodeTypes for the various arithmetic tokens
-- don't have any explicit precedence, but their arithmetic *operators* do,
-- i.e. the "ADD" operator have it, but not the "PLUS" token.

-------------------------------------------------------------------------------
-- TOKENIZE
-------------------------------------------------------------------------------

-- The tokenizer uses NodeTypes where Literal or LiteralPattern is defined.
-- The tokenizer creates a new Node where PrimitiveValue is set to the matching text.
-- The tokenizer begins matching at the first character in the source code,
-- and tries to match the longest _Literal first, and then if there is no match
-- it tries to find a matching _LiteralPattern instead.


SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SOURCE_CODE', _PrimitiveType := 'text'::regtype);
-- The node containing the source code of the program stored as text
-- in Nodes.PrimitiveValue.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ALLOCA', _PrimitiveType := 'void'::regtype);
-- The node per function to which all the function's arguments and local variables are connected.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'RET',    _PrimitiveType := 'void'::regtype);
-- The node per function which determines where to continue when we're done executing the function.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'PLUS',     _Literal := '+', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'MINUS',    _Literal := '-', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ASTERISK', _Literal := '*', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SLASH',    _Literal := '/', _NodeGroup := 'OPS');
-- Arithmetic tokens defines the _Literal text that must match exactly in the source code.
-- We group them together by using the _NodeGroup feature, which lets us refer to them as a
-- group later on.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'LPAREN', _Literal := '(');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'RPAREN', _Literal := ')');
-- These tokens are used to explicitly tell we want a SUB_EXPRESSION to be executed first,
-- before executing the main expression.
-- These are not part of the same NodeGroup, as we don't want them to match a normal EXPRESSION,
-- but only a SUB_EXPRESSION.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'WHITE_SPACE', _LiteralPattern := '(\s+)');
-- White space is not ignored by default in this compiler,
-- as there might be languages where white space matters,
-- such as Python.
--
-- Here we make use of the _LiteralPattern feature for the first time,
-- so let's explain it before moving on:
--
-- * It must contain exactly one capture group, i.e. one ().
-- * If you need multiple parenthesis, use (?:) to avoid capturing.
-- * The text captured is stored as the Nodes.PrimitiveValue.
--
-- If "foo" would have support for double-quotes text string, which it don't,
-- the _LiteralPattern would be: "((?:[^"\\]|\\.)*)"
-- This would make the double-quotes (") to NOT be included in the PrimitiveValue,
-- since the capture group captures whatever is in between the double-quotes.

SELECT New_Node_Type(
    _Language       := 'foo',
    _NodeType       := 'INTEGER',
    _PrimitiveType  := 'integer'::regtype,
    _NodeGroup      := 'VALUE',
    _LiteralPattern := '([0-9]+)'
);
-- In "foo" we only have support for integers,
-- but if we would have support for e.g. boolean, text, numeric, etc,
-- they would also get _NodeGroup := 'VALUE', to allow refering to them
-- as a group in the grammar.

SELECT New_Node_Type(
    _Language       := 'foo',
    _NodeType       := 'ILLEGAL',
    _LiteralPattern := '(.)',
    _NodeSeverity   := 'ERROR'::severity
);
-- Finally, if we are still parsing source code
-- and no Literal or LitteralPattern matches
-- then we have found an illegal character
-- which in our language is an ERROR,
-- but you can imagine some other language
-- where illegal characters only leads to a WARNING.

-- We're done defining NodeTypes for tokens,
-- i.e. those that have _Literal or _LiteralPattern.

-------------------------------------------------------------------------------
-- PARSE
-------------------------------------------------------------------------------

-- Next up is NodePatterns, that define what-is-what on
-- an abstract level. These nodes don't have a literal
-- presence in the source code, but only exist on an
-- abstract level in the Abstract Syntax Tree that
-- the parser will generate by creating new Nodes
-- and inserting rows to Edges, based on the NodePatterns
-- we define.
--
-- The parser code is in PARSE/ENTER_SOURCE_CODE.sql
--
-- How the parser works is out of scope for this install-and-test
-- document, but we need to at least say something about it
-- to explain the NodePatterns concept.
--
-- The first thing the parser does is to generate a text
-- string representing the entire program as a sequence
-- of the tokens generated by the tokenizer,
-- on the format: [NodeType][NodeID] separated by spaces.
--
-- For instance, if our program would be '12 + 23 + 34',
-- we would get 'INTEGER1 PLUS2 INTEGER3 PLUS4 INTEGER5'.
--
-- Thanks to NodeID being unique, and thanks to the space
-- in between each node, we are guaranteed that whatever
-- the NodePattern regex matches, will match at exactly
-- one place, which will allow us to simply replace
-- the nodes it matched directly in the text string,
-- and then start over and see what next NodePattern
-- that matches the new sequence of nodes.
--
-- The string '\d+' is appended to the NodeType names
-- in NodePatterns, before matching. This is to make
-- the NodePatterns visually cleaner to the eye.
-- E.g., the NodePattern '(?:^| )(VALUE PLUS VALUE)'
-- will be expanded to '(?:^| )(VALUE\d+ PLUS\d+ VALUE\d+)'.
--
-- Imagine the parser starting and the program is:
-- VALUE1 PLUS2 VALUE3 PLUS4 VALUE5

-- Imagine only having a single NodePattern defined, named 'ADD':
-- (?:^| )(VALUE PLUS VALUE)

-- This NodePattern is expanded to:
-- (?:^| )(VALUE\d+ PLUS\d+ VALUE\d+)

-- This will match:
-- VALUE1 PLUS2 VALUE3

-- Thanks to NodeID being unique,
-- we can simply use replace() to replace this snippet
-- in the text string representing the full program,
-- since we know it will match only at one place.

-- The parser will create a new ADD node and replace
-- the nodes that matched the pattern with the NodeType
-- concatenated with the NodeID, which will get NodeID 6,
-- since we had five nodes before.

-- Since ADD grows into a VALUE, the resulting text will be:
-- VALUE6 PLUS4 INTEGER5

-- Next, the same NodePattern will match again,
-- and a new ADD node will be created,
-- which will be represented as another VALUE:
-- VALUE7

-- The details of how the parsing algorithm works
-- is out of scope for this document, but hopefully
-- this will be enough to understand the NodePatterns
-- in the grammar below.

-- The order in which you create NodeTypes by calling New_Node_Type()
-- that determine their precedence, unless specified explicitly via
-- the _Precedence input param.

-- Just like with LiteralPatterns, there must be exactly one capture group.
-- If you need multiple paranthesis, use (?:) to avoid capturing them.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'VALUE', _NodePattern := '(?:^| )((?#VALUE))(?: |$)');
-- This will raise our INTEGER to a VALUE, which allows
-- us to define more general NodePatterns dealing with VALUE nodes,
-- instead of having to repeat our selves and define
-- specific NodePatterns for all our NodeTypes, such as INTEGER, NUMERIC, TEXT, etc,
-- if we would have had support for more types than just INTEGER.
--
-- Normally in regex, (?#) means comment.
-- We will hijack this syntax and use it to instead mean we want to
-- expand the NodeGroup specified here.
-- E.g.: (?#VALUE) -> (INTEGER|NUMERIC|TEXT)
-- That is, if we would have support for NUMERIC and TEXT as well,
-- but since we don't (?#VALUE) is only expanded to (INTEGER).
--
-- The '(?:^| )' ensures we match either at the beginning of the
-- sequence of tokens, or right after a previous token.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SUB_EXPRESSION', _NodePattern := '(?:^|(?:^| )(?#OPS) )(LPAREN (?:VALUE|(?#OPS))(?: (?:VALUE|(?#OPS)))* RPAREN)', _GrowFrom := 'VALUE', _NodeGroup := 'VALUE');
-- This is the first time we make use of the _GrowFrom input param to New_Node_Type(),
-- so let's explain it here.
--
-- _GrowFrom means the sequence of nodes matching the NodePattern must
-- be reduced to a single node of the type specified, in this case 'VALUE'.
--
-- Only NodeTypes with a _GrowInto equal to the _GrowFrom value will be considered
-- when parsing the sequence of nodes.
--
-- This is especially useful when matching expressions, as we can easily define
-- a NodePattern for a sequence of tokens that will match all the different types
-- of tokens that can be part of a sub expression, but the tokens matched
-- must then be parsed isolated separately from the main parsing process,
-- which is achieved by using the _GrowInto and _GrowFrom params.
--
-- The regex for a sub expression always matches the inner-most paranthesis
-- not containing any sub expressions that have not already been parsed,
-- thanks to LPAREN and RPAREN being neither a VALUE nor part of the OPS node group.
-- We only want to match at the beginning or right after an operator token. i.e. part ofthe OPS node group.
--
-- The sub expression is itself also part of the NodeGroup 'VALUE',
-- meaning it will also be raised to a VALUE in the next parsing iteration
-- unless consumed by some other NodePattern with higher percedence.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'EXPRESSION', _NodePattern := '^((?:VALUE|(?#OPS))(?: (?:VALUE|(?#OPS)))*)$', _GrowFrom := 'VALUE');
-- When we reach this node type in the parser,
-- we can feel confident all sub expression have now been parsed,
-- and we're ready to parse expressions without any sub expressions.
--
-- The SUB_EXPRESSION have at this stage been transformed into VALUE nodes
-- in the text with sequence of tokens the parser is parsing.
--
-- In our test language, the entire program must be a single expression,
-- so our NodePattern starts with '^' and ends with '$' as it must
-- match the entire program.
--
-- Just like SUB_EXPRESSION, our EXPRESSION is grown from VALUEs,
-- i.e. _GrowFrom := 'VALUE'.

-- Next up is the different arithmetic operators, which all have _GrowInto := 'VALUE',
-- to tell the parser we want these to be considered when matching node patterns
-- that have _GrowFrom := 'VALUE'.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'GROUP', _GrowInto := 'VALUE', _NodePattern := '(?:^|(?#OPS) )(LPAREN VALUE RPAREN)');
-- This matches a paranthesis group and has the highest precedence, since it's the first NodeType for _GrowInto := 'VALUE'.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'UNARY_MINUS', _GrowInto := 'VALUE', _NodePattern := '(?:^|(?:^| )(?!(?:VALUE|RPAREN) )[A-Z_]+ )(MINUS VALUE)');
-- The NodePattern might look a bit complicated, so let's explain it:
-- We want (MINUS VALUE) to match, but only if NOT preceded by a VALUE or a RPAREN,
-- as that would mean it's a SUBTRACT operator instead.
-- Here we make use of the (?!) regex feature, which is Negative Look-Ahead,
-- which means we match here if the regex expression inside (?!_____) does NOT match
-- whatever comes after, which in this case is '[A-Z_]+ '.
-- Thanks to the capture group being only (MINUS VALUE), we don't consume
-- the text matched before or after, it is merely used to enfore we
-- match where we want to, also known as Context Sensitive Parsing.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'DIVIDE',   _GrowInto := 'VALUE', _Precedence := 'PRODUCT', _NodePattern := '(?:^| )(VALUE SLASH VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'MULTIPLY', _GrowInto := 'VALUE', _Precedence := 'PRODUCT', _NodePattern := '(?:^| )(VALUE ASTERISK VALUE)');
-- The NodePatterns for DIVIDE and MULTIPLY are must simpler
-- since they are Context Free meaning they should always match
-- regardless of what comes before or after.
--
-- This is the first time we make use of _Precedence, so let's explain it here:
-- Normally, all NodeTypes have a unique percedence, given by their NodeTypeID,
-- that is, the same order as they were created by calling New_Node_Type().
-- However, sometimes it is necessary that the percedence is the same
-- as some other NodeType(s), otherwise we wouldn't do DIVIDE and MULTIPLY
-- from left-to-right, but all of one or the other first, depending on
-- what order they are defined.
--
-- The first NodeType given a certain _Precedence will determine the
-- precedence for all other NodeTypes with the same _Precedence value,
-- that is, MULTIPLY will get the same precedence as DIVIDE.

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ADD',      _GrowInto := 'VALUE', _Precedence := 'SUM', _NodePattern := '(?:^| )(VALUE PLUS VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SUBTRACT', _GrowInto := 'VALUE', _Precedence := 'SUM', _NodePattern := '(?:^| )(VALUE MINUS VALUE)');
-- ADD and SUBTRACT are done after DIVIDE and MULTIPLY,
-- which is why they are defined after them,
-- but we need to give them their own precedence group, 'SUM',
-- otherwise all ADD would be computed before SUBTRACT,
-- which e.g. given '1 - 2 + 3' would cause '2 + 3' to be
-- evaluated first, but since they have the same precedence
-- '1 - 2' should be evaluated first since it's the left-most
-- expression of the same precedence.
--
-- The names used for _Precedence have no special meaning, use any name,
-- it's the order in which they are defined that determine their precedence.

SELECT New_Node_Type(
    _Language     := 'foo',
    _NodeType     := 'INVALID_EXPRESSION',
    _GrowInto     := 'VALUE',
    _NodePattern  := '^(?!VALUE$)([A-Z_]+(?: [A-Z_]+)*)$',
    _NodeSeverity := 'ERROR'::severity
);
-- If the sequence of nodes for an expression or sub expression
-- doesn't match any of the NodeTypes defined for _GrowInto := 'VALUE' so far,
-- we know we have an INVALID_EXPRESSION, which in our test language is an ERROR.
-- There is no semantic feature implemented for INVALID_EXPRESSION,
-- it is simply a node created allowing the programmer to look at the tree
-- or the highlighted source code to understand what invalid expressions
-- there are in the code. We don't want to abort the parsing
-- since there might be other invalid expressions to be found.

SELECT New_Node_Type(
    _Language     := 'foo',
    _NodeType     := 'UNPARSEABLE',
    _NodePattern  := '(?:^| )(?!EXPRESSION|UNPARSEABLE|PROGRAM)([A-Z_]+)',
    _NodeSeverity := 'ERROR'::severity
);
-- If no NodeTypes match up until here,
-- and we don't have a single EXPRESSION,
-- and we don't have a single PROGRAM,
-- then this node is UNPARSEABLE,
-- unless it's already an UNPARSEABLE node that is.
-- This is to allow continue to parse the program,
-- even if encountering something that we cannot parse.
--
-- If we don't define an UNPARSEABLE node this way,
-- the parser will still work, but will throw
-- an 'Illegal node patterns' exception if
-- the entire program could not be parsed into a PROGRAM.
--
-- UNPARSEABLE is different from INVALID_EXPRESSION,
-- since INVALID_EXPRESSION only detects invalid expressions,
-- whereas UNPARSEABLE detects unparsable nodes in the main parsing
-- of the program.

SELECT New_Node_Type(
    _Language    := 'foo',
    _NodeType    := 'PROGRAM',
    _NodePattern := '^((?:UNPARSEABLE)?(?: UNPARSEABLE)*EXPRESSION(?: UNPARSEABLE)*)$',
    _Prologue    := 'ALLOCA',
    _Epilogue    := 'RET'
);
-- Finally we arrive at the NodeType defining what a PROGRAM is.
-- Since we might want to allow further compilation phases
-- even if we encountered something UNPARSEABLE,
-- we allow any number of UNPARSEABLE nodes
-- but exactly one EXPRESSION
-- followed by any number of UNPARSEABLE nodes.

\ir soft/TABLES/programs.sql
\ir soft/FUNCTIONS/new_program.sql
SELECT New_Program(
    _Language := 'foo',
    _Program  := '30+70'
);
-- A program has a name that is unique per language,
-- that is, multiple programs with one and the same name
-- can be implemented in different languages.
--
-- In this document, we will create two programs.
-- The first one '30+70' is only to demonstrate
-- how to directly create Nodes and Edges,
-- but won't result in a runnable program.
--
-- The second program will be defined futher down,
-- and uses New_Test()/Run_Test() to also run the program.

-------------------------------------------------------------------------------
-- ABSTRACT SYNTAX TREE DATA MODEL
-------------------------------------------------------------------------------

\ir soft/TABLES/nodes.sql
\ir soft/FUNCTIONS/new_node.sql
-- Nodes are of different NodeTypes and can be either
-- Literal nodes created by the tokenizer with PrimitiveValues
-- originating from the source code, or they can be abstract
-- nodes created by the parser, where the PrimitiveValues
-- are computed when evalutating the node,
-- or they never have any values at all,
-- depending on the NodeType.

ALTER TABLE Programs ADD FOREIGN KEY (NodeID) REFERENCES Nodes(NodeID);
-- Each program has a current NodeID where we're currently at.
-- This is aka as the "program counter" or "PC".

SELECT New_Node(
    _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = '30+70'),
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'INTEGER'),
    _PrimitiveType  := 'integer'::regtype,
    _PrimitiveValue := '30'
);

SELECT New_Node(
    _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = '30+70'),
    _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'INTEGER'),
    _PrimitiveType  := 'integer'::regtype,
    _PrimitiveValue := '70'
);

SELECT New_Node(
    _ProgramID  := (SELECT ProgramID  FROM Programs  WHERE Program  = '30+70'),
    _NodeTypeID := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'ADD')
);
-- The ADD node doesn't have any PrimitiveType/PrimitiveValue from the beginning
-- but are later infered and calculated from its arguments.

-- Since these are the first three nodes, we know they will get NodeID 1, 2 and 3.

\ir soft/TABLES/edges.sql
\ir soft/FUNCTIONS/new_edge.sql

SELECT New_Edge(
    _ParentNodeID := 1, -- INTEGER1=30
    _ChildNodeID  := 3  -- ADD1
);

SELECT New_Edge(
    _ParentNodeID := 2, -- INTEGER2=70
    _ChildNodeID  := 3  -- ADD1
);

-- This connects the two INTEGER nodes to the ADD node.
-- The order here is important, since it determines
-- what is the 1st argument to ADD,
-- and what is the 2nd argument to ADD.
-- The argument order is the same as the order the Edges are created,
-- i.e. the order in which New_Edge() is called, i.e. ORDER BY EdgeID.

-- This results in a tree looking like this:
-- 30         70
--  \-> ADD <-/

-------------------------------------------------------------------------------
-- LOGGING AND DEBUGGING
-------------------------------------------------------------------------------

\ir soft/TABLES/ansiescapecodes.sql
-- This installs a helper-table with the ANSI escape codes
-- for various colors, to make the output from the compiler
-- a bit more colorful, e.g. fragments in a text can be highlighted
-- in a different color to make it stand out what part of the
-- source code we are refering to.

\ir soft/TABLES/log.sql
-- The Log table is written to by the Log() function.
-- From the input NodeID, which is at what node
-- the log message happened, we derive the program,
-- and the current phase, which is stored to Log,
-- together with the log message, the log severity
-- and the current time.
--
-- This allows us to carefully follow the different compilation
-- phases and the program execution during eval
-- at the desired log severity level.

\ir soft/FUNCTIONS/notice.sql
-- This function simply does a RAISE NOTICE of the input text.
-- This is needed since we cannot do RAISE NOTICE directly in psql.
SELECT Notice('Hello world!');

\ir soft/FUNCTIONS/colorize.sql
-- Let's us colorize the input text.
SELECT Notice(Colorize(_Text := 'Hello green world!', _Color := 'GREEN'));

\ir soft/FUNCTIONS/log.sql
-- Logging of compiler messages,
-- always passing the current NodeID
-- to know at what node the log event happened.
SELECT Log(
    _NodeID   := 1,
    _Severity := 'NOTICE',
    _Message  := 'Hello world! This is a log message!'
);

\ir soft/FUNCTIONS/highlight_characters.sql
-- Let's us colorize specific characters in the input text.
SELECT Notice(Highlight_Characters(
    _Text       := 'Hello red world!',
    _Characters := ARRAY[7,8,9],
    _Color      := 'RED'
));

\ir soft/FUNCTIONS/get_parent_nodes.sql
-- Recursively gets all parent nodes for a node.
-- Remember the ADD node we created before with NodeID3?
-- This should return its two parent nodes, 1 and 2, together with itself, 3:
SELECT Get_Parent_Nodes(3);

\ir soft/FUNCTIONS/get_source_code_fragment.sql


\ir soft/TABLES/tests.sql



-- Each program has a name that is unique per language:

-- Helper-function to handle ANSI colors
-- and highlight code fragments:

\ir soft/FUNCTIONS/get_env.sql
\ir soft/FUNCTIONS/one_line.sql

-- Returns text description of things:
\ir soft/FUNCTIONS/language.sql
\ir soft/FUNCTIONS/phase.sql
\ir soft/FUNCTIONS/node_type.sql
\ir soft/FUNCTIONS/node.sql

\ir soft/VIEWS/view_nodes.sql

SELECT * FROM View_Nodes;

\ir soft/FUNCTIONS/new_test.sql

-- New_Test() will create a SOURCE_CODE node with the _SourceCode
-- and store the other input params in Tests,
-- but it won't actually run the test. To do so, we will call
-- Run_Test() later when we're ready:

SELECT New_Test(
    _Language      := 'foo',
    _Program       := 'bar',
    _SourceCode    := '1 + 2 - - 3 * 4 - 15 / (2 + 1)',
    _ExpectedType  := 'integer',
    _ExpectedValue := '10'
);



-- To reference some other node from a node,
-- use Set_Reference_Node(_ReferenceNodeID integer, _NodeID integer),
-- which will set Nodes.ReferenceNodeID to _ReferenceNodeID
-- for the input _NodeID.
--
-- This means that when someone wants to use _NodeID's value,
-- they will get the value of _ReferenceNodeID instead,
-- or its parent tree, if it's a multi-node tree object
-- such as a FUNCTION_DECLARATION:

\ir soft/FUNCTIONS/set_reference_node.sql

-- To get the referenced node, use Dereference(_NodeID integer)
-- which will recursively Dereference(ReferenceNodeID)
-- until we get the final NodeID where Nodes.ReferenceNodeID IS NULL:

\ir soft/FUNCTIONS/dereference.sql

-- Nodes can be cloned which recursively copies
-- the node and its parents, if any.

\ir soft/FUNCTIONS/clone_node.sql

SELECT Clone_Node((SELECT NodeID FROM Nodes ORDER BY NodeID LIMIT 1));


-- Some nodes only exist in the early compilation phases
-- and are killed when giving birth to abstract nodes
-- that only need the nodes containing primitive values
-- that can be computed.
-- For instance, the program '1 + 2' consist of three
-- nodes 'INTEGER PLUS INTEGER' after TOKENIZE,
-- but during PARSE, 'PLUS' will die, and
-- a new 'ADD' node will be born, with Edges pointing
-- to the two 'INTEGER' nodes.
--
-- To keep track of exactly when Nodes and Edges have been
-- killed, we don't actually DELETE them, but instead
-- set their DeathPhaseID and DeathTime columns,
-- which tells during what phase they were killed
-- and at what clock_timestamp().

\ir soft/FUNCTIONS/kill_edge.sql
\ir soft/FUNCTIONS/kill_node.sql

-- Kill_Clone() kills all the Nodes and Edges
-- for a cloned copy of a node, which could
-- be just a single node, or a sub-tree.

\ir soft/FUNCTIONS/kill_clone.sql

-- Copy value from one node to some other node:
\ir soft/FUNCTIONS/copy_node.sql

-- Returns PrimitiveType/PrimitiveValue for node:
\ir soft/FUNCTIONS/primitive_type.sql
\ir soft/FUNCTIONS/primitive_value.sql

-- Test copy value from first node (integer 30) to second (integer 70):
SELECT Copy_Node(
    _FromNodeID := (SELECT NodeID FROM Nodes ORDER BY NodeID LIMIT 1 OFFSET 1),
    _ToNodeID   := (SELECT NodeID FROM Nodes ORDER BY NodeID LIMIT 1 OFFSET 2)
);

-- Kill the clone we created earlier:
SELECT Kill_Clone(NodeID) FROM Nodes WHERE ClonedFromNodeID IS NOT NULL AND ClonedRootNodeID IS NULL;

SELECT * FROM View_Nodes;

-- Parser helper-functions:
\ir soft/FUNCTIONS/expand_token_groups.sql
\ir soft/FUNCTIONS/get_capturing_group.sql
\ir soft/FUNCTIONS/precedence.sql

-- Graphviz DOT generation:
\ir soft/FUNCTIONS/get_dot.sql
\ir soft/FUNCTIONS/get_node_attributes.sql
\ir soft/FUNCTIONS/get_node_color.sql

-- Tree searching:
\ir soft/FUNCTIONS/find_node.sql

-- Eval helper-functions:
\ir soft/FUNCTIONS/determine_return_type.sql
\ir soft/FUNCTIONS/set_node_value.sql
\ir soft/FUNCTIONS/matching_input_types.sql

-- Tree walking:
\ir soft/FUNCTIONS/walk_tree.sql
\ir soft/FUNCTIONS/enter_node.sql
\ir soft/FUNCTIONS/eval_node.sql
\ir soft/FUNCTIONS/leave_node.sql
\ir soft/FUNCTIONS/next_node.sql
\ir soft/FUNCTIONS/get_program_node.sql
\ir soft/FUNCTIONS/run.sql
\ir soft/FUNCTIONS/set_program_node.sql
\ir soft/FUNCTIONS/descend.sql
\ir soft/FUNCTIONS/set_walkable.sql

-- Tree modifying:
\ir soft/FUNCTIONS/set_edge_parent.sql

-- Run test:
\ir soft/FUNCTIONS/run_test.sql

-- Validation functions:
\ir soft/FUNCTIONS/valid_node_pattern.sql

\ir soft/VIEWS/export_node_types.sql

-- SEMANTIC SUPPORT:
--
-- All directories and functions from here on have names in ALL CAPS
-- to visually distinguish them from the core functionality above. 
--
-- Each phase has its own database schema and its own directory.
--
-- The files are given the same name as the NodeTypes.NodeType
-- they represent, prefixed with "ENTER_", "LEAVE_" or no prefix,
-- to control if the function should be called when you ENTER
-- or LEAVE the node.
--
-- Functions without the ENTER/LEAVE prefix are called when the
-- node is evaluated.
--
-- Functions are called in this order:
-- [Phase]/ENTER_[NodeType].sql
-- [Phase]/[NodeType].sql
-- [Phase]/LEAVE_[NodeType].sql
--
-- Each Walkable node is visited exactly two times,
-- once when entering the node, and once when leaving the node,
-- i.e. when descending.

-- The TOKENIZE phase creates new token Nodes by matching the
-- SOURCE_CODE node's PrimitiveValue text, i.e. the source code,
-- against all literal NodeTypes Literal or LiteralPattern.

\ir TOKENIZE/ENTER_SOURCE_CODE.sql

-- The DISCARD phase eliminates white space nodes.
-- If white space matters in a language,
-- this phase is simply skipped.

\ir DISCARD/ENTER_WHITE_SPACE.sql

-- The PARSE phase creates new an Abstract-Syntax Tree
-- which means creating new abstract Nodes
-- and new Edges to connect them to the graph.
--
-- This is done by matching the sequence of tokens against
-- the NodePatterns defined in NodeTypes,
-- in Precedence order, and if two NodeTypes
-- of the same Precedence match, then the
-- left most match is selected.

\ir PARSE/ENTER_SOURCE_CODE.sql

-- The REDUCE phase shrinks the AST by eliminating
-- unnecessary middle-men nodes that have exactly
-- one parent and one child.

\ir REDUCE/ENTER_PROGRAM.sql

-- The MAP_VARIABLES phase looks up what
-- VARIABLE an IDENTIFIER refers to,
-- and connects it by killing the IDENTIFIER
-- node and replacing it with a new Edge
-- to the VARIABLE.

\ir MAP_VARIABLES/ENTER_ALLOCA.sql
\ir MAP_VARIABLES/ENTER_BOOLEAN.sql
\ir MAP_VARIABLES/ENTER_IDENTIFIER.sql
\ir MAP_VARIABLES/ENTER_INTEGER.sql
\ir MAP_VARIABLES/ENTER_TEXT.sql
\ir MAP_VARIABLES/LEAVE_FUNCTION_DECLARATION.sql
\ir MAP_VARIABLES/LEAVE_IF_EXPRESSION.sql
\ir MAP_VARIABLES/LEAVE_IF_STATEMENT.sql
\ir MAP_VARIABLES/LEAVE_LET_STATEMENT.sql
\ir MAP_VARIABLES/LEAVE_ARGUMENTS.sql

-- The EVAL phase computes the values
-- for nodes when they are visited.

\ir EVAL/ADD.sql
\ir EVAL/DIVIDE.sql
\ir EVAL/ENTER_RET.sql
\ir EVAL/ENTER_ARGUMENTS.sql
\ir EVAL/EQUAL.sql
\ir EVAL/GREATER_THAN.sql
\ir EVAL/LEAVE_ARRAY.sql
\ir EVAL/LEAVE_BLOCK_EXPRESSION.sql
\ir EVAL/LEAVE_BLOCK_STATEMENT.sql
\ir EVAL/LEAVE_CALL.sql
\ir EVAL/LEAVE_HASH.sql
\ir EVAL/LEAVE_IF_EXPRESSION.sql
\ir EVAL/LEAVE_IF_STATEMENT.sql
\ir EVAL/LEAVE_INDEX.sql
\ir EVAL/LEAVE_LET_STATEMENT.sql
\ir EVAL/LEAVE_PROGRAM.sql
\ir EVAL/LEAVE_RETURN_STATEMENT.sql
\ir EVAL/LEAVE_STATEMENTS.sql
\ir EVAL/LESS_THAN.sql
\ir EVAL/MULTIPLY.sql
\ir EVAL/NOT.sql
\ir EVAL/NOT_EQUAL.sql
\ir EVAL/SUBTRACT.sql
\ir EVAL/UNARY_MINUS.sql

-- The BUILT_IN_FUNCTIONS phase contains
-- functionality that is built-in to languages.

\ir BUILT_IN_FUNCTIONS/FIRST.sql
\ir BUILT_IN_FUNCTIONS/LAST.sql
\ir BUILT_IN_FUNCTIONS/LENGTH.sql
\ir BUILT_IN_FUNCTIONS/PUSH.sql
\ir BUILT_IN_FUNCTIONS/PUTS.sql
\ir BUILT_IN_FUNCTIONS/REST.sql

SELECT Run_Test('foo','bar','DEBUG5');
