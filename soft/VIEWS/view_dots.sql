CREATE VIEW View_DOTs AS
SELECT
lpad(
    DOTs.DOTID::text,
    (SELECT MAX(LENGTH(DOTID::text)) FROM DOTs),
    '0'
) AS DOTID,
Programs.Program,
Phases.Phase,format('digraph {
rankdir=LR;
labelloc="t";
label="%s %s";
%s
}', Programs.Program, Phases.Phase, DOTs.DOT) AS DOT
FROM DOTs
INNER JOIN Programs ON Programs.ProgramID = DOTs.ProgramID
INNER JOIN Phases   ON Phases.PhaseID     = DOTs.PhaseID
ORDER BY DOTs.DOTID
;
