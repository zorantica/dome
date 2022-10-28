# D.O.M.E. (Deployment Organization Made Easy)
DOME for Oracle database and Oracle APEX is a tool which helps developer teams to organize and speed-up deployment (installation) scripts production processes.

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
- 1.0 - Initial Release

## Requirements
- Oracle database 11g R2 or newer
- Oracle APEX 22.1.4 or newer

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
Script no. 00 is optional and it helps to create database user / schema.

If You are going to use this script please enter correct user name, password and tablespaces for Your database.

A user, in which the DOME is installed, should have following roles and grants assigned:
- APEX_ADMINISTRATOR_READ_ROLE role assigned
- execute grant on dbms_crypto package
- select grant on dba_objects view

Script no. 06 is used to recompile the schema, in which DOME is installed, at the end of installation. Please provide a correct schema name.

Script no. 50 is APEX application script, which should be imported in appropriate workspace (using APEX GUI or from a client such as SQLcl, SQLPlus, SQL Developer...).

### First Login
After all scripts are installed You should be able to login into DOME with username "admin" and password "admin".

## How to configure and use DOME
Manuals are located in repository under folder "manuals".

## Quick preview
![](https://github.com/zorantica/dome/blob/main/preview/preview01.jpg)
