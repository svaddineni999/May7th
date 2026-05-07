/**
 * Handler class for sending SMS Reminders to recipients using eLetter Functionality. Implements PC_Reminder Processor Interface
 */

public with sharing class PC_SendRemindersViaSMS implements PC_Reminder.Processor{
    public static PC_Reminder.Response process(PC_Reminder.Request queueAndSettingsRequest){
        PC_Reminder.Response reminderResponse = new PC_Reminder.Response();
        List<PC_Reminder.ProcessResult> allProcessResults = new List<PC_Reminder.ProcessResult>();
        List<String> eLetterNames = new List<String>();
        Map<String,String> elettersIdByName = new Map<String,String>();
        Map<String,PC_Reminder.ProcessResult> processResultByMessageId = new Map<String,PC_Reminder.ProcessResult>();
        try{
            for(PC_Reminder.ProcessRequest eachProcessRequest : queueAndSettingsRequest.processRequests){
                //Getting all Eletter names to create a map of eLetterId and eLetter names
                eLetterNames.add(eachProcessRequest.setting.PC_TemplateName__c);
            }

            //FLS Check
            List<String> eletterFields = new List<String>{'Id','Name'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'),PC_Database.Operation.Reading, eletterFields);
            List<PC_eLetter__c> eLetters = new List<PC_eLetter__c>([SELECT Id,Name FROM PC_eLetter__c WHERE Name IN: eLetterNames]);
            if(eLetters != null && !eLetters.isEmpty()){
                for(PC_eLetter__c eLetter : eLetters){
                    if(!elettersIdByName.containsKey(eLetter.Name)){
                        elettersIdByName.put(eLetter.Name,eLetter.Id);
                    }
                }

                //Creating Request to be processed by sendMessages() method
                List<PC_SMSSender2Controller.MessageRecipientDetail> messageRecipientDetails = new List<PC_SMSSender2Controller.MessageRecipientDetail>();
                for(PC_Reminder.ProcessRequest eachProcessRequest : queueAndSettingsRequest.processRequests){
                    //Creating Response
                    PC_Reminder.ProcessResult reminderProcessResult = new PC_Reminder.ProcessResult();
                    reminderProcessResult.queueRecord = eachProcessRequest.queueRecord;
                    reminderProcessResult.setting = eachProcessRequest.setting;
                    reminderProcessResult.salesforceRecordId = '';

                    if(elettersIdByName != null && elettersIdByName.get(eachProcessRequest.setting.PC_TemplateName__c) != null){
                        reminderProcessResult.status = PC_Reminder.STATUS.FAILED;
                        reminderProcessResult.statusDetails = 'Something went wrong. Please contact System Administrator for checking Error Logs.';
                        PC_SMSSender2Controller.MessageRecipientDetail messageRecipientDetail = new PC_SMSSender2Controller.MessageRecipientDetail();
                        messageRecipientDetail.recordId = eachProcessRequest.queueRecord.PC_RecordID__c;

                        //Deserializing the recipient string stored in reminder queue
                        PC_ReminderQueue.RecipientDetail queuedRecipient = new PC_ReminderQueue.RecipientDetail();
                        try{
                            queuedRecipient = (PC_ReminderQueue.RecipientDetail) System.JSON.deserialize(eachProcessRequest.queueRecord.PC_Recipient__c, PC_ReminderQueue.RecipientDetail.class);
                        }catch(Exception ex){
                            allProcessResults.add(reminderProcessResult);
                            continue;
                        }
                        //Creating SMS recipient to pass into send messages method
                        PC_SMSSender2Controller.SMSRecipient recipient = new PC_SMSSender2Controller.SMSRecipient();
                        recipient.Id = queuedRecipient.id;
                        recipient.name = queuedRecipient.name;
                        recipient.phone = queuedRecipient.address;
                        recipient.recipientType = queuedRecipient.type;
                        recipient.associationId = queuedRecipient.associationId;

                        messageRecipientDetail.recipient = recipient;
                        messageRecipientDetail.eLetterId = elettersIdByName.get(reminderProcessResult.setting.PC_TemplateName__c);

                        //Creating a map of recipient id + record Id as key and result as value
                        processResultByMessageId.put(messageRecipientDetail.recordId + recipient.Id, reminderProcessResult);

                        messageRecipientDetails.add(messageRecipientDetail);
                    }else{
                        reminderProcessResult.status = PC_Reminder.STATUS.FAILED;
                        String eLetterError = String.format(System.Label.PC_MentionedELetterNotFoundError,
                                new List<Object>{eachProcessRequest.queueRecord.PC_ReminderSetting__c});
                        reminderProcessResult.statusDetails = eLetterError;
                    }
                    allProcessResults.add(reminderProcessResult);
                }

                //Calling Send Messages Method
                PC_SMSSender2Controller.MessageRequest messageRequest = new PC_SMSSender2Controller.MessageRequest(messageRecipientDetails);
                PC_SMSSender2Controller.MessageDetails messageDetails = PC_SMSSender2Controller.sendMessages(messageRequest);

                //Updating status and Populating salesforce record id, content
                if(messageDetails != null && messageDetails.messageRecipientDetails != null && !messageDetails.messageRecipientDetails.isEmpty()){
                    for(PC_SMSSender2Controller.MessageRecipientDetail recipientDetail : messageDetails.messageRecipientDetails){
                        if(recipientDetail.messageRecord != null && recipientDetail.messageRecord.PC_Case__c != null && recipientDetail.messageRecord.PC_Receiver__c != null && processResultByMessageId.get(recipientDetail.messageRecord.PC_Case__c + recipientDetail.messageRecord.PC_Receiver__c) != null){
                            PC_Reminder.ProcessResult resultLog = processResultByMessageId.get(recipientDetail.messageRecord.PC_Case__c + recipientDetail.messageRecord.PC_Receiver__c);
                            resultLog.salesforceRecordId = recipientDetail.messageRecord.Id;
                            resultLog.content = recipientDetail.messageRecord.PC_Content__c;
                            if(String.isNotBlank(recipientDetail.errorMessage) || recipientDetail.messageRecord.PC_Message_Status__c == PC_SMS.PC_SMS_FAILED){
                                resultLog.status = PC_Reminder.STATUS.FAILED;
                                if(String.isBlank(recipientDetail.errorMessage)){
                                    resultLog.statusDetails = recipientDetail.messageRecord.PC_MessageStatusDetails__c;
                                }else{
                                    resultLog.statusDetails = recipientDetail.errorMessage;
                                }
                            }else{
                                resultLog.status = PC_Reminder.STATUS.UNPROCESSED;
                                resultLog.statusDetails = System.Label.PC_MessageCreationSuccessful;
                            }
                        }
                    }
                }
            }else{
                for(PC_Reminder.ProcessRequest eachProcessRequest : queueAndSettingsRequest.processRequests){
                    //Creating Response
                    PC_Reminder.ProcessResult reminderProcessResult = new PC_Reminder.ProcessResult();
                    reminderProcessResult.queueRecord = eachProcessRequest.queueRecord;
                    reminderProcessResult.setting = eachProcessRequest.setting;
                    reminderProcessResult.salesforceRecordId = '';
                    reminderProcessResult.status = PC_Reminder.STATUS.FAILED;
                    reminderProcessResult.statusDetails = System.Label.PC_NoELettersFoundError;
                    allProcessResults.add(reminderProcessResult);
                }
            }
        }catch(Exception ex){
            PC_Utility.publishErrorLog(ex,ex.getMessage());
        }
        reminderResponse.processResults = allProcessResults;
        return reminderResponse;
    }
}