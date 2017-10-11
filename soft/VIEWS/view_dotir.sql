CREATE VIEW View_DOTIR AS
SELECT
lpad(
    DOTIR.DOTIRID::text,
    (SELECT MAX(LENGTH(DOTIRID::text)) FROM DOTIR),
    '0'
) AS DOTIRID,
Programs.Program,
Phases.Phase,
format('digraph {
dotir="%1$s";
rankdir=LR;
labelloc="t";
label="%2$s %3$s";
%4$s
}',
    replace(json_object(ARRAY[
        ['Program',          Programs.Program],
        ['Language',         Languages.Language],
        ['Phase',            Phases.Phase],
        ['Direction',        Programs.Direction::text],
        ['NodeID',           COALESCE(DOTIR.NodeID::text,'')]
    ])::text,'"','\"'),
    Programs.Program,
    Phases.Phase,
    DOTIR.DOTIR
) AS DOTIR
FROM DOTIR
INNER JOIN Programs ON Programs.ProgramID    = DOTIR.ProgramID
INNER JOIN Phases   ON Phases.PhaseID        = DOTIR.PhaseID
INNER JOIN Languages ON Languages.LanguageID = Programs.LanguageID
ORDER BY DOTIR.DOTIRID
;
