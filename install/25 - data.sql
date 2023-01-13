SET DEFINE OFF;

Insert into PROJECTS
   (PROJECT_ID, NAME, CODE)
 Values
   (1, 'Default project', 'DEFP');


Insert into R_SETTINGS
   (SETTING_ID, CODE, NAME, HIDDEN_YN)
 Values
   (6, 'REL_DOC_HTML_TEMPL', 'Release HTML document template', 'N');
Insert into R_SETTINGS
   (SETTING_ID, CODE, NAME, HIDDEN_YN)
 Values
   (5, 'REL_DOC_MD_TEMPLATE', 'Release markdown document template', 'N');
Insert into R_SETTINGS
   (SETTING_ID, CODE, NAME, HIDDEN_YN)
 Values
   (2, 'PATCH_TEMPLATE_CODE', 'Patch template code', 'N');
Insert into R_SETTINGS
   (SETTING_ID, CODE, NAME, HIDDEN_YN)
 Values
   (7, 'RLS_TEMPLATE_CODE', 'Patch template code for Release', 'N');



Insert into PROJECT_SETTINGS
   (PROJECT_SETTING_ID, PROJECT_ID, SETTING_ID, VALUE_VC2)
 Values
   (6, 1, 6, '<html>'||CHR(13)||CHR(10)||'<head>'||CHR(13)||CHR(10)||'<TITLE>Release #RELEASE_CODE# - #RELEASE_NAME#</TITLE>'||CHR(13)||CHR(10)||'</head>'||CHR(13)||CHR(10)||'<body>'||CHR(13)||CHR(10)||'<h1>Release #RELEASE_CODE# - #RELEASE_NAME#</h1>'||CHR(13)||CHR(10)||'<h2>Time of release</h2>'||CHR(13)||CHR(10)||'<p>Date: #RELEASE_DATE#<br />Time: #RELEASE_TIME#<br />Duration: #RELEASE_DURATION#</p>'||CHR(13)||CHR(10)||'<h2>Timeout</h2>'||CHR(13)||CHR(10)||'<p>#TIMEOUT#</p>'||CHR(13)||CHR(10)||'<h2>Release content</h2>'||CHR(13)||CHR(10)||'<h3>Confirmed and included tasks/patches in the release</h3>'||CHR(13)||CHR(10)||'<p>#TASKS#</p>'||CHR(13)||CHR(10)||'<h3><br />Not confirmed yet but needs to be included in the release</h3>'||CHR(13)||CHR(10)||'<p>#NOT_CONFIRMED#</p>'||CHR(13)||CHR(10)||'<h3>Will not be included in the release</h3>'||CHR(13)||CHR(10)||'<p>#NOT_INCLUDED#</p>'||CHR(13)||CHR(10)||'<h3>Application and database objects in the release</h3>'||CHR(13)||CHR(10)||'<p>#OBJECTS#</p>'||CHR(13)||CHR(10)||'</body>'||CHR(13)||CHR(10)||'</html>');
Insert into PROJECT_SETTINGS
   (PROJECT_SETTING_ID, PROJECT_ID, SETTING_ID, VALUE_VC2)
 Values
   (5, 1, 5, '# Release #RELEASE_CODE# - #RELEASE_NAME#'||CHR(13)||CHR(10)||'## Time of release'||CHR(13)||CHR(10)||'Date: #RELEASE_DATE#'||CHR(13)||CHR(10)||'Time: #RELEASE_TIME#'||CHR(13)||CHR(10)||'Duration: #RELEASE_DURATION#'||CHR(13)||CHR(10)||'## Timeout'||CHR(13)||CHR(10)||'#TIMEOUT#'||CHR(13)||CHR(10)||'## Release content'||CHR(13)||CHR(10)||'### Confirmed and included tasks/patches in the release'||CHR(13)||CHR(10)||'#TASKS#'||CHR(13)||CHR(10)||'### Not confirmed yet but needs to be included in the release'||CHR(13)||CHR(10)||'#NOT_CONFIRMED#'||CHR(13)||CHR(10)||'### Will not be included in the release'||CHR(13)||CHR(10)||'#NOT_INCLUDED#'||CHR(13)||CHR(10)||'### Application and database objects in the release'||CHR(13)||CHR(10)||'#OBJECTS#');
Insert into PROJECT_SETTINGS
   (PROJECT_SETTING_ID, PROJECT_ID, SETTING_ID, VALUE_VC2)
 Values
   (2, 1, 2, 'SQLPLUS');
SET DEFINE OFF;
Insert into PROJECT_SETTINGS
   (PROJECT_SETTING_ID, PROJECT_ID, SETTING_ID, VALUE_VC2)
 Values
   (7, 1, 7, 'SQLPLUS_RLS');


Insert into PATCH_TEMPLATES
   (PATCH_TEMPLATE_ID, CODE, NAME, PROCEDURE_NAME, SQL_SUBFOLDER)
 Values
   (2, 'SQLPLUS_RLS', 'SQL Plus install scripts for Release', 'pkg_scripts.p_sqlplus_release_p', 'Patches');
Insert into PATCH_TEMPLATES
   (PATCH_TEMPLATE_ID, CODE, NAME, PROCEDURE_NAME, SQL_SUBFOLDER)
 Values
   (1, 'SQLPLUS', 'SQL Plus install scripts', 'pkg_scripts.p_sqlplus_multiple_files_p', 'sql');

Insert into PATCH_TEMPLATE_FILES
   (PATCH_TEMPLATE_FILE_ID, FILE_NAME, PATCH_TEMPLATE_ID, FILE_CONTENT, USAGE_TYPE)
 Values
   (57, 'documentation/instructions.txt', 1, pkg_utils.f_clob_to_blob('- Use SQLPlus.exe to execute install.sql file'||CHR(13)||CHR(10)||'- Provide necessary information (connection strings, environment data...)'||CHR(13)||CHR(10)||'- Install logs will be stored in /LOGS folder'), 'A');
Insert into PATCH_TEMPLATE_FILES
   (PATCH_TEMPLATE_FILE_ID, FILE_NAME, PATCH_TEMPLATE_ID, FILE_CONTENT, USAGE_TYPE)
 Values
   (58, 'documentation/release_notes.txt', 1, pkg_utils.f_clob_to_blob('Release notes:'||CHR(13)||CHR(10)||'__RELEASE_NOTES__'), 'A');
Insert into PATCH_TEMPLATE_FILES
   (PATCH_TEMPLATE_FILE_ID, FILE_NAME, PATCH_TEMPLATE_ID, FILE_CONTENT, USAGE_TYPE)
 Values
   (59, 'documentation/content.txt', 1, pkg_utils.f_clob_to_blob('Application: __APP_NAME__'||CHR(13)||CHR(10)||'Patch Code: __CODE__'||CHR(13)||CHR(10)||'Patch Name: __NAME__'||CHR(13)||CHR(10)||'Author: __AUTHOR__'||CHR(13)||CHR(10)||'Version: __VERSION__'||CHR(13)||CHR(10)||'Comment: __COMMENT__'), 'A');
Insert into PATCH_TEMPLATE_FILES
   (PATCH_TEMPLATE_FILE_ID, FILE_NAME, PATCH_TEMPLATE_ID, FILE_CONTENT, USAGE_TYPE)
 Values
   (62, 'log/log.txt', 1, pkg_utils.f_clob_to_blob('will be filled after first install'), 'A');
Insert into PATCH_TEMPLATE_FILES
   (PATCH_TEMPLATE_FILE_ID, FILE_NAME, PATCH_TEMPLATE_ID, FILE_CONTENT, USAGE_TYPE)
 Values
   (61, 'install.bat', 1, pkg_utils.f_clob_to_blob('sqlplus @install.sql /nolog'), 'A');
Insert into PATCH_TEMPLATE_FILES
   (PATCH_TEMPLATE_FILE_ID, FILE_NAME, PATCH_TEMPLATE_ID, FILE_CONTENT, USAGE_TYPE)
 Values
   (64, 'install.bat', 2, pkg_utils.f_clob_to_blob('sqlplus @install.sql /nolog'), 'A');


Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, TARGET_FOLDER, SOURCE_FOLDER, 
    RECORD_AS)
 Values
   (4, 'APP', 'Application', 'sql/#SCHEMA#/130_apex', '/app/apex/full', 
    'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (5, 'PAGE', 'Page', 'APP', 'sql/#SCHEMA#/130_apex', 
    'APPS/APEX/components/f#APP_ID#/application/pages', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (6, 'LOV', 'List of values', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, RECORD_AS)
 Values
   (7, 'WORKSPACE', 'APEX Applications workspace', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, RECORD_AS)
 Values
   (8, 'DB_SCHEMA', 'Database schema', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (9, 'APP_ITEM', 'Application item', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (10, 'APP_PROCESS', 'Application process', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (11, 'LIST', 'List', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (12, 'BREADCRUMB', 'Breadcrumb', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (43, 'SYNONYM', 'Database synonym', 'DB', 'sql/#SCHEMA#/050_synonyms', 
    'DB/#SCHEMA#/synonyms', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (44, 'SEQUENCE', 'Database sequence', 'DB', 'sql/#SCHEMA#/020_sequences', 
    'DB/#SCHEMA#/sequences', 'SCRIPT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (45, 'TYPE', 'Database type', 'DB', 'sql/#SCHEMA#/030_types', 
    'DB/#SCHEMA#/types', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (46, 'TABLE', 'Database table', 'DB', 'sql/#SCHEMA#/040_tables', 
    'DB/#SCHEMA#/tables', 'SCRIPT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (47, 'PROCEDURE', 'Database procedures', 'DB', 'sql/#SCHEMA#/070_procedures', 
    'DB/#SCHEMA#/procedures', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (48, 'FUNCTION', 'Database function', 'DB', 'sql/#SCHEMA#/080_functions', 
    'DB/#SCHEMA#/functions', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS, RECORD_AS_OBJECT_TYPE_ID)
 Values
   (50, 'INDEX', 'Database table index', 'DB', 'sql/#SCHEMA#/040_tables', 
    'DB/#SCHEMA#/tables', 'SCRIPT', 46);
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (13, 'APP_ACL', 'APP_ACL', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (14, 'APP_COMPUTATION', 'APP_COMPUTATION', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (15, 'APP_SETTING', 'APP_SETTING', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (16, 'AUTHENTICATION', 'AUTHENTICATION', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (17, 'AUTHORIZATION', 'AUTHORIZATION', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (18, 'BREADCRUMB_ENTRY', 'BREADCRUMB_ENTRY', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (19, 'BREADCRUMB_TEMPLATE', 'BREADCRUMB_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (20, 'BUILD_OPTION', 'BUILD_OPTION', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (21, 'BUTTON_TEMPLATE', 'BUTTON_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (22, 'CALENDAR_TEMPLATE', 'CALENDAR_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (23, 'CREDENTIAL', 'CREDENTIAL', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (24, 'DATA_LOADING', 'DATA_LOADING', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (25, 'DATA_PROFILE', 'DATA_PROFILE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (26, 'LABEL_TEMPLATE', 'LABEL_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (27, 'LIST_TEMPLATE', 'LIST_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (28, 'MESSAGE', 'MESSAGE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (29, 'NAVBAR', 'NAVBAR', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (30, 'PAGE_TEMPLATE', 'PAGE_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (31, 'PARENT_TAB', 'PARENT_TAB', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (32, 'PLUGIN', 'PLUGIN', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (33, 'POPUP_LOV_TEMPLATE', 'POPUP_LOV_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (34, 'REGION_TEMPLATE', 'REGION_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (35, 'REMOTE_SERVER', 'REMOTE_SERVER', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (36, 'REPORT_QUERY', 'REPORT_QUERY', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (37, 'REPORT_TEMPLATE', 'REPORT_TEMPLATE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (38, 'SHORTCUT', 'SHORTCUT', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (39, 'TAB', 'TAB', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (40, 'TREE', 'TREE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (41, 'WEB_SERVICE', 'WEB_SERVICE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (42, 'WEB_SOURCE', 'WEB_SOURCE', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (49, 'PACKAGE BODY', 'Database package body', 'DB', 'sql/#SCHEMA#/100_package_bodies', 
    'DB/#SCHEMA#/packages', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (1, 'PACKAGE', 'Database package', 'DB', 'sql/#SCHEMA#/090_packages', 
    'DB/#SCHEMA#/packages', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (2, 'TRIGGER', 'Database trigger', 'DB', 'sql/#SCHEMA#/110_triggers', 
    'DB/#SCHEMA#/triggers', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (3, 'VIEW', 'Database view', 'DB', 'sql/#SCHEMA#/060_views', 
    'DB/#SCHEMA#/views', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (53, 'DIRECTORY', 'Database directory', 'DB', 'sql/#SCHEMA#/045_directories', 
    'DB/#SCHEMA#/directories', 'SCRIPT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (54, 'TYPE BODY', 'Database type body', 'DB', 'sql/#SCHEMA#/035_type_bodies', 
    'DB/#SCHEMA#/types', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (55, 'STATIC_APP_FILE', 'Static application file', 'APP', 'sql/#SCHEMA#/130_apex', 
    '/app/apex/full', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (52, 'ORDS', 'ORDS RESTful Data Services', 'DB', 'sql/#SCHEMA#/140_ords', 
    'ORDS/#SCHEMA#', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (56, 'CONTEXT', 'DB Context', 'DB', 'sql/#SCHEMA#/044_contexts', 
    'DB/#SCHEMA#/contexts', 'OBJECT');
Insert into OBJECT_TYPES
   (OBJECT_TYPE_ID, CODE, NAME, OBJECT_LOCATION, TARGET_FOLDER, 
    SOURCE_FOLDER, RECORD_AS)
 Values
   (57, 'SNAPSHOT', 'Database Snapshot', 'DB', 'sql/#SCHEMA#/060_views', 
    'DB/#SCHEMA#/snapshots', 'OBJECT');


Insert into PATCH_SCRIPT_TYPES
   (PATCH_SCRIPT_TYPE_ID, CODE, NAME, TARGET_FOLDER, DEFAULT_YN, 
    SEQ)
 Values
   (9, 'OTHER_DDL', 'Other DDL scripts (comment, analyze...)', 'sql/#SCHEMA#/115_other_ddl', 'N', 
    6);
Insert into PATCH_SCRIPT_TYPES
   (PATCH_SCRIPT_TYPE_ID, CODE, NAME, TARGET_FOLDER, DEFAULT_YN, 
    SEQ)
 Values
   (1, 'PRE', 'Pre-install', 'sql/#SCHEMA#/010_preinstall', 'Y', 
    1);
Insert into PATCH_SCRIPT_TYPES
   (PATCH_SCRIPT_TYPE_ID, CODE, NAME, TARGET_FOLDER, DEFAULT_YN, 
    SEQ)
 Values
   (2, 'POST', 'Post-install', 'sql/#SCHEMA#/200_postinstall', 'N', 
    5);
Insert into PATCH_SCRIPT_TYPES
   (PATCH_SCRIPT_TYPE_ID, CODE, NAME, TARGET_FOLDER, DEFAULT_YN, 
    SEQ)
 Values
   (3, 'DATA', 'Data', 'sql/#SCHEMA#/120_data', 'N', 
    2);
Insert into PATCH_SCRIPT_TYPES
   (PATCH_SCRIPT_TYPE_ID, CODE, NAME, DEFAULT_YN, SEQ)
 Values
   (4, 'DDL', 'DDL scripts', 'N', 3);

Insert into RELEASE_SCRIPT_TYPES
   (RLS_SCRIPT_TYPE_ID, CODE, NAME, TARGET_FOLDER, SEQ)
 Values
   (1, 'PRE_RLS', 'Pre-release', 'pre_rls/#SCHEMA#', 1);
Insert into RELEASE_SCRIPT_TYPES
   (RLS_SCRIPT_TYPE_ID, CODE, NAME, TARGET_FOLDER, SEQ)
 Values
   (2, 'POST_RLS', 'Post-release', 'post_rls/#SCHEMA#', 2);


COMMIT;
