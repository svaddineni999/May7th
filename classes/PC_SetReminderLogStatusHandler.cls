/**********************************************************************************************************************************************
Class Name      : PC_SetReminderLogStatusHandler
Description     : Trigger handler on Message object that changes the status of reminder logs when message is delivered/undelivered/failed.
Created By      : Kishore Kanteti
Created Date    : Oct 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti          Oct 15, 2021           Initial Version
Satheesh Kumar           Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
************************************************************************************************************************************************/
public inherited sharing class PC_SetReminderLogStatusHandler extends PC_TriggerHandler {
    private final String DELIVERED = 'Delivered';
    private final String UNDELIVERED = 'Undelivered';
    private final String FAILED = 'Failed';
    //This class runs under Trigger context and hence 'with sharing' is not provided.
    override public void afterUpdate(){
        assignReminderLogStatus((Map<Id,PC_Message__c >) newMap);
    }
    /*********************************************************************************
    Method Name    : assignReminderLogStatus
    Author         : Kishore Kanteti
    Description    : This method is to set the status of reminder log once the message status is updated.
    Return Type    : void
    *********************************************************************************/
    private void assignReminderLogStatus(Map<Id,PC_Message__c> messagesMap) {
        Map<String,PC_ReminderLog__c> reminderLogsMap = new Map<String, PC_ReminderLog__c>([SELECT Id, PC_Status__c, PC_StatusDetails__c, PC_SalesforceID__c FROM PC_ReminderLog__c WHERE PC_SalesforceID__c IN: messagesMap.keySet()]);
        for(PC_ReminderLog__c eachLog : reminderLogsMap.values()){
            String status = messagesMap.get(eachLog.PC_SalesforceID__c).PC_Message_Status__c;
            if(status == DELIVERED){
                eachLog.PC_Status__c = String.valueOf(PC_Reminder.STATUS.SUCCESS);
                eachLog.PC_StatusDetails__c = System.Label.PC_SMS_Success;
            }else if(status == UNDELIVERED || status == FAILED){
                eachLog.PC_Status__c = String.valueOf(PC_Reminder.STATUS.FAILED);
                eachLog.PC_StatusDetails__c = System.Label.PC_SMS_Error;
            }
        }
        PC_Database.upd(reminderLogsMap.values(),false);
    }
}