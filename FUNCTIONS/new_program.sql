CREATE OR REPLACE FUNCTION soft.New_Program(_Language text, _Program text, _NodeID integer)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_LanguageID integer;
_ProgramID  integer;
_Nodes      text;
BEGIN
SELECT LanguageID INTO STRICT _LanguageID FROM Languages WHERE Language = _Language;

INSERT INTO Programs ( LanguageID,  Program,  NodeID)
VALUES               (_LanguageID, _Program, _NodeID)
RETURNING ProgramID INTO STRICT _ProgramID;

UPDATE Nodes SET Visited = 1 WHERE NodeID = _NodeID;

PERFORM Tokenize(_LanguageID, _NodeID);

SELECT string_agg(format('%s%s',NodeTypes.NodeType,Nodes.NodeID), ' ' ORDER BY Nodes.NodeID)
INTO _Nodes
FROM Nodes
INNER JOIN NodeTypes              ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
INNER JOIN Edges                  ON Edges.ChildNodeID    = Nodes.NodeID
WHERE Edges.ParentNodeID = _NodeID;

PERFORM Parse(_LanguageID, _Nodes);

PERFORM Shortcut_NOPs();

RETURN _ProgramID;
END;
$$;
