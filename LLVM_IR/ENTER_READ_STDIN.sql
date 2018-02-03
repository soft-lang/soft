CREATE OR REPLACE FUNCTION "LLVM_IR"."ENTER_READ_STDIN"(_NodeID integer)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
BEGIN
PERFORM Log(
    _NodeID   := _NodeID,
    _Severity := 'STDOUT',
    _Message  := format($IR$
; >ENTER_READ_STDIN %1$s
%%user_input%1$s     = call                  i32 @getchar()
%%user_input_i8_%1$s = trunc                 i32 %%user_input%1$s to i8
%%dataptr%1$s        = load                  i32,                    i32* %%dataptr_addr
%%element_addr%1$s   = getelementptr inbounds i8,                     i8* %%memory,          i32 %%dataptr%1$s
                       store                  i8 %%user_input_i8_%1$s, i8* %%element_addr%1$s
; <ENTER_READ_STDIN %1$s
$IR$, _NodeID)
);
RETURN;
END;
$$;
