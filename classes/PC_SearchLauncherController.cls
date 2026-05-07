/*********************************************************************************
Class Name        :     PC_SearchLauncherController
Description       :     Controller for PC_SearchLauncher Component
Created By        :     Haritha Reddy
Created Date      :     03-Nov-2019
Modification Log  :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy            03-Nov-2019              Initial Version
Haritha Reddy            17-Dec-2019              [PC-5791] Added error handling for getOrgNamespace method
*********************************************************************************/

public with sharing class PC_SearchLauncherController {
    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Method name  : getOrgNamespace
    * Return Type  : String
    * Description  : Return the namespace of client Org.
    *****************************************************************************************************/
    @AuraEnabled
    public static String getOrgNamespace() {
        try{
            return PC_Utility.getOrgNamespace();
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }
}