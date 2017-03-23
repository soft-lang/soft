CREATE OR REPLACE FUNCTION soft.Shortcut_Nops()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NOPNodeID integer;
_SourceCodeNodeID integer;
_ProgramNodeID integer;
_ParentNodeID integer;
_ChildNodeID integer;
_EdgeIDToParent integer;
_GrantParentNodeID integer;
_EdgeIDToChild integer;
_OK boolean;
_DidWork boolean;
_NodeTypeID integer;
_ValueType regtype;
_NodeType text;
BEGIN

LOOP
    _DidWork := FALSE;

    SELECT NodeID
    INTO STRICT _SourceCodeNodeID
    FROM Nodes
    WHERE NOT EXISTS (SELECT 1 FROM Edges WHERE Edges.ChildNodeID = Nodes.NodeID);

    FOR _NOPNodeID, _NodeTypeID, _NodeType, _ValueType IN
    SELECT Nodes.NodeID, Nodes.NodeTypeID, NodeTypes.NodeType, NodeTypes.ValueType
    FROM Nodes
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Nodes.ValueType IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = 'soft'
        AND   pg_proc.proname      = NodeTypes.NodeType
    )
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.ParentNodeID = Nodes.NodeID) = 1
    AND (SELECT COUNT(*) FROM Edges WHERE Edges.ChildNodeID  = Nodes.NodeID) = 1
    LOOP
        RAISE NOTICE 'SELECT1 ChildNodeID=NOPNodeID %', _NOPNodeID;
        SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID  = _NOPNodeID;
        RAISE NOTICE 'SELECT2 ParentNodeID=NOPNodeID %', _NOPNodeID;
        SELECT ChildNodeID  INTO STRICT _ChildNodeID  FROM Edges WHERE ParentNodeID = _NOPNodeID;

        RAISE NOTICE 'DELETE Edge %->%', _ParentNodeID, _NOPNodeID;
        DELETE FROM Edges
        WHERE ParentNodeID = _ParentNodeID
        AND   ChildNodeID  = _NOPNodeID
        RETURNING TRUE INTO STRICT _OK;

        RAISE NOTICE 'UPDATE Edge %->% => %->%', _NOPNodeID, _ChildNodeID, _ParentNodeID, _ChildNodeID;

        IF _ParentNodeID = _SourceCodeNodeID THEN
            DELETE FROM Edges
            WHERE ParentNodeID = _NOPNodeID
            AND   ChildNodeID  = _ChildNodeID
            RETURNING TRUE INTO STRICT _OK;
        ELSE
            UPDATE Edges
            SET ParentNodeID = _ParentNodeID
            WHERE ParentNodeID = _NOPNodeID
            AND   ChildNodeID  = _ChildNodeID
            RETURNING TRUE INTO STRICT _OK;
        END IF;

        DELETE FROM Nodes WHERE NodeID = _NOPNodeID RETURNING TRUE INTO STRICT _OK;

        IF NOT EXISTS (SELECT 1 FROM Edges WHERE ChildNodeID = _ChildNodeID) THEN
            INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_SourceCodeNodeID, _ChildNodeID) RETURNING TRUE INTO STRICT _OK;
        END IF;

        IF _ValueType IS NOT NULL THEN
            UPDATE Nodes SET NodeTypeID = _NodeTypeID WHERE NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
        END IF;

        RAISE NOTICE 'Shortcutted NOP % % -> % -> %', _NodeType, _ParentNodeID, _NOPNodeID, _ChildNodeID;

        _DidWork := TRUE;
    END LOOP;

    FOR _NOPNodeID IN
    SELECT Nodes.NodeID
    FROM Nodes
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    INNER JOIN Edges     ON Edges.ChildNodeID    = Nodes.NodeID
    WHERE Edges.ParentNodeID = _SourceCodeNodeID
    AND (SELECT COUNT(*) FROM Edges AS E WHERE E.ParentNodeID = Nodes.NodeID) = 0
    AND (SELECT COUNT(*) FROM Edges AS E WHERE E.ChildNodeID  = Nodes.NodeID) = 1
    AND Nodes.ValueType IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = 'soft'
        AND   pg_proc.proname      = NodeTypes.NodeType
    )
    LOOP
        DELETE FROM Edges WHERE ChildNodeID  = _NOPNodeID RETURNING ParentNodeID INTO STRICT _ParentNodeID;
        DELETE FROM Nodes WHERE NodeID       = _NOPNodeID RETURNING TRUE         INTO STRICT _OK;
        _DidWork := TRUE;
    END LOOP;
    SELECT NodeID
    INTO STRICT _ProgramNodeID
    FROM Nodes
    WHERE NOT EXISTS (SELECT 1 FROM Edges WHERE Edges.ParentNodeID = Nodes.NodeID);
    DELETE FROM Edges WHERE ParentNodeID = _SourceCodeNodeID AND ChildNodeID = _ProgramNodeID;
    IF FOUND THEN
        _DidWork := TRUE;
    END IF;
    IF _DidWork THEN
        CONTINUE;
    END IF;
    EXIT;
END LOOP;

UPDATE Programs SET NodeID = _ProgramNodeID WHERE NodeID = _SourceCodeNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Nodes SET Visited = 1 WHERE NodeID = _ProgramNodeID RETURNING TRUE INTO STRICT _OK;

RETURN TRUE;
END;
$$;
