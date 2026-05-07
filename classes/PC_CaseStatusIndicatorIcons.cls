/*********************************************************************************
Class Name      : PC_CaseStatusIndicatorIcons
Description     : Displays the Status Icons of a Case
Created By      : Cameron Reid
Created Date    : 13-June-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Cameron Reid              	13-June-16              Initial Version
Ajinkya Deshmukh			08-June-17				FLS Check Added
Mayuresh Patil             25-July-17              FLS/CRUD check for Account
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_CaseStatusIndicatorIcons {

    ApexPages.StandardController stdController;
    
    //List of Status
    public List<iconWrapper> lstStatusIcons {public get; public set;}
    
    //Case Object
    public Case objCase {get;set;}

    public PC_CaseStatusIndicatorIcons(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        
        getCase();
        getStatusIcons();
    }
    
    /*********************************************************************************
    Method Name    : getCase
    Description    : retrieve Case fields
    Return Type    : void       
    *********************************************************************************/
    private void getCase() {
        try {
            
            String rID = stdController.getID();
            
            //For Debugging Purposes on Preview
            if(rID == null || rID == '')
            {
                 return;
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
                ID, Account.Name, 
                RecordType.Name, 
                RecordType.DeveloperName, 
                PC_Status_Indicator_1__c, 
                PC_Status_Indicator_2__c, 
                PC_Status_Indicator_3__c, 
                PC_Status_Indicator_4__c, 
                PC_Status_Indicator_5__c  
              FROM 
                  Case 
              WHERE 
                  ID =: rID 
              LIMIT 1];
            
            if(lstCases.size() > 0) 
            {
                objCase = lstCases[0];
            }
        }
        catch (exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
    
    /*********************************************************************************
    Method Name    : GetResourceURL
    Description    : retrieve the path to the Icon
    Return Type    : void     
    Parameter      : 1. Indicator : String representation of the Indicator
                     2. Status : the status of the Indicator
    *********************************************************************************/
    private static String GetResourceURL(String Indicator, String status){

        string path = '/ICONS/' + Indicator + '_' + status + PC_Constants.JPG_FORMAT;
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
    private iconWrapper createIconWrapper (String statusIcon, String statusValue, String name) 
    {
        iconWrapper iw = null;
        
        if(string.isBlank(statusValue) || statusValue == PC_Constants.STATUS_INDICATOR_COMPLETE || statusValue == PC_Constants.STATUS_INDICATOR_NOT_APPLICABLE) 
        { 
            iw = new iconWrapper( 
                getResourceUrl(statusIcon, 'Grey') , 
                name, 
                PC_Constants.STATUS_INDICATOR_COMPLETE); 
        }
        else 
        { 
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
    *********************************************************************************/
    private void getStatusIcons() {
        lstStatusIcons = new List<iconWrapper>();
        try {
            if(objCase != null)
            {
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
        return;
    }
    
    /*********************************************************************************
    Class Name    : iconWrapper
    Author        : Cameron Reid
    Description   : Wrapper class Icon Details
    *********************************************************************************/
    public inherited sharing class iconWrapper {
        public String path {get;set;}
        public String title {get;set;}
        public String status {get;set;}
        
        public iconWrapper (String sUrl, String sTitle, String sStatus) {
            this.path = sUrl;
            this.title = sTitle;
            this.status = sStatus;        
        }
    }
}