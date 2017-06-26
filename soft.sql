CREATE SCHEMA soft;
SET search_path TO soft, public;
\ir soft/TYPES/severity.sql
\ir soft/TYPES/variablebinding.sql
\ir soft/TYPES/direction.sql

\ir soft/TABLES/languages.sql
\ir soft/TABLES/phases.sql
\ir soft/TABLES/nodetypes.sql
\ir soft/TABLES/programs.sql
\ir soft/TABLES/nodes.sql
\ir soft/TABLES/edges.sql
\ir soft/TABLES/log.sql
\ir soft/TABLES/ansiescapecodes.sql
\ir soft/TABLES/tests.sql
\ir soft/TABLES/builtinfunctions.sql

ALTER TABLE Programs ADD FOREIGN KEY (NodeID) REFERENCES Nodes(NodeID);

\ir soft/FUNCTIONS/new_language.sql
\ir soft/FUNCTIONS/new_phase.sql
\ir soft/FUNCTIONS/new_node_type.sql
\ir soft/FUNCTIONS/new_program.sql
\ir soft/FUNCTIONS/new_test.sql
\ir soft/FUNCTIONS/new_node.sql
\ir soft/FUNCTIONS/new_edge.sql
\ir soft/FUNCTIONS/kill_node.sql
\ir soft/FUNCTIONS/kill_edge.sql
\ir soft/FUNCTIONS/kill_clone.sql
\ir soft/FUNCTIONS/expand_token_groups.sql
\ir soft/FUNCTIONS/get_capturing_group.sql
\ir soft/FUNCTIONS/get_dot.sql
\ir soft/FUNCTIONS/log.sql
\ir soft/FUNCTIONS/colorize.sql
\ir soft/FUNCTIONS/highlight_characters.sql
\ir soft/FUNCTIONS/get_source_code_fragment.sql
\ir soft/FUNCTIONS/get_parent_nodes.sql
\ir soft/FUNCTIONS/one_line.sql
\ir soft/FUNCTIONS/set_edge_parent.sql
\ir soft/FUNCTIONS/set_edge_child.sql
\ir soft/FUNCTIONS/node.sql
\ir soft/FUNCTIONS/phase.sql
\ir soft/FUNCTIONS/set_node_type.sql
\ir soft/FUNCTIONS/get_program_node.sql
\ir soft/FUNCTIONS/walk_tree.sql
\ir soft/FUNCTIONS/enter_node.sql
\ir soft/FUNCTIONS/leave_node.sql
\ir soft/FUNCTIONS/run.sql
\ir soft/FUNCTIONS/find_node.sql
\ir soft/FUNCTIONS/copy_node.sql
\ir soft/FUNCTIONS/clone_node.sql
\ir soft/FUNCTIONS/determine_return_type.sql
\ir soft/FUNCTIONS/set_node_value.sql
\ir soft/FUNCTIONS/eval_node.sql
\ir soft/FUNCTIONS/set_program_node.sql
\ir soft/FUNCTIONS/set_walkable.sql
\ir soft/FUNCTIONS/goto_child.sql
\ir soft/FUNCTIONS/goto_parent.sql
\ir soft/FUNCTIONS/quote.sql
\ir soft/FUNCTIONS/export_node_types.sql
\ir soft/FUNCTIONS/next_node.sql
\ir soft/FUNCTIONS/dereference.sql
\ir soft/FUNCTIONS/primitive_type.sql
\ir soft/FUNCTIONS/primitive_value.sql
\ir soft/FUNCTIONS/set_reference_node.sql
\ir soft/FUNCTIONS/language.sql
\ir soft/FUNCTIONS/programid.sql
\ir soft/FUNCTIONS/new_built_in_function.sql
\ir soft/FUNCTIONS/notice.sql

CREATE SCHEMA "DISCARD";
\ir DISCARD/ENTER_WHITE_SPACE.sql

CREATE SCHEMA "TOKENIZE";
\ir TOKENIZE/ENTER_SOURCE_CODE.sql

CREATE SCHEMA "PARSE";
\ir PARSE/ENTER_SOURCE_CODE.sql

CREATE SCHEMA "REDUCE";
\ir REDUCE/ENTER_PROGRAM.sql

CREATE SCHEMA "MAP_VARIABLES";
\ir MAP_VARIABLES/ENTER_ALLOCA.sql
\ir MAP_VARIABLES/ENTER_TEXT.sql
\ir MAP_VARIABLES/ENTER_INTEGER.sql
\ir MAP_VARIABLES/ENTER_BOOLEAN.sql
\ir MAP_VARIABLES/ENTER_IDENTIFIER.sql
\ir MAP_VARIABLES/LEAVE_LET_STATEMENT.sql
\ir MAP_VARIABLES/LEAVE_STORE_ARGS.sql
\ir MAP_VARIABLES/LEAVE_FUNCTION_DECLARATION.sql
\ir MAP_VARIABLES/LEAVE_IF_STATEMENT.sql
\ir MAP_VARIABLES/LEAVE_IF_EXPRESSION.sql

CREATE SCHEMA "EVAL";
\ir EVAL/ENTER_STORE_ARGS.sql
\ir EVAL/ENTER_RET.sql
\ir EVAL/ENTER_PROGRAM.sql
\ir EVAL/ADD.sql
\ir EVAL/DIVIDE.sql
\ir EVAL/EQUAL.sql
\ir EVAL/GREATER_THAN.sql
\ir EVAL/LESS_THAN.sql
\ir EVAL/MULTIPLY.sql
\ir EVAL/NOT_EQUAL.sql
\ir EVAL/NOT.sql
\ir EVAL/SUBTRACT.sql
\ir EVAL/UNARY_MINUS.sql
\ir EVAL/IF_EXPR.sql
\ir EVAL/LEAVE_INDEX.sql
\ir EVAL/LEAVE_CALL.sql
\ir EVAL/LEAVE_PROGRAM.sql
\ir EVAL/LEAVE_BLOCK_EXPRESSION.sql
\ir EVAL/LEAVE_BLOCK_STATEMENT.sql
\ir EVAL/LEAVE_ARRAY.sql
\ir EVAL/LEAVE_LET_STATEMENT.sql
\ir EVAL/LEAVE_IF_STATEMENT.sql
\ir EVAL/LEAVE_IF_EXPRESSION.sql
\ir EVAL/LEAVE_ASSIGNMENT_STATEMENT.sql
\ir EVAL/LEAVE_RETURN_STATEMENT.sql
\ir EVAL/LEAVE_STATEMENTS.sql
\ir EVAL/LEAVE_LOOP_EXPRESSION.sql
\ir EVAL/LEAVE_HASH.sql

CREATE SCHEMA "BUILT_IN_FUNCTIONS";
\ir BUILT_IN_FUNCTIONS/REST.sql
\ir BUILT_IN_FUNCTIONS/FIRST.sql
\ir BUILT_IN_FUNCTIONS/LAST.sql
\ir BUILT_IN_FUNCTIONS/LENGTH.sql
\ir BUILT_IN_FUNCTIONS/PUSH.sql
