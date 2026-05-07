/**********************************************************************************************************************************************
Class Name      : PC_InboundSmsTaskCreationHandler
Description     : Trigger on Message object that initiates task creation after an Inbound message record gets created.
Created By      : Chetna Mohapatra
Created Date    : Oct 13, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra          Oct 13, 2021           Initial Version
Satheesh Kumar            Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
************************************************************************************************************************************************/
public inherited sharing class PC_InboundSmsTaskCreationHandler extends PC_TriggerHandler {
    override public void afterInsert() {
        try {
            initiateTaskCreationForInboundSms((List<PC_Message__c>) newList);
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
    /************************************************************************************
   Method Name    : assignPreviousStatus
   Author         : Chetna Mohapatra
   Description    : This method is to initiate the task creation process for Inbound sms
   Return Type    : void
   Parameter      : List of new message records- messages
   ***************************************************************************************/
    private void initiateTaskCreationForInboundSms(List<PC_Message__c> messages) {
        Set<Id> senderAccountIdSet = new Set<Id>();
        Set<Id> caseIdSet= new Set<Id>();
        for (PC_Message__c msg : messages) {
            if (msg.PC_Type__c == PC_Constants.INBOUND && msg.PC_Case__c != null && msg.PC_SenderAccount__c != null) {
                senderAccountIdSet.add(msg.PC_SenderAccount__c);
                caseIdSet.add(msg.PC_Case__c);
            }
        }
        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*// FLS Check
        List<String> accountFields = new List<String>{'Id', 'Name'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields); */
        //Query and store the sender account details in a Map
        Map<Id, Account> accountMap= new Map<Id, Account>([SELECT Id,Name FROM Account WHERE ID IN: senderAccountIdSet]);

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*// FLS Check
        List<String> caseFields = new List<String>{'Id', 'OwnerId', PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c')};
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);*/
        //Query and store the sender account details in a Map
        Map<Id, Case> caseMap= new Map<Id, Case>([SELECT Id,OwnerId, PC_Care_Coordinator__c FROM Case WHERE ID IN: caseIdSet]);

        List<Task> inboundMessageTaskList= new List<Task>();
        Account senderAccount= new Account();
        Case senderCase= new Case();
        String ownerId, caseId, senderName,subject= PC_Constants.EMPTY_STRING;
        for (PC_Message__c msg : messages) {
            if (msg.PC_Type__c == PC_Constants.INBOUND && msg.PC_Case__c != null && msg.PC_SenderAccount__c != null) {
                if(accountMap.containsKey(msg.PC_SenderAccount__c)){
                    senderAccount = accountMap.get(msg.PC_SenderAccount__c);
                    if (senderAccount.Name != null) {
                        senderName = senderAccount.Name;
                        subject= String.format(System.Label.PC_InboundMessageTitle, new List<String>{ senderName });
                    }
                }
                if (caseMap.containsKey(msg.PC_Case__c)) {
                    senderCase = caseMap.get(msg.PC_Case__c);
                    if(senderCase.PC_Care_Coordinator__c !=null){
                        ownerId= senderCase.PC_Care_Coordinator__c;
                    }
                    else if (senderCase.PC_Care_Coordinator__c == null && senderCase.OwnerId != null) {
                        ownerId = senderCase.OwnerId;
                    }
                    caseId= senderCase.Id;
                }
               inboundMessageTaskList.add(createInboundMessageTask(caseId,ownerId,subject,''));
            }
        }
        PC_Database.ins(inboundMessageTaskList,false);//Bulk-Insert
    }
    /*********************************************************************************
    Method Name    : createInboundMessageTask
    Author         : Chetna Mohapatra
    Description    : This method is used for creating user task on creation of Inbound message record
    Return Type    : task
    Parameter      : whatId, ownerId, subject, description
    *********************************************************************************/
    private static task createInboundMessageTask(String whatId, String ownerId, String subject, String description) {
        Task task = new Task();
        task.WhatId = whatId;
        task.OwnerId = (String.isNotBlank(ownerId) ? ownerId : UserInfo.getUserId());
        task.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
        task.PC_Direction__c = PC_Constants.INBOUND;
        task.PC_Channel__c = PC_Constants.PC_TASK_CHANNEL_SMS;
        task.Description = description;
        task.Subject = subject;
        task.Priority = PC_Constants.PC_PRIORITY_NORMAL;
        task.ActivityDate = System.today();
        task.Status = PC_Constants.PC_TASK_STATUS_WAITING;
        return task;

    }
}