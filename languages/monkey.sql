SET search_path TO soft, public;

SELECT New_Language(_Language := 'monkey', _LogSeverity := 'DEBUG5');
\ir monkey/node_types.sql

SELECT New_Phase(_Language := 'monkey', _Phase := 'TOKENIZE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'DISCARD');
SELECT New_Phase(_Language := 'monkey', _Phase := 'PARSE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'REDUCE');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_VARIABLES');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_ALLOCA');
SELECT New_Phase(_Language := 'monkey', _Phase := 'MAP_FUNCTIONS');
SELECT New_Phase(_Language := 'monkey', _Phase := 'EVAL');

SELECT New_Program(_Language := 'monkey', _Program := 'test');

SELECT New_Node(_Program := 'test', _NodeType := 'SOURCE_CODE', _TerminalType := 'text'::regtype, _TerminalValue := $SRC$
let foo = fn(a,b) {
    let x = a*b;
    x
};
let y = foo(2,3)+foo(4,5);
return y;
$SRC$);




















































-- SELECT "TOKENIZE"."SOURCE_CODE"(1);
-- UPDATE Programs SET PhaseID = 2 WHERE ProgramID = 1;
-- SELECT "DISCARD"."WHITE_SPACE"(NodeID) FROM Nodes WHERE NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'WHITE_SPACE');
-- UPDATE Programs SET PhaseID = 3 WHERE ProgramID = 1;
-- SELECT "PARSE"."SOURCE_CODE"(1);
-- UPDATE Programs SET PhaseID = 4 WHERE ProgramID = 1;
-- SELECT "REDUCE"."SOURCE_CODE"(1);

-- SELECT "PARSE"."SOURCE_CODE"(1);

/*
SELECT Expand_Token_Groups(_Language := 'monkey');

CREATE SCHEMA IF NOT EXISTS "MAP_VARIABLES";
SELECT New_Bonsai_Schema(_Language := 'monkey', _BonsaiSchema := 'MAP_VARIABLES');

CREATE SCHEMA IF NOT EXISTS "MAP_ALLOCA";
SELECT New_Bonsai_Schema(_Language := 'monkey', _BonsaiSchema := 'MAP_ALLOCA');

CREATE SCHEMA IF NOT EXISTS "CUT_NAVEL_CORDS";
SELECT New_Bonsai_Schema(_Language := 'monkey', _BonsaiSchema := 'CUT_NAVEL_CORDS');

CREATE SCHEMA IF NOT EXISTS "BLOCK_BRANCHES";
SELECT New_Bonsai_Schema(_Language := 'monkey', _BonsaiSchema := 'BLOCK_BRANCHES');


CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."LEAVE_FUNCTION_DECLARATION"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_LetStatementNodeID integer;
_VariableNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ChildNodeID INTO STRICT _LetStatementNodeID FROM Edges WHERE ParentNodeID = _CurrentNodeID;
SELECT ParentNodeID INTO STRICT _VariableNodeID FROM Edges WHERE ChildNodeID = _LetStatementNodeID ORDER BY EdgeID LIMIT 1;
DELETE FROM Edges WHERE ChildNodeID = _LetStatementNodeID AND ParentNodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Edges SET ChildNodeID = _VariableNodeID WHERE ParentNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Edges SET ParentNodeID = _VariableNodeID WHERE ParentNodeID = _LetStatementNodeID RETURNING TRUE INTO STRICT _OK;
DELETE FROM Nodes WHERE NodeID = _LetStatementNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Nodes SET NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'FUNCTION_LABEL') WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'MAP_VARIABLES.LEAVE_FUNCTION_DECLARATION _CurrentNodeID %', _CurrentNodeID;
END;
$$;

CREATE OR REPLACE FUNCTION "CUT_NAVEL_CORDS"."LEAVE_FUNCTION_LABEL"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_DeclarePointNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
IF NOT EXISTS (
    SELECT 1
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ParentNodeID = _CurrentNodeID
    AND NodeTypes.NodeType = 'CALL'
) THEN
    RAISE NOTICE 'Function NodeID % is unused', _CurrentNodeID;
    RETURN;
END IF;
DELETE FROM Edges WHERE EdgeID = (
    SELECT Edges.EdgeID
    FROM Edges
    INNER JOIN Nodes     ON Nodes.NodeID         = Edges.ChildNodeID
    INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
    WHERE Edges.ParentNodeID = _CurrentNodeID
    AND NodeTypes.NodeType <> 'CALL'
)
RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'CUT_NAVEL_CORDS.LEAVE_FUNCTION_LABEL _CurrentNodeID %', _CurrentNodeID;
END;
$$;

CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_FUNCTION_NAME"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
_ChildNodeID integer;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT Visited, NameValue INTO STRICT _Visited, _NameValue FROM Nodes WHERE NodeID = _CurrentNodeID AND ValueType = 'name'::regtype;
_VariableNodeID := Find_Function_Node(_CurrentNodeID, _NameValue);
RAISE NOTICE '_CurrentNodeID % VariableNodeID %', _CurrentNodeID, _VariableNodeID;
SELECT ChildNodeID INTO STRICT _ChildNodeID FROM Edges WHERE ParentNodeID = _CurrentNodeID;
RAISE NOTICE '_ChildNodeID %', _ChildNodeID;
UPDATE Programs SET NodeID = _ChildNodeID WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'Set current node';
UPDATE Edges SET ParentNodeID = _VariableNodeID WHERE ParentNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'Update edge';
DELETE FROM Nodes WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'ENTER_FUNCTION_NAME _CurrentNodeID % _NameValue % <- _VariableNodeID %', _CurrentNodeID, _NameValue, _VariableNodeID;
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "MAP_VARIABLES"."ENTER_CALL"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ArgsNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
_ChildNodeID integer;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT New_Node(NodeTypeID) INTO STRICT _ArgsNodeID FROM NodeTypes WHERE NodeType = 'ARGS';
UPDATE Edges SET ChildNodeID = _ArgsNodeID WHERE EdgeID IN (SELECT EdgeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID OFFSET 1);
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_ArgsNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE 'MAP_VARIABLES.ENTER_CALL _CurrentNodeID %', _CurrentNodeID;
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "MAP_ALLOCA"."ENTER_VARIABLE"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_NodeID integer;
_AllocaNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
RAISE NOTICE 'MAP_ALLOCA.ENTER_VARIABLE _CurrentNodeID %', _CurrentNodeID;
_NodeID := _CurrentNodeID;
LOOP
    SELECT AllocaNode.NodeID INTO _AllocaNodeID
    FROM Nodes
    INNER JOIN Edges               ON Edges.ChildNodeID    = Nodes.NodeID
    INNER JOIN Nodes AS AllocaNode ON AllocaNode.NodeID    = Edges.ParentNodeID
    INNER JOIN NodeTypes           ON NodeTypes.NodeTypeID = AllocaNode.NodeTypeID
    WHERE Nodes.NodeID     = _NodeID
    AND NodeTypes.NodeType = 'ALLOCA'
    ORDER BY Edges.EdgeID DESC
    LIMIT 1;
    IF FOUND THEN
        RAISE NOTICE 'MAP_ALLOCA.ENTER_VARIABLE _CurrentNodeID % Connecting to _AllocaNodeID %', _CurrentNodeID, _AllocaNodeID;
        INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_CurrentNodeID, _AllocaNodeID) RETURNING TRUE INTO STRICT _OK;
        EXIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Edges WHERE ParentNodeID = _NodeID) THEN
        EXIT;
    END IF;
    SELECT ChildNodeID INTO STRICT _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
END LOOP;
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "MAP_ALLOCA"."ENTER_IDENTIFIER"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
UPDATE Nodes SET NodeTypeID = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE') WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
PERFORM "MAP_ALLOCA"."ENTER_VARIABLE"();
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "BLOCK_BRANCHES"."LEAVE_IF_STATEMENT"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_BranchNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
RAISE NOTICE 'BLOCK_BRANCHES.LEAVE_IF_STATEMENT CurrentNodeID %', _CurrentNodeID;
FOR _BranchNodeID IN
SELECT Edges.ParentNodeID FROM Edges
WHERE Edges.ChildNodeID = _CurrentNodeID
ORDER BY Edges.EdgeID
OFFSET 1
LOOP
    RAISE NOTICE 'BLOCK_BRANCHES.LEAVE_IF_STATEMENT CurrentNodeID % BranchNodeID %', _CurrentNodeID, _BranchNodeID;
    PERFORM Set_Visited(_BranchNodeID, NULL);
END LOOP;
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "EXPRESSION_STATEMENT"(anyelement) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "RET"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION "BLOCK_EXPRESSION"(anyelement) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_LastNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _LastNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID DESC LIMIT 1;

PERFORM Copy_Node(_LastNodeID, _CurrentNodeID);

RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION "ALLOCA"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION Find_Variable_Node(_NodeID integer, _NameValue name DEFAULT NULL) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
_OriginNodeID integer;
BEGIN
_OriginNodeID := _NodeID;
LOOP
    SELECT Variable.NodeID INTO _VariableNodeID
    FROM Nodes AS LetStatementChild
    INNER JOIN Edges AS Edge1 ON Edge1.ChildNodeID = LetStatementChild.NodeID
    INNER JOIN Nodes AS CreatorNode ON CreatorNode.NodeID = Edge1.ParentNodeID
    INNER JOIN Edges AS Edge2 ON Edge2.ChildNodeID = CreatorNode.NodeID
    INNER JOIN Nodes AS Variable ON Variable.NodeID = Edge2.ParentNodeID
    WHERE LetStatementChild.NodeID = _NodeID
    AND CreatorNode.NodeTypeID  = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'LET_STATEMENT')
    AND Variable.NodeTypeID     = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE')
    AND (Variable.NameValue     = _NameValue OR _NameValue IS NULL)
    ORDER BY Edge1.EdgeID DESC
    LIMIT 1;
    IF FOUND THEN
        RETURN _VariableNodeID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Edges WHERE ParentNodeID = _NodeID) THEN
        EXIT;
    END IF;
    SELECT ChildNodeID INTO STRICT _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
END LOOP;
_NodeID := _OriginNodeID;
LOOP
    SELECT Variable.NodeID INTO _VariableNodeID
    FROM Nodes AS LetStatementChild
    INNER JOIN Edges AS Edge1       ON Edge1.ChildNodeID  = LetStatementChild.NodeID
    INNER JOIN Nodes AS CreatorNode ON CreatorNode.NodeID = Edge1.ParentNodeID
    INNER JOIN Edges AS Edge2       ON Edge2.ChildNodeID  = CreatorNode.NodeID
    INNER JOIN Nodes AS Params      ON Params.NodeID      = Edge2.ParentNodeID
    INNER JOIN Edges AS Edge3       ON Edge3.ChildNodeID  = Params.NodeID
    INNER JOIN Nodes AS Variable    ON Variable.NodeID    = Edge3.ParentNodeID
    WHERE LetStatementChild.NodeID = _NodeID
    AND CreatorNode.NodeTypeID  = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'FUNCTION_DECLARATION')
    AND Params.NodeTypeID       = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'STORE_ARGS')
    AND Variable.NodeTypeID     = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'IDENTIFIER')
    AND (Variable.NameValue     = _NameValue OR _NameValue IS NULL)
    ORDER BY Edge1.EdgeID DESC
    LIMIT 1;
    IF FOUND THEN
        RETURN _VariableNodeID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Edges WHERE ParentNodeID = _NodeID) THEN
        EXIT;
    END IF;
    SELECT ChildNodeID INTO STRICT _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
END LOOP;
RETURN NULL; -- will never reach
END;
$$;

CREATE OR REPLACE FUNCTION Find_Function_Node(_NodeID integer, _NameValue name DEFAULT NULL) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
_VariableNodeID integer;
BEGIN
LOOP
    RAISE NOTICE 'NodeID %', _NodeID;
    SELECT Variable.NodeID INTO _VariableNodeID
    FROM Nodes AS VariableChild
    INNER JOIN Edges AS Edge1       ON Edge1.ChildNodeID  = VariableChild.NodeID
    INNER JOIN Nodes AS Variable    ON Variable.NodeID    = Edge1.ParentNodeID
    WHERE VariableChild.NodeID = _NodeID
    AND Variable.NodeTypeID    = (SELECT NodeTypeID FROM NodeTypes WHERE NodeType = 'FUNCTION_LABEL')
    AND (Variable.NameValue    = _NameValue OR _NameValue IS NULL)
    ORDER BY Edge1.EdgeID DESC
    LIMIT 1;
    IF FOUND THEN
        RETURN _VariableNodeID;
    END IF;
    SELECT ChildNodeID INTO _NodeID FROM Edges WHERE ParentNodeID = _NodeID ORDER BY EdgeID LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Origin variable node for % not found from %', _NameValue, _NodeID;
    END IF;
END LOOP;
RETURN NULL; -- will never reach
END;
$$;

CREATE OR REPLACE FUNCTION "INIT_LOOP_STATEMENT"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_TrueNodeID integer;
_VariableNodeID integer;
_AssignmentNodeID integer;
_StatementsNodeID integer;
_OK boolean;
_NameValue name;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT New_Node(NodeTypeID, 'true', 'boolean'::regtype) INTO STRICT _TrueNodeID FROM NodeTypes WHERE NodeType = 'BOOLEAN';
SELECT New_Node(NodeTypeID) INTO STRICT _VariableNodeID FROM NodeTypes WHERE NodeType = 'VARIABLE';
SELECT New_Node(NodeTypeID) INTO STRICT _AssignmentNodeID FROM NodeTypes WHERE NodeType = 'LET_STATEMENT';
SELECT New_Node(NodeTypeID) INTO STRICT _StatementsNodeID FROM NodeTypes WHERE NodeType = 'STATEMENTS';

UPDATE Edges SET ParentNodeID = _StatementsNodeID WHERE ParentNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;

INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _AssignmentNodeID) RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_TrueNodeID, _AssignmentNodeID) RETURNING TRUE INTO STRICT _OK;

INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_AssignmentNodeID, _StatementsNodeID) RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_CurrentNodeID, _StatementsNodeID) RETURNING TRUE INTO STRICT _OK;

INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;

UPDATE Nodes SET Visited = 1 WHERE NodeID IN (_TrueNodeID, _VariableNodeID, _AssignmentNodeID, _StatementsNodeID);

RAISE NOTICE 'INIT_LOOP_STATEMENT _CurrentNodeID %', _CurrentNodeID;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "INIT_BREAK_STATEMENT"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_LoopNodeID integer;
_OK boolean;
_NameValue name;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LOOP_STATEMENT');

RAISE NOTICE 'INIT_BREAK_STATEMENT _CurrentNodeID % -> _VariableNodeID %', _CurrentNodeID, _VariableNodeID;

DELETE FROM Edges WHERE ChildNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "INIT_CONTINUE_STATEMENT"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_LoopNodeID integer;
_OK boolean;
_NameValue name;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LOOP_STATEMENT');

RAISE NOTICE 'INIT_CONTINUE_STATEMENT _CurrentNodeID % -> _VariableNodeID %', _CurrentNodeID, _VariableNodeID;

DELETE FROM Edges WHERE ChildNodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
INSERT INTO Edges (ParentNodeID, ChildNodeID) VALUES (_VariableNodeID, _CurrentNodeID) RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "SET_VARIABLE_NODE"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_Visited integer;
_VariableNodeID integer;
_OK boolean;
_NameValue name;
_ParentNodeID integer;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT NodeTypeID INTO STRICT _NodeTypeID FROM NodeTypes WHERE NodeType = 'VARIABLE';

SELECT
    ChildNode.Visited,
    ParentNode.NameValue,
    ParentNode.NodeID
INTO STRICT
    _Visited,
    _NameValue,
    _ParentNodeID
FROM Nodes AS ChildNode
INNER JOIN Edges ON Edges.ChildNodeID = ChildNode.NodeID
INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = ParentNode.NodeTypeID
WHERE ChildNode.NodeID = _CurrentNodeID
AND NodeTypes.NodeType = 'SET_VARIABLE';

_VariableNodeID := Find_Variable_Node(_CurrentNodeID, 'LET_STATEMENT', _NameValue);

RAISE NOTICE 'SET_VARIABLE_NODE _CurrentNodeID % _NameValue % -> _VariableNodeID %', _CurrentNodeID, _NameValue, _VariableNodeID;

UPDATE Edges SET ParentNodeID = _VariableNodeID WHERE ParentNodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
DELETE FROM Nodes WHERE NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "LOOP_STATEMENT"(boolean) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ParentNodeID integer;
_VariableNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

IF $1 THEN
    RAISE NOTICE 'LOOP *** %', _CurrentNodeID;
    UPDATE Nodes SET Visited = Visited + 1 WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
    SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
    UPDATE Programs SET NodeID = _ParentNodeID RETURNING TRUE INTO STRICT _OK;
ELSE
    SELECT ParentNodeID INTO STRICT _VariableNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID DESC LIMIT 1;
    UPDATE Nodes SET BooleanValue = TRUE WHERE NodeID = _VariableNodeID RETURNING TRUE INTO STRICT _OK;
    RAISE NOTICE 'END LOOP *** %', _CurrentNodeID;
END IF;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "BREAK_STATEMENT"(boolean) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ParentNodeID integer;
_FreeNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID;
SELECT ChildNodeID INTO STRICT _FreeNodeID FROM Edges WHERE ParentNodeID = _ParentNodeID ORDER BY EdgeID DESC LIMIT 1;

RAISE NOTICE 'BREAK LOOP *** %', _CurrentNodeID;
UPDATE Programs SET NodeID = _FreeNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "CONTINUE_STATEMENT"(boolean) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ParentNodeID integer;
_LoopNodeID integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ParentNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID;

SELECT Edges.ChildNodeID INTO STRICT _LoopNodeID FROM Edges
INNER JOIN Nodes ON Nodes.NodeID = Edges.ChildNodeID
INNER JOIN NodeTypes ON NodeTypes.NodeTypeID = Nodes.NodeTypeID
WHERE Edges.ParentNodeID = _ParentNodeID
AND NodeTypes.NodeType = 'LOOP_STATEMENT';

RAISE NOTICE 'CONTINUE LOOP *** % -> %', _CurrentNodeID, _LoopNodeID;
UPDATE Programs SET NodeID = _LoopNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;


CREATE OR REPLACE FUNCTION "IF_STATEMENT"(boolean) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ConditionNodeID integer;
_TrueNodeID integer;
_FalseNodeID integer;
_BranchNodeID integer;
_IfVisited integer;
_TrueVisited integer;
_ElseVisited integer;
_OK boolean;
BEGIN

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _ConditionNodeID FROM Edges WHERE ChildNodeID  = _CurrentNodeID ORDER BY EdgeID OFFSET 0 LIMIT 1;
SELECT ParentNodeID INTO STRICT _TrueNodeID      FROM Edges WHERE ChildNodeID  = _CurrentNodeID ORDER BY EdgeID OFFSET 1 LIMIT 1;
SELECT ParentNodeID INTO        _FalseNodeID     FROM Edges WHERE ChildNodeID  = _CurrentNodeID ORDER BY EdgeID OFFSET 2 LIMIT 1;

SELECT Visited INTO STRICT _IfVisited    FROM Nodes WHERE NodeID = _CurrentNodeID;
SELECT Visited INTO STRICT _TrueVisited  FROM Nodes WHERE NodeID = _TrueNodeID;
SELECT Visited INTO        _ElseVisited  FROM Nodes WHERE NodeID = _FalseNodeID;

IF _TrueVisited IS NOT NULL THEN
    RAISE NOTICE '*** RETURN FROM TRUE BRANCH';
    PERFORM Set_Visited(_TrueNodeID, NULL);
    UPDATE Nodes SET Visited = Visited - 1 WHERE NodeID = _ConditionNodeID RETURNING TRUE INTO STRICT _OK;
ELSIF _ElseVisited IS NOT NULL THEN
    RAISE NOTICE '*** RETURN FROM FALSE BRANCH';
    PERFORM Set_Visited(_FalseNodeID, NULL);
    UPDATE Nodes SET Visited = Visited - 1 WHERE NodeID = _ConditionNodeID RETURNING TRUE INTO STRICT _OK;
ELSE
    IF $1 THEN
        RAISE NOTICE '**** IF_STATEMENT IS TRUE';
        _BranchNodeID := _TrueNodeID;
    ELSE
        RAISE NOTICE '**** IF_STATEMENT IS FALSE';
        _BranchNodeID := _FalseNodeID;
    END IF;
    UPDATE Programs SET NodeID = _BranchNodeID WHERE NodeID = _CurrentNodeID RETURNING TRUE INTO STRICT _OK;
    PERFORM Set_Visited(_BranchNodeID, _IfVisited);
END IF;

RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "ASSIGNMENT_STATEMENT"(anyelement) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ValueNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ValueNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
PERFORM Set_Node_Value(_ValueNodeID, $1);
RETURN;
END;
$$;

CREATE OR REPLACE FUNCTION "LET_STATEMENT"() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_CurrentNodeID integer;
_ValueNodeID integer;
_OK boolean;
BEGIN
SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;
SELECT ParentNodeID INTO STRICT _ValueNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID LIMIT 1;
UPDATE Nodes SET
    ValueType    = NULL,
    NameValue    = NULL,
    BooleanValue = NULL,
    NumericValue = NULL,
    IntegerValue = NULL,
    TextValue    = NULL
WHERE NodeID = _ValueNodeID
RETURNING TRUE INTO STRICT _OK;
END;
$$;

CREATE OR REPLACE FUNCTION "LET_STATEMENT"(anyelement) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM "LET_STATEMENT"();
PERFORM "ASSIGNMENT_STATEMENT"($1);
END;
$$;

CREATE OR REPLACE FUNCTION "FREE_STATEMENT"(anyelement) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_NodeTypeID integer;
_CurrentNodeID integer;
_ValueNodeID integer;
_OldOldValueNodeID integer;
_NewOldValueNodeID integer;
_OK boolean;
BEGIN

SELECT NodeTypeID INTO STRICT _NodeTypeID FROM NodeTypes WHERE ValueType = pg_typeof($1);

SELECT NodeID INTO STRICT _CurrentNodeID FROM Programs;

SELECT ParentNodeID INTO STRICT _ValueNodeID FROM Edges WHERE ChildNodeID = _CurrentNodeID ORDER BY EdgeID DESC LIMIT 1;

SELECT ParentNodeID INTO STRICT _NewOldValueNodeID FROM Edges WHERE ChildNodeID = _ValueNodeID;

SELECT ParentNodeID INTO STRICT _OldOldValueNodeID FROM Edges WHERE ChildNodeID = _NewOldValueNodeID;

RAISE NOTICE 'FREE UPDATE _ValueNodeID % by setting it to values for _NewOldValueNodeID %', _ValueNodeID, _NewOldValueNodeID;

UPDATE Nodes AS CurValueNode SET
    NodeTypeID   = OldValueNode.NodeTypeID,
    ValueType    = OldValueNode.ValueType,
    NameValue    = OldValueNode.NameValue,
    BooleanValue = OldValueNode.BooleanValue,
    NumericValue = OldValueNode.NumericValue,
    IntegerValue = OldValueNode.IntegerValue,
    TextValue    = OldValueNode.TextValue
FROM Nodes AS OldValueNode
WHERE OldValueNode.NodeID = _NewOldValueNodeID
AND CurValueNode.NodeID = _ValueNodeID
RETURNING TRUE INTO STRICT _OK;

-- SOURCE_CODE(OldOldValueNodeID) -1> VARIABLE(NewOldValueNodeID) -2-> VARIABLE(ValueNodeID) -3> LET_STATEMENT(CurrentNodeID)
-- SOURCE_CODE(OldOldValueNodeID) -1> VARIABLE(ValueNodeID) -3> LET_STATEMENT(CurrentNodeID)

DELETE FROM Edges WHERE ParentNodeID = _NewOldValueNodeID AND ChildNodeID = _ValueNodeID RETURNING TRUE INTO STRICT _OK;
UPDATE Edges SET ChildNodeID = _ValueNodeID WHERE ParentNodeID = _OldOldValueNodeID AND ChildNodeID = _NewOldValueNodeID RETURNING TRUE INTO STRICT _OK;

DELETE FROM Nodes WHERE NodeID = _NewOldValueNodeID RETURNING TRUE INTO STRICT _OK;

RETURN;
END;
$$;



CREATE OR REPLACE FUNCTION "TERNARY"                  (boolean, anyelement, anyelement)    RETURNS anyelement LANGUAGE sql AS $$ SELECT CASE WHEN $1 THEN $2 ELSE $3 END $$;
CREATE OR REPLACE FUNCTION "LOGICAL_OR"               (boolean, boolean)                   RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 OR $2                         $$;
CREATE OR REPLACE FUNCTION "LOGICAL_XOR"              (boolean, boolean)                   RETURNS boolean    LANGUAGE sql AS $$ SELECT NOT($1 AND $2)                   $$;
CREATE OR REPLACE FUNCTION "LOGICAL_AND"              (boolean, boolean)                   RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 AND $2                        $$;
CREATE OR REPLACE FUNCTION "LOGICAL_NOT"              (boolean)                            RETURNS boolean    LANGUAGE sql AS $$ SELECT NOT $1                           $$;
CREATE OR REPLACE FUNCTION "BITWISE_OR"               (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 | $2                          $$;
CREATE OR REPLACE FUNCTION "BITWISE_XOR"              (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 # $2                          $$;
CREATE OR REPLACE FUNCTION "BITWISE_AND"              (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 & $2                          $$;
CREATE OR REPLACE FUNCTION "EQUAL"                    (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 = $2                          $$;
CREATE OR REPLACE FUNCTION "NOT_EQUAL"                (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 <> $2                         $$;
CREATE OR REPLACE FUNCTION "LESS_THAN"                (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 < $2                          $$;
CREATE OR REPLACE FUNCTION "GREATER_THAN"             (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 > $2                          $$;
CREATE OR REPLACE FUNCTION "LESS_THAN_OR_EQUAL_TO"    (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 <= $2                         $$;
CREATE OR REPLACE FUNCTION "GREATER_THAN_OR_EQUAL_TO" (anyelement, anyelement)             RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 >= $2                         $$;
CREATE OR REPLACE FUNCTION "BITWISE_SHIFT_LEFT"       (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 << $2::integer                $$;
CREATE OR REPLACE FUNCTION "BITWISE_SHIFT_RIGHT"      (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 >> $2::integer                $$;
CREATE OR REPLACE FUNCTION "BETWEEN"                  (anyelement, anyelement, anyelement) RETURNS boolean    LANGUAGE sql AS $$ SELECT $1 BETWEEN $2 AND $3             $$;
CREATE OR REPLACE FUNCTION "SQUARE_ROOT"              (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT |/ $1                            $$;
CREATE OR REPLACE FUNCTION "CUBE_ROOT"                (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT ||/ $1                           $$;
CREATE OR REPLACE FUNCTION "FACTOR"                   (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 !                             $$;
CREATE OR REPLACE FUNCTION "ABS"                      (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT @ $1                             $$;
CREATE OR REPLACE FUNCTION "SUBTRACT"                 (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 - $2                          $$;
CREATE OR REPLACE FUNCTION "MULTIPLY"                 (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 * $2                          $$;
CREATE OR REPLACE FUNCTION "DIVIDE"                   (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 / $2                          $$;
CREATE OR REPLACE FUNCTION "MODULO"                   (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 % $2                          $$;
CREATE OR REPLACE FUNCTION "EXPONENT"                 (anyelement, anyelement)             RETURNS anyelement LANGUAGE sql AS $$ SELECT ($1 ^ $2)::integer                $$;
CREATE OR REPLACE FUNCTION "UNARY_MINUS"              (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT - $1                             $$;
CREATE OR REPLACE FUNCTION "UNARY_PLUS"               (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT + $1                             $$;
CREATE OR REPLACE FUNCTION "BITWISE_NOT"              (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT ~$1                              $$;
CREATE OR REPLACE FUNCTION "ARRAY_INDEX"              (anyarray, integer)                  RETURNS anyelement LANGUAGE sql AS $$ SELECT $1[$2]                           $$;
CREATE OR REPLACE FUNCTION "INCREMENT"                (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 + 1                           $$;
CREATE OR REPLACE FUNCTION "DECREMENT"                (anyelement)                         RETURNS anyelement LANGUAGE sql AS $$ SELECT $1 - 1                           $$;

*/