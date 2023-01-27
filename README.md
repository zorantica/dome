# D.O.M.E. for Oracle 5.1 *(Deployment Organization Made Easy)*

DOME for Oracle database and APEX is a utility, which helps developer teams developing in PL/SQL and APEX to organize and speed-up development and deployment processes and installation scripts production.

Build by developers and meant for developers. 

Main features:
- Swift and automatic patch scripts generation
- Records DDL operations in database schemas and stores them in appropriate patches
- Multiple target environments definitions
- Tracks “who did what”
- Works on both APEX component level and APEX application level
- Database and APEX objects versioning
- Locking database objects and APEX pages
- Handling concurrency during development
- Linking patches (objects share)
- Tracks deployment to different environments
- Patch / release dependencies check
- Script templates (single SQLPlus or SQLcl scripts, target GIT folders, OPAL tools...)
- Quick overview of patches with search and filtering
- Groups patches into releases
- Prepares a release documentation
- Hierarchical organization of patches (projects – task groups – tasks – patches)
- Utilities such as: prepare installation scripts for binary files, source wrapping, export source (for GIT or other version control) 


## Change Log
- 5.1.0 - Export patch and release scripts for SQL Plus 
- 5.0.0 - List of application objects changed by current user (helper to add application objects to patch)
- 4.9.1 - Patch warnings (empty patch...) displayed on patch list
- 4.9.0 - Hidden task group (useful for testing or instructions)
- 4.8.2 - Re-sequence patch scripts
- 4.8.1 - Start / stop button on patch details page

*Complete Change Log can be found in document [changelog.md](changelog.md).*


## Requirements
- Oracle database 11g R2 or newer
- Oracle APEX 19.2 or newer

## How to install DOME
It is strongly recommended to install DOME into separate database schema and provide only necessary grants.

### Installation scripts
Download scripts from "install" folder and install them in provided order.

Scripts: 
- 00 - db user (optional).sql
- 01 - tables.sql
- 02 - sequences.sql
- 03 - triggers.sql
- 04 - views.sql
- 05 - packages.sql
- 06 - recompile schema.sql
- 20 - admin app user.sql
- 25 - data.sql
- 50 - APEX application.sql

### Installation Remarks
Script no. 00 is optional and it helps to create DOME database user / schema. If You are going to use this script please enter correct user name, password and tablespaces for Your database.

A user / schema, in which the DOME is installed, should have following roles and grants assigned:
- APEX_ADMINISTRATOR_READ_ROLE role assigned
- execute grant on dbms_crypto package
- select grant on dba_objects view
- select grant on dba_tab_columns view

Script no. 06 is used to recompile the schema, in which DOME is installed, at the end of installation. Please provide a correct schema name and check invalid objects (should be none).

Script no. 50 is APEX application script, which should be imported in appropriate workspace (using APEX GUI or from a client such as SQLcl, SQLPlus, SQL Developer...).

### First Login
After all scripts are installed You should be able to login into DOME with username "admin" and password "admin".

## How to configure and use DOME
Manuals are located in repository under folder "manuals".


## Quick preview
![](https://github.com/zorantica/dome/blob/main/preview/preview01.jpg)
