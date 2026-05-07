/*************************************************************************************
Source - https://github.com/vipultaylor/sf-activity-timeline
Class Name          : PC_Test_DynamicActivityTimelineCntlr
Description         : Test Class for PC_DynamicActivityTimeline controller.
CreatedBy           : Deloitte
Created Date        : 1 March 2021
Modification Log    :
*****************************************************************************************************
Developer                   Date                   Description
****************************************************************************************************
Kanteti Kishore            1 March 2021           Initial version[PC-7427]
Haritha Reddy              19 Oct  2022           PC-9273: Added task with no due date
*****************************************************************************************************/
@IsTest
private class PC_Test_DynamicActivityTimelineCntlr{
    private static User FRM_USER;
    private static String FRM_PROFILE = 'PC FRM User';
    private static String USER_NAME = 'testfrmuser@test.com';
    private static String ALIAS = 'testUser';
    private static String FROM_ADDRESS = 'FromAddress';
    private static String TO_ADDRESS = 'ToAddress';
    private static integer TASK_COUNT = 5;
    private static integer CALL_COUNT = 5;
    private static integer EVENT_COUNT = 5;
    private static integer EMAIL_COUNT = 5;
    private static integer NO_DUE_DATE_TASK_COUNT = 1;

    @testSetup static void setup(){

        //Insert User
        FRM_USER = PC_Test_Setup.createUser(FRM_PROFILE, USER_NAME, ALIAS);
        PC_Database.ins(FRM_USER);
        //Assigning Permission Set
        PC_Test_Setup.assignFRMUserPermissionSet(FRM_USER.Id);

        System.runAs(FRM_USER){
            //Insert Accounts
            List<Account> lstAccounts = new List<Account>();
            lstAccounts = PC_Test_Setup.createAccounts('Patient', 1, PC_Constants.PATIENT_RECORD_TYPE);
            insert lstAccounts;

            //Insert Activities
            //Add Tasks
            List<Task> lstTasks = new List<Task>();
            lstTasks.addAll(addTasks(TASK_COUNT, 'Task', lstAccounts[0].Id, null,FRM_USER.Id));
            lstTasks.addAll(addTasks(CALL_COUNT, 'Call', lstAccounts[0].Id, null,FRM_USER.Id));
            insert lstTasks;

            //Insert task with no due date
            Task noDueDateTask = new Task();
            noDueDateTask.Subject = 'Test Task with no due date';
            noDueDateTask.TaskSubType = 'Call';
            noDueDateTask.Description = 'Test task Description with no due date';
            noDueDateTask.OwnerId = FRM_USER.Id;
            noDueDateTask.WhatId = lstAccounts[0].Id;
            noDueDateTask.ActivityDate = null;
            insert noDueDateTask;

            //Add Events
            List<Event> lstEvents = new List<Event>();
            lstEvents.addAll(PC_Test_Setup.createEvents(EVENT_COUNT, lstAccounts[0].Id, null));
            insert lstEvents;

            //Add Emails
            insertEmails(EMAIL_COUNT, lstAccounts[0].Id, null);
        }
    }



    @IsTest
    private static void testGetActivityTimeline(){
        List<Account> lstAccounts = [SELECT Id FROM Account];
        FRM_USER = [SELECT Id FROM User WHERE username =: USER_NAME][0];
        System.runAs(FRM_USER) {
            Test.startTest();
            List<PC_DynamicActivityTimelineGroup> groups = PC_DynamicActivityTimelineController.getActivityTimeline(lstAccounts[0].Id, false);
            //Calculate the months for the closed task groupings
            System.assertEquals(2, groups.size());

            List<PC_DynamicActivityTimelineModel> lstActivities = new List<PC_DynamicActivityTimelineModel>();
            for (PC_DynamicActivityTimelineGroup groupObj : groups) {
                lstActivities.addAll(groupObj.items);
            }
            System.assertEquals(TASK_COUNT + CALL_COUNT + EVENT_COUNT + EMAIL_COUNT + NO_DUE_DATE_TASK_COUNT , lstActivities.size());

            Test.stopTest();
        }
    }

    private static List<Task> addTasks(Integer numberOfTasks, String subType, Id whatId, Id whoId, Id AssignedTo){
        List<Task> lstTasks = PC_Test_Setup.createTasks(whatId,numberOfTasks);
        Integer i = 1;
        For(Task eachTask : lstTasks) {
            eachTask.Subject = 'Test Subject (' + subType + ') ' + i;
            eachTask.TaskSubType = subType;
            eachTask.ActivityDate = Date.today();
            eachTask.PC_Original_Due_Date__c = Date.today();
            eachTask.Description = 'Test Description ' + i;
            eachTask.OwnerId = AssignedTo;
            if(whoId != null){
                eachTask.WhoId = whoId;
            }
            i++;
        }
        return lstTasks;
    }
    private static void insertEmails(Integer numberOfEmails, Id whatId, Id whoId){
        List<EmailMessage> lstEmails = PC_Test_Setup.createEmailMessages(numberOfEmails, whatId);
        insert lstEmails;

        List<EmailMessageRelation> lstRelations = PC_Test_Setup.createEmailMessageRelations(lstEmails,whoId,FROM_ADDRESS);
        List<EmailMessageRelation> lstToRelations = PC_Test_Setup.createEmailMessageRelations(lstEmails,whoId,TO_ADDRESS);
        lstRelations.addAll(lstToRelations);
        insert lstRelations;
    }
}