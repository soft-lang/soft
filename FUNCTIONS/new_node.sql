CREATE OR REPLACE FUNCTION soft.New_Node(
_NodeTypeID      integer,
_Literal         text      DEFAULT NULL,
_ValueType       regtype   DEFAULT NULL,
_Chars           integer[] DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO soft, public, pg_temp
AS $$
DECLARE
_NodeID          integer;
_NameValue       name;
_BooleanValue    boolean;
_NumericValue    numeric;
_IntegerValue    integer;
_TextValue       text;
_OK              boolean;
BEGIN

RAISE NOTICE '% % % %', _NodeTypeID, _Literal, _ValueType, _Chars;

IF (SELECT ValueType FROM NodeTypes WHERE NodeTypeID = _NodeTypeID) <> _ValueType THEN
    RAISE EXCEPTION 'ValueType % is different from NodeTypes.ValueType', _ValueType;
END IF;

IF _ValueType IS NULL THEN
    -- throw away _Literal
ELSIF _ValueType = 'name'::regtype THEN
    _NameValue := _Literal::name;
ELSIF _ValueType = 'numeric'::regtype THEN
    _NumericValue := _Literal::numeric;
ELSIF _ValueType = 'integer'::regtype THEN
    _IntegerValue := _Literal::integer;
ELSIF _ValueType = 'text'::regtype THEN
    _TextValue := _Literal::text;
ELSIF _ValueType = 'boolean'::regtype THEN
    _BooleanValue := _Literal::boolean;
ELSE
    RAISE EXCEPTION 'Unsupported ValueType %', _ValueType;
END IF;

INSERT INTO Nodes  ( NodeTypeID,  ValueType,  NameValue,  BooleanValue,  NumericValue,  IntegerValue,  TextValue,  Chars)
VALUES             (_NodeTypeID, _ValueType, _NameValue, _BooleanValue, _NumericValue, _IntegerValue, _TextValue, _Chars)
RETURNING    NodeID
INTO STRICT _NodeID;

RETURN _NodeID;
END;
$$;
