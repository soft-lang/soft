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
\ir soft/FUNCTIONS/new_phase.sql
\ir soft/FUNCTIONS/new_node_type.sql
\ir soft/FUNCTIONS/new_program.sql
\ir soft/FUNCTIONS/new_node.sql
\ir soft/FUNCTIONS/new_edge.sql
\ir soft/FUNCTIONS/new_test.sql
\ir soft/FUNCTIONS/new_built_in_function.sql

-- Logging and helper-functions for the same:
\ir soft/FUNCTIONS/notice.sql
\ir soft/FUNCTIONS/log.sql
\ir soft/FUNCTIONS/colorize.sql
\ir soft/FUNCTIONS/highlight_characters.sql
\ir soft/FUNCTIONS/get_parent_nodes.sql
\ir soft/FUNCTIONS/get_source_code_fragment.sql
\ir soft/FUNCTIONS/one_line.sql

-- Returns text description of things:
\ir soft/FUNCTIONS/language.sql
\ir soft/FUNCTIONS/phase.sql
\ir soft/FUNCTIONS/node_type.sql
\ir soft/FUNCTIONS/node.sql

-- Killing of things:
\ir soft/FUNCTIONS/kill_clone.sql
\ir soft/FUNCTIONS/kill_edge.sql
\ir soft/FUNCTIONS/kill_node.sql

-- Copying, cloning and dereferencing of nodes:
\ir soft/FUNCTIONS/clone_node.sql
\ir soft/FUNCTIONS/copy_node.sql
\ir soft/FUNCTIONS/dereference.sql
\ir soft/FUNCTIONS/set_reference_node.sql

-- Returns PrimitiveType/PrimitiveValue for node:
\ir soft/FUNCTIONS/primitive_type.sql
\ir soft/FUNCTIONS/primitive_value.sql

-- Parser helper-functions:
\ir soft/FUNCTIONS/expand_token_groups.sql
\ir soft/FUNCTIONS/get_capturing_group.sql
\ir soft/FUNCTIONS/precedence.sql

-- Graphviz DOT generation:
\ir soft/FUNCTIONS/get_dot.sql
\ir soft/FUNCTIONS/get_node_attributes.sql
\ir soft/FUNCTIONS/get_node_color.sql
\ir soft/FUNCTIONS/get_node_lexical_environment.sql

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
\ir soft/VIEWS/view_nodes.sql

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

CREATE SCHEMA "TOKENIZE";
\ir TOKENIZE/ENTER_SOURCE_CODE.sql

-- The DISCARD phase eliminates white space nodes.
-- If white space matters in a language,
-- this phase is simply skipped.

CREATE SCHEMA "DISCARD";
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

CREATE SCHEMA "PARSE";
\ir PARSE/ENTER_SOURCE_CODE.sql

-- The REDUCE phase shrinks the AST by eliminating
-- unnecessary middle-men nodes that have exactly
-- one parent and one child.

CREATE SCHEMA "REDUCE";
\ir REDUCE/ENTER_PROGRAM.sql

-- The MAP_VARIABLES phase looks up what
-- VARIABLE an IDENTIFIER refers to,
-- and connects it by killing the IDENTIFIER
-- node and replacing it with a new Edge
-- to the VARIABLE.

CREATE SCHEMA "MAP_VARIABLES";
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

CREATE SCHEMA "EVAL";
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

CREATE SCHEMA "BUILT_IN_FUNCTIONS";
\ir BUILT_IN_FUNCTIONS/FIRST.sql
\ir BUILT_IN_FUNCTIONS/LAST.sql
\ir BUILT_IN_FUNCTIONS/LENGTH.sql
\ir BUILT_IN_FUNCTIONS/PUSH.sql
\ir BUILT_IN_FUNCTIONS/PUTS.sql
\ir BUILT_IN_FUNCTIONS/REST.sql
