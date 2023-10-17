SET DEFINE OFF;
--
-- APUSRPRJ_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER apusrprj_trg_inc BEFORE
    INSERT ON app_user_projects
    FOR EACH ROW
WHEN ( new.app_user_project_id IS NULL )
BEGIN
    :new.app_user_project_id := seq_app_user_projects.nextval;
END;
/


--
-- ENV_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER env_trg_inc BEFORE
    INSERT ON environments
    FOR EACH ROW
WHEN ( new.environment_id IS NULL )
BEGIN
    :new.environment_id := seq_environments.nextval;
END;
/


--
-- EXCLREC_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER exclrec_trg_inc BEFORE
    INSERT ON exclude_from_recording
    FOR EACH ROW
WHEN ( new.exclude_from_recording_id IS NULL )
BEGIN
    :new.exclude_from_recording_id := seq_exclude_from_recording.nextval;
END;
/


--
-- LNKPATCH_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER lnkpatch_trg_inc BEFORE
    INSERT ON linked_patches
    FOR EACH ROW
WHEN ( new.linked_patch_id IS NULL )
BEGIN
    :new.linked_patch_id := seq_linked_patches.nextval;
END;
/


--
-- OBJTYP_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER objtyp_trg_inc BEFORE
    INSERT ON object_types
    FOR EACH ROW
WHEN ( new.object_type_id IS NULL )
BEGIN
    :new.object_type_id := seq_object_types.nextval;
END;
/


--
-- OBJ_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER obj_trg_inc BEFORE
    INSERT ON objects
    FOR EACH ROW
WHEN ( new.object_id IS NULL )
BEGIN
    :new.object_id := seq_objects.nextval;
END;
/


--
-- PDS_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER pds_trg_inc BEFORE
    INSERT ON project_database_schemas
    FOR EACH ROW
WHEN ( new.project_database_schema_id IS NULL )
BEGIN
    :new.project_database_schema_id := seq_project_database_schemas.nextval;
END;
/


--
-- PRJAPP_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER prjapp_trg_inc BEFORE
    INSERT ON project_apps
    FOR EACH ROW
WHEN ( new.project_app_id IS NULL )
BEGIN
    :new.project_app_id := seq_project_apps.nextval;
END;
/


--
-- PRJ_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER prj_trg_inc BEFORE
    INSERT ON projects
    FOR EACH ROW
WHEN ( new.project_id IS NULL )
BEGIN
    :new.project_id := seq_projects.nextval;
END;
/


--
-- PRSET_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER prset_trg_inc BEFORE
    INSERT ON project_settings
    FOR EACH ROW
WHEN ( new.project_setting_id IS NULL )
BEGIN
    :new.project_setting_id := seq_project_settings.nextval;
END;
/


--
-- PSCR_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER pscr_trg_inc BEFORE
    INSERT ON patch_scripts
    FOR EACH ROW
WHEN ( new.patch_script_id IS NULL )
BEGIN
    :new.patch_script_id := seq_patch_scripts.nextval;
END;
/


--
-- PTCHDISAPP_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchdisapp_trg_inc BEFORE
    INSERT ON patch_disable_apps
    FOR EACH ROW
WHEN ( new.patch_disable_app_id IS NULL )
BEGIN
    :new.patch_disable_app_id := seq_patch_disable_apps.nextval;
END;
/


--
-- PTCHINST_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchinst_trg_inc BEFORE
    INSERT ON patch_installs
    FOR EACH ROW
WHEN ( new.patch_install_id IS NULL )
BEGIN
    :new.patch_install_id := seq_patch_installs.nextval;
END;
/


--
-- PTCHOBJ_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchobj_trg_inc BEFORE
    INSERT ON patch_objects
    FOR EACH ROW
WHEN ( new.patch_object_id IS NULL )
BEGIN
    :new.patch_object_id := seq_patch_objects.nextval;
END;
/


--
-- PTCHOTF_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchotf_trg_inc BEFORE
    INSERT ON patch_obj_type_folders
    FOR EACH ROW
WHEN ( new.patch_obj_type_folder_id IS NULL )
BEGIN
    :new.patch_obj_type_folder_id := seq_patch_obj_type_folders.nextval;
END;
/


--
-- PTCHSTYPE_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchstype_trg_inc BEFORE
    INSERT ON patch_script_types
    FOR EACH ROW
WHEN ( new.patch_script_type_id IS NULL )
BEGIN
    :new.patch_script_type_id := seq_patch_script_types.nextval;
END;
/


--
-- PTCHTMPFL_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchtmpfl_trg_inc BEFORE
    INSERT ON patch_template_files
    FOR EACH ROW
WHEN ( new.patch_template_file_id IS NULL )
BEGIN
    :new.patch_template_file_id := seq_patch_template_files.nextval;
END;
/


--
-- PTCHTMPL_TRG_ARI  (Trigger) 
--
CREATE OR REPLACE TRIGGER PTCHTMPL_TRG_ARI
AFTER INSERT
ON PATCH_TEMPLATES
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
    INSERT INTO patch_obj_type_folders (
        patch_template_id, 
        object_type_id, 
        source_folder,
        target_folder
    )
    SELECT 
        :new.patch_template_id,
        object_type_id, 
        source_folder,
        target_folder
    FROM object_types
    ;
END;
/


--
-- PTCHTMPL_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptchtmpl_trg_inc BEFORE
    INSERT ON patch_templates
    FOR EACH ROW
WHEN ( new.patch_template_id IS NULL )
BEGIN
    :new.patch_template_id := seq_patch_templates.nextval;
END;
/


--
-- PTCH_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER ptch_trg_inc BEFORE
    INSERT ON patches
    FOR EACH ROW
WHEN ( new.patch_id IS NULL )
BEGIN
    :new.patch_id := seq_patches.nextval;
END;
/


--
-- RELDPTXT_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER reldptxt_trg_inc BEFORE
    INSERT ON release_doc_part_txt
    FOR EACH ROW
WHEN ( new.release_doc_part_txt_id IS NULL )
BEGIN
    :new.release_doc_part_txt_id := seq_release_doc_part_txt.nextval;
END;
/


--
-- RELDP_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER reldp_trg_inc BEFORE
    INSERT ON release_doc_parts
    FOR EACH ROW
WHEN ( new.release_doc_part_id IS NULL )
BEGIN
    :new.release_doc_part_id := seq_release_doc_parts.nextval;
END;
/


--
-- RELEASES_ARI  (Trigger) 
--
CREATE OR REPLACE TRIGGER RELEASES_ARI
AFTER INSERT
ON RELEASES
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
    
    INSERT INTO release_doc_part_txt (release_doc_part_id, release_id)
    SELECT release_doc_part_id, :NEW.release_id
    FROM release_doc_parts rdp
    WHERE project_id = :NEW.project_id
    ;
    
END RELEASES_ARI;
/


--
-- RLSSTYPE_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER rlsstype_trg_inc BEFORE
    INSERT ON release_script_types
    FOR EACH ROW
WHEN ( new.rls_script_type_id IS NULL )
BEGIN
    :new.rls_script_type_id := seq_release_script_types.nextval;
END;
/


--
-- RLS_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER rls_trg_inc BEFORE
    INSERT ON releases
    FOR EACH ROW
WHEN ( new.release_id IS NULL )
BEGIN
    :new.release_id := seq_releases.nextval;
END;
/


--
-- RSCR_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER rscr_trg_inc BEFORE
    INSERT ON release_scripts
    FOR EACH ROW
WHEN ( new.release_script_id IS NULL )
BEGIN
    :new.release_script_id := seq_release_scripts.nextval;
END;
/


--
-- RSETT_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER rsett_trg_inc BEFORE
    INSERT ON r_settings
    FOR EACH ROW
WHEN ( new.setting_id IS NULL )
BEGIN
    :new.setting_id := seq_r_settings.nextval;
END;
/


--
-- TRG_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER trg_trg_inc BEFORE
    INSERT ON task_groups
    FOR EACH ROW
WHEN ( new.task_group_id IS NULL )
BEGIN
    :new.task_group_id := seq_task_groups.nextval;
END;
/


--
-- TSK_ARI  (Trigger) 
--
CREATE OR REPLACE TRIGGER TSK_ARI
AFTER INSERT
ON TASKS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
    INSERT INTO patches (
        task_id,
        created_app_user_id,
        owner_app_user_id
    )
    VALUES (
        :NEW.task_id,
        :NEW.app_user_id,
        :NEW.app_user_id
    );
END;
/


--
-- TSK_TRG_BRU  (Trigger) 
--
CREATE OR REPLACE TRIGGER tsk_trg_bru BEFORE
    UPDATE OF finished_yn ON tasks
    FOR EACH ROW
BEGIN
    if :old.finished_yn = 'N' and :new.finished_yn = 'Y' then
        :new.finished_on := sysdate;
    end if;

    if :old.finished_yn = 'Y' and :new.finished_yn = 'N' then
        :new.finished_on := null;
    end if;
END;
/


--
-- TSK_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER tsk_trg_inc BEFORE
    INSERT ON tasks
    FOR EACH ROW
WHEN ( new.task_id IS NULL )
BEGIN
    :new.task_id := seq_tasks.nextval;
END;
/


--
-- USR_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER usr_trg_inc BEFORE
    INSERT ON app_users
    FOR EACH ROW
WHEN ( new.app_user_id IS NULL )
BEGIN
    :new.app_user_id := seq_app_users.nextval;
END;
/


--
-- UWOP_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER uwop_trg_inc BEFORE
    INSERT ON user_works_on_patch
    FOR EACH ROW
WHEN ( new.uwop_id IS NULL )
BEGIN
    :new.uwop_id := seq_user_works_on_patch.nextval;
END;
/


--
-- WROBJTYP_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER wrobjtyp_trg_inc BEFORE
    INSERT ON wrap_object_types
    FOR EACH ROW
WHEN ( new.wrap_object_type_id IS NULL )
BEGIN
    :new.wrap_object_type_id := seq_wrap_object_types.nextval;
END;
/


--
-- WROBSRC_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER wrobsrc_trg_inc BEFORE
    INSERT ON wrap_object_sources
    FOR EACH ROW
WHEN ( new.wrap_object_source_id IS NULL )
BEGIN
    :new.wrap_object_source_id := seq_wrap_object_sources.nextval;
END;
/


--
-- WSPUS_TRG_INC  (Trigger) 
--
CREATE OR REPLACE TRIGGER wspus_trg_inc BEFORE
    INSERT ON workspace_users
    FOR EACH ROW
WHEN ( new.workspace_user_id IS NULL )
BEGIN
    :new.workspace_user_id := seq_workspace_users.nextval;
END;
/
