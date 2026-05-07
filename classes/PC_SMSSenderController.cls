/*********************************************************************************
Class Name      : PC_SMSSenderController
Description     : This class is used for retrieving the sms conversation from a case
Created By      : Vasile Paraschiv
Created Date    : 14-June-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Vasile Paraschiv            14-June-16              Initial Version
Shabda Bhujad				Dec 05, 2016			Added FLS check to getCaseMessages,sendMessage methods
Mayuresh Patil              Jul 26, 2017            Updated CRUD/FLS checks
Shishir Bansal              06-Dec-2019             [PC-5792] Avoid hardcoding of string variable
*********************************************************************************/
public with sharing class PC_SMSSenderController {

    private static final String SourceType = 'SMS';
    private static final String Type = 'Outbound';
    public Case currentCase{ set; get; }

    //constructor
    public PC_SMSSenderController(ApexPages.StandardController controller) {
        currentCase = (Case)controller.getRecord();
    }

    /*********************************************************************************
    Method Name    : getMessages
    Description    : Retrieve a list of Message feed items for the current case
    Return Type    : List<Task>
    Parameter      : String caseId   - current case Id  
    *********************************************************************************/
    @AuraEnabled
    public static List<PC_Message__c> getCaseMessages(String caseId) {
        List<PC_Message__c> messages = new List<PC_Message__c>();
        try{
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Content__c'),PC_Constants.getQualifiedAPIName('PC_Message_Date__c'), PC_Constants.getQualifiedAPIName('PC_Sender__c'), PC_Constants.getQualifiedAPIName('PC_Source_Type__c'),PC_Constants.getQualifiedAPIName('PC_Type__c'),PC_Constants.getQualifiedAPIName('PC_Hide_from_Feed__c'),PC_Constants.getQualifiedAPIName('PC_Case__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'),PC_Database.Operation.Reading, fields); 
            messages = [SELECT Id, PC_Content__c, PC_Message_Date__c, PC_Sender__c, PC_Source_Type__c, PC_Type__c FROM PC_Message__c WHERE PC_Hide_from_Feed__c = false AND PC_Case__c = :caseId order by CreatedDate ASC];
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return messages;
    }

    /*********************************************************************************
    Method Name    : sendMessage
    Author         : Vasile Paraschiv
    Description    : Method used to save a SMS task that will be later send by the client's SMS app
    Return Type    : String
    Parameter      : String messageText, String caseId              
    *********************************************************************************/
    @AuraEnabled
    public static Boolean sendMessage(String messageText, String caseId) {
        PC_Message__c msg = new PC_Message__c();
        try{
            List<String> fields = new List<String>{'CaseNumber', PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c')};
            PC_Database.assertAccess('Case',PC_Database.Operation.Reading, fields); 
            fields = new List<String>{'Name'};
            PC_Database.assertAccess('Account',PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
            PC_Database.assertAccess('User',PC_Database.Operation.Reading, fields);
            Case currentCase = [SELECT Id, CaseNumber, Account.Name, PC_Care_Coordinator__r.Name FROM Case WHERE Id = :caseId];
            msg.PC_Case__c = caseId;
            msg.PC_Content__c = messageText;
            msg.PC_Hide_from_Feed__c = false;
            msg.PC_Message_Date__c = datetime.now();
            msg.PC_Sender__c = currentCase.PC_Care_Coordinator__r.Name;
            msg.PC_Receiver__c = currentCase.Account.Name;
            msg.PC_Source_Type__c = SourceType;
            msg.PC_Type__c = Type;
            msg = (PC_Message__c)PC_Database.ins(msg);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return (msg.Id != null) ? true : false;
    }
}