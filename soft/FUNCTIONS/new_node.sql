CREATE OR REPLACE FUNCTION New_Node(
_ProgramID            integer,
_NodeTypeID           integer,
_TerminalType         regtype   DEFAULT NULL,
_TerminalValue        text      DEFAULT NULL,
_ClonedFromNodeID     integer   DEFAULT NULL,
_ClonedRootNodeID     integer   DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_BirthPhaseID integer;
_NodeID       integer;
_OK           boolean;
_CastTest     text;
BEGIN

SELECT PhaseID INTO STRICT _BirthPhaseID FROM Programs WHERE ProgramID = _ProgramID;

IF _TerminalValue IS NOT NULL AND _TerminalType IS NOT NULL THEN
    EXECUTE format('SELECT %L::%s::text', _TerminalValue, _TerminalType) INTO STRICT _CastTest;
    IF _TerminalValue IS DISTINCT FROM _CastTest THEN
        RAISE EXCEPTION 'TerminalValue "%" resulted in the different value "%" when casted to type "%" and then back to text', _TerminalValue, _CastTest, _TerminalType;
    END IF;
END IF;

INSERT INTO Nodes  ( ProgramID,  NodeTypeID,  BirthPhaseID,  TerminalType,  TerminalValue,  ClonedFromNodeID,  ClonedRootNodeID)
VALUES             (_ProgramID, _NodeTypeID, _BirthPhaseID, _TerminalType, _TerminalValue, _ClonedFromNodeID, _ClonedRootNodeID)
RETURNING    NodeID
INTO STRICT _NodeID;

RETURN _NodeID;
END;
$$;

CREATE OR REPLACE FUNCTION New_Node(
_Program              text,
_NodeType             text,
_TerminalType         regtype   DEFAULT NULL,
_TerminalValue        text      DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_ProgramID integer;
_NodeTypeID integer;
BEGIN
SELECT
    Programs.ProgramID,
    NodeTypes.NodeTypeID
INTO STRICT
    _ProgramID,
    _NodeTypeID
FROM Programs
INNER JOIN Phases    ON Phases.PhaseID = Programs.PhaseID
INNER JOIN NodeTypes ON NodeTypes.LanguageID = Phases.LanguageID
WHERE Programs.Program = _Program
AND NodeTypes.NodeType = _NodeType;

RETURN New_Node(
    _ProgramID            := _ProgramID,
    _NodeTypeID           := _NodeTypeID,
    _TerminalType         := _TerminalType,
    _TerminalValue        := _TerminalValue
);
END;
$$;
