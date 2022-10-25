SET DEFINE OFF;
--
-- TRG_DOME_BEFORE_DDL  (Trigger) 
--
CREATE OR REPLACE TRIGGER TRG_DOME_BEFORE_DDL
BEFORE CREATE OR ALTER OR DROP ON SCHEMA
DECLARE
    lcMessage varchar2(32000);

BEGIN
    lcMessage := pkg_dome_interface.f_allowed_to_compile(
        p_owner => ora_dict_obj_owner,
        p_object_name => ora_dict_obj_name,
        p_object_type => ora_dict_obj_type,
        p_event => ora_sysevent,  --CREATE or ALTER or DROP
        p_proxy_user => sys_context('USERENV','PROXY_USER')
    );
    
    if lcMessage is not null then
        RAISE_APPLICATION_ERROR(-20001, lcMessage);
    end if;

END trg_dome_before_ddl;
/


--
-- TRG_DOME_AFTER_DDL  (Trigger) 
--
CREATE OR REPLACE TRIGGER TRG_DOME_AFTER_DDL
AFTER ALTER OR CREATE OR DROP OR COMMENT ON SCHEMA
DECLARE
    
    lrScriptPieces ora_name_list_t;
    lnScriptPiecesCount pls_integer;
    lcScript clob;
    
BEGIN
    --get script pieces and merge it into one script (CLOB)
    lnScriptPiecesCount := ora_sql_txt(lrScriptPieces);
    
    FOR t IN 1 .. lnScriptPiecesCount LOOP
        lcScript := lcScript || lrScriptPieces(t);
    END LOOP;

    
    --call DOME interface
    pkg_dome_interface.p_add_object_to_patch(
        p_owner => ora_dict_obj_owner,
        p_object_name => ora_dict_obj_name,
        p_object_type => ora_dict_obj_type,
        p_event => ora_sysevent,
        p_script => lcScript,
        p_proxy_user => sys_context('USERENV','PROXY_USER')
    );

END trg_dome_after_ddl;
/
