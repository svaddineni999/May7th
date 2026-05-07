/*********************************************************************************
Class Name      : PC_CaseStatusIndicatorIconController
Description     : Displays the Status Icons of a Case
Created By      : Cameron Reid
Created Date    : 13-June-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Cameron Reid               13-June-16            Initial Version
Ajinkya Deshmukh		   8-June-17			 FLS Check Added
Mayuresh Patil             25-July-17            FLS/CRUD check for Account
Haritha Reddy             11-Dec-2019            [PC-5791] Added Error handling for getStatusIndicatorIcons method
Haritha Reddy             21-Jan-2021            [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Hitha Avalakki            26-Feb-2021            [PC-7442] Replaced the use of RecordTypeId with 'Type' field of Case object to decide if its a program case record
*********************************************************************************/
public with sharing class PC_CaseStatusIndicatorIconController {
    
    /*********************************************************************************
    Method Name    : getStatusIndicatorIcons
    Description    : retrieve the list of Status Icons
    Return Type    : List<iconWrapper>      
    Parameter      : 1. CaseID The Case to query for
    *********************************************************************************/
    @AuraEnabled
    public static List<iconWrapper> getStatusIndicatorIcons(String caseId) {
        List<iconWrapper> lstStatusIcons = new List<iconWrapper>();
        try {
            if (caseId != null && caseId != '') {
                Case objCase = getCase(caseId);
                lstStatusIcons = getStatusIcons(objCase);
            } else {
                return null;
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return lstStatusIcons;
    }
    
    /*********************************************************************************
    Method Name    : getCase
    Description    : retrieve Case fields
    Return Type    : void       
    Parameter      : 1. CaseID The Case to query for
    *********************************************************************************/
    @AuraEnabled
    public static Case getCase(String caseID) {
        Case objCase = null;
        
        try {            
            String rID = caseID; 

            //Check if ID is not null
            if(rID == null || rID == '') {
                 return null;
            }
            
            /*
            * FLS Check for Case
            */
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Status_Indicator_1__c'), PC_Constants.getQualifiedAPIName('PC_Status_Indicator_2__c'),
                                                    PC_Constants.getQualifiedAPIName('PC_Status_Indicator_3__c'), PC_Constants.getQualifiedAPIName('PC_Status_Indicator_4__c'),
                                                    PC_Constants.getQualifiedAPIName('PC_Status_Indicator_5__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            /*
            * FLS/CRUD Check for Account
            */
            List<String> accountFields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields);

            List<Case> lstCases = [SELECT 
                                    Id, Account.Name, 
                                    RecordType.Name, 
                                    RecordType.DeveloperName,
                                    Type,
                                    PC_Status_Indicator_1__c, 
                                    PC_Status_Indicator_2__c, 
                                    PC_Status_Indicator_3__c, 
                                    PC_Status_Indicator_4__c, 
                                    PC_Status_Indicator_5__c  
                                  FROM Case 
                                  WHERE Id =: rID 
                                  LIMIT 1];

            if(lstCases.size() > 0)  {
                objCase = lstCases[0];
            }
        }
        catch (exception e) {
            PC_Utility.createExceptionLog(e);
        }
        
        return objCase;
    }
    
    /*********************************************************************************
    Method Name    : GetResourceURL
    Description    : retrieve the path to the Icon
    Return Type    : void       
    Parameter      : 1. Indicator : Name of the Indicator
                     2. Status : The status of the indicator
    *********************************************************************************/
    private static String GetResourceURL(String Indicator, String statusValue){
		/*False Positive result from ForceReviewer*/
        string path = '/PC_Resources/Images/StatusIndicatorIcons/' + Indicator + '_' + statusValue + PC_Constants.JPG_FORMAT;
        return path;
    }
    
    /*********************************************************************************
    Method Name    : createIconWrapper
    Description    : create the IconWrapper object
    Return Type    : void 
    Parameter      : 1. statusIcon : String representation of the Icon
                     2. StatusValue : The statusValue of the indicator      
                     3. Name: The Name of the icon (for accessability standards used as alt name)
    *********************************************************************************/
    private static iconWrapper createIconWrapper (String statusIcon, String statusValue, String name) 
    {
        iconWrapper iw = null;
        if(string.isBlank(statusValue) || statusValue == PC_Constants.STATUS_INDICATOR_COMPLETE || statusValue == PC_Constants.STATUS_INDICATOR_NOT_APPLICABLE) { 
            iw = new iconWrapper( 
                getResourceUrl(statusIcon, 'Grey') , 
                name, 
                PC_Constants.STATUS_INDICATOR_COMPLETE); 
        }
        else { 
            iw = new iconWrapper( 
                getResourceUrl(statusIcon,'Orange'), 
                name, 
                PC_Constants.STATUS_INDICATOR_INCOMPLETE); 
        }
        return iw;
    }
    
    /*********************************************************************************
    Method Name    : getStatusIcons
    Description    : retrieve Status Icons
    Return Type    : void       
    Parameter      : 1. objCase : Case the status are coming from
    *********************************************************************************/
    private static List<iconWrapper> getStatusIcons(Case objCase) {
        List<iconWrapper> lstStatusIcons = new List<iconWrapper>();
        try {
            if(objCase != null) {
                //Status Indicator 1
                lstStatusIcons.add ( createIconWrapper (PC_Constants.STATUS_INDICATOR_TYPE_CONSENT, objCase.PC_Status_Indicator_1__c, Label.PC_Case_Status_Indicator_1));

                //Status Indicator 2
                lstStatusIcons.add ( createIconWrapper (PC_Constants.STATUS_INDICATOR_TYPE_COVERAGE, objCase.PC_Status_Indicator_2__c, Label.PC_Case_Status_Indicator_2));

                //Status Indicator 3
                lstStatusIcons.add ( createIconWrapper (PC_Constants.STATUS_INDICATOR_TYPE_ENGAGEMENT, objCase.PC_Status_Indicator_3__c, Label.PC_Case_Status_Indicator_3));

                //Status Indicator 4
                lstStatusIcons.add ( createIconWrapper (PC_Constants.STATUS_INDICATOR_TYPE_ADHERENCE, objCase.PC_Status_Indicator_4__c, Label.PC_Case_Status_Indicator_4));

                //Status Indicator 5
                lstStatusIcons.add ( createIconWrapper (PC_Constants.STATUS_INDICATOR_TYPE_LABS, objCase.PC_Status_Indicator_5__c, Label.PC_Case_Status_Indicator_5));
            }
        }
        catch (exception e) {
            PC_Utility.createExceptionLog(e);
        }       
        return lstStatusIcons;
    }
    
    /*********************************************************************************
    Class Name    : iconWrapper
    Author        : Cameron Reid
    Description   : Wrapper class Icon Details
    *********************************************************************************/
    public inherited sharing class iconWrapper {
        @AuraEnabled public String path {get;set;}
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String status {get;set;}
        
        public iconWrapper (String sUrl, String sTitle, String sStatus) {
            this.path = sUrl;
            this.title = sTitle;
            this.status = sStatus;        
        }
    }
}