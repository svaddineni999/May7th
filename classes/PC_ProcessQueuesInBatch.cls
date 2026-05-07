/**
 * Global Batch Class to Process Reminder Queues
 */
global class PC_ProcessQueuesInBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts{

    private Document summaryLogDocument = new Document();
    private String summaryLogContent = '';
    private String batchLogContent = '';
    private static final String TXT_KEY = 'txt';
    private Integer i = 0;
    private Boolean anyChildBatchFailed = false;
    private Integer successRecordCount = 0;
    private Integer unprocessedRecordCount = 0;
    private Integer failedRecordCount = 0;
    private String reminderQueueQuery = '';
    private Boolean notifyAllAdmins = false;
/**
  *Batch Class Constructor
 */
    global PC_ProcessQueuesInBatch(Parameters reminderQueueParameters){
        this.reminderQueueQuery = reminderQueueParameters.reminderQueueQuery;
        this.notifyAllAdmins = reminderQueueParameters.notifyAllAdmins;
    }

/**
 * @description Start method for the batch
 * @param BatchableContext
 * @return Database.QueryLocator
 */
    public Database.QueryLocator start(Database.BatchableContext bc){
        try{
            createSummaryLogDocument();
            String initializeSummaryContent = 'Initiating job to Process Reminders... \n';
            initializeSummaryContent += '\nJob Id -> ' + bc.getJobId();
            initializeSummaryContent += '\nParameters Received...';
            initializeSummaryContent += '\n\t1. Reminder Queue Query - '+ reminderQueueQuery;
            initializeSummaryContent += '\n\t2. Notify All Admins - '+ notifyAllAdmins;
            Integer batchJobRecordsCount = [
                    SELECT count()
                    FROM PC_ReminderQueue__c
                    WHERE PC_Active__c = TRUE AND PC_AllRemindersSent__c = FALSE
            ];
            initializeSummaryContent += '\n\nProcessing ' + batchJobRecordsCount + ' Reminder Queue Records';
            updateAndSaveSummaryLogDocument(initializeSummaryContent);
            Database.QueryLocator queryLocator = Database.getQueryLocator(reminderQueueQuery);
            return queryLocator;
        }catch(Exception ex){
            summaryLogContent += ex.getMessage();
            summaryLogContent += '\n' + reminderQueueQuery;
            PC_Utility.publishErrorLog(ex, ex.getMessage() + '\n' + summaryLogContent);
        }
        return Database.getQueryLocator('SELECT ID FROM PC_ReminderQueue__c LIMIT 0');
    }
    /**
 * @description Execute method for the batch
 * @param BatchableContext,PC_ReminderQueue__c[]
 */
    public void execute(Database.BatchableContext bc, List<PC_ReminderQueue__c> reminderQueues){
        Document batchLog = createBatchDocument();
        try{
            batchLogContent = '';
            GroupedReminderQueues groupedReminderQueueAndSettings =  groupReminderQueues(reminderQueues);
            List<PC_ReminderQueue__c> expiredReminderQueues = new List<PC_ReminderQueue__c>();
            expiredReminderQueues = groupedReminderQueueAndSettings.expiredReminderQueues;
            List<PC_ReminderQueue__c> queuesTooSoonToBeSent = new List<PC_ReminderQueue__c>();
            queuesTooSoonToBeSent = groupedReminderQueueAndSettings.queuesTooSoonToBeSent;
            List<PC_ReminderQueue__c> noHandlerForQueues = new List<PC_ReminderQueue__c>();
            noHandlerForQueues = groupedReminderQueueAndSettings.noHandlerForQueues;

            batchLogContent += '\nStart: Child Batch Job Id ' + bc.getChildJobId() + ' for ' + reminderQueues.size() + ' records ';
            batchLogContent += '\nBatch Log Name: '+ batchLog.Name;
            if(expiredReminderQueues.size() > 0){
                batchLogContent += '\n\n***********************************************************************************';
                batchLogContent += '\n Inactivating ' + expiredReminderQueues.size() + ' Reminder Queues because ' + System.Label.PC_ReminderQueueInactivatedComments;
                for(PC_ReminderQueue__c expiredQueue : expiredReminderQueues){
                    batchLogContent += '\n ' + expiredQueue.Id + ' - '+ expiredQueue.Name + ' / Setting - ' + expiredQueue.PC_ReminderSetting__c;
                }
                PC_Database.upd(expiredReminderQueues,false);
                batchLogContent += '\n Inactivated ' + expiredReminderQueues.size() + ' Reminder Queues.';
                summaryLogContent += '\nInactivated ' + expiredReminderQueues.size() + ' Reminder Queues. Child batch file - '+ batchLog.Name;
                batchLogContent += '\n***********************************************************************************';
            }
            if(queuesTooSoonToBeSent.size() > 0){
                batchLogContent += '\n\n***********************************************************************************';
                batchLogContent += '\n Skipped ' + queuesTooSoonToBeSent.size() + ' Reminder Queues because the interval specified in settings is not met.';
                summaryLogContent += '\nSkipped ' + queuesTooSoonToBeSent.size() + ' Reminder Queues because the interval specified in settings is not met. Child batch file - '+ batchLog.Name;
                for(PC_ReminderQueue__c skippedQueue : queuesTooSoonToBeSent){
                    batchLogContent += '\n ' + skippedQueue.Id + ' - '+ skippedQueue.Name + ' / Setting - ' + skippedQueue.PC_ReminderSetting__c;
                }
                batchLogContent += '\n***********************************************************************************';
            }
            if(noHandlerForQueues.size() > 0){
                batchLogContent += '\n\n***********************************************************************************';
                batchLogContent += '\n Did not process ' + noHandlerForQueues.size() + ' Reminder Queues because there is no handler class for processing for that channel.';
                summaryLogContent += '\nDid not process ' + noHandlerForQueues.size() + ' Reminder Queues because there is no handler class for processing for that channel. Child batch file - '+ batchLog.Name;
                batchLogContent += '\n Please check Reminder Channel And Handler Mapping in Patient Connect Setting.';
                for(PC_ReminderQueue__c notProcessedQueue : noHandlerForQueues){
                    batchLogContent += '\n ' + notProcessedQueue.Id + ' - '+ notProcessedQueue.Name + ' / Setting - ' + notProcessedQueue.PC_ReminderSetting__c + ' / Channel - ' + notProcessedQueue.PC_ReminderChannel__c;
                }
                PC_BatchUtility.notifyAdministratorsOrUser(notifyAllAdmins,'Did not process ' + noHandlerForQueues.size() + ' Reminder Queues because there is no handler class for processing for that channel.'+
                        'Please check Batch logs with name: '+ batchLog.Name +' in Salesforce Document Object and Reminder Channel And Handler Mapping in Patient Connect Setting.');
                batchLogContent += '\n***********************************************************************************';
            }

            Map<String,List<EligibleReminderQueue>> handlerQueuesMap =  new Map<String,List<EligibleReminderQueue>>();
            handlerQueuesMap = groupedReminderQueueAndSettings.allHandlerReminderQueuesMap;
            List<PC_ReminderLog__c> allEligibleReminderLogs = new List<PC_ReminderLog__c>();
            List<Task> allFailureTasks = new List<Task>();
            List<Event> successEvents = new List<Event>();
            for (String handler : handlerQueuesMap.keySet()){
                Type handlerType = Type.forName(handler);
                if (handlerType != null){
                    Object classObject = handlerType.newInstance();
                    if(classObject instanceof PC_Reminder.Processor){
                        batchLogContent += '\n\n*************************************************************************************';
                        batchLogContent += '\nProcessing ' + handlerQueuesMap.get(handler).size() + ' records in ' + handler + ' class....';
                        Integer batchRecordCount = 0;

                        //Creating Request And Sending it to Service Class
                        PC_Reminder.Request queueAndSettingsRequest = new PC_Reminder.Request();
                        queueAndSettingsRequest.processRequests = new List<PC_Reminder.ProcessRequest>();
                        batchLogContent += '\nProcessing Queue IDs are: ';
                        for (EligibleReminderQueue eligibleQueueAndSetting : handlerQueuesMap.get(handler)){
                            PC_Reminder.ProcessRequest eachProcessRequest = new PC_Reminder.ProcessRequest();
                            batchLogContent += '\t '+ eligibleQueueAndSetting.queueRecord.Id;
                            eachProcessRequest.queueRecord = eligibleQueueAndSetting.queueRecord;
                            eachProcessRequest.setting = eligibleQueueAndSetting.reminderSetting;
                            queueAndSettingsRequest.processRequests.add(eachProcessRequest);
                        }
                        PC_Reminder.Processor queueProcessor = (PC_Reminder.Processor) classObject;
                        PC_Reminder.Response reminderResponse = new PC_Reminder.Response();
                        try{
                            reminderResponse = queueProcessor.process(queueAndSettingsRequest);
                        }catch(Exception ex){
                            batchLogContent += '\nATTENTION: Something went wrong in handler class '+ handler+'. Continued with the execution for remaining records.';
                            batchLogContent += '\nATTENTION: '+ex.getMessage();
                            summaryLogContent += '\nATTENTION: '+ex.getMessage()+' Exception in child batch job with Id '+bc.getChildJobId();
                            if(anyChildBatchFailed == false){
                                anyChildBatchFailed = true;
                            }
                            continue;
                        }
                        batchLogContent += '\n\n Below are the results: ';
                        for (PC_Reminder.ProcessResult eachResult : reminderResponse.processResults){
                            batchRecordCount++;
                            //Creating Reminder Log Record.
                            PC_ReminderLog__c reminderLog = new PC_ReminderLog__c();
                            reminderLog.PC_ReminderQueue__c = eachResult.queueRecord.Id;
                            if(String.isNotBlank(reminderLog.PC_StatusDetails__c)) {
                                reminderLog.PC_StatusDetails__c += eachResult.statusDetails;
                            }else{
                                reminderLog.PC_StatusDetails__c = eachResult.statusDetails;
                            }
                            reminderLog.PC_ExternalID__c = String.isNotBlank(eachResult.externalId) ? eachResult.externalId : '';
                            reminderLog.PC_SalesforceID__c = String.isNotBlank(eachResult.salesforceRecordId) ? eachResult.salesforceRecordId : '';
                            reminderLog.PC_ReminderContent__c = eachResult.content;
                            if(eachResult.status == PC_Reminder.STATUS.SUCCESS){
                                successRecordCount += 1;
                                reminderLog.PC_Status__c = String.valueOf(PC_Reminder.STATUS.SUCCESS);
                                batchLogContent += '\n\n'+ batchRecordCount + '. Reminder Processed Successfully for Reminder Queue Id ' + eachResult.queueRecord.Id + ' - '+ eachResult.queueRecord.Name;
                                batchLogContent += '\n   Setting Name: ' + eachResult.queueRecord.PC_ReminderSetting__c;
                                batchLogContent += '\n   Status Details: ' + eachResult.statusDetails;
                                batchLogContent += '\n   Recipient: ' + eachResult.queueRecord.PC_Recipient__c;
                                if(eachResult.setting.PC_ShowSuccessfulRemindersNotifications__c){
                                    //Creating success event only if Show notifications is true on reminder setting
                                    Event successEvent = new Event();
                                    successEvent.Subject = System.Label.PC_ReminderProcessed;
                                    successEvent.Description = System.Label.PC_ReminderProcessed + ' / '+eachResult.queueRecord.PC_ReminderChannel__c;
                                    successEvent.StartDateTime = system.now();
                                    successEvent.EndDateTime = system.now();
                                    if (eachResult.queueRecord.PC_ParentReferenceRecordID__c != null) {
                                        successEvent.WhatId = eachResult.queueRecord.PC_ParentReferenceRecordID__c;
                                    } else {
                                        successEvent.WhatId = eachResult.queueRecord.PC_RecordID__c;
                                    }
                                    if(eachResult.queueRecord.PC_AssignNotificationToUser__c != null && String.isNotBlank(eachResult.queueRecord.PC_AssignNotificationToUser__c)) {
                                        successEvent.OwnerId = eachResult.queueRecord.PC_AssignNotificationToUser__c;
                                    }else{
                                        successEvent.OwnerId = UserInfo.getUserId();
                                    }
                                    successEvents.add(successEvent);
                                }
                            }else if(eachResult.status == PC_Reminder.STATUS.FAILED){
                                failedRecordCount += 1;
                                //Updating Log Status And Batch Log Content
                                reminderLog.PC_Status__c = String.valueOf(PC_Reminder.STATUS.FAILED);
                                batchLogContent += '\n\n'+ batchRecordCount + ' Reminder Processing Failed for Reminder Queue Id ' + eachResult.queueRecord.Id + ' - '+ eachResult.queueRecord.Name + ' due to ' + eachResult.statusDetails;
                                batchLogContent += '\n   Setting Name: ' + eachResult.queueRecord.PC_ReminderSetting__c;
                                batchLogContent += '\n   Recipient: ' + eachResult.queueRecord.PC_Recipient__c;

                                if(eachResult.setting.PC_CreateTasksOnFailure__c){
                                    if(eachResult.queueRecord.PC_ParentReferenceRecordID__c != null){
                                        eachResult.failureTask.WhatId = eachResult.queueRecord.PC_ParentReferenceRecordID__c;
                                    }else{
                                        eachResult.failureTask.WhatId = eachResult.queueRecord.PC_RecordID__c;
                                    }
                                    if(eachResult.queueRecord.PC_AssignNotificationToUser__c != null && String.isNotBlank(eachResult.queueRecord.PC_AssignNotificationToUser__c)){
                                        eachResult.failureTask.OwnerId = eachResult.queueRecord.PC_AssignNotificationToUser__c;
                                    }else{
                                        eachResult.failureTask.OwnerId = UserInfo.getUserId();
                                    }
                                    allFailureTasks.add(eachResult.failureTask);
                                }
                            }else if(eachResult.status == PC_Reminder.STATUS.UNPROCESSED){
                                unprocessedRecordCount += 1;
                                reminderLog.PC_Status__c = String.valueOf(PC_Reminder.STATUS.UNPROCESSED);
                                batchLogContent += '\n\n'+ batchRecordCount + ' Reminder Log is Unprocessed. Reminder Queue Id ' + eachResult.queueRecord.Id + ' - '+ eachResult.queueRecord.Name;
                                batchLogContent += '\n   Reason: ' + eachResult.statusDetails;
                                batchLogContent += '\n   Setting Name: ' + eachResult.queueRecord.PC_ReminderSetting__c;
                                batchLogContent += '\n   Recipient: ' + eachResult.queueRecord.PC_Recipient__c;
                            }
                            allEligibleReminderLogs.add(reminderLog);
                        }
                        batchLogContent += '\n\n Processed ' + handlerQueuesMap.get(handler).size() + ' records in ' + handler + ' class.';
                        batchLogContent += '\n****************************************************************************************';
                    }else{
                        String errorMessage = 'Registered '
                                + handler
                                + ' does not implement required interface PC_Reminder.Processor.';
                        batchLogContent += '\nATTENTION: '+errorMessage;
                        summaryLogContent += '\nATTENTION: '+ errorMessage;
                        PC_Utility.createErrorLog(errorMessage);
                        if(anyChildBatchFailed == false){
                            anyChildBatchFailed = true;
                        }
                        continue;
                    }
                }else{
                    String classNotFoundError = 'Registered '
                            + handler
                            + ' class not found. Check Patient Connect Setting PC_ReminderChannelHandlerMapping.';
                    batchLogContent += '\nATTENTION: '+ classNotFoundError;
                    summaryLogContent += '\nATTENTION: '+ classNotFoundError;
                    PC_Utility.createErrorLog(classNotFoundError);
                    if(anyChildBatchFailed == false){
                        anyChildBatchFailed = true;
                    }
                    continue;
                }
            }
            if(allEligibleReminderLogs.size()>0){
                PC_Database.ins(allEligibleReminderLogs,true);
                batchLogContent += '\nCreated  ' + allEligibleReminderLogs.size() + ' reminder log(s).';
                summaryLogContent += '\nCreated  ' + allEligibleReminderLogs.size() + ' reminder log(s) in child batch file ' + batchLog.Name;
            }
            if(!allFailureTasks.isEmpty()){
                PC_Database.ins(allFailureTasks,true);
                batchLogContent += '\nCreated  ' + allFailureTasks.size() + ' failure task(s).';
                summaryLogContent += '\nCreated  ' + allFailureTasks.size() + ' failure task(s) in child batch file ' + batchLog.Name;
            }
            if(!successEvents.isEmpty()){
                PC_Database.ins(successEvents,true);
                batchLogContent += '\nCreated  ' + successEvents.size() + ' success event(s).';
                summaryLogContent += '\nCreated  ' + successEvents.size() + ' success event(s) in child batch file ' + batchLog.Name;
            }
            batchLogContent += '\nEnd: Child Batch Job Id ' + bc.getChildJobId();
            summaryLogContent += '\nProcessed ' + reminderQueues.size() + ' record(s) in child batch file ' + batchLog.Name + '\n';
        }catch(Exception ex) {
            summaryLogContent += '\nATTENTION: Exception occurred while processing child batch job with Id ' + bc.getChildJobId();
            summaryLogContent += '\n'+ex.getMessage();
            if(anyChildBatchFailed == false){
                anyChildBatchFailed = true;
            }
            PC_Utility.publishErrorLog(ex, ex.getMessage());
        }finally{
            updateAndSaveBatchLogDocument(batchLog, batchLogContent);
        }
    }
/**
 * @description Finish method for the batch
 * @param BatchableContext
 */
    public void finish(Database.BatchableContext bc){
        try{
            if(anyChildBatchFailed == true){
                summaryLogContent += '\nATTENTION: One or more of the child jobs have failed.';
                summaryLogContent += '\nATTENTION: Please look at logged exceptions either in this file or in the error log to take corrective action.';
                summaryLogContent += '\nATTENTION: Once done, re-run the batch job.';
                PC_BatchUtility.notifyAdministratorsOrUser(notifyAllAdmins,summaryLogContent);
            }else{
                summaryLogContent += '\n\nSuccessfully processed '+ successRecordCount + ' records.';
                summaryLogContent += '\nATTENTION: Processing failed for '+ failedRecordCount + ' records.';
                summaryLogContent += '\nUnprocessed '+ unprocessedRecordCount + ' records.';
            }
        }catch(Exception ex){
            PC_Utility.publishErrorLog(ex,ex.getMessage()+ '. Administrator could not be notified with the error. Please check all the settings related to Reminder Service');
        }
        updateAndSaveSummaryLogDocument(summaryLogContent);
    }
    /**
 * @description Creates summary log document in Salesforce Document Object
 */
    private void createSummaryLogDocument() {
        summaryLogDocument.Name = 'PC_Reminder - SummaryLog - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        summaryLogDocument.Type = TXT_KEY;
        summaryLogDocument.FolderId = PC_BatchUtility.getFolderId(PC_BatchUtility.REMINDER_QUEUES_BATCH_NAME);
        Database.SaveResult result = Database.insert(summaryLogDocument);
        summaryLogDocument.Id = result.id;
    }
    /**
 * @description Updates summary log document with content
 * @param String Content
 */
    private void updateAndSaveSummaryLogDocument(String content) {
        String existingBodyContent = summaryLogDocument.Body == null ? '' : summaryLogDocument.Body.toString();
        summaryLogDocument.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(summaryLogDocument != null){
            update summaryLogDocument;
        }
    }
    /**
 * @description Creates Batch Log Document for each Batch in Salesforce Document Object
 * @return sObject(Document)
 */
    private Document createBatchDocument() {
        Document batchLog = new Document();
        batchLog.Name = 'PC_Reminder - BatchLog '+  ++i  + ' - ' + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        batchLog.Type = TXT_KEY;
        batchLog.FolderId = PC_BatchUtility.getFolderId(PC_BatchUtility.REMINDER_QUEUES_BATCH_NAME);
        return batchLog;
    }
    /**
 * @description Updates batch log document with content
 * @param sObject Document, String - Content
 */
    private void updateAndSaveBatchLogDocument(Document batchLog, String content) {
        String existingBodyContent = batchLog.Body == null ? '' : batchLog.Body.toString();
        batchLog.Body = Blob.valueOf(existingBodyContent + '\n' + content);
        if(batchLog != null){
            upsert batchLog;
        }
    }
    /**
 * @description Filters reminder queues based on different conditions
 * @param PC_ReminderQueue__c[]
 * @return DifferentReminderQueues wrapper class(PC_ReminderQueue__c[] expired, PC_ReminderQueue__c[]queuesNotAchievedTimeInterval, EligibleReminderQueue[] eligibleQueues)
 */
    private static GroupedReminderQueues groupReminderQueues(List<PC_ReminderQueue__c> reminderQueues){
        GroupedReminderQueues allGroupedReminderQueues = new GroupedReminderQueues();
        List<EligibleReminderQueue> eligibleBatchQueuesAndSettings = new List<EligibleReminderQueue>();
        List<PC_ReminderSetting__mdt> reminderSettings = new List<PC_ReminderSetting__mdt>([
                SELECT Id, PC_ReminderChannel__c, PC_Object_ReminderService__c, PC_StartDateOffsetType__c, PC_StartDateOffset__c, PC_TemplateType__c, PC_OtherChannelName__c,
                        PC_OtherTemplateType__c, DeveloperName, PC_CreateTasksOnFailure__c, PC_ShowSuccessfulRemindersNotifications__c, PC_MaximumRemindersToBeSent__c, PC_StartDateOffsetReference__c,
                        PC_TemplateName__c, PC_MinimumIntervalReminders__c, PC_AssignNotificationFieldName__c, PC_EndDateOffsetReference__c, PC_EndDateOffset__c, PC_EndDateOffsetType__c
                FROM PC_ReminderSetting__mdt
                WHERE PC_Active__c = TRUE]);

        Map<String,String> channelHandlerMap = new Map<String,String>();
        Map<String, List<EligibleReminderQueue>> handlerQueuesMap = new Map<String, List<EligibleReminderQueue>>();
        String channelHandlerMappingJSON = PC_SYSTEM.getPatientConnectSetting(PC_BatchUtility.REMINDER_CHANNEL_HANDLER_SETTING,'');
        List<ReminderChannelHandler> channelHandlerMappingList = new List<ReminderChannelHandler>();
        channelHandlerMappingList = (List<ReminderChannelHandler>) JSON.deserialize(channelHandlerMappingJSON, List<ReminderChannelHandler>.class);
        for(ReminderChannelHandler eachChannelHandler : channelHandlerMappingList){
            channelHandlerMap.put(eachChannelHandler.channel,eachChannelHandler.handler);
        }

        Map<String,PC_ReminderSetting__mdt> settingNameRecordMap = new Map<String,PC_ReminderSetting__mdt>();
        for(PC_ReminderSetting__mdt eachSetting : reminderSettings){
            settingNameRecordMap.put(eachSetting.DeveloperName,eachSetting);
        }
        List<PC_ReminderQueue__c> expiredReminderQueues = new List<PC_ReminderQueue__c>();

        for(PC_ReminderQueue__c eachQueueRecord : reminderQueues){
            PC_ReminderSetting__mdt metadataSetting = settingNameRecordMap.get(eachQueueRecord.PC_ReminderSetting__c);
            //Logic to make record inactive if settings are for Before the due date and it is past the current date/time
            if(checkExpirationOfReminderQueue(eachQueueRecord, metadataSetting)){
                eachQueueRecord.PC_Active__c = false;
                if(String.isNotBlank(eachQueueRecord.PC_Comments__c)){
                    eachQueueRecord.PC_Comments__c += System.Label.PC_ReminderQueueInactivatedComments;
                }else{
                    eachQueueRecord.PC_Comments__c = System.Label.PC_ReminderQueueInactivatedComments;
                }
                expiredReminderQueues.add(eachQueueRecord);
                allGroupedReminderQueues.expiredReminderQueues.add(eachQueueRecord);
                continue;
            }
            //Logic to skip the Queue record if the minimum time interval is not achieved
            if(eachQueueRecord.PC_LastSuccessfulReminderSent__c != null){
                if(Decimal.valueOf((System.now().getTime() - eachQueueRecord.PC_LastSuccessfulReminderSent__c.getTime()) / (1000 * 60)) < (metadataSetting.PC_MinimumIntervalReminders__c * 60)){
                    allGroupedReminderQueues.queuesTooSoonToBeSent.add(eachQueueRecord);
                    continue;
                }
            }else{
                Datetime startDatetime = PC_BatchUtility.getDatetime(eachQueueRecord.PC_DueDate__c,Integer.valueOf(metadataSetting.PC_StartDateOffset__c),
                metadataSetting.PC_StartDateOffsetType__c,metadataSetting.PC_StartDateOffsetReference__c);
                if(System.now() < startDatetime){
                    allGroupedReminderQueues.queuesTooSoonToBeSent.add(eachQueueRecord);
                    continue;
                }
            }
            if(channelHandlerMap.containsKey(eachQueueRecord.PC_ReminderChannel__c)){
                if(checkEligibilityOfQueueRecord(eachQueueRecord, metadataSetting)){
                    EligibleReminderQueue queueAndSetting = new EligibleReminderQueue();
                    queueAndSetting.queueRecord = eachQueueRecord;
                    queueAndSetting.reminderSetting = settingNameRecordMap.get(eachQueueRecord.PC_ReminderSetting__c);
                    queueAndSetting.handlerClass = channelHandlerMap.get(eachQueueRecord.PC_ReminderChannel__c);
                    eligibleBatchQueuesAndSettings.add(queueAndSetting);
                }
            }else{
                allGroupedReminderQueues.noHandlerForQueues.add(eachQueueRecord);
                continue;
            }
        }
        //Creating a Map of Handler Class Name and List of Reminder Queues.
        for(EligibleReminderQueue reminderQueue : eligibleBatchQueuesAndSettings){
            if(handlerQueuesMap.containsKey(reminderQueue.handlerClass)){
                handlerQueuesMap.get(reminderQueue.handlerClass).add(reminderQueue);
            }else{
                List<EligibleReminderQueue> eligibleReminderQueuesList = new List<EligibleReminderQueue>();
                eligibleReminderQueuesList.add(reminderQueue);
                handlerQueuesMap.put(reminderQueue.handlerClass, eligibleReminderQueuesList);
            }
        }
        allGroupedReminderQueues.allHandlerReminderQueuesMap = handlerQueuesMap;
        return allGroupedReminderQueues;
    }
/**
 * @description Checks eligibility(Offset Calculation) of each reminder queue to send a reminder.
 * @param PC_ReminderQueue__c  reminderQueue ,PC_ReminderSetting__mdt - reminderSetting
 * @return Boolean
 */
    private static Boolean checkEligibilityOfQueueRecord(PC_ReminderQueue__c reminderQueue, PC_ReminderSetting__mdt reminderSetting){
        Integer offset = Integer.valueOf(reminderSetting.PC_StartDateOffset__c);
        String offsetType = reminderSetting.PC_StartDateOffsetType__c;
        String offsetReference = reminderSetting.PC_StartDateOffsetReference__c;
        Datetime calculatedDate;
        if(offsetType == PC_BatchUtility.OFFSET_AFTER){
            if(offsetReference == PC_BatchUtility.OFFSET_REFERENCE_DAYS){
                calculatedDate = reminderQueue.PC_DueDate__c.addDays(offset);
            }else{
                calculatedDate = reminderQueue.PC_DueDate__c.addHours(offset);
            }
        }else{
            if(offsetReference == PC_BatchUtility.OFFSET_REFERENCE_DAYS){
                calculatedDate = reminderQueue.PC_DueDate__c.addDays(-offset);
            }else{
                calculatedDate = reminderQueue.PC_DueDate__c.addHours(-offset);
            }
        }
        if(calculatedDate <= system.now()){
            return true;
        }else{
            return false;
        }
    }
    /**
 * @description Checks expiration(End Date Offset Calculation) of each queue to inactivate.
 * @param PC_ReminderQueue__c  reminderQueue ,PC_ReminderSetting__mdt - reminderSetting
 * @return Boolean
 */
    private static Boolean checkExpirationOfReminderQueue(PC_ReminderQueue__c reminderQueue, PC_ReminderSetting__mdt reminderSetting){
        Integer offset = Integer.valueOf(reminderSetting.PC_EndDateOffset__c);
        String offsetType = reminderSetting.PC_EndDateOffsetType__c;
        String offsetReference = reminderSetting.PC_EndDateOffsetReference__c;
        Datetime calculatedDate;
        if(offsetType == PC_BatchUtility.OFFSET_AFTER){
            if(offsetReference == PC_BatchUtility.OFFSET_REFERENCE_DAYS){
                calculatedDate = reminderQueue.PC_DueDate__c.addDays(offset);
            }else{
                calculatedDate = reminderQueue.PC_DueDate__c.addHours(offset);
            }
        }else{
            if(offsetReference == PC_BatchUtility.OFFSET_REFERENCE_DAYS){
                calculatedDate = reminderQueue.PC_DueDate__c.addDays(-offset);
            }else{
                calculatedDate = reminderQueue.PC_DueDate__c.addHours(-offset);
            }
        }
        //Both(Calculated Date and  System.now()) are in GMT Timezones so there will be no issue while comparing
        if(calculatedDate <= system.now()){
            return true;
        }else{
            return false;
        }
    }
    private inherited sharing class GroupedReminderQueues{
        private List<PC_ReminderQueue__c> expiredReminderQueues{get;set;}
        private List<PC_ReminderQueue__c> queuesTooSoonToBeSent{get;set;}
        private List<PC_ReminderQueue__c> noHandlerForQueues{get;set;}
        private Map<String, List<EligibleReminderQueue>> allHandlerReminderQueuesMap{get;set;}
        private GroupedReminderQueues(){
            expiredReminderQueues = new List<PC_ReminderQueue__c>();
            queuesTooSoonToBeSent = new List<PC_ReminderQueue__c>();
            noHandlerForQueues = new List<PC_ReminderQueue__c>();
        }
    }
    private inherited sharing class EligibleReminderQueue{
        private PC_ReminderQueue__c queueRecord{get;set;}
        private PC_ReminderSetting__mdt reminderSetting{get;set;}
        private String handlerClass{get;set;}
        private EligibleReminderQueue(){}
    }

    private inherited sharing class ReminderChannelHandler{
        private String channel{get;set;}
        private String handler{get;set;}
    }

    global class Parameters{
        global String reminderQueueQuery{get;set;}
        global Boolean notifyAllAdmins{get;set;}
    }
}