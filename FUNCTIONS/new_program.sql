CREATE OR REPLACE FUNCTION soft.New_Program(_Language text, _Program text, _SourceCodeNodeID integer)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_LanguageID    integer;
_ProgramID     integer;
_Nodes         text;
_OK            boolean;
_ProgramNodeID integer;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

PERFORM Expand_Token_Groups(_Language);

INSERT INTO Programs ( LanguageID,  Program,  NodeID,            SourceCodeNodeID)
VALUES               (_LanguageID, _Program, _SourceCodeNodeID, _SourceCodeNodeID)
RETURNING ProgramID INTO STRICT _ProgramID;

UPDATE Nodes SET Visited = 1 WHERE NOT Deleted AND NodeID = _SourceCodeNodeID RETURNING TRUE INTO STRICT _OK;

PERFORM Tokenize(_LanguageID, _SourceCodeNodeID);

SELECT string_agg(format('%s%s',NodeTypes.NodeType,Nodes.NodeID), ' ' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Nodes
INNER JOIN NodeTypes              ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges                  ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Edges.ParentNodeID = _SourceCodeNodeID
AND NOT Nodes.Deleted
AND NOT Edges.Deleted;

PERFORM Parse(_LanguageID, _Nodes);

SELECT NodeID
INTO STRICT _ProgramNodeID
FROM Nodes
WHERE NOT Deleted
AND NOT EXISTS (SELECT 1 FROM Edges WHERE NOT Edges.Deleted AND Edges.ParentNodeID = Nodes.NodeID);

UPDATE Programs SET NodeID = _ProgramNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
UPDATE Edges SET Deleted = TRUE WHERE NOT Deleted AND ParentNodeID = _SourceCodeNodeID;
UPDATE Programs SET SourceCodeNodeID = _SourceCodeNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Nodes SET Visited = 1 WHERE NOT Deleted AND NodeID = _ProgramNodeID RETURNING TRUE INTO STRICT _OK;

PERFORM Shortcut_NOPs();

RETURN _ProgramID;
END;
$$;
