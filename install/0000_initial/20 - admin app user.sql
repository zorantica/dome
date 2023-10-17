--initial user - admin
BEGIN
    Insert into APP_USERS
       (APP_USER_ID, DISPLAY_NAME, LOGIN_USERNAME, LOGIN_PASSWORD)
     Values
       (1, 'Administrator', 'ADMIN', '---');
    
    pkg_auth.p_change_pwd ('ADMIN', 'admin');
    
    COMMIT;
END;
/

