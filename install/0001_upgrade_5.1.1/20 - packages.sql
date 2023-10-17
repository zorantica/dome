set define off;

Prompt Package Body PKG_LOB_2_SCRIPT;
CREATE OR REPLACE PACKAGE BODY pkg_lob_2_script IS


PROCEDURE p_generate_script(
    p_table varchar2,
    p_column varchar2,
    p_column_type varchar2,  --"C" for CLOB; "B" for BLOB
    p_where varchar2,
    p_blob_source varchar2,  --"PARAM" as p_file parameter, "APEX_VIEW" as single file from apex_application_temp_files view, "READ_FROM_TABLE" read from source table
    p_file blob default null
) IS

    lbBlob blob;
    lcClob clob;
    lrPieces apex_t_varchar2;
    
    PROCEDURE p_add(p_text varchar2 default null) IS
    BEGIN
        lcClob := lcClob || p_text || chr(10);
    END p_add;
    
BEGIN
    --get document
    if p_blob_source = 'READ_FROM_TABLE' then
        EXECUTE IMMEDIATE 'SELECT ' || p_column || ' FROM ' || p_table || ' WHERE ' || p_where
        INTO lbBlob;
        
    elsif p_blob_source = 'APEX_VIEW' then
        SELECT blob_content
        INTO lbBlob
        FROM apex_application_temp_files
        WHERE rownum = 1;
        
    elsif p_blob_source = 'PARAM' then
        lbBlob := p_file;
    end if;
    
    
    --encode to base64 and split into rows
    lcClob := replace( apex_web_service.blob2clobbase64(p_blob => lbBlob), chr(13) || chr(10), chr(10) );
    lrPieces := apex_string.split(lcClob);
    
    
    --P R E P A R E   S C R I P T
    --header
    lcClob := null;
    p_add('DECLARE');
    p_add;
    p_add('    lcClob clob;');
    p_add('    lbBlob blob;');
    p_add;
    
    p_add(q'[  function decode_base64(p_clob_in in clob) return blob is
    v_blob blob;
    v_result blob;
    v_offset integer;
    v_buffer_size binary_integer := 48;
    v_buffer_varchar varchar2(48);
    v_buffer_raw raw(48);
  begin
    if p_clob_in is null then
      return null;
    end if;
    dbms_lob.createtemporary(v_blob, true);
    v_offset := 1;
    for i in 1 .. ceil(dbms_lob.getlength(p_clob_in) / v_buffer_size) loop
      dbms_lob.read(p_clob_in, v_buffer_size, v_offset, v_buffer_varchar);
      v_buffer_raw := utl_raw.cast_to_raw(v_buffer_varchar);
      v_buffer_raw := utl_encode.base64_decode(v_buffer_raw);
      dbms_lob.writeappend(v_blob, utl_raw.length(v_buffer_raw), v_buffer_raw);
      v_offset := v_offset + v_buffer_size;
    end loop;
    v_result := v_blob;
    dbms_lob.freetemporary(v_blob);
    return v_result;
  end decode_base64;]');
    p_add;

    if p_column_type = 'C' then
        p_add(q'[  FUNCTION f_blob_to_clob(
    blob_in IN blob,
    plEncoding IN NUMBER default 0) RETURN clob IS

    v_clob Clob;
    v_in Pls_Integer := 1;
    v_out Pls_Integer := 1;
    v_lang Pls_Integer := 0;
    v_warning Pls_Integer := 0;
    v_id number(10);

BEGIN
    if blob_in is null then
        return null;
    end if;

    v_in:=1;
    v_out:=1;
    dbms_lob.createtemporary(v_clob,TRUE);
    DBMS_LOB.convertToClob(v_clob,
                           blob_in,
                           DBMS_lob.getlength(blob_in),
                           v_in,
                           v_out,
                           plEncoding,
                           v_lang,
                           v_warning);

    RETURN v_clob;

END f_blob_to_clob;]');
        p_add;
    end if;


    p_add('BEGIN');

    --lines
    FOR t in 1 .. lrPieces.count LOOP
        p_add('    lcClob := lcClob || ''' || lrPieces(t) || ''';');
    END LOOP;
    p_add;

    --convert back to blob
    p_add('    lbBlob := decode_base64(lcClob);');
    p_add;
    
    --update desired record
    p_add(
        '    UPDATE ' || p_table || 
        ' SET ' ||  p_column || ' = ' || 
        CASE p_column_type WHEN 'B' THEN 'lbBlob' ELSE 'f_blob_to_clob(lbBlob)' END || 
        ' WHERE ' || p_where || 
        ';'
    );
    p_add;

    --finish
    p_add('    COMMIT;');
    p_add;
    p_add('END;');
    p_add('/');

    DELETE FROM apex_application_temp_files;
    COMMIT;

    
    --convert script to blob and download
    pkg_utils.p_download_document(
        p_text => lcClob,
        p_file_name => 'lob_doc.sql'
    );
    
END p_generate_script;


END pkg_lob_2_script;
/



Prompt Package PKG_OBJECTS;
CREATE OR REPLACE PACKAGE PKG_OBJECTS AS 


CURSOR c_data(p_object_id objects.object_id%TYPE) IS
SELECT
    o.filename,
    coalesce(
        v_dbo.db_schema_name,
        v_apc.app_schema_name,
        v_app.schema_name
    ) as db_schema,
    coalesce(
        v_apc.application_number,
        v_app.application_number
    ) as application_number,
    ot.target_folder,
    ot.source_folder
FROM
    objects o
    JOIN object_types ot ON o.object_type_id = ot.object_type_id
    LEFT JOIN v_database_objects v_dbo ON o.object_id = v_dbo.db_object_id
    LEFT JOIN v_app_components v_apc ON o.object_id = v_apc.app_component_id
    LEFT JOIN v_applications v_app ON o.object_id = v_app.application_id
WHERE o.object_id = p_object_id
;


FUNCTION f_get_object_id(
    p_parent_object_type varchar2,
    p_parent_object varchar2,
    p_object_type varchar2,
    p_object_name varchar2
) RETURN objects.object_id%TYPE
;


--database object file names
FUNCTION f_db_object_filename(
    p_name varchar2,
    p_type varchar2
) RETURN objects.filename%TYPE;

--source filename (with folder and chema name and app ID replace)
FUNCTION f_source_filename(
    p_object_id objects.object_id%TYPE
) RETURN varchar2;



--refresh object register
PROCEDURE p_refresh_database_objects(
    p_db_schemas objects.name%TYPE,  --database schemas
    p_object_types object_types.code%TYPE
);

PROCEDURE p_refresh_app_comp(
    p_app_ids varchar2  --application IDs (input is checkbox and string is : separated)
);

FUNCTION f_merge_app_component (
    p_comp_id number,
    p_app_id number,
    p_type_code varchar2,
    p_comp_name varchar2
) RETURN objects.object_id%TYPE;



--create object
FUNCTION f_create_db_object(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2
) RETURN objects.object_id%TYPE;


FUNCTION f_exclude_from_record_yn(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_exclusion_type varchar2  --P (patch) or R (register)
) RETURN varchar2;



--object scripts
FUNCTION f_get_database_object_script(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_grants_yn varchar2 default 'N'
) RETURN clob;

FUNCTION f_get_app_component_script(
    p_app_no number,
    p_component_id number,
    p_type varchar2
) RETURN clob;

FUNCTION f_get_app_script(
    p_app_no number
) RETURN clob;

FUNCTION f_default_db_schema 
RETURN v_database_schemas.schema_name%TYPE;



--locks
PROCEDURE p_lock_object(
    p_object_id objects.object_id%TYPE,
    p_lock_type objects.lock_type%TYPE,
    p_comment objects.lock_comment%TYPE
);

PROCEDURE p_unlock_object(
    p_object_id objects.object_id%TYPE
);

FUNCTION f_is_object_locked_yn(
    p_object_id objects.object_id%TYPE,
    p_user_id app_users.app_user_id%TYPE
) RETURN varchar2;


FUNCTION f_who_locked_object(
    p_object_id objects.object_id%TYPE
) RETURN app_users.app_user_id%TYPE;


FUNCTION f_page_locked_in_apex_yn(
    p_object_id objects.object_id%TYPE
) RETURN varchar2;


END PKG_OBJECTS;
/

SHOW ERRORS;



Prompt Package Body PKG_OBJECTS;
CREATE OR REPLACE PACKAGE BODY PKG_OBJECTS AS


FUNCTION f_get_object_record(
    p_object_id objects.object_id%TYPE
) RETURN objects%ROWTYPE IS

    lrObject objects%ROWTYPE;

BEGIN
    SELECT *
    INTO lrObject
    FROM objects
    WHERE object_id = p_object_id;

    RETURN lrObject;
END f_get_object_record;



FUNCTION f_get_object_id(
    p_parent_object_type varchar2, --APPLICATION, DB_SCHEMA
    p_parent_object varchar2, --parent object marker - application number, schema name...
    p_object_type varchar2,
    p_object_name varchar2

) RETURN objects.object_id%TYPE IS

    lnID objects.object_id%TYPE;

BEGIN
    if p_parent_object_type = 'DB_SCHEMA' then
        SELECT v_dbo.db_object_id
        INTO lnID
        FROM 
            v_database_objects v_dbo
        WHERE
            nvl(v_dbo.db_schema_name, 'x') = nvl(p_parent_object, 'x')  --some objects are not on schema level... for example directory 
        AND v_dbo.db_object_name = p_object_name
        AND v_dbo.object_type_code = p_object_type
        ;
        
    elsif p_parent_object_type = 'APPLICATION' then
        SELECT v_apc.app_component_id 
        INTO lnID
        FROM
            v_app_components v_apc
        WHERE
            v_apc.application_number = p_parent_object
        AND v_apc.app_component_name = p_object_name
        AND v_apc.object_type_code = p_object_type
        ;
    
    end if;
    

    RETURN lnID;
    
EXCEPTION WHEN no_data_found THEN
    RETURN null;
    
END f_get_object_id;


FUNCTION f_db_object_filename(
    p_name varchar2,
    p_type varchar2
) RETURN objects.filename%TYPE IS
BEGIN
    RETURN
        lower(p_name) || (
            CASE p_type 
                WHEN 'PACKAGE' THEN '.pks' 
                WHEN 'PACKAGE BODY' THEN '.pkb' 
                ELSE '.sql' END
            )
    ;
END f_db_object_filename;

PROCEDURE p_refresh_database_objects(
    p_db_schemas objects.name%TYPE,  --database schemas
    p_object_types object_types.code%TYPE
) AS

    lrOrdsList pkg_interface.t_objects;

BEGIN
    --insert standard objects from DBA_OBJECTS view
    INSERT INTO objects (
        parent_object_id,
        object_type_id,
        name,
        filename
        )
    SELECT
        dbs.schema_id as db_schema_id,
        obt.object_type_id,
        upper(dbo.object_name) as object_name,
        pkg_objects.f_db_object_filename(
            p_name => dbo.object_name,
            p_type => dbo.object_type
        ) as filename
    FROM 
        dba_objects dbo
        JOIN v_database_schemas dbs ON dbo.owner = dbs.schema_name
        JOIN object_types obt ON dbo.object_type = obt.code
    WHERE
        dbo.owner in ( SELECT column_value FROM TABLE(apex_string.split(p_db_schemas, ':')) )
    AND dbo.object_type in ( SELECT column_value FROM TABLE(apex_string.split(p_object_types, ':')) )
    AND not exists --only new objects
        (
        SELECT 1
        FROM v_database_objects v_dbo 
        WHERE 
            dbo.owner = v_dbo.db_schema_name
        AND upper(dbo.object_name) = upper(v_dbo.db_object_name)
        AND dbo.object_type = v_dbo.object_type_code
        )
    ;
    
    --mark dropped objects as inactive
    UPDATE objects
    SET active_yn = 'N'
    WHERE object_id in 
    (
    SELECT v_dbo.db_object_id
    FROM v_database_objects v_dbo
    WHERE 
        v_dbo.object_type_code <> 'ORDS'
    AND v_dbo.db_schema_name in ( SELECT column_value FROM TABLE(apex_string.split(p_db_schemas, ':')) )
    AND v_dbo.object_type_code in ( SELECT column_value FROM TABLE(apex_string.split(p_object_types, ':')) )
    AND v_dbo.active_yn = 'Y'
    AND NOT EXISTS 
        (
        SELECT 1 
        FROM dba_objects dba_obj
        WHERE
            v_dbo.db_object_name = dba_obj.object_name
        AND v_dbo.object_type_code = dba_obj.object_type
        AND v_dbo.db_schema_name = dba_obj.owner
        )
    )
    ;
    
    
    --refresh ORDS (if selected)
    if instr(p_object_types, 'ORDS') > 0 then
        FOR t IN ( SELECT column_value as schema_name FROM TABLE(apex_string.split(p_db_schemas, ':')) ) LOOP
        
            EXECUTE IMMEDIATE 'BEGIN :1 := ' || t.schema_name || '.PKG_DOME_UTILS.f_get_objects_list(''ORDS''); END;'
            USING OUT lrOrdsList;
            
            --used FOR LOOP because INSERT INTO ... SELECT is throwing invalid datatype error???
            FOR p IN (
                SELECT
                    v_dbs.schema_id,
                    ot.object_type_id,
                    v_list.name as object_name,
                    lower(ot.code || '_' || v_list.name || '.sql') as filename
                FROM 
                    table( lrOrdsList ) v_list
                    JOIN v_database_schemas v_dbs ON v_dbs.schema_name = t.schema_name
                    JOIN object_types ot ON ot.code = 'ORDS'
                    LEFT JOIN v_database_objects v_dbo ON 
                            v_dbo.db_object_name = v_list.name
                        AND v_dbo.object_type_code = ot.code
                        AND v_dbo.db_schema_name = t.schema_name
                WHERE v_dbo.db_object_id is null  --only new objects
            ) LOOP
            
                INSERT INTO objects (
                    parent_object_id,
                    object_type_id,
                    name,
                    filename
                ) VALUES (
                    p.schema_id,
                    p.object_type_id,
                    p.object_name,
                    p.filename
                );
            
            END LOOP;
            
        END LOOP;
        
    end if;
    
    
END p_refresh_database_objects;


PROCEDURE p_refresh_app_comp(
    p_app_ids varchar2  --application IDs
) AS
BEGIN
    --merge into for all selected applications
    MERGE INTO objects obj
    USING (
        --app components
        SELECT 
            vju.id, 
            vju.name, 
            ot.object_type_id,
            v_app.application_id,
            ob.object_id,
            lower(ot.code) || '_' || v_app.application_number || '_' || vju.id || '.sql' as filename
        FROM 
            apex_appl_export_comps vju
            JOIN object_types ot ON vju.type_name = ot.code AND ot.object_location = 'APP'
            JOIN v_applications v_app ON vju.application_id = v_app.application_number
            LEFT JOIN objects ob ON 
                    ob.parent_object_id = v_app.application_id
                AND ob.object_type_id = ot.object_type_id
                AND ob.aa_number_01 = vju.id
            JOIN ( SELECT to_number(column_value) as app_id FROM TABLE(apex_string.split(p_app_ids, ':')) ) flt ON v_app.application_id = flt.app_id
        UNION ALL  --static application files (not included in app components view)
        SELECT 
            aasf.application_file_id as id,
            aasf.file_name as name,
            ot.object_type_id,
            v_app.application_id,
            vju.object_id,
            lower(ot.code) || '_' || aasf.application_id || '_' || aasf.application_file_id || '.sql' as filename
        FROM 
            apex_application_static_files aasf
            JOIN (SELECT to_number(column_value) as app_id FROM TABLE(apex_string.split('400', ':')) ) flt ON aasf.application_id = flt.app_id
            JOIN v_applications v_app ON aasf.application_id = v_app.application_number 
            CROSS JOIN (SELECT object_type_id, code FROM object_types WHERE code = 'STATIC_APP_FILE') ot
            LEFT JOIN 
            (
            SELECT 
                ob.object_id,
                ob.aa_number_01
            FROM 
                objects ob
                JOIN object_types ot ON ob.object_type_id = ot.object_type_id
            WHERE 
                ot.code = 'STATIC_APP_FILE'
            ) vju ON aasf.application_file_id = vju.aa_number_01 
    ) v
    ON (obj.object_id = v.object_id)
    WHEN NOT MATCHED THEN INSERT (object_type_id, name, filename, parent_object_id, aa_number_01) 
        VALUES (
            v.object_type_id, 
            v.name, 
            v.filename,
            v.application_id,
            v.id
            )
    WHEN MATCHED THEN UPDATE SET 
        obj.name = v.name,
        obj.filename = v.filename
    ;
    
    
    --mark missing componentes (presumably deleted from applications) as inactive
    UPDATE objects
    SET active_yn = 'N'
    WHERE object_id in 
        (
        SELECT 
            v_apc.app_component_id
        FROM 
            v_app_components v_apc
            JOIN (SELECT to_number(column_value) as app_id FROM TABLE(apex_string.split('400', ':')) ) flt ON v_apc.application_number = flt.app_id
        WHERE 
            v_apc.object_type_code <> 'STATIC_APP_FILE'
        AND v_apc.active_yn = 'Y'
        AND NOT EXISTS 
            (
            SELECT 1 
            FROM apex_appl_export_comps apex_comp
            WHERE 
                v_apc.app_component_number = apex_comp.id
            AND v_apc.application_number = apex_comp.application_id
            AND v_apc.object_type_code = apex_comp.type_name
            )
        )
    ;

END p_refresh_app_comp;


FUNCTION f_merge_app_component (
    p_comp_id number,
    p_app_id number,
    p_type_code varchar2,
    p_comp_name varchar2
) RETURN objects.object_id%TYPE IS

    CURSOR c_data IS
        SELECT
            ot.object_type_id,
            app.application_id as dome_app_id
        FROM
            object_types ot
            CROSS JOIN v_applications app 
        WHERE
            ot.code = p_type_code
        AND app.application_number = p_app_id
        ; 

    lrData c_data%ROWTYPE;

    lnObjectID objects.object_id%TYPE;

BEGIN
    --get app component ID
    BEGIN
        SELECT
            app_component_id
        INTO
            lnObjectID
        FROM 
            v_app_components
        WHERE
            application_number = p_app_id
        AND app_component_number = p_comp_id
        AND object_type_code = p_type_code
        ;
        
        --if component already exists in DOME register -> update name
        UPDATE objects 
        SET name = p_comp_name
        WHERE object_id = lnObjectID;
        
    EXCEPTION WHEN no_data_found THEN
        --if component doesn't exist in DOME register -> add component to register
        OPEN c_data;
        FETCH c_data INTO lrData;
        if c_data%NOTFOUND then
            RAISE_APPLICATION_ERROR(-20010, 'Object type with code ' || p_type_code || ' does not exist!');
        end if;
        CLOSE c_data;
        
    
        INSERT INTO objects (
            object_type_id, 
            name, 
            filename, 
            parent_object_id, 
            aa_number_01
        )
        VALUES (
            lrData.object_type_id,
            p_comp_name,
            lower(p_type_code) || '_' || p_app_id || '_' || p_comp_id || '.sql',
            lrData.dome_app_id,
            p_comp_id
        )
        RETURNING object_id INTO lnObjectID
        ;
    END;
    
    RETURN lnObjectID;
    
END f_merge_app_component;


FUNCTION f_create_db_object(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2
) RETURN objects.object_id%TYPE IS

    lrObject objects%ROWTYPE;

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --get object type and schema
    BEGIN
        SELECT object_type_id
        INTO lrObject.object_type_id 
        FROM object_types
        WHERE 
            code = p_type
        AND object_location = 'DB'
        ;
    EXCEPTION WHEN no_data_found THEN
        RAISE_APPLICATION_ERROR(-20001, 'Object type ' || p_type || ' is not found in register!');
    END;
    

    --If database object is not linked to database schema... no problem. Just don't assign object to schema.
     --Example is database directory.
    BEGIN
        SELECT schema_id
        INTO lrObject.parent_object_id
        FROM v_database_schemas
        WHERE schema_name = p_schema;
        
    EXCEPTION WHEN no_data_found THEN
        lrObject.parent_object_id := null;
    END;

    --name and filename
    lrObject.name := upper(p_name);
    lrObject.filename := pkg_objects.f_db_object_filename(
        p_name => p_name,
        p_type => p_type
    )
    ;
    
    lrObject.active_yn := 'Y';
    
    INSERT INTO objects 
    VALUES lrObject
    RETURNING object_id INTO lrObject.object_id
    ;

    COMMIT;

    RETURN lrObject.object_id;
END f_create_db_object;


FUNCTION f_exclude_from_record_yn(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_exclusion_type varchar2  --P (patch) or R (register)
) RETURN varchar2 IS

    CURSOR c_exclude_pattern IS
        SELECT exclude_yes_no
        FROM 
            (
            SELECT
                'Y' as exclude_yes_no
            FROM 
                exclude_from_recording efr
                LEFT JOIN v_database_schemas v_dbs ON efr.db_schema_id = v_dbs.schema_id
                LEFT JOIN object_types ot ON efr.object_type_id = ot.object_type_id
            WHERE
                (efr.db_schema_id is null OR p_schema is null OR v_dbs.schema_name = p_schema)  --schema
            AND (efr.object_type_id is null OR ot.code = p_type)  --object
            AND 
                --naming pattern
                (
                    efr.like_or_regexp is null 
                OR  (efr.like_or_regexp = 'L' AND p_name like efr.naming_pattern)
                OR  (efr.like_or_regexp = 'R' AND regexp_like(p_name, efr.naming_pattern) )
                )
            AND
                --from patch or register
                (
                    (p_exclusion_type = 'R' AND efr.from_register_yn = 'Y')
                OR  (p_exclusion_type = 'P' AND efr.from_patch_yn = 'Y')
                )
            )
        WHERE 
            exclude_yes_no = 'Y'
        AND rownum = 1
        ;

    lrExclude c_exclude_pattern%ROWTYPE;

BEGIN
    --get data
    OPEN c_exclude_pattern;
    FETCH c_exclude_pattern INTO lrExclude;
    CLOSE c_exclude_pattern;
    
    --if no record fetched then do not exclude object
    lrExclude.exclude_yes_no := nvl( lrExclude.exclude_yes_no, 'N');
    
    
    RETURN lrExclude.exclude_yes_no;
    
END f_exclude_from_record_yn;



FUNCTION f_get_database_object_script(
    p_schema varchar2,
    p_name varchar2,
    p_type varchar2,
    p_grants_yn varchar2 default 'N'
) RETURN clob AS

    lcScript clob;

BEGIN
    EXECUTE IMMEDIATE 
        'BEGIN :script := ' || nvl(p_schema, pkg_objects.f_default_db_schema) || '.pkg_dome_utils.f_get_database_object_script(:name, :type, :grants_yn); END;' 
    USING 
        OUT lcScript,
        IN p_name, 
        IN p_type, 
        IN p_grants_yn
    ;
    
    RETURN lcScript;
END f_get_database_object_script;



FUNCTION f_get_app_component_script(
    p_app_no number,
    p_component_id number,
    p_type varchar2
) RETURN clob AS

    lcShema v_database_schemas.schema_name%TYPE;
    lcScript clob;

    lrFiles apex_t_export_files;
    
    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --schema name, from which application component script will be requested
    SELECT schema_name
    INTO lcShema
    FROM v_applications
    WHERE application_number = p_app_no
    ;

    --get component script
    if lcShema is not null then

        EXECUTE IMMEDIATE 
            'BEGIN :script := ' || lcShema || '.pkg_dome_utils.f_get_app_component_script(:app_no, :component_id, :type); END;' 
        USING OUT lcScript, IN p_app_no, IN p_component_id, IN p_type;

    else

        lrFiles := apex_export.get_application(
            p_application_id => p_app_no,
            p_split => false,
            --p_with_ir_public_reports => true,
            p_with_translations => true,
            p_with_comments => true,
            p_components => apex_t_varchar2( p_type || ':' || p_component_id )
        );
    
        lcScript := lrFiles(lrFiles.first).contents;
    end if;

    RETURN lcScript;
    
END f_get_app_component_script;



FUNCTION f_get_app_script(
    p_app_no number
) RETURN clob AS

    lcShema v_database_schemas.schema_name%TYPE;
    lcScript clob;

    lrFiles apex_t_export_files;

    PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    --schema name, from which application component script will be requested
    SELECT schema_name
    INTO lcShema
    FROM v_applications
    WHERE application_number = p_app_no
    ;

    --get component script
    if lcShema is not null then

        EXECUTE IMMEDIATE 
            'BEGIN :script := ' || lcShema || '.pkg_dome_utils.f_get_app_script(:app_no); END;' 
        USING 
            OUT lcScript,
            IN p_app_no
        ;

    else

        lrFiles := apex_export.get_application(
            p_application_id => p_app_no,
            p_split => false,
            --p_with_ir_public_reports => true,
            p_with_translations => true,
            p_with_comments => true
        );
    
        lcScript := lrFiles(lrFiles.first).contents;
    end if;

    RETURN lcScript;
    
END f_get_app_script;



FUNCTION f_source_filename(
    p_object_id objects.object_id%TYPE
) RETURN varchar2 IS

    lrData pkg_objects.c_data%ROWTYPE;
    lcFilename varchar2(1000);
    
BEGIN
    --get data
    OPEN pkg_objects.c_data(p_object_id);
    FETCH pkg_objects.c_data INTO lrData;
    CLOSE pkg_objects.c_data;
    
    lcFilename := replace(lrData.source_folder, '#SCHEMA#', lower( nvl(lrData.db_schema, pkg_objects.f_default_db_schema) ) );
    lcFilename := replace(lcFilename, '#APP_ID#', lower(lrData.application_number) );
    
    lcFilename := lcFilename || '/' || lrData.filename;
    
    RETURN lcFilename;
        
END f_source_filename;



FUNCTION f_is_object_locked_yn(
    p_object_id objects.object_id%TYPE,
    p_user_id app_users.app_user_id%TYPE
) RETURN varchar2 IS
BEGIN
    RETURN CASE WHEN f_get_object_record(p_object_id).lock_type = 'E' THEN 'Y' ELSE 'N' END;
END f_is_object_locked_yn;


FUNCTION f_who_locked_object(
    p_object_id objects.object_id%TYPE
) RETURN app_users.app_user_id%TYPE IS
BEGIN
    RETURN f_get_object_record(p_object_id).lock_app_user_id;
END f_who_locked_object;


PROCEDURE p_lock_object(
    p_object_id objects.object_id%TYPE,
    p_lock_type objects.lock_type%TYPE,
    p_comment objects.lock_comment%TYPE
) IS
BEGIN
    UPDATE objects
    SET
        lock_type = p_lock_type, 
        lock_app_user_id = nv('APP_LOGGED_USER_ID'),
        lock_date = sysdate, 
        lock_comment = p_comment
    WHERE object_id = p_object_id;

END p_lock_object;


PROCEDURE p_unlock_object(
    p_object_id objects.object_id%TYPE
) IS
BEGIN
    UPDATE objects
    SET
        lock_type = null, 
        lock_app_user_id = null,
        lock_date = null, 
        lock_comment = null
    WHERE object_id = p_object_id;

END p_unlock_object;


FUNCTION f_page_locked_in_apex_yn(
    p_object_id objects.object_id%TYPE
) RETURN varchar2 IS

    lrRecord v_app_components%ROWTYPE;
    lcYesNo varchar2(1);

BEGIN
    --schema name, from which application component script will be requested
    SELECT *
    INTO lrRecord
    FROM v_app_components
    WHERE app_component_id = p_object_id
    ;

    --get component script
    if lrRecord.app_schema_name is not null then

        EXECUTE IMMEDIATE 
            'SELECT ' || lrRecord.app_schema_name || '.pkg_dome_utils.f_page_locked_yn(:1, :2) FROM dual' 
        INTO lcYesNo
        USING lrRecord.application_number, lrRecord.app_component_number;

    else

        SELECT
            CASE 
                WHEN EXISTS 
                    (
                    SELECT 1 
                    FROM apex_application_locked_pages ap
                    WHERE
                        ap.application_id = lrRecord.application_number
                    AND ap.page_id = lrRecord.app_component_number
                    )
                THEN 'Y'
                ELSE 'N'
            END
        INTO lcYesNo
        FROM dual;

    end if;

    RETURN lcYesNo;

END f_page_locked_in_apex_yn;


FUNCTION f_default_db_schema 
RETURN v_database_schemas.schema_name%TYPE IS
BEGIN
    --TODO: make a parameter
    RETURN 'MBA';
END f_default_db_schema;


END PKG_OBJECTS;
/

SHOW ERRORS;



CREATE OR REPLACE PACKAGE PKG_PATCHES AS 

--patch ZIP filename
FUNCTION f_patch_filename(
    p_patch_id patches.patch_id%TYPE,
    p_extension varchar2 default null
) RETURN varchar2;



CURSOR c_patch(p_patch_id patches.patch_id%TYPE) IS
    SELECT
        v_p.patch_id,
        v_p.project_id,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '.zip') as filename,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '_src.zip') as src_filename,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '/') as root_folder,
        v_p.patch_code as patch_code,
        v_p.task_code_and_name || ' (' || v_p.patch_number || ')' as name,
        v_p.patch_template_id,
        pkg_patch_templates.f_get_procedure_name(patch_template_id) as patch_procedure_name
    FROM 
        v_patches v_p
    WHERE v_p.patch_id = p_patch_id
;


CURSOR c_patch_schemas (
    p_patch_id patches.patch_id%TYPE
) IS 
    SELECT DISTINCT 
        v_pso.schema_name as schema_name
    FROM v_patch_scr_and_obj v_pso
    WHERE 
        v_pso.patch_id = p_patch_id
    AND v_pso.object_as_patch_script_yn = 'N'
;

TYPE t_patch_schemas IS TABLE OF c_patch_schemas%ROWTYPE;



CURSOR c_patch_files (
    p_patch_id patches.patch_id%TYPE
) IS 
    SELECT
        v_pso.filename_replaced as filename,
        pkg_utils.f_clob_to_blob(v_pso.sql_content) as blob_file,
        v_pso.schema_name,
        CASE 
            WHEN v_pso.schema_name <> lag(v_pso.schema_name, 1, 'not existing one') over (order by v_pso.schema_name, v_pso.seq_nr, v_pso.filename) THEN 'Y' 
            ELSE 'N' 
        END as change_schema_yn
    FROM v_patch_scr_and_obj v_pso
    WHERE 
        v_pso.patch_id = p_patch_id
    AND v_pso.object_as_patch_script_yn = 'N'
    ORDER BY
        v_pso.schema_name,
        v_pso.seq_nr,
        v_pso.filename
;

TYPE t_patch_files IS TABLE OF c_patch_files%ROWTYPE;




--getters
FUNCTION f_get_v_patch(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches%ROWTYPE;

FUNCTION f_get_project_id(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches.project_id%TYPE;


PROCEDURE p_confirm_patch(
    p_patch_id patches.patch_id%TYPE,
    p_user_confirmed_id patches.confirmed_app_user_id%TYPE
);

--unlock patch
FUNCTION f_unlock_patch_possible(
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2;

PROCEDURE p_unlock_patch(
    p_patch_id patches.patch_id%TYPE
);


PROCEDURE p_download_zip(
    p_patch_id patches.patch_id%TYPE
);



--on which environments is patch installed
FUNCTION f_installed_on(
    p_patch_id patches.patch_id%TYPE,
    p_separator varchar2 default chr(10)
) RETURN varchar2;



--user works on patch
PROCEDURE p_start_stop_working(
    p_user_id app_users.app_user_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_action varchar2  --START or STOP
);



--download ZIP file with object SQL source 
PROCEDURE p_download_source(
    p_patch_id patches.patch_id%TYPE
);




--warnings on patch
FUNCTION f_patch_warnings (
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2;


--move tasks to another task group
PROCEDURE p_move_tasks (
    p_new_group_id task_groups.task_group_id%TYPE 
);


END PKG_PATCHES;
/


Prompt Package Body PKG_PATCH_OBJECTS;
CREATE OR REPLACE PACKAGE BODY PKG_PATCH_OBJECTS AS

FUNCTION f_next_version(
    p_object_id objects.object_id%TYPE
) RETURN patch_objects.object_version%TYPE AS

    lnNextVersion patch_objects.object_version%TYPE;

BEGIN
    SELECT nvl( max(object_version), 0) + 1
    INTO lnNextVersion
    FROM patch_objects
    WHERE object_id = p_object_id;

    RETURN lnNextVersion;
END f_next_version;



PROCEDURE p_add_object_to_patch(
    p_object_id objects.object_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_user_id app_users.app_user_id%TYPE,
    p_as_patch_script_yn patch_objects.as_patch_script_yn%TYPE DEFAULT 'N'
) IS
BEGIN
    MERGE INTO patch_objects pa
    USING (
        SELECT
            p_patch_id as patch_id,
            p_object_id as object_id,
            p_user_id as app_user_id,
            p_as_patch_script_yn as as_patch_script_yn
        FROM dual
    ) vju
    ON (
        pa.patch_id = vju.patch_id AND pa.object_id = vju.object_id
    )
    WHEN NOT MATCHED THEN INSERT (
        patch_id, 
        object_id, 
        app_user_id,
        as_patch_script_yn)
    VALUES (
        vju.patch_id,
        vju.object_id,
        vju.app_user_id,
        vju.as_patch_script_yn
    )
    ;
    
END p_add_object_to_patch;



FUNCTION f_object_in_another_patch_err(
    p_object_id objects.object_id%TYPE,
    p_current_patch_id patches.patch_id%TYPE
) RETURN varchar2 IS

    lcError varchar2(10000);

BEGIN
    SELECT 'Object ' || v_o.object_name || ' (' || v_o.object_type || ') is already included in patch "' || v_p.display || '"'
    INTO lcError
    FROM 
        patch_objects po
        JOIN v_patches v_p ON po.patch_id = v_p.patch_id
        JOIN v_objects v_o ON po.object_id = v_o.object_id
    WHERE 
        po.object_id = p_object_id
    AND v_p.confirmed_yn = 'N'
    AND po.patch_id <> p_current_patch_id
    AND po.patch_id not in  --linked patches are ignored
        (
        SELECT patch2_id
        FROM linked_patches
        WHERE patch1_id = p_current_patch_id
        UNION ALL
        SELECT patch1_id
        FROM linked_patches
        WHERE patch2_id = p_current_patch_id
        )
    ;

    RETURN lcError;

EXCEPTION WHEN no_data_found THEN
    RETURN null;

END f_object_in_another_patch_err;


PROCEDURE p_prepare_component_list (
    p_patch_id patches.patch_id%TYPE,
    p_current_user_id app_users.app_user_id%TYPE 
) IS

    CURSOR c_apps IS
        SELECT 
            app.application_number as application_id
        FROM 
            project_apps pa
            JOIN v_patches p ON pa.project_id = p.project_id
            JOIN v_applications app ON pa.object_id = app.application_id
        WHERE 
            p.patch_id = p_patch_id
        ;

    lrApps coll_dome_num;
    ldPatchCreateDate patches.created_on%TYPE;
    
    TYPE t_users IS TABLE OF varchar2(128) INDEX BY varchar2(30);
    lrUsers t_users;

    CURSOR c_objects IS
        SELECT
            ec.application_id,
            ec.id,
            ec.application_name,
            ec.type_name,
            ec.name,
            ec.last_updated_by,
            ec.last_updated_on,
            ec.workspace,
            CASE WHEN ec.last_updated_on >= ldPatchCreateDate THEN 'Yes' ELSE 'No' END as changed_after_patch,
            'Yes' as last_changed_by_me
        FROM 
            apex_appl_export_comps ec
        WHERE
            ec.application_id member of lrApps
        ORDER BY ec.last_updated_on desc nulls last
        ;
        
        TYPE t_objects IS TABLE OF c_objects%ROWTYPE;
        lrObjects t_objects;

BEGIN
    --get app list (all project apps - project is determined from current patch)
    OPEN c_apps;
    FETCH c_apps BULK COLLECT INTO lrApps;
    CLOSE c_apps;
    
    --get patch create date
    ldPatchCreateDate := pkg_patches.f_get_v_patch(p_patch_id).created_on;
    
    --get objects for applications
    OPEN c_objects;
    FETCH c_objects BULK COLLECT INTO lrObjects;
    CLOSE c_objects;
    
    
    --read current user's APEX usernames for workspaces
    FOR t IN 
        (
        SELECT
            apex_user_name,
            workspace_name
        FROM v_workspace_users 
        WHERE app_user_id = p_current_user_id
        ) LOOP
    
        lrUsers(t.workspace_name) := t.apex_user_name;
        
    END LOOP;
    
    --set "last changed by me" flag (based on workspace and APEX user name)
    FOR t IN 1 .. lrObjects.count LOOP
        lrObjects(t).last_changed_by_me := 
            CASE 
                WHEN lrObjects(t).last_updated_by = lrUsers(lrObjects(t).workspace) THEN 'Yes'
                ELSE 'No'
            END;
    END LOOP;
    
    --fill APEX collection
    APEX_COLLECTION.create_or_truncate_collection(gcCompListCollName);
    
    /*
    n001 as application_id,
    c001 as application_name,
    c002 as type_name,
    c003 as name,
    c004 as last_updated_by,
    d001 as last_updated_on,
    c005 as workspace,
    c006 as last_changed_by_me,
    c007 as changed_after_patch
    */
    FOR t IN 1 .. lrObjects.count LOOP
        APEX_COLLECTION.add_member (
            p_collection_name => gcCompListCollName,
            p_n001 => lrObjects(t).application_id,
            p_c001 => lrObjects(t).application_name,
            p_c002 => lrObjects(t).type_name,
            p_n002 => lrObjects(t).id,
            p_c003 => lrObjects(t).name,
            p_c004 => lrObjects(t).last_updated_by,
            p_d001 => lrObjects(t).last_updated_on,
            p_c005 => lrObjects(t).workspace,
            p_c006 => lrObjects(t).last_changed_by_me,
            p_c007 => lrObjects(t).changed_after_patch
        );
    END LOOP;
    
    

END p_prepare_component_list;


FUNCTION f_comp_list_coll_name RETURN varchar2 IS
BEGIN
    RETURN gcCompListCollName;
END f_comp_list_coll_name;


PROCEDURE p_add_app_comp_to_patch (
    p_patch_id patches.patch_id%TYPE,
    p_current_user_id app_users.app_user_id%TYPE 
) IS

    lrSeq coll_dome_num := coll_dome_num();

    CURSOR c_components IS
        SELECT
            ac.n001 as application_id,
            ac.c002 as type_code,
            ac.c003 as name,
            ac.n002 as component_id,
            0 as dome_component_id 
        FROM 
            apex_collections ac
            JOIN (SELECT to_number(column_value) as seq_id FROM table(lrSeq) ) tbl ON ac.seq_id = tbl.seq_id  --only selected components
        WHERE 
            ac.collection_name = PKG_PATCH_OBJECTS.f_comp_list_coll_name            
        ;

    TYPE t_components IS TABLE OF c_components%ROWTYPE;
    lrComp t_components;

BEGIN
    --selected components (seq_id from APEX collection) to DB collection
    lrSeq.extend( apex_application.g_f01.count );
    FOR t IN 1 .. apex_application.g_f01.count LOOP
        lrSeq(t) := apex_application.g_f01(t);
    END LOOP;

    --read components
    OPEN c_components;
    FETCH c_components BULK COLLECT INTO lrComp;
    CLOSE c_components;

    --insert or update components and add components to patch
    FOR t IN 1 .. lrComp.count LOOP
        lrComp(t).dome_component_id := pkg_objects.f_merge_app_component (
            p_comp_id => lrComp(t).component_id,
            p_app_id => lrComp(t).application_id,
            p_type_code => lrComp(t).type_code,
            p_comp_name => lrComp(t).name
        );
        
        p_add_object_to_patch (
            p_object_id => lrComp(t).dome_component_id,
            p_patch_id => p_patch_id,
            p_user_id => p_current_user_id
        );
    
        --apex_debug.message( 'Selected component: ' || lrComp(t).dome_component_id || '; ' || lrComp(t).type_code || ' - ' || lrComp(t).name);
    END LOOP;
    
END p_add_app_comp_to_patch;


END PKG_PATCH_OBJECTS;
/

SHOW ERRORS;

Prompt Package PKG_PATCH_OBJECTS;
CREATE OR REPLACE PACKAGE PKG_PATCH_OBJECTS AS 


gcCompListCollName varchar2(30) := 'COLL_P470_COMP_LIST';



FUNCTION f_next_version(
    p_object_id objects.object_id%TYPE
) RETURN patch_objects.object_version%TYPE;




PROCEDURE p_add_object_to_patch(
    p_object_id objects.object_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_user_id app_users.app_user_id%TYPE,
    p_as_patch_script_yn patch_objects.as_patch_script_yn%TYPE DEFAULT 'N'
);


--function returns error message with patch name where object is already included
--returns null if object can be added to patch
FUNCTION f_object_in_another_patch_err(
    p_object_id objects.object_id%TYPE,
    p_current_patch_id patches.patch_id%TYPE
) RETURN varchar2;


--function is used on page 470 - it prepares app components list and stores it in APEX collection
PROCEDURE p_prepare_component_list (
    p_patch_id patches.patch_id%TYPE,
    p_current_user_id app_users.app_user_id%TYPE
);

FUNCTION f_comp_list_coll_name RETURN varchar2;

PROCEDURE p_add_app_comp_to_patch (
    p_patch_id patches.patch_id%TYPE,
    p_current_user_id app_users.app_user_id%TYPE
);

END PKG_PATCH_OBJECTS;
/

SHOW ERRORS;




CREATE OR REPLACE PACKAGE PKG_RELEASES AS 


TYPE t_file IS RECORD (
    filename varchar2(4000),
    file_content blob
);

TYPE t_files IS TABLE OF t_file;


-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--getters
FUNCTION f_rls_code (
    p_release_id releases.release_id%TYPE
) RETURN releases.code%TYPE;



FUNCTION f_object_target_filename(
    p_object_id objects.object_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2;

FUNCTION f_script_target_filename(
    p_patch_script_id patch_scripts.patch_script_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2;



FUNCTION f_prepare_patch_files(
    p_patch_id patches.patch_id%TYPE,
    p_main_folder_name_prefix varchar2 default null 
) RETURN pkg_releases.t_files;

PROCEDURE p_prepare_patch_zip(
    p_patch_id patches.patch_id%TYPE,
    p_zip IN OUT blob,
    p_filename OUT varchar2
);



PROCEDURE p_download_rls_zip(
    p_release_id releases.release_id%TYPE,
    p_merge_files_yn varchar2 default 'N'
);



PROCEDURE p_download_report(
    p_release_id releases.release_id%TYPE,
    p_format varchar2  --MARKDOWN
);


FUNCTION f_script_filename(
    p_release_script_type_id release_script_types.rls_script_type_id%TYPE,
    p_nr release_scripts.order_by%TYPE
) RETURN release_scripts.filename%TYPE;


FUNCTION f_release_patches(
    p_release_id releases.release_id%TYPE
) RETURN varchar2;


PROCEDURE p_add_patches_to_release (
    p_release_id releases.release_id%TYPE
);


END PKG_RELEASES;
/


CREATE OR REPLACE PACKAGE BODY PKG_RELEASES AS 

CURSOR c_doc_part_texts(p_release_id releases.release_id%TYPE) IS
    SELECT 
        rdp.placeholder,
        rdpt.part_text
    FROM 
        release_doc_part_txt rdpt 
        JOIN release_doc_parts rdp ON rdpt.release_doc_part_id = rdp.release_doc_part_id
    WHERE rdpt.release_id = p_release_id
    ;

TYPE t_doc_part_texts IS TABLE OF c_doc_part_texts%ROWTYPE;


CURSOR c_release_tasks(p_release_id releases.release_id%TYPE) IS
    SELECT
        t.code || ' - ' || t.name as code_and_name,
        t.external_link,
        count(*) as no_of_patches
    FROM 
        patches p
        JOIN tasks t ON p.task_id = t.task_id
    WHERE p.release_id = p_release_id
    GROUP BY 
        t.code,
        t.name,
        t.external_link
    ORDER BY 1
    ;

TYPE t_release_tasks IS TABLE OF c_release_tasks%ROWTYPE;


CURSOR c_release_objects(p_release_id releases.release_id%TYPE) IS
SELECT
    v_po.object_id,
    v_po.schema_name,
    v_po.object_group,
    v_po.object_type,
    v_po.object_name,
    listagg(v_p.patch_code, ', ') within group (order by v_po.object_version) as included_in_patches
FROM 
    v_patches v_p
    JOIN v_patch_scr_and_obj v_po ON v_p.patch_id = v_po.patch_id
WHERE 
    v_p.release_id = p_release_id
AND v_po.object_group <> 'PATCH_SCRIPT'
GROUP BY
    v_po.object_id,
    v_po.schema_name,
    v_po.object_group,
    v_po.object_type,
    v_po.object_name
ORDER BY 
    v_po.object_group,
    v_po.object_type,
    v_po.object_name
;


TYPE t_release_objects IS TABLE OF c_release_objects%ROWTYPE;


FUNCTION f_get_release(
    p_release_id releases.release_id%TYPE
) RETURN releases%ROWTYPE IS

    lrRelease releases%ROWTYPE;

BEGIN
    SELECT *
    INTO lrRelease
    FROM releases
    WHERE release_id = p_release_id
    ;

    RETURN lrRelease;
END f_get_release;


FUNCTION f_rls_code (
    p_release_id releases.release_id%TYPE
) RETURN releases.code%TYPE IS
BEGIN
    RETURN f_get_release(p_release_id).code;
END f_rls_code;



PROCEDURE p_add(
    p_script IN OUT clob,
    p_text_to_add varchar2,
    p_separator varchar2 default chr(10)
) IS
BEGIN
    p_script := p_script || p_text_to_add || p_separator;
END p_add;



PROCEDURE p_enable_disable_apps(
    p_script IN OUT clob,
    p_zip IN OUT blob,
    p_patch pkg_patches.c_patch%ROWTYPE,
    p_enable_or_disable varchar2  --values "ENABLE" or "DISABLE"
) IS

    lcEnDisScript clob;
    lcFileName varchar2(1000);
    lcAppsExist varchar2(1);

BEGIN
    --check if there are any apps to be disabled; if not just return and do not add file
    <<apps_to_disable>>
    BEGIN
        SELECT 'Y'
        INTO lcAppsExist
        FROM patch_disable_apps
        WHERE patch_id = p_patch.patch_id
        ;
        
    EXCEPTION WHEN no_data_found THEN
        RETURN;
    END apps_to_disable;
    

    --get script for enable or disable apps
    /*
    SELECT pkg_utils.f_blob_to_clob(blob_file)
    INTO lcEnDisScript
    FROM additional_files
    WHERE code = 'ENDISAPP'
    ;
    */
    
    --replace placeholders
    lcEnDisScript := replace(lcEnDisScript, '__PATCH_ID__', p_patch.patch_id);
    lcEnDisScript := replace(lcEnDisScript, '__USERNAME__', 'AUCTIM');
    lcEnDisScript := replace(lcEnDisScript, '__STATUS__', (CASE p_enable_or_disable WHEN 'ENABLE' THEN 'AVAILABLE_W_EDIT_LINK' ELSE 'UNAVAILABLE_URL' END) );
    lcEnDisScript := replace(lcEnDisScript, '__URL__', '&AI_DOMAIN./i/MO/images/maintenance.htm');

    --file name 
    lcFileName := 
        'utils/' || 
        (CASE p_enable_or_disable WHEN 'ENABLE' THEN 'enable_apps' ELSE 'disable_apps' END) || 
        '.sql'
    ;

    --add script file to ZIP
    apex_zip.add_file(
        p_zip, 
        p_patch.root_folder || lcFileName,
        pkg_utils.f_clob_to_blob(lcEnDisScript)
    );

    --add script call to script
    p_add(p_script, 'PROMPT ' || lower(p_enable_or_disable) || ' apps');    
    p_add(p_script, '@@' || lcFileName);    
    p_add(p_script, null);    

END p_enable_disable_apps;


PROCEDURE p_recompile_objects(
    p_script IN OUT clob,
    p_zip IN OUT blob,
    p_patch pkg_patches.c_patch%ROWTYPE,
    p_create_file boolean
) IS

    CURSOR c_db_schemas_in_patch IS
        SELECT DISTINCT db_schema_name
        FROM 
            (
            SELECT v_dbo.db_schema_name
            FROM 
                patch_objects po
                JOIN v_database_objects v_dbo ON po.object_id = v_dbo.db_object_id
            WHERE patch_id = p_patch.patch_id
            UNION ALL
            SELECT v_dbs.schema_name
            FROM 
                patch_scripts ps
                JOIN v_database_schemas v_dbs ON ps.database_schema_id = v_dbs.schema_id
            WHERE patch_id = p_patch.patch_id
            )
        ;

    TYPE t_db_schemas_in_patch IS TABLE OF c_db_schemas_in_patch%ROWTYPE;
    lrSchemasInPatch t_db_schemas_in_patch;

    lcRecompScript clob;

BEGIN
    --get schemas
    OPEN c_db_schemas_in_patch;
    FETCH c_db_schemas_in_patch BULK COLLECT INTO lrSchemasInPatch;
    CLOSE c_db_schemas_in_patch;
    
    --if there is not schemas to compile... return
    if lrSchemasInPatch.count = 0 then
        RETURN;
    end if;

    --prepare script (if needed)
    if p_create_file then
        p_add(lcRecompScript, 'BEGIN');
        
        FOR t IN 1 .. lrSchemasInPatch.count LOOP
            p_add(lcRecompScript, '    DBMS_UTILITY.compile_schema(schema => ''' || lrSchemasInPatch(t).db_schema_name || ''', compile_all => false);');
        END LOOP;
        
        p_add(lcRecompScript, 'END;');
        p_add(lcRecompScript, '/');
        p_add(lcRecompScript, null);
    
        p_add(lcRecompScript, q'[SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID' AND object_type not like '%JAVA%']');
        p_add(lcRecompScript, '/');
        
        --add script file to ZIP
        apex_zip.add_file(
            p_zip, 
            p_patch.root_folder || 'utils/recompile.sql',
            pkg_utils.f_clob_to_blob(lcRecompScript)
        );
        
    end if;

    --add script call to script
    p_add(p_script, 'PROMPT recompile objects...');
    p_add(p_script, '@@' || 'utils/recompile.sql');
    p_add(p_script, null);
    
END p_recompile_objects;


FUNCTION f_object_target_filename(
    p_object_id objects.object_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2 IS

    lrData pkg_objects.c_data%ROWTYPE;
    
BEGIN
    --get data
    OPEN pkg_objects.c_data(p_object_id);
    FETCH pkg_objects.c_data INTO lrData;
    CLOSE pkg_objects.c_data;
    
    RETURN 
        CASE p_replace_schema_yn 
            WHEN 'Y' THEN replace(lrData.target_folder, '#SCHEMA#', lower(lrData.db_schema) ) 
            ELSE lrData.target_folder 
        END || 
        '/' || 
        lrData.filename
    ;
    
END f_object_target_filename;


FUNCTION f_script_target_filename(
    p_patch_script_id patch_scripts.patch_script_id%TYPE,
    --p_patch_template_id patch_templates.patch_template_id%TYPE,
    p_replace_schema_yn varchar2 default 'N'
) RETURN varchar2 IS

    CURSOR c_data IS
    SELECT
        v_dbs.schema_name as db_schema,
        lower(ps.filename) as filename,
        nvl(ot.target_folder, pst.target_folder) as target_folder
    FROM 
        patch_scripts ps
        JOIN patch_script_types pst ON ps.patch_script_type_id = pst.patch_script_type_id
        LEFT JOIN object_types ot ON ps.object_type_id = ot.object_type_id
        JOIN v_database_schemas v_dbs ON ps.database_schema_id = v_dbs.schema_id
    WHERE ps.patch_script_id = p_patch_script_id;

    lrData c_data%ROWTYPE;

BEGIN
    --get data
    OPEN c_data;
    FETCH c_data INTO lrData;
    CLOSE c_data;

    RETURN 
        CASE p_replace_schema_yn 
            WHEN 'Y' THEN replace(lrData.target_folder, '#SCHEMA#', lower(lrData.db_schema) ) 
            ELSE lrData.target_folder 
        END || 
        '/' || 
        lrData.filename
    ;
END f_script_target_filename;




FUNCTION f_prepare_patch_files(
    p_patch_id patches.patch_id%TYPE,
    p_main_folder_name_prefix varchar2 default null 
) RETURN pkg_releases.t_files AS

    lrPatch pkg_patches.c_patch%ROWTYPE;
    lrFiles pkg_releases.t_files := pkg_releases.t_files();

BEGIN
    --patch data
    OPEN pkg_patches.c_patch(p_patch_id);
    FETCH pkg_patches.c_patch INTO lrPatch;
    CLOSE pkg_patches.c_patch;

    EXECUTE IMMEDIATE 'BEGIN ' || lrPatch.patch_procedure_name || '(p_id => :1, p_patch_or_release => ''P'', p_files => :2); END;' 
    USING IN p_patch_id, OUT lrFiles;
    
    --for release - store patches within sub-folder
    if p_main_folder_name_prefix is not null then
        FOR t IN 1 .. lrFiles.count LOOP
            lrFiles(t).filename := p_main_folder_name_prefix || lrFiles(t).filename;
        END LOOP;
    end if;

    RETURN lrFiles;
    
END f_prepare_patch_files;



PROCEDURE p_prepare_patch_zip(
    p_patch_id patches.patch_id%TYPE,
    p_zip IN OUT blob,
    p_filename OUT varchar2
) AS

    lrPatch pkg_patches.c_patch%ROWTYPE;
    lrFiles pkg_releases.t_files := pkg_releases.t_files();
    
BEGIN
    --patch data
    OPEN pkg_patches.c_patch(p_patch_id);
    FETCH pkg_patches.c_patch INTO lrPatch;
    CLOSE pkg_patches.c_patch;

    --patch files
    lrFiles := f_prepare_patch_files(
        p_patch_id => p_patch_id
    );

    FOR t IN 1 .. lrFiles.count LOOP
        apex_zip.add_file(
            p_zipped_blob => p_zip, 
            p_file_name => lrFiles(t).filename,
            p_content => lrFiles(t).file_content
        );
    END LOOP;


    --filename and finish ZIP
    p_filename := lrPatch.filename;
    
    apex_zip.finish(p_zip);
    
    
END p_prepare_patch_zip;



FUNCTION f_prepare_rls_files(
    p_release_id releases.release_id%TYPE,
    p_merge_files_yn varchar2 default 'N'
) RETURN pkg_releases.t_files IS

    lrReleaseFiles t_files;

    CURSOR c_patch_template IS
        SELECT 
            r.patch_template_procedure_name as procedure_name
        FROM v_releases r
        WHERE r.release_id = p_release_id
        ;

    lrPatchTemplate c_patch_template%ROWTYPE;

BEGIN
    --patch template procedure name and patches subfolder (used for release)
    OPEN c_patch_template;
    FETCH c_patch_template INTO lrPatchTemplate;
    CLOSE c_patch_template;

    --get files
    EXECUTE IMMEDIATE 'BEGIN ' || lrPatchTemplate.procedure_name || '(p_id => :1, p_patch_or_release => ''RELEASE'', p_files => :2); END;' 
    USING IN p_release_id, OUT lrReleaseFiles;
    
    RETURN lrReleaseFiles;
    
END f_prepare_rls_files;


PROCEDURE p_download_rls_zip(
    p_release_id releases.release_id%TYPE,
    p_merge_files_yn varchar2 default 'N'
) IS

    lbZip blob;
    lrFiles pkg_releases.t_files;

BEGIN
    --get all release files
    lrFiles := f_prepare_rls_files (
        p_release_id => p_release_id,
        p_merge_files_yn => p_merge_files_yn
    );
    
    --prepare ZIP
    FOR t IN 1 .. lrFiles.count LOOP
        apex_zip.add_file(
            p_zipped_blob => lbZip, 
            p_file_name => lrFiles(t).filename,
            p_content => lrFiles(t).file_content
        );
    END LOOP;

    apex_zip.finish(lbZip);

    --get filename and download ZIP file
    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => f_rls_code(p_release_id) || '.zip'
    );

END p_download_rls_zip;



PROCEDURE p_prepare_html_report(
    p_release_id releases.release_id%TYPE,
    p_report IN OUT NOCOPY blob,
    p_filename OUT varchar2
) IS

    lrRelease v_releases%ROWTYPE;
    lrDocPartTexts t_doc_part_texts;
    lrTasks t_release_tasks;
    lrObjects t_release_objects;
    
    lcDoc clob;
    lcText varchar2(32000);

BEGIN
    --release data
    SELECT *
    INTO lrRelease
    FROM v_releases
    WHERE release_id = p_release_id
    ;
    
    
    --document template
    lcDoc := pkg_settings.f_project_sett_vc2(
        p_project_id => lrRelease.project_id,
        p_code => 'REL_DOC_HTML_TEMPL'
    );
    
    
    --basic placeholders
    lcDoc := replace(lcDoc, '#RELEASE_CODE#', lrRelease.code);
    lcDoc := replace(lcDoc, '#RELEASE_NAME#', lrRelease.description);
    lcDoc := replace(lcDoc, '#RELEASE_DATE#', to_char(lrRelease.planed_release_date, 'dd.mm.yyyy') );
    lcDoc := replace(lcDoc, '#RELEASE_TIME#', to_char(lrRelease.planed_release_date, 'hh24:mi') );
    lcDoc := replace(lcDoc, '#RELEASE_DURATION#', lrRelease.planed_duration);

    
    --document part texts
    OPEN c_doc_part_texts(p_release_id);
    FETCH c_doc_part_texts BULK COLLECT INTO lrDocPartTexts;
    CLOSE c_doc_part_texts;
    
    FOR t IN 1 .. lrDocPartTexts.count LOOP
        lcDoc := replace(
            lcDoc, 
            lrDocPartTexts(t).placeholder, 
            replace(lrDocPartTexts(t).part_text, chr(10), '<br>')
        );
    END LOOP;
    
    
    --task list
    OPEN c_release_tasks(p_release_id);
    FETCH c_release_tasks BULK COLLECT INTO lrTasks;
    CLOSE c_release_tasks;
    
    lcText := '<ul>' || chr(10);
    
    FOR t IN 1 .. lrTasks.count LOOP
        lcText := lcText || 
            '<li>' || 
            '<a href="' || lrTasks(t).external_link || '" target="_blank">' ||
            lrTasks(t).code_and_name || '</a></li>' || 
            chr(10)
        ;
    END LOOP;

    lcText := lcText || '</ul>' || chr(10);
    
    lcDoc := replace(lcDoc, '#TASKS#', lcText);
    
    
    
    --object list
    lcText := '<table style="border-collapse: collapse; width: 100%;" border="1"><tbody>
<tr>
<td style="width: 10%; text-align: center;"><strong>Object Group</strong></td>
<td style="width: 10%; text-align: center;"><strong>Object Type</strong></td>
<td style="width: 55%; text-align: center;"><strong>Object Name</strong></td>
<td style="width: 25%; text-align: center;"><strong>Included in patches</strong></td>
</tr>
' || chr(10);
    
    OPEN c_release_objects(p_release_id);
    FETCH c_release_objects BULK COLLECT INTO lrObjects;
    CLOSE c_release_objects;
    
    FOR t IN 1 .. lrObjects.count LOOP
        lcText := lcText || 
'<tr>
<td>' || initcap(lrObjects(t).object_group) || '</td>
<td>' || lrObjects(t).object_type || '</td>
<td>' || lrObjects(t).object_name || '</td>
<td>' || lrObjects(t).included_in_patches || '</td>
</tr>' || chr(10)
;
        
    END LOOP;

    lcText := lcText || '</tbody></table>' || chr(10);

    lcDoc := replace(lcDoc, '#OBJECTS#', lcText);

    
    --filename
    p_filename := lrRelease.code || '.html';
    
    
    --convert to blob
    p_report := pkg_utils.f_clob_to_blob(lcDoc);
    
    
END p_prepare_html_report;


PROCEDURE p_prepare_md_report(
    p_release_id releases.release_id%TYPE,
    p_report IN OUT NOCOPY blob,
    p_filename OUT varchar2
) IS

    lrRelease v_releases%ROWTYPE;
    lrDocPartTexts t_doc_part_texts;
    lrTasks t_release_tasks;
    lrObjects t_release_objects;
    
    lcDoc clob;
    lcText varchar2(32000);

BEGIN
    --release data
    SELECT *
    INTO lrRelease
    FROM v_releases
    WHERE release_id = p_release_id
    ;
    
    
    --document template
    lcDoc := pkg_settings.f_project_sett_vc2(
        p_project_id => lrRelease.project_id,
        p_code => 'REL_DOC_MD_TEMPLATE'
    );
    
    
    --basic placeholders
    lcDoc := replace(lcDoc, '#RELEASE_CODE#', lrRelease.code);
    lcDoc := replace(lcDoc, '#RELEASE_NAME#', lrRelease.description);
    lcDoc := replace(lcDoc, '#RELEASE_DATE#', to_char(lrRelease.planed_release_date, 'dd.mm.yyyy') );
    lcDoc := replace(lcDoc, '#RELEASE_TIME#', to_char(lrRelease.planed_release_date, 'hh24:mi') );
    lcDoc := replace(lcDoc, '#RELEASE_DURATION#', lrRelease.planed_duration);

    
    --document part texts
    OPEN c_doc_part_texts(p_release_id);
    FETCH c_doc_part_texts BULK COLLECT INTO lrDocPartTexts;
    CLOSE c_doc_part_texts;
    
    FOR t IN 1 .. lrDocPartTexts.count LOOP
        lcDoc := replace(lcDoc, lrDocPartTexts(t).placeholder, lrDocPartTexts(t).part_text);
    END LOOP;
    
    
    --task list
    OPEN c_release_tasks(p_release_id);
    FETCH c_release_tasks BULK COLLECT INTO lrTasks;
    CLOSE c_release_tasks;
    
    FOR t IN 1 .. lrTasks.count LOOP
        lcText := lcText || 
            '- ' || 
            '[' || lrTasks(t).code_and_name || ']' || 
            '(' || lrTasks(t).external_link || ')' || 
            chr(10)
        ;
    END LOOP;
    
    lcDoc := replace(lcDoc, '#TASKS#', lcText);
    
    
    
    --object list
    lcText := null;
    
    OPEN c_release_objects(p_release_id);
    FETCH c_release_objects BULK COLLECT INTO lrObjects;
    CLOSE c_release_objects;
    
    FOR t IN 1 .. lrObjects.count LOOP
        if t = 1 or (t > 1 and lrObjects(t).object_group <> lrObjects(t - 1).object_group) then
            lcText := lcText || '#### ' || initcap(lrObjects(t).object_group) || chr(10);
        
        else
            lcText := lcText || 
                '- ' || lrObjects(t).object_type || ' ' || 
                lrObjects(t).object_name || ' (' || 
                lrObjects(t).included_in_patches || ')' || chr(10) 
            ;
        end if;
        
    END LOOP;

    lcDoc := replace(lcDoc, '#OBJECTS#', lcText);

    
    --filename
    p_filename := lrRelease.code || '.md';
    
    
    --convert to blob
    p_report := pkg_utils.f_clob_to_blob(lcDoc);
    
    
END p_prepare_md_report;



PROCEDURE p_download_report(
    p_release_id releases.release_id%TYPE,
    p_format varchar2
) IS

    lbReport blob;
    lcFilename varchar2(1000);

BEGIN
    if p_format = 'MARKDOWN' then
        p_prepare_md_report(
            p_release_id => p_release_id,
            p_report => lbReport,
            p_filename => lcFilename
        );

    elsif p_format = 'HTML' then
        p_prepare_html_report(
            p_release_id => p_release_id,
            p_report => lbReport,
            p_filename => lcFilename
        );

    end if;

    --download document
    pkg_utils.p_download_document(
        p_doc => lbReport,
        p_file_name => lcFilename
    );

END;



FUNCTION f_script_filename(
    p_release_script_type_id release_script_types.rls_script_type_id%TYPE,
    p_nr release_scripts.order_by%TYPE
) RETURN release_scripts.filename%TYPE IS

    lcFilename release_scripts.filename%TYPE;

BEGIN
    SELECT file_name
    INTO lcFilename
    FROM 
        (
        SELECT 
            lower(rst.code) || '_' || to_char(nvl(p_nr, 1), 'fm000') || '.sql' as file_name,
            row_number() over (order by rst.seq asc) as rn
        FROM release_script_types rst
        WHERE 
            rst.rls_script_type_id = p_release_script_type_id
        OR  p_release_script_type_id is null
        )
    WHERE rn = 1
    ;

    RETURN lcFilename;
    
END f_script_filename;


FUNCTION f_release_patches(
    p_release_id releases.release_id%TYPE
) RETURN varchar2 IS

    CURSOR c_patches IS
        SELECT
            CASE 
                WHEN p.confirmed_on is null THEN '<span style="color:#AAAAAA">' || t.code || '_' || p.patch_number || ' - ' || t.name || '</span>' 
                ELSE t.code || '_' || p.patch_number || ' - ' || t.name
            END as patch_name 
        FROM 
            patches p
            JOIN tasks t ON p.task_id = t.task_id
        WHERE p.release_id = p_release_id
        ORDER BY patch_name
    ;

    TYPE t_patches IS TABLE OF c_patches%ROWTYPE;
    lrPatches t_patches;

    lcPatches varchar2(32000);
    lcSeparator varchar2(50) := '<br>';

BEGIN
    OPEN c_patches;
    FETCH c_patches BULK COLLECT INTO lrPatches;
    CLOSE c_patches;

    FOR t IN 1 .. lrPatches.count LOOP
        lcPatches := lcPatches || lrPatches(t).patch_name || lcSeparator;
    END LOOP;
    lcPatches := rtrim(lcPatches, lcSeparator);
    
    RETURN lcPatches;
    
END f_release_patches;


PROCEDURE p_add_patches_to_release (
    p_release_id releases.release_id%TYPE
) IS
BEGIN
    --selected patch IDs are already stored in the APEX collection named SELECTED_PATCHES_COLL
    UPDATE patches
    SET release_id = p_release_id
    WHERE 
        patch_id in (SELECT n001 FROM apex_collections WHERE collection_name = 'SELECTED_PATCHES_COLL')
    ;

END p_add_patches_to_release;


END PKG_RELEASES;
/




CREATE OR REPLACE PACKAGE PKG_PATCHES AS 

--patch ZIP filename
FUNCTION f_patch_filename(
    p_patch_id patches.patch_id%TYPE,
    p_extension varchar2 default null
) RETURN varchar2;



CURSOR c_patch(p_patch_id patches.patch_id%TYPE) IS
    SELECT
        v_p.patch_id,
        v_p.project_id,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '.zip') as filename,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '_src.zip') as src_filename,
        pkg_patches.f_patch_filename(p_patch_id => p_patch_id, p_extension => '/') as root_folder,
        v_p.patch_code as patch_code,
        v_p.task_code_and_name || ' (' || v_p.patch_number || ')' as name,
        v_p.patch_template_id,
        pkg_patch_templates.f_get_procedure_name(patch_template_id) as patch_procedure_name
    FROM 
        v_patches v_p
    WHERE v_p.patch_id = p_patch_id
;


CURSOR c_patch_schemas (
    p_patch_id patches.patch_id%TYPE
) IS 
    SELECT DISTINCT 
        v_pso.schema_name as schema_name
    FROM v_patch_scr_and_obj v_pso
    WHERE 
        v_pso.patch_id = p_patch_id
    AND v_pso.object_as_patch_script_yn = 'N'
;

TYPE t_patch_schemas IS TABLE OF c_patch_schemas%ROWTYPE;



CURSOR c_patch_files (
    p_patch_id patches.patch_id%TYPE
) IS 
    SELECT
        v_pso.filename_replaced as filename,
        pkg_utils.f_clob_to_blob(v_pso.sql_content) as blob_file,
        v_pso.schema_name,
        CASE 
            WHEN v_pso.schema_name <> lag(v_pso.schema_name, 1, 'not existing one') over (order by v_pso.schema_name, v_pso.seq_nr, v_pso.filename) THEN 'Y' 
            ELSE 'N' 
        END as change_schema_yn
    FROM v_patch_scr_and_obj v_pso
    WHERE 
        v_pso.patch_id = p_patch_id
    AND v_pso.object_as_patch_script_yn = 'N'
    ORDER BY
        v_pso.schema_name,
        v_pso.seq_nr,
        v_pso.filename
;

TYPE t_patch_files IS TABLE OF c_patch_files%ROWTYPE;




--getters
FUNCTION f_get_v_patch(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches%ROWTYPE;

FUNCTION f_get_project_id(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches.project_id%TYPE;


PROCEDURE p_confirm_patch(
    p_patch_id patches.patch_id%TYPE,
    p_user_confirmed_id patches.confirmed_app_user_id%TYPE
);

--unlock patch
FUNCTION f_unlock_patch_possible(
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2;

PROCEDURE p_unlock_patch(
    p_patch_id patches.patch_id%TYPE
);


PROCEDURE p_download_zip(
    p_patch_id patches.patch_id%TYPE
);



--on which environments is patch installed
FUNCTION f_installed_on(
    p_patch_id patches.patch_id%TYPE,
    p_separator varchar2 default chr(10)
) RETURN varchar2;



--user works on patch
PROCEDURE p_start_stop_working(
    p_user_id app_users.app_user_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_action varchar2  --START or STOP
);



--download ZIP file with object SQL source 
PROCEDURE p_download_source(
    p_patch_id patches.patch_id%TYPE
);




--warnings on patch
FUNCTION f_patch_warnings (
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2;


--move tasks to another task group
PROCEDURE p_move_tasks (
    p_new_group_id task_groups.task_group_id%TYPE 
);


--mark patches as ready for production
PROCEDURE p_mark_for_production;


END PKG_PATCHES;
/

CREATE OR REPLACE PACKAGE BODY DOME.PKG_PATCHES AS 


FUNCTION f_get_v_patch(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches%ROWTYPE IS

    lrPatch v_patches%ROWTYPE;

BEGIN
    SELECT *
    INTO lrPatch
    FROM v_patches
    WHERE patch_id = p_patch_id;

    RETURN lrPatch;
END f_get_v_patch;


PROCEDURE p_confirm_patch(
    p_patch_id patches.patch_id%TYPE,
    p_user_confirmed_id patches.confirmed_app_user_id%TYPE
) AS

    CURSOR c_object_scripts IS
        SELECT *
        FROM v_patch_obj_src_scripts
        WHERE patch_id = p_patch_id
    ;

BEGIN
    --get patch object scripts
    FOR t IN c_object_scripts LOOP
        
        UPDATE patch_objects
        SET 
            sql_content = t.object_script,
            object_version = t.next_version
        WHERE patch_object_id = t.patch_object_id
        ;
        
    END LOOP;


    --mark patch as confirmed
    UPDATE patches
    SET
        confirmed_on = sysdate,
        confirmed_app_user_id = p_user_confirmed_id
    WHERE patch_id = p_patch_id;
    
    --stop working on patch (if anyone is currently working on it)
    UPDATE user_works_on_patch 
    SET stop = sysdate
    WHERE
        patch_id = p_patch_id
    AND stop is null;
    
    
END p_confirm_patch;



PROCEDURE p_unlock_patch(
    p_patch_id patches.patch_id%TYPE
) AS
BEGIN
    --mark patch as not confimed
    UPDATE patches
    SET
        confirmed_on = null,
        confirmed_app_user_id = null
    WHERE patch_id = p_patch_id
    ;

    --set patch objects version to null (will be again set to next value when patch is confirmed)
    UPDATE patch_objects po
    SET po.object_version = null
    WHERE po.patch_id = p_patch_id
    ;

END p_unlock_patch;



PROCEDURE p_download_zip(
    p_patch_id patches.patch_id%TYPE
) AS

    lbZip blob;
    lcFilename varchar2(1000);

BEGIN
    --get ZIP
    pkg_releases.p_prepare_patch_zip(
        p_patch_id => p_patch_id,
        p_zip => lbZip,
        p_filename => lcFilename
    );
    
    --download document
    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => lcFilename
    );
END p_download_zip;





FUNCTION f_installed_on(
    p_patch_id patches.patch_id%TYPE,
    p_separator varchar2 default chr(10)
) RETURN varchar2 AS

    lcInstalledOn varchar2(32000);

BEGIN
    SELECT 
        listagg(env.code || ': ' || to_char(pi.start_date, 'dd.mm.yyyy hh24:mi'), p_separator ) within group (order by pi.end_date)
    INTO lcInstalledOn
    FROM 
        patch_installs pi
        JOIN environments env ON pi.environment_id = env.environment_id
    WHERE 
        pi.patch_id = p_patch_id
    AND pi.end_date is not null
    ;

    RETURN lcInstalledOn;
END f_installed_on;


FUNCTION f_unlock_patch_possible(
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2 AS

    --objects
    CURSOR c_objects IS
        WITH w_max AS (
            SELECT 
                vju.object_id,
                vju.object_version as max_version,
                vju.max_patch_data
            FROM
                (
                SELECT 
                    po.object_id,
                    po.patch_id,
                    po.object_version,
                    v_p.task_name || ' (' || v_p.patch_number || '); owned by ' || v_p.user_owner as max_patch_data,
                    row_number() over (partition by po.object_id order by po.object_version desc) as rbr
                FROM 
                    patch_objects po
                    JOIN v_patches v_p ON po.patch_id = v_p.patch_id
                    JOIN patch_objects curr_patch ON po.object_id = curr_patch.object_id AND curr_patch.patch_id = p_patch_id
                ) vju
            WHERE 
                vju.rbr = 1
        )
        SELECT 
            (CASE 
                WHEN v_dbo.db_object_id is not null THEN v_dbo.object_type_name || ' - ' || v_dbo.display
                WHEN v_apc.app_component_id is not null THEN v_apc.object_type_name || ' - ' || v_apc.display
                WHEN v_app.application_id is not null THEN v_app.display
            ELSE 'unknown' END) as obj_name,
            po.object_version,
            w_max.max_version,
            w_max.max_patch_data
        FROM 
            patch_objects po 
            JOIN w_max ON po.object_id = w_max.object_id
            LEFT JOIN v_database_objects v_dbo ON po.object_id = v_dbo.db_object_id
            LEFT JOIN v_app_components v_apc ON po.object_id = v_apc.app_component_id
            LEFT JOIN v_applications v_app ON po.object_id = v_app.application_id
        WHERE
            po.patch_id = p_patch_id
        AND w_max.max_version > po.object_version
        ;

    lcObjects varchar2(32000);

BEGIN
    FOR t IN c_objects LOOP
        lcObjects := lcObjects || '- ' || t.obj_name || '; newer version ' || t.max_version || ' in patch ' || t.max_patch_data || '<br>';
    END LOOP;

    RETURN lcObjects;
END f_unlock_patch_possible;



PROCEDURE p_start_stop_working(
    p_user_id app_users.app_user_id%TYPE,
    p_patch_id patches.patch_id%TYPE,
    p_action varchar2  --START or STOP
) IS
BEGIN
    --stop work on all patches on which then user is working
    UPDATE user_works_on_patch 
    SET stop = sysdate
    WHERE
        app_user_id = p_user_id
    AND stop is null;
    
    --if action is START then start working on a patch
    if p_action = 'START' then
        INSERT INTO user_works_on_patch(app_user_id, patch_id)
        VALUES (p_user_id, p_patch_id)
        ;
    end if;

END p_start_stop_working;



FUNCTION f_patch_filename(
    p_patch_id patches.patch_id%TYPE,
    p_extension varchar2 default null
) RETURN varchar2 IS

    lcFilename varchar2(1000);

    CURSOR c_patch IS
    SELECT
        regexp_replace(
            replace( substr(v_p.task_code || '_' || v_p.patch_number || ' - ' || v_p.task_name, 1, 100), '"', null),
            '[/\:*?<>]',
            '_'
        )
        || p_extension as filename
    FROM v_patches v_p
    WHERE v_p.patch_id = p_patch_id;

BEGIN
    --patch data
    OPEN c_patch;
    FETCH c_patch INTO lcFilename;
    CLOSE c_patch;

    RETURN lcFilename;
END f_patch_filename;



PROCEDURE p_download_source(
    p_patch_id patches.patch_id%TYPE
) IS

    CURSOR c_patch_files IS
        --objects
        SELECT
            v_src.source_filename,
            pkg_utils.f_clob_to_blob(v_src.object_script) as blob_file
        FROM v_patch_obj_src_scripts v_src
        WHERE v_src.patch_id = p_patch_id
        ;

    lrPatch pkg_patches.c_patch%ROWTYPE;
    lbZip blob;

BEGIN
    --patch data
    OPEN pkg_patches.c_patch(p_patch_id);
    FETCH pkg_patches.c_patch INTO lrPatch;
    CLOSE pkg_patches.c_patch;
    

    --files
    FOR t IN c_patch_files LOOP
        apex_zip.add_file(
            p_zipped_blob => lbZip, 
            p_file_name => t.source_filename,
            p_content => t.blob_file
        );
    END LOOP;
    
    
    --finish ZIP and download document
    apex_zip.finish(lbZip);

    pkg_utils.p_download_document(
        p_doc => lbZip,
        p_file_name => lrPatch.src_filename
    );
    
END p_download_source;


FUNCTION f_get_project_id(
    p_patch_id patches.patch_id%TYPE
) RETURN v_patches.project_id%TYPE IS
BEGIN
    RETURN f_get_v_patch(p_patch_id).project_id;
END f_get_project_id;




FUNCTION f_patch_warnings (
    p_patch_id patches.patch_id%TYPE
) RETURN varchar2 IS

    lnCount pls_integer;
    lcWarning varchar2(32000);

    PROCEDURE p_add (
        p_text varchar2,
        p_separator varchar2 default chr(10)
    ) IS
    BEGIN
        lcWarning := lcWarning || p_text || p_separator;
    END p_add;

BEGIN
    --Is patch empty? Are there any scripts and objects in patch?
    SELECT count(*)
    INTO lnCount
    FROM 
        (
        SELECT 1
        FROM patch_scripts 
        WHERE patch_id = p_patch_id
        UNION ALL
        SELECT 1
        FROM patch_objects 
        WHERE patch_id = p_patch_id
        )
    ;
    
    if lnCount = 0 then
        p_add('Patch is empty');
    end if;
    
    RETURN lcWarning;
    
END f_patch_warnings;


PROCEDURE p_move_tasks (
    p_new_group_id task_groups.task_group_id%TYPE 
) IS
BEGIN
    UPDATE tasks
    SET task_group_id = p_new_group_id
    WHERE 
        task_id in 
            (SELECT to_number(c001) FROM apex_collections WHERE collection_name = 'SELECTED_TASKS_COLL')
    ;
END p_move_tasks;


PROCEDURE p_mark_for_production IS
BEGIN
    UPDATE patches
    SET for_production_yn = 'Y'
    WHERE patch_id IN (SELECT to_number(c001) FROM apex_collections WHERE collection_name = 'SELECTED_PATCHES_COLL')
    ;
END p_mark_for_production;

END PKG_PATCHES;
/


