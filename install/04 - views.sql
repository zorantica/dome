SET DEFINE OFF;
--
-- V_APPLICATIONS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_APPLICATIONS
BEQUEATH DEFINER
AS 
SELECT
    ob.object_id as application_id,
    ob.parent_object_id as workspace_id,
    ob.object_type_id,
    ot.code as object_type_code,
    ot.name as object_type_name,
    ob.name as application_name,
    ob.aa_number_01 as application_number,
    ob.filename as application_filename,
    ob.user_comment,
    ob.name || (CASE WHEN ob.aa_number_01 is not null THEN ' (' || ob.aa_number_01 || ')' END) as display,
    (SELECT ob_parent.name FROM objects ob_parent WHERE ob.parent_object_id = ob_parent.object_id) as workspace_name,
    v_dbs.schema_name
FROM
    objects ob
    JOIN object_types ot ON ob.object_type_id = ot.object_type_id
    LEFT JOIN v_database_schemas v_dbs ON ob.aa_number_02 = v_dbs.schema_id
WHERE ot.code = 'APP'
/


--
-- V_APP_COMPONENTS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_APP_COMPONENTS
BEQUEATH DEFINER
AS 
SELECT
    ob.object_id as app_component_id,
    ob.parent_object_id as application_id,
    ob.object_type_id,
    ob.name as app_component_name,
    ob.aa_number_01 as app_component_number,
    ob.filename as app_component_filename,
    ob.user_comment,
    ob_parent.aa_number_01 || ':' || ob.aa_number_01 || ' - ' || ob.name || CASE WHEN ob.active_yn = 'N' THEN ' (inactive)' ELSE null END as display,
    ob_parent.aa_number_01 as application_number,
    ob_parent.name as application_name,
    v_app.schema_name as app_schema_name,
    ot.code as object_type_code,
    ot.name as object_type_name,
    ob.lock_app_user_id,
    au.display_name as lock_app_user_name,
    ob.lock_comment,
    ob.lock_date,
    ob.lock_type,
    ob.active_yn
FROM
    objects ob
    JOIN object_types ot ON ob.object_type_id = ot.object_type_id
    JOIN objects ob_parent ON ob.parent_object_id = ob_parent.object_id
    JOIN v_applications v_app ON ob.parent_object_id = v_app.application_id
    LEFT JOIN app_users au ON ob.lock_app_user_id = au.app_user_id
WHERE ot.object_location = 'APP'
/


--
-- V_DATABASE_OBJECTS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_DATABASE_OBJECTS
BEQUEATH DEFINER
AS 
SELECT
    ob.object_id as db_object_id,
    ob.parent_object_id as db_schema_id,
    ob.object_type_id,
    ob.name as db_object_name,
    ob.filename as db_object_filename,
    ob.user_comment,
    ob_parent.name || '.' || ob.name || CASE WHEN ob.active_yn = 'N' THEN ' (inactive)' ELSE null END as display,
    ob.name || CASE WHEN ob.active_yn = 'N' THEN ' (inactive)' ELSE null END as name_with_inactive,
    ob_parent.name as db_schema_name,
    ot.code as object_type_code,
    ot.name as object_type_name,
    ob.lock_app_user_id,
    ot.record_as,
    au.display_name as lock_app_user_name,
    ob.lock_comment,
    ob.lock_date,
    ob.lock_type,
    ob.active_yn
FROM
    objects ob
    JOIN object_types ot ON ob.object_type_id = ot.object_type_id
    LEFT JOIN objects ob_parent ON ob.parent_object_id = ob_parent.object_id  --some objects don't have a parent schema, for example directory
    LEFT JOIN app_users au ON ob.lock_app_user_id = au.app_user_id
WHERE ot.object_location = 'DB'
/


--
-- V_DATABASE_SCHEMAS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_DATABASE_SCHEMAS
BEQUEATH DEFINER
AS 
SELECT
    ob.object_id as schema_id,
    ob.object_type_id,
    ob.name as schema_name,
    ob.user_comment
FROM
    objects ob
    JOIN object_types ot ON ob.object_type_id = ot.object_type_id
WHERE ot.code = 'DB_SCHEMA'
/


--
-- V_OBJECTS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_OBJECTS
BEQUEATH DEFINER
AS 
SELECT
    o.object_id,
    coalesce(v_dbo.object_type_code, v_apc.object_type_code, v_app.object_type_code) as object_type,
    coalesce(v_dbo.display, v_apc.display, v_app.display) as object_name
FROM 
    objects o
    LEFT JOIN v_database_objects v_dbo ON o.object_id = v_dbo.db_object_id
    LEFT JOIN v_app_components v_apc ON o.object_id = v_apc.app_component_id
    LEFT JOIN v_applications v_app ON o.object_id = v_app.application_id
/


--
-- V_PATCHES  (View) 
--
CREATE OR REPLACE FORCE VIEW V_PATCHES
BEQUEATH DEFINER
AS 
SELECT
    pa.patch_id,
    pa.release_id,
    pa.task_id,
    pr.project_id,
    pa.created_app_user_id,
    pa.owner_app_user_id,
    pa.patch_number,
    pa.automatic_yn,
    pa.created_on,
    pa.confirmed_app_user_id,
    pa.confirmed_on,
    pa.user_comments,
    pa.release_notes,
    ta.code || '_' || pa.patch_number as patch_code,
    ta.code as task_code,
    ta.code || ' - ' || ta.name as task_code_and_name,
    ta.name as task_name,
    ta.code || '_' || pa.patch_number || ' (' || ta.name || ')' as display,
    tg.code || ' - ' || tg.name as task_group_name,
    rls.code as release_code,
    pa.release_order,
    pr.name as project_name,
    usr_cr.display_name as user_created,
    usr_con.display_name as user_confirmed,
    (CASE WHEN pa.confirmed_app_user_id is null THEN 'N' ELSE 'Y' END) as confirmed_yn,
    (CASE WHEN EXISTS 
       (SELECT 1 
        FROM 
            patch_installs pi
            JOIN environments env ON pi.environment_id = env.environment_id
        WHERE 
            pi.patch_id = pa.patch_id
        AND pi.end_date is not null
        AND env.production_yn = 'Y')
        THEN 'Y' ELSE 'N' END) as installed_on_prod_yn,
    (SELECT
        listagg(au.display_name, ', ') within group (order by au.display_name) as user_name
    FROM 
        user_works_on_patch uwop
        JOIN app_users au ON uwop.app_user_id = au.app_user_id
    WHERE 
        uwop.patch_id = pa.patch_id
    AND uwop.stop is null) as currently_works_on_patch,
    ta.finished_yn as task_finished_yn,
    patch_temp.patch_template_id,
    patch_temp.code as patch_template_code,
    pa.for_production_yn,
    ta.external_link,
    usr_ow.display_name as user_owner,
    pa.for_production_comment,
    tg.hidden_yn as task_group_hidden_yn
FROM
    patches pa
    JOIN tasks ta ON pa.task_id = ta.task_id
        JOIN task_groups tg ON ta.task_group_id = tg.task_group_id
            JOIN projects pr ON tg.project_id = pr.project_id
    JOIN app_users usr_cr ON pa.created_app_user_id = usr_cr.app_user_id
    JOIN app_users usr_ow ON pa.owner_app_user_id = usr_ow.app_user_id
    LEFT JOIN app_users usr_con ON pa.confirmed_app_user_id = usr_con.app_user_id
    LEFT JOIN releases rls ON pa.release_id = rls.release_id
    LEFT JOIN patch_templates patch_temp ON patch_temp.code = pkg_settings.f_project_sett_vc2(pr.project_id, 'PATCH_TEMPLATE_CODE')
/


--
-- V_PATCH_OBJ_SRC_SCRIPTS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_PATCH_OBJ_SRC_SCRIPTS
BEQUEATH DEFINER
AS 
SELECT  --database objects
    po.patch_object_id,
    po.patch_id,
    PKG_OBJECTS.f_get_database_object_script(
        p_schema => v_do.db_schema_name, 
        p_name => v_do.db_object_name, 
        p_type => v_do.object_type_code
    ) as object_script,
    pkg_objects.f_source_filename(po.object_id) as source_filename,
    PKG_PATCH_OBJECTS.f_next_version(po.object_id) as next_version
FROM 
    patch_objects po
    JOIN v_database_objects v_do ON po.object_id = v_do.db_object_id
UNION ALL  --application components
SELECT
    po.patch_object_id,
    po.patch_id,
    PKG_OBJECTS.f_get_app_component_script(
        p_app_no => v_ac.application_number, 
        p_component_id => v_ac.app_component_number, 
        p_type => v_ac.object_type_code
    ) as object_script,
    pkg_objects.f_source_filename(po.object_id) as source_filename,
    PKG_PATCH_OBJECTS.f_next_version(po.object_id) as next_version
FROM 
    patch_objects po
    JOIN v_app_components v_ac ON po.object_id = v_ac.app_component_id
UNION ALL  --applications
SELECT
    po.patch_object_id,
    po.patch_id,
    PKG_OBJECTS.f_get_app_script(
        p_app_no => v_app.application_number
    ) as object_script,
    pkg_objects.f_source_filename(po.object_id) as source_filename,
    PKG_PATCH_OBJECTS.f_next_version(po.object_id) as next_version
FROM 
    patch_objects po
    JOIN v_applications v_app ON po.object_id = v_app.application_id
/


--
-- V_PATCH_SCR_AND_OBJ  (View) 
--
CREATE OR REPLACE FORCE VIEW V_PATCH_SCR_AND_OBJ
BEQUEATH DEFINER
AS 
SELECT  --scripts
    null as object_id,
    ps.patch_id,
    v_dbs.schema_name,
    'PATCH_SCRIPT' as object_group,
    pst.code as object_type,
    'script' as object_name,
    PKG_RELEASES.f_script_target_filename(
        p_patch_script_id => ps.patch_script_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'N'
    ) as filename,
    PKG_RELEASES.f_script_target_filename(
        p_patch_script_id => ps.patch_script_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'Y'
    ) as filename_replaced,
    ps.sql_content,
    1 as object_version,
    'N' as object_as_patch_script_yn,
    'Y' as patch_script_yn,
    order_by as seq_nr,
    ps.patch_script_id as seq_nr2
FROM 
    patch_scripts ps
    JOIN v_database_schemas v_dbs ON ps.database_schema_id = v_dbs.schema_id
    JOIN patch_script_types pst ON ps.patch_script_type_id = pst.patch_script_type_id
    JOIN v_patches v_p ON ps.patch_id = v_p.patch_id
UNION ALL
SELECT  --database objects
    po.object_id,
    po.patch_id,
    v_dbo.db_schema_name as schema_name,
    'DB_OBJECT' as object_group,
    v_dbo.object_type_code as object_type,
    v_dbo.display as object_name,
    PKG_RELEASES.f_object_target_filename(
        p_object_id => po.object_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'N'
    ) as filename,
    PKG_RELEASES.f_object_target_filename(
        p_object_id => po.object_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'Y'
    ) as filename_replaced,
    po.sql_content,
    po.object_version,
    po.as_patch_script_yn as object_as_patch_script_yn,
    'N' as patch_script_yn,
    100000 as seq_nr,
    po.patch_object_id as seq_nr2
FROM 
    patch_objects po
    JOIN v_database_objects v_dbo ON po.object_id = v_dbo.db_object_id
    JOIN v_patches v_p ON po.patch_id = v_p.patch_id
UNION ALL
SELECT  --application components
    po.object_id,
    po.patch_id,
    v_apc.app_schema_name as schema_name,
    'APP_COMPONENT' as object_group,
    v_apc.object_type_code as object_type,
    v_apc.display as object_name,
    PKG_RELEASES.f_object_target_filename(
        p_object_id => po.object_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'N'
    ) as filename,
    PKG_RELEASES.f_object_target_filename(
        p_object_id => po.object_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'Y'
    ) as filename_replaced,
    po.sql_content,
    po.object_version,
    'N' as object_as_patch_script_yn,
    'N' as patch_script_yn,
    100010 as seq_nr,
    po.patch_object_id as seq_nr2
FROM
    patch_objects po
    JOIN v_app_components v_apc ON po.object_id = v_apc.app_component_id
    JOIN v_patches v_p ON po.patch_id = v_p.patch_id
UNION ALL
SELECT  --applications
    po.object_id,
    po.patch_id,
    v_app.schema_name as schema_name,
    'APPLICATION' as object_group,
    v_app.object_type_code as object_type,
    v_app.display as object_name,
    PKG_RELEASES.f_object_target_filename(
        p_object_id => po.object_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'N'
    ) as filename,
    PKG_RELEASES.f_object_target_filename(
        p_object_id => po.object_id,
        --p_patch_template_id => v_p.patch_template_id,
        p_replace_schema_yn => 'Y'
    ) as filename_replaced,
    po.sql_content,
    po.object_version,
    'N' as object_as_patch_script_yn,
    'N' as patch_script_yn,
    100020 as seq_nr,
    po.patch_object_id as seq_nr2
FROM
    patch_objects po
    JOIN v_applications v_app ON po.object_id = v_app.application_id
    JOIN v_patches v_p ON po.patch_id = v_p.patch_id
/


--
-- V_RELEASES  (View) 
--
CREATE OR REPLACE FORCE VIEW V_RELEASES
BEQUEATH DEFINER
AS 
SELECT
    rls.release_id,
    rls.project_id,
    rls.code,
    rls.description,
    rls.code || ' - ' || rls.description as display,
    au.app_user_id as user_created_id,
    au.display_name as user_created_display_name,
    pr.code || ' - ' || pr.name as project,
    nvl(v_p.patches_no, 0) as patches_no,
    CASE  --all patches need to be confirmed in order to download RLS ZIP
        WHEN 
            EXISTS (SELECT 1 FROM patches z WHERE z.release_id = rls.release_id AND z.confirmed_on is null) 
            THEN 'N' 
        ELSE 'Y'
    END as download_yn,
    pt.patch_template_id,
    pt.sql_subfolder as patch_template_sql_subfolder,
    pt.procedure_name as patch_template_procedure_name,
    rls.planed_release_date,
    rls.planed_duration 
FROM 
    releases rls
    JOIN projects pr ON rls.project_id = pr.project_id
    JOIN app_users au ON rls.created_app_user_id = au.app_user_id
    JOIN project_settings ps ON rls.project_id = ps.project_id
        JOIN r_settings s ON ps.setting_id = s.setting_id AND s.code = 'PATCH_TEMPLATE_CODE'
    LEFT JOIN patch_templates pt ON ps.value_vc2 = pt.code
    LEFT JOIN
    (
    SELECT
        release_id,
        count(*) as patches_no
    FROM 
        patches p
        JOIN tasks t ON p.task_id = t.task_id
    GROUP BY release_id
    ) v_p ON rls.release_id = v_p.release_id
/


--
-- V_RELEASE_SCRIPTS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_RELEASE_SCRIPTS
BEQUEATH DEFINER
AS 
SELECT 
    rs.release_script_id, 
    rs.release_id, 
    rs.rls_script_type_id, 
    rs.database_schema_id, 
    rs.sql_content, 
    rs.added_on, 
    rs.filename, 
    rs.user_comments, 
    rs.order_by,
    v_dbs.schema_name,
    rst.code as script_type_code,
    rst.name as script_type_name,
    replace(rst.target_folder, '#SCHEMA#', lower(v_dbs.schema_name)) || '/' || rs.filename as filename_for_zip
FROM 
    release_scripts rs
    JOIN release_script_types rst ON rs.rls_script_type_id = rst.rls_script_type_id
    JOIN v_database_schemas v_dbs ON rs.database_schema_id = v_dbs.schema_id
/


--
-- V_WORKSPACES  (View) 
--
CREATE OR REPLACE FORCE VIEW V_WORKSPACES
BEQUEATH DEFINER
AS 
SELECT
    ob.object_id as workspace_id,
    ob.object_type_id,
    ob.name as workspace_name,
    ob.user_comment
FROM
    objects ob
    JOIN object_types ot ON ob.object_type_id = ot.object_type_id
WHERE ot.code = 'WORKSPACE'
/


--
-- V_WORKSPACE_USERS  (View) 
--
CREATE OR REPLACE FORCE VIEW V_WORKSPACE_USERS
BEQUEATH DEFINER
AS 
SELECT
    wu.apex_user_name,
    ws.aa_number_01 as workspace_id,
    ws.name as workspace_name,
    au.display_name,
    au.login_username,
    au.app_user_id
FROM 
    workspace_users wu
    JOIN objects ws ON wu.workspace_id = ws.object_id
    JOIN app_users au on wu.app_user_id = au.app_user_id
/
