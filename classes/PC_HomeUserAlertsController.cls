/*********************************************************************************************************
Class Name      : PC_HomeUserAlertsController
Description     : Controller for the Home Page Status Indicators
Created By      : Deloitte
Created Date    : July 7, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Cameron Reid                    July 07, 2016          	Initial Version
Alina Balan                     July 15, 2016          	PC-123: added "overrideAlert" and "getDefaultOverriddenReasonValue" methods
Shabda Bhujad					Dec 05, 2016			Added FLS checks to getActiveUserAlerts, getListViews, overrideAlert method
Ajinkya Deshmukh				June 08, 2017			FLS Check Added
Mayuresh Patil                  July 26, 2017           Updated CRUD/FLS Checks
Tushar Arora                    Jul 24,2019             PC-5166 Removed Patient Name formula field  to reference code from the Query in getActiveUserAlerts for the Visibility on Alerts Home Page
****************************************************************************************************************/
public with sharing class PC_HomeUserAlertsController {
	
    /*********************************************************************************
    Method Name    : getActiveUserAlerts
    Description    : retrieve Users Alerts based on the Programs they are assigned to
    Return Type    : List<PC_Alert__c>
    *********************************************************************************/ 
    @AuraEnabled
    public static List<alertWrapper> getActiveUserAlerts() {
    
        List<alertWrapper> lstAlertWrapper = new List<alertWrapper>();
        try {
            DateTime newDate = DateTime.Now().AddDays(7);
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Patient__c'), PC_Constants.getQualifiedAPIName('PC_Patient_ID__c'), PC_Constants.getQualifiedAPIName('PC_Reason_for_Alert__c'), PC_Constants.getQualifiedAPIName('PC_Type__c'), PC_Constants.getQualifiedAPIName('PC_Date_of_Alert__c'), PC_Constants.getQualifiedAPIName('PC_Alert_Status__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Alert__c'),PC_Database.Operation.Reading, fields);

            fields = new List<String>{'ParentID', 'MemberID'};
            PC_Database.assertAccess(PC_Constants.PC_CASETEAMMEMBER,PC_Database.Operation.Reading, fields);

            List<PC_Alert__c> lstAlerts = [SELECT Id, Name, PC_Program__c, PC_Program__r.CaseNumber, toLabel(PC_Program__r.RecordType.Name),PC_Program__r.Account.Name , PC_Patient_ID__c, PC_Reason_for_Alert__c, PC_Type__c, PC_Date_of_Alert__c, PC_Alert_Status__c FROM PC_Alert__c WHERE PC_Alert_Status__c = 'New' AND PC_Date_of_Alert__c <= :newDate AND PC_Program__c IN (SELECT ParentID FROM CaseTeamMember WHERE MemberID =: userinfo.getUserID()) ORDER BY PC_Date_of_Alert__c ASC];

        	for(PC_Alert__c a : lstAlerts) {
                lstAlertWrapper.add(new alertWrapper(a));
            } 
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
         
        return lstAlertWrapper;
    }
    
    /*********************************************************************************
    Method Name    : getListViews
    Description    : retrieve List View for Alerts.  This is a standard Salesforce Method found Here: 
                     https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/ref_force_navigateToList.htm
    Return Type    : List<ListView>
    *********************************************************************************/ 
    @AuraEnabled
    public static ListView getListViews() {
        String alertObj = PC_Constants.getQualifiedAPIName('PC_Alert__c');
        
        try {
            List<String> fields = new List<String>{'Name', 'SobjectType'};
            PC_Database.assertAccess(PC_Constants.PC_LISTVIEW,PC_Database.Operation.Reading, fields);
			
            List<ListView> listviews = [SELECT Id, Name FROM ListView WHERE SobjectType =: alertObj and Name='New Alerts'];
            
            if(listviews.size() <= 0) {
                listviews = [SELECT Id, Name FROM ListView WHERE SobjectType =: alertObj  limit 1];
            }
            
            ListView listview = null; 
            if(listviews.size() > 0) {
                listview = listviews[0];
            }
            return listview;
           }catch(Exception ex) {
               PC_Utility.logAndThrowException(ex);   
               return null;
           }
    }

     /*********************************************************************************
      Method Name    : overrideAlert
      Author         : Alina Balan
      Description    : This method is used for overridden an alert
      Return Type    : void 
      Parameter      : String objAlertId
     *********************************************************************************/
    @AuraEnabled 
    public static void overrideAlert(String objAlertId) {
        if (String.isBlank(objAlertId)) {
        	return;
        }
        try {
            //CRUD/FLS check for PC_Alert__c
        	List<String> fields = new List<String>{'Id'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Alert__c'),PC_Database.Operation.Reading, fields);
            List<PC_Alert__c> lstAlerts = [SELECT Id FROM PC_Alert__c WHERE Id =: objAlertId];
            PC_Alert__c oAlert;
            if (lstAlerts.size() > 0) {
                oAlert = lstAlerts[0];
            }
            String defaultVal = getDefaultOverriddenReasonValue();
            oAlert.PC_Alert_Status__c = PC_Constants.ALERT_OVERRIDDEN_STATUS;
            if (!String.isBlank(defaultVal)) {
                oAlert.PC_Reason_for_Override__c = defaultVal;
            }
            PC_Database.upd(oAlert);//CRUD/FLS enforced in the database upd method
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

     /*********************************************************************************
      Method Name    : getDefaultOverriddenReasonValue
      Author         : Alina Balan
      Description    : This method is used for getting the default overridden reason
      Return Type    : String 
      Parameter      : 
     *********************************************************************************/
    private static String getDefaultOverriddenReasonValue() {
        String defaultVal;
        Schema.DescribeFieldResult result = PC_Alert__c.PC_Reason_for_Override__c.getDescribe();
        List<Schema.PicklistEntry> pickVals = result.getPicklistValues();        
        for (Schema.PicklistEntry pv: pickVals) {
            if (pv.isDefaultValue()) {
                defaultVal = pv.getValue();
            }    
        }
        return defaultVal;
    }
    
    /*********************************************************************************
    Method Name    : getReturnUrl
    Author         : Tetiana Danylyshyn
    Description    : This method is used to get the return url
    Return Type    : String
    *********************************************************************************/
    @AuraEnabled 
    public static String getReturnUrl() {
        String key = PC_Alert__c.getSobjectType().getDescribe().getKeyPrefix();
        return '/' + key;
    }
    public class alertWrapper {
        @AuraEnabled public String patientName {get;set;}
        @AuraEnabled public String patientId {get;set;}
        @AuraEnabled public String alertID {get;set;}
        @AuraEnabled public String alertReason {get;set;}
        @AuraEnabled public String alertType {get;set;}
        @AuraEnabled public DateTime alertDate {get;set;}
        @AuraEnabled public String caseId {get;set;}
        @AuraEnabled public String caseNumber {get;set;}
        @AuraEnabled public String caseType {get;set;}
        public alertWrapper(PC_Alert__c a) {
            this.patientName = a.PC_Program__r.Account.Name;
            this.alertID = a.ID; 
            this.alertReason = a.PC_Reason_for_Alert__c;  
            this.alertType = a.PC_Type__c;
            this.alertDate = a.PC_Date_of_Alert__c;
            this.caseId = a.PC_Program__c;
            this.caseType = a.PC_Program__r.RecordType.Name;
            this.patientId = a.PC_Patient_ID__c;
            this.caseNumber = a.PC_Program__r.CaseNumber;
        }
    }	
}