CREATE SCHEMA soft;
SET search_path TO soft, public;
\ir soft/TYPES/severity.sql

\ir soft/TABLES/languages.sql
\ir soft/TABLES/phases.sql
\ir soft/TABLES/nodetypes.sql
\ir soft/TABLES/programs.sql
\ir soft/TABLES/nodes.sql
\ir soft/TABLES/edges.sql
\ir soft/TABLES/log.sql
\ir soft/TABLES/ansiescapecodes.sql

ALTER TABLE Programs ADD FOREIGN KEY (NodeID) REFERENCES Nodes(NodeID);

\ir soft/FUNCTIONS/new_language.sql
\ir soft/FUNCTIONS/new_phase.sql
\ir soft/FUNCTIONS/new_node_type.sql
\ir soft/FUNCTIONS/new_program.sql
\ir soft/FUNCTIONS/new_node.sql
\ir soft/FUNCTIONS/new_edge.sql
\ir soft/FUNCTIONS/kill_node.sql
\ir soft/FUNCTIONS/kill_edge.sql
\ir soft/FUNCTIONS/expand_token_groups.sql
\ir soft/FUNCTIONS/get_capturing_group.sql
\ir soft/FUNCTIONS/get_dot.sql
\ir soft/FUNCTIONS/log.sql
\ir soft/FUNCTIONS/colorize.sql
\ir soft/FUNCTIONS/highlight_characters.sql
\ir soft/FUNCTIONS/get_source_code_node.sql
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
\ir soft/FUNCTIONS/push_node.sql
\ir soft/FUNCTIONS/pop_node.sql
\ir soft/FUNCTIONS/determine_return_type.sql
\ir soft/FUNCTIONS/set_node_value.sql
\ir soft/FUNCTIONS/eval_node.sql

CREATE SCHEMA "DISCARD";
\ir DISCARD/ENTER_WHITE_SPACE.sql

CREATE SCHEMA "TOKENIZE";
\ir TOKENIZE/ENTER_SOURCE_CODE.sql

CREATE SCHEMA "PARSE";
\ir PARSE/ENTER_SOURCE_CODE.sql

CREATE SCHEMA "REDUCE";
\ir REDUCE/ENTER_PROGRAM.sql

CREATE SCHEMA "MAP_VARIABLES";
\ir MAP_VARIABLES/LEAVE_LET_STATEMENT.sql
\ir MAP_VARIABLES/LEAVE_STORE_ARGS.sql
\ir MAP_VARIABLES/ENTER_IDENTIFIER.sql

CREATE SCHEMA "MAP_FUNCTIONS";
\ir MAP_FUNCTIONS/ENTER_IDENTIFIER.sql
\ir MAP_FUNCTIONS/LEAVE_FUNCTION_DECLARATION.sql

CREATE SCHEMA "MAP_ALLOCA";
\ir MAP_ALLOCA/ENTER_VARIABLE.sql

CREATE SCHEMA "BLOCK_PATHS";
\ir BLOCK_PATHS/LEAVE_FUNCTION_LABEL.sql

CREATE SCHEMA "EVAL";
\ir EVAL/ENTER_ALLOCA.sql
\ir EVAL/ENTER_CALL.sql
\ir EVAL/ENTER_STORE_ARGS.sql
\ir EVAL/ADD.sql
\ir EVAL/DIVIDE.sql
\ir EVAL/EQUAL.sql
\ir EVAL/GREATER_THAN.sql
\ir EVAL/LESS_THAN.sql
\ir EVAL/MULTIPLY.sql
\ir EVAL/NOT_EQUAL.sql
\ir EVAL/SUBTRACT.sql
\ir EVAL/UNARY_MINUS.sql
\ir EVAL/STORE_ARGS.sql
\ir EVAL/LEAVE_PROGRAM.sql
\ir EVAL/LEAVE_BLOCK_EXPRESSION.sql
\ir EVAL/LEAVE_LET_STATEMENT.sql

-- \ir soft/FUNCTIONS/tokenize.sql
-- \ir soft/FUNCTIONS/parse.sql
-- \ir soft/FUNCTIONS/get_dot.sql
-- \ir soft/FUNCTIONS/shortcut_nops.sql
-- \ir soft/FUNCTIONS/eval_node.sql
-- \ir soft/FUNCTIONS/matching_arguments.sql
-- \ir soft/FUNCTIONS/walk_tree.sql
-- \ir soft/FUNCTIONS/find_last_edge.sql
-- \ir soft/FUNCTIONS/free_variables.sql
-- \ir soft/FUNCTIONS/if_statements.sql
-- \ir soft/FUNCTIONS/function_declarations.sql
-- \ir soft/FUNCTIONS/find_node.sql
-- \ir soft/FUNCTIONS/copy_node.sql
-- \ir soft/FUNCTIONS/push_node.sql
-- \ir soft/FUNCTIONS/pop_node.sql
-- \ir soft/FUNCTIONS/execute_bonsai_functions.sql
-- \ir soft/FUNCTIONS/set_visited.sql
