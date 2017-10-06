SET search_path TO soft, public, pg_temp;

\COPY (SELECT * FROM Export_Node_Types) TO ~/src/soft/languages/monkey/node_types.csv WITH CSV HEADER QUOTE '"';
