/**
 *Global Interface for clients to implement and Process Reminder Queues
 */
global with sharing class PC_Reminder{
    global enum STATUS {SUCCESS, FAILED, UNPROCESSED}
    private static final String PRIORITY_HIGH = 'High';
    private static final String TASK_STATUS_WAITING = 'Waiting on someone else';
    /**
     *Interface for Processing Reminder Queues and Sending Reminders
     */
    global interface Processor{
        /**
         *Interface method that has to be implemented in service classes to process reminder queues and send reminders
         *through different channels, the results are captured under reminder logs object
         * @param Request
         */
         Response process(Request reminderQueuesBatch);
    }


    global inherited sharing class Request{
        global List<ProcessRequest> processRequests{get;set;}
    }
    global inherited sharing class ProcessRequest{
        global PC_ReminderQueue__c queueRecord{get;set;}
        global PC_ReminderSetting__mdt setting{get;set;}
    }
    global inherited sharing class Response{
        global List<ProcessResult> processResults;
        global Boolean responseStatus;
        global Response(){
            responseStatus = false;
        }
    }
    global inherited sharing class ProcessResult{
        global PC_ReminderQueue__c queueRecord{get;set;}
        global PC_ReminderSetting__mdt setting{get;set;}
        global STATUS status {get;set;}
        global String statusDetails {get;set;}
        global String content {get;set;}
        global String externalId {get;set;}
        global String salesforceRecordId {get;set;}
        global Task failureTask {get;set;}

        global ProcessResult(){
            statusDetails = '';
            status = PC_Reminder.STATUS.FAILED;
            externalId = '';
            salesforceRecordId = '';
            failureTask = new Task();
            failureTask.ActivityDate = System.today();
            failureTask.Priority = PRIORITY_HIGH;
            failureTask.Status = TASK_STATUS_WAITING;
            failureTask.Subject = System.Label.PC_ReminderNotProcessed;
        }
    }
}