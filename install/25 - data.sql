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
   (2, 1, 2, 'SINGLE');


Insert into PATCH_TEMPLATES
   (PATCH_TEMPLATE_ID, CODE, NAME, PROCEDURE_NAME, SQL_SUBFOLDER)
 Values
   (1, 'SINGLE', 'Single installation script', 'pkg_patch_templates.p_single_template_files', null);


COMMIT;
