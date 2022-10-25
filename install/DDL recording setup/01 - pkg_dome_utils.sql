CREATE OR REPLACE PACKAGE PKG_DOME_UTILS AS 


--object scripts
FUNCTION f_get_database_object_script(
    p_name varchar2,
    p_type varchar2,
    p_grants_yn varchar2 default 'N'
) RETURN clob;


FUNCTION f_get_app_component_script(
    p_app_no number,
    p_id number,
    p_type varchar2
) RETURN clob;


FUNCTION f_get_app_script(
    p_app_no number
) RETURN clob;


--object lists
FUNCTION f_get_objects_list(
    p_object_type varchar2  --values: ORDS
) RETURN PKG_DOME_INTERFACE.t_objects;

--lock page
FUNCTION f_page_locked_yn(
    p_app_number number,
    p_page_number number
) RETURN varchar2;


END PKG_DOME_UTILS;
/


CREATE OR REPLACE PACKAGE BODY PKG_DOME_UTILS AS

FUNCTION f_db_object_exists_yn(
    p_name varchar2,
    p_type varchar2
) RETURN varchar2 IS

    lcObjectExists varchar2(1);

BEGIN
    if p_type in ('DIRECTORY') then
        SELECT 'Y'
        INTO lcObjectExists
        FROM all_objects
        WHERE
            object_type = p_type
        AND object_name = p_name
        ;
    
    else
        SELECT 'Y'
        INTO lcObjectExists
        FROM user_objects
        WHERE
            object_type = p_type
        AND object_name = p_name
        ;
    
    end if;

    RETURN lcObjectExists;
    
EXCEPTION WHEN no_data_found THEN 
    RETURN 'N';
    
END f_db_object_exists_yn;




FUNCTION f_get_database_object_script(
    p_name varchar2,
    p_type varchar2,
    p_grants_yn varchar2 default 'N'
) RETURN clob AS

    lcScript clob;

    CURSOR c_grants IS
        SELECT 
            'GRANT ' || privilege || ' TO ' || grantee || ' ON ' || table_name || chr(10) || '/' || chr(10) as grant_script
        FROM user_tab_privs
        WHERE 
            type = p_type
        AND table_name = p_name
        AND owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
        ;

BEGIN
    if p_type = 'ORDS' then
        lcScript := ords_export.export_module(
            p_module_name => p_name
        );

    elsif p_type = 'DIRECTORY' then
        --TODO: fix script for directories
        RETURN null;
        
    else
        --if object doesn't exist (dropped or some other reason) just return empty script
        if f_db_object_exists_yn(p_name => p_name, p_type => p_type) = 'N' then
            RETURN null;
        end if;

        --used mostly for triggers to separate trigger ENABLE statement from trigger definition
        DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
        
        --main object script
        lcScript := dbms_metadata.get_ddl(
            object_type => 
                CASE p_type 
                    WHEN 'PACKAGE' THEN 'PACKAGE_SPEC'
                    WHEN 'PACKAGE BODY' THEN 'PACKAGE_BODY'
                    ELSE p_type
                END, 
            name => p_name
        );
        
        if p_grants_yn = 'Y' and p_type in ('PACKAGE', 'VIEW', 'TABLE') then
            lcScript := lcScript || chr(10) || chr(10);
        
            FOR t IN c_grants LOOP
                lcScript := lcScript || t.grant_script;
            END LOOP;
        end if;
        
    end if;
    
    RETURN lcScript;
    
END f_get_database_object_script;



FUNCTION f_get_app_component_script(
    p_app_no number,
    p_id number,
    p_type varchar2
) RETURN clob AS

    lrFiles apex_t_export_files;
    lcFileName apex_application_static_files.file_name%TYPE;

BEGIN
    --get files
    if p_type <> 'STATIC_APP_FILE' then  --classic components
    
        lrFiles := apex_export.get_application(
            p_application_id => p_app_no,
            p_split => false,
            --p_with_ir_public_reports => true,
            p_with_translations => true,
            p_with_comments => true,
            p_components => apex_t_varchar2( p_type || ':' || p_id )
        );

        RETURN lrFiles(lrFiles.first).contents;
        
    else  --static application files

        --get splitted application scripts
        lrFiles := apex_export.get_application(
            p_application_id => p_app_no,
            p_split => true,
            p_with_translations => true,
            p_with_comments => true
        );

        --get file name
        SELECT 
            lower(
                replace( replace(file_name, '/', '_'), '.', '_') 
            )
        INTO lcFileName
        FROM apex_application_static_files
        WHERE application_file_id = p_id
        ;

        --loop through static app files and pick script for selected static application file
        FOR t IN 1 .. lrFiles.count LOOP

            if instr(lrFiles(t).name, lcFileName || '.sql') > 0 then
                RETURN 
                    lrFiles(t).contents ||  
                    chr(10) ||
                    'BEGIN' || chr(10) || 
                    '    COMMIT;' || chr(10) || 
                    'END;' || chr(10) || 
                    '/';
            end if;
             
        END LOOP;
        
        RAISE_APPLICATION_ERROR( -20001, 'Script for static app file ' || lcFileName || ' not found! Please contact administrator.');
        
    end if;
    
END f_get_app_component_script;


FUNCTION f_get_app_script(
    p_app_no number
) RETURN clob IS

    l_files apex_t_export_files;

BEGIN
    --get files
    l_files := apex_export.get_application(
        p_application_id => p_app_no,
        p_split => false,
        --p_with_ir_public_reports => true,
        p_with_translations => true,
        p_with_comments => true
    );

    RETURN l_files(l_files.first).contents;

END f_get_app_script;



FUNCTION f_get_objects_list(
    p_object_type varchar2  --values: ORDS
) RETURN PKG_DOME_INTERFACE.t_objects IS

    lrList PKG_DOME_INTERFACE.t_objects := PKG_DOME_INTERFACE.t_objects();

BEGIN
    if p_object_type = 'ORDS' then
        SELECT 
            name 
        BULK COLLECT INTO lrList
        FROM user_ords_modules;
    end if;

    RETURN lrList;
END f_get_objects_list;



FUNCTION f_page_locked_yn(
    p_app_number number,
    p_page_number number
) RETURN varchar2 IS

    lcYesNo varchar2(1);

BEGIN
    SELECT
        CASE 
            WHEN EXISTS 
                (
                SELECT 1 
                FROM apex_application_locked_pages ap
                WHERE
                    ap.application_id = p_app_number
                AND ap.page_id = p_page_number
                )
            THEN 'Y'
            ELSE 'N'
        END
    INTO lcYesNo
    FROM dual;

    RETURN lcYesNo;
END f_page_locked_yn;


PROCEDURE p_lock_page(
    p_user varchar2,
    p_application_number number,
    p_page_number number,
    p_comment varchar2
) IS
BEGIN
    --TODO
    
    /*
    --==============================================================================
    -- Locks or updates an existing page lock. The result is returned
    -- with the following JSON structure:
    --
    -- { isUserOwner: true,   // only emitted in case of true
    --   owner:   "<string>", // only emitted if isUserOwner = flase
    --   on:      "<string">,
    --   comment: "<string>"
    -- }
    --
    --==============================================================================
    procedure lock_page (
        p_application_id in number,
        p_page_id        in number,
        p_comment        in varchar2 );
    */

/*
PROCEDURE LOCK_PAGE (
    P_APPLICATION_ID IN NUMBER,
    P_PAGE_ID        IN NUMBER,
    P_COMMENT        IN VARCHAR2 )
IS
    L_LOCK T_PAGE_LOCK;
BEGIN
    WWV_FLOW_DEBUG.ENTER(
        'lock_page',
        'p_application_id', P_APPLICATION_ID,
        'p_page_id',        P_PAGE_ID,
        'p_comment',        P_COMMENT );

    WWV_FLOW_JSON.INITIALIZE_OUTPUT (
        P_HTTP_CACHE => FALSE );

    L_LOCK := GET_PAGE_LOCK_STATE (
                  P_APPLICATION_ID => P_APPLICATION_ID,
                  P_PAGE_ID        => P_PAGE_ID );

    
    
    
    
    IF L_LOCK.LOCKED_BY IS NULL THEN

        INSERT INTO WWV_FLOW_LOCK_PAGE (
            FLOW_ID,
            OBJECT_ID,
            LOCK_COMMENT,
            LOCKED_BY,
            LOCKED_ON )
        VALUES (
            P_APPLICATION_ID,
            P_PAGE_ID,
            P_COMMENT,
            WWV_FLOW.G_USER,
            SYSDATE );

    ELSIF L_LOCK.LOCKED_BY = WWV_FLOW.G_USER THEN

        UPDATE WWV_FLOW_LOCK_PAGE
           SET LOCK_COMMENT = P_COMMENT
         WHERE FLOW_ID           = P_APPLICATION_ID
           AND OBJECT_ID         = P_PAGE_ID
           AND SECURITY_GROUP_ID = WWV_FLOW_SECURITY.G_SECURITY_GROUP_ID;

    END IF;

    
    EMIT_PAGE_LOCK_STATE (
        P_APPLICATION_ID => P_APPLICATION_ID,
        P_PAGE_ID        => P_PAGE_ID,
        P_OBJECT_NAME    => NULL );

END LOCK_PAGE;
*/
    
    null;
    
    --WWV_FLOW_PROPERTY_DEV.lock_page
END p_lock_page;

PROCEDURE p_unlock_page(
    p_user varchar2,
    p_application_number number,
    p_page_number number
) IS
BEGIN
    --TODO

/*
--==============================================================================
-- Unlocks the current page lock. The result is returned
-- with the following JSON structure:
--
-- { status: "OK" / "FAILED",
--   reason: "<error>"
-- }
--
--==============================================================================
procedure unlock_page (
    p_application_id in number,
    p_page_id        in number );

*/
    null;
    --WWV_FLOW_PROPERTY_DEV.unlock_page
END p_unlock_page;


END PKG_DOME_UTILS;

/

