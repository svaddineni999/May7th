/*********************************************************************************
Class Name      : PC_MessageManagementController
Description     : This class is used for retrieving the sms conversation from a case
Created By      : Vasile Paraschiv
Created Date    : 14-June-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Vasile Paraschiv            14-June-16              Initial Version
Shabda Bhujad				Dec 05, 2016			Added FLS check to getCaseMessages,sendMessage,getAccountMessages,getUserMessages methods
Ajinkya Deshmukh			June 12, 2017			FLS Check Added
Mayuresh Patil              July 26, 2017           Updated CRUD/FLS Checks
Mayuresh Patil              Nov 1, 2017             Removing updating unread messages when reading messages
Vijay Kashikar              21-Jan-21               [PC-7102] Added FLS Checks
*********************************************************************************/
public with sharing class PC_MessageManagementController {

    /*********************************************************************************
      Method Name    : getMessages
      Description    : Retrieve a list of Message feed items for the current case
      Return Type    : List<Task>
      Parameter      : String caseId   - current case Id  
     *********************************************************************************/
    @AuraEnabled
    public static List<PC_Message__c> getCaseMessages(String caseId) {
        List<PC_Message__c> messages = new List<PC_Message__c> ();
        try {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Message_Read__c'), PC_Constants.getQualifiedAPIName('PC_Content__c'),PC_Constants.getQualifiedAPIName('PC_Message_Date__c'), PC_Constants.getQualifiedAPIName('PC_Sender__c'), PC_Constants.getQualifiedAPIName('PC_Source_Type__c'), PC_Constants.getQualifiedAPIName('PC_Type__c'),
                                                   PC_Constants.getQualifiedAPIName('PC_Hide_from_Feed__c'), PC_Constants.getQualifiedAPIName('PC_Case__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'),PC_Database.Operation.Reading, fields); 
            messages = [SELECT Id, PC_Message_Read__c, PC_Content__c, PC_Message_Date__c, PC_Sender__c, PC_Source_Type__c, PC_Type__c FROM PC_Message__c WHERE PC_Hide_from_Feed__c = false AND PC_Case__c = :caseId order by CreatedDate ASC];
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

        try {
            List<String> fields = new List<String>{'CaseNumber',PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading, fields);
            Case currentCase = [SELECT Id, CaseNumber, Account.Name, PC_Care_Coordinator__r.Name FROM Case WHERE Id = :caseId];

            msg.PC_Case__c = caseId;
            msg.PC_Content__c = messageText;
            msg.PC_Hide_from_Feed__c = false;
            msg.PC_Message_Date__c = datetime.now();
            msg.PC_Sender__c = UserInfo.getName();
            msg.PC_Receiver__c = currentCase.Account.Name;
            msg.PC_Source_Type__c = PC_Constants.PC_SMS;
            msg.PC_Type__c = PC_Constants.OUTBOUND;
            msg.PC_Message_Read__c = true;
            msg = (PC_Message__c) PC_Database.ins(msg);//CRUD/FLS is enforced in the database ins method
            
            return(msg.Id != null) ? true : false;
            
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return false;
        }    
    }

    /*********************************************************************************
      Method Name    : getAccountMessages
      Description    : Retrieve a list of Message feed items for the current user account
      Return Type    : List<Task>
      Parameter      : String caseId   - current case Id  
     *********************************************************************************/
    @AuraEnabled
    public static List<PC_Message__c> getAccountMessages(String caseId) {
        List<PC_Message__c> messages = new List<PC_Message__c> ();
        try {
            String userName = UserInfo.getName();
            List<String> casefields = new List<String>{'AccountId'};
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, casefields);
            Case currentCase = [select AccountId from Case where Id = :caseId];
            
            List<String> fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            Account account = [SELECT Name from Account WHERE Id = :currentCase.AccountId];
            
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Case__c'),PC_Constants.getQualifiedAPIName('PC_Message_Read__c'), PC_Constants.getQualifiedAPIName('PC_Content__c'),PC_Constants.getQualifiedAPIName('PC_Receiver__c'),PC_Constants.getQualifiedAPIName('PC_Message_Date__c'), PC_Constants.getQualifiedAPIName('PC_Sender__c'), PC_Constants.getQualifiedAPIName('PC_Source_Type__c'), PC_Constants.getQualifiedAPIName('PC_Type__c'),
                                      PC_Constants.getQualifiedAPIName('PC_Hide_from_Feed__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'),PC_Database.Operation.Reading, fields);

            fields = new List<String>{'AccountId'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            messages = [SELECT Id, PC_Case__c, PC_Message_Read__c, PC_Content__c, PC_Receiver__c, PC_Message_Date__c, PC_Sender__c, PC_Source_Type__c, PC_Type__c FROM PC_Message__c
                        WHERE PC_Hide_from_Feed__c = false
                        and PC_Case__r.AccountId = :account.Id
                        AND(PC_Receiver__c = :userName OR PC_Sender__c = :userName)
                        order by CreatedDate ASC];
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return messages;
    }

    /*********************************************************************************
      Method Name    : getUserMessages
      Description    : Retrieve a list of Message feed items for the current user
      Return Type    : List<Task>
      Parameter      : None 
     *********************************************************************************/
    @AuraEnabled
    public static List<PC_Message__c> getUserMessages() {
        List<PC_Message__c> messages = new List<PC_Message__c> ();
        try {
            List<Datetime> dates = new List<Datetime> ();
            List<String> fields = new List<String>{'CreatedDate', PC_Constants.getQualifiedAPIName('PC_Case__c'), PC_Constants.getQualifiedAPIName('PC_Hide_from_Feed__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'),PC_Database.Operation.Reading, fields);

            fields = new List<String>{'AccountId'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            List<AggregateResult> groupedResults = [SELECT max(CreatedDate) CreatedDate, PC_Case__r.AccountId AccountId FROM PC_Message__c
                                                    WHERE PC_Hide_from_Feed__c = false
                                                    GROUP BY PC_Case__r.AccountId
                                                    LIMIT 10];
            Set<String> accIds = new Set<String> ();
            for (AggregateResult rs : groupedResults) {
                accIds.add(String.valueOf(rs.get('AccountId')));
                dates.add((Datetime) rs.get('CreatedDate'));
            }
            String userName = UserInfo.getName();
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Case__c'),PC_Constants.getQualifiedAPIName('PC_Message_Read__c'), PC_Constants.getQualifiedAPIName('PC_Content__c'),PC_Constants.getQualifiedAPIName('PC_Receiver__c'),PC_Constants.getQualifiedAPIName('PC_Message_Date__c'), PC_Constants.getQualifiedAPIName('PC_Sender__c'), PC_Constants.getQualifiedAPIName('PC_Source_Type__c'), PC_Constants.getQualifiedAPIName('PC_Type__c'),
                                      PC_Constants.getQualifiedAPIName('PC_Hide_from_Feed__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'),PC_Database.Operation.Reading, fields);

            //CRUD/FLS for case already checked above in the method
            messages = [SELECT Id, PC_Case__c, PC_Message_Read__c, PC_Content__c, PC_Receiver__c, PC_Message_Date__c, PC_Sender__c, PC_Source_Type__c, PC_Type__c FROM PC_Message__c
                        WHERE PC_Hide_from_Feed__c = false
                        AND PC_Case__r.AccountId IN :accIds
                        AND CreatedDate in :dates
                        AND(PC_Receiver__c = :userName OR PC_Sender__c = :userName)
                        ORDER BY CreatedDate DESC LIMIT 10];


        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return messages;
    }

}