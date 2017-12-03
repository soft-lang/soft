CREATE OR REPLACE FUNCTION Print_Node(
_NodeID         integer,
_RootNodeID     integer   DEFAULT NULL,
_VisitedEdgeIDs integer[] DEFAULT ARRAY[]::integer[]
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
_EdgeID         integer;
_ParentNodeID   integer;
_Message        text;
_PrimitiveValue text;
_NodeName       text;
_RefNodeName    text;

_FunctionName   text;
_Node           Nodes;
BEGIN

SELECT * INTO STRICT _Node FROM Nodes WHERE NodeID = _NodeID;

_PrimitiveValue := Primitive_Value(_NodeID);

IF _PrimitiveValue IS NOT NULL THEN
    _Message := _PrimitiveValue;
ELSIF Node_Type(Dereference(_NodeID)) = 'CLASS_DECLARATION' THEN
    _Message := COALESCE(
        Node_Name(Parent(Child(Dereference(_NodeID),'DECLARATION'),'VARIABLE'))::text,
        Node_Name(Dereference(_NodeID))::text || ' instance',
        format('Do not know how to print CLASS_DECLARATION NodeID %s', _NodeID)
    );
ELSIF Node_Type(Dereference(_NodeID)) = 'FUNCTION_DECLARATION' THEN
    _Message := COALESCE(
        '<fn ' || Node_Name(Parent(Child(Dereference(_NodeID),'DECLARATION'),'VARIABLE'))::text || '>',
        format('Do not know how to print FUNCTION_DECLARATION NodeID %s', _NodeID)
    );
ELSIF Orphan(_NodeID) THEN
    _Message := 'nil';
ELSE
    _Message := format('Do not know how to print NodeID %s', _NodeID);
END IF;

IF _Message IS NOT NULL THEN
    PERFORM Log(
        _NodeID   := _NodeID,
        _Severity := 'STDOUT',
        _Message  := _Message
    );
    RETURN;
END IF;

PERFORM Print_Node(
    _NodeID         := ParentNodeID,
    _RootNodeID     := COALESCE(_RootNodeID,_NodeID),
    _VisitedEdgeIDs := _VisitedEdgeIDs || EdgeID
)
FROM (
    SELECT
        Edges.EdgeID,
        Edges.ParentNodeID
    FROM Edges
    INNER JOIN Nodes AS ParentNode ON ParentNode.NodeID = Edges.ParentNodeID
    INNER JOIN Nodes AS ChildNode  ON ChildNode.NodeID  = Dereference(Edges.ChildNodeID)
    WHERE Edges.ChildNodeID    = _NodeID
    AND NOT Edges.EdgeID       = ANY(_VisitedEdgeIDs)
    AND Edges.DeathPhaseID      IS NULL
    AND ParentNode.DeathPhaseID IS NULL
    AND ChildNode.DeathPhaseID  IS NULL
    ORDER BY Edges.EdgeID
) AS X;

RETURN;
END;
$$;
