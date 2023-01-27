SET DEFINE OFF;
--
-- PKG_APEX_150_11000  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_APEX_150_11000 AS
/******************************************************************************
   NAME:       PKG_APEX_150_11000
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27.11.2020      zoran       1. Created this package.
******************************************************************************/

FUNCTION f_get_script(
    p_table varchar2,
    p_filter_column varchar2,
    p_id number,
    p_source_column varchar2
) RETURN clob;


PROCEDURE p_save_script(
    p_table varchar2,
    p_filter_column varchar2,
    p_id number,
    p_source_column varchar2,
    p_text clob
);


END PKG_APEX_150_11000;
/


--
-- PKG_AUTH  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_auth AS
/******************************************************************************
   NAME:       pck_auth
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22.06.2018      ticaz       1. Created this package.
******************************************************************************/

FUNCTION f_login(
    p_username in varchar2,
    p_password in varchar2) RETURN boolean;

PROCEDURE post_auth(
    p_username in varchar2,
    out_user_id out number,
    out_user_display_name out varchar2);

PROCEDURE post_auth_db_account(
    p_username in varchar2,
    out_user_id out number,
    out_user_display_name out varchar2);



FUNCTION encrypt_password(p_password in varchar2) RETURN raw;

FUNCTION decrypt_password(p_username in varchar2) RETURN varchar2;

PROCEDURE p_change_pwd(
    p_username varchar2,
    p_new_password varchar2);

END pkg_auth;
/


--
-- PKG_CHECK  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_check IS

gcCollPatches varchar2(30) := 'CHK_PATCHES';
gcCollResults varchar2(30) := 'CHK_RESULTS';


FUNCTION f_coll_name(
    p_which varchar2  --values PATCHES or RESULTS
) RETURN varchar2;


PROCEDURE p_add_patch_to_coll(
    p_patch_id patches.patch_id%TYPE
);

PROCEDURE p_add_rls_patches_to_coll(
    p_release_id releases.release_id%TYPE
);


--patch IDs are stored in APEX collection gcCollPatches (n001)
--p_group_yn - if patches should be treated as a group (potential release)
PROCEDURE p_check_dependencies(
    p_target_env_id environments.environment_id%TYPE,
    p_group_yn varchar2
);


END pkg_check;
/


--
-- PKG_DECLARATIONS  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_declarations IS

SUBTYPE yes_no IS varchar2(1);

END pkg_declarations;
/



--
-- PKG_EXPORT_SOURCE  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_EXPORT_SOURCE AS 

PROCEDURE p_export_source(
    p_db_schemas varchar2,
    p_object_types varchar2
);

END PKG_EXPORT_SOURCE;
/


--
-- PKG_INTERFACE  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_interface AS


TYPE r_object IS RECORD (
    name varchar2(128)
);

TYPE t_objects IS TABLE OF r_object;



--user operations
PROCEDURE p_dome_login(
    p_username app_users.login_username%TYPE,
    p_password app_users.login_password%TYPE
);

PROCEDURE p_dome_logout;

FUNCTION f_dome_logged_user RETURN app_users.display_name%TYPE;


--objects operations
PROCEDURE p_add_object_to_patch(
    p_owner varchar2,
    p_object_name varchar2,
    p_object_type varchar2,
    p_event varchar2,  --CREATE or ALTER or DROP
    p_script clob,
    p_proxy_user varchar2 default null
);

--function checks if objects is allowed to compile/modify or not
--returns null if object is allowed to compile/modify
--returns error description if object is not allowed to compile/modify
FUNCTION f_allowed_to_compile(
    p_owner varchar2,
    p_object_name varchar2,
    p_object_type varchar2,
    p_event varchar2,  --CREATE or ALTER or DROP
    p_proxy_user varchar2
) RETURN varchar2;


--external systems (like OPAL tools) patch install start and stop
PROCEDURE p_ext_install_start(
    p_ext_system_code varchar2,
    p_ext_system_ref varchar2,
    p_reference varchar2,
    p_environment varchar2
);


PROCEDURE p_ext_install_stop(
    p_ext_system_code varchar2,
    p_ext_system_ref varchar2
);


END pkg_interface;
/


--
-- PKG_LOB_2_SCRIPT  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_lob_2_script IS

PROCEDURE p_generate_script(
    p_table varchar2,
    p_column varchar2,
    p_column_type varchar2,  --"C" for CLOB; "B" for BLOB
    p_where varchar2,
    p_blob_source varchar2,  --"PARAM" as p_file parameter, "APEX_VIEW" as single file from apex_application_temp_files view, "READ_FROM_TABLE" read from source table
    p_file blob default null
);

END pkg_lob_2_script;
/


--
-- PKG_OBJECTS  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_OBJECTS AS 


CURSOR c_data(p_object_id objects.object_id%TYPE) IS
SELECT
    o.filename,
    coalesce(
        v_dbo.db_schema_name,
        v_apc.app_schema_name,
        v_app.schema_name
    ) as db_schema,
    coalesce(
        v_apc.application_number,
        v_app.application_number
    ) as application_number,
    ot.target_folder,
    ot.source_folder
FROM
    objects o
    JOIN object_types ot ON o.object_type_id = ot.object_type_id
    LEFT JOIN v_database_objects v_dbo ON o.object_id = v_dbo.db_object_id
    LEFT JOIN v_app_components v_apc ON o.object_id = v_apc.app_component_id
    LEFT JOIN v_applications v_app ON o.object_id = v_app.application_id
WHERE o.object_id = p_object_id
;


FUNCTION f_get_object_id(
    p_parent_object_type varchar2,
    p_parent_object varchar2,
    p_object_type varchar2,
    p_object_name varchar2
) RETURN objects.object_id%TYPE
;


--database object file names
FUNCTION f_db_object_filename(
    p_name varchar2,
    p_type varchar2
) RETURN objects.filename%TYPE;

--source filename (with folder and chema name and app ID replace)
FUNCTION f_source_filename(
    p_object_id objects.object_id%TYPE
) RETURN varchar2;



--refresh object register
PROCEDURE p_refresh_database_objects(
    p_db_schemas objects.name%TYPE,  --database schemas
    p_object_types object_types.code%TYPE
);

PROCEDURE p_refresh_app_comp(
    p_app_ids varchar2  --application IDs (input is checkbox and string is : separated)
);



--create object
FUNCTION f_create_db_object(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2
) RETURN objects.object_id%TYPE;


FUNCTION f_exclude_from_record_yn(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_exclusion_type varchar2  --P (patch) or R (register)
) RETURN varchar2;



--object scripts
FUNCTION f_get_database_object_script(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_grants_yn varchar2 default 'N'
) RETURN clob;

FUNCTION f_get_app_component_script(
    p_app_no number,
    p_component_id number,
    p_type varchar2
) RETURN clob;

FUNCTION f_get_app_script(
    p_app_no number
) RETURN clob;

FUNCTION f_default_db_schema 
RETURN v_database_schemas.schema_name%TYPE;



--locks
PROCEDURE p_lock_object(
    p_object_id objects.object_id%TYPE,
    p_lock_type objects.lock_type%TYPE,
    p_comment objects.lock_comment%TYPE
);

PROCEDURE p_unlock_object(
    p_object_id objects.object_id%TYPE
);

FUNCTION f_is_object_locked_yn(
    p_object_id objects.object_id%TYPE,
    p_user_id app_users.app_user_id%TYPE
) RETURN varchar2;


FUNCTION f_who_locked_object(
    p_object_id objects.object_id%TYPE
) RETURN app_users.app_user_id%TYPE;


FUNCTION f_page_locked_in_apex_yn(
    p_object_id objects.object_id%TYPE
) RETURN varchar2;


END PKG_OBJECTS;
/


--
-- PKG_OBJECT_TYPES  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_object_types AS

--constants
cWorkspace object_types.code%TYPE := 'WORKSPACE';
cDbSchema object_types.code%TYPE := 'DB_SCHEMA';
cApplication object_types.code%TYPE := 'APP';


--logic
FUNCTION f_get_object_type_ID(
    p_object_type_code object_types.code%TYPE
) RETURN object_types.object_type_id%TYPE;


FUNCTION f_get_object_type_code(
    p_object_type_id object_types.object_type_id%TYPE
) RETURN object_types.code%TYPE;




FUNCTION f_get_record_as(
    p_object_type_id object_types.object_type_id%TYPE
) RETURN object_types.record_as%TYPE;

FUNCTION f_get_record_as(
    p_object_type_code object_types.code%TYPE
) RETURN object_types.record_as%TYPE;


FUNCTION f_get_record_as_obj_type_id(
    p_object_type_code object_types.code%TYPE
) RETURN object_types.object_type_id%TYPE;


END pkg_object_types;
/


--
-- PKG_PATCHES  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_PATCHES AS 

--patch ZIP filename
FUNCTION f_patch_filename(
    p_patch_id patches.patch_id%TYPE,
    p_extension varchar2 default null
) RETURN varchar2;



CURSOR c_patch(p_patch_id patches.patch_id%TYPE) IS
    SELECT
        v_p.patch_id,
        v_p.project_id,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '.zip') as filename,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '_src.zip') as src_filename,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '/') as root_folder,
        v_p.patch_code as patch_code,
        v_p.task_code_and_name || ' (' || v_p.patch_number || ')' as name,
        v_p.patch_template_id,
        pkg_patch_templates.f_get_procedure_name(patch_template_id) as patch_procedure_name
    FROM 
        v_patches v_p
    WHERE v_p.patch_id = p_patch_id
;


CURSOR c_patch_schemas (
    p_patch_id patches.patch_id%TYPE
) IS 
    SELECT DISTINCT 
        v_pso.schema_name as schema_name
    FROM v_patch_scr_and_obj v_pso
    WHERE 
        v_pso.patch_id = p_patch_id
    AND v_pso.object_as_patch_script_yn = 'N'
;

TYPE t_patch_schemas IS TABLE OF c_patch_schemas%ROWTYPE;



CURSOR c_patch_files (
    p_patch_id patches.patch_id%TYPE
) IS 
    SELECT
        v_pso.filename_replaced as filename,
        pkg_utils.f_clob_to_blob(v_pso.sql_content) as blob_file,
        v_pso.schema_name,
        CASE 
            WHEN v_pso.schema_name <> lag(v_pso.schema_name, 1, 'not existing one') over (order by v_pso.schema_name, v_pso.seq_nr, v_pso.filename) THEN 'Y' 
            ELSE 'N' 
        END as change_schema_yn
    FROM v_patch_scr_and_obj v_pso
    WHERE 
        v_pso.patch_id = p_patch_id
    AND v_pso.object_as_patch_script_yn = 'N'
    ORDER BY
        v_pso.schema_name,
        v_pso.seq_nr,
        v_pso.filename
;

TYPE t_patch_files IS TABLE OF c_patch_files%ROWTYPE;




--getters
FUNCTION f_get_project_id(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches.project_id%TYPE;


PROCEDURE p_confirm_patch(
    p_patch_id patches.patch_id%TYPE,
    p_user_confirmed_id patches.confirmed_app_user_id%TYPE
);

--unlock patch
FUNCTION f_unlock_patch_possible(
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2;

PROCEDURE p_unlock_patch(
    p_patch_id patches.patch_id%TYPE
);


PROCEDURE p_download_zip(
    p_patch_id patches.patch_id%TYPE
);



--on which environments is patch installed
FUNCTION f_installed_on(
    p_patch_id patches.patch_id%TYPE,
    p_separator varchar2 default chr(10)
) RETURN varchar2;



--user works on patch
PROCEDURE p_start_stop_working(
    p_user_id app_users.app_user_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_action varchar2  --START or STOP
);



--download ZIP file with object SQL source 
PROCEDURE p_download_source(
    p_patch_id patches.patch_id%TYPE
);




--warnings on patch
FUNCTION f_patch_warnings (
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2;


--move tasks to another task group
PROCEDURE p_move_tasks (
    p_new_group_id task_groups.task_group_id%TYPE 
);


END PKG_PATCHES;
/


--
-- PKG_PATCH_OBJECTS  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_PATCH_OBJECTS AS 

FUNCTION f_next_version(
    p_object_id objects.object_id%TYPE
) RETURN patch_objects.object_version%TYPE;




PROCEDURE p_add_object_to_patch(
    p_object_id objects.object_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_user_id app_users.app_user_id%TYPE,
    p_as_patch_script_yn patch_objects.as_patch_script_yn%TYPE DEFAULT 'N'
);


--function returns error message with patch name where object is already included
--returns null if object can be added to patch
FUNCTION f_object_in_another_patch_err(
    p_object_id objects.object_id%TYPE,
    p_current_patch_id patches.patch_id%TYPE
) RETURN varchar2;


END PKG_PATCH_OBJECTS;
/


--
-- PKG_PATCH_SCRIPTS  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_PATCH_SCRIPTS AS
/******************************************************************************
   NAME:       PKG_PATCH_SCRIPTS
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27.11.2020      zoran       1. Created this package.
******************************************************************************/


FUNCTION f_script_filename(
    p_patch_script_type_id patch_script_types.patch_script_type_id%TYPE,
    p_nr patch_scripts.order_by%TYPE
) RETURN varchar2;


PROCEDURE p_add_object_script(
    p_patch_id patches.patch_id%TYPE,
    p_owner varchar2,
    p_object_name varchar2,
    p_object_type varchar2,
    p_event varchar2,
    p_script clob,
    p_user_id app_users.app_user_id%TYPE,
    p_object_id objects.object_id%TYPE,
    p_prompt varchar2 default null
);


PROCEDURE p_refresh_object_script(
    p_patch_object_id patch_objects.patch_object_id%TYPE,
    p_commit_yn varchar2 default 'N'
);

PROCEDURE p_resequence_scripts(
    p_patch_id patches.patch_id%TYPE,
    p_start pls_integer,
    p_step pls_integer
);

END PKG_PATCH_SCRIPTS;
/


--
-- PKG_PATCH_TEMPLATES  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_patch_templates AS


CURSOR c_template_data (
    p_id number,
    p_patch_or_release varchar2
)
    IS
    SELECT 
        patch_template_id,
        project_name,
        task_code as code,
        task_code_and_name as name,
        user_created,
        'P_' || patch_id as id,
        '1.' || patch_number as version,
        user_comments,
        release_notes,
        filename_without_extension || '.zip' as filename,
        filename_without_extension || '/' as root_folder
    FROM v_patches
    WHERE 
        patch_id = p_id
    AND p_patch_or_release = 'P'
  UNION ALL 
    SELECT 
        patch_template_id,
        project as project_name,
        code as code,
        display as name,
        user_created_display_name as user_created,
        'R_' || release_id as id,
        '1.0' as version,
        null as user_comments,
        null as release_notes,
        code || '.zip' as filename,
        code || '/' as root_folder
    FROM v_releases
    WHERE 
        release_id = p_id
    AND p_patch_or_release = 'R'
;

CURSOR c_patch_template_files(p_patch_template_id patch_templates.patch_template_id%TYPE) IS
    SELECT
        file_name,
        file_content,
        usage_type
    FROM patch_template_files 
    WHERE 
        patch_template_id = p_patch_template_id
    AND usage_type <> 'N'  --N never used
;

TYPE t_patch_template_files IS TABLE OF c_patch_template_files%ROWTYPE;





--getters
FUNCTION f_get_procedure_name(
    p_patch_template_id patch_templates.patch_template_id%TYPE
) RETURN patch_templates.procedure_name%TYPE;

FUNCTION f_get_sql_subfolder(
    p_patch_template_id patch_templates.patch_template_id%TYPE
) RETURN patch_templates.sql_subfolder%TYPE;


--procedure for importing template files from ZIP
PROCEDURE p_parse_zip(
    p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_file_name varchar2
);


END pkg_patch_templates;
/


--
-- PKG_PROJECTS  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_projects AS

FUNCTION f_default_db_schema(
    p_project_id projects.project_id%TYPE
) RETURN project_database_schemas.object_id%TYPE;

FUNCTION f_default_db_schema(
    p_patch_id patches.patch_id%TYPE
) RETURN project_database_schemas.object_id%TYPE;


END pkg_projects;
/


--
-- PKG_RELEASES  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_RELEASES AS 


TYPE t_file IS RECORD (
    filename varchar2(4000),
    file_content blob
);

TYPE t_files IS TABLE OF t_file;


-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--getters
FUNCTION f_rls_code (
    p_release_id releases.release_id%TYPE
) RETURN releases.code%TYPE;



FUNCTION f_object_target_filename(
    p_object_id objects.object_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2;

FUNCTION f_script_target_filename(
    p_patch_script_id patch_scripts.patch_script_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2;



FUNCTION f_prepare_patch_files(
    p_patch_id patches.patch_id%TYPE,
    p_main_folder_name_prefix varchar2 default null 
) RETURN pkg_releases.t_files;

PROCEDURE p_prepare_patch_zip(
    p_patch_id patches.patch_id%TYPE,
    p_zip IN OUT blob,
    p_filename OUT varchar2
);



PROCEDURE p_download_rls_zip(
    p_release_id releases.release_id%TYPE,
    p_merge_files_yn varchar2 default 'N'
);



PROCEDURE p_download_report(
    p_release_id releases.release_id%TYPE,
    p_format varchar2  --MARKDOWN
);


FUNCTION f_script_filename(
    p_release_script_type_id release_script_types.rls_script_type_id%TYPE,
    p_nr release_scripts.order_by%TYPE
) RETURN release_scripts.filename%TYPE;


FUNCTION f_release_patches(
    p_release_id releases.release_id%TYPE
) RETURN varchar2;

END PKG_RELEASES;
/


--
-- PKG_SCRIPTS  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_scripts as

/*
This package is used to store procedures, which define scripts output for patches and releases.
Main procedure name for scripts output should be set in patch templates.
*/

PROCEDURE p_sqlplus_multiple_files_p (
    p_id number,  --patch or release ID
    p_patch_or_release varchar2,  --values PATCH or RELEASE
    p_files OUT pkg_releases.t_files
);



PROCEDURE p_sqlplus_release_p (
    p_id number,  --patch or release ID
    p_patch_or_release varchar2,  --values P or R
    p_files OUT pkg_releases.t_files
);

END pkg_scripts;
/


--
-- PKG_SETTINGS  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_settings AS

FUNCTION f_project_sett_vc2(
    p_project_id projects.project_id%TYPE,
    p_code r_settings.code%TYPE
) RETURN project_settings.value_vc2%TYPE
;


PROCEDURE p_set_value(
    p_project_id projects.project_id%TYPE,
    p_code r_settings.code%TYPE,
    p_vc2_value project_settings.value_vc2%TYPE default null,
    p_number_value project_settings.value_num%TYPE default null,
    p_date_value project_settings.value_date%TYPE default null
);


FUNCTION f_setting_hidden_yn(
    p_setting_id r_settings.setting_id%TYPE
) RETURN r_settings.hidden_yn%TYPE
;

END pkg_settings;
/


--
-- PKG_USERS  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_USERS AS 

FUNCTION f_display_name(
    p_app_user_id app_users.app_user_id%TYPE
) RETURN app_users.display_name%TYPE;


FUNCTION f_get_user_id(
    p_proxy_user app_users.proxy_user%TYPE
) RETURN app_users.app_user_id%TYPE;


FUNCTION f_user_works_on_patch_id(
    p_app_user_id app_users.app_user_id%TYPE
) RETURN patches.patch_id%TYPE;

END PKG_USERS;
/


--
-- PKG_UTILS  (Package) 
--
CREATE OR REPLACE PACKAGE PKG_UTILS AS 

FUNCTION f_clob_to_blob(
    c clob,
    plEncoding IN NUMBER default 0
) RETURN blob;

FUNCTION f_blob_to_clob(
    blob_in IN blob,
    plEncoding IN NUMBER default 0
) RETURN clob;



PROCEDURE p_download_document(
    p_doc IN OUT blob,
    p_file_name varchar2,
    p_disposition varchar2 default 'attachment'  --values "attachment" and "inline"
);

PROCEDURE p_download_document(
    p_text IN OUT clob,
    p_file_name varchar2,
    p_disposition varchar2 default 'attachment'  --values "attachment" and "inline"
);

PROCEDURE p_vc_arr2_to_apex_coll(
    p_app_coll wwv_flow_global.vc_arr2,
    p_apex_coll_name varchar2,
    p_n001_yn varchar2 default 'N'
);


END PKG_UTILS;
/


--
-- PKG_WRAP  (Package) 
--
CREATE OR REPLACE PACKAGE pkg_wrap IS

FUNCTION f_wrap(
    p_sql_source clob
) RETURN clob;


FUNCTION f_object_type_wrap_yn(
    p_project_id projects.project_id%TYPE,
    p_type_code object_types.code%TYPE
) RETURN varchar2;

PROCEDURE p_set_obj_type_wrap(
    p_project_id projects.project_id%TYPE,
    p_type_code object_types.code%TYPE,
    p_wrap_yn varchar2  --values Y or N
);

FUNCTION f_wrap_object_yn(
    p_object_id objects.object_id%TYPE,
    p_project_id  projects.project_id%TYPE
) RETURN varchar2
;


END pkg_wrap;
/

SET DEFINE OFF;
--
-- PKG_APEX_150_11000  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_APEX_150_11000 AS
/******************************************************************************
   NAME:       PKG_APEX_150_11000
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27.11.2020      zoran       1. Created this package body.
******************************************************************************/

FUNCTION f_get_script(
    p_table varchar2,
    p_filter_column varchar2,
    p_id number,
    p_source_column varchar2
) RETURN clob IS

    lcText clob;
    lcColumnType clob;
    lcScript varchar2(32000);

BEGIN
    SELECT data_type
    INTO lcColumnType
    FROM user_tab_columns
    WHERE 
        table_name = upper(p_table)
    AND column_name = upper(p_source_column)
    ;
    
    lcScript := 
    'SELECT ' || (CASE WHEN lcColumnType = 'BLOB' THEN 'pkg_utils.f_blob_to_clob(' || p_source_column || ')' ELSE p_source_column END) || 
    ' FROM ' || p_table || 
    ' WHERE ' || p_filter_column || ' = :1'
    ;
    
    apex_debug.message(lcScript);
    
    EXECUTE IMMEDIATE lcScript
    INTO lcText
    USING p_id;

    RETURN lcText;
END f_get_script;


PROCEDURE p_save_script(
    p_table varchar2,
    p_filter_column varchar2,
    p_id number,
    p_source_column varchar2,
    p_text clob
) IS
BEGIN
    EXECUTE IMMEDIATE
        'UPDATE ' || p_table ||
        ' SET ' || p_source_column || ' = :1 ' ||
        ' WHERE ' || p_filter_column || ' = :2'
    USING
        p_text,
        p_id
    ;

END p_save_script;


END PKG_APEX_150_11000;
/


--
-- PKG_AUTH  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_auth AS
/******************************************************************************
   NAME:       pck_auth
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22.06.2018      ticaz       1. Created this package body.
******************************************************************************/

lrKey raw(32) := UTL_RAW.CAST_TO_RAW('A1A2A3A4A5A6CAFE');


FUNCTION encrypt_password(p_password in varchar2) RETURN raw IS
    lbBlob blob;
BEGIN
    RETURN DBMS_CRYPTO.encrypt(UTL_RAW.CAST_TO_RAW(p_password), 4353, lrKey);
END;


FUNCTION decrypt_password(p_username in varchar2) RETURN varchar2 IS

    lrPwd raw(500);

BEGIN
    SELECT DBMS_CRYPTO.decrypt(login_password, 4353, lrKey)
    INTO lrPwd
    FROM app_users
    WHERE upper(login_username) = upper(p_username);

    RETURN UTL_RAW.cast_to_varchar2(lrPwd);
END;


FUNCTION f_login(
    p_username in varchar2,
    p_password in varchar2) RETURN boolean IS

    lcPwd varchar2(1000);

BEGIN
    if decrypt_password(p_username) <> p_password then
        RETURN false;
    end if;

    RETURN true;

EXCEPTION WHEN NO_DATA_FOUND THEN
    RETURN false;
END;


PROCEDURE post_auth(
    p_username in varchar2,
    out_user_id out number,
    out_user_display_name out varchar2) IS
BEGIN
    SELECT 
        app_user_id, 
        display_name
    INTO 
        out_user_id, 
        out_user_display_name
    FROM app_users
    WHERE upper(login_username) = upper(p_username);

END post_auth;


PROCEDURE post_auth_db_account(
    p_username in varchar2,
    out_user_id out number,
    out_user_display_name out varchar2) IS
BEGIN
    SELECT 
        app_user_id, 
        display_name
    INTO 
        out_user_id, 
        out_user_display_name
    FROM app_users
    WHERE upper(login_username) = upper(p_username);

END post_auth_db_account;


PROCEDURE p_change_pwd(
    p_username varchar2,
    p_new_password varchar2) IS
BEGIN
    UPDATE app_users
    SET login_password = encrypt_password(p_new_password)
    WHERE upper(login_username) = upper(p_username);

    COMMIT;
END;



END pkg_auth;
/


--
-- PKG_CHECK  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_check IS

FUNCTION f_coll_name(
    p_which varchar2  --values PATCHES or RESULTS
) RETURN varchar2 IS
BEGIN
    RETURN 
        CASE p_which 
            WHEN 'PATCHES' THEN gcCollPatches 
            ELSE gcCollResults 
        END;
END f_coll_name;


PROCEDURE p_add_patch_to_coll(
    p_patch_id patches.patch_id%TYPE
) IS
BEGIN
    --clear collection
    apex_collection.create_or_truncate_collection(gcCollPatches);
    
    --add patch to collection
    apex_collection.add_member(
        p_collection_name => gcCollPatches,
        p_n001 => p_patch_id
    );
    
END p_add_patch_to_coll;



PROCEDURE p_add_rls_patches_to_coll(
    p_release_id releases.release_id%TYPE
) IS
BEGIN
    --clear collection
    apex_collection.create_or_truncate_collection(gcCollPatches);
    
    --add release patches to collection
    FOR t IN (SELECT patch_id FROM patches WHERE release_id = p_release_id) LOOP
        apex_collection.add_member(
            p_collection_name => gcCollPatches,
            p_n001 => t.patch_id
        );
    END LOOP;
    
END p_add_rls_patches_to_coll;



PROCEDURE p_check_dependencies(
    p_target_env_id environments.environment_id%TYPE,
    p_group_yn varchar2
) IS

    --check patch objects
    CURSOR c_dependencies IS
        WITH v_pa_tc AS  --selected patches to check
            (
            SELECT ac.n001 as patch_id
            FROM apex_collections ac
            WHERE ac.collection_name = pkg_check.f_coll_name('PATCHES')
            ) 
        SELECT  --newer object version is already installed on target environment
            po_trg.object_id,
            v_p_src.patch_id as source_patch_id,
            v_p_trg.patch_id as target_patch_id,
            v_p_src.task_code_and_name || '_' || v_p_trg.patch_number as source_patch_name,
            v_obj.object_type,
            v_obj.object_name,
            po_src.object_version as src_object_version,
            'Newer version ' || 
                po_trg.object_version || 
                ' is already installed on target environment! Patch <a href="' || 
                apex_page.get_url(
                    p_page => 410,
                    p_items => 'P410_PATCH_ID',
                    p_values => v_p_trg.patch_id
                ) ||
                '">"' || 
                v_p_trg.task_code_and_name || 
                '_' ||
                v_p_trg.patch_number || 
                '"</a>'
            as description
        FROM 
            patch_objects po_src
            JOIN patch_objects po_trg ON po_src.object_id = po_trg.object_id
            JOIN v_patches v_p_src ON po_src.patch_id = v_p_src.patch_id
            JOIN v_patches v_p_trg ON po_trg.patch_id = v_p_trg.patch_id
            JOIN v_objects v_obj ON po_trg.object_id = v_obj.object_id
            JOIN v_pa_tc ON po_src.patch_id = v_pa_tc.patch_id
        WHERE
            po_src.as_patch_script_yn = 'N'
        AND EXISTS (SELECT 1 FROM patch_installs pi WHERE po_trg.patch_id = pi.patch_id AND pi.environment_id = p_target_env_id)
        AND po_src.object_version < po_trg.object_version
        UNION ALL 
        SELECT  --older object version is not installed on target environment
            po_trg.object_id,
            v_p_src.patch_id as source_patch_id,
            v_p_trg.patch_id as target_patch_id,
            v_p_src.task_code_and_name || '_' || v_p_trg.patch_number as source_patch_name,
            v_obj.object_type,
            v_obj.object_name,
            po_src.object_version as src_object_version,
            'Skipping versions! Older version ' || 
                po_trg.object_version || 
                ' is not installed on target environment! Patch <a href="' || 
                apex_page.get_url(
                    p_page => 410,
                    p_items => 'P410_PATCH_ID',
                    p_values => v_p_trg.patch_id
                ) ||
                '">"' || 
                v_p_trg.task_code_and_name || 
                '_' ||
                v_p_trg.patch_number || 
                '"</a>'
            as description
        FROM 
            patch_objects po_src
            JOIN patch_objects po_trg ON po_src.object_id = po_trg.object_id
            JOIN v_patches v_p_src ON po_src.patch_id = v_p_src.patch_id
            JOIN v_patches v_p_trg ON po_trg.patch_id = v_p_trg.patch_id
            JOIN v_objects v_obj ON po_trg.object_id = v_obj.object_id
            JOIN v_pa_tc ON po_src.patch_id = v_pa_tc.patch_id
        WHERE
            po_src.as_patch_script_yn = 'N'
        AND NOT EXISTS (SELECT 1 FROM patch_installs pi WHERE po_trg.patch_id = pi.patch_id AND pi.environment_id = p_target_env_id)
        AND --if selected patches are treated as a group do not check in-between dependencies - presumably they will be installed together on target environment
            (
            p_group_yn = 'N' OR
            po_trg.patch_id not in (SELECT patch_id FROM v_pa_tc)
            )
        AND po_src.object_version > po_trg.object_version
        ORDER BY
            object_type,
            object_name
        ;


    lrN001 apex_application_global.n_arr;
    lrN002 apex_application_global.n_arr;
    lrN003 apex_application_global.n_arr;
    lrC001 apex_application_global.vc_arr2;
    lrC002 apex_application_global.vc_arr2;
    lrC003 apex_application_global.vc_arr2;
    lrC004 apex_application_global.vc_arr2;
    lrC005 apex_application_global.vc_arr2;

BEGIN
    /*
    collection structure
    n001 - object ID
    n002 - source patch ID
    n003 - target patch ID
    c001 - source patch name
    c002 - object type
    c003 - object name
    c004 - object version
    c005 - dependency description
    */


    --fetch dependencies into arrays
    OPEN c_dependencies;
    FETCH c_dependencies BULK COLLECT INTO 
        lrN001,  --object_id
        lrN002,  --source_patch_id
        lrN003,  --target_patch_id
        lrC001,  --source_patch_name
        lrC002,  --object_type
        lrC003,  --object_name
        lrC004,  --src_object_version
        lrC005   --dependency_description
    ;
    CLOSE c_dependencies;


    --clear and fill collection
    apex_collection.create_or_truncate_collection(gcCollResults);

    apex_collection.add_members(
        p_collection_name => gcCollResults,
        p_n001 => lrN001,
        p_n002 => lrN002,
        p_n003 => lrN003,
        p_c001 => lrC001,
        p_c002 => lrC002,
        p_c003 => lrC003,
        p_c004 => lrC004,
        p_c005 => lrC005
    );
    
END p_check_dependencies;

END pkg_check;
/


--
-- PKG_EXPORT_SOURCE  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_EXPORT_SOURCE AS 

PROCEDURE p_prepare_zip(
    p_db_schemas varchar2,
    p_object_types varchar2,
    p_zip IN OUT blob
) IS

    CURSOR c_objects IS
        SELECT
            --filename
            dbo.owner || '/' || 
            lower(dbo.object_type) || '/' || 
            lower(dbo.object_name) || '.sql' as filename,
            dbo.owner,
            dbo.object_name,
            dbo.object_type as object_type
        FROM 
            dba_objects dbo
            JOIN ( SELECT column_value as owner FROM TABLE(apex_string.split(p_db_schemas, ':')) ) sch ON dbo.owner = sch.owner
            JOIN ( SELECT column_value as object_type FROM TABLE(apex_string.split(p_object_types, ':')) ) ot ON dbo.object_type = ot.object_type
        ;
    
    lbScript blob;
    
    leObjectNotFound exception;
    PRAGMA EXCEPTION_INIT(leObjectNotFound, -31603);
    
BEGIN
    FOR t IN c_objects LOOP
        BEGIN
            lbScript := pkg_utils.f_clob_to_blob(
                PKG_OBJECTS.f_get_database_object_script(
                    p_schema => t.owner,
                    p_name => t.object_name,
                    p_type => t.object_type,
                    p_grants_yn => 'Y'
                )
            );
        
        EXCEPTION WHEN leObjectNotFound THEN
            --if object doesn't exist then raise error
            --only package body is exception - package CAN be without body
            if t.object_type <> 'PACKAGE_BODY' then
                RAISE;
            end if;
        END;
        
        apex_zip.add_file(
            p_zipped_blob => p_zip, 
            p_file_name => t.filename,
            p_content => lbScript
        );
        
    END LOOP;
    
    apex_zip.finish(p_zip);
    
END p_prepare_zip;


PROCEDURE p_export_source(
    p_db_schemas varchar2,
    p_object_types varchar2
) AS

    lbZip blob;

BEGIN
    p_prepare_zip(
        p_db_schemas => p_db_schemas,
        p_object_types => p_object_types,
        p_zip => lbZip
    );
    
    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => 'scripts.zip'
    );
    
END p_export_source;



END PKG_EXPORT_SOURCE;
/


--
-- PKG_INTERFACE  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_interface AS

gnUserID app_users.app_user_id%TYPE;
gcUserDisplayName app_users.display_name%TYPE;


PROCEDURE p_dome_login(
    p_username app_users.login_username%TYPE,
    p_password app_users.login_password%TYPE
) IS
BEGIN
    if pkg_auth.f_login(p_username, p_password) then
        pkg_auth.post_auth(
            p_username => p_username,
            out_user_id => gnUserID,
            out_user_display_name => gcUserDisplayName
        );
    else
        RAISE_APPLICATION_ERROR(-20001, 'Login failed! Please check username and password!');
    end if;

END p_dome_login;

PROCEDURE p_dome_logout IS
BEGIN
    gnUserID := null;
    gcUserDisplayName := null;
END p_dome_logout;



FUNCTION f_dome_logged_user RETURN app_users.display_name%TYPE IS
BEGIN
    RETURN gcUserDisplayName;
END f_dome_logged_user;




PROCEDURE p_add_object_to_patch(
    p_owner varchar2,
    p_object_name varchar2,
    p_object_type varchar2,
    p_event varchar2,  --CREATE or ALTER or DROP
    p_script clob,
    p_proxy_user varchar2 default null
) IS

    lnObjectID objects.object_id%TYPE;
    lnPatchID patches.patch_id%TYPE;
    lcExcludeYn varchar2(1);

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --some object types and actions are not monitored
    if p_event = 'ALTER' and p_object_type = 'SUMMARY' then 
        RETURN;
    end if;

    --get object ID (if exists); if not -> create object
    if p_event <> 'COMMENT' then
        lnObjectID := pkg_objects.f_get_object_id(
            p_parent_object_type => 'DB_SCHEMA',
            p_parent_object => p_owner,
            p_object_type => p_object_type,
            p_object_name => p_object_name
        );

        if lnObjectID is null then
        
            --check if object should be excluded from recording into object register
            if pkg_objects.f_exclude_from_record_yn(
                p_schema => p_owner,
                p_name => p_object_name,
                p_type => p_object_type,
                p_exclusion_type => 'R'  --exclude from register
            ) = 'Y' then
                RETURN;
            end if;
        
            --add to object register
            lnObjectID := pkg_objects.f_create_db_object(
                p_schema => p_owner,
                p_name => p_object_name,
                p_type => p_object_type
            );
        end if;
    end if;


    --if proxy user is provided then determine app user
    if gnUserID is null and p_proxy_user is not null then
        gnUserID := pkg_users.f_get_user_id(
            p_proxy_user => p_proxy_user
        );
    end if; 


    --if user is not set then... nothing... just exit
    if gnUserID is null then
        RETURN;
    end if;
   

    --get a current patch for the user... if current patch is not set... then do nothing
    lnPatchID := pkg_users.f_user_works_on_patch_id(gnUserID);
    
    if lnPatchID is null then
        RETURN;
    end if;


    --TODO remove after testing
    /*
    zt_log.p_zabelezi_komentar(p_event || ' ' || p_object_type);
    zt_log.p_zabelezi_komentar('p_name: ' || p_object_name);
    zt_log.p_zabelezi_komentar(ascii(substr(p_script, -1)));
    zt_log.p_zabelezi_komentar(substr(p_script, 1, 4000));
    zt_log.p_zabelezi_komentar('Patch ID: ' || lnPatchID);
    RETURN;
    */

    
    --check if object should be excluded from recording into patch
    if pkg_objects.f_exclude_from_record_yn(
        p_schema => p_owner,
        p_name => p_object_name,
        p_type => p_object_type,
        p_exclusion_type => 'P'  --exclude from patch
    ) = 'Y' then
        RETURN;
    end if;
    
    
    --H A N D L E   D D L   A S   S C R I P T
    if pkg_object_types.f_get_record_as(p_object_type) = 'SCRIPT' or p_event <> 'CREATE' then
        pkg_patch_scripts.p_add_object_script(
            p_patch_id => lnPatchID,
            p_owner => p_owner,
            p_object_name => p_object_name,
            p_object_type => p_object_type,
            p_event => p_event,
            p_script => p_script,
            p_user_id => gnUserID,
            p_object_id => lnObjectID,
            p_prompt => 
                p_event || ' ' || 
                p_object_type || ' ' || 
                CASE WHEN p_event <>  'COMMENT' THEN p_object_name || ' ' ELSE null END || 
                'recorded on ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss') || ' by ' ||
                pkg_users.f_display_name(gnUserID)
        );
        
    else

    --H A N D L E   D D L   A S   O B J E C T
        pkg_patch_objects.p_add_object_to_patch(
            p_object_id => lnObjectID,
            p_patch_id => lnPatchID,
            p_user_id => gnUserID
        );
        
    end if;
    
    
    COMMIT;
    
END p_add_object_to_patch;


FUNCTION f_allowed_to_compile(
    p_owner varchar2,
    p_object_name varchar2,
    p_object_type varchar2,
    p_event varchar2,  --CREATE or ALTER or DROP
    p_proxy_user varchar2
) RETURN varchar2 IS

    lnObjectID objects.object_id%TYPE;
    lnCurrentPatchID patches.patch_id%TYPE;
    
    lcError varchar2(10000);
    
    lrObject v_database_objects%ROWTYPE;

BEGIN
    --get object ID
    lnObjectID := pkg_objects.f_get_object_id(
        p_parent_object_type => 'DB_SCHEMA',
        p_parent_object => p_owner,
        p_object_type => p_object_type,
        p_object_name => p_object_name
    );


    --if object exists in register -> check it
    if lnObjectID is not null then

        --if user is not already determined -> get user ID from proxy user name
        if gnUserID is null then
            gnUserID := pkg_users.f_get_user_id(
                p_proxy_user => p_proxy_user
            );
        end if;
        
        --get object data
        SELECT *
        INTO lrObject
        FROM v_database_objects
        WHERE db_object_id = lnObjectID;
    

        --check locked object: if current user differs from user who locked the object -> return error description
        if lrObject.lock_app_user_id <> nvl(gnUserID, -1) then
            lcError := 
                'Object ' || p_object_name ||
                ' is locked by ' || lrObject.lock_app_user_name ||
                ' (comment "' || lrObject.lock_comment || '")'
            ;
        end if;


        --if object is not locked and it is recorded as object (not script) -> check if object can be added to current user's patch
        if lcError is null and lrObject.record_as = 'OBJECT' then
        
            --current patch for user
            lnCurrentPatchID := pkg_users.f_user_works_on_patch_id(
                p_app_user_id => gnUserID
            );
            
            --if user works on some patch -> check if object is already included in another patch
            if lnCurrentPatchID is not null then
                --current patch for user
                lcError := pkg_patch_objects.f_object_in_another_patch_err(
                    p_object_id => lnObjectID,
                    p_current_patch_id => lnCurrentPatchID
                );
            end if;
        
        end if;

    end if;

    RETURN lcError;
    
END f_allowed_to_compile;



PROCEDURE p_ext_install_start(
    p_ext_system_code varchar2,
    p_ext_system_ref varchar2,
    p_reference varchar2,
    p_environment varchar2
) IS

    TYPE r_reference IS RECORD (
        ref_type varchar2(10),
        ref_id number
    );
    
    lrReference r_reference;
    leNotPatchOrRelease exception;
    leNoEnvironment exception;
    
    lnID number;
    lnEnvID environments.environment_id%TYPE;

    PRAGMA AUTONOMOUS_TRANSACTION;

    PROCEDURE p_add_install(
        p_environment_id patch_installs.environment_id%TYPE,
        p_patch_id patch_installs.patch_id%TYPE
    ) IS

        lrPatchInstall patch_installs%ROWTYPE;

    BEGIN
        lrPatchInstall.environment_id := p_environment_id;
        lrPatchInstall.patch_id := p_patch_id;
        lrPatchInstall.start_date := sysdate;
        lrPatchInstall.ext_system_code  := p_ext_system_code;
        lrPatchInstall.ext_system_ref  := p_ext_system_ref;
        
        INSERT INTO patch_installs VALUES lrPatchInstall;
    END p_add_install;

BEGIN
    --reference patch or release
    if substr(p_reference, 1, 2) not in ('P_', 'R_') then
        RAISE leNotPatchOrRelease;
    end if;
    

    --get reference type and ID from input parameter
    if p_reference is not null then
        lrReference.ref_type := substr(p_reference, 1, 1);
        lrReference.ref_id := substr(p_reference, 3);
    end if;
    
    --get environment
    BEGIN
        SELECT environment_id 
        INTO lnEnvID
        FROM environments 
        WHERE ext_code = p_environment;
        
    EXCEPTION WHEN no_data_found THEN
        RAISE leNoEnvironment;
        
    END;
    
    
    --check if reference exists
    BEGIN
        if lrReference.ref_type = 'P' then
            SELECT patch_id
            INTO lnID
            FROM patches
            WHERE patch_id = lrReference.ref_id;

            p_add_install(
                p_environment_id => lnEnvID,
                p_patch_id => lrReference.ref_id
            );
            
        elsif lrReference.ref_type = 'R' then
            SELECT release_id
            INTO lnID
            FROM releases
            WHERE release_id = lrReference.ref_id;
        
            --add install for all release's patches
            FOR t IN (SELECT patch_id FROM patches WHERE release_id = lrReference.ref_id) LOOP
            
                p_add_install(
                    p_environment_id => lnEnvID,
                    p_patch_id => t.patch_id
                );
                
            END LOOP;

        end if;
    
    EXCEPTION WHEN no_data_found THEN
        RAISE leNotPatchOrRelease;
        
    END;

    COMMIT;
    
EXCEPTION WHEN leNotPatchOrRelease or leNoEnvironment THEN
    RETURN;
    
END p_ext_install_start;



PROCEDURE p_ext_install_stop(
    p_ext_system_code varchar2,
    p_ext_system_ref varchar2
) IS

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    UPDATE patch_installs 
    SET end_date = sysdate
    WHERE
        ext_system_code = p_ext_system_code
    AND ext_system_ref = p_ext_system_ref;
    
    COMMIT;
    
END p_ext_install_stop;


END pkg_interface;
/


--
-- PKG_LOB_2_SCRIPT  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_lob_2_script IS


PROCEDURE p_generate_script(
    p_table varchar2,
    p_column varchar2,
    p_column_type varchar2,  --"C" for CLOB; "B" for BLOB
    p_where varchar2,
    p_blob_source varchar2,  --"PARAM" as p_file parameter, "APEX_VIEW" as single file from apex_application_temp_files view, "READ_FROM_TABLE" read from source table
    p_file blob default null
) IS

    lbBlob blob;
    lcClob clob;
    lrPieces apex_t_varchar2;
    
    PROCEDURE p_add(p_text varchar2 default null) IS
    BEGIN
        lcClob := lcClob || p_text || chr(10);
    END p_add;
    
BEGIN
    --get document
    if p_blob_source = 'READ_FROM_TABLE' then
        EXECUTE IMMEDIATE 'SELECT ' || p_column || ' FROM ' || p_table || ' WHERE ' || p_where
        INTO lbBlob;
        
    elsif p_blob_source = 'APEX_VIEW' then
        SELECT blob_content
        INTO lbBlob
        FROM apex_application_temp_files
        WHERE rownum = 1;
        
    elsif p_blob_source = 'PARAM' then
        lbBlob := p_file;
    end if;
    
    
    --encode to base64 and split into rows
    lcClob := replace( apex_web_service.blob2clobbase64(p_blob => lbBlob), chr(13) || chr(10), chr(10) );
    lrPieces := apex_string.split(lcClob);
    
    
    --P R E P A R E   S C R I P T
    --header
    lcClob := null;
    p_add('DECLARE');
    p_add;
    p_add('    lcClob clob;');
    p_add('    lbBlob blob;');
    p_add;
    
    p_add(q'[  function decode_base64(p_clob_in in clob) return blob is
    v_blob blob;
    v_result blob;
    v_offset integer;
    v_buffer_size binary_integer := 48;
    v_buffer_varchar varchar2(48);
    v_buffer_raw raw(48);
  begin
    if p_clob_in is null then
      return null;
    end if;
    dbms_lob.createtemporary(v_blob, true);
    v_offset := 1;
    for i in 1 .. ceil(dbms_lob.getlength(p_clob_in) / v_buffer_size) loop
      dbms_lob.read(p_clob_in, v_buffer_size, v_offset, v_buffer_varchar);
      v_buffer_raw := utl_raw.cast_to_raw(v_buffer_varchar);
      v_buffer_raw := utl_encode.base64_decode(v_buffer_raw);
      dbms_lob.writeappend(v_blob, utl_raw.length(v_buffer_raw), v_buffer_raw);
      v_offset := v_offset + v_buffer_size;
    end loop;
    v_result := v_blob;
    dbms_lob.freetemporary(v_blob);
    return v_result;
  end decode_base64;]');
    p_add;

    if p_column_type = 'C' then
        p_add(q'[  FUNCTION f_blob_to_clob(
    blob_in IN blob,
    plEncoding IN NUMBER default 0) RETURN clob IS

    v_clob Clob;
    v_in Pls_Integer := 1;
    v_out Pls_Integer := 1;
    v_lang Pls_Integer := 0;
    v_warning Pls_Integer := 0;
    v_id number(10);

BEGIN
    if blob_in is null then
        return null;
    end if;

    v_in:=1;
    v_out:=1;
    dbms_lob.createtemporary(v_clob,TRUE);
    DBMS_LOB.convertToClob(v_clob,
                           blob_in,
                           DBMS_lob.getlength(blob_in),
                           v_in,
                           v_out,
                           plEncoding,
                           v_lang,
                           v_warning);

    RETURN v_clob;

END f_blob_to_clob;]');
        p_add;
    end if;


    p_add('BEGIN');

    --lines
    FOR t in 1 .. lrPieces.count LOOP
        p_add('    lcClob := lcClob || ''' || lrPieces(t) || ''';');
    END LOOP;
    p_add;

    --convert back to blob
    p_add('    lbBlob := decode_base64(lcClob);');
    p_add;
    
    --update desired record
    p_add(
        '    UPDATE ' || p_table || 
        ' SET ' ||  p_column || ' = ' || 
        CASE p_column_type WHEN 'B' THEN 'lbBlob' ELSE 'f_blob_to_clob(lbBlob)' END || 
        ' WHERE ' || p_where || 
        ';'
    );
    p_add;

    --finish
    p_add('    COMMIT;');
    p_add;
    p_add('END;');
    p_add('/');

    
    --convert script to blob and download
    pkg_utils.p_download_document(
        p_text => lcClob,
        p_file_name => 'lob_doc.sql'
    );
    
END p_generate_script;


END pkg_lob_2_script;
/


--
-- PKG_OBJECTS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_OBJECTS AS


FUNCTION f_get_object_record(
    p_object_id objects.object_id%TYPE
) RETURN objects%ROWTYPE IS

    lrObject objects%ROWTYPE;

BEGIN
    SELECT *
    INTO lrObject
    FROM objects
    WHERE object_id = p_object_id;

    RETURN lrObject;
END f_get_object_record;



FUNCTION f_get_object_id(
    p_parent_object_type varchar2, --APPLICATION, DB_SCHEMA
    p_parent_object varchar2, --parent object marker - application number, schema name...
    p_object_type varchar2,
    p_object_name varchar2

) RETURN objects.object_id%TYPE IS

    lnID objects.object_id%TYPE;

BEGIN
    if p_parent_object_type = 'DB_SCHEMA' then
        SELECT v_dbo.db_object_id
        INTO lnID
        FROM 
            v_database_objects v_dbo
        WHERE
            nvl(v_dbo.db_schema_name, 'x') = nvl(p_parent_object, 'x')  --some objects are not on schema level... for example directory 
        AND v_dbo.db_object_name = p_object_name
        AND v_dbo.object_type_code = p_object_type
        ;
        
    elsif p_parent_object_type = 'APPLICATION' then
        SELECT v_apc.app_component_id 
        INTO lnID
        FROM
            v_app_components v_apc
        WHERE
            v_apc.application_number = p_parent_object
        AND v_apc.app_component_name = p_object_name
        AND v_apc.object_type_code = p_object_type
        ;
    
    end if;
    

    RETURN lnID;
    
EXCEPTION WHEN no_data_found THEN
    RETURN null;
    
END f_get_object_id;


FUNCTION f_db_object_filename(
    p_name varchar2,
    p_type varchar2
) RETURN objects.filename%TYPE IS
BEGIN
    RETURN
        lower(p_name) || (
            CASE p_type 
                WHEN 'PACKAGE' THEN '.pks' 
                WHEN 'PACKAGE BODY' THEN '.pkb' 
                ELSE '.sql' END
            )
    ;
END f_db_object_filename;

PROCEDURE p_refresh_database_objects(
    p_db_schemas objects.name%TYPE,  --database schemas
    p_object_types object_types.code%TYPE
) AS

    lrOrdsList pkg_interface.t_objects;

BEGIN
    --insert standard objects from DBA_OBJECTS view
    INSERT INTO objects (
        parent_object_id,
        object_type_id,
        name,
        filename
        )
    SELECT
        dbs.schema_id as db_schema_id,
        obt.object_type_id,
        upper(dbo.object_name) as object_name,
        pkg_objects.f_db_object_filename(
            p_name => dbo.object_name,
            p_type => dbo.object_type
        ) as filename
    FROM 
        all_objects dbo
        JOIN v_database_schemas dbs ON dbo.owner = dbs.schema_name
        JOIN object_types obt ON dbo.object_type = obt.code
    WHERE
        dbo.owner in ( SELECT column_value FROM TABLE(apex_string.split(p_db_schemas, ':')) )
    AND dbo.object_type in ( SELECT column_value FROM TABLE(apex_string.split(p_object_types, ':')) )
    AND not exists --only new objects
        (
        SELECT 1
        FROM v_database_objects v_dbo 
        WHERE 
            dbo.owner = v_dbo.db_schema_name
        AND upper(dbo.object_name) = upper(v_dbo.db_object_name)
        AND dbo.object_type = v_dbo.object_type_code
        )
    ;
    
    --mark dropped objects as inactive
    UPDATE objects
    SET active_yn = 'N'
    WHERE object_id in 
    (
    SELECT v_dbo.db_object_id
    FROM v_database_objects v_dbo
    WHERE 
        v_dbo.object_type_code <> 'ORDS'
    AND v_dbo.db_schema_name in ( SELECT column_value FROM TABLE(apex_string.split(p_db_schemas, ':')) )
    AND v_dbo.object_type_code in ( SELECT column_value FROM TABLE(apex_string.split(p_object_types, ':')) )
    AND v_dbo.active_yn = 'Y'
    AND NOT EXISTS 
        (
        SELECT 1 
        FROM all_objects dba_obj
        WHERE
            v_dbo.db_object_name = dba_obj.object_name
        AND v_dbo.object_type_code = dba_obj.object_type
        AND v_dbo.db_schema_name = dba_obj.owner
        )
    )
    ;
    
    
    --refresh ORDS (if selected)
    if instr(p_object_types, 'ORDS') > 0 then
        FOR t IN ( SELECT column_value as schema_name FROM TABLE(apex_string.split(p_db_schemas, ':')) ) LOOP
        
            EXECUTE IMMEDIATE 'BEGIN :1 := ' || t.schema_name || '.PKG_DOME_UTILS.f_get_objects_list(''ORDS''); END;'
            USING OUT lrOrdsList;
            
            --used FOR LOOP because INSERT INTO ... SELECT is throwing invalid datatype error???
            FOR p IN (
                SELECT
                    v_dbs.schema_id,
                    ot.object_type_id,
                    v_list.name as object_name,
                    lower(ot.code || '_' || v_list.name || '.sql') as filename
                FROM 
                    table( lrOrdsList ) v_list
                    JOIN v_database_schemas v_dbs ON v_dbs.schema_name = t.schema_name
                    JOIN object_types ot ON ot.code = 'ORDS'
                    LEFT JOIN v_database_objects v_dbo ON 
                            v_dbo.db_object_name = v_list.name
                        AND v_dbo.object_type_code = ot.code
                        AND v_dbo.db_schema_name = t.schema_name
                WHERE v_dbo.db_object_id is null  --only new objects
            ) LOOP
            
                INSERT INTO objects (
                    parent_object_id,
                    object_type_id,
                    name,
                    filename
                ) VALUES (
                    p.schema_id,
                    p.object_type_id,
                    p.object_name,
                    p.filename
                );
            
            END LOOP;
            
        END LOOP;
        
    end if;
    
    
END p_refresh_database_objects;


PROCEDURE p_refresh_app_comp(
    p_app_ids varchar2  --application IDs
) AS
BEGIN
    --merge into for all selected applications
    MERGE INTO objects obj
    USING (
        --app components
        SELECT 
            vju.id, 
            vju.name, 
            ot.object_type_id,
            v_app.application_id,
            ob.object_id,
            lower(ot.code) || '_' || v_app.application_number || '_' || vju.id || '.sql' as filename
        FROM 
            apex_appl_export_comps vju
            JOIN object_types ot ON vju.type_name = ot.code AND ot.object_location = 'APP'
            JOIN v_applications v_app ON vju.application_id = v_app.application_number
            LEFT JOIN objects ob ON 
                    ob.parent_object_id = v_app.application_id
                AND ob.object_type_id = ot.object_type_id
                AND ob.aa_number_01 = vju.id
            JOIN ( SELECT to_number(column_value) as app_id FROM TABLE(apex_string.split(p_app_ids, ':')) ) flt ON v_app.application_id = flt.app_id
        UNION ALL  --static application files (not included in app components view)
        SELECT 
            aasf.application_file_id as id,
            aasf.file_name as name,
            ot.object_type_id,
            v_app.application_id,
            vju.object_id,
            lower(ot.code) || '_' || aasf.application_id || '_' || aasf.application_file_id || '.sql' as filename
        FROM 
            apex_application_static_files aasf
            JOIN (SELECT to_number(column_value) as app_id FROM TABLE(apex_string.split('400', ':')) ) flt ON aasf.application_id = flt.app_id
            JOIN v_applications v_app ON aasf.application_id = v_app.application_number 
            CROSS JOIN (SELECT object_type_id, code FROM object_types WHERE code = 'STATIC_APP_FILE') ot
            LEFT JOIN 
            (
            SELECT 
                ob.object_id,
                ob.aa_number_01
            FROM 
                objects ob
                JOIN object_types ot ON ob.object_type_id = ot.object_type_id
            WHERE 
                ot.code = 'STATIC_APP_FILE'
            ) vju ON aasf.application_file_id = vju.aa_number_01 
    ) v
    ON (obj.object_id = v.object_id)
    WHEN NOT MATCHED THEN INSERT (object_type_id, name, filename, parent_object_id, aa_number_01) 
        VALUES (
            v.object_type_id, 
            v.name, 
            v.filename,
            v.application_id,
            v.id
            )
    WHEN MATCHED THEN UPDATE SET 
        obj.name = v.name,
        obj.filename = v.filename
    ;
    
    
    --mark missing componentes (presumably deleted from applications) as inactive
    UPDATE objects
    SET active_yn = 'N'
    WHERE object_id in 
        (
        SELECT 
            v_apc.app_component_id
        FROM 
            v_app_components v_apc
            JOIN (SELECT to_number(column_value) as app_id FROM TABLE(apex_string.split('400', ':')) ) flt ON v_apc.application_number = flt.app_id
        WHERE 
            v_apc.object_type_code <> 'STATIC_APP_FILE'
        AND v_apc.active_yn = 'Y'
        AND NOT EXISTS 
            (
            SELECT 1 
            FROM apex_appl_export_comps apex_comp
            WHERE 
                v_apc.app_component_number = apex_comp.id
            AND v_apc.application_number = apex_comp.application_id
            AND v_apc.object_type_code = apex_comp.type_name
            )
        )
    ;

END p_refresh_app_comp;




FUNCTION f_create_db_object(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2
) RETURN objects.object_id%TYPE IS

    lrObject objects%ROWTYPE;

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --get object type and schema
    BEGIN
        SELECT object_type_id
        INTO lrObject.object_type_id 
        FROM object_types
        WHERE 
            code = p_type
        AND object_location = 'DB'
        ;
    EXCEPTION WHEN no_data_found THEN
        RAISE_APPLICATION_ERROR(-20001, 'Object type ' || p_type || ' is not found in register!');
    END;
    

    --If database object is not linked to database schema... no problem. Just don't assign object to schema.
     --Example is database directory.
    BEGIN
        SELECT schema_id
        INTO lrObject.parent_object_id
        FROM v_database_schemas
        WHERE schema_name = p_schema;
        
    EXCEPTION WHEN no_data_found THEN
        lrObject.parent_object_id := null;
    END;

    --name and filename
    lrObject.name := upper(p_name);
    lrObject.filename := pkg_objects.f_db_object_filename(
        p_name => p_name,
        p_type => p_type
    )
    ;
    
    lrObject.active_yn := 'Y';
    
    INSERT INTO objects 
    VALUES lrObject
    RETURNING object_id INTO lrObject.object_id
    ;

    COMMIT;

    RETURN lrObject.object_id;
END f_create_db_object;


FUNCTION f_exclude_from_record_yn(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_exclusion_type varchar2  --P (patch) or R (register)
) RETURN varchar2 IS

    CURSOR c_exclude_pattern IS
        SELECT exclude_yes_no
        FROM 
            (
            SELECT
                'Y' as exclude_yes_no
            FROM 
                exclude_from_recording efr
                LEFT JOIN v_database_schemas v_dbs ON efr.db_schema_id = v_dbs.schema_id
                LEFT JOIN object_types ot ON efr.object_type_id = ot.object_type_id
            WHERE
                (efr.db_schema_id is null OR p_schema is null OR v_dbs.schema_name = p_schema)  --schema
            AND (efr.object_type_id is null OR ot.code = p_type)  --object
            AND 
                --naming pattern
                (
                    efr.like_or_regexp is null 
                OR  (efr.like_or_regexp = 'L' AND p_name like efr.naming_pattern)
                OR  (efr.like_or_regexp = 'R' AND regexp_like(p_name, efr.naming_pattern) )
                )
            AND
                --from patch or register
                (
                    (p_exclusion_type = 'R' AND efr.from_register_yn = 'Y')
                OR  (p_exclusion_type = 'P' AND efr.from_patch_yn = 'Y')
                )
            )
        WHERE 
            exclude_yes_no = 'Y'
        AND rownum = 1
        ;

    lrExclude c_exclude_pattern%ROWTYPE;

BEGIN
    --get data
    OPEN c_exclude_pattern;
    FETCH c_exclude_pattern INTO lrExclude;
    CLOSE c_exclude_pattern;
    
    --if no record fetched then do not exclude object
    lrExclude.exclude_yes_no := nvl( lrExclude.exclude_yes_no, 'N');
    
    
    RETURN lrExclude.exclude_yes_no;
    
END f_exclude_from_record_yn;



FUNCTION f_get_database_object_script(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_grants_yn varchar2 default 'N'
) RETURN clob AS

    lcScript clob;

BEGIN
    EXECUTE IMMEDIATE 
        'BEGIN :script := ' || nvl(p_schema, pkg_objects.f_default_db_schema) || '.pkg_dome_utils.f_get_database_object_script(:name, :type, :grants_yn); END;' 
    USING 
        OUT lcScript,
        IN p_name, 
        IN p_type, 
        IN p_grants_yn
    ;
    
    RETURN lcScript;
END f_get_database_object_script;



FUNCTION f_get_app_component_script(
    p_app_no number,
    p_component_id number,
    p_type varchar2
) RETURN clob AS

    lcShema v_database_schemas.schema_name%TYPE;
    lcScript clob;

    lrFiles apex_t_export_files;
    
    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --schema name, from which application component script will be requested
    SELECT schema_name
    INTO lcShema
    FROM v_applications
    WHERE application_number = p_app_no
    ;

    --get component script
    if lcShema is not null then

        EXECUTE IMMEDIATE 
            'BEGIN :script := ' || lcShema || '.pkg_dome_utils.f_get_app_component_script(:app_no, :component_id, :type); END;' 
        USING OUT lcScript, IN p_app_no, IN p_component_id, IN p_type;

    else

        lrFiles := apex_export.get_application(
            p_application_id => p_app_no,
            p_split => false,
            --p_with_ir_public_reports => true,
            p_with_translations => true,
            p_with_comments => true,
            p_components => apex_t_varchar2( p_type || ':' || p_component_id )
        );
    
        lcScript := lrFiles(lrFiles.first).contents;
    end if;

    RETURN lcScript;
    
END f_get_app_component_script;



FUNCTION f_get_app_script(
    p_app_no number
) RETURN clob AS

    lcShema v_database_schemas.schema_name%TYPE;
    lcScript clob;

    lrFiles apex_t_export_files;

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --schema name, from which application component script will be requested
    SELECT schema_name
    INTO lcShema
    FROM v_applications
    WHERE application_number = p_app_no
    ;

    --get component script
    if lcShema is not null then

        EXECUTE IMMEDIATE 
            'BEGIN :script := ' || lcShema || '.pkg_dome_utils.f_get_app_script(:app_no); END;' 
        USING 
            OUT lcScript,
            IN p_app_no
        ;

    else

        lrFiles := apex_export.get_application(
            p_application_id => p_app_no,
            p_split => false,
            --p_with_ir_public_reports => true,
            p_with_translations => true,
            p_with_comments => true
        );
    
        lcScript := lrFiles(lrFiles.first).contents;
    end if;

    RETURN lcScript;
    
END f_get_app_script;



FUNCTION f_source_filename(
    p_object_id objects.object_id%TYPE
) RETURN varchar2 IS

    lrData pkg_objects.c_data%ROWTYPE;
    lcFilename varchar2(1000);
    
BEGIN
    --get data
    OPEN pkg_objects.c_data(p_object_id);
    FETCH pkg_objects.c_data INTO lrData;
    CLOSE pkg_objects.c_data;
    
    lcFilename := replace(lrData.source_folder, '#SCHEMA#', lower( nvl(lrData.db_schema, pkg_objects.f_default_db_schema) ) );
    lcFilename := replace(lcFilename, '#APP_ID#', lower(lrData.application_number) );
    
    lcFilename := lcFilename || '/' || lrData.filename;
    
    RETURN lcFilename;
        
END f_source_filename;



FUNCTION f_is_object_locked_yn(
    p_object_id objects.object_id%TYPE,
    p_user_id app_users.app_user_id%TYPE
) RETURN varchar2 IS
BEGIN
    RETURN CASE WHEN f_get_object_record(p_object_id).lock_type = 'E' THEN 'Y' ELSE 'N' END;
END f_is_object_locked_yn;


FUNCTION f_who_locked_object(
    p_object_id objects.object_id%TYPE
) RETURN app_users.app_user_id%TYPE IS
BEGIN
    RETURN f_get_object_record(p_object_id).lock_app_user_id;
END f_who_locked_object;


PROCEDURE p_lock_object(
    p_object_id objects.object_id%TYPE,
    p_lock_type objects.lock_type%TYPE,
    p_comment objects.lock_comment%TYPE
) IS
BEGIN
    UPDATE objects
    SET
        lock_type = p_lock_type, 
        lock_app_user_id = nv('APP_LOGGED_USER_ID'),
        lock_date = sysdate, 
        lock_comment = p_comment
    WHERE object_id = p_object_id;

END p_lock_object;


PROCEDURE p_unlock_object(
    p_object_id objects.object_id%TYPE
) IS
BEGIN
    UPDATE objects
    SET
        lock_type = null, 
        lock_app_user_id = null,
        lock_date = null, 
        lock_comment = null
    WHERE object_id = p_object_id;

END p_unlock_object;


FUNCTION f_page_locked_in_apex_yn(
    p_object_id objects.object_id%TYPE
) RETURN varchar2 IS

    lrRecord v_app_components%ROWTYPE;
    lcYesNo varchar2(1);

BEGIN
    --schema name, from which application component script will be requested
    SELECT *
    INTO lrRecord
    FROM v_app_components
    WHERE app_component_id = p_object_id
    ;

    --get component script
    if lrRecord.app_schema_name is not null then

        EXECUTE IMMEDIATE 
            'SELECT ' || lrRecord.app_schema_name || '.pkg_dome_utils.f_page_locked_yn(:1, :2) FROM dual' 
        INTO lcYesNo
        USING lrRecord.application_number, lrRecord.app_component_number;

    else

        SELECT
            CASE 
                WHEN EXISTS 
                    (
                    SELECT 1 
                    FROM apex_application_locked_pages ap
                    WHERE
                        ap.application_id = lrRecord.application_number
                    AND ap.page_id = lrRecord.app_component_number
                    )
                THEN 'Y'
                ELSE 'N'
            END
        INTO lcYesNo
        FROM dual;

    end if;

    RETURN lcYesNo;

END f_page_locked_in_apex_yn;


FUNCTION f_default_db_schema 
RETURN v_database_schemas.schema_name%TYPE IS
BEGIN
    --TODO: make a parameter
    RETURN 'MBA';
END f_default_db_schema;


END PKG_OBJECTS;
/


--
-- PKG_OBJECT_TYPES  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_object_types AS

FUNCTION f_get_object_type_by_id(
    p_object_type_id object_types.object_type_id%TYPE
) RETURN object_types%ROWTYPE AS

    lrRecord object_types%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRecord
    FROM object_types
    WHERE object_type_id = p_object_type_id;
    
    RETURN lrRecord;
END f_get_object_type_by_id;

FUNCTION f_get_object_type_by_code(
    p_object_type_code object_types.code%TYPE
) RETURN object_types%ROWTYPE AS

    lrRecord object_types%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRecord
    FROM object_types
    WHERE code = p_object_type_code;
    
    RETURN lrRecord;
END f_get_object_type_by_code;


FUNCTION f_get_object_type_code(
    p_object_type_id object_types.object_type_id%TYPE
) RETURN object_types.code%TYPE AS
BEGIN
    RETURN f_get_object_type_by_id(p_object_type_id).code;
END f_get_object_type_code;



FUNCTION f_get_object_type_ID(
    p_object_type_code object_types.code%TYPE
) RETURN object_types.object_type_id%TYPE AS
BEGIN
    RETURN f_get_object_type_by_code(p_object_type_code).object_type_id;
END f_get_object_type_ID;



FUNCTION f_get_record_as(
    p_object_type_id object_types.object_type_id%TYPE
) RETURN object_types.record_as%TYPE AS
BEGIN
    RETURN f_get_object_type_by_id(p_object_type_id).record_as;
END f_get_record_as;

FUNCTION f_get_record_as(
    p_object_type_code object_types.code%TYPE
) RETURN object_types.record_as%TYPE AS
BEGIN
    RETURN f_get_object_type_by_code(p_object_type_code).record_as;
EXCEPTION WHEN no_data_found THEN
    RETURN 'no data';
END f_get_record_as;




FUNCTION f_get_record_as_obj_type_id(
    p_object_type_code object_types.code%TYPE
) RETURN object_types.object_type_id%TYPE AS
BEGIN
    if f_get_object_type_by_code(p_object_type_code).record_as_object_type_id is not null then
        RETURN f_get_object_type_by_code(p_object_type_code).record_as_object_type_id;
    else
        RETURN f_get_object_type_by_code(p_object_type_code).object_type_id;
    end if;
END f_get_record_as_obj_type_id;




END pkg_object_types;
/


--
-- PKG_PATCHES  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_PATCHES AS 


FUNCTION f_get_v_patch(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches%ROWTYPE IS

    lrPatch v_patches%ROWTYPE;

BEGIN
    SELECT *
    INTO lrPatch
    FROM v_patches
    WHERE patch_id = p_patch_id;

    RETURN lrPatch;
END f_get_v_patch;


PROCEDURE p_confirm_patch(
    p_patch_id patches.patch_id%TYPE,
    p_user_confirmed_id patches.confirmed_app_user_id%TYPE
) AS

    CURSOR c_object_scripts IS
        SELECT *
        FROM v_patch_obj_src_scripts
        WHERE patch_id = p_patch_id
    ;

BEGIN
    --get patch object scripts
    FOR t IN c_object_scripts LOOP
        
        UPDATE patch_objects
        SET 
            sql_content = t.object_script,
            object_version = t.next_version
        WHERE patch_object_id = t.patch_object_id
        ;
        
    END LOOP;


    --mark patch as confirmed
    UPDATE patches
    SET
        confirmed_on = sysdate,
        confirmed_app_user_id = p_user_confirmed_id
    WHERE patch_id = p_patch_id;
    
    --stop working on patch (if anyone is currently working on it)
    UPDATE user_works_on_patch 
    SET stop = sysdate
    WHERE
        patch_id = p_patch_id
    AND stop is null;
    
    
END p_confirm_patch;



PROCEDURE p_unlock_patch(
    p_patch_id patches.patch_id%TYPE
) AS
BEGIN
    --mark patch as not confimed
    UPDATE patches
    SET
        confirmed_on = null,
        confirmed_app_user_id = null
    WHERE patch_id = p_patch_id
    ;

    --set patch objects version to null (will be again set to next value when patch is confirmed)
    UPDATE patch_objects po
    SET po.object_version = null
    WHERE po.patch_id = p_patch_id
    ;

END p_unlock_patch;



PROCEDURE p_download_zip(
    p_patch_id patches.patch_id%TYPE
) AS

    lbZip blob;
    lcFilename varchar2(1000);

BEGIN
    --get ZIP
    pkg_releases.p_prepare_patch_zip(
        p_patch_id => p_patch_id,
        p_zip => lbZip,
        p_filename => lcFilename
    );
    
    --download document
    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => lcFilename
    );
END p_download_zip;





FUNCTION f_installed_on(
    p_patch_id patches.patch_id%TYPE,
    p_separator varchar2 default chr(10)
) RETURN varchar2 AS

    lcInstalledOn varchar2(32000);

BEGIN
    SELECT 
        listagg(env.code || ': ' || to_char(pi.start_date, 'dd.mm.yyyy hh24:mi'), p_separator ) within group (order by pi.end_date)
    INTO lcInstalledOn
    FROM 
        patch_installs pi
        JOIN environments env ON pi.environment_id = env.environment_id
    WHERE 
        pi.patch_id = p_patch_id
    AND pi.end_date is not null
    ;

    RETURN lcInstalledOn;
END f_installed_on;


FUNCTION f_unlock_patch_possible(
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2 AS

    --objects
    CURSOR c_objects IS
        WITH w_max AS (
            SELECT 
                vju.object_id,
                vju.object_version as max_version,
                vju.max_patch_data
            FROM
                (
                SELECT 
                    po.object_id,
                    po.patch_id,
                    po.object_version,
                    v_p.task_name || ' (' || v_p.patch_number || '); owned by ' || v_p.user_owner as max_patch_data,
                    row_number() over (partition by po.object_id order by po.object_version desc) as rbr
                FROM 
                    patch_objects po
                    JOIN v_patches v_p ON po.patch_id = v_p.patch_id
                    JOIN patch_objects curr_patch ON po.object_id = curr_patch.object_id AND curr_patch.patch_id = p_patch_id
                ) vju
            WHERE 
                vju.rbr = 1
        )
        SELECT 
            (CASE 
                WHEN v_dbo.db_object_id is not null THEN v_dbo.object_type_name || ' - ' || v_dbo.display
                WHEN v_apc.app_component_id is not null THEN v_apc.object_type_name || ' - ' || v_apc.display
                WHEN v_app.application_id is not null THEN v_app.display
            ELSE 'unknown' END) as obj_name,
            po.object_version,
            w_max.max_version,
            w_max.max_patch_data
        FROM 
            patch_objects po 
            JOIN w_max ON po.object_id = w_max.object_id
            LEFT JOIN v_database_objects v_dbo ON po.object_id = v_dbo.db_object_id
            LEFT JOIN v_app_components v_apc ON po.object_id = v_apc.app_component_id
            LEFT JOIN v_applications v_app ON po.object_id = v_app.application_id
        WHERE
            po.patch_id = p_patch_id
        AND w_max.max_version > po.object_version
        ;

    lcObjects varchar2(32000);

BEGIN
    FOR t IN c_objects LOOP
        lcObjects := lcObjects || '- ' || t.obj_name || '; newer version ' || t.max_version || ' in patch ' || t.max_patch_data || '<br>';
    END LOOP;

    RETURN lcObjects;
END f_unlock_patch_possible;



PROCEDURE p_start_stop_working(
    p_user_id app_users.app_user_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_action varchar2  --START or STOP
) IS
BEGIN
    --stop work on all patches on which then user is working
    UPDATE user_works_on_patch 
    SET stop = sysdate
    WHERE
        app_user_id = p_user_id
    AND stop is null;
    
    --if action is START then start working on a patch
    if p_action = 'START' then
        INSERT INTO user_works_on_patch(app_user_id, patch_id)
        VALUES (p_user_id, p_patch_id)
        ;
    end if;

END p_start_stop_working;



FUNCTION f_patch_filename(
    p_patch_id patches.patch_id%TYPE,
    p_extension varchar2 default null
) RETURN varchar2 IS

    lcFilename varchar2(1000);

    CURSOR c_patch IS
    SELECT
        regexp_replace(
            replace( substr(v_p.task_code || '_' || v_p.patch_number || ' - ' || v_p.task_name, 1, 100), '"', null),
            '[/\:*?<>]',
            '_'
        )
        || p_extension as filename
    FROM v_patches v_p
    WHERE v_p.patch_id = p_patch_id;

BEGIN
    --patch data
    OPEN c_patch;
    FETCH c_patch INTO lcFilename;
    CLOSE c_patch;

    RETURN lcFilename;
END f_patch_filename;



PROCEDURE p_download_source(
    p_patch_id patches.patch_id%TYPE
) IS

    CURSOR c_patch_files IS
        --objects
        SELECT
            v_src.source_filename,
            pkg_utils.f_clob_to_blob(v_src.object_script) as blob_file
        FROM v_patch_obj_src_scripts v_src
        WHERE v_src.patch_id = p_patch_id
        ;

    lrPatch pkg_patches.c_patch%ROWTYPE;
    lbZip blob;

BEGIN
    --patch data
    OPEN pkg_patches.c_patch(p_patch_id);
    FETCH pkg_patches.c_patch INTO lrPatch;
    CLOSE pkg_patches.c_patch;
    

    --files
    FOR t IN c_patch_files LOOP
        apex_zip.add_file(
            p_zipped_blob => lbZip, 
            p_file_name => t.source_filename,
            p_content => t.blob_file
        );
    END LOOP;
    
    
    --finish ZIP and download document
    apex_zip.finish(lbZip);

    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => lrPatch.src_filename
    );
    
END p_download_source;


FUNCTION f_get_project_id(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches.project_id%TYPE IS
BEGIN
    RETURN f_get_v_patch(p_patch_id).project_id;
END f_get_project_id;




FUNCTION f_patch_warnings (
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2 IS

    lnCount pls_integer;
    lcWarning varchar2(32000);

    PROCEDURE p_add (
        p_text varchar2,
        p_separator varchar2 default chr(10)
    ) IS
    BEGIN
        lcWarning := lcWarning || p_text || p_separator;
    END p_add;

BEGIN
    --Is patch empty? Are there any scripts and objects in patch?
    SELECT count(*)
    INTO lnCount
    FROM 
        (
        SELECT 1
        FROM patch_scripts 
        WHERE patch_id = p_patch_id
        UNION ALL
        SELECT 1
        FROM patch_objects 
        WHERE patch_id = p_patch_id
        )
    ;
    
    if lnCount = 0 then
        p_add('Patch is empty');
    end if;
    
    RETURN lcWarning;
    
END f_patch_warnings;


PROCEDURE p_move_tasks (
    p_new_group_id task_groups.task_group_id%TYPE 
) IS
BEGIN
    UPDATE tasks
    SET task_group_id = p_new_group_id
    WHERE 
        task_id in 
            (SELECT to_number(c001) FROM apex_collections WHERE collection_name = 'SELECTED_TASKS_COLL')
    ;
END p_move_tasks;

END PKG_PATCHES;
/


--
-- PKG_PATCH_OBJECTS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_PATCH_OBJECTS AS

FUNCTION f_next_version(
    p_object_id objects.object_id%TYPE
) RETURN patch_objects.object_version%TYPE AS

    lnNextVersion patch_objects.object_version%TYPE;

BEGIN
    SELECT nvl( max(object_version), 0) + 1
    INTO lnNextVersion
    FROM patch_objects
    WHERE object_id = p_object_id;

    RETURN lnNextVersion;
END f_next_version;



PROCEDURE p_add_object_to_patch(
    p_object_id objects.object_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_user_id app_users.app_user_id%TYPE,
    p_as_patch_script_yn patch_objects.as_patch_script_yn%TYPE DEFAULT 'N'
) IS
BEGIN
    MERGE INTO patch_objects pa
    USING (
        SELECT
            p_patch_id as patch_id,
            p_object_id as object_id,
            p_user_id as app_user_id,
            p_as_patch_script_yn as as_patch_script_yn
        FROM dual
    ) vju
    ON (
        pa.patch_id = vju.patch_id AND pa.object_id = vju.object_id
    )
    WHEN NOT MATCHED THEN INSERT (
        patch_id, 
        object_id, 
        app_user_id,
        as_patch_script_yn)
    VALUES (
        vju.patch_id,
        vju.object_id,
        vju.app_user_id,
        vju.as_patch_script_yn
    )
    ;
    
END p_add_object_to_patch;



FUNCTION f_object_in_another_patch_err(
    p_object_id objects.object_id%TYPE,
    p_current_patch_id patches.patch_id%TYPE
) RETURN varchar2 IS

    lcError varchar2(10000);

BEGIN
    SELECT 'Object ' || v_o.object_name || ' (' || v_o.object_type || ') is already included in patch "' || v_p.display || '"'
    INTO lcError
    FROM 
        patch_objects po
        JOIN v_patches v_p ON po.patch_id = v_p.patch_id
        JOIN v_objects v_o ON po.object_id = v_o.object_id
    WHERE 
        po.object_id = p_object_id
    AND v_p.confirmed_yn = 'N'
    AND po.patch_id <> p_current_patch_id
    AND po.patch_id not in  --linked patches are ignored
        (
        SELECT patch2_id
        FROM linked_patches
        WHERE patch1_id = p_current_patch_id
        UNION ALL
        SELECT patch1_id
        FROM linked_patches
        WHERE patch2_id = p_current_patch_id
        )
    ;

    RETURN lcError;

EXCEPTION WHEN no_data_found THEN
    RETURN null;

END f_object_in_another_patch_err;


END PKG_PATCH_OBJECTS;
/


--
-- PKG_PATCH_SCRIPTS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_PATCH_SCRIPTS AS
/******************************************************************************
   NAME:       PKG_PATCH_SCRIPTS
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27.11.2020      zoran       1. Created this package body.
******************************************************************************/

FUNCTION f_script_filename(
    p_patch_script_type_id patch_script_types.patch_script_type_id%TYPE,
    p_nr patch_scripts.order_by%TYPE
) RETURN varchar2 IS

    lcFilename varchar2(100);

BEGIN
    SELECT 
        lower(pst.code) || '_' || to_char(p_nr, 'fm000') || '.sql' as file_name
    INTO lcFilename
    FROM patch_script_types pst
    WHERE 
        pst.patch_script_type_id = p_patch_script_type_id
    ;

    RETURN lcFilename;
    
END f_script_filename;


PROCEDURE p_add_object_script(
    p_patch_id patches.patch_id%TYPE,
    p_owner varchar2,
    p_object_name varchar2,
    p_object_type varchar2,
    p_event varchar2,
    p_script clob,
    p_user_id app_users.app_user_id%TYPE,
    p_object_id objects.object_id%TYPE,
    p_prompt varchar2 default null
) IS

    lrScriptRecord patch_scripts%ROWTYPE;
    lcAction varchar2(10);
    lcDebug varchar2(4000);

BEGIN
    --get patch script record
    BEGIN
        SELECT *
        INTO lrScriptRecord
        FROM
            (
            SELECT ps.*
            FROM 
                patch_scripts ps
                JOIN patch_script_types pst ON ps.patch_script_type_id = pst.patch_script_type_id
            WHERE
                ps.patch_id = p_patch_id
            AND 
            (
                (
                    p_event in ('CREATE', 'ALTER', 'DROP')
                AND ps.object_type_id = pkg_object_types.f_get_record_as_obj_type_id(p_object_type_code => p_object_type)
                )
                OR
                (
                    p_event not in ('CREATE', 'ALTER', 'DROP')
                AND pst.code = 'OTHER_DDL'
                )
            )
            ORDER BY ps.order_by desc 
            )
        WHERE rownum = 1;
        
        lcAction := 'UPDATE';

    EXCEPTION WHEN no_data_found THEN
        --if script doesn't exist - create one
        lrScriptRecord.patch_id := p_patch_id;
        lrScriptRecord.added_on := sysdate;
        lrScriptRecord.app_user_id := p_user_id;

        if p_event in ('CREATE', 'ALTER', 'DROP') then
            lrScriptRecord.object_type_id := pkg_object_types.f_get_record_as_obj_type_id(p_object_type_code => p_object_type);
        end if;

        SELECT nvl( max(order_by), 0) + 1
        INTO lrScriptRecord.order_by
        FROM patch_scripts 
        WHERE patch_id = p_patch_id
        ;
        
        BEGIN
            SELECT v_dbs.schema_id
            INTO lrScriptRecord.database_schema_id
            FROM v_database_schemas v_dbs
            WHERE v_dbs.schema_name = p_owner;
        
        --some object types (for example directories) don't belong to specific schema (owner)
        --in that case set default schema for patch script
        EXCEPTION WHEN no_data_found THEN
            lrScriptRecord.database_schema_id := 
                pkg_projects.f_default_db_schema(
                    p_patch_id => p_patch_id
                )
            ;
            
        END;
        
        SELECT pst.patch_script_type_id
        INTO lrScriptRecord.patch_script_type_id
        FROM patch_script_types pst
        WHERE
            pst.code = CASE WHEN p_event in ('CREATE', 'ALTER', 'DROP') THEN 'DDL' ELSE 'OTHER_DDL' END
        ;

        lrScriptRecord.filename := f_script_filename(
            p_patch_script_type_id => lrScriptRecord.patch_script_type_id,
            p_nr => lrScriptRecord.order_by
        );
        
        lcAction := 'INSERT';
    END;
    
    --add script to patch script
    lrScriptRecord.sql_content := 
        lrScriptRecord.sql_content || 
        CASE WHEN lcAction = 'UPDATE' THEN chr(10) || chr(10) ELSE null END || 
        CASE WHEN p_prompt is not null THEN 'PROMPT ' || p_prompt || chr(10) ELSE null END || 
        substr(p_script, 1, length(p_script) - 1) || chr(10) ||  --substr is removing ASCII 0 character from the end
        CASE WHEN substr(p_script, -1) <> '/' THEN '/' ELSE null END
    ;
    
    --insert or update patch script record
    if lcAction = 'INSERT' then
        INSERT INTO patch_scripts VALUES lrScriptRecord
        ;
        
    elsif lcAction = 'UPDATE' then
        UPDATE patch_scripts
        SET sql_content = lrScriptRecord.sql_content
        WHERE patch_script_id = lrScriptRecord.patch_script_id
        ;
        
    end if;

    
    --mark object as changed
    if p_event in ('CREATE', 'ALTER', 'DROP') then
        pkg_patch_objects.p_add_object_to_patch(
            p_object_id => p_object_id,
            p_patch_id => p_patch_id,
            p_user_id => p_user_id,
            p_as_patch_script_yn => 'Y'
        );
    end if;

END p_add_object_script;



PROCEDURE p_refresh_object_script(
    p_patch_object_id patch_objects.patch_object_id%TYPE,
    p_commit_yn varchar2 default 'N'
) IS

    lrObject v_patch_obj_src_scripts%ROWTYPE;

BEGIN
    --get object data
    SELECT *
    INTO lrObject
    FROM v_patch_obj_src_scripts v_pos
    WHERE v_pos.patch_object_id = p_patch_object_id
    ;

    --update patch script
    UPDATE patch_objects 
    SET sql_content = lrObject.object_script
    WHERE patch_object_id = p_patch_object_id
    ;

    --commit if selected
    if p_commit_yn = 'Y' then
        COMMIT;
    end if;
    
END p_refresh_object_script;


PROCEDURE p_resequence_scripts(
    p_patch_id patches.patch_id%TYPE,
    p_start pls_integer,
    p_step pls_integer
) IS

    CURSOR c_scripts IS
        SELECT
            patch_script_id,
            order_by
        FROM patch_scripts 
        WHERE patch_id = p_patch_id
        ORDER BY order_by;

    TYPE t_scripts IS TABLE OF c_scripts%ROWTYPE;
    lrScripts t_scripts;

    lnCounter pls_integer := p_start;

BEGIN
    --fetch data
    OPEN c_scripts;
    FETCH c_scripts BULK COLLECT INTO lrScripts;
    CLOSE c_scripts;
    
    --resequence
    FOR t IN 1 .. lrScripts.count LOOP
        lrScripts(t).order_by := lnCounter;
        lnCounter := lnCounter + p_step;
    END LOOP;

    --set previous order by as negative values so no unique constraints should happen
    UPDATE patch_scripts 
    SET order_by = - order_by
    WHERE patch_id = p_patch_id
    ;

    --store data back to table
    FORALL t IN 1 .. lrScripts.count
        UPDATE patch_scripts 
        SET order_by = lrScripts(t).order_by
        WHERE patch_script_id = lrScripts(t).patch_script_id
    ;

END p_resequence_scripts;


END PKG_PATCH_SCRIPTS;
/


--
-- PKG_PATCH_TEMPLATES  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_patch_templates AS


FUNCTION f_get_patch_template(
    p_patch_template_id patch_templates.patch_template_id%TYPE
) RETURN patch_templates%ROWTYPE IS
    lrRecord patch_templates%ROWTYPE;
BEGIN
    SELECT *
    INTO lrRecord
    FROM patch_templates
    WHERE patch_template_id = p_patch_template_id;
    
    RETURN lrRecord;
END f_get_patch_template;


FUNCTION f_get_procedure_name(
    p_patch_template_id patch_templates.patch_template_id%TYPE
) RETURN patch_templates.procedure_name%TYPE IS
BEGIN
    RETURN f_get_patch_template(p_patch_template_id).procedure_name;
END f_get_procedure_name;


FUNCTION f_get_sql_subfolder(
    p_patch_template_id patch_templates.patch_template_id%TYPE
) RETURN patch_templates.sql_subfolder%TYPE IS
BEGIN
    RETURN f_get_patch_template(p_patch_template_id).sql_subfolder;
END f_get_sql_subfolder;





PROCEDURE p_parse_zip(
    p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_file_name varchar2
) IS

    lrFile apex_application_temp_files%ROWTYPE;
    lrFiles apex_zip.t_files;
    
BEGIN
    --if file is not selected then... do nothing
    if p_file_name is null then
        null;
    end if;

    --get uploaded ZIP file
    SELECT *
    INTO lrFile
    FROM apex_application_temp_files
    WHERE 
        application_id = nv('APP_ID')
    AND name = p_file_name
    ;

    --get files from ZIP and add it to patch
    lrFiles := apex_zip.get_files(
        p_zipped_blob => lrFile.blob_content
    );
    
    DELETE FROM patch_template_files 
    WHERE patch_template_id = p_patch_template_id;
    
    FOR t IN 1 .. lrFiles.count LOOP
        INSERT INTO patch_template_files (
            file_name, 
            patch_template_id, 
            file_content)
        VALUES (
            lrFiles(t),
            p_patch_template_id,
            apex_zip.get_file_content(
                p_zipped_blob => lrFile.blob_content,
                p_file_name   => lrFiles(t)
            )
        );
    END LOOP;
    
END p_parse_zip;


END pkg_patch_templates;
/


--
-- PKG_PROJECTS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_projects AS

FUNCTION f_default_db_schema(
    p_project_id projects.project_id%TYPE
) RETURN project_database_schemas.object_id%TYPE IS

    lcDefaultSchemaID project_database_schemas.object_id%TYPE;

BEGIN
    --get default schema
    SELECT object_id
    INTO lcDefaultSchemaID
    FROM project_database_schemas
    WHERE 
        project_id = p_project_id
    AND default_yn = 'Y'
    AND rownum = 1
    ;
    
    RETURN lcDefaultSchemaID;
    
END f_default_db_schema;


FUNCTION f_default_db_schema(
    p_patch_id patches.patch_id%TYPE
) RETURN project_database_schemas.object_id%TYPE IS
BEGIN
    RETURN 
        f_default_db_schema(
            p_project_id => pkg_patches.f_get_project_id(p_patch_id)
        )
    ;
END f_default_db_schema;

END pkg_projects;
/


--
-- PKG_RELEASES  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_RELEASES AS 

CURSOR c_doc_part_texts(p_release_id releases.release_id%TYPE) IS
    SELECT 
        rdp.placeholder,
        rdpt.part_text
    FROM 
        release_doc_part_txt rdpt 
        JOIN release_doc_parts rdp ON rdpt.release_doc_part_id = rdp.release_doc_part_id
    WHERE rdpt.release_id = p_release_id
    ;

TYPE t_doc_part_texts IS TABLE OF c_doc_part_texts%ROWTYPE;


CURSOR c_release_tasks(p_release_id releases.release_id%TYPE) IS
    SELECT
        t.code || ' - ' || t.name as code_and_name,
        t.external_link,
        count(*) as no_of_patches
    FROM 
        patches p
        JOIN tasks t ON p.task_id = t.task_id
    WHERE p.release_id = p_release_id
    GROUP BY 
        t.code,
        t.name,
        t.external_link
    ORDER BY 1
    ;

TYPE t_release_tasks IS TABLE OF c_release_tasks%ROWTYPE;


CURSOR c_release_objects(p_release_id releases.release_id%TYPE) IS
SELECT
    v_po.object_id,
    v_po.schema_name,
    v_po.object_group,
    v_po.object_type,
    v_po.object_name,
    listagg(v_p.patch_code, ', ') within group (order by v_po.object_version) as included_in_patches
FROM 
    v_patches v_p
    JOIN v_patch_scr_and_obj v_po ON v_p.patch_id = v_po.patch_id
WHERE 
    v_p.release_id = p_release_id
AND v_po.object_group <> 'PATCH_SCRIPT'
GROUP BY
    v_po.object_id,
    v_po.schema_name,
    v_po.object_group,
    v_po.object_type,
    v_po.object_name
ORDER BY 
    v_po.object_group,
    v_po.object_type,
    v_po.object_name
;


TYPE t_release_objects IS TABLE OF c_release_objects%ROWTYPE;


FUNCTION f_get_release(
    p_release_id releases.release_id%TYPE
) RETURN releases%ROWTYPE IS

    lrRelease releases%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRelease
    FROM releases
    WHERE release_id = p_release_id
    ;

    RETURN lrRelease;
END f_get_release;


FUNCTION f_rls_code (
    p_release_id releases.release_id%TYPE
) RETURN releases.code%TYPE IS
BEGIN
    RETURN f_get_release(p_release_id).code;
END f_rls_code;



PROCEDURE p_add(
    p_script IN OUT clob,
    p_text_to_add varchar2,
    p_separator varchar2 default chr(10)
) IS
BEGIN
    p_script := p_script || p_text_to_add || p_separator;
END p_add;



PROCEDURE p_enable_disable_apps(
    p_script IN OUT clob,
    p_zip IN OUT blob,
    p_patch pkg_patches.c_patch%ROWTYPE,
    p_enable_or_disable varchar2  --values "ENABLE" or "DISABLE"
) IS

    lcEnDisScript clob;
    lcFileName varchar2(1000);
    lcAppsExist varchar2(1);

BEGIN
    --check if there are any apps to be disabled; if not just return and do not add file
    <<apps_to_disable>>
    BEGIN
        SELECT 'Y'
        INTO lcAppsExist
        FROM patch_disable_apps
        WHERE patch_id = p_patch.patch_id
        ;
        
    EXCEPTION WHEN no_data_found THEN
        RETURN;
    END apps_to_disable;
    

    --get script for enable or disable apps
    /*
    SELECT pkg_utils.f_blob_to_clob(blob_file)
    INTO lcEnDisScript
    FROM additional_files
    WHERE code = 'ENDISAPP'
    ;
    */
    
    --replace placeholders
    lcEnDisScript := replace(lcEnDisScript, '__PATCH_ID__', p_patch.patch_id);
    lcEnDisScript := replace(lcEnDisScript, '__USERNAME__', 'AUCTIM');
    lcEnDisScript := replace(lcEnDisScript, '__STATUS__', (CASE p_enable_or_disable WHEN 'ENABLE' THEN 'AVAILABLE_W_EDIT_LINK' ELSE 'UNAVAILABLE_URL' END) );
    lcEnDisScript := replace(lcEnDisScript, '__URL__', '&AI_DOMAIN./i/MO/images/maintenance.htm');

    --file name 
    lcFileName := 
        'utils/' || 
        (CASE p_enable_or_disable WHEN 'ENABLE' THEN 'enable_apps' ELSE 'disable_apps' END) || 
        '.sql'
    ;

    --add script file to ZIP
    apex_zip.add_file(
        p_zip, 
        p_patch.root_folder || lcFileName,
        pkg_utils.f_clob_to_blob(lcEnDisScript)
    );

    --add script call to script
    p_add(p_script, 'PROMPT ' || lower(p_enable_or_disable) || ' apps');    
    p_add(p_script, '@@' || lcFileName);    
    p_add(p_script, null);    

END p_enable_disable_apps;


PROCEDURE p_recompile_objects(
    p_script IN OUT clob,
    p_zip IN OUT blob,
    p_patch pkg_patches.c_patch%ROWTYPE,
    p_create_file boolean
) IS

    CURSOR c_db_schemas_in_patch IS
        SELECT DISTINCT db_schema_name
        FROM 
            (
            SELECT v_dbo.db_schema_name
            FROM 
                patch_objects po
                JOIN v_database_objects v_dbo ON po.object_id = v_dbo.db_object_id
            WHERE patch_id = p_patch.patch_id
            UNION ALL
            SELECT v_dbs.schema_name
            FROM 
                patch_scripts ps
                JOIN v_database_schemas v_dbs ON ps.database_schema_id = v_dbs.schema_id
            WHERE patch_id = p_patch.patch_id
            )
        ;

    TYPE t_db_schemas_in_patch IS TABLE OF c_db_schemas_in_patch%ROWTYPE;
    lrSchemasInPatch t_db_schemas_in_patch;

    lcRecompScript clob;

BEGIN
    --get schemas
    OPEN c_db_schemas_in_patch;
    FETCH c_db_schemas_in_patch BULK COLLECT INTO lrSchemasInPatch;
    CLOSE c_db_schemas_in_patch;
    
    --if there is not schemas to compile... return
    if lrSchemasInPatch.count = 0 then
        RETURN;
    end if;

    --prepare script (if needed)
    if p_create_file then
        p_add(lcRecompScript, 'BEGIN');
        
        FOR t IN 1 .. lrSchemasInPatch.count LOOP
            p_add(lcRecompScript, '    DBMS_UTILITY.compile_schema(schema => ''' || lrSchemasInPatch(t).db_schema_name || ''', compile_all => false);');
        END LOOP;
        
        p_add(lcRecompScript, 'END;');
        p_add(lcRecompScript, '/');
        p_add(lcRecompScript, null);
    
        p_add(lcRecompScript, q'[SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID' AND object_type not like '%JAVA%']');
        p_add(lcRecompScript, '/');
        
        --add script file to ZIP
        apex_zip.add_file(
            p_zip, 
            p_patch.root_folder || 'utils/recompile.sql',
            pkg_utils.f_clob_to_blob(lcRecompScript)
        );
        
    end if;

    --add script call to script
    p_add(p_script, 'PROMPT recompile objects...');
    p_add(p_script, '@@' || 'utils/recompile.sql');
    p_add(p_script, null);
    
END p_recompile_objects;


FUNCTION f_object_target_filename(
    p_object_id objects.object_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2 IS

    lrData pkg_objects.c_data%ROWTYPE;
    
BEGIN
    --get data
    OPEN pkg_objects.c_data(p_object_id);
    FETCH pkg_objects.c_data INTO lrData;
    CLOSE pkg_objects.c_data;
    
    RETURN 
        CASE p_replace_schema_yn 
            WHEN 'Y' THEN replace(lrData.target_folder, '#SCHEMA#', lower(lrData.db_schema) ) 
            ELSE lrData.target_folder 
        END || 
        '/' || 
        lrData.filename
    ;
    
END f_object_target_filename;


FUNCTION f_script_target_filename(
    p_patch_script_id patch_scripts.patch_script_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2 IS

    CURSOR c_data IS
    SELECT
        v_dbs.schema_name as db_schema,
        lower(ps.filename) as filename,
        nvl(ot.target_folder, pst.target_folder) as target_folder
    FROM 
        patch_scripts ps
        JOIN patch_script_types pst ON ps.patch_script_type_id = pst.patch_script_type_id
        LEFT JOIN object_types ot ON ps.object_type_id = ot.object_type_id
        JOIN v_database_schemas v_dbs ON ps.database_schema_id = v_dbs.schema_id
    WHERE ps.patch_script_id = p_patch_script_id;

    lrData c_data%ROWTYPE;

BEGIN
    --get data
    OPEN c_data;
    FETCH c_data INTO lrData;
    CLOSE c_data;

    RETURN 
        CASE p_replace_schema_yn 
            WHEN 'Y' THEN replace(lrData.target_folder, '#SCHEMA#', lower(lrData.db_schema) ) 
            ELSE lrData.target_folder 
        END || 
        '/' || 
        lrData.filename
    ;
END f_script_target_filename;




FUNCTION f_prepare_patch_files(
    p_patch_id patches.patch_id%TYPE,
    p_main_folder_name_prefix varchar2 default null 
) RETURN pkg_releases.t_files AS

    lrPatch pkg_patches.c_patch%ROWTYPE;
    lrFiles pkg_releases.t_files := pkg_releases.t_files();

BEGIN
    --patch data
    OPEN pkg_patches.c_patch(p_patch_id);
    FETCH pkg_patches.c_patch INTO lrPatch;
    CLOSE pkg_patches.c_patch;

    EXECUTE IMMEDIATE 'BEGIN ' || lrPatch.patch_procedure_name || '(p_id => :1, p_patch_or_release => ''P'', p_files => :2); END;' 
    USING IN p_patch_id, OUT lrFiles;
    
    --for release - store patches within sub-folder
    if p_main_folder_name_prefix is not null then
        FOR t IN 1 .. lrFiles.count LOOP
            lrFiles(t).filename := p_main_folder_name_prefix || lrFiles(t).filename;
        END LOOP;
    end if;

    RETURN lrFiles;
    
END f_prepare_patch_files;



PROCEDURE p_prepare_patch_zip(
    p_patch_id patches.patch_id%TYPE,
    p_zip IN OUT blob,
    p_filename OUT varchar2
) AS

    lrPatch pkg_patches.c_patch%ROWTYPE;
    lrFiles pkg_releases.t_files := pkg_releases.t_files();
    
BEGIN
    --patch data
    OPEN pkg_patches.c_patch(p_patch_id);
    FETCH pkg_patches.c_patch INTO lrPatch;
    CLOSE pkg_patches.c_patch;

    --patch files
    lrFiles := f_prepare_patch_files(
        p_patch_id => p_patch_id
    );

    FOR t IN 1 .. lrFiles.count LOOP
        apex_zip.add_file(
            p_zipped_blob => p_zip, 
            p_file_name => lrFiles(t).filename,
            p_content => lrFiles(t).file_content
        );
    END LOOP;


    --filename and finish ZIP
    p_filename := lrPatch.filename;
    
    apex_zip.finish(p_zip);
    
    
END p_prepare_patch_zip;



FUNCTION f_prepare_rls_files(
    p_release_id releases.release_id%TYPE,
    p_merge_files_yn varchar2 default 'N'
) RETURN pkg_releases.t_files IS

    lrReleaseFiles t_files;

    CURSOR c_patch_template IS
        SELECT 
            r.patch_template_procedure_name as procedure_name
        FROM v_releases r
        WHERE r.release_id = p_release_id
        ;

    lrPatchTemplate c_patch_template%ROWTYPE;

BEGIN
    --patch template procedure name and patches subfolder (used for release)
    OPEN c_patch_template;
    FETCH c_patch_template INTO lrPatchTemplate;
    CLOSE c_patch_template;

    --get files
    EXECUTE IMMEDIATE 'BEGIN ' || lrPatchTemplate.procedure_name || '(p_id => :1, p_patch_or_release => ''RELEASE'', p_files => :2); END;' 
    USING IN p_release_id, OUT lrReleaseFiles;
    
    RETURN lrReleaseFiles;
    
END f_prepare_rls_files;


PROCEDURE p_download_rls_zip(
    p_release_id releases.release_id%TYPE,
    p_merge_files_yn varchar2 default 'N'
) IS

    lbZip blob;
    lrFiles pkg_releases.t_files;

BEGIN
    --get all release files
    lrFiles := f_prepare_rls_files (
        p_release_id => p_release_id,
        p_merge_files_yn => p_merge_files_yn
    );
    
    --prepare ZIP
    FOR t IN 1 .. lrFiles.count LOOP
        apex_zip.add_file(
            p_zipped_blob => lbZip, 
            p_file_name => lrFiles(t).filename,
            p_content => lrFiles(t).file_content
        );
    END LOOP;

    apex_zip.finish(lbZip);

    --get filename and download ZIP file
    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => f_rls_code(p_release_id) || '.zip'
    );

END p_download_rls_zip;



PROCEDURE p_prepare_html_report(
    p_release_id releases.release_id%TYPE,
    p_report IN OUT NOCOPY blob,
    p_filename OUT varchar2
) IS

    lrRelease v_releases%ROWTYPE;
    lrDocPartTexts t_doc_part_texts;
    lrTasks t_release_tasks;
    lrObjects t_release_objects;
    
    lcDoc clob;
    lcText varchar2(32000);

BEGIN
    --release data
    SELECT *
    INTO lrRelease
    FROM v_releases
    WHERE release_id = p_release_id
    ;
    
    
    --document template
    lcDoc := pkg_settings.f_project_sett_vc2(
        p_project_id => lrRelease.project_id,
        p_code => 'REL_DOC_HTML_TEMPL'
    );
    
    
    --basic placeholders
    lcDoc := replace(lcDoc, '#RELEASE_CODE#', lrRelease.code);
    lcDoc := replace(lcDoc, '#RELEASE_NAME#', lrRelease.description);
    lcDoc := replace(lcDoc, '#RELEASE_DATE#', to_char(lrRelease.planed_release_date, 'dd.mm.yyyy') );
    lcDoc := replace(lcDoc, '#RELEASE_TIME#', to_char(lrRelease.planed_release_date, 'hh24:mi') );
    lcDoc := replace(lcDoc, '#RELEASE_DURATION#', lrRelease.planed_duration);

    
    --document part texts
    OPEN c_doc_part_texts(p_release_id);
    FETCH c_doc_part_texts BULK COLLECT INTO lrDocPartTexts;
    CLOSE c_doc_part_texts;
    
    FOR t IN 1 .. lrDocPartTexts.count LOOP
        lcDoc := replace(
            lcDoc, 
            lrDocPartTexts(t).placeholder, 
            replace(lrDocPartTexts(t).part_text, chr(10), '<br>')
        );
    END LOOP;
    
    
    --task list
    OPEN c_release_tasks(p_release_id);
    FETCH c_release_tasks BULK COLLECT INTO lrTasks;
    CLOSE c_release_tasks;
    
    lcText := '<ul>' || chr(10);
    
    FOR t IN 1 .. lrTasks.count LOOP
        lcText := lcText || 
            '<li>' || 
            '<a href="' || lrTasks(t).external_link || '" target="_blank">' ||
            lrTasks(t).code_and_name || '</a></li>' || 
            chr(10)
        ;
    END LOOP;

    lcText := lcText || '</ul>' || chr(10);
    
    lcDoc := replace(lcDoc, '#TASKS#', lcText);
    
    
    
    --object list
    lcText := '<table style="border-collapse: collapse; width: 100%;" border="1"><tbody>
<tr>
<td style="width: 10%; text-align: center;"><strong>Object Group</strong></td>
<td style="width: 10%; text-align: center;"><strong>Object Type</strong></td>
<td style="width: 55%; text-align: center;"><strong>Object Name</strong></td>
<td style="width: 25%; text-align: center;"><strong>Included in patches</strong></td>
</tr>
' || chr(10);
    
    OPEN c_release_objects(p_release_id);
    FETCH c_release_objects BULK COLLECT INTO lrObjects;
    CLOSE c_release_objects;
    
    FOR t IN 1 .. lrObjects.count LOOP
        lcText := lcText || 
'<tr>
<td>' || initcap(lrObjects(t).object_group) || '</td>
<td>' || lrObjects(t).object_type || '</td>
<td>' || lrObjects(t).object_name || '</td>
<td>' || lrObjects(t).included_in_patches || '</td>
</tr>' || chr(10)
;
        
    END LOOP;

    lcText := lcText || '</tbody></table>' || chr(10);

    lcDoc := replace(lcDoc, '#OBJECTS#', lcText);

    
    --filename
    p_filename := lrRelease.code || '.html';
    
    
    --convert to blob
    p_report := pkg_utils.f_clob_to_blob(lcDoc);
    
    
END p_prepare_html_report;


PROCEDURE p_prepare_md_report(
    p_release_id releases.release_id%TYPE,
    p_report IN OUT NOCOPY blob,
    p_filename OUT varchar2
) IS

    lrRelease v_releases%ROWTYPE;
    lrDocPartTexts t_doc_part_texts;
    lrTasks t_release_tasks;
    lrObjects t_release_objects;
    
    lcDoc clob;
    lcText varchar2(32000);

BEGIN
    --release data
    SELECT *
    INTO lrRelease
    FROM v_releases
    WHERE release_id = p_release_id
    ;
    
    
    --document template
    lcDoc := pkg_settings.f_project_sett_vc2(
        p_project_id => lrRelease.project_id,
        p_code => 'REL_DOC_MD_TEMPLATE'
    );
    
    
    --basic placeholders
    lcDoc := replace(lcDoc, '#RELEASE_CODE#', lrRelease.code);
    lcDoc := replace(lcDoc, '#RELEASE_NAME#', lrRelease.description);
    lcDoc := replace(lcDoc, '#RELEASE_DATE#', to_char(lrRelease.planed_release_date, 'dd.mm.yyyy') );
    lcDoc := replace(lcDoc, '#RELEASE_TIME#', to_char(lrRelease.planed_release_date, 'hh24:mi') );
    lcDoc := replace(lcDoc, '#RELEASE_DURATION#', lrRelease.planed_duration);

    
    --document part texts
    OPEN c_doc_part_texts(p_release_id);
    FETCH c_doc_part_texts BULK COLLECT INTO lrDocPartTexts;
    CLOSE c_doc_part_texts;
    
    FOR t IN 1 .. lrDocPartTexts.count LOOP
        lcDoc := replace(lcDoc, lrDocPartTexts(t).placeholder, lrDocPartTexts(t).part_text);
    END LOOP;
    
    
    --task list
    OPEN c_release_tasks(p_release_id);
    FETCH c_release_tasks BULK COLLECT INTO lrTasks;
    CLOSE c_release_tasks;
    
    FOR t IN 1 .. lrTasks.count LOOP
        lcText := lcText || 
            '- ' || 
            '[' || lrTasks(t).code_and_name || ']' || 
            '(' || lrTasks(t).external_link || ')' || 
            chr(10)
        ;
    END LOOP;
    
    lcDoc := replace(lcDoc, '#TASKS#', lcText);
    
    
    
    --object list
    lcText := null;
    
    OPEN c_release_objects(p_release_id);
    FETCH c_release_objects BULK COLLECT INTO lrObjects;
    CLOSE c_release_objects;
    
    FOR t IN 1 .. lrObjects.count LOOP
        if t = 1 or (t > 1 and lrObjects(t).object_group <> lrObjects(t - 1).object_group) then
            lcText := lcText || '#### ' || initcap(lrObjects(t).object_group) || chr(10);
        
        else
            lcText := lcText || 
                '- ' || lrObjects(t).object_type || ' ' || 
                lrObjects(t).object_name || ' (' || 
                lrObjects(t).included_in_patches || ')' || chr(10) 
            ;
        end if;
        
    END LOOP;

    lcDoc := replace(lcDoc, '#OBJECTS#', lcText);

    
    --filename
    p_filename := lrRelease.code || '.md';
    
    
    --convert to blob
    p_report := pkg_utils.f_clob_to_blob(lcDoc);
    
    
END p_prepare_md_report;



PROCEDURE p_download_report(
    p_release_id releases.release_id%TYPE,
    p_format varchar2
) IS

    lbReport blob;
    lcFilename varchar2(1000);

BEGIN
    if p_format = 'MARKDOWN' then
        p_prepare_md_report(
            p_release_id => p_release_id,
            p_report => lbReport,
            p_filename => lcFilename
        );

    elsif p_format = 'HTML' then
        p_prepare_html_report(
            p_release_id => p_release_id,
            p_report => lbReport,
            p_filename => lcFilename
        );

    end if;

    --download document
    pkg_utils.p_download_document(
        p_doc => lbReport,
        p_file_name => lcFilename
    );

END;



FUNCTION f_script_filename(
    p_release_script_type_id release_script_types.rls_script_type_id%TYPE,
    p_nr release_scripts.order_by%TYPE
) RETURN release_scripts.filename%TYPE IS

    lcFilename release_scripts.filename%TYPE;

BEGIN
    SELECT file_name
    INTO lcFilename
    FROM 
        (
        SELECT 
            lower(rst.code) || '_' || to_char(nvl(p_nr, 1), 'fm000') || '.sql' as file_name,
            row_number() over (order by rst.seq asc) as rn
        FROM release_script_types rst
        WHERE 
            rst.rls_script_type_id = p_release_script_type_id
        OR  p_release_script_type_id is null
        )
    WHERE rn = 1
    ;

    RETURN lcFilename;
    
END f_script_filename;


FUNCTION f_release_patches(
    p_release_id releases.release_id%TYPE
) RETURN varchar2 IS

    CURSOR c_patches IS
        SELECT
            CASE 
                WHEN p.confirmed_on is null THEN '<span style="color:#AAAAAA">' || t.code || '_' || p.patch_number || ' - ' || t.name || '</span>' 
                ELSE t.code || '_' || p.patch_number || ' - ' || t.name
            END as patch_name 
        FROM 
            patches p
            JOIN tasks t ON p.task_id = t.task_id
        WHERE p.release_id = p_release_id
        ORDER BY patch_name
    ;

    TYPE t_patches IS TABLE OF c_patches%ROWTYPE;
    lrPatches t_patches;

    lcPatches varchar2(32000);
    lcSeparator varchar2(50) := '<br>';

BEGIN
    OPEN c_patches;
    FETCH c_patches BULK COLLECT INTO lrPatches;
    CLOSE c_patches;

    FOR t IN 1 .. lrPatches.count LOOP
        lcPatches := lcPatches || lrPatches(t).patch_name || lcSeparator;
    END LOOP;
    lcPatches := rtrim(lcPatches, lcSeparator);
    
    RETURN lcPatches;
    
END f_release_patches;

END PKG_RELEASES;
/


--
-- PKG_SCRIPTS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_scripts as


PROCEDURE p_add_text (
    p_file IN OUT clob,
    p_text varchar2
) IS
BEGIN
    p_file := p_file || p_text || chr(10);
END p_add_text;


PROCEDURE p_add_output_file (
    p_root_folder varchar2,
    p_file_list IN OUT pkg_releases.t_files,
    p_file_name varchar2,
    p_file_content blob
) IS
BEGIN
    p_file_list.extend;

    p_file_list(p_file_list.count).filename := p_root_folder || p_file_name;
    p_file_list(p_file_list.count).file_content := p_file_content;
    
END p_add_output_file;


PROCEDURE p_sqlplus_multiple_files_p (
    p_id number,  --patch or release ID
    p_patch_or_release varchar2,  --values P or R
    p_files OUT pkg_releases.t_files
) IS

    lrData pkg_patch_templates.c_template_data%ROWTYPE;
    lrTemplateFiles pkg_patch_templates.t_patch_template_files;
    lrPatchFiles pkg_patches.t_patch_files;
    lrSchemas pkg_patches.t_patch_schemas;

    lcClob clob;
    lcFilename varchar2(4000);
    lcReference varchar2(20) := p_patch_or_release || '_' || p_id;
    
BEGIN
    p_files := pkg_releases.t_files();

    --patch or release data (cursor is defined in package spec)
    OPEN pkg_patch_templates.c_template_data (
        p_id => p_id,
        p_patch_or_release => p_patch_or_release
    );
    FETCH pkg_patch_templates.c_template_data INTO lrData;
    CLOSE pkg_patch_templates.c_template_data;

    --patch database schemas
    OPEN pkg_patches.c_patch_schemas(p_id);
    FETCH pkg_patches.c_patch_schemas BULK COLLECT INTO lrSchemas;
    CLOSE pkg_patches.c_patch_schemas;


    --TEMPLATE FILES
    
    --get template files (cursor is defined in package spec)
    OPEN pkg_patch_templates.c_patch_template_files(lrData.patch_template_id);
    FETCH pkg_patch_templates.c_patch_template_files BULK COLLECT INTO lrTemplateFiles;
    CLOSE pkg_patch_templates.c_patch_template_files;

    --replace placeholders and add files to output collection
    FOR t IN 1 .. lrTemplateFiles.count LOOP
        
        if lrTemplateFiles(t).usage_type <> 'B' then  --non-binary files -> replace placeholders
            lcClob := pkg_utils.f_blob_to_clob(lrTemplateFiles(t).file_content);
            
            lcClob := replace(lcClob, '__APP_NAME__', lrData.project_name);
            lcClob := replace(lcClob, '__CODE__', lrData.code);
            lcClob := replace(lcClob, '__NAME__', lrData.name);
            lcClob := replace(lcClob, '__AUTHOR__', lrData.user_created);
            lcClob := replace(lcClob, '__VERSION__', lrData.version);
            lcClob := replace(lcClob, '__COMMENT__', lrData.user_comments);
            lcClob := replace(lcClob, '__RELEASE_NOTES__', lrData.release_notes);
            
            lrTemplateFiles(t).file_content := pkg_utils.f_clob_to_blob(lcClob);
            

            if lrTemplateFiles(t).usage_type = 'SL' then  --multiply schema level files for every schema
            
                FOR s IN 1 .. lrSchemas.count LOOP
                    lcFilename := replace(lrTemplateFiles(t).file_name, '#SCHEMA#', lower(lrSchemas(s).schema_name) );
                
                    p_add_output_file(
                        p_root_folder => lrData.root_folder,
                        p_file_list => p_files,
                        p_file_name => lcFilename,
                        p_file_content => lrTemplateFiles(t).file_content
                    );
                END LOOP;

            else  --add single file to output collection
                p_add_output_file(
                    p_root_folder => lrData.root_folder,
                    p_file_list => p_files,
                    p_file_name => lrTemplateFiles(t).file_name,
                    p_file_content => lrTemplateFiles(t).file_content
                );
                
            end if;
        
        else  --binary files -> just add to collection
            p_add_output_file(
                p_root_folder => lrData.root_folder,
                p_file_list => p_files,
                p_file_name => lrTemplateFiles(t).file_name,
                p_file_content => lrTemplateFiles(t).file_content
            );
        
        end if;
        
    END LOOP;
    

    
    --PATCH FILES
    OPEN pkg_patches.c_patch_files (
        p_patch_id => p_id
    );
    FETCH pkg_patches.c_patch_files BULK COLLECT INTO lrPatchFiles;
    CLOSE pkg_patches.c_patch_files;
    
    lcClob := null;  --will store main install.sql file
    
    p_add_text(lcClob,  'PROMPT Install scripts for patch ' || lrData.name);
    p_add_text(lcClob,  '--' );
    p_add_text(lcClob,  'SPOOL log/log.txt' );
    p_add_text(lcClob,  '--' );
    p_add_text(lcClob,  'PROMPT Start install' );
    p_add_text(lcClob,  'connect &&schema_DEV.');
    p_add_text(lcClob,  'BEGIN' );
    p_add_text(lcClob,  '    pkg_interface.p_ext_install_start (
        p_ext_system_code => ''SQLPLUS'',
        p_ext_system_ref => ''' || lcReference || ''',
        p_reference => ''' || lcReference || ''',
        p_environment => ''&&myEnv.''
    );' );
    p_add_text(lcClob,  'END;' );
    p_add_text(lcClob,  '/' );


    
    FOR t IN 1 .. lrPatchFiles.count LOOP
    
        p_add_output_file(
            p_root_folder => lrData.root_folder,
            p_file_list => p_files,
            p_file_name => lrPatchFiles(t).filename,
            p_file_content => lrPatchFiles(t).blob_file
        );
        
        if lrPatchFiles(t).change_schema_yn = 'Y' then
            p_add_text(lcClob,  'PROMPT Please enter connect string for schema ' || lrPatchFiles(t).schema_name);
            p_add_text(lcClob,  'connect &&schema_' || lrPatchFiles(t).schema_name || '.');
        end if;
        
        p_add_text(lcClob,  '@' || lrPatchFiles(t).filename);
    END LOOP;

    p_add_text(lcClob,  '--' );
    p_add_text(lcClob,  'PROMPT Install end' );
    p_add_text(lcClob,  'connect &&schema_DEV.');
    p_add_text(lcClob,  'BEGIN' );
    p_add_text(lcClob,  '    pkg_interface.p_ext_install_stop (
        p_ext_system_code => ''SQLPLUS'',
        p_ext_system_ref => ''' || lcReference || '''
    );' );
    p_add_text(lcClob,  'END;' );
    p_add_text(lcClob,  '/' );


    p_add_text(lcClob,  'SPOOL off' );
    
    p_add_output_file(
        p_root_folder => lrData.root_folder,
        p_file_list => p_files,
        p_file_name => 'install.sql',
        p_file_content => pkg_utils.f_clob_to_blob(lcClob)
    );
   
END p_sqlplus_multiple_files_p;



PROCEDURE p_sqlplus_release_p (
    p_id number,  --patch or release ID
    p_patch_or_release varchar2,  --values P or R
    p_files OUT pkg_releases.t_files
) IS

    CURSOR c_patches IS
        SELECT 
            patch_id,
            display,
            filename_without_extension
        FROM v_patches
        WHERE release_id = p_id
        ORDER BY 
            release_order asc,
            confirmed_on asc
    ;

    lrPatchFiles pkg_releases.t_files;
    lrTemplateFiles pkg_patch_templates.t_patch_template_files;
    lrRelease v_releases%ROWTYPE; 
    lnCounter pls_integer := 0;
    lnMainPatchesFolder varchar2(1000);
    lcClob clob;
    lcPatchList clob;

    PROCEDURE p_release_scripts (
        p_script_type_code release_script_types.code%TYPE
    ) IS

    CURSOR c_rls_files IS
        SELECT
            filename_for_zip,
            pkg_utils.f_clob_to_blob(sql_content) as blob_file,
            schema_name,
            CASE 
                WHEN schema_name <> lag(schema_name, 1, 'not existing one') over (order by schema_name, order_by) THEN 'Y' 
                ELSE 'N' 
            END as change_schema_yn
        FROM v_release_scripts
        WHERE 
            release_id = p_id
        AND script_type_code = p_script_type_code
        ORDER BY
            order_by
    ;
    
    TYPE t_rls_files IS TABLE OF c_rls_files%ROWTYPE;
    lrRlsFiles t_rls_files;

    BEGIN
        --get release files
        OPEN c_rls_files;
        FETCH c_rls_files BULK COLLECT INTO lrRlsFiles;
        CLOSE c_rls_files;
        
        if lrRlsFiles.count > 0 then
            p_add_text(lcClob,  'PROMPT Installing ' || p_script_type_code || 'scripts...' );
        end if;

        FOR t IN 1 .. lrRlsFiles.count LOOP
        
            if lrRlsFiles(t).change_schema_yn = 'Y' then
                p_add_text(lcClob,  'PROMPT Please enter connect string for schema ' || lrRlsFiles(t).schema_name);
                p_add_text(lcClob,  'connect &&schema_' || lrRlsFiles(t).schema_name || '.');
            end if;
            
            p_add_text(lcClob,  '@' || lrRlsFiles(t).filename_for_zip);
            
            p_add_output_file(
                p_root_folder => lrRelease.code || '/',
                p_file_list => p_files,
                p_file_name => lrRlsFiles(t).filename_for_zip,
                p_file_content => lrRlsFiles(t).blob_file
            );
        
        END LOOP;
        
    END p_release_scripts;

BEGIN
    --initialize collection
    p_files := pkg_releases.t_files();

    --get release record
    SELECT * 
    INTO lrRelease
    FROM v_releases r
    WHERE r.release_id = p_id
    ;

    --get template files (cursor is defined in package spec)
    OPEN pkg_patch_templates.c_patch_template_files(lrRelease.patch_template_id);
    FETCH pkg_patch_templates.c_patch_template_files BULK COLLECT INTO lrTemplateFiles;
    CLOSE pkg_patch_templates.c_patch_template_files;

    --add template files to release - currently just static files, without modifications
    FOR t IN 1 .. lrTemplateFiles.count LOOP
        p_add_output_file(
            p_root_folder => lrRelease.code || '/',
            p_file_list => p_files,
            p_file_name => lrTemplateFiles(t).file_name,
            p_file_content => lrTemplateFiles(t).file_content
        );
    END LOOP;


    --initialize and fill main install.sql file
    lcClob := null;  --will store main install.sql file
    lcPatchList := null;  --will store patch list file
    
    p_add_text(lcClob,  'PROMPT Install scripts for release ' || lrRelease.display);
    p_add_text(lcClob,  '---' );
    p_add_text(lcClob,  '---' );

    p_release_scripts(
        p_script_type_code => 'PRE_RLS'
    );

    --process patches
    FOR ptch IN c_patches LOOP
        --get patches files and add it to release files list
        lnCounter := lnCounter + 10;

        lnMainPatchesFolder := 
            lrRelease.code || '/' ||
            CASE WHEN lrRelease.patch_template_sql_subfolder is not null THEN lrRelease.patch_template_sql_subfolder || '/' ELSE null END ||
            to_char(lnCounter, 'fm000') || '_'
            
        ;

        lrPatchFiles := pkg_releases.f_prepare_patch_files (
            p_patch_id => ptch.patch_id,
            p_main_folder_name_prefix => lnMainPatchesFolder
        );
        
        p_files := p_files MULTISET UNION ALL lrPatchFiles;
        
        --add lines to main release install.sql file
        p_add_text(lcClob, 'PROMPT Start install for patch ' || ptch.display );
        p_add_text(lcClob, 
            '@' || 
            CASE WHEN lrRelease.patch_template_sql_subfolder is not null THEN lrRelease.patch_template_sql_subfolder || '/' ELSE null END ||
            to_char(lnCounter, 'fm000') || '_' ||
            ptch.filename_without_extension || '/install.sql'
        );
        p_add_text(lcClob, '---' );

        --patch list document
        p_add_text(lcPatchList, ptch.display);

    END LOOP;

    p_release_scripts(
        p_script_type_code => 'POST_RLS'
    );

    p_add_text(lcClob, '---' );
    p_add_text(lcClob, 'PROMPT Install end' );


    --add main install.sql to patch
    p_add_output_file(
        p_root_folder => lrRelease.code || '/',
        p_file_list => p_files,
        p_file_name => 'install.sql',
        p_file_content => pkg_utils.f_clob_to_blob(lcClob)
    );

    --documentation/patch_list.txt
    p_add_output_file(
        p_root_folder => lrRelease.code || '/',
        p_file_list => p_files,
        p_file_name => 'documentation/patch_list.txt',
        p_file_content => pkg_utils.f_clob_to_blob(lcPatchList)
    );

END p_sqlplus_release_p;

END pkg_scripts;
/


--
-- PKG_SETTINGS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_settings AS

FUNCTION f_prj_sett_record(
    p_project_id projects.project_id%TYPE,
    p_code r_settings.code%TYPE
) RETURN project_settings%ROWTYPE IS

    lrRecord project_settings%ROWTYPE;

BEGIN
    SELECT ps.*
    INTO lrRecord
    FROM 
        project_settings ps 
        JOIN r_settings rs ON ps.setting_id = rs.setting_id
    WHERE
        ps.project_id = p_project_id
    AND rs.code = p_code;
    
    RETURN lrRecord;
END f_prj_sett_record;


FUNCTION f_setting_record(
    p_setting_id r_settings.setting_id%TYPE
) RETURN r_settings%ROWTYPE IS

    lrRecord r_settings%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRecord
    FROM 
        r_settings
    WHERE
        setting_id = p_setting_id;
    
    RETURN lrRecord;
END f_setting_record;



FUNCTION f_project_sett_vc2(
    p_project_id projects.project_id%TYPE,
    p_code r_settings.code%TYPE
) RETURN project_settings.value_vc2%TYPE AS
BEGIN
    RETURN f_prj_sett_record(
        p_project_id,
        p_code
    ).value_vc2;
END f_project_sett_vc2;


PROCEDURE p_set_value(
    p_project_id projects.project_id%TYPE,
    p_code r_settings.code%TYPE,
    p_vc2_value project_settings.value_vc2%TYPE default null,
    p_number_value project_settings.value_num%TYPE default null,
    p_date_value project_settings.value_date%TYPE default null
) IS 
BEGIN
    UPDATE 
        (
        SELECT ps.*
        FROM 
            project_settings ps 
            JOIN r_settings rs ON ps.setting_id = rs.setting_id
        WHERE
            ps.project_id = p_project_id
        AND rs.code = p_code
        )
    SET
        value_num = p_number_value, 
        value_vc2 = p_vc2_value, 
        value_date = p_date_value
    ;
    
END p_set_value;


FUNCTION f_setting_hidden_yn(
    p_setting_id r_settings.setting_id%TYPE
) RETURN r_settings.hidden_yn%TYPE IS
BEGIN
    RETURN f_setting_record(p_setting_id).hidden_yn;
END f_setting_hidden_yn;



END pkg_settings;
/


--
-- PKG_USERS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_USERS AS 

FUNCTION f_get_user(
    p_app_user_id app_users.app_user_id%TYPE
) RETURN app_users%ROWTYPE AS

    lrRecord app_users%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRecord
    FROM app_users
    WHERE app_user_id = p_app_user_id;

    RETURN lrRecord;
END f_get_user;


FUNCTION f_display_name(
    p_app_user_id app_users.app_user_id%TYPE
) RETURN app_users.display_name%TYPE AS
BEGIN
    RETURN f_get_user(p_app_user_id).display_name;
END f_display_name;


FUNCTION f_get_user_id(
    p_proxy_user app_users.proxy_user%TYPE
) RETURN app_users.app_user_id%TYPE AS

    lrRecord app_users%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRecord
    FROM app_users
    WHERE proxy_user = p_proxy_user;

    RETURN lrRecord.app_user_id;

EXCEPTION WHEN no_data_found THEN 
    RETURN null;

END f_get_user_id;



FUNCTION f_user_works_on_patch_id(
    p_app_user_id app_users.app_user_id%TYPE
) RETURN patches.patch_id%TYPE IS

    lnPatchID patches.patch_id%TYPE;

BEGIN
    SELECT patch_id
    INTO lnPatchID
    FROM user_works_on_patch
    WHERE
        app_user_id = p_app_user_id
    AND stop is null;
    
    RETURN lnPatchID;
    
EXCEPTION WHEN no_data_found THEN
    RETURN null;
    
END f_user_works_on_patch_id;


END PKG_USERS;
/


--
-- PKG_UTILS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY PKG_UTILS AS 

FUNCTION f_clob_to_blob(
    c clob,
    plEncoding IN NUMBER default 0) RETURN blob IS

    v_blob Blob;
    v_in Pls_Integer := 1;
    v_out Pls_Integer := 1;
    v_lang Pls_Integer := 0;
    v_warning Pls_Integer := 0;
    v_id number(10);

BEGIN
    if c is null then
        return null;
    end if;

    v_in:=1;
    v_out:=1;
    dbms_lob.createtemporary(v_blob,TRUE);
    
    DBMS_LOB.convertToBlob(
        v_blob,
        c,
        DBMS_lob.getlength(c),
        v_in,
        v_out,
        plEncoding,
        v_lang,
        v_warning
    );

    RETURN v_blob;

END f_clob_to_blob; 


FUNCTION f_blob_to_clob(
    blob_in IN blob,
    plEncoding IN NUMBER default 0) RETURN clob IS

    v_clob Clob;
    v_in Pls_Integer := 1;
    v_out Pls_Integer := 1;
    v_lang Pls_Integer := 0;
    v_warning Pls_Integer := 0;
    v_id number(10);

BEGIN
    if blob_in is null then
        return null;
    end if;

    v_in:=1;
    v_out:=1;
    dbms_lob.createtemporary(v_clob,TRUE);
    DBMS_LOB.convertToClob(v_clob,
                           blob_in,
                           DBMS_lob.getlength(blob_in),
                           v_in,
                           v_out,
                           plEncoding,
                           v_lang,
                           v_warning);

    RETURN v_clob;

END f_blob_to_clob;

PROCEDURE p_download_document(
    p_doc IN OUT blob,
    p_file_name varchar2,
    p_disposition varchar2 default 'attachment'  --values "attachment" and "inline"
    ) IS
BEGIN
    htp.init;
    OWA_UTIL.MIME_HEADER('application/pdf', FALSE);
    htp.p('Content-length: ' || dbms_lob.getlength(p_doc) ); 
    htp.p('Content-Disposition: ' || p_disposition || '; filename="' || p_file_name || '"' );
    OWA_UTIL.HTTP_HEADER_CLOSE;
    
    WPG_DOCLOAD.DOWNLOAD_FILE(p_doc);
    DBMS_LOB.FREETEMPORARY(p_doc);
    
    apex_application.stop_apex_engine;
END p_download_document;  


PROCEDURE p_download_document(
    p_text IN OUT clob,
    p_file_name varchar2,
    p_disposition varchar2 default 'attachment'  --values "attachment" and "inline"
    ) IS
    
    lbBlob blob;
    
BEGIN
    lbBlob := f_clob_to_blob(p_text);
    
    p_download_document(
        p_doc => lbBlob,
        p_file_name => p_file_name,
        p_disposition => p_disposition
    );
END p_download_document;


PROCEDURE p_vc_arr2_to_apex_coll(
    p_app_coll wwv_flow_global.vc_arr2,
    p_apex_coll_name varchar2,
    p_n001_yn varchar2 default 'N'
) IS
BEGIN
    APEX_COLLECTION.create_or_truncate_collection(p_apex_coll_name);

    FOR t IN 1 .. p_app_coll.count LOOP
        APEX_COLLECTION.add_member(
            p_collection_name => p_apex_coll_name,
            p_c001 => p_app_coll(t),
            p_n001 => CASE WHEN p_n001_yn = 'Y' THEN to_number(p_app_coll(t)) ELSE null END
        );
    END LOOP;

END p_vc_arr2_to_apex_coll;

END PKG_UTILS;
/


--
-- PKG_WRAP  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY pkg_wrap IS

FUNCTION f_wrap(
    p_sql_source clob
) RETURN clob IS

    lrSource dbms_sql.varchar2a;
    lrWrapped dbms_sql.varchar2a;
    
    lnPos pls_integer := 1;
    lnIndex pls_integer := 1;
    
    lcClob clob;

BEGIN
    --remove EDITIONABLE word because it rises an error
    lcClob := replace(p_sql_source, 'CREATE OR REPLACE EDITIONABLE', 'CREATE OR REPLACE');
    
    --remove "/" from end of script - wrapped script gets invalid
    lcClob := rtrim(lcClob, '/');
    

    --break clob in varchar2 chunks
    WHILE lnPos <= dbms_lob.getLength( lcClob) LOOP
        lrSource(lnIndex) := substr(lcClob, lnPos, 30000);
        
        lnPos := lnPos + 30000;
        lnIndex := lnIndex + 1;
    END LOOP; 

    --wrap chunks
    lrWrapped := dbms_ddl.wrap(
        ddl => lrSource,
        lb => 1,
        ub => lrSource.count
    );

    --concat wrapped chunks into CLOB
    lcClob := null;
    FOR t IN 1 .. lrWrapped.count LOOP
        lcClob := lcClob || lrWrapped(t); 
    END LOOP;

    RETURN lcClob;

END f_wrap;


FUNCTION f_object_type_wrap_yn(
    p_project_id projects.project_id%TYPE,
    p_type_code object_types.code%TYPE
) RETURN varchar2 IS

    lcYesNo varchar2(1);

BEGIN
    SELECT
        CASE WHEN EXISTS 
            (
            SELECT 1
            FROM 
                wrap_object_types wot
                JOIN object_types ot ON wot.object_type_id = ot.object_type_id
            WHERE
                wot.project_id = p_project_id
            AND ot.code = p_type_code
            ) THEN 'Y'
        ELSE 'N'
        END
    INTO lcYesNo
    FROM dual;

    RETURN lcYesNo;
    
END f_object_type_wrap_yn;


PROCEDURE p_set_obj_type_wrap(
    p_project_id projects.project_id%TYPE,
    p_type_code object_types.code%TYPE,
    p_wrap_yn varchar2  --values Y or N
) IS
BEGIN
    if p_wrap_yn = 'Y' then
        
        MERGE INTO wrap_object_types ot
        USING (
            SELECT object_type_id
            FROM object_types 
            WHERE code = p_type_code
        ) vju
        ON (ot.project_id = p_project_id AND ot.object_type_id = vju.object_type_id)
        WHEN NOT MATCHED THEN INSERT (project_id, object_type_id) VALUES (p_project_id, vju.object_type_id)
        ;
        
    else  --remove
        DELETE FROM
        (
            SELECT wot.wrap_object_type_id
            FROM 
                wrap_object_types wot
                JOIN object_types ot ON wot.object_type_id = ot.object_type_id
            WHERE
                wot.project_id = p_project_id
            AND ot.code = p_type_code
        );
    end if;

END p_set_obj_type_wrap;


FUNCTION f_wrap_object_yn(
    p_object_id objects.object_id%TYPE,
    p_project_id  projects.project_id%TYPE
) RETURN varchar2 IS

    lcYesNo pkg_declarations.yes_no;

BEGIN
    if p_object_id is null then
        lcYesNo := 'N';
    
    else
        SELECT 
            CASE 
                WHEN 
                        wot.wrap_object_type_id is not null  --whole object type is marked for wrapping
                    or  wos.wrap_object_source_id is not null THEN 'Y'  --single object is marked for wrapping
                ELSE 'N' 
            END
        INTO lcYesNo
        FROM 
            objects o
            LEFT JOIN wrap_object_types wot ON o.object_type_id = wot.object_type_id AND wot.project_id = p_project_id
            LEFT JOIN wrap_object_sources wos ON o.object_id = wos.object_id AND wos.project_id = p_project_id
        WHERE o.object_id = p_object_id;
        
    end if;

    RETURN lcYesNo;
END f_wrap_object_yn;

END pkg_wrap;
/
