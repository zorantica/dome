# Change Log

## 5.2.0
### New functionalities:
- Multilanguage support for applications and components export
- Patch and object scripts search
- Modernized code editor (Monaco VS plugin)
- Display an object script from the object history
- 2 object script versions comparison (using Monaco VS plugin)
- Generate scripts for schema monitoring setup
- A new DOME Installation Process using APEX Supporting Objects

### Improvements and bug fixes:
- Patch details page - Corrent next patch number within the same task
- Patch details page - "Automatic Y/N" flag for the new patch
- Object history overview page - added a column "installed on environments" 
- Releases page - interactive report - added a column "release date"
- Patches list page - Refresh patches report region after including patches in the release
- Patches list page - Improved IR layout (control break, order by, columns...)
- Patches list page - "Installed on" column without escaping special characters
- Patch details page - Improved default layout on Applications and Components region
- Patch details page - Added components concurrency control when adding a component to the patch from Select components page
- Patch details page - Automatic Refresh of components after selecting on Applications and Components region
- Replace special characters " and ' in the file name of the produced patch
- Patch details page - Cancel button navigation
- Object history page - Added a link to patch details page
- Patch details page - Unified icons for columns
- Unified history column label name through the application
- History page - Displayed a selected object name
- Patch details page - changes warning solved
- SQLPLUS template - a few bugs solved (BAT file content, installation start/end evidence...)



## Previous versions
- 5.1.0 - Export patch and release scripts for SQL Plus 
- 5.0.0 - List of application objects changed by current user (helper to add application objects to patch)
- 4.9.1 - Patch warnings (empty patch...) displayed on patch list
- 4.9.0 - Hidden task group (useful for testing or instructions)
- 4.8.2 - Re-sequence patch scripts
- 4.8.1 - Start / stop button on patch details page
- 4.8.0 - Linked patches (both share the same object and should be installed together) (input, ignore locks for common database objects)
- 4.7.0 - Naming pattern to exclude objects from automatically adding to patch or objects
- 4.6.0 - Pre-release custom scripts (stop apps and similar)
- 4.5.0 - Refresh ORDS object list
- 4.4.2 - Display comments for production upgrade instructions on patch list
- 4.4.1 - Mark objects as inactive (automatically mark during objects refresh; display inactive indicator in name)
- 4.4.0 - Export static application files scripts
- 4.3.0 - Release report (patches and objects list in Markdown and HTML format)
- 4.2.1 - Throw an error with nice description if object type doesn't exist during database object DDL
- 4.2.0 - List of all objects which are included in release
- 4.1.0 - Download release scripts
- 4.0.1 - When adding new object to patch - check if it is included in other active patch
- 4.0.0 - Patch dependency controls
- 3.6.1 - Patch unlock allowed
- 3.6.0 - External task link
- 3.5.0 - Create release from patches list page
- 3.4.1 - History -> mark row for current patch
- 3.4.0 - Include REST in patch
- 3.3.0 - Wrap package bodies
- 3.2.1 - Refresh one object script after the patch is confirmed
- 3.2.0 - Lock database objects
- 3.1.1 - Application script on patch confirm (dynamic)
- 3.1.0 - Implement history and script view for all objects
- 3.0.0 - Releases
- 2.3.1 - Change comments after patch is confirmed
- 2.3.0 - Download patch or source from patch details page (open modal window because of IG)
- 2.2.0 - Refresh script and DB objects regions with button on patch details page
- 2.1.0 - Enable user comment of patch script
- 2.0.3 - Check trigger generation scripts and missing "/"
- 2.0.2 - Record COMMENT and other system events
- 2.0.1 - Prepare scripts for coping into git source folder
- 2.0.0 - Record DDL operations
- 1.2.0 - Mark installation on environment
- 1.1.2 - Add/edit script files after patch is confirmed
- 1.1.1 - Display patches for objects
- 1.1.0 - Utility which prepares script for BLOB/CLOB upload
- 1.0.3 - Edit object script files after patch is confirmed (need to implement CLOB upload)
- 1.0.2 - Add application number to page script file name
- 1.0.1 - Refresh app objects from patch details page
- 1.0.0 - Initial release
