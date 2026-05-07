/*************************************************************************************
Source - https://github.com/vipultaylor/sf-activity-timeline
Class Name          : PC_DynamicActivityTimelineController
Description         : Controller for PC_DynamicActivityTimeline aura component.This controller also works for other objects
                      like Documents, Accounts (Objects that are supported in Related To field of Task)
CreatedBy           : Deloitte
Created Date        : 1 March 2021
Modification Log    :
*****************************************************************************************************
Developer                   Date                   Description
****************************************************************************************************
Kanteti Kishore            1 March 2021           Initial version[PC-7427]
Haritha Reddy              19 Oct  2022           PC-9273: Updated logic to sort activities based on last modified date when due date is not available
*****************************************************************************************************/
public with sharing class PC_DynamicActivityTimelineController{

    private static final String PC_EMAIL = 'Email';
    private static final String PC_EVENT = 'Event';
    private static final String FROM_ADDRESS = 'FromAddress';
    private static final String TO_ADDRESS = 'ToAddress';


    @AuraEnabled
    public static List<PC_DynamicActivityTimelineGroup> getActivityTimeline(Id recordId, Boolean includeChildren){
        List<PC_DynamicActivityTimelineGroup> timelineGroups = new List<PC_DynamicActivityTimelineGroup>();
        try {
            //Find out the Sobject type of the recordId passed
            Schema.SObjectType sobjType = recordId.getSobjectType();

            Set<Id> whatIdSet = new Set<Id>();
            Set<Id> whoIdSet = new Set<Id>();

            //Add the record passed
            if (sobjType == Schema.Contact.SObjectType) {
                whoIdSet.add(recordId);
            } else {
                whatIdSet.add(recordId);
            }
            //Include children boolean value will be always false for release 13.1 hence commenting below lines
            //Process Accounts
            /*if (sobjType == Schema.Account.SObjectType) {
                //Process Other 'Child' Objects
                if (includeChildren) {
                    //Contacts
                    Map<Id, Contact> mapDirectContacts = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId = :recordId]);
                    whoIdSet.addAll(mapDirectContacts.keySet());

                    //Opportunities
                    Map<Id, Opportunity> mapDirectOpportunities = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE AccountId = :recordId]);
                    whatIdSet.addAll(mapDirectOpportunities.keySet());

                    //Cases
                    Map<Id, Case> mapDirectCases = new Map<Id, Case>([SELECT Id FROM Case WHERE AccountId = :recordId]);
                    whatIdSet.addAll(mapDirectCases.keySet());
                }
            }*/

            // Create a return List
            List<PC_DynamicActivityTimelineModel> lstAllActivities = new List<PC_DynamicActivityTimelineModel>();

            // Add Tasks, Emails & Events
            addTasksAndEmails(lstAllActivities, recordId, whatIdSet, whoIdSet);
            addEvents(lstAllActivities, recordId, whatIdSet, whoIdSet);
            timelineGroups = generateGroups(lstAllActivities);
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return timelineGroups;
    }

    private static List<PC_DynamicActivityTimelineGroup> generateGroups(List<PC_DynamicActivityTimelineModel> lstAllActivities) {
        // Sort List
        lstAllActivities.sort();

        //Filter Out Open Tasks & Activties
        List<PC_DynamicActivityTimelineModel> lstOpenActivities = new List<PC_DynamicActivityTimelineModel>();
        for(PC_DynamicActivityTimelineModel item : lstAllActivities){
            if(!item.isComplete){
                lstOpenActivities.add(item);
            }
        }

        //Prepare Map of grouped activities
        Map<Long, List<PC_DynamicActivityTimelineModel>> mapActivityTimeline = new Map<Long, List<PC_DynamicActivityTimelineModel>>();
        for(PC_DynamicActivityTimelineModel item : lstAllActivities){
            //Only Completed items
            if(item.isComplete){
                List<PC_DynamicActivityTimelineModel> lstActivities = new List<PC_DynamicActivityTimelineModel>();
                DateTime firstDayOfMonth;
                if(item.activityDate != null ){
                    firstDayOfMonth = Datetime.newInstance(item.activityDate.year(), item.activityDate.month(), 1, 0, 0, 0);
                }else{
                    firstDayOfMonth = Datetime.newInstance(item.LastModifiedDate.year(), item.LastModifiedDate.month(), 1, 0, 0, 0);
                }
                Long mapKey = firstDayOfMonth.getTime();
                if(mapActivityTimeline.containsKey(mapKey)){
                    lstActivities = mapActivityTimeline.get(mapKey);
                }

                lstActivities.add(item);
                mapActivityTimeline.put(mapKey, lstActivities);
            }
        }

        List<PC_DynamicActivityTimelineGroup> lstActivityGroups = new List<PC_DynamicActivityTimelineGroup>();
        //Open Activities
        lstActivityGroups.add(new PC_DynamicActivityTimelineGroup(System.Label.PC_Upcoming_Overdue, lstOpenActivities));

        //Closed Activities
        For(Long dateAsLong: mapActivityTimeline.keySet()){
            PC_DynamicActivityTimelineGroup activityGroup = new PC_DynamicActivityTimelineGroup(dateAsLong, mapActivityTimeline.get(dateAsLong));
            lstActivityGroups.add(activityGroup);
        }

        return lstActivityGroups;
    }


    private static void addTasksAndEmails(List<PC_DynamicActivityTimelineModel> returnList, Id recordId, Set<Id> whatIdSet, Set<Id> whoIdSet){

        //FLS Check
        List<String> taskFields = new List<String>{'Id', 'RecordTypeId', 'ActivityDate', 'lastModifiedDate', 'Description', 'IsRecurrence', 'OwnerId', 'Owner.Name', 'Priority',
                'Status', 'Subject', 'TaskSubtype', 'Type', 'WhatId', 'What.Name', 'WhoId', 'Who.Name'};
        PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, taskFields);

        List<Task> taskList = [SELECT Id, RecordTypeId, ActivityDate,lastModifiedDate, Description, IsRecurrence, OwnerId, Owner.Name, Priority, Status, Subject,
                TaskSubtype, Type, WhatId, What.Name, WhoId, Who.Name
        FROM Task
        WHERE WhatId IN: whatIdSet OR WhoId IN: whoIdSet
        ORDER BY ActivityDate DESC NULLS FIRST];

        //generate a map of Task Status to get Closed Status
        Map<String, TaskStatus> mapTaskStatus = new Map<String, TaskStatus>();
        for(TaskStatus ts: [SELECT MasterLabel, IsClosed FROM TaskStatus]){
            mapTaskStatus.put(ts.MasterLabel, ts);
        }

        //generate a map of Task Priority to get High Priority
        Map<String, TaskPriority> mapTaskPriority = new Map<String, TaskPriority>();
        for(TaskPriority tp: [SELECT MasterLabel, IsHighPriority FROM TaskPriority]){
            mapTaskPriority.put(tp.MasterLabel, tp);
        }

        //generate a map of Email tasks
        //The Enhanced Emails are stored in the Email Message object but they have a corresponding Task with SubType Email.
        //You need to filter those out in order to prevent duplicate records being displayed
        Map<Id, Task> mapEmailTasks = new Map<Id, Task>();

        if(taskList.size() > 0) {
            for(Task taskObj: taskList) {
                if(taskObj.TaskSubtype == PC_EMAIL && String.isBlank(taskObj.RecordTypeId)){
                    //Collect tasks for handling email messages separately
                    mapEmailTasks.put(taskObj.Id, taskObj);
                } else {
                    PC_DynamicActivityTimelineModel taskItem = new PC_DynamicActivityTimelineModel();

                    taskItem.recordId = taskObj.Id;
                    taskItem.sobjectName = String.valueOf(Task.SobjectType);
                    taskItem.activityTimelineType = taskObj.TaskSubtype;
                    taskItem.activityDate = taskObj.ActivityDate;
                    taskItem.lastModifiedDate = taskObj.lastModifiedDate;
                    taskItem.subject = taskObj.Subject;
                    taskItem.detail = taskObj.Description;

                    //Assigned To
                    taskItem.assignedTo = new PC_DynamicActivityTimelineModel.RecordReference(taskObj.OwnerId, taskObj.Owner.Name);

                    //Recipients
                    if(String.isNotEmpty(taskObj.WhoId)){
                        //Dont add the current record in Task Contact
                        if(taskObj.WhoId != recordId){
                            taskItem.recipients = new List<PC_DynamicActivityTimelineModel.RecordReference>();
                            taskItem.recipients.add(new PC_DynamicActivityTimelineModel.RecordReference(taskObj.WhoId, taskObj.Who.Name));
                        }
                    }

                    //Related To
                    if(String.isNotEmpty(taskObj.WhatId)){
                        //Dont add the current record in related to
                        if(taskObj.WhatId != recordId){
                            taskItem.relatedTo = new PC_DynamicActivityTimelineModel.RecordReference(taskObj.WhatId, taskObj.What.Name);
                        }
                    }

                    taskItem.isComplete = mapTaskStatus.get(taskObj.Status).IsClosed;
                    taskItem.isOverdue = taskObj.ActivityDate < Date.today() && !taskItem.isComplete;
                    taskItem.isRecurring = taskObj.IsRecurrence;
                    taskItem.isPriority = mapTaskPriority.get(taskObj.Priority).IsHighPriority;

                    returnList.add(taskItem);
                }
            }

            //Process Email Tasks
            if(mapEmailTasks.size() > 0){
                //FLS Check on Email Message
                List<String> emailMessageFields = new List<String>{'Id', 'ActivityDate', 'HasAttachment', 'IsRecurrence',
                        'MessageDate', 'Status', 'Subject', 'TextBody'};
                PC_Database.assertAccess(PC_Constants.PC_EMAIL_MESSAGE,PC_Database.Operation.Reading, emailMessageFields);

                //FLS Check on Email Message Relations
                List<String> emailMessageRelationFields = new List<String>{'Id', 'RelationType', 'RelationId', 'Relation.Name', 'RelationAddress'};
                PC_Database.assertAccess(PC_Constants.PC_EMAIL_MESSAGE_RELATION,PC_Database.Operation.Reading,emailMessageRelationFields);

                List<EmailMessage> lstEmailMessages = [SELECT Id, ActivityId, HasAttachment, MessageDate, Status, Subject, TextBody,
                (SELECT Id, RelationType, RelationId, Relation.Name, RelationAddress
                FROM EmailMessageRelations)
                FROM EmailMessage
                WHERE ActivityId IN: mapEmailTasks.keySet()];
                For(EmailMessage emailMsg : lstEmailMessages){
                    Task taskObj = mapEmailTasks.get(emailMsg.ActivityId);

                    PC_DynamicActivityTimelineModel emailItem = new PC_DynamicActivityTimelineModel();

                    emailItem.recordId = emailMsg.Id;
                    emailItem.sobjectName = String.valueOf(EmailMessage.SobjectType);
                    emailItem.activityTimelineType = PC_EMAIL;
                    emailItem.activityDate = emailMsg.MessageDate;
                    emailItem.subject = emailMsg.Subject;
                    emailItem.detail = emailMsg.TextBody;

                    //Assigned To & Recipients
                    emailItem.recipients = new List<PC_DynamicActivityTimelineModel.RecordReference>();
                    For(EmailMessageRelation relationObj : emailMsg.EmailMessageRelations){
                        //Assigned To
                        if(relationObj.RelationType == FROM_ADDRESS){
                            if(String.isNotEmpty(relationObj.relationId)){
                                emailItem.assignedTo = new PC_DynamicActivityTimelineModel.RecordReference(relationObj.relationId, relationObj.Relation.Name);
                            } else {
                                emailItem.fromEmail = new PC_DynamicActivityTimelineModel.EmailReference(relationObj.RelationAddress);
                            }
                        } else if(relationObj.RelationType == TO_ADDRESS){
                            if(String.isNotEmpty(relationObj.relationId)){
                                emailItem.recipients.add(new PC_DynamicActivityTimelineModel.RecordReference(relationObj.relationId, relationObj.Relation.Name));
                            } else {
                                emailItem.toEmail = new PC_DynamicActivityTimelineModel.EmailReference(relationObj.RelationAddress);
                            }
                        }
                    }

                    //Related To
                    if(String.isNotEmpty(taskObj.WhatId)){
                        //Dont add the current record in Related To
                        if(taskObj.WhatId != recordId){
                            emailItem.relatedTo = new PC_DynamicActivityTimelineModel.RecordReference(taskObj.WhatId, taskObj.What.Name);
                        }
                    }

                    emailItem.isComplete = true;
                    emailItem.hasAttachments = emailMsg.HasAttachment;

                    returnList.add(emailItem);
                }
            }
        }
    }

    private static void addEvents(List<PC_DynamicActivityTimelineModel> returnList, Id recordId, Set<Id> whatIdSet, Set<Id> whoIdSet) {

        //FLS Check
        List<String> eventFields = new List<String>{'Id', 'ActivityDate', 'Description', 'IsRecurrence', 'OwnerId', 'Owner.Name', 'EndDateTime',
                 'Subject', 'EventSubtype', 'Type', 'WhatId', 'What.Name', 'WhoId', 'Who.Name', 'StartDateTime'
        };
        PC_Database.assertAccess(PC_Constants.PC_EVENT,PC_Database.Operation.Reading, eventFields);

        List<Event> eventList = [SELECT Id, ActivityDate, Description, EndDateTime, EventSubtype, IsRecurrence, OwnerId, Owner.Name,
                StartDateTime, Subject, Type, WhatId, What.Name, WhoId, Who.Name
        FROM Event
        WHERE WhatId IN: whatIdSet OR WhoId IN: whoIdSet];

        if(eventList.size() > 0) {
            for(Event eventObj: eventList){
                PC_DynamicActivityTimelineModel eventItem = new PC_DynamicActivityTimelineModel();

                eventItem.recordId = eventObj.Id;
                eventItem.sobjectName = String.valueOf(Event.SobjectType);
                eventItem.activityTimelineType = PC_EVENT;
                eventItem.activityDate = eventObj.ActivityDate;
                eventItem.subject = eventObj.Subject;
                eventItem.detail = eventObj.Description;

                //Assigned To
                eventItem.assignedTo = new PC_DynamicActivityTimelineModel.RecordReference(eventObj.OwnerId, eventObj.Owner.Name);

                //Recipients
                if(String.isNotEmpty(eventObj.WhoId)){
                    if(eventObj.WhoId != recordId){
                        eventItem.recipients = new List<PC_DynamicActivityTimelineModel.RecordReference>();
                        eventItem.recipients.add(new PC_DynamicActivityTimelineModel.RecordReference(eventObj.WhoId, eventObj.Who.Name));
                    }
                }

                //Related To
                if(String.isNotEmpty(eventObj.WhatId)){
                    if(eventObj.WhatId != recordId){
                        eventItem.relatedTo = new PC_DynamicActivityTimelineModel.RecordReference(eventObj.WhatId, eventObj.What.Name);
                    }
                }

                eventItem.startDateTime = eventObj.StartDateTime;
                eventItem.endDateTime = eventObj.EndDateTime;
                eventItem.isComplete = eventObj.StartDateTime < System.now();

                returnList.add(eventItem);
            }
        }
    }
}