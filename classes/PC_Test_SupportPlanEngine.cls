/**************************************************************************************
Apex Class Name     : PC_Test_SupportPlanEngine
Description         : This class is used for testing PC_SupportPlanEngine;
CreatedBy           : Sahil Garg
Created Date        : 12 Mar 2018
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Sahil Garg                 12 Mar 2018           Initial version
Tejas Patel                1 Mar 2019            New Test Methods added
Tushar Arora               Jun 26, 2019          [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Tejas Patel                18-Oct-2019           PC-5575 Test start-stop encapsulates case creation to handle future method callout and return
Haritha Reddy			   16 Apr,2020			 [PC-6033] Test methods modified
Haritha Reddy             10 Nov, 2020          [PC-6893] Added date field mapping to check Formula calculation, Added asserts to check log creation
Haritha Reddy             11 Nov, 2020          [PC-6938] Added a test method to verify Support plan behaviour
Haritha Reddy             16 Mar, 2021          [PC-7530] Added a test method to verify Support plan processing when huge number of runtimes exist in system
Haritha Reddy             05 Apr, 2021          [PC-6629] Added test method to check evaluation of Contains and does not contains condition
Hitha Avalakki            10 May,2021           [PC-7666] Addec code to test date and datetime values via formula for user task
Hitha Avalakki            31 Aug,2021           [PC-8089] Added code to test task reparenting logic for Service case with and without parent case and support plan for Interaction record with Parent case.
Hitha Avalakki            20 Oct,2021           [PC-8139] Added code to create task related user task fields' string required for Support plan execution
Haritha Reddy             24-Nov-2021           [PC-8361] Added test method to ensure duplicate tasks are not getting created when bulk case insert is done with multiple engagement programs.
Haritha Reddy             19-Jan-2022           [PC-8454] Added test method to ensure that SPA Criteria is evaluated when trigger object and Previous activity object type are same.
*************************************************************************************/

@isTest(seeAllData=false)
public with sharing class PC_Test_SupportPlanEngine {
    private static User adminUser;
    private static User careCoordinator;
    private static Case programCase,programCase1,programCase2;
    private static Case casetestDueDate;
    private static Account patient;
    private static Account  manufacturer;
    private static PC_SupportPlan__c supportPlan1;
    private static PC_SupportPlan__c supportPlan2;
    private static PC_SupportPlan__c bulkSupportPlan1,bulkSupportPlan2;
    private static PC_SupportPlanActivity__c bulkSupPlanActy1,bulkSupPlanActy2;
    private static PC_SupportPlanActivity__c supPlanActy1,supPlanActy2,supPlanActy3,supPlanActy4;
    private static PC_SupportPlanActivity__c supPlanGrp1,supPlanGrp1Acty1,supPlanGrp1Acty2;
    private static PC_SupportPlanActivity__c supPlanGrp2,supPlanGrp2Acty1,supPlanGrp2Acty2;
    private static PC_Engagement_Program__c enmtProgram,enmtProgram1,enmtProgram2;
    private static PC_EngagementProgram_SupportPlan__c enmtPgmSupPlan,enmtPgm1SupPlan1,enmtPgm1SupPlan2,enmtPgm2SupPlan2;
    private static Task outcomeTask;
    private static String INTERACTION_SOBJECT_NAME = 'PC_Interaction__c';
    private static Map<String, PC_AutomationTaskHelper.FieldMap> userTaskFieldsLabelMap;
    private static String triggerObjectType='PC_Message__c';
    private static List<Schema.SObjectType> objectsWithActivitiesEnabled;
            /*********************************************************************************
            Method Name    : createTestData
            Author         : Haritha Reddy
            Description    : This method is used for creating test data
            Return Type    : void
            *********************************************************************************/
    
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);
        
        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t2.com', 'test2');
        careCoordinator = (User) PC_Database.ins(careCoordinator);
        
        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);
        
        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);
        
        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram('TestPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c = 'TestPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);
        
        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c = enmtProgram.Id;
        programCase.PC_Care_Coordinator__c      =   careCoordinator.Id;
        programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase.PC_Treatment_Start_Date__c = date.today();
        programCase.IsEscalated = false;
        programCase.HealthCloudGA__FinancialValue__c = 10;
        programCase = (Case)PC_Database.ins(programCase, false);
        programCase.PC_Approval_Denial_Date__c = date.today();
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);
        
        //Create Support Plan
        supportPlan1= PC_Test_Setup.createSupportPlan();
        supportPlan1.PC_IsActive__c=true;
        supportPlan1.PC_TriggerEventObject__c='Case';
        supportPlan1.PC_TriggerEventType__c='Insert/Update';
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1.PC_SupportPlan_Behavior__c=String.valueOf(PC_Constants.SupportPlanBehaviour.RunOncePerRecord);
        supportPlan1 = (PC_SupportPlan__c) PC_Database.ins(supportPlan1, false);

        //Create Support Plan for Interaction object
        supportPlan2= PC_Test_Setup.createSupportPlan();
        supportPlan2.Name = 'TestInteractionSupPlan';
        supportPlan2.PC_IsActive__c=true;
        supportPlan2.PC_TriggerEventObject__c=PC_Constants.getQualifiedAPIName('PC_Interaction__c');
        supportPlan2.PC_TriggerEventType__c='Insert/Update';
        supportPlan2.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan2.PC_SupportPlan_Behavior__c=String.valueOf(PC_Constants.SupportPlanBehaviour.RunOncePerRecord);
        supportPlan2 = (PC_SupportPlan__c) PC_Database.ins(supportPlan2, false);
        
        //Create Support Plan Activity1
        supPlanActy1= PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);
        //Create Support Plan Activity2
        supPlanActy2= PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Program Coverage');
        supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);
        //Create Support Plan Activity3
        supPlanActy3= PC_Test_Setup.createPublishPlatformEventSPA('Activity 3: Publish Platform Event');
        supPlanActy3 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy3, false);

        //Create Support Plan Group 1
        supPlanGrp1= PC_Test_Setup.createSupportPlanGroup('SupportPlan Group 1');
        supPlanGrp1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanGrp1, false);

        //Create Support Plan Group 2
        supPlanGrp2= PC_Test_Setup.createSupportPlanGroup('SupportPlan Group 2');
        supPlanGrp2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanGrp2, false);

        //Create Support Plan Group 1 Activity 1
        supPlanGrp1Acty1= PC_Test_Setup.createSupportPlanGroupActivity('SupportPlan Group 1 Activity 1');
        supPlanGrp1Acty1.PC_ActivitySequence__c = supPlanGrp1.Id;
        supPlanGrp1Acty1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanGrp1Acty1, false);

        //Create Support Plan Group 2 Activity 1
        supPlanGrp2Acty1= PC_Test_Setup.createSupportPlanGroupActivity('SupportPlan Group 2 Activity 1');
        supPlanGrp2Acty1.PC_ActivitySequence__c = supPlanGrp2.Id;
        supPlanGrp2Acty1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanGrp2Acty1, false);

        //Create Support Plan Group 1 Activity 2
        supPlanGrp1Acty2= PC_Test_Setup.createSupportPlanGroupActivity('SupportPlan Group 1 Activity 2');
        supPlanGrp1Acty2.PC_ActivitySequence__c = supPlanGrp1.Id;
        supPlanGrp1Acty2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanGrp1Acty2, false);

        //Create Support Plan Group 2 Activity 2
        supPlanGrp2Acty2= PC_Test_Setup.createSupportPlanGroupActivity('SupportPlan Group 2 Activity 2');
        supPlanGrp2Acty2.PC_ActivitySequence__c = supPlanGrp2.Id;
        supPlanGrp2Acty2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanGrp2Acty2, false);

        //Create Engagement Program Support Plan Junction Object
        enmtPgmSupPlan= PC_Test_Setup.createEnggmtPgmSupPlan();
        enmtPgmSupPlan.PC_EngagementProgram__c=enmtProgram.Id;
        enmtPgmSupPlan.PC_SupportPlan__c=supportPlan1.Id;
        enmtPgmSupPlan = (PC_EngagementProgram_SupportPlan__c)PC_Database.ins(enmtPgmSupPlan, false);

        PC_AutomationTaskHelper.FormulaValue formulaValue =  new PC_AutomationTaskHelper.FormulaValue();
        PC_AutomationTaskHelper.FieldMap fieldMap;
        userTaskFieldsLabelMap = new Map<String, PC_AutomationTaskHelper.FieldMap>();

        Map<String,Object> formulaValueMap = new Map<String, Object>();

        fieldMap = new PC_AutomationTaskHelper.FieldMap('Priority','Priority',false,'PICKLIST','Normal',formulaValue,false);
        userTaskFieldsLabelMap.put('Priority',fieldMap);

        fieldMap = new PC_AutomationTaskHelper.FieldMap('Channel', PC_Constants.getQualifiedAPIName('PC_Channel__c'),false,'STRING','Call',formulaValue,false);
        userTaskFieldsLabelMap.put(PC_Constants.getQualifiedAPIName('PC_Channel__c'),fieldMap);

        fieldMap = new PC_AutomationTaskHelper.FieldMap('Subject','Subject',false,'STRING','Test ',formulaValue,false);
        userTaskFieldsLabelMap.put('Subject',fieldMap);

        fieldMap = new PC_AutomationTaskHelper.FieldMap('Assign to Role',PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c'),false,'PICKLIST','Care Coordinator',formulaValue,false);
        userTaskFieldsLabelMap.put(PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c'),fieldMap);
        //Populating the objectsWithActivitiesEnabled List.
        objectsWithActivitiesEnabled= new List<Schema.SObjectType>();
        for (Schema.SObjectType whatIdObjectType : Task.WhatId.getDescribe().getReferenceTo()) {
            objectsWithActivitiesEnabled.add(whatIdObjectType);
        }

    }

    @isTest static void testBulkRecordInsert() {
        try {
            createTestData();
            enmtProgram1 = PC_Test_Setup.createEngagementProgram('TestPgm1', manufacturer.Id);
            enmtProgram1.PC_Program_Code__c = 'TestPgm1';
            enmtProgram1 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram1, false);

            enmtProgram2 = PC_Test_Setup.createEngagementProgram('TestPgm2', manufacturer.Id);
            enmtProgram2.PC_Program_Code__c = 'TestPgm2';
            enmtProgram2 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram2, false);

            bulkSupportPlan1 = new PC_SupportPlan__c();
            bulkSupportPlan1.Name = 'Test Bulk SP1';
            bulkSupportPlan1.PC_IsActive__c = true;
            bulkSupportPlan1.PC_TriggerEventObject__c = 'Case';
            bulkSupportPlan1.PC_TriggerEventType__c = 'Insert';
            bulkSupportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            bulkSupportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            bulkSupportPlan1.PC_SupportPlan_Behavior__c = String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeRuleMatches);
            bulkSupportPlan1 = (PC_SupportPlan__c) PC_Database.ins(bulkSupportPlan1, false);
            system.assertNotEquals(bulkSupportPlan1.Id, null);

            bulkSupportPlan2 = new PC_SupportPlan__c();
            bulkSupportPlan2.Name = 'Test Bulk SP2';
            bulkSupportPlan2.PC_IsActive__c = true;
            bulkSupportPlan2.PC_TriggerEventObject__c = 'Case';
            bulkSupportPlan2.PC_TriggerEventType__c = 'Insert';
            bulkSupportPlan2.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            bulkSupportPlan2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            bulkSupportPlan2.PC_SupportPlan_Behavior__c = String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeRuleMatches);
            bulkSupportPlan2 = (PC_SupportPlan__c) PC_Database.ins(bulkSupportPlan2, false);
            system.assertNotEquals(bulkSupportPlan2.Id, null);

            PC_AutomationTaskHelper.FormulaValue formulaValue;
            PC_AutomationTaskHelper.FieldMap fieldMap;
            formulaValue = new PC_AutomationTaskHelper.FormulaValue(PC_Constants.getQualifiedAPIName('PC_Approval_Denial_Date__c'), 'DATETIME', 'Add', 'Days', 5);
            fieldMap = new PC_AutomationTaskHelper.FieldMap('Due Date', 'ActivityDate', true, 'DATE', PC_Constants.PC_FORMULA_VALUE, formulaValue, false);
            userTaskFieldsLabelMap.put('ActivityDate', fieldMap);

            bulkSupPlanActy1 = PC_Test_Setup.createSupportPlanActivity('Bulk Activity 1: Task - Log a Call');
            bulkSupPlanActy1.PC_SupportPlan__c = bulkSupportPlan1.Id;
            bulkSupPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
            bulkSupPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(bulkSupPlanActy1, false);

            bulkSupPlanActy2 = PC_Test_Setup.createSupportPlanActivity('Bulk Activity 2: Task - Log a Call');
            bulkSupPlanActy2.PC_SupportPlan__c = bulkSupportPlan2.Id;
            bulkSupPlanActy2.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
            bulkSupPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(bulkSupPlanActy2, false);

            bulkSupportPlan1.PC_InitialActivity__c = bulkSupPlanActy1.Id;
            bulkSupportPlan1 = (PC_SupportPlan__c) PC_Database.upd(bulkSupportPlan1, false);

            bulkSupportPlan2.PC_InitialActivity__c = bulkSupPlanActy2.Id;
            bulkSupportPlan2 = (PC_SupportPlan__c) PC_Database.upd(bulkSupportPlan2, false);

            //Configure enmtProgram1 for both Support plans
            enmtPgm1SupPlan1 = PC_Test_Setup.createEnggmtPgmSupPlan();
            enmtPgm1SupPlan1.PC_EngagementProgram__c = enmtProgram1.Id;
            enmtPgm1SupPlan1.PC_SupportPlan__c = bulkSupportPlan1.Id;
            enmtPgm1SupPlan1 = (PC_EngagementProgram_SupportPlan__c) PC_Database.ins(enmtPgm1SupPlan1, false);

            enmtPgm1SupPlan2 = PC_Test_Setup.createEnggmtPgmSupPlan();
            enmtPgm1SupPlan2.PC_EngagementProgram__c = enmtProgram1.Id;
            enmtPgm1SupPlan2.PC_SupportPlan__c = bulkSupportPlan2.Id;
            enmtPgm1SupPlan2 = (PC_EngagementProgram_SupportPlan__c) PC_Database.ins(enmtPgm1SupPlan2, false);

            //Configure enmtProgram2 for bulk Support plan 2
            enmtPgm2SupPlan2 = PC_Test_Setup.createEnggmtPgmSupPlan();
            enmtPgm2SupPlan2.PC_EngagementProgram__c = enmtProgram2.Id;
            enmtPgm2SupPlan2.PC_SupportPlan__c = bulkSupportPlan2.Id;
            enmtPgm2SupPlan2 = (PC_EngagementProgram_SupportPlan__c) PC_Database.ins(enmtPgm2SupPlan2, false);

            programCase1 = PC_Test_Setup.createCase(adminUser, patient);
            programCase1.PC_Engagement_Program__c = enmtProgram1.Id;
            programCase1.PC_Care_Coordinator__c = careCoordinator.Id;
            programCase1.PC_Enrollment_Date__c = date.today().addDays(-10);
            programCase1.PC_Treatment_Start_Date__c = date.today();
            programCase1.IsEscalated = false;
            programCase1.HealthCloudGA__FinancialValue__c = 10;
            programCase1.PC_Approval_Denial_Date__c = date.today();
            programCase1.Status = 'In Treatment';

            programCase2 = PC_Test_Setup.createCase(adminUser, patient);
            programCase2.PC_Engagement_Program__c = enmtProgram2.Id;
            programCase2.PC_Care_Coordinator__c = careCoordinator.Id;
            programCase2.PC_Enrollment_Date__c = date.today().addDays(-10);
            programCase2.PC_Treatment_Start_Date__c = date.today();
            programCase2.IsEscalated = false;
            programCase2.HealthCloudGA__FinancialValue__c = 10;
            programCase2.PC_Approval_Denial_Date__c = date.today();
            programCase2.Status = 'In Treatment';

            Test.StartTest();
            system.runAs(adminUser) {
                List<Case> caseList = new List<Case>();
                caseList.add(programCase1);
                caseList.add(programCase2);
                caseList = (List<Case>) PC_Database.ins(caseList, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            List<Task> case1Tasks = [SELECT Id FROM Task WHERE PC_Program__r.PC_Engagement_Program__c = :enmtProgram1.Id];
            List<Task> case2Tasks = [SELECT Id FROM Task WHERE PC_Program__r.PC_Engagement_Program__c = :enmtProgram2.Id];

            //validate that only support plans configured for related EP of case are executed for each case record
            system.assertNotEquals(case1Tasks.size(), 2);
            system.assertNotEquals(case2Tasks.size(), 1);
        }catch(Exception ex){
            system.debug('exception in testBulkRecordInsert>>'+ex.getMessage());
            system.debug('exception >>'+ex.getStackTraceString());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testSPExecutionWithBulkRuntimes() {
        try{
            createTestData();
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
            update supPlanActy1;

            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            List<PC_SupportPlanRunTime__c> inProgressRuntimes = new List<PC_SupportPlanRunTime__c>();
            for(integer i=0; i<9900 ; i++){
                PC_SupportPlanRunTime__c runtime = new PC_SupportPlanRunTime__c();
                runtime.PC_SupportPlan__c = supportPlan1.Id;
                runtime.PC_SupportPlanCase__c = programCase.Id;
                runtime.PC_CurrentActivityStatus__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED;
                inProgressRuntimes.add(runtime);
            }
            inProgressRuntimes = (List<PC_SupportPlanRunTime__c>) PC_Database.ins(inProgressRuntimes, false);

            Case programCase1 = PC_Test_Setup.createCase(adminUser, patient);
            programCase1.PC_Engagement_Program__c = enmtProgram.Id;
            programCase1.PC_Care_Coordinator__c      =   careCoordinator.Id;
            programCase1.PC_Enrollment_Date__c = date.today().addDays(-10);
            programCase1.PC_Treatment_Start_Date__c = date.today();
            programCase1.IsEscalated = false;
            programCase1.HealthCloudGA__FinancialValue__c = 10;
            programCase1 = (Case)PC_Database.ins(programCase1, false);
            // check if program Case is created
            system.assertNotEquals(programCase1.Id, null);

            Test.StartTest();
            List<PC_SupportPlanRunTime__c> completedRuntimes = new List<PC_SupportPlanRunTime__c>();
            for(integer i=0; i<9900 ; i++){
                PC_SupportPlanRunTime__c runtime = new PC_SupportPlanRunTime__c();
                runtime.PC_SupportPlan__c = supportPlan1.Id;
                runtime.PC_SupportPlanCase__c = programCase.Id;
                runtime.PC_CurrentActivityStatus__c = PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED;
                completedRuntimes.add(runtime);
            }
            completedRuntimes = (List<PC_SupportPlanRunTime__c>) PC_Database.ins(completedRuntimes, false);

            system.runAs(adminUser) {
                programCase1.Status = 'In Treatment';
                programCase1 = (Case)PC_Database.upd(programCase1, false);
            }
            system.assert(Limits.getQueryRows()<Limits.getLimitQueryRows());
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            //Query the Log
            PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_TriggerRecordId__c =:programCase1.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
            system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

            Task  firsTask=[SELECT Id,Status FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c ];
            //Completed first task
            firsTask.Status='Completed';
            firsTask = (Task) PC_Database.upd(firsTask, false);

            PC_SupportPlanActivityLog__c completedLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_SupportPlanRuntime__c =:inProgressLog.PC_SupportPlanRuntime__c AND PC_Status__c =:PC_Constants.PC_LOG_STATUS_COMPLETED];

            system.assertNotEquals(completedLog.Id, null);

        }catch(Exception ex){
            system.debug('exception in testSPExecutionWithBulkRuntimes>>'+ex.getMessage());
            system.debug('exception >>'+ex.getStackTraceString());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testCreateUserTaskAction() {
        try{
            createTestData();
            PC_AutomationTaskHelper.FormulaValue formulaValue;
            PC_AutomationTaskHelper.FieldMap fieldMap;
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;

        formulaValue = new PC_AutomationTaskHelper.FormulaValue(PC_Constants.getQualifiedAPIName('PC_Approval_Denial_Date__c'),'DATETIME','Add','Days',5);
        fieldMap = new PC_AutomationTaskHelper.FieldMap('Due Date','ActivityDate',true,'DATE',PC_Constants.PC_FORMULA_VALUE,formulaValue,false);
        userTaskFieldsLabelMap.put('ActivityDate',fieldMap);

        supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
        PC_Database.upd(supPlanActy1);
            
            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);
            
            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'In Treatment';
                update programCase;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            //Query the Log
            PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                                                           PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
                                                           WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];
            
            system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
            system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);
            
            Task  firsTask=[SELECT Id,Status FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c ];
            //Completed first task
            firsTask.Status='Completed';
            firsTask = (Task) PC_Database.upd(firsTask, false);
            
            PC_SupportPlanActivityLog__c completedLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                                                          PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
                                                          WHERE PC_SupportPlanRuntime__c =:inProgressLog.PC_SupportPlanRuntime__c AND PC_Status__c =:PC_Constants.PC_LOG_STATUS_COMPLETED];
            
            system.assertNotEquals(completedLog.Id, null);

        }catch(Exception ex){
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testHandlingObjectsWithActivitiesDisabled(){
        try {
            createTestData();
            Test.StartTest();
            System.runAs(adminUser) {
                PC_SupportPlanEngine.handleObjectsWithActivitiesDisabled(triggerObjectType, objectsWithActivitiesEnabled);
            }
            Test.StopTest();
        }catch(Exception ex){
            system.debug('exception in handleObjectsWithActivitiesDisabled>>'+ex.getMessage());
            system.assert(true,'Exception is expected since activities is not enabled on the object');
        }
    }

    @isTest static void testPreviousTaskSPACriteria() {
        try{
            createTestData();

            PC_AutomationTaskHelper.FormulaValue formulaValue;
            PC_AutomationTaskHelper.FieldMap fieldMap;
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;

            formulaValue = new PC_AutomationTaskHelper.FormulaValue(PC_Constants.getQualifiedAPIName('PC_Approval_Denial_Date__c'),'DATETIME','Add','Days',5);
            fieldMap = new PC_AutomationTaskHelper.FieldMap('Due Date','ActivityDate',true,'DATE',PC_Constants.PC_FORMULA_VALUE,formulaValue,false);
            userTaskFieldsLabelMap.put('ActivityDate',fieldMap);

            supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
            supPlanActy1.PC_ConditionBehavior__c  = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanActy1.PC_ConditionOption__c  = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            supPlanActy1.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":[{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Equals","Type":"Picklist","Value":"In Treatment"}],"Logic":""}]}';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            supPlanActy2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy2.PC_NextActivityNumber__c = supPlanActy1.Id;
            supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy2, false);

            supportPlan1.PC_InitialActivity__c = supPlanActy2.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'In Treatment';
                update programCase;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            //Query the Log 1
            PC_SupportPlanActivityLog__c completedLog1  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy2.Id];

            system.assertNotEquals(completedLog1.PC_ActionRecordId__c, null);
            system.assertEquals(completedLog1.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Query the Log 2
            PC_SupportPlanActivityLog__c completedLog2  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
            system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

        }catch(Exception ex){
            system.debug('exception in testPreviousTaskSPACriteria>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testSupportPlanBehaviour() {
        try{
            createTestData();
            supportPlan1.PC_SupportPlan_Behavior__c=String.valueOf(PC_Constants.SupportPlanBehaviour.RunEveryTimeIfNoPendingRuntime);
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            supPlanActy1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanActy1.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":[{"ConditionNo":1,"FieldName":"Case Type","FieldApiName":"type","Operator":"Equals","Type":"PICKLIST","Value":"Program"},'+
                    '{"ConditionNo":2,"FieldName":"Status","FieldApiName":"status","Operator":"Equals","Type":"PICKLIST","Value":"Open"}],"Logic":"1 AND 2"}]}';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);


            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'In Treatment';
                update programCase;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Query SPRT
            PC_SupportPlanRunTime__c SPRT = [SELECT ID,PC_CurrentActivityStatus__c FROM PC_SupportPlanRunTime__c WHERE PC_SupportPlanCase__c =:programCase.Id];
            system.assertEquals(SPRT.PC_CurrentActivityStatus__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION);

            system.runAs(adminUser) {
                programCase.Status = 'In Treatment';
                update programCase;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Query SPRT
            List<PC_SupportPlanRunTime__c> SPRTList = [SELECT ID,PC_CurrentActivityStatus__c FROM PC_SupportPlanRunTime__c WHERE PC_SupportPlanCase__c =:programCase.Id];
            //ensure that support plan is not executed if there is existing pending runtime and behaviour is set to RunEveryTimeIfNoPendingRuntime
            system.assertEquals(SPRTList.size(), 1);

            Test.StopTest();

        }catch(Exception ex){
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testPublishPlatformEventAction() {
        try{
            createTestData();
            supPlanActy3.PC_SupportPlan__c = supportPlan1.Id;
            update supPlanActy3;
            
            supportPlan1.PC_InitialActivity__c = supPlanActy3.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);
            
            Test.StartTest();
            system.runAs(adminUser) {
                programCase.Status = 'In Treatment';
                update programCase;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();
            
            //Query the Log
            PC_SupportPlanActivityLog__c log  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c
                                                 FROM PC_SupportPlanActivityLog__c WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy3.Id];
            
            system.assertEquals(log.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);
        }catch(Exception ex){
            system.debug('exception in testPublishPlatformEventAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testCreateRecordAction() {
         try{
             createTestData();
             supPlanActy2.PC_SupportPlan__c = supportPlan1.Id;
             supPlanActy2.PC_AutomationTaskJSON__c = '{"fieldMapping":[{"label":"Record Type Name","apiName":"RecordType","isDeleteAllowed":false,"type":"Picklist",'+
                     '"value":"'+PC_Constants.getQualifiedAPIName('PC_Benefits_Investigation_Benefits_Verification')+'","isBoundValue":false},{"label":"Status","apiName":"Status","isDeleteAllowed":false,"type":"Picklist",'+
                     '"value":"New","isBoundValue":false},{"label":"Case Origin","apiName":"Origin","isDeleteAllowed":false,"type":"Picklist","value":"Email","isBoundValue":false},'+
                     '{"label":"Account ID","apiName":"AccountId","isDeleteAllowed":false,"type":"Reference","value":"AccountId","isBoundValue":true},'+
                     '{"label":"Enrollment Date","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Enrollment_Date__c')+'","isDeleteAllowed":false,"type":"Date","value":"--PC_Formula--",'+
                     '"formulaValue":{"referenceFieldApiName":"CreatedDate","referenceFieldType":"DATETIME","operation":"Add","offsetType":"Days","offsetValue":10},"isBoundValue":true},'+
                     '{"label":"Treatment Start Date","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","isDeleteAllowed":false,"type":"Date","value":"--PC_Formula--",'+
                     '"formulaValue":{"referenceFieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Enrollment_Date__c')+'","referenceFieldType":"DATE","operation":"Subtract","offsetType":"Years","offsetValue":1},"isBoundValue":true}],'+
                     '"objectDetails":{"qualifiedApiName":"Case"},"outcomeTaskDetails":{"create":true}}';
             update supPlanActy2;

             supportPlan1.PC_InitialActivity__c = supPlanActy2.Id;
             supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

             Test.StartTest();
             system.runAs(adminUser) {
                 programCase.Status = 'In Treatment';
                 update programCase;
             }
             //Deliver the Support Plan Info Platform event with context "ExecuteActions"
             Test.getEventBus().deliver();
             //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
             Test.getEventBus().deliver();
             Test.StopTest();

             Case newCase  = [SELECT ID FROM Case where  Origin='Email' Limit 1];
             system.assertNotEquals(newCase, null,'newCase creation failed');

             //Query the Outcome Task
              outcomeTask  = [SELECT ID,WhatId,Status,PC_SupportPlanActivity__c,Description FROM Task
              WHERE WhatId =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy2.Id];
             system.assertNotEquals(outcomeTask, null,'outcomeTask creation failed');

             //Query the Log
              PC_SupportPlanActivityLog__c log  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c
                                                   FROM PC_SupportPlanActivityLog__c WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy2.Id];

              system.assertNotEquals(log.PC_ActionRecordId__c, null);
              system.assertEquals(log.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

         }catch(Exception ex){
             system.debug('exception>>'+ex.getMessage());
             system.assert(false,ex.getMessage()+' : '+ex.getStackTraceString() + ' : '+ ex.getLineNumber());
         }
    }

    @isTest static void testAllActivitySkipFirst(){
        createTestData();
        PC_AutomationTaskHelper.FormulaValue formulaValue;
        PC_AutomationTaskHelper.FieldMap fieldMap;
        system.runAs(adminUser){
            //Create Support Plan Activity4
            supPlanActy4= PC_Test_Setup.createSupportPlanActivity('SupportPlan Activity 2');
            supPlanActy4.PC_SupportPlan__c               = supportPlan1.Id;
            supPlanActy4.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanActy4.PC_ConditionOption__c           = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            supPlanActy4.PC_Conditional_Logic__c         = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":[{"ConditionNo":1,"FieldName":"Case Type","FieldApiName":"type","Operator":"Equals","Type":"PICKLIST","Value":"Program"},'+
                    '{"ConditionNo":2,"FieldName":"Status","FieldApiName":"status","Operator":"Equals","Type":"PICKLIST","Value":"Open"}],"Logic":"1 AND 2"}]}';

            fieldMap = new PC_AutomationTaskHelper.FieldMap('Record Type Name','RecordType',false,'PICKLIST',PC_Constants.getQualifiedAPIName('PC_LogCall'),formulaValue,false);

            userTaskFieldsLabelMap.put('RecordType',fieldMap);
            supPlanActy4.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);


            supPlanActy4 = (PC_SupportPlanActivity__c)PC_Database.ins(supPlanActy4, false);

            //Update Support Plan Activity1
            supPlanActy1.PC_NextActivityNumber__c        = supPlanActy4.Id;
            supPlanActy1.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_SKIPFALSE;
            supPlanActy1.PC_ConditionOption__c           = PC_Constants.PC_COND_OPTION_APEX_CLASS;
            supPlanActy1.PC_ApexCondition__c             = 'PC_SupportPlan_DummyApexWaitCondition';
            supPlanActy1.PC_SupportPlan__c               = supportPlan1.Id;
            supPlanActy1 = (PC_SupportPlanActivity__c)PC_Database.upd(supPlanActy1, false);

            //Update Support Plan
            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            Test.startTest();
            system.runAs(adminUser) {
                programCase.Status = 'Open';
                programCase.Type = 'Program';
                update programCase;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Query SPRT
            PC_SupportPlanRunTime__c SPRT   = [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];
            //NO Group Should be Create
            system.assertNotEquals(SPRT.Name, null);
            system.assertEquals(SPRT.PC_Current_Group__c, null);
            system.assertEquals(SPRT.PC_Current_Group_Status__c, null);
            system.assertEquals(SPRT.PC_Current_Group_Next_Activity__c, null);
            system.assertEquals(SPRT.PC_CurrentActivityStatus__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS);
            system.assertEquals(SPRT.PC_EndTime__c, null);

            //First Task Created
            Set<String> actIds = new Set<String>();
            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentActivity__c,Set<String>.class));
            Task  task1=[SELECT Id,PC_SupportPlanActivity__c,Status, PC_Close_Date__c from Task where WhatId=:programCase.Id and PC_SupportPlanActivity__c IN :actIds];
            system.assertNotEquals(task1.Id, null);

            //Completed first task
            task1.Status='Completed';
            task1 = (Task) PC_Database.upd(task1, false);
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes" for Activity 1
            Test.getEventBus().deliver();

            //Query SPRT
            SPRT= [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];

            system.assertEquals(SPRT.PC_Completed_Activity__c, task1.Id);
            system.assertEquals(SPRT.PC_EndTime__c, null);
            system.assertEquals(SPRT.PC_CurrentActivityStatus__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS);

            //second Task Created
            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentActivity__c,Set<String>.class));
            Task  task2=[SELECT Id,PC_SupportPlanActivity__c,Status, PC_Close_Date__c from Task where WhatId=:programCase.Id and PC_SupportPlanActivity__c IN :actIds];
            system.assertNotEquals(task2.Id, null);

            //Completed second task
            task2.Status='Completed';
            task2 = (Task) PC_Database.upd(task2, false);
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes" for Activity 2
            Test.getEventBus().deliver();

            //Query SPRT
            SPRT= [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];

            //Check Completed activity on SPRT with the completed task
            system.assertEquals(SPRT.PC_Completed_Activity__c, task2.Id);
            system.assertNotEquals(SPRT.PC_EndTime__c, null);
            system.assertEquals(SPRT.PC_CurrentActivityStatus__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED);

            Test.stopTest();
        }
    }

    @isTest static void testAllAtOnceGroup(){
        createTestData();
        system.runAs(adminUser){
            //Update Support Plan Group 1 Activity 2
            supPlanGrp1Acty2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp1Acty2 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp1Acty2, false);

            //Update Support Plan Group 1 Activity 1
            supPlanGrp1Acty1.PC_NextActivityNumber__c   = supPlanGrp1Acty2.Id;
            supPlanGrp1Acty1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp1Acty1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp1Acty1, false);

            //Update Support Plan Group 1
            supPlanGrp1.PC_InitialSequenceActivity__c   = supPlanGrp1Acty1.Id;
            supPlanGrp1.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            supPlanGrp1.PC_GroupActivityExecution__c    = 'All at once';
            supPlanGrp1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp1.PC_NextActivityNumber__c = supPlanGrp2.Id;
            supPlanGrp1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp1, false);

            //Update Support Plan Group 2 Activity 2
            supPlanGrp2Acty2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp2Acty2 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp2Acty2, false);

            //Update Support Plan Group 2 Activity 1
            supPlanGrp2Acty1.PC_NextActivityNumber__c = supPlanGrp2Acty2.Id;
            supPlanGrp2Acty1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp2Acty1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp2Acty1, false);

            //Update Support Plan Group 2
            supPlanGrp2.PC_InitialSequenceActivity__c   = supPlanGrp2Acty1.Id;
            supPlanGrp2.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            supPlanGrp2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp2 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp2, false);

            //Update Support Plan
            supportPlan1.PC_InitialActivity__c = supPlanGrp1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            Test.startTest();
            programCase.Status = 'In Treatment';
            update programCase;
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Query SPRT
            PC_SupportPlanRunTime__c SPRT   = [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c, PC_CurrentGroupAllActivities__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];
            //First Group
            system.assertNotEquals(SPRT.Name, null);
            system.assertEquals(SPRT.PC_Current_Group__c, supPlanGrp1.Id);
            system.assertEquals(SPRT.PC_Current_Group_Status__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS);
            system.assertEquals(SPRT.PC_Current_Group_Next_Activity__c, supPlanGrp2.Id);

            //First Task of Group 1 Created
            Set<String> actIds = new Set<String>();
            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentGroupAllActivities__c,Set<String>.class));
            List<Task>  AllTaskCreated =[SELECT Id,PC_SupportPlanActivity__c,Status, PC_Close_Date__c from Task where WhatId=:programCase.Id and PC_SupportPlanActivity__c IN :actIds];
            Integer taskCount = AllTaskCreated.size();
            system.assertEquals(2,taskCount);

            //Completed first task
            AllTaskCreated[0].Status='Completed';
            AllTaskCreated[1].Status='Completed';
            PC_Database.upd(AllTaskCreated[0], false);
            PC_Database.upd(AllTaskCreated[1], false);

            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes" for Task 1 and Task 2 in Group 1
            Test.getEventBus().deliver();

            //Query SPRT
            SPRT= [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];

            //First Task of Group 2 Created
            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentActivity__c,Set<String>.class));

            List<Task>  AllTaskCreated1 =[SELECT Id,PC_SupportPlanActivity__c,Status, PC_Close_Date__c from Task where WhatId=:programCase.Id and PC_SupportPlanActivity__c IN :actIds];
            Integer group2Task1 = AllTaskCreated1.size();
            system.assertEquals(group2Task1, 1);

            //Completed first task
            AllTaskCreated1[0].Status='Completed';
            PC_Database.upd(AllTaskCreated1[0], false);

            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes" for Task 1 in Group 2
            Test.getEventBus().deliver();

            //Query SPRT
            SPRT= [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];

            //Second Task of Group 2 Created
            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentActivity__c,Set<String>.class));
            List<Task>  AllTaskCreated2 =[SELECT Id,PC_SupportPlanActivity__c,Status, PC_Close_Date__c from Task where WhatId=:programCase.Id and PC_SupportPlanActivity__c IN :actIds];
            Integer group2Task2 = AllTaskCreated2.size();
            system.assertEquals(group2Task2, 1);
            Test.stopTest();
        }
    }

    @isTest static void testAllAtOnceGroupWithWaitCondition(){
        createTestData();
        system.runAs(adminUser){
            //Update Support Plan Group 1
            supPlanGrp1.PC_InitialSequenceActivity__c = supPlanGrp1Acty1.Id;
            supPlanGrp1.PC_GroupActivityExecution__c    = 'All at once';
            supPlanGrp1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp1, false);

            //Update Support Plan Group 1 Activity 1
            supPlanGrp1Acty1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp1Acty1.PC_NextActivityNumber__c = supPlanGrp1Acty2.Id;
            supPlanGrp1Acty1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp1Acty1, false);

            //Update Support Plan Group 1
            supPlanGrp1.PC_NextActivityNumber__c = supPlanGrp2.Id;
            supPlanGrp1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp1, false);

            //Update Support Plan Group 2
            supPlanGrp2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp2.PC_InitialSequenceActivity__c = supPlanGrp2Acty1.Id;
            supPlanGrp2.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanGrp2.PC_ConditionOption__c           = PC_Constants.PC_COND_OPTION_APEX_CLASS;
            supPlanGrp2.PC_ApexCondition__c             = 'PC_SupportPlan_DummyApexWaitCondition';
            supPlanGrp2.PC_GroupActivityExecution__c    = 'All at once';
            supPlanGrp2 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp2, false);

            //Update Support Plan Group 1 Activity 1
            supPlanGrp2Acty1.PC_NextActivityNumber__c = supPlanGrp2Acty2.Id;
            supPlanGrp2Acty1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanGrp2Acty1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanGrp2Acty1, false);

            //Update Support Plan
            supportPlan1.PC_InitialActivity__c = supPlanGrp1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            Test.startTest();
            programCase.Status = 'In Treatment';
            programCase.PC_Enrollment_Date__c = NULL;
            update programCase;
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            //Query SPRT
            PC_SupportPlanRunTime__c SPRT   = [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c, PC_CurrentGroupAllActivities__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];
            //Group Should be Created
            system.assertNotEquals(SPRT.Name, null);
            system.assertEquals(SPRT.PC_Current_Group__c, supPlanGrp1.Id);
            system.assertEquals(SPRT.PC_Current_Group_Status__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS);
            system.assertEquals(SPRT.PC_Current_Group_Next_Activity__c, supPlanGrp2.Id);

            //All Task for Group 1 Created
            Set<String> actIds = new Set<String>();
            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentGroupAllActivities__c,Set<String>.class));
            List<Task>  ListAllTask =[SELECT Id,PC_SupportPlanActivity__c,Status, PC_Close_Date__c from Task where WhatId=:programCase.Id and PC_SupportPlanActivity__c IN :actIds];
            system.assertEquals(ListAllTask.size(), 2);

            //Completed first task
            ListAllTask[0].Status='Completed';
            ListAllTask[1].Status='Completed';
            ListAllTask[0] = (Task) PC_Database.upd(ListAllTask[0], false);
            ListAllTask[1] = (Task) PC_Database.upd(ListAllTask[1], false);
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes" for Task 1 and Task 2 in Group 1
            Test.getEventBus().deliver();

            //Check Completed activity on SPRT with the completed task
            SPRT= [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c, PC_CurrentGroupAllActivities__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];

            actIds = (Set<String>) (System.JSON.deserialize(SPRT.PC_CurrentGroupAllActivities__c,Set<String>.class));

            system.assertEquals(SPRT.PC_Completed_Activity__c, ListAllTask[1].Id);
            system.assertEquals(SPRT.PC_EndTime__c, null);
            system.assertEquals(actIds.contains(supPlanGrp2Acty1.Id), true);
            system.assertEquals(SPRT.PC_Current_Group__c, supPlanGrp2.Id);
            system.assertEquals(SPRT.PC_Current_Group_Status__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION);
            system.assertEquals(SPRT.PC_Current_Group_Next_Activity__c, null);
            system.assertEquals(SPRT.PC_CurrentActivityStatus__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS);

            //Update Case
            programCase.PC_Enrollment_Date__c= Date.today();
            PC_Database.upd(programCase, false);
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes" for pending SPRT
            Test.getEventBus().deliver();

            //Check updated Status on Group and Activity
            SPRT= [SELECT ID, Name, CreatedDate, PC_SupportPlanCase__r.CaseNumber,PC_CurrentActivity__c,PC_CurrentActivityStatus__c,PC_EndTime__c,
                    PC_Current_Group__c,PC_Current_Group_Status__c,PC_Current_Group_Next_Activity__c,PC_Completed_Activity__c,PC_Completed_Activity_Date__c, PC_CurrentGroupAllActivities__c
            FROM PC_SupportPlanRunTime__c
            WHERE PC_SupportPlanCase__c =:programCase.Id];

            //Group Should be Create
            system.assertNotEquals(SPRT.Name, null);
            system.assertEquals(SPRT.PC_Current_Group__c, supPlanGrp2.Id);
            system.assertEquals(SPRT.PC_Current_Group_Status__c, PC_Constants.SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS);
            system.assertEquals(SPRT.PC_Current_Group_Next_Activity__c, null);

            Test.stopTest();
        }
    }

    @isTest static void testDueDate(){
        createTestData();
        system.runAs(adminUser) {
            //Create Support Plan
            //Update Support Plan Activity1
            supPlanActy1.PC_NextActivityNumber__c   = supPlanActy2.Id;
            supPlanActy1.PC_ConditionBehavior__c    = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            supPlanActy1.PC_ReferenceDate__c        = 'PC_ENROLLMENT_DATE__C';
            supPlanActy1.PC_ReferenceOffset__c      = String.valueOf(10);
            supPlanActy1.PC_ReferenceType__c        = PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_BEFOREREFDATE;
            supPlanActy1.PC_ReferenceOffsetUnit__c  = PC_Constants.SUPPORTPLANTASK_REFERENCEUNIT_DAYS;
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy1 = (PC_SupportPlanActivity__c)PC_Database.upd(supPlanActy1, false);
            
            //Update Support Plan Activity2
            supPlanActy2.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
            supPlanActy2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy2 = (PC_SupportPlanActivity__c)PC_Database.upd(supPlanActy2, false);
            
            //Update Support Plan
            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);
            
            //Create Case: This will trigger the apex classes
            casetestDueDate = PC_Test_Setup.createCase(adminUser,patient);
            casetestDueDate.PC_Engagement_Program__c=enmtProgram.Id;
            casetestDueDate = (Case) PC_Database.ins(casetestDueDate, false);
            
            Test.startTest();
            casetestDueDate.PC_ENROLLMENT_DATE__C=Date.today();
            casetestDueDate = (Case) PC_Database.upd(casetestDueDate, false);
            
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
            
            Date prevActivityCompletionDate=Date.today().addDays(-10);
            
            Date returnedDate=PC_SupportPlanEngine.taskDueDateCalculator(prevActivityCompletionDate,casetestDueDate.Id,'Case',supPlanActy1);
            System.assert(null!=returnedDate);
            
            casetestDueDate.PC_ENROLLMENT_DATE__C=null;
            PC_Database.upd(casetestDueDate, false);
            
            supPlanActy1.PC_ReferenceType__c=PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_AFTERREFDATE;
            PC_Database.upd(supPlanActy1, false);
            
            Date returnedDate1=PC_SupportPlanEngine.taskDueDateCalculator(prevActivityCompletionDate,casetestDueDate.Id,'Case',supPlanActy1);
            System.assert(null!=returnedDate1);
            
            supPlanActy1.PC_ReferenceDate__c=PC_Constants.PC_NONE;
            supPlanActy1.PC_ReferenceType__c=PC_Constants.SUPPORTPLANTASK_REFERENCETYPE_AFTERPREVACTIVITY;
            PC_Database.upd(supPlanActy1, false);
            
            Date returnedDate2=PC_SupportPlanEngine.taskDueDateCalculator(prevActivityCompletionDate,casetestDueDate.Id,'Case',supPlanActy1);
            System.assert(null!=returnedDate2);
            
            supPlanActy1.PC_ReferenceDate__c=PC_Constants.PC_NONE;
            supPlanActy1.PC_ReferenceOffset__c=String.valueOf(10);
            supPlanActy1.PC_ReferenceType__c=PC_Constants.PC_ACTIVITY_CREATION_DATE;
            supPlanActy1.PC_ReferenceOffsetUnit__c=PC_Constants.SUPPORTPLANTASK_REFERENCEUNIT_DAYS;
            PC_Database.upd(supPlanActy1, false);
            
            Date dueDate = Date.today();
            
            Date returnedDate3=PC_SupportPlanEngine.taskDueDateCalculator(prevActivityCompletionDate,casetestDueDate.Id,'Case',supPlanActy1);
            System.assertEquals(returnedDate3 , dueDate.addDays(10));
        }
    }

    @isTest static void testCriteriaWithEqualsCondition() {
        createTestData();
        String todayDate = String.valueOf(date.today());
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":[{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Equals","Type":"Picklist","Value":"In Treatment"},'+
                '{"ConditionNo":2,"FieldName":"Record Type Name","FieldApiName":"RecordType","Operator":"Equals","Type":"Picklist","Value":"'+PC_Constants.getQualifiedAPIName('PC_Program')+'"},'+
                '{"ConditionNo":3,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Equals","Type":"Boolean","Value":"False"}],"Logic":"1 AND 2 AND 3"}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_Condition_Option__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
        supportPlan1.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":['+
                '{"ConditionNo":1,"FieldName":"Enrollment Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Enrollment_Date__c')+'","Operator":"Equals","Type":"Date","Value":"'+todayDate+'"},'+
                '{"ConditionNo":2,"FieldName":"Created Date","FieldApiName":"CreatedDate","Operator":"Equals","Type":"Datetime","Value":"2020-05-14T06:30:00.000Z"}],'+
                '"Logic":"1 OR 2"}]}';
        update supportPlan1;

        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        supPlanActy1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supPlanActy1.PC_ConditionOption__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
        supPlanActy1.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":['+
                '{"ConditionNo":1,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Equals","Type":"Date","Value":"2020-04-22"},'+
                '{"ConditionNo":2,"FieldName":"PA Status","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_PA_Status__c')+'","Operator":"Equals","Type":"Picklist","Value":"Approved"}],'+
                '"Logic":"1 AND 2"}]}';
        update supPlanActy1;

        Test.StartTest();
            system.runAs(adminUser) {
            programCase.Status = 'In Treatment';
            programCase.PC_Enrollment_Date__c = date.today();
            programCase.PC_Treatment_Start_Date__c = date.today();
            programCase.PC_PA_Status__c = 'Approved';
            update programCase;
        }
        //Deliver the Support Plan Info Platform event with context "ExecuteActions"
        Test.getEventBus().deliver();
        //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
        Test.getEventBus().deliver();

        //Query the Log
        List<PC_SupportPlanActivityLog__c> inProgressLogs  = new List<PC_SupportPlanActivityLog__c>();
        inProgressLogs = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

        system.assertEquals(true, inProgressLogs.isEmpty());

        Test.StopTest();
    }

    @isTest static void testNotEqualsANDNullConditions() {
        createTestData();
        String todayDate = String.valueOf(date.today());
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":[{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Is not null","Type":"Picklist","Value":""},'+
            '{"ConditionNo":2,"FieldName":"Record Type Name","FieldApiName":"RecordType","Operator":"Is not null","Type":"Picklist","Value":""},'+
            '{"ConditionNo":3,"FieldName":"ADHERENCE","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Status_Indicator_4__c')+'","Operator":"Is null","Type":"Picklist","Value":""}],'+
            '"Logic":"1 AND 2 AND 3"}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_Condition_Option__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
        supportPlan1.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","Conditions":['+
            '{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Does not equals","Type":"Picklist","Value":"In Treatment"},'+
            '{"ConditionNo":2,"FieldName":"Record Type Name","FieldApiName":"RecordType","Operator":"Does not equals","Type":"Picklist","Value":"'+PC_Constants.getQualifiedAPIName('PC_Enrollment')+'"},'+
            '{"ConditionNo":3,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Does not equals","Type":"Boolean","Value":"False"},'+
            '{"ConditionNo":4,"FieldName":"Enrollment Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Enrollment_Date__c')+'","Operator":"Does not equals","Type":"Date","Value":"'+todayDate+'"},'+
            '{"ConditionNo":5,"FieldName":"Created Date","FieldApiName":"CreatedDate","Operator":"Does not equals","Type":"Datetime","Value":"2020-05-14T06:30:00.000Z"}],'+
            '"Logic":"1 AND 2 AND 3 AND 4 AND 5"}]}';
        
        update supportPlan1;
        
        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        update supPlanActy1;
        
        Test.StartTest();
        system.runAs(adminUser) {
            programCase.Status = 'In Progress';
            programCase.IsEscalated = true;
            programCase.PC_Enrollment_Date__c = date.today().addDays(-100);
            update programCase;
        }
        //Deliver the Support Plan Info Platform event with context "ExecuteActions"
        Test.getEventBus().deliver();
        //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
        Test.getEventBus().deliver();
        //Query the Log
        List<PC_SupportPlanActivityLog__c> inProgressLogs  = new List<PC_SupportPlanActivityLog__c>();
        inProgressLogs = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

        system.assertEquals(true, inProgressLogs.isEmpty());
        Test.StopTest();
    }

    @isTest static void testGreaterThanLessThanConditions() {
        createTestData();
        String todayDate = String.valueOf(date.today());
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":['+
            '{"ConditionNo":1,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Greater than","Type":"Date","Value":"'+todayDate+'"},'+
            '{"ConditionNo":2,"FieldName":"Enrollment Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Enrollment_Date__c')+'","Operator":"Less than","Type":"Date","Value":"'+todayDate+'"},'+
            '{"ConditionNo":3,"FieldName":"Request Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Request_Date__c')+'","Operator":"Less than or equal","Type":"Date","Value":"'+todayDate+'"},'+
            '{"ConditionNo":4,"FieldName":"Date Submitted to Patient","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Date_Submitted_to_Patient__c')+'","Operator":"Greater than or equal","Type":"Date","Value":"'+todayDate+'"},'+
            '{"ConditionNo":5,"FieldName":"Sort Order","FieldApiName":"HealthCloudGA__SortOrder__c","Operator":"Greater than or equal","Type":"Double","Value":"2"},'+
            '{"ConditionNo":6,"FieldName":"Sort Order","FieldApiName":"HealthCloudGA__SortOrder__c","Operator":"Less than or equal","Type":"Double","Value":"50"},'+
            '{"ConditionNo":7,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Less than","Type":"Currency","Value":"100"},'+
            '{"ConditionNo":8,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Greater than","Type":"Currency","Value":"10"}'+
            '],"Logic":"1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7 AND 8"}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        update supportPlan1;
        
        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        update supPlanActy1;
        
        Test.StartTest();
        system.runAs(adminUser) {
            programCase.PC_Enrollment_Date__c = date.today().addDays(-100);
            programCase.PC_Treatment_Start_Date__c = date.today().addDays(+10);
            programCase.PC_Request_Date__c = date.today().addDays(-10);
            programCase.PC_Date_Submitted_to_Patient__c = date.today().addDays(+10);
            programCase.HealthCloudGA__SortOrder__c = 10;
            programCase.HealthCloudGA__FinancialValue__c = 50;
            update programCase;
        }
        //Deliver the Support Plan Info Platform event with context "ExecuteActions"
        Test.getEventBus().deliver();
        //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
        Test.getEventBus().deliver();
        //Query the Log
        List<PC_SupportPlanActivityLog__c> inProgressLogs  = new List<PC_SupportPlanActivityLog__c>();
        inProgressLogs = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

        system.assertEquals(true, inProgressLogs.isEmpty());
        Test.StopTest();
    }

    @isTest static void testHasNotChangedConditions() {
        createTestData();
        String todayDate = String.valueOf(date.today());
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":[{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Has not changed","Type":"Picklist","Value":""},'+
                '{"ConditionNo":2,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Has not changed","Type":"Date","Value":""},'+
                '{"ConditionNo":3,"FieldName":"Created Date","FieldApiName":"CreatedDate","Operator":"Has not changed","Type":"Datetime","Value":""},'+
                '{"ConditionNo":4,"FieldName":"Record Type Name","FieldApiName":"RecordType","Operator":"Has not changed","Type":"Picklist","Value":""},'+
                '{"ConditionNo":5,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Has not changed","Type":"Boolean","Value":""},'+
                '{"ConditionNo":6,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Has not changed","Type":"Currency","Value":""}'+
                '],"Logic":"1 AND 2 OR 3 AND (4 AND   5 AND 6 )"}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        update supportPlan1;

        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        update supPlanActy1;

        Test.StartTest();
        system.runAs(adminUser) {
            programCase.HealthCloudGA__SortOrder__c = 10;
            update programCase;
        }
        //Deliver the Support Plan Info Platform event with context "ExecuteActions"
        Test.getEventBus().deliver();
        //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
        Test.getEventBus().deliver();
        //Query the Log
        List<PC_SupportPlanActivityLog__c> inProgressLogs  = new List<PC_SupportPlanActivityLog__c>();
        inProgressLogs = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

        system.assertEquals(true, inProgressLogs.isEmpty());
        Test.StopTest();
    }

    @isTest static void testHasChangedConditions() {
        createTestData();
        String todayDate = String.valueOf(date.today());
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":['+
                '{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Has changed","Type":"Picklist","Value":"--PC_Any--","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":2,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Has changed","Type":"Date","Value":"--PC_Any--","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":3,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Has changed","Type":"Boolean","Value":"--PC_Any--","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":4,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Has changed","Type":"Currency","Value":"--PC_Any--","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":5,"FieldName":"Status","FieldApiName":"Status","Operator":"Has changed","Type":"Picklist","Value":"--PC_Any--","changeToValue":"In Treatment"},'+
                '{"ConditionNo":6,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Has changed","Type":"Date","Value":"--PC_Any--","changeToValue":""},'+
                '{"ConditionNo":7,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Has changed","Type":"Boolean","Value":"--PC_Any--","changeToValue":"True"},'+
                '{"ConditionNo":8,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Has changed","Type":"Currency","Value":"--PC_Any--","changeToValue":"50"},'+
                '{"ConditionNo":9,"FieldName":"Status","FieldApiName":"Status","Operator":"Has changed","Type":"Picklist","Value":"New","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":10,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Has changed","Type":"Date","Value":"'+todayDate+'","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":11,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Has changed","Type":"Boolean","Value":"False","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":12,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Has changed","Type":"Currency","Value":"10","changeToValue":"--PC_Any--"},'+
                '{"ConditionNo":13,"FieldName":"Status","FieldApiName":"Status","Operator":"Has changed","Type":"Picklist","Value":"New","changeToValue":"In Treatment"},'+
                '{"ConditionNo":14,"FieldName":"Treatment Start Date","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_Treatment_Start_Date__c')+'","Operator":"Has changed","Type":"Date","Value":"'+todayDate+'","changeToValue":""},'+
                '{"ConditionNo":15,"FieldName":"Escalated","FieldApiName":"IsEscalated","Operator":"Has changed","Type":"Boolean","Value":"False","changeToValue":"True"},'+
                '{"ConditionNo":16,"FieldName":"Financial Value","FieldApiName":"HealthCloudGA__FinancialValue__c","Operator":"Has changed","Type":"Currency","Value":"10","changeToValue":"50"}],'+
                '"Logic":"1 AND 2 AND 3 AND 4 AND 5 AND 6 AND 7 AND 8 AND 9 AND 10 AND 11 AND 12 AND 13 AND 14 AND 15 AND 16"}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        update supportPlan1;

        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        update supPlanActy1;

        Test.StartTest();
        system.runAs(adminUser) {
            programCase.Status = 'In Treatment';
            programCase.PC_Treatment_Start_Date__c = null;
            programCase.IsEscalated = true;
            programCase.HealthCloudGA__FinancialValue__c = 50;
            update programCase;
        }
        //Deliver the Support Plan Info Platform event with context "ExecuteActions"
        Test.getEventBus().deliver();
        //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
        Test.getEventBus().deliver();
        //Query the Log
        List<PC_SupportPlanActivityLog__c> inProgressLogs  = new List<PC_SupportPlanActivityLog__c>();
        inProgressLogs = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

        system.assertEquals(true, inProgressLogs.isEmpty());
        Test.StopTest();
    }

    @isTest static void testContainsDoesNotContainsConditions() {
        createTestData();
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
        supportPlan1.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":['+
                '{"ConditionNo":1,"FieldName":"Description","FieldApiName":"Description","Operator":"Contains","Type":"Textarea","Value":"Test"},'+
                '{"ConditionNo":2,"FieldName":"Subject","FieldApiName":"Subject","Operator":"Contains","Type":"String","Value":"Test"},'+
                '{"ConditionNo":3,"FieldName":"Engagement Program Name","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_EngagementProgramName__c')+
                '","Operator":"Contains","Type":"String","Value":"Test"},'+
                '{"ConditionNo":4,"FieldName":"Description","FieldApiName":"Description","Operator":"Does not contains","Type":"Textarea","Value":"Test1"},'+
                '{"ConditionNo":5,"FieldName":"Subject","FieldApiName":"Subject","Operator":"Does not contains","Type":"String","Value":"Test1"},'+
                '{"ConditionNo":6,"FieldName":"Engagement Program Name","FieldApiName":"'+PC_Constants.getQualifiedAPIName('PC_EngagementProgramName__c')+
                '","Operator":"Does not contains","Type":"String","Value":"Test1"}'+
                '],"Logic":"1 AND 2 AND 3 AND 4 AND 5 AND 6"}]}';
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        update supportPlan1;

        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        update supPlanActy1;

        Test.StartTest();
        system.runAs(adminUser) {
            programCase.Description = 'Test Description';
            update programCase;
        }
        //Deliver the Support Plan Info Platform event with context "ExecuteActions"
        Test.getEventBus().deliver();
        //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
        Test.getEventBus().deliver();
        //Query the Log
        List<PC_SupportPlanActivityLog__c> inProgressLogs  = new List<PC_SupportPlanActivityLog__c>();
        inProgressLogs = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
        WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

        system.assertEquals(true, inProgressLogs.isEmpty());
        Test.StopTest();
    }

    @isTest static void testTaskReparentLogicWithParentCaseOnCaseObject() {
        try{
            createTestData();
            PC_AutomationTaskHelper.FieldMap fieldMap;
            PC_AutomationTaskHelper.FormulaValue formulaValue =  new PC_AutomationTaskHelper.FormulaValue();
            List<Account> patientList = new List<Account>();
            patientList.add(patient);
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;

            fieldMap = new PC_AutomationTaskHelper.FieldMap('Priority','Priority',false,'PICKLIST','High',formulaValue,false);
            userTaskFieldsLabelMap.put('Priority',fieldMap);

            fieldMap = new PC_AutomationTaskHelper.FieldMap(' Related To ID','WhatId',true,'Reference',PC_Constants.getQualifiedAPIName('PC_Program__c'),formulaValue,false);
            userTaskFieldsLabelMap.put('WhatId',fieldMap);
            supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
            PC_Database.upd(supPlanActy1);

            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            List<Case> papCases = PC_Test_Setup.createCases(patientList, 1, PC_Constants.PAP_RECORD_TYPE);
            papCases[0].Origin=PC_Constants.CASE_ORIGIN_EMAIL;
            papCases[0].PC_Program__c = programCase.Id;
            papCases[0].PC_Engagement_Program__c = enmtProgram.Id;
            PC_Database.ins(papCases);

            Test.StartTest();
            system.runAs(adminUser) {
                papCases[0].Origin=PC_Constants.CASE_ORIGIN_PHONE;
                PC_Database.upd(papCases);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            //Query the Log
            PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_TriggerRecordId__c =:papCases[0].Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            Task  firsTask=[SELECT Id,Status,WhatId FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c ];

            System.assertEquals(programCase.Id,firsTask.WhatId);
            //Completed first task
            firsTask.Status='Completed';
            firsTask = (Task) PC_Database.upd(firsTask, false);

            PC_SupportPlanActivityLog__c completedLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_SupportPlanRuntime__c =:inProgressLog.PC_SupportPlanRuntime__c AND PC_Status__c =:PC_Constants.PC_LOG_STATUS_COMPLETED];

            system.assertNotEquals(completedLog.Id, null);


        }catch(Exception ex){
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testTaskReparentLogicWithoutParentCaseOnCaseObject() {
        try{
            createTestData();
            PC_AutomationTaskHelper.FieldMap fieldMap;
            PC_AutomationTaskHelper.FormulaValue formulaValue =  new PC_AutomationTaskHelper.FormulaValue();
            List<Account> patientList = new List<Account>();
            patientList.add(patient);
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;

            fieldMap = new PC_AutomationTaskHelper.FieldMap('Priority','Priority',false,'PICKLIST','High',formulaValue,false);
            userTaskFieldsLabelMap.put('Priority',fieldMap);

            fieldMap = new PC_AutomationTaskHelper.FieldMap(' Related To ID','WhatId',true,'Reference',PC_Constants.getQualifiedAPIName('PC_Program__c'),formulaValue,false);
            userTaskFieldsLabelMap.put('WhatId',fieldMap);

            supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);

            PC_Database.upd(supPlanActy1);

            supportPlan1.PC_InitialActivity__c = supPlanActy1.Id;
            supportPlan1 = (PC_SupportPlan__c) PC_Database.upd(supportPlan1, false);

            List<Case> papCases = PC_Test_Setup.createCases(patientList, 1, PC_Constants.PAP_RECORD_TYPE);
            papCases[0].Origin=PC_Constants.CASE_ORIGIN_EMAIL;
            papCases[0].PC_Engagement_Program__c = enmtProgram.Id;
            PC_Database.ins(papCases);

            Test.StartTest();
            system.runAs(adminUser) {
                papCases[0].Origin=PC_Constants.CASE_ORIGIN_PHONE;
                PC_Database.upd(papCases) ;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            //Query the Log
            PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_TriggerRecordId__c =:papCases[0].Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            Task  firsTask=[SELECT Id,Status,WhatId FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c];
            System.assertEquals(papCases[0].Id, firsTask.WhatId);

            //Completed first task
            firsTask.Status='Completed';
            firsTask = (Task) PC_Database.upd(firsTask, false);

            PC_SupportPlanActivityLog__c completedLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_SupportPlanRuntime__c =:inProgressLog.PC_SupportPlanRuntime__c AND PC_Status__c =:PC_Constants.PC_LOG_STATUS_COMPLETED];

            system.assertNotEquals(completedLog.Id, null);


        }catch(Exception ex){
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testTaskReparentLogicWithNonCaseObjectWithParentCase() {
        try{
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegistersForInteraction= [SELECT Id,PC_ApexClass__c,PC_Active__c,PC_sObject__c
                                                                                         FROM PC_TriggerHandlerRegister__mdt
                                                                                         WHERE PC_Active__c= true AND PC_sObject__c=:INTERACTION_SOBJECT_NAME AND
                                                                                         PC_ApexClass__c =: PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME];

            if(triggerHandlerRegistersForInteraction!=null && !triggerHandlerRegistersForInteraction.isEmpty()){
                createTestData();
                PC_AutomationTaskHelper.FieldMap fieldMap;
                PC_AutomationTaskHelper.FormulaValue formulaValue =  new PC_AutomationTaskHelper.FormulaValue();
                List<PC_Interaction__c> interactionRecordList = new List<PC_Interaction__c>();
                List<Account> patientList = new List<Account>();
                patientList.add(patient);
                supPlanActy1.PC_SupportPlan__c = supportPlan2.Id;

                fieldMap = new PC_AutomationTaskHelper.FieldMap('Assigned To ID','OwnerId',false,'Reference','CreatedById',formulaValue,false);
                userTaskFieldsLabelMap.put('OwnerId',fieldMap);

                fieldMap = new PC_AutomationTaskHelper.FieldMap(' Related To ID','WhatId',true,'Reference',PC_Constants.getQualifiedAPIName('PC_Patient_Program__c'),formulaValue,true);
                userTaskFieldsLabelMap.put('WhatId',fieldMap);

                userTaskFieldsLabelMap.remove(PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c'));

                supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);

                PC_Database.upd(supPlanActy1);
                supportPlan2.PC_InitialActivity__c = supPlanActy1.Id;
                supportPlan2 = (PC_SupportPlan__c) PC_Database.upd(supportPlan2, false);

                interactionRecordList.add(PC_Test_Setup.newInteraction(programCase.Id));

                Test.StartTest();
                system.runAs(adminUser) {
                    PC_Database.ins(interactionRecordList);
                }
                //Deliver the Support Plan Info Platform event with context "ExecuteActions"
                Test.getEventBus().deliver();
                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();
                Test.StopTest();

                //Query the Log
                PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                        PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_TriggerRecordId__c =:interactionRecordList[0].Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

                Task firsTask=[SELECT Id,Status,WhatId FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c ];

                System.assertEquals(programCase.Id,firsTask.WhatId);
                //Completed first task
                firsTask.Status='Completed';
                firsTask = (Task) PC_Database.upd(firsTask, false);

                PC_SupportPlanActivityLog__c completedLog  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                        PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_SupportPlanRuntime__c =:inProgressLog.PC_SupportPlanRuntime__c AND PC_Status__c =:PC_Constants.PC_LOG_STATUS_COMPLETED];

                system.assertNotEquals(completedLog.Id, null);
            }

        }
        catch(Exception ex){
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

}