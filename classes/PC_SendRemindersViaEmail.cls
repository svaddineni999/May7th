/**
 * Handler class for sending Email Reminders to recipients. Implements PC_Reminder Processor Interface
 */
global with sharing class PC_SendRemindersViaEmail implements PC_Reminder.Processor{
    global static PC_Reminder.Response process(PC_Reminder.Request queueAndSettingsRequest){
        PC_Reminder.Response reminderResponse = new PC_Reminder.Response();
        List<PC_Reminder.ProcessResult> allProcessResults = new List<PC_Reminder.ProcessResult>();
        List<Messaging.SingleEmailMessage> allMessages = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress[] orgWideAddresses = [select Id from OrgWideEmailAddress where Address = :PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL, '')];
        List<EmailTemplate> eTemplates = new List<EmailTemplate>();
        Map<String,EmailTemplate> eTemplatesMap = new Map<String,EmailTemplate>();
        eTemplates = [Select Id,DeveloperName from EmailTemplate];
        if(eTemplates.size()>0){
            for(EmailTemplate eTemplate : eTemplates){
                eTemplatesMap.put(eTemplate.DeveloperName,eTemplate);
            }
        }
        try{
            for(PC_Reminder.ProcessRequest eachProcessRequest : queueAndSettingsRequest.processRequests){
                //Creating Response
                PC_Reminder.ProcessResult reminderProcessResult = new PC_Reminder.ProcessResult();
                reminderProcessResult.queueRecord = eachProcessRequest.queueRecord;
                reminderProcessResult.setting = eachProcessRequest.setting;
                reminderProcessResult.status = PC_Reminder.STATUS.FAILED;
                reminderProcessResult.statusDetails = ' ';
                reminderProcessResult.externalId = eachProcessRequest.queueRecord.Id + '-' + eachProcessRequest.queueRecord.PC_ReminderChannel__c + '-' + eachProcessRequest.queueRecord.PC_ParentReferenceRecordID__c;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                try{
                    //Creating Mail

                    message.setReplyTo('no-reply@company.com');
                    if (orgWideAddresses.size() > 0) {
                        message.setOrgWideEmailAddressId(orgWideAddresses.get(0).Id);
                    }
                    if(eTemplatesMap.containsKey(eachProcessRequest.setting.PC_TemplateName__c)){
                        message = Messaging.renderStoredEmailTemplate(eTemplatesMap.get(eachProcessRequest.setting.PC_TemplateName__c).Id,null,eachProcessRequest.queueRecord.PC_RecordID__c);
                    }else{
                        reminderProcessResult.statusDetails = 'No email template found.';
                    }
                    message.toAddresses = new String[]{
                            eachProcessRequest.queueRecord.PC_Recipient__c
                    };
                    message.setSaveAsActivity(false);
                    reminderProcessResult.content = message.getSubject() + '\n';
                    reminderProcessResult.content = message.getHtmlBody() + '\n';
                    reminderProcessResult.content = message.getPlainTextBody() + '\n';
                }catch(Exception ex){
                    reminderProcessResult.status = PC_Reminder.STATUS.FAILED;
                    if(String.isBlank(reminderProcessResult.statusDetails)){
                        reminderProcessResult.statusDetails = ex.getMessage();
                    }
                }
                allMessages.add(message);
                allProcessResults.add(reminderProcessResult);
            }
            Messaging.SendEmailResult[] messageEmailResults = Messaging.sendEmail(allMessages);
            for(Integer i=0; i < messageEmailResults.size(); i++){
                if(messageEmailResults[i].isSuccess()) {
                    allProcessResults[i].status = PC_Reminder.STATUS.SUCCESS;
                }else{
                    if(messageEmailResults[i] != null){
                        if(messageEmailResults[i].errors[0] != null){
                            if(String.isNotBlank(messageEmailResults[i].errors[0].message)){
                                allProcessResults[i].statusDetails = messageEmailResults[i].errors[0].message;
                            }else{
                                allProcessResults[i].statusDetails = 'Something went wrong in PC_SendRemindersViaEmail class for Queue ID: '+allProcessResults[i].queueRecord.Id;
                            }
                        }else{
                            allProcessResults[i].statusDetails = 'Something went wrong in PC_SendRemindersViaEmail class for Queue ID: '+allProcessResults[i].queueRecord.Id;
                        }
                    }else{
                        allProcessResults[i].statusDetails = 'Something went wrong in PC_SendRemindersViaEmail class for Queue ID: '+allProcessResults[i].queueRecord.Id;
                    }
                }
            }
        }catch(Exception ex){
            PC_Utility.publishErrorLog(ex,ex.getMessage());
        }
        reminderResponse.processResults = allProcessResults;
        return reminderResponse;
    }
}