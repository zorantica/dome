BEGIN
    DBMS_UTILITY.compile_schema(schema => 'DOME', compile_all => true);
END;
/

SELECT object_type, object_name
FROM user_objects
WHERE status <> 'VALID'
ORDER BY 1, 2
;