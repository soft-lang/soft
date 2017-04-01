CREATE SCHEMA soft;
SET search_path TO soft, public;
\ir soft/TABLES/languages.sql
\ir soft/TABLES/phases.sql
\ir soft/TABLES/nodetypes.sql
\ir soft/TABLES/programs.sql
\ir soft/TABLES/nodes.sql
\ir soft/TABLES/edges.sql

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

CREATE SCHEMA "TOKENIZE";
\ir TOKENIZE/SOURCE_CODE.sql

CREATE SCHEMA "PARSE";
\ir PARSE/SOURCE_CODE.sql

CREATE SCHEMA "MAP_VARIABLES";

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
-- \ir soft/FUNCTIONS/set_node_value.sql
-- \ir soft/FUNCTIONS/push_node.sql
-- \ir soft/FUNCTIONS/pop_node.sql
-- \ir soft/FUNCTIONS/execute_bonsai_functions.sql
-- \ir soft/FUNCTIONS/set_visited.sql
-- \ir soft/FUNCTIONS/highlight_code.sql
