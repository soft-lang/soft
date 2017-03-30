CREATE OR REPLACE FUNCTION soft.Shortcut_Nops()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NOPNodeID integer;
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

    FOR _NOPNodeID, _NodeTypeID, _NodeType, _ValueType IN
    SELECT Nodes.NodeID, Nodes.NodeTypeID, NodeTypes.NodeType, NodeTypes.ValueType
    FROM Nodes
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE NOT Nodes.Deleted
    AND Nodes.ValueType IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = 'soft'
        AND   pg_proc.proname      = NodeTypes.NodeType
    )
    AND (SELECT COUNT(*) FROM Edges WHERE NOT Edges.Deleted AND Edges.ParentNodeID = Nodes.NodeID) = 1
    AND (SELECT COUNT(*) FROM Edges WHERE NOT Edges.Deleted AND Edges.ChildNodeID  = Nodes.NodeID) = 1
    LOOP
        RAISE NOTICE 'SELECT1 ChildNodeID=NOPNodeID %', _NOPNodeID;
        SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE NOT Deleted AND ChildNodeID  = _NOPNodeID;
        RAISE NOTICE 'SELECT2 ParentNodeID=NOPNodeID %', _NOPNodeID;
        SELECT ChildNodeID  INTO STRICT _ChildNodeID  FROM Edges WHERE NOT Deleted AND ParentNodeID = _NOPNodeID;

        RAISE NOTICE 'DELETE Edge %->%', _ParentNodeID, _NOPNodeID;
        UPDATE Edges SET Deleted = TRUE
        WHERE NOT Deleted
        AND   ParentNodeID = _ParentNodeID
        AND   ChildNodeID  = _NOPNodeID
        RETURNING TRUE INTO STRICT _OK;

        RAISE NOTICE 'UPDATE Edge %->% => %->%', _NOPNodeID, _ChildNodeID, _ParentNodeID, _ChildNodeID;

        UPDATE Edges
        SET ParentNodeID = _ParentNodeID
        WHERE NOT Deleted
        AND   ParentNodeID = _NOPNodeID
        AND   ChildNodeID  = _ChildNodeID
        RETURNING TRUE INTO STRICT _OK;

        UPDATE Nodes SET Deleted = TRUE WHERE NOT Deleted AND NodeID = _NOPNodeID RETURNING TRUE INTO STRICT _OK;

        IF _ValueType IS NOT NULL THEN
            UPDATE Nodes SET NodeTypeID = _NodeTypeID WHERE NOT Deleted AND NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
        END IF;

        RAISE NOTICE 'Shortcutted NOP % % -> % -> %', _NodeType, _ParentNodeID, _NOPNodeID, _ChildNodeID;

        _DidWork := TRUE;
    END LOOP;

    FOR _NOPNodeID IN
    SELECT Nodes.NodeID
    FROM Nodes
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE NOT Nodes.Deleted
    AND (SELECT COUNT(*) FROM Edges AS E WHERE NOT E.Deleted AND E.ChildNodeID  = Nodes.NodeID) = 0
    AND Nodes.ValueType IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = 'soft'
        AND   pg_proc.proname      = NodeTypes.NodeType
    )
    LOOP
        UPDATE Edges SET Deleted = TRUE WHERE NOT Deleted AND ParentNodeID = _NOPNodeID RETURNING ChildNodeID INTO STRICT _ChildNodeID;
        UPDATE Nodes SET Deleted = TRUE WHERE NOT Deleted AND NodeID       = _NOPNodeID RETURNING TRUE        INTO STRICT _OK;
        UPDATE Nodes SET Chars = Chars || (SELECT Chars FROM Nodes WHERE NodeID = _NOPNodeID) WHERE NodeID = _ChildNodeID RETURNING TRUE INTO STRICT _OK;
        _DidWork := TRUE;
    END LOOP;

    IF _DidWork THEN
        CONTINUE;
    END IF;
    EXIT;
END LOOP;

RETURN TRUE;
END;
$$;
