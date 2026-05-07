/**
 * Created by popavankumar on 10/30/2021.
 */

public with sharing class PC_WCDServiceClassNameWrapper{
    public String defaultclass;
    public List<careTeamRoles> classPerRole;

    public inherited sharing class careTeamRoles {
        public String role;
        public String classname;
    }
}