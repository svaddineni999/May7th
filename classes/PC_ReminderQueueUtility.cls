/**
 * Utility class with helper methods w.r.t queuing of Reminder records.
 */
global inherited sharing class PC_ReminderQueueUtility{
    private static final String OFFSET_AFTER = 'After';
    private static final String OFFSET_REFERENCE_DAYS = 'Days';
    private static final String RECIPIENT_FIELD_APINAME = 'Recipient Field API Name';
    private static final String RECIPIENTS_SOURCE_CLASS = 'Recipients Source Class';

    /**
 * @description Variable to define whether or not to create a new reminder record, if it already exists.
 *              TAKE_NO_ACTION - Does not create any record.
 *              DEACTIVATE_AND_CREATE_NEW - Deactivates the existing one and creates a new record.
 */
    global enum HandleExistingQueueCriteria {TAKE_NO_ACTION, DEACTIVATE_AND_CREATE_NEW}

    /**
 * @description Global method for validating and creating queue reminder record
 * @param Request wrapper class(RecordId, Reminder Setting Name, Queue Criteria)
 * @return Response wrapper class(Status, Error Message, Queue Record Id)
 */
    global static Response queueReminder(Request queueReminderRequest){
        Response queueReminderResponse = new Response();
        try {
            //Validating Metadata Setting
            PC_ReminderSetting__mdt reminderMetadata = new PC_ReminderSetting__mdt();
            reminderMetadata = [
                    SELECT Id, MasterLabel, DeveloperName, PC_Object_ReminderService__c, PC_MinimumIntervalReminders__c, PC_ParentFieldName__c, PC_RecipientFieldName__c, PC_StartDateOffset__c,
                            PC_ReminderChannel__c, PC_AssignNotificationFieldName__c, PC_ObjectNamespace__c, PC_DueDate_FieldName__c, PC_StartDateOffsetType__c, PC_TemplateName__c,
                            PC_CreateTasksOnFailure__c, PC_ShowSuccessfulRemindersNotifications__c, PC_OtherChannelName__c, PC_RecipientSourceClass__c, PC_RecipientSource__c,
                            PC_StartDateOffsetReference__c, PC_EndDateOffset__c, PC_EndDateOffsetType__c, PC_EndDateOffsetReference__c, PC_MaximumRemindersToBeSent__c
                    FROM PC_ReminderSetting__mdt
                    WHERE DeveloperName =: queueReminderRequest.reminderSettingName
            ];
            if(reminderMetadata == null){
                queueReminderResponse.status = PC_Constants.ERROR;
                queueReminderResponse.errorMessage = System.label.PC_ReminderSettingDoesNotExist;
                return queueReminderResponse;
            }

            //Querying record for which Reminder Queue Record is Created
            String objectName = Id.valueOf(queueReminderRequest.recordId).getSObjectType().getDescribe().getName();
            String queryForRecord = 'SELECT ';
            if(String.isNotBlank(reminderMetadata.PC_DueDate_FieldName__c) && reminderMetadata.PC_DueDate_FieldName__c != null){
                queryForRecord = queryForRecord + reminderMetadata.PC_DueDate_FieldName__c + ',';
            }
            if(reminderMetadata.PC_RecipientSource__c == RECIPIENT_FIELD_APINAME && String.isNotBlank(reminderMetadata.PC_RecipientFieldName__c) && reminderMetadata.PC_RecipientFieldName__c != null){
                queryForRecord = queryForRecord + reminderMetadata.PC_RecipientFieldName__c + ',';
            }
            if(String.isNotBlank(reminderMetadata.PC_AssignNotificationFieldName__c) && reminderMetadata.PC_AssignNotificationFieldName__c != null){
                queryForRecord = queryForRecord + reminderMetadata.PC_AssignNotificationFieldName__c + ',';
            }
            if(String.isNotBlank(reminderMetadata.PC_ParentFieldName__c) && reminderMetadata.PC_ParentFieldName__c != null){
                queryForRecord = queryForRecord + reminderMetadata.PC_ParentFieldName__c;
            }else{
                queryForRecord = queryForRecord + 'ID';
            }
            queryForRecord = queryForRecord + ' FROM ' + objectName + ' WHERE Id = \'' + queueReminderRequest.recordId + '\' LIMIT 1';
            sObject triggeredRecord = Database.query(queryForRecord);

            String reminderQueueId = '';
            List<PC_ReminderQueue__c> existingReminderQueueRecords = new List<PC_ReminderQueue__c>([
                    SELECT Id, PC_Active__c
                    FROM PC_ReminderQueue__c
                    WHERE PC_RecordID__c =: queueReminderRequest.recordId AND PC_Active__c = TRUE AND PC_ReminderSetting__c =: queueReminderRequest.reminderSettingName]);
            List<PC_ReminderQueue__c> createdQueues = new List<PC_ReminderQueue__c>();
            if(existingReminderQueueRecords.isEmpty()){
                createdQueues = createQueuesBasedOnRecipientsSource(reminderMetadata,triggeredRecord,queueReminderRequest);
            }else if(queueReminderRequest.queueCriteria == HandleExistingQueueCriteria.DEACTIVATE_AND_CREATE_NEW){
                for(PC_ReminderQueue__c existingRecord : existingReminderQueueRecords){
                    existingRecord.PC_Active__c = false;
                }
                //Updating existing reminder queue records
                PC_Database.upd(existingReminderQueueRecords, true);
                createdQueues = createQueuesBasedOnRecipientsSource(reminderMetadata,triggeredRecord,queueReminderRequest);
            }
            List<String> queueRecordIds = new List<String>();
            if(!createdQueues.isEmpty()){
                queueRecordIds.addAll(new Map<String,PC_ReminderQueue__c>(createdQueues).keySet());
            }
            queueReminderResponse.queueRecordIds = queueRecordIds;
            queueReminderResponse.status = PC_Constants.SUCCESS;
        }catch(Exception ex){
            queueReminderResponse.status = PC_Constants.ERROR;
            queueReminderResponse.errorMessage = ex.getMessage() + ex.getStackTraceString();
            PC_Utility.createExceptionLog(ex);
        }
        return queueReminderResponse;
    }
/**
 * @description Private method for creating reminder queues based on recipients source in metadata
 * @param PC_ReminderSetting__mdt, sObject, Request
 * @return PC_ReminderQueue__c[]
 */
    private static List<PC_ReminderQueue__c> createQueuesBasedOnRecipientsSource(PC_ReminderSetting__mdt reminderMetadata,sObject triggeredRecord, Request queueReminderRequest){
        List<PC_ReminderQueue__c> queuesToBeCreated = new List<PC_ReminderQueue__c>();
        PC_ReminderQueue.RecipientsResponse recipientsResponse = new PC_ReminderQueue.RecipientsResponse();
        //Get Recipients
        if(reminderMetadata.PC_RecipientSource__c == RECIPIENTS_SOURCE_CLASS){
            if(String.isBlank(reminderMetadata.PC_RecipientSourceClass__c)){
                String sourceClassError = String.format(System.Label.PC_ReminderSourceClassError,
                        new List<Object>{reminderMetadata.MasterLabel});
                throw new PC_ReminderQueueUtilityException(sourceClassError);
            }
            recipientsResponse = getRecipientsFromSourceClass(reminderMetadata,queueReminderRequest);
            for(PC_ReminderQueue.RecordRecipientDetail eachRecordRecipientDetail : recipientsResponse.recordRecipientDetails){
                for(PC_ReminderQueue.RecipientDetail recipient : eachRecordRecipientDetail.recipientDetails){
                    PC_ReminderQueue__c reminderQueueForRecipient = new PC_ReminderQueue__c();
                    reminderQueueForRecipient = getQueueRecord(triggeredRecord, reminderMetadata, eachRecordRecipientDetail.recordId);
                    reminderQueueForRecipient.PC_Recipient__c = JSON.serialize(recipient);
                    queuesToBeCreated.add(reminderQueueForRecipient);
                }
            }
        }else{
            PC_ReminderQueue__c reminderQueue = new PC_ReminderQueue__c();
            reminderQueue = getQueueRecord(triggeredRecord,reminderMetadata,queueReminderRequest.recordId);
            queuesToBeCreated.add(reminderQueue);
        }
        if(!queuesToBeCreated.isEmpty()){
            PC_Database.ins(queuesToBeCreated,true);
        }else{
            throw new PC_ReminderQueueUtilityException(System.Label.PC_NoReminderQueuesCreatedError);
        }
        return queuesToBeCreated;
    }

/**
 * @description Private method for getting recipients from mentioned source class in metadata
 * @param PC_ReminderSetting__mdt,String
 * @return PC_ReminderQueue.RecipientsResponse
 */
    private static PC_ReminderQueue.RecipientsResponse getRecipientsFromSourceClass(PC_ReminderSetting__mdt reminderMetadata, Request queueReminderRequest){
        PC_ReminderQueue.RecipientsResponse recipientsResponse = new PC_ReminderQueue.RecipientsResponse();
        Type t = Type.forName(reminderMetadata.PC_RecipientSourceClass__c);
        if (t != null){
            Object o = t.newInstance();
            if (o instanceof PC_ReminderQueue.RecipientFinder){
                List<PC_ReminderQueue.RecordDetail> recordDetails = new List<PC_ReminderQueue.RecordDetail>();
                PC_ReminderQueue.RecordDetail recordDetail = new PC_ReminderQueue.RecordDetail();
                recordDetail.recordId = queueReminderRequest.recordId;
                recordDetails.add(recordDetail);
                PC_ReminderQueue.RecipientsRequest recipientsRequest = new PC_ReminderQueue.RecipientsRequest();
                recipientsRequest.recordDetails = recordDetails;
                recipientsRequest.setting = reminderMetadata;
                PC_ReminderQueue.RecipientFinder getRecipientsClass = (PC_ReminderQueue.RecipientFinder) o;
                recipientsResponse = getRecipientsClass.getRecipients(recipientsRequest);
            }else{
                String recipientsClassError = String.format(System.Label.PC_RecipientsClassError,
                        new List<Object>{reminderMetadata.PC_RecipientSourceClass__c});
                throw new PC_ReminderQueueUtilityException(recipientsClassError);
            }
        }else{
            String classNotFoundError = String.format(System.Label.PC_ClassNotFoundError,
                    new List<Object>{reminderMetadata.PC_RecipientSourceClass__c});
            throw new PC_ReminderQueueUtilityException(classNotFoundError);
        }
        return recipientsResponse;
    }


    /**
 * @description Private method for creating queue reminder record
 * @param sObject,PC_ReminderSetting__mdt,String
 * @return String
 */
    private static PC_ReminderQueue__c getQueueRecord(sObject triggeredRecord, PC_ReminderSetting__mdt reminderMetadata, String recordId){
        //Creating Reminder Queue Record
        PC_ReminderQueue__c reminderQueue = new PC_ReminderQueue__c();
        reminderQueue.PC_DueDate__c = (Datetime)triggeredRecord.get(reminderMetadata.PC_DueDate_FieldName__c);
        if(reminderQueue.PC_DueDate__c == null){
            String exceptionMessage = String.format(System.Label.PC_DueDateBlankError,
                    new List<Object>{reminderMetadata.PC_DueDate_FieldName__c});
            throw new PC_ReminderQueueUtilityException(exceptionMessage);
        }
        if(reminderMetadata.PC_ReminderChannel__c == PC_Constants.PC_OTHER && String.isNotBlank(reminderMetadata.PC_OtherChannelName__c)) {
            reminderQueue.PC_ReminderChannel__c = reminderMetadata.PC_OtherChannelName__c;
        }else{
            reminderQueue.PC_ReminderChannel__c = reminderMetadata.PC_ReminderChannel__c;
        }
        if(String.isNotBlank(reminderMetadata.PC_ParentFieldName__c)){
            reminderQueue.PC_ParentReferenceRecordID__c = String.valueOf(triggeredRecord.get(reminderMetadata.PC_ParentFieldName__c));
        }else{
            reminderQueue.PC_ParentReferenceRecordID__c = String.valueOf(triggeredRecord.get('Id'));
        }
        reminderQueue.PC_Active__c = true;
        reminderQueue.PC_ReminderSetting__c = reminderMetadata.DeveloperName;
        reminderQueue.PC_RecordID__c = recordId;
        String recipientFieldName = reminderMetadata.PC_RecipientFieldName__c;
        if(reminderMetadata.PC_RecipientSource__c == RECIPIENT_FIELD_APINAME && String.isNotBlank(recipientFieldName)){
            if(recipientFieldName.contains('.')){
                List<String> objectRelationshipsList = recipientFieldName.split('\\.');
                sObject finalObject = triggeredRecord;
                for(Integer i=0; i< (objectRelationshipsList.size() - 1); i++){
                    finalObject = finalObject.getSObject(objectRelationshipsList[i]);
                }
                reminderQueue.PC_Recipient__c = String.valueOf(finalObject.get(objectRelationshipsList[objectRelationshipsList.size() - 1]));
            }else{
                reminderQueue.PC_Recipient__c = String.valueOf(triggeredRecord.get(reminderMetadata.PC_RecipientFieldName__c));
            }
        }
        if(String.isNotBlank(reminderMetadata.PC_AssignNotificationFieldName__c)){
            String assignNotificationFieldName = reminderMetadata.PC_AssignNotificationFieldName__c;
            if(assignNotificationFieldName.contains('.')){
                List<String> relationshipsList = assignNotificationFieldName.split('\\.');
                sObject finalObject = triggeredRecord;
                for(Integer i=0; i< (relationshipsList.size() - 1); i++){
                    finalObject = finalObject.getSObject(relationshipsList[i]);
                }
                reminderQueue.PC_AssignNotificationToUser__c = String.valueOf(finalObject.get(relationshipsList[relationshipsList.size() - 1]));
            }else{
                reminderQueue.PC_AssignNotificationToUser__c = String.valueOf(triggeredRecord.get(reminderMetadata.PC_AssignNotificationFieldName__c));
            }
        }

        if(reminderMetadata.PC_MinimumIntervalReminders__c <= 0.0){
            String errorMessage = String.format(System.Label.PC_MinimumIntervalInvalidError,
                    new List<Object>{reminderMetadata.DeveloperName});
            throw new PC_ReminderQueueUtilityException(errorMessage);
        }else{
            //Calculating number of reminders to be sent
            Datetime startDatetime = PC_BatchUtility.getDatetime(reminderQueue.PC_DueDate__c,Integer.valueOf(reminderMetadata.PC_StartDateOffset__c),reminderMetadata.PC_StartDateOffsetType__c,reminderMetadata.PC_StartDateOffsetReference__c);
            Datetime endDatetime   = PC_BatchUtility.getDatetime(reminderQueue.PC_DueDate__c,Integer.valueOf(reminderMetadata.PC_EndDateOffset__c),reminderMetadata.PC_EndDateOffsetType__c,reminderMetadata.PC_EndDateOffsetReference__c);
            Integer numberOfReminders = getNumberOfReminders(startDatetime,endDatetime,reminderMetadata.PC_MinimumIntervalReminders__c);
            reminderQueue.PC_RemindersToBeSent__c = numberOfReminders < Integer.valueOf(reminderMetadata.PC_MaximumRemindersToBeSent__c) ? numberOfReminders : Integer.valueOf(reminderMetadata.PC_MaximumRemindersToBeSent__c);
        }
        return reminderQueue;
    }


    private static Integer getNumberOfReminders(Datetime startDatetime, Datetime endDatetime, Decimal minimumInterval){
        Integer numberOfReminders;
        numberOfReminders = Integer.valueOf(((endDatetime.getTime() - startDatetime.getTime())/(1000*60)) / (minimumInterval * 60));
        return numberOfReminders;
    }
    /**
     * Request for creating reminder queue record
     */
    global inherited sharing class Request{
        /**
         * ID of the record for which the queue record is created
         */
        global String recordId{get;set;}
        /**
         * Developer Name of the Custom Metadata(Reminder Object Setting) Record
         */
        global String reminderSettingName{get;set;}
        /**
         * Criteria to define whether or not to create a new reminder record, if it already exists.
         */
        global HandleExistingQueueCriteria queueCriteria{get;set;}
        global Request(){}
    }
    /**
     * Response for the successful/failure of queue record creation
     */
    global inherited sharing class Response{
        /**
         * ID of the record for which the queue record(s) is created
         */
        global String recordId{get;set;}
        /**
         * Notifies if the reminder queue record was created successfully or not
         */
        global String status{get;set;}
        /**
         * Message if the code execution has failed.
         */
        global String errorMessage{get;set;}
        /**
         * The ID of reminder queue record that was created.
         */
        global String queueRecordId{get;set;} //queueRecordId is retained for backward compatibility purposes.

        /**
         * The IDs of reminder queue records that are created.
         */
        global List<String> queueRecordIds{get;
            set{
                if(queueRecordIds != null && queueRecordIds.size() == 1){
                    queueRecordId = queueRecordIds[0];
                }else{
                    queueRecordIds = value;
                    queueRecordId = '';
                }
            }
        }
        /**
         * Additional Task Comments if any for the reminder queue record(s) that are created.
         */
        global String additionalComments{get;set;}
        global Response(){
            queueRecordIds = new List<String>();
            queueRecordId = '';
        }
    }
    public inherited sharing class PC_ReminderQueueUtilityException extends Exception{}
    public inherited sharing class QueueReminderSetting{
        public String reminderChannel{get;set;}
        public String reminderSettingName{get;set;}
        public String handleExistingQueueCriteria{get;set;}
    }
}