CREATE OR REPLACE FUNCTION BuiltIn(_NodeID integer, _ImplementationFunction text)
RETURNS text
LANGUAGE sql
AS $$
SELECT BuiltInFunctions.Identifier
FROM Nodes
INNER JOIN Programs         ON Programs.ProgramID          = Nodes.ProgramID
INNER JOIN BuiltInFunctions ON BuiltInFunctions.LanguageID = Programs.LanguageID
WHERE Nodes.NodeID                            = $1
AND   BuiltInFunctions.ImplementationFunction = $2
$$;
