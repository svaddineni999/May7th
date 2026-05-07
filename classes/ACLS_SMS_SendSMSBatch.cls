/*********************************************************************************************************
Class Name      : ACLS_SMS_SendSMSBatch
Description     : This Batch is used to perform the handshake with SMS vendor and invoke APIs to send SMSs 
Created By      : Vartika Goyal
Created Date    : Mar 26th 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
Vartika Goyal               Mar 26th 2023          Initial Version
-------------------------------------------------------------------------------------------------------------- */  
public with sharing class ACLS_SMS_SendSMSBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    String query = '';    
    public static final List<PC_Remote_Service_Log__c> listRsl = new List<PC_Remote_Service_Log__c>(); // in days
    Map<String, String> mapTempNameAndTempId = new Map<String, String>(); 
    public ACLS_SMS_SendSMSBatch(){ 
        System.debug('query VG1');   
        for(EmailTemplate et: [select id, name, DeveloperName, Body from EmailTemplate LIMIT 100]){    
            mapTempNameAndTempId.put(et.DeveloperName, et.id);    
        }    
    }
    
    public ACLS_SMS_SendSMSBatch(String inputQuery){    
        System.debug('query VG2');
        for(EmailTemplate et: [select id, name, DeveloperName, Body from EmailTemplate LIMIT 100]){    
            mapTempNameAndTempId.put(et.DeveloperName, et.id);
            System.debug(mapTempNameAndTempId +'Template Name');
        }    
        query = inputQuery;    
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        query = (query =='')? 'Select id, Name, ACLS_Campaign_Name__c, PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c,PC_ExternalRecipientNumber__c, PC_Type__c, ACLS_SMS_Operation__c, PC_Case__c, PC_Case__r.PC_Engagement_Program__c, PC_Content__c, ACLS_Interaction__c, ACLS_Interaction__r.PC_End__c, ACLS_Program_Service_Permission__c, ACLS_Interaction__r.PC_Start__c, PC_Case__r.PC_Engagement_Program__r.ACLS_TimeZone__c, PC_MessageStatusDetails__c from PC_Message__c where (PC_Type__c = \'Outbound\' AND PC_Message_Status__c = \'Queued\') ORDER BY PC_Message_Date__c ASC' : query;
        System.debug('query VG'+query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PC_Message__c> scope){

        Map<Id, String> mapMessageIdAndTemplate = new Map<Id, String>();
        List<PC_Message__c> lstMessageRecord= new List<PC_Message__c>();
        Messaging.SingleEmailMessage singleEmailMessage;
        List<Task> lstTaskException =  new List<Task>();  
        String accessToken; 

        try {
            if(scope!=null && !scope.isEmpty()){
                accessToken = ACLS_SMSIntegrationHandler.smsGetToken(); 
                System.debug('access Token'+accessToken);
            }
                
            if(accessToken!=null && scope!=null && !scope.isEmpty()){              
                for(PC_Message__c messageRecord: scope){
                    System.debug('query VG'+messageRecord);
                    System.debug('query VG'+messageRecord.ACLS_Interaction__c);

                    try {
                        
                         System.debug('Template Name'+ mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c));
                        System.debug('Interaction'+messageRecord.ACLS_Interaction__c);
                        
                        if(mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c) != null && (messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c == 'ACLS_Opt_Out_Message' || messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c == 'ACLS_Help_Message')){
                            // if(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c == 'ACLS_Opt_Out_Message' || messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c == 'ACLS_Help_Message'){
                                singleEmailMessage = Messaging.renderStoredEmailTemplate(mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c), null ,messageRecord.PC_Case__r.PC_Engagement_Program__c);                        
                            }
                       
                       
                            else if(mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c) != null && messageRecord.ACLS_Interaction__c != null){
                                System.debug('first'+messageRecord.ACLS_Interaction__r.PC_Start__c);
                                DateTime StartDateTime = messageRecord.ACLS_Interaction__r.PC_Start__c;
                                String StartTime = StartDateTime.format('HH:mm');
                                String EndTime = messageRecord.ACLS_Interaction__r.PC_End__c.format('HH:mm');
                                String StartDate = StartDateTime.month()+'/'+StartDateTime.day()+'/'+StartDateTime.year();
                                String TimeZone = messageRecord.PC_Case__r.PC_Engagement_Program__r.ACLS_TimeZone__c;

                                singleEmailMessage = Messaging.renderStoredEmailTemplate(mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c), null ,messageRecord.PC_Case__c);                        
                                String injectionTextBody = singleEmailMessage.getPlainTextBody().replace('scheduledDate', StartDate+' from '+StartTime+' to '+EndTime+' '+TimeZone);
                                singleEmailMessage.setPlainTextBody(injectionTextBody);
                            }
                            else if(mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c) != null){
                                singleEmailMessage = Messaging.renderStoredEmailTemplate(mapTempNameAndTempId.get(messageRecord.PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c), null ,messageRecord.PC_Case__c);                        
                            }
                        
                        // if (singleEmailMessage != null && messageRecord.PC_ExternalRecipientNumber__c != null) {
                            if(singleEmailMessage != null && messageRecord.PC_ExternalRecipientNumber__c != null && messageRecord.ACLS_SMS_Operation__c == ACLS_Constants.SMS_OPERATION_OPTIN){
                                System.debug('singleEmailMessage.getHtmlBody()'+singleEmailMessage.getHtmlBody()+'kj'+singleEmailMessage.getPlainTextBody());
                                messageRecord.PC_Content__c = singleEmailMessage.getHtmlBody();
                                messageRecord = processOptInSMS(messageRecord, accessToken);
                            }
                            else if(singleEmailMessage != null && messageRecord.PC_ExternalRecipientNumber__c != null && messageRecord.ACLS_SMS_Operation__c == ACLS_Constants.SMS_OPERATION_OPTOUT){
                                messageRecord.PC_Content__c = singleEmailMessage.getPlainTextBody();
                                messageRecord = processOptOutSMS(messageRecord, accessToken);                                
                            }
                            else if(singleEmailMessage != null && messageRecord.PC_ExternalRecipientNumber__c != null && messageRecord.ACLS_SMS_Operation__c == ACLS_Constants.SMS_OPERATION_SEND_SMS){
                                messageRecord.PC_Content__c = singleEmailMessage.getPlainTextBody();
                                messageRecord = processSendSMS(messageRecord, accessToken);
                            }
                            else if(singleEmailMessage != null && messageRecord.PC_ExternalRecipientNumber__c != null){    
                                messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_UNDELIVERED;
                                messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_NO_OPERATION_FOUND;                        
                            }                        
                        // }
                        else{    
                            messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_UNDELIVERED;
                            messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_FAILED_TO_GET_CONTENT;                    
                        }
                        lstMessageRecord.add(messageRecord);
                    }
                    catch(Exception ex){
                        System.debug('lstTaskException1');
                        ACLS_Utility.createINTErrorLogs(ex, null, null, null, null, ACLS_Constants.CLASS_BATCH_SENDSMS, ACLS_Constants.METHOD_BATCH_SENDSMS_EXECUTE, '');
                        Id relatedTo = messageRecord.ACLS_Interaction__c != null ? messageRecord.ACLS_Interaction__c: (messageRecord.ACLS_SMS_Operation__c != ACLS_Constants.SMS_OPERATION_SEND_SMS && messageRecord.ACLS_Program_Service_Permission__c != null) ? messageRecord.ACLS_Program_Service_Permission__c : messageRecord.PC_Case__c;
                        Task taskRecord = ACLS_Utility.createTask(ACLS_Constants.OUTBOUND_SMS_EXCEPTION, ACLS_Constants.INTEGRATION, ACLS_Constants.SMS, DATE.today(), ACLS_Constants.ACLS_ADMIN_QUEUE, relatedTo, ACLS_Constants.SMS_EXCEPTION_COMMENT);
                        lstTaskException.add(taskRecord);
                        lstMessageRecord.add(messageRecord);
                    }
                }
                if(!lstTaskException.isEmpty()){
                    System.debug('lstTaskException'+lstTaskException);
                    PC_Database.ins(lstTaskException);
                }
                if(!listRsl.isEmpty()){
                    System.debug('listRsl'+listRsl);
                    PC_Database.ins(listRsl);
                }
                if(!lstMessageRecord.isEmpty()){
                    System.debug('lstMessageRecord'+lstMessageRecord);
                    PC_Database.upd(lstMessageRecord);
                }
            }                
                        
        }
        catch(Exception ex) {
            ACLS_Utility.createINTErrorLogs(ex, null, null, null, null, ACLS_Constants.CLASS_BATCH_SENDSMS, ACLS_Constants.METHOD_BATCH_SENDSMS_EXECUTE, '');
            System.debug('in exception '+ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc){
        
            AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = : bc.getJobId()]; 
            Integer batchSize = 40;
            Integer batchFrequency = 15;
            batchSize = ACLS_KeyValMapperUtil.getValue(ACLS_Constants.SENDSMS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHSIZE) != null ? Integer.ValueOf(ACLS_KeyValMapperUtil.getValue(ACLS_Constants.SENDSMS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHSIZE)) : batchSize;
            batchFrequency = ACLS_KeyValMapperUtil.getValue(ACLS_Constants.SENDSMS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHFREQ) != null ? Integer.ValueOf(ACLS_KeyValMapperUtil.getValue(ACLS_Constants.SENDSMS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHFREQ)) : batchFrequency;

            System.debug('here batch size'+Integer.ValueOf(batchSize));
        	if(!Test.isRunningTest()) {
            	System.scheduleBatch(new ACLS_SMS_SendSMSBatch(), 'SendSMSBatch' ,batchFrequency, batchSize); 
        	}
            if(asyncJob.NumberOfErrors>0) {  
                ACLS_Utility.createINTErrorLogs(null, null, null, 'Batch Status - The batch apex job has processed ' + asyncJob.TotalJobItems + ' jobs with ' + asyncJob.NumberOfErrors + ' failures.', null, ACLS_Constants.CLASS_BATCH_SENDSMS, ACLS_Constants.METHOD_BATCH_SENDSMS_FINISH, '');
            }        
    }

    
    public static PC_Message__c processOptInSMS(PC_Message__c messageRecord, String accessToken){    
        Boolean isOptedIn = ACLS_SMSIntegrationHandler.smsUpdateOptInOptOut(messageRecord.PC_ExternalRecipientNumber__c,ACLS_Constants.SMS_STATE_OPTIN, accessToken);
        if(isOptedIn){
            messageRecord.PC_TransactionId__c = ACLS_SMSIntegrationHandler.sendMessage(messageRecord, accessToken);
            if(messageRecord.PC_TransactionId__c != null){
                messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_SENDING;
            }
            else{
                messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_FAILED;
                messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_UNABLE_TO_SEND_SMS;
                throw new PC_SMS.SMSException(ACLS_Constants.SMS_UNABLE_TO_SEND_SMS);
            }
        }  
        else{
            messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_FAILED;
            messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_UNABLE_TO_OPTIN;
            throw new PC_SMS.SMSException(ACLS_Constants.SMS_UNABLE_TO_OPTIN);
        }
        return messageRecord;             
    }
      
    public static PC_Message__c processOptOutSMS(PC_Message__c messageRecord, String accessToken){    
        Boolean isOptedOut = ACLS_SMSIntegrationHandler.sMSUpdateOptInOptOut(messageRecord.PC_ExternalRecipientNumber__c, ACLS_Constants.SMS_STATE_OPTOUT ,accessToken);   
        if(isOptedOut){
            messageRecord.PC_TransactionId__c = ACLS_SMSIntegrationHandler.sendMessage(messageRecord, accessToken);
            if(messageRecord.PC_TransactionId__c != null){
                messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_SENDING;
            }
            else{
                messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_FAILED;
                messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_UNABLE_TO_SEND_SMS;
                throw new PC_SMS.SMSException(ACLS_Constants.SMS_UNABLE_TO_SEND_SMS);

            }            
        }  
        else{
            messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_FAILED;
            messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_UNABLE_TO_OPTIN;
            throw new PC_SMS.SMSException(ACLS_Constants.SMS_UNABLE_TO_OPTIN);

        }
        return messageRecord;
    }       
        
    public static PC_Message__c processSendSMS(PC_Message__c messageRecord, String accessToken){    
        messageRecord.PC_TransactionId__c  = ACLS_SMSIntegrationHandler.sendMessage(messageRecord, accessToken); 
        if(messageRecord.PC_TransactionId__c != null){
            messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_SENDING;
        }
        else{
            messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_FAILED;
            messageRecord.PC_MessageStatusDetails__c = ACLS_Constants.SMS_UNABLE_TO_SEND_SMS;
            throw new PC_SMS.SMSException(ACLS_Constants.SMS_UNABLE_TO_SEND_SMS);            
        }    
        return messageRecord;    
    }
}