ROLLBACK;
\set AUTOCOMMIT ON

CREATE TYPE public.batchjobstate AS ENUM (
    'AGAIN',
    'DONE'
);

DROP SCHEMA soft CASCADE;
DROP SCHEMA "TOKENIZE" CASCADE;
DROP SCHEMA "DISCARD" CASCADE;
DROP SCHEMA "PARSE" CASCADE;
DROP SCHEMA "REDUCE" CASCADE;
DROP SCHEMA "MAP_VARIABLES" CASCADE;
DROP SCHEMA "EVAL" CASCADE;
DROP SCHEMA "BUILT_IN_FUNCTIONS" CASCADE;

CREATE SCHEMA soft;

SET search_path TO soft, public;

\ir soft/TYPES/severity.sql
\ir soft/TYPES/variablebinding.sql
\ir soft/TYPES/direction.sql
\ir soft/TYPES/nil.sql

\ir soft/TABLES/languages.sql
\ir soft/TABLES/phases.sql
\ir soft/TABLES/nodetypes.sql
\ir soft/TABLES/programs.sql
\ir soft/TABLES/nodes.sql
\ir soft/TABLES/edges.sql
\ir soft/TABLES/ansiescapecodes.sql
\ir soft/TABLES/tests.sql
\ir soft/TABLES/builtinfunctions.sql
\ir soft/TABLES/log.sql

ALTER TABLE Programs ADD FOREIGN KEY (NodeID) REFERENCES Nodes(NodeID);

-- Creation of things:
\ir soft/FUNCTIONS/new_language.sql

-- We will create a simple language named "foo"
-- capable of calculating a single arithmetic expression
-- with support for the operators + - / * ( )

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

\ir soft/FUNCTIONS/new_phase.sql

-- Languages have different compiler phases
-- that are usually quite similar between
-- different languages.

-- Each phase gets its own schema in ALL CAPS:

CREATE SCHEMA "TOKENIZE";
CREATE SCHEMA "DISCARD";
CREATE SCHEMA "PARSE";
CREATE SCHEMA "REDUCE";
CREATE SCHEMA "MAP_VARIABLES";
CREATE SCHEMA "EVAL";

-- The order of New_Phase() calls determines in which order
-- the phases are executed:

SELECT New_Phase(_Language := 'foo', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'foo', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'foo', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'foo', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'foo', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'foo', _Phase := 'EVAL');

\ir soft/FUNCTIONS/new_node_type.sql

-- All the things in the source code are represented as Nodes
-- of different NodeTypes connected via Edges to form
-- an Abstract Syntax Tree (AST).

-- In our simple test language, the following is the bare minimum:

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SOURCE_CODE');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ALLOCA', _PrimitiveType := 'void'::regtype);
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'RET',    _PrimitiveType := 'void'::regtype);

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'PLUS',        _Literal := '+', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'MINUS',       _Literal := '-', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ASTERISK',    _Literal := '*', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SLASH',       _Literal := '/', _NodeGroup := 'OPS');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'LPAREN',      _Literal := '(');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'RPAREN',      _Literal := ')');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'WHITE_SPACE', _LiteralPattern := '(\s+)');

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'INTEGER', _PrimitiveType := 'integer'::regtype, _NodeGroup := 'VALUE', _LiteralPattern := '([0-9]+)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ILLEGAL', _LiteralPattern := '(.)', _NodeSeverity := 'ERROR'::severity);

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'VALUE', _NodePattern := '(?:^| )((?#VALUE))(?: |$)');

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SUB_EXPRESSION', _NodePattern := '(?:^|(?:^| )(?#OPS) )(LPAREN (?:VALUE|(?#OPS))(?: (?:VALUE|(?#OPS)))* RPAREN)', _GrowFrom := 'VALUE', _NodeGroup := 'VALUE');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'EXPRESSION',     _NodePattern := '(?:^| )((?:VALUE|(?#OPS))(?: (?:VALUE|(?#OPS)))*)$',       _GrowFrom := 'VALUE');

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'GROUP',              _GrowInto := 'VALUE',                           _NodePattern := '(?:^|(?#OPS) )(LPAREN VALUE RPAREN)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'UNARY_MINUS',        _GrowInto := 'VALUE',                           _NodePattern := '(?:^|(?:^| )(?!(?:VALUE|RPAREN) )[A-Z_]+ )(MINUS VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'DIVIDE',             _GrowInto := 'VALUE', _Precedence := 'PRODUCT', _NodePattern := '(?:^| )(VALUE SLASH VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'MULTIPLY',           _GrowInto := 'VALUE', _Precedence := 'PRODUCT', _NodePattern := '(?:^| )(VALUE ASTERISK VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'ADD',                _GrowInto := 'VALUE', _Precedence := 'SUM',     _NodePattern := '(?:^| )(VALUE PLUS VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'SUBTRACT',           _GrowInto := 'VALUE', _Precedence := 'SUM',     _NodePattern := '(?:^| )(VALUE MINUS VALUE)');
SELECT New_Node_Type(_Language := 'foo', _NodeType := 'INVALID_EXPRESSION', _GrowInto := 'VALUE',                           _NodePattern := '^(?!VALUE$)([A-Z_]+(?: [A-Z_]+)*)$', _NodeSeverity := 'ERROR'::severity);

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'UNPARSEABLE', _NodePattern := '(?:^| )(?!EXPRESSION|UNPARSEABLE|PROGRAM)([A-Z_]+)', _NodeSeverity := 'ERROR'::severity);

SELECT New_Node_Type(_Language := 'foo', _NodeType := 'PROGRAM', _NodePattern := '(?:^| )((?:EXPRESSION|UNPARSEABLE)(?: (?:EXPRESSION|UNPARSEABLE))*)', _Prologue := 'ALLOCA', _Epilogue := 'RET');

\ir soft/FUNCTIONS/new_program.sql

-- Each program has a name that is unique per language:

SELECT New_Program(
    _Language := 'foo',
    _Program  := '30+70'
);

\ir soft/FUNCTIONS/new_node.sql
\ir soft/FUNCTIONS/new_edge.sql

-- Let's create a tree looking like this:
-- INTEGER1=30 -> ADD1
-- INTEGER2=70 -> ADD1
-- (3 Nodes and 2 Edges)

WITH ADD AS (
    SELECT New_Node(
        _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = '30+70'),
        _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'ADD')
    ) AS NodeID
)
SELECT
    New_Edge(
        _ParentNodeID := New_Node(
            _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = '30+70'),
            _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'INTEGER'),
            _PrimitiveType  := 'integer'::regtype,
            _PrimitiveValue := '30'
        ),
        _ChildNodeID := Add.NodeID
    ) AS FirstArgument,
    New_Edge(
        _ParentNodeID := New_Node(
            _ProgramID      := (SELECT ProgramID  FROM Programs  WHERE Program  = '30+70'),
            _NodeTypeID     := (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'INTEGER'),
            _PrimitiveType  := 'integer'::regtype,
            _PrimitiveValue := '70'
        ),
        _ChildNodeID := Add.NodeID
    ) AS SecondArgument
FROM ADD;

-- Helper-function to handle ANSI colors
-- and highlight code fragments:

\ir soft/FUNCTIONS/colorize.sql
\ir soft/FUNCTIONS/notice.sql
\ir soft/FUNCTIONS/highlight_characters.sql
\ir soft/FUNCTIONS/get_parent_nodes.sql
\ir soft/FUNCTIONS/get_env.sql
\ir soft/FUNCTIONS/get_source_code_fragment.sql
\ir soft/FUNCTIONS/one_line.sql
\ir soft/FUNCTIONS/log.sql

SELECT Notice(Colorize(_Text := 'Hello world!', _Color := 'GREEN'));

SELECT Notice(Highlight_Characters(
    _Text       := 'Hello world!',
    _Characters := ARRAY[7,8,9,10,11],
    _Color      := 'RED'
));

-- Logging of compiler messages,
-- always passing the current NodeID
-- to know at what node the log event happened.
SELECT Log(
    _NodeID   := (SELECT NodeID FROM Nodes ORDER BY NodeID LIMIT 1),
    _Severity := 'NOTICE',
    _Message  := 'Hello again world!'
);

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

-- Our simple test language doesn't have any built-in functions,
-- but let's say it would have a function called "puts"
-- implemented as in the function "BUILT_IN_FUNCTIONS"."PUTS",
-- we would then do:

\ir soft/FUNCTIONS/new_built_in_function.sql

CREATE SCHEMA "BUILT_IN_FUNCTIONS";
\ir BUILT_IN_FUNCTIONS/PUTS.sql
SELECT New_Built_In_Function(
    _Language               := 'foo',
    _Identifier             := 'puts',
    _ImplementationFunction := 'PUTS'
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
