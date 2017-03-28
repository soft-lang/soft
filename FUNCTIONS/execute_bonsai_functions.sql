CREATE OR REPLACE FUNCTION soft.Execute_Bonsai_Functions(_ProgramID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_LanguageID     integer;
_NodeID         integer;
_BonsaiSchemaID integer;
_BonsaiSchema   name;
_ValueType      regtype;
_Visited        integer;
_ParentNodeID   integer;
_NodeType       text;
_ChildNodeID    integer;
_OK             boolean;
_BonsaiFunction text;
BEGIN

SELECT
    Programs.LanguageID,
    Programs.NodeID,
    Programs.BonsaiSchemaID,
    BonsaiSchemas.BonsaiSchema
INTO STRICT
    _LanguageID,
    _NodeID,
    _BonsaiSchemaID,
    _BonsaiSchema
FROM Programs
LEFT JOIN BonsaiSchemas ON BonsaiSchemas.BonsaiSchemaID = Programs.BonsaiSchemaID
WHERE ProgramID = _ProgramID;

RAISE NOTICE 'ProgramID % NodeID %', _ProgramID, _NodeID;

IF _BonsaiSchemaID IS NULL THEN
    SELECT BonsaiSchemaID,  BonsaiSchema
    INTO  _BonsaiSchemaID, _BonsaiSchema
    FROM BonsaiSchemas
    WHERE LanguageID = _LanguageID
    ORDER BY BonsaiSchemaID
    LIMIT 1;

    UPDATE Programs SET BonsaiSchemaID = _BonsaiSchemaID
    WHERE ProgramID = _ProgramID
    RETURNING TRUE INTO STRICT _OK;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
END IF;

SELECT Nodes.ValueType, Nodes.Visited INTO STRICT _ValueType, _Visited FROM Nodes
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE NodeID = _NodeID;

SELECT
    Edges.ParentNodeID,
    'ENTER_'||NodeTypes.NodeType
INTO
    _ParentNodeID,
    _BonsaiFunction
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ChildNodeID = _NodeID
AND Nodes.Visited       < _Visited
ORDER BY Edges.EdgeID
LIMIT 1;
IF FOUND THEN
    RAISE NOTICE '% -> % %', _NodeID, _ParentNodeID, _BonsaiFunction;
    UPDATE Programs SET NodeID  = _ParentNodeID WHERE ProgramID = _ProgramID    RETURNING TRUE INTO STRICT _OK;
    UPDATE Nodes    SET Visited = Visited + 1   WHERE NodeID    = _ParentNodeID RETURNING TRUE INTO STRICT _OK;

    IF EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = _BonsaiSchema
        AND   pg_proc.proname      = _BonsaiFunction
    ) THEN
        RAISE NOTICE 'Executing bonsai function %.%', _BonsaiSchema, _BonsaiFunction;
        EXECUTE format('SELECT %I.%I()', _BonsaiSchema, _BonsaiFunction);
    END IF;

    RETURN TRUE;
END IF;

SELECT
    Edges.ChildNodeID,
    'LEAVE_'||NodeTypes.NodeType
INTO
    _ChildNodeID,
    _BonsaiFunction
FROM Edges
INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _NodeID
ORDER BY Edges.EdgeID
LIMIT 1;
IF FOUND THEN
    RAISE NOTICE '% <- % %', _ChildNodeID, _NodeID, _BonsaiFunction;
    IF EXISTS (
        SELECT 1 FROM pg_proc
        INNER JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE pg_namespace.nspname = _BonsaiSchema
        AND   pg_proc.proname      = _BonsaiFunction
    ) THEN
        RAISE NOTICE 'Executing bonsai function %.%', _BonsaiSchema, _BonsaiFunction;
        EXECUTE format('SELECT %I.%I()', _BonsaiSchema, _BonsaiFunction);
        IF NOT EXISTS (SELECT 1 FROM Nodes WHERE NodeID = _NodeID) THEN
            -- Node was deleted by bonsai function
            RETURN TRUE;
        END IF;        
        SELECT
            Edges.ChildNodeID
        INTO STRICT
            _ChildNodeID
        FROM Edges
        WHERE Edges.ParentNodeID = _NodeID
        ORDER BY Edges.EdgeID
        LIMIT 1;
    END IF;
    UPDATE Programs SET NodeID = _ChildNodeID WHERE ProgramID = _ProgramID RETURNING TRUE INTO STRICT _OK;
    RETURN TRUE;
END IF;

SELECT BonsaiSchemaID,  BonsaiSchema
INTO  _BonsaiSchemaID, _BonsaiSchema
FROM BonsaiSchemas
WHERE LanguageID     = _LanguageID
AND   BonsaiSchemaID > _BonsaiSchemaID
ORDER BY BonsaiSchemaID
LIMIT 1;
IF FOUND THEN
    RAISE NOTICE 'Switching to bonsai schema %', _BonsaiSchema;
    UPDATE Programs SET
        BonsaiSchemaID = _BonsaiSchemaID
    WHERE ProgramID = _ProgramID
    RETURNING NodeID INTO STRICT _NodeID;
    UPDATE Nodes SET
        Visited        = Visited + 1
    WHERE NodeID = _NodeID
    RETURNING TRUE INTO STRICT _OK;
    RETURN TRUE;
END IF;

RETURN FALSE;
END;
$$;
