--execute this grant in DOME schema and allow monitored schema to access DOME interface package
--change schema names for DOME schema and monitored schema for Your purpose
GRANT EXECUTE ON DOME.PKG_INTERFACE TO #SCHEMA#;



--execute this grant in monitored schema to allow DOME access to interface package (dome utils)
GRANT EXECUTE ON dome_mon01.pkg_dome_utils TO DOME;
