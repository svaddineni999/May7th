/**
 * Created by vkashikar on 4/23/2020.
 * Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          01-Jul-2021              [PC-7869] Modified Queries to avoid hitting non selective query issue.
                                                Code can be uncommented to fix the issue while fetching SPA Logs.
 */


/**
 * Batch Job to align Support Plan Runtimes with the enhanced Support Plan model.
 */
global class PC_UpdateSupportPlanRuntimes implements Database.Batchable<sObject>, Database.Stateful{
    private Document summaryLogDocument = new Document();
    private String summaryLogContent = '';
    private String batchLogContent = '';
    private Integer i = 0;

    private static final String TXT_KEY = 'txt';

    private Boolean anyChildBatchFailed = false;

    /**
     * Implements Database.Batchable method
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        try {
            createSummaryLogDocument();

            String intializeSummaryContent = 'Initiating alignment of Support Plan Runtimes... \n';
            intializeSummaryContent += '\nJob Id -> ' + bc.getJobId();

            Integer batchJobRecordsCount = [
                    SELECT count()
                    FROM Task WHERE (Status != 'Completed' AND Status != 'Closed')
                    AND PC_SupportPlanActivity__c != NULL
            ];
            intializeSummaryContent += '\nNumber of Tasks that are not complete/closed and that need to be aligned = ' + batchJobRecordsCount;

            updateAndSaveSummaryLogDocument(intializeSummaryContent);

            query = getQuery();
            Database.QueryLocator queryLocator = Database.getQueryLocator(query);

            return queryLocator;

        }
        catch(Exception ex) {
            system.debug(ex.getMessage());
            summaryLogContent += ex.getMessage();
            summaryLogContent += '\n' + query;
            PC_Utility.publishErrorLog(ex, ex.getMessage() + '\n' + summaryLogContent);
        }
        return Database.getQueryLocator('SELECT ID FROM Task LIMIT 0');

    }

    /**
     * Implements Database.Batchable method
     */
    global void execute(Database.BatchableContext bc, List<Task> scope){
        batchLogContent = '';
        Document batchLog = createBatchDocument();
        List<Id> processedIds = new List<Id>();
        List<Id> unprocessedIds = new List<Id>();
        try {
            batchLogContent += '\nStart: Child Batch Job Id ' + bc.getChildJobId();

            List<Task> toBeMigratedTasks = getToBeMigratedTasks(scope);
            if(scope.size() != toBeMigratedTasks.size()) {
                summaryLogContent += '\nSkipped ' + String.valueOf(scope.size() - toBeMigratedTasks.size())
                        + ' record(s) as they are already aligned. See batch file ' + batchLog.Name + ' for more details';
            }
            List<PC_SupportPlanRuntime__c> scopedRuntimes= getScopedRuntimes(toBeMigratedTasks);

            List<PC_SupportPlanActivityLog__c> supportPlanActivityLogs=  new List<PC_SupportPlanActivityLog__c>();

            PC_SupportPlanActivityLog__c supportPlanActivityLog;
            for (Task t : toBeMigratedTasks) {
                supportPlanActivityLog = createSupportPlanActivityLog(t, scopedRuntimes);
                if(supportPlanActivityLog == null) {
                    batchLogContent += '\n Unable to migrate Task Id = ' + t.Id + ' since the associated runtime for this could not be found.';
                    unprocessedIds.add(t.Id);
                }
                else {
                    supportPlanActivityLogs.add(supportPlanActivityLog);
                    processedIds.add(t.Id);
                }

            }

            if(supportPlanActivityLogs != null){
                insert supportPlanActivityLogs;
            }

            if(supportPlanActivityLogs.size() > 0) {
                batchLogContent += '\nAlignment Successfully completed for the following support plan runtimes.';
            }
            for(PC_SupportPlanActivityLog__c log : supportPlanActivityLogs) {
                batchLogContent += '\nCreated Support Plan Activity Log with Id = ' + log.Id + ' for Task Id = ' + log.PC_ActionRecordId__c;
            }

            summaryLogContent += '\nAligned ' + processedIds.size() + ' record(s) in child batch file ' + batchLog.Name;
            if(unprocessedIds.size() > 0) {
                summaryLogContent += '\nCould not align ' + unprocessedIds.size() +
                        ' task(s) in child batch file ' + batchLog.Name + '. Please contact administrator.';
                batchLogContent += '\nAlignment could NOT be completed for the following tasks as the associated run time could not be found.';
                batchLogContent += '\n' + String.join(unprocessedIds, '\n');
            }
            batchLogContent += '\nEnd: Child Batch Job Id ' + bc.getChildJobId();
            updateAndSaveBatchLogDocument(batchLog, batchLogContent);

        }
        catch(Exception ex) {
            system.debug('***' + ex.getMessage());
            summaryLogContent += '\nException occurred while processing child batch job with Id ' + bc.getChildJobId();
            summaryLogContent += ex.getMessage();
            if(anyChildBatchFailed == false) {
                anyChildBatchFailed = true;
            }
            PC_Utility.publishErrorLog(ex, ex.getMessage());
        }

    }

    /**
     * Implements Database.Batchable method
     */
    global void finish(Database.BatchableContext bc){
        if(anyChildBatchFailed == true) {
            summaryLogContent += 'One or more of the child jobs have failed.';
            summaryLogContent += ' Please look at the logged exceptions either in this file or in the error log to take corrective action.';
            summaryLogContent += ' Once done, re-run the batch job.';
        }
        updateAndSaveSummaryLogDocument(summaryLogContent);
    }

    private PC_SupportPlanActivityLog__c createSupportPlanActivityLog(Task t, List<PC_SupportPlanRuntime__c> scopedRuntimes) {
        PC_SupportPlanActivityLog__c log;
        for (PC_SupportPlanRuntime__c runtime : scopedRuntimes) {
            if
                            (
                            (
                                    (runtime.PC_CurrentActivity__c != null && runtime.PC_CurrentActivity__c.contains(t.PC_SupportPlanActivity__r.PC_InternalActivityNumber__c)) ||
                                            (runtime.PC_CurrentGroupAllActivities__c != null && runtime.PC_CurrentGroupAllActivities__c.contains(t.PC_SupportPlanActivity__r.PC_InternalActivityNumber__c))
                            )
                                    &&
                                    runtime.PC_SupportPlanCase__c == t.WhatId
                            ) {
                log = new PC_SupportPlanActivityLog__c();
                log.PC_TriggerRecordId__c = t.whatId;
                log.PC_SupportPlanActivity__c = t.PC_SupportPlanActivity__c;
                log.PC_Status__c = 'In Progress';
                log.PC_ActionRecordId__c = t.Id;
                log.PC_RuntimeUser__c = t.OwnerId;
                log.PC_LogDateTime__c = runtime.PC_StartTime__c;
                log.PC_SupportPlanRuntime__c = runtime.Id;
                break;
            }
        }
        return log;

    }
    private List<Task> getToBeMigratedTasks(List<Task> tasks) {
        List<Task> toBeMigratedTasks = new List<Task>();
        Map<Id, Task> tasksByIds = new Map<Id, Task>();
        //Uncomment below line to resolve hitting Non selective Query limit
        //Set<Id> spaIds = new Set<Id>();
        for(Task t : Tasks) {
            system.debug('-----------' + t.Subject);
            tasksByIds.put(t.Id, t);
            //Uncomment below line to resolve hitting Non selective Query limit
            //spaIds.add(t.PC_SupportPlanActivity__c);
        }

        /*
        //Uncomment below code to resolve hitting Non selective Query limit
        List<PC_SupportPlanActivityLog__c> supportPlanActivityLogList = [SELECT ID, PC_ActionRecordId__c,PC_SupportPlanActivity__c
                    FROM PC_SupportPlanActivityLog__c WHERE PC_SupportPlanActivity__c IN: spaIds AND PC_ActionRecordId__c IN :tasksByIds.keySet()];

        List<PC_SupportPlanActivityLog__c>  migratedTasksAsActivities= new List<PC_SupportPlanActivityLog__c>();
        for(Task taskRecord : Tasks){
            for(PC_SupportPlanActivityLog__c log : supportPlanActivityLogList){
                if(taskRecord.Id == log.PC_ActionRecordId__c && taskRecord.PC_SupportPlanActivity__c == log.PC_SupportPlanActivity__c){
                    migratedTasksAsActivities.add(log);
                }
            }
        }*/

        /*Start - Comment this query to resolve hitting Non selective Query limit*/
        List<PC_SupportPlanActivityLog__c> migratedTasksAsActivities = [SELECT ID, PC_ActionRecordId__c
                    FROM PC_SupportPlanActivityLog__c WHERE PC_ActionRecordId__c IN :tasksByIds.keySet()];

        /*End - Comment this query to resolve hitting Non selective Query limit*/

        List<Id> actionIds = new List<Id>();
        for(PC_SupportPlanActivityLog__c log : migratedTasksAsActivities){
            actionIds.add(log.PC_ActionRecordId__c);
        }

        //batchLogContent += 'Debug Logs. All action Ids in this batch....';
        //batchLogContent += '\n' + String.join(actionIds, ',');
        Boolean isMigrated;
        for(Task t : tasks) {
            isMigrated = false;
            for(Id actionId : actionIds) { // 'contains' method of List did not work and hence the loop.
                if (String.valueOf(actionId).equalsIgnoreCase(String.valueOf(t.Id))) {
                    batchLogContent += '\nTask with Id ' + t.Id + ' has already been aligned. Hence, skipping.';
                    isMigrated = true;
                    break;
                }
            }
            if(!isMigrated) {
                toBeMigratedTasks.add(t);
            }

        }
        return toBeMigratedTasks;

    }
    private List<PC_SupportPlanRuntime__c> getScopedRuntimes(List<Task> tasks) {
        Set<Id> whatIds = new Set<Id>();
        for(Task t : Tasks) {
            whatIds.add(t.WhatId);
        }
        // Get the list of runtimes that are not completed and which are the runtimes for the given tasks.
        List<PC_SupportPlanRuntime__c> supportPlanRuntimes =
                    [Select Id, PC_SupportPlanCase__c, PC_CurrentActivity__c, PC_StartTime__c, PC_CurrentGroupAllActivities__c
                    FROM PC_SupportPlanRuntime__c
                    Where PC_SupportPlanCase__c IN :whatIds AND PC_CurrentActivityStatus__c != 'Completed' ];

        return supportPlanRuntimes;
    }

    private String getQuery() {
        String oTask = 'Task';
        String fSupportPlanActivity = PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c');
        String fSupportPlanActivityR = PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__r');
        String fSupportPlanInternalActivity = PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c');


        String query = 'Select Id, WhatId, Status, Subject, OwnerId, ' +
                fSupportPlanActivity + ',  ' +
                fSupportPlanActivityR + '.' + fSupportPlanInternalActivity + ' ' +
                ' FROM ' + oTask + ' ' +
                ' WHERE ' + '(Status != \'Completed\' AND Status != \'Closed\') AND ' +
                fSupportPlanActivity + ' != NULL' +
                ' ORDER BY CreatedDate';
        system.debug(query);

        return query;
    }

    private void createSummaryLogDocument() {
        summaryLogDocument.Name = 'PC_SupportPlanRuntime - SummaryLog - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        summaryLogDocument.Type = TXT_KEY;
        summaryLogDocument.folderid = UserInfo.getUserId();
        Database.SaveResult result = Database.insert(summaryLogDocument);
        summaryLogDocument.Id = result.id;
    }
    private void updateAndSaveSummaryLogDocument(String content) {
        String existingBodyContent = summaryLogDocument.Body == null ? '' : summaryLogDocument.Body.toString();
        summaryLogDocument.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(summaryLogDocument != null){
            update summaryLogDocument;
        }
    }
    private Document createBatchDocument() {
        Document batchLog = new Document();
        batchLog.Name = 'PC_SupportPlanRuntime - BatchLog ' + ++i + ' - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        batchLog.Type = TXT_KEY;
        batchLog.folderid = UserInfo.getUserId();
        Database.SaveResult result = Database.insert(batchLog);
        batchLog.Id = result.Id;
        return batchLog;
    }
    private void updateAndSaveBatchLogDocument(Document batchLog, String content) {
        String existingBodyContent = batchLog.Body == null ? '' : batchLog.Body.toString();
        batchLog.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(batchLog != null){
            update batchLog;
        }
    }

}