/*********************************************************************************************************
Class Name      : ACLS_SMS_GetSMSStatusBatch
Description     : This Batch is used to perform the handshake with SMS vendor and invoke APIs to get SMS details 
Created By      : Vartika Goyal
Created Date    : Apr 7th 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
Vartika Goyal               Apr 7th 2023          Initial Version
-------------------------------------------------------------------------------------------------------------- */  
public with sharing class ACLS_SMS_GetSMSStatusBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    String query = '';   
    public static final List<PC_Remote_Service_Log__c> listRsl = new List<PC_Remote_Service_Log__c>(); // in days 
    
    public ACLS_SMS_GetSMSStatusBatch(String inputQuery){       
        query = inputQuery;    
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        query = (query =='')? 'Select id, Name, PC_TransactionId__c, PC_SMSELetter__r.PC_eLetter__r.PC_Template_Name__c,PC_ExternalRecipientNumber__c, PC_Type__c, ACLS_SMS_Operation__c, PC_Case__c, PC_Content__c, PC_Message_Status__c from PC_Message__c where (PC_Type__c = \'Outbound\' AND PC_Message_Status__c = \'Sending\') ORDER BY PC_Message_Date__c ASC' : query;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<PC_Message__c> scope){
        String accessToken;
        try {
            if(scope!=null && !scope.isEmpty()){
                accessToken = ACLS_SMSIntegrationHandler.smsGetToken(); 
            }
                
            if(accessToken!=null){
                updateMessageStatus(scope, accessToken);
            }               
        }
        catch(Exception ex) {
            ACLS_Utility.createINTErrorLogs(ex, null, null, null, null, ACLS_Constants.CLASS_BATCH_GETSMSSTATUS, ACLS_Constants.METHOD_BATCH_SENDSMS_EXECUTE, '');
        }
    }

    public void finish(Database.BatchableContext bc){
        AsyncApexJob asyncJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = : bc.getJobId()];    
        Integer batchSize = 40;
        Integer batchFrequency = 15;
        batchSize = ACLS_KeyValMapperUtil.getValue(ACLS_Constants.GETSMSSTATUS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHSIZE) != null ? Integer.ValueOf(ACLS_KeyValMapperUtil.getValue(ACLS_Constants.GETSMSSTATUS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHSIZE)) : batchSize;
        batchFrequency = ACLS_KeyValMapperUtil.getValue(ACLS_Constants.GETSMSSTATUS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHFREQ) != null ? Integer.ValueOf(ACLS_KeyValMapperUtil.getValue(ACLS_Constants.GETSMSSTATUS_BATCHSIZE_KEY, ACLS_Constants.KEYVAL_TYPE_BATCHFREQ)) : batchFrequency;

        if(!Test.isRunningTest()){
            System.scheduleBatch(new ACLS_SMS_GetSMSStatusBatch(''), 'GetSMSStatusBatch' ,batchFrequency, batchSize); 
        }
        if(asyncJob.NumberOfErrors>0) {  
            ACLS_Utility.createINTErrorLogs(null, null, null, 'Batch Status - The batch apex job has processed ' + asyncJob.TotalJobItems + ' jobs with ' + asyncJob.NumberOfErrors + ' failures.', null, ACLS_Constants.CLASS_BATCH_GETSMSSTATUS, ACLS_Constants.METHOD_BATCH_SENDSMS_FINISH, '');
        }
    }

    public void updateMessageStatus(List<PC_Message__c> scope, String accessToken){
        List<PC_Message__c> lstMessageRecord= new List<PC_Message__c>();
        for(PC_Message__c messageRecord: scope){
            try 
            {
                String messageStatus = ACLS_SMSIntegrationHandler.getMessageStatus(messageRecord, accessToken);

                if(messageStatus == ACLS_Constants.SMS_STATUS_COMPLETED){
                    messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_DELIVERED;
                }
                else if(messageStatus == ACLS_Constants.SMS_STATUS_FAILED.toUpperCase()){
                    messageRecord.PC_Message_Status__c = ACLS_Constants.SMS_STATUS_UNDELIVERED;
                }
                else{
                    continue;
                }
                lstMessageRecord.add(messageRecord);
            }
            catch(Exception ex){
                ACLS_Utility.createINTErrorLogs(ex, null, null, null, null, ACLS_Constants.CLASS_BATCH_GETSMSSTATUS, ACLS_Constants.METHOD_BATCH_SENDSMS_EXECUTE, messageRecord.id);
            }
        }
    
        if(!listRsl.isEmpty()){
            PC_Database.ins(listRsl);
        }
        if(!lstMessageRecord.isEmpty()){
            PC_Database.upd(lstMessageRecord);
        }
    }
}