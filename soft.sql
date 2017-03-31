CREATE SCHEMA soft;
SET search_path TO soft, public;
\ir soft/TABLES/languages.sql
\ir soft/TABLES/phases.sql
\ir soft/TABLES/nodetypes.sql
\ir soft/TABLES/nodes.sql
\ir soft/TABLES/edges.sql
\ir soft/TABLES/programs.sql
\ir soft/FUNCTIONS/new_language.sql
\ir soft/FUNCTIONS/new_phase.sql
\ir soft/FUNCTIONS/new_node_type.sql
\ir soft/FUNCTIONS/new_node.sql
\ir soft/FUNCTIONS/new_edge.sql

\ir FUNCTIONS/tokenize.sql
\ir FUNCTIONS/parse.sql
\ir FUNCTIONS/new_program.sql
\ir FUNCTIONS/get_dot.sql
\ir FUNCTIONS/shortcut_nops.sql
\ir FUNCTIONS/eval_node.sql
\ir FUNCTIONS/matching_arguments.sql
\ir FUNCTIONS/walk_tree.sql
\ir FUNCTIONS/find_last_edge.sql
\ir FUNCTIONS/free_variables.sql
\ir FUNCTIONS/if_statements.sql
\ir FUNCTIONS/function_declarations.sql
\ir FUNCTIONS/find_node.sql
\ir FUNCTIONS/copy_node.sql
\ir FUNCTIONS/set_node_value.sql
\ir FUNCTIONS/push_node.sql
\ir FUNCTIONS/pop_node.sql
\ir FUNCTIONS/expand_token_groups.sql
\ir FUNCTIONS/execute_bonsai_functions.sql
\ir FUNCTIONS/set_visited.sql
\ir FUNCTIONS/highlight_code.sql
