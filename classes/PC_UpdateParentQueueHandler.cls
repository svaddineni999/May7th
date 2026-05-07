/*********************************************************************************************************
Class Name      : PC_UpdateParentQueueHandler
Description     : Handler class for PC_ReminderLog__c object trigger.
Created By      : Deloitte
Created Date    : June 18, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore               June 18, 2021          Initial Version
Satheesh Kumar                Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
***********************************************************************************************************/

public inherited sharing class PC_UpdateParentQueueHandler extends PC_TriggerHandler{
    override public void afterInsert(){
        updateParentReminderQueues((List<PC_ReminderLog__c>) newList);
    }
    override public void afterUpdate(){
        updateParentReminderQueues((List<PC_ReminderLog__c>) newList);
    }
/**
 * @description Updates parent reminder queue record after creating a reminder log record, if a reminder is sent successfully
 * @param List Trigger.new
 */
    private void updateParentReminderQueues(List<PC_ReminderLog__c> newList){
        try{
            Map<Id,PC_ReminderQueue__c> reminderQueueMap;
            List<Id> queueIds =  new List<Id>();
            for(PC_ReminderLog__c eachLog : newList){
                queueIds.add(eachLog.PC_ReminderQueue__c);
            }
            if(!queueIds.isEmpty()){
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                /*//FLS Check
                List<String> queueFields = new List<String>{
                        PC_Constants.getQualifiedAPIName('PC_LastSuccessfulReminderSent__c'), 'Id'
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_ReminderQueue__c'), PC_Database.Operation.Reading, queueFields);*/

                reminderQueueMap = new Map<Id, PC_ReminderQueue__c>([SELECT Id, PC_LastSuccessfulReminderSent__c FROM PC_ReminderQueue__c WHERE Id IN:queueIds]);
                for(PC_ReminderLog__c reminderLog : newList){
                    if(reminderLog.PC_Status__c == PC_Constants.SUCCESS){
                        reminderQueueMap.get(reminderLog.PC_ReminderQueue__c).PC_LastSuccessfulReminderSent__c = System.now();
                    }
                }
                PC_Database.upd(reminderQueueMap.values(), false);
            }
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
}