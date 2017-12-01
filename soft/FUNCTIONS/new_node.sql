CREATE OR REPLACE FUNCTION New_Node(
_ProgramID            integer,
_NodeTypeID           integer,
_PrimitiveType        regtype   DEFAULT NULL,
_PrimitiveValue       text      DEFAULT NULL,
_NodeName             name      DEFAULT NULL,
_Walkable             boolean   DEFAULT NULL,
_ClonedFromNodeID     integer   DEFAULT NULL,
_ClonedRootNodeID     integer   DEFAULT NULL,
_ReferenceNodeID      integer   DEFAULT NULL,
_EnvironmentID        integer   DEFAULT 0
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_Program      text;
_BirthPhaseID integer;
_NodeID       integer;
_CastTest     text;
_OK           boolean;
BEGIN

SELECT PhaseID, Program INTO STRICT _BirthPhaseID, _Program FROM Programs WHERE ProgramID = _ProgramID;

IF _PrimitiveValue IS NOT NULL AND _PrimitiveType IS NOT NULL THEN
    EXECUTE format('SELECT %L::%s::text', _PrimitiveValue, _PrimitiveType) INTO STRICT _CastTest;
    IF _PrimitiveValue IS DISTINCT FROM _CastTest THEN
        RAISE EXCEPTION 'Program "%": PrimitiveValue "%" resulted in the different value "%" when casted to type "%" and then back to text', _Program, _PrimitiveValue, _CastTest, _PrimitiveType;
    END IF;
END IF;

IF _Walkable IS NULL THEN
    IF _PrimitiveValue IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM Programs
        INNER JOIN Phases       ON Phases.LanguageID    = Programs.LanguageID
        INNER JOIN pg_namespace ON pg_namespace.nspname = Phases.Phase
        INNER JOIN pg_proc      ON pg_proc.pronamespace = pg_namespace.oid
        INNER JOIN NodeTypes    ON NodeTypes.NodeTypeID = _NodeTypeID
        WHERE Programs.ProgramID = _ProgramID
        AND pg_proc.proname IN (
            'ENTER_'||NodeTypes.NodeType,
            NodeTypes.NodeType,
            'LEAVE_'||NodeTypes.NodeType
        )
    ) THEN
        -- Node is given an initial primitive value
        -- and there is no semantic functionality for its NodeType
        -- so no need to visit this node when walking the tree.
        _Walkable := FALSE;
    ELSE
        _Walkable := TRUE;
    END IF;
END IF;

INSERT INTO Nodes  ( ProgramID,  NodeTypeID,  BirthPhaseID,  PrimitiveType,  PrimitiveValue,  NodeName,  Walkable,  ClonedFromNodeID,  ClonedRootNodeID,  ReferenceNodeID,  EnvironmentID)
VALUES             (_ProgramID, _NodeTypeID, _BirthPhaseID, _PrimitiveType, _PrimitiveValue, _NodeName, _Walkable, _ClonedFromNodeID, _ClonedRootNodeID, _ReferenceNodeID, _EnvironmentID)
RETURNING    NodeID
INTO STRICT _NodeID;

RETURN _NodeID;
END;
$$;

CREATE OR REPLACE FUNCTION New_Node(
_Language         text,
_Program          text,
_NodeType         text,
_PrimitiveType    regtype   DEFAULT NULL,
_PrimitiveValue   text      DEFAULT NULL,
_NodeName         name      DEFAULT NULL,
_Walkable         boolean   DEFAULT NULL,
_ClonedFromNodeID integer   DEFAULT NULL,
_ClonedRootNodeID integer   DEFAULT NULL,
_ReferenceNodeID  integer   DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_NodeID integer;
BEGIN
SELECT New_Node(
    _ProgramID        := Programs.ProgramID,
    _NodeTypeID       := NodeTypes.NodeTypeID,
    _PrimitiveType    := _PrimitiveType,
    _PrimitiveValue   := _PrimitiveValue,
    _NodeName         := _NodeName,
    _Walkable         := _Walkable,
    _ClonedFromNodeID := _ClonedFromNodeID,
    _ClonedRootNodeID := _ClonedRootNodeID,
    _ReferenceNodeID  := _ReferenceNodeID
)
INTO STRICT _NodeID
FROM Programs
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
INNER JOIN NodeTypes ON NodeTypes.LanguageID = Languages.LanguageID
WHERE Languages.Language = _Language
AND   Programs.Program   = _Program
AND   NodeTypes.NodeType = _NodeType;
RETURN _NodeID;
END;
$$;
