/**
 * Global class for scheduling batch to process reminder queues
 */

global with sharing class PC_ProcessQueuesInBatchScheduler implements Schedulable{

    /**
 * @description Global method for scheduling batch to process reminder queues
 */
    global void execute(SchedulableContext scMain){
        String reminderQueueQuery = 'SELECT ID, Name, PC_LastSuccessfulReminderSent__c, PC_Comments__c, PC_ReminderChannel__c, PC_RecordID__c, PC_ReminderSetting__c, PC_Recipient__c, '+
                'PC_ParentReferenceRecordID__c, PC_Active__c, PC_DueDate__c, ' +
                'PC_AssignNotificationToUser__c FROM PC_ReminderQueue__c WHERE PC_Active__c = TRUE AND PC_AllRemindersSent__c = FALSE';
        try{
            Integer batchSize = 200;
            PC_ProcessQueuesInBatch.Parameters reminderParameters = new PC_ProcessQueuesInBatch.Parameters();
            reminderParameters.reminderQueueQuery = reminderQueueQuery;
            reminderParameters.notifyAllAdmins = false;
            PC_BatchUtility.BatchJobProperties batchJobSetting = new PC_BatchUtility.BatchJobProperties();
            batchJobSetting = PC_BatchUtility.getBatchJobSetting(PC_BatchUtility.REMINDER_QUEUES_BATCH_NAME);
            if(batchJobSetting != null){
                reminderParameters.notifyAllAdmins = batchJobSetting.notifyAllAdmins;
                batchSize = batchJobSetting.size;
            }
            Database.executeBatch(new PC_ProcessQueuesInBatch(reminderParameters), batchSize);
        }catch(Exception ex){
            PC_Utility.publishErrorLog(ex, ex.getMessage() + '\n OR \n Issue in Patient Connect Setting '+PC_BatchUtility.BATCH_SIZE_SETTING_NAME+' make sure the JSON is correct.');
            PC_BatchUtility.notifyAdministratorsOrUser(true,ex.getMessage() + '\n OR \n Issue in Patient Connect Setting '+PC_BatchUtility.BATCH_SIZE_SETTING_NAME+' make sure the JSON is correct.');
        }
    }
}