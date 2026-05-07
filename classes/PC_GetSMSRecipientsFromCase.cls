/************************************************************************************************************************************************************************
Class Name      : PC_GetSMSRecipientsFromCase
Description     : This class is used for getting SMS recipients for creating reminder queues in PatientConnect.
Created By      : Kishore Kanteti
Created Date    : Oct 8,2021
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Kishore Kanteti          Oct 8, 2021             Initial Version
*************************************************************************************************************************************************************************/

global with sharing class PC_GetSMSRecipientsFromCase implements PC_ReminderQueue.RecipientFinder{

    global static PC_ReminderQueue.RecipientsResponse getRecipients(PC_ReminderQueue.RecipientsRequest recipientsRequest){
        PC_ReminderQueue.RecipientsResponse recipientsResponse = new PC_ReminderQueue.RecipientsResponse();
        List<PC_ReminderQueue.RecordRecipientDetail> recordRecipientDetails = new List<PC_ReminderQueue.RecordRecipientDetail>();
        try{
            List<String> caseIds = new List<String>();
            for(PC_ReminderQueue.RecordDetail eachDetail : recipientsRequest.recordDetails){
                caseIds.add(eachDetail.recordId);
            }
            PC_eLetter__c eLetter = new PC_eLetter__c();
            //FLS Check
            List<String> eletterFields = new List<String>{'Id','Name'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'),PC_Database.Operation.Reading, eletterFields);

            eLetter = [SELECT Id,Name FROM PC_eLetter__c WHERE Name =: recipientsRequest.setting.PC_TemplateName__c LIMIT 1];
            if(eLetter == null){
                throw new PC_ReminderQueueUtility.PC_ReminderQueueUtilityException(System.Label.PC_NoELettersFoundError);
            }
            PC_SMSSender2Controller.RecipientsInfoResponse recipientsInfoResponse = PC_SMSSender2Controller.getRecipientsInfo(eLetter.Id,caseIds);
            for(PC_SMSSender2Controller.RecipientsByCaseId recipientsByCaseId : recipientsInfoResponse.recipientDetails){
                List<PC_ReminderQueue.RecipientDetail> allRecipientsByCaseId = new List<PC_ReminderQueue.RecipientDetail>();
                for(PC_SMSSender2Controller.SMSRecipient recipient : recipientsByCaseId.recipients){
                    if(String.isNotBlank(recipient.phone)){
                        PC_ReminderQueue.RecipientDetail eachRecipient = new PC_ReminderQueue.RecipientDetail();
                        eachRecipient.Id = recipient.Id;
                        eachRecipient.name = recipient.name;
                        eachRecipient.address = recipient.recipientType == PC_Constants.PC_EXTERNAL_RECIPIENTS ? recipient.phone : '';
                        eachRecipient.channel = PC_ReminderQueue.RecipientChannel.SMS;
                        eachRecipient.type = recipient.recipientType;
                        eachRecipient.associationId = recipient.associationId != null ? recipient.associationId : '';
                        allRecipientsByCaseId.add(eachRecipient);
                    }
                }
                //populate response
                PC_ReminderQueue.RecordRecipientDetail recipientDetail = new PC_ReminderQueue.RecordRecipientDetail();
                recipientDetail.recordId = recipientsByCaseId.caseId;
                recipientDetail.recipientDetails = allRecipientsByCaseId;
                recordRecipientDetails.add(recipientDetail);
            }
            recipientsResponse.recordRecipientDetails = recordRecipientDetails;
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return recipientsResponse;
    }
}