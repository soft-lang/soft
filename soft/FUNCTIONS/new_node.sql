CREATE OR REPLACE FUNCTION New_Node(
_ProgramID            integer,
_NodeTypeID           integer,
_TerminalValue        text      DEFAULT NULL,
_TerminalType         regtype   DEFAULT NULL,
_SourceCodeCharacters integer[] DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_PhaseID  integer;
_NodeID   integer;
_OK       boolean;
_CastTest text;
BEGIN
IF (SELECT TerminalType FROM NodeTypes WHERE NodeTypeID = _NodeTypeID) <> _TerminalType THEN
    RAISE EXCEPTION 'TerminalType % is different from NodeTypes.TerminalType', _TerminalType;
END IF;

SELECT PhaseID INTO STRICT _PhaseID FROM Programs WHERE ProgramID = _ProgramID;

IF _TerminalValue IS NOT NULL THEN
    EXECUTE format('SELECT %L::%s::text', _TerminalValue, _TerminalType) INTO STRICT _CastTest;
    IF _TerminalValue IS DISTINCT FROM _CastTest THEN
        RAISE EXCEPTION 'TerminalValue "%" resulted in the different value "%" when casted to type "%" and then back to text', _TerminalValue, _CastTest, _TerminalType;
    END IF;
END IF;

INSERT INTO Nodes  ( ProgramID,  NodeTypeID, BirthPhaseID, VisitPhaseID,  TerminalType,  TerminalValue,  SourceCodeCharacters)
VALUES             (_ProgramID, _NodeTypeID,     _PhaseID,     _PhaseID, _TerminalType, _TerminalValue, _SourceCodeCharacters)
RETURNING    NodeID
INTO STRICT _NodeID;

RETURN _NodeID;
END;
$$;
