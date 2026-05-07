/*********************************************************************************
Class Name         :   PC_LookupController
Description        :   Controller for PC_Lookup Component
Created By         :   Haritha Reddy
Created Date       :   21-Nov-2019
Modification Log   :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          21-Nov-2019             [PC-5656] Initial Version
Haritha Reddy         16-Dec-2019              [PC-5791] Added error handling for searchDB Method
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_LookupController {
    @AuraEnabled(cacheable=true)
    public static String searchDB(String objectName, String fld_API_Text, String fld_API_Val,
            Integer lim,String fld_API_Search,String searchText ){

        List<ResultWrapper> lstRet = new List<ResultWrapper>();
        try {

            searchText = '\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';


            String query = 'SELECT ' + fld_API_Text + ' ,' + fld_API_Val +
                    ' FROM ' + objectName +
                    ' WHERE ' + fld_API_Search + ' LIKE ' + searchText +
                    ' LIMIT ' + lim;

            List<sObject> sobjList = Database.query(query);
            for (SObject s : sobjList) {
                ResultWrapper obj = new ResultWrapper();
                obj.objName = objectName;
                obj.text = String.valueOf(s.get(fld_API_Text)) ;
                obj.val = String.valueOf(s.get(fld_API_Val)) ;
                lstRet.add(obj);
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return JSON.serialize(lstRet) ;
    }

    public inherited sharing class ResultWrapper{
        public String objName {get;set;}
        public String text{get;set;}
        public String val{get;set;}
    }
}