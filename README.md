# D.O.M.E. for Oracle *(Deployment Organization Made Easy)*

**DOME for Oracle Database and APEX** is a powerful utility designed to streamline and accelerate development and deployment processes for teams working with PL/SQL and Oracle APEX.

It provides a structured approach to organizing projects, simplifying the creation of installation / deployment scripts, and enhancing overall productivity, making it an essential tool for developers aiming to optimize their workflow.

### Main features:

- **Automated Patch Script Generation**: Quickly and automatically generate patch scripts to streamline development.
- **DDL Operations Recording**: Captures and stores DDL statements executed in monitored database schemas, organizing them into appropriate patches.
- **Multiple Environment Definitions**: Supports multiple target environments for flexible deployment configurations.
- **Activity Tracking**: Monitors and tracks who made changes on objects and components and what was altered.
- **APEX Component and Application Level Support**: Operates effectively on both individual APEX components and entire APEX applications.
- **Database and APEX Object Versioning**: Manages versioning for both database and APEX objects.
- **Object and Pages Locking**: Enables locking of database objects and APEX pages to prevent conflicts during development.
- **Concurrency Management**: Handles concurrency issues during development, minimizing conflicts and ensuring smooth collaboration.
- **Patch Linking**: Allows sharing of objects across patches, facilitating better integration and dependency management.
- **Deployment Tracking**: Keeps track of deployments across different environments, ensuring accurate and consistent rollouts.
- **Patch/Release Dependency Checking**: Verifies dependencies between patches and releases to prevent conflicts and ensure smooth deployments.
- **Script Templates**: Provides templates for various deployment tools like single SQLPlus or SQLcl scripts, target GIT folders, OPAL tools...
- **Patch Overview with Search and Filtering**: Offers a quick overview of patches with robust search and filtering capabilities for easy management.
- **Patch Grouping into Releases**: Organizes patches into releases for more structured and efficient deployments.
- **Release Documentation Preparation**: Automatically prepares detailed documentation for each release, ensuring thorough and accurate records.
- **Hierarchical Patch Organization**: Structures patches within a hierarchy of projects, task groups, tasks, and patches for better organization.
- **Various Utilities**: Includes utilities for preparing installation scripts for binary files, source wrapping, and exporting sources for GIT or other version control systems.

## Change Log
*Complete Change Log can be found in the document [changelog.md](changelog.md).*
- 6.0.0 - 7 new major functionalities and cca 20 improvements / bug fixes
- 5.1.0 - Export patch and release scripts for SQL Plus 
- 5.0.0 - List of application objects changed by current user (helper to add application objects to patch)
- 4.9.1 - Patch warnings (empty patch...) displayed on patch list
- 4.9.0 - Hidden task group (useful for testing or instructions)
- 4.8.2 - Re-sequence patch scripts
- 4.8.1 - Start / stop button on patch details page

## Requirements
- Oracle database 11g R2 or newer
- Oracle APEX 19.2 or newer

## YouTube Videos
For a guidance on using D.O.M.E. and understanding its features, please visit our YouTube channel where you'll find helpful instructional videos.

- [Introduction to the D.O.M.E.](https://youtu.be/psi8gW_XSA8)
- [Let's get familiar with the D.O.M.E.](https://youtu.be/bf6BWGIh9QY)
- [How to install the D.O.M.E.](https://youtu.be/HzDjPasU4OY)

## How to install the DOME
It is strongly recommended to install the DOME in a separate database schema. This approach minimizes intrusion into your development schemas and eliminates the need for granting any unnecessary permissions.

For a DOME user creation You may use the script named [DOME_DB_user.sql](install/DOME_DB_user.sql) located in the [install](install) folder.

### The Installation or Upgrade Process
In order to install a DOME just import the application in Your desired workspace and install supporting objects.

The application and supporting objects are joined in a single installation file [dome.sql](https://github.com/zorantica/dome/blob/main/install/dome.sql) which can be located in the [install](install) folder.

The upgrade process is the same as the installation process. Just import the latest version of the DOME application and overwrite the existing DOME application. During the process upgrade the supporting objects and that's it.

### Installation and Upgrade Remarks

#### "Installation of database objects and seed data has failed." message
After the supporting objects installation You may encounter the message "Installation of database objects and seed data has failed."

First, You should check the Install Summary. If the issues are related to views and packages only, like on the picure below, then it is fine. The problem is with the order of the views and packages generation and their in-between dependencies.

![](https://github.com/zorantica/dome/blob/main/Install_Summary.png)

Second, check if there are any invalid DOME objects in the schema where the DOME is installed. There should be none because at the end of the supporting object scripts there is a script which recompiles all objects in the schema.  

#### Roles and Grants
A user / schema in which the DOME is installed should have following roles and grants granted:
- APEX_ADMINISTRATOR_READ_ROLE role
- execute grant on dbms_crypto package
- select grant on dba_objects view
- select grant on dba_tab_columns view

*If You used the script from the install folder to create a new user then all those grants and roles should be correctly granted.*

### First Login in the DOME
After the instalation You should be able to login into the DOME with the username "admin" and password "admin".

Then You can configure the DOME for Your projects and users.

## How to configure and use the DOME
Manuals are located in the repository under the folder [manuals](manuals).

## Quick preview
![](https://github.com/zorantica/dome/blob/main/preview/preview01.jpg)
