DROP TABLE IF EXISTS NodeTypes;
CREATE TABLE NodeTypes (
NodeTypeID serial NOT NULL,
NodeType text NOT NULL,
LiteralPattern text,
NodePattern text,
PRIMARY KEY (NodeTypeID),
UNIQUE(NodeType)
);

-- \i ~/src/soft/soft/FUNCTIONS/regexp_escape.sql
\i ~/src/soft/soft/FUNCTIONS/get_token_regexp.sql
\i ~/src/soft/soft/FUNCTIONS/get_token_nodetypes.sql
\i ~/src/soft/soft/FUNCTIONS/get_tokens_regexp.sql
\i ~/src/soft/soft/FUNCTIONS/tokenize.sql
\i ~/src/soft/soft/FUNCTIONS/parse.sql

CREATE EXTENSION IF NOT EXISTS hstore;

\copy NodeTypes (NodeType, LiteralPattern, NodePattern) FROM ~/src/soft/languages/json/node_types.csv WITH CSV NULL '' HEADER QUOTE '"'
UPDATE NodeTypes SET LiteralPattern = NULL WHERE LiteralPattern = '';
UPDATE NodeTypes SET NodePattern = NULL WHERE NodePattern = '';

ALTER TABLE NodeTypes ADD COLUMN UnicodeChar char;
ALTER TABLE NodeTypes ADD UNIQUE(UnicodeChar);
ALTER TABLE NodeTypes ADD COLUMN NodePatternUnicode text;

SELECT * FROM Get_Token_NodeTypes();

\x
SELECT * FROM Get_Tokens_Regexp();
\x

SELECT Parse('{"foo":"bar"}');

-- 44032

-- ^(?:(\s+)|(\{)|("(?:[^\x00-\x1f"\\]|\\(?:["\\/bfnrt]|u[0-9A-Fa-f]{4}))*")|(:)|(,)|(\})|(\[)|(\])|(true)|(false)|(null)|(-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?))
