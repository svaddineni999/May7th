/**************************************************************************************
Apex Class Name     : PC_Test_SPACriteriaEvaluation
Description         : This class is used for testing Support Plan Activity criteria evaluation
CreatedBy           : Haritha Reddy
Created Date        : 27-Jan-2022
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Haritha Reddy             27-Jan-2022           Initial version
****************************************************************************************/
@isTest(seeAllData=false)
public with sharing class PC_Test_SPACriteriaEvaluation {
    private static User adminUser;
    private static Case programCase;
    private static Account patient, manufacturer;
    private static PC_SupportPlan__c supportPlan1,supportPlan2;
    private static PC_SupportPlanActivity__c supPlanActy1,supPlanActy2;
    private static PC_Engagement_Program__c enmtProgram;
    private static PC_EngagementProgram_SupportPlan__c enmtPgmSupPlan;
    private static Map<String, PC_AutomationTaskHelper.FieldMap> userTaskFieldsLabelMap;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Haritha Reddy
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testuserpc@email.com', 'pctest1');
        PC_Database.ins(adminUser, false);

        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram('TestEngPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c = 'TestEngPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c = enmtProgram.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
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
    }

    /*
    *This test case tests the execution of Support plan activity criteria on Trigger record case with Record value set as Case
    * and 1st activity is of type create case
     */
    @isTest static void testSPACriteriaOnTriggerRecordCaseWithRecValue() {
        try{
            createTestData();

            //Create Support Plan Activity 2
            supPlanActy2= PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Case 2');
            supPlanActy2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy2.PC_ConditionBehavior__c  = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanActy2.PC_ConditionOption__c  = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            supPlanActy2.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Case","RecordValue":"Case","Conditions":[{"ConditionNo":1,"FieldName":"Status","FieldApiName":"Status","Operator":"Equals","Type":"Picklist","Value":"In Treatment"}],"Logic":""}]}';
            supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);

            //Create Support Plan Activity 1
            supPlanActy1= PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 1: Create Case 1');
            supPlanActy1.PC_NextActivityNumber__c = supPlanActy2.Id;
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

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
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.StopTest();

            //Query the Log 2
            PC_SupportPlanActivityLog__c completedLog2  = [SELECT ID,PC_TriggerRecordId__c,PC_ActionRecordId__c,PC_SupportPlanActivity__c,PC_Status__c,
                    PC_SupportPlanRuntime__c FROM PC_SupportPlanActivityLog__c WHERE PC_SupportPlanActivity__c =:supPlanActy2.Id];

            system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
            system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

        }catch(Exception ex){
            system.debug('exception in testSPACriteriaOnTriggerRecordCase>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }
    /*
    *This test case tests the execution of Support plan activity criteria on Previous task with Record value set as previousActivity
    * and 1st activity is of type user task. Support plan trigger Object is Case
     */
    @isTest static void testSPACriteriaOnPreviousTaskWithRecValue() {
        try{
            createTestData();

            //Create Support Plan Activity 2
            supPlanActy2= PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Case 2');
            supPlanActy2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy2.PC_ConditionBehavior__c  = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanActy2.PC_ConditionOption__c  = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            supPlanActy2.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Task","RecordValue":"previousActivity","Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"Normal"}],"Logic":""}]}';
            supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);

            //Create Support Plan Activity 1
            supPlanActy1= PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
            supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
            supPlanActy1.PC_NextActivityNumber__c = supPlanActy2.Id;
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

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

            //Query the Log 1
            PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID, PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
            system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

            Task  firsTask=[SELECT Id,Status FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c ];
            //Complete first task
            firsTask.Status='Completed';
            firsTask = (Task) PC_Database.upd(firsTask, false);

            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            Test.StopTest();
            //Query the Log 2
            PC_SupportPlanActivityLog__c completedLog2  = [SELECT ID,PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_SupportPlanActivity__c =:supPlanActy2.Id];

            system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
            system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

        }catch(Exception ex){
            system.debug('exception in testSPACriteriaOnPreviousTaskWithRecValue>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    /*
       *This test case tests the execution of Support plan activity criteria on Previous task without Record value set as previousActivity
       * and 1st activity is of type user task. Support plan trigger Object is Case.
        */
    @isTest static void testSPACriteriaOnPreviousTaskWithOutRecValue() {
        try{
            createTestData();

            //Create Support Plan Activity 2
            supPlanActy2= PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Case 2');
            supPlanActy2.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy2.PC_ConditionBehavior__c  = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
            supPlanActy2.PC_ConditionOption__c  = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
            supPlanActy2.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Task","Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"Normal"}],"Logic":""}]}';
            supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);

            //Create Support Plan Activity 1
            supPlanActy1= PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
            supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
            supPlanActy1.PC_NextActivityNumber__c = supPlanActy2.Id;
            supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

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

            //Query the Log 1
            PC_SupportPlanActivityLog__c inProgressLog  = [SELECT ID, PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_TriggerRecordId__c =:programCase.Id AND PC_SupportPlanActivity__c =:supPlanActy1.Id];

            system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
            system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

            Task  firsTask=[SELECT Id,Status FROM Task WHERE Id=:inProgressLog.PC_ActionRecordId__c ];
            //Complete first task
            firsTask.Status='Completed';
            firsTask = (Task) PC_Database.upd(firsTask, false);

            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();

            Test.StopTest();
            //Query the Log 2
            PC_SupportPlanActivityLog__c completedLog2  = [SELECT ID,PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
            WHERE PC_SupportPlanActivity__c =:supPlanActy2.Id];

            system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
            system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);

        }catch(Exception ex){
            system.debug('exception in testSPACriteriaOnPreviousTaskWithOutRecValue>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }
    /*
      *This test case tests the execution of Support plan activity criteria on Trigger record task with Record value set as Task
      * and 1st activity is of type user task. Support plan trigger Object is Task.
       */
    @isTest static void testSPACriteriaOnTriggerRecordTaskWithRecValue() {
        try{
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegistersForTask = [SELECT Id FROM PC_TriggerHandlerRegister__mdt
                    WHERE PC_Active__c = true AND PC_sObject__c = :PC_Constants.PC_TASK AND PC_ApexClass__c = :PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME];

            if (triggerHandlerRegistersForTask != null && !triggerHandlerRegistersForTask.isEmpty()) {
                createTestData();

                //Create Support Plan for Interaction object
                supportPlan2 = PC_Test_Setup.createSupportPlan();
                supportPlan2.Name = 'Test Task Support Plan';
                supportPlan2.PC_IsActive__c = true;
                supportPlan2.PC_TriggerEventObject__c = PC_Constants.PC_TASK;
                supportPlan2.PC_TriggerEventType__c = 'Insert/Update';
                supportPlan2.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supportPlan2.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"High"}],"Logic":""}]}';
                supportPlan2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
                supportPlan2.PC_SupportPlan_Behavior__c = String.valueOf(PC_Constants.SupportPlanBehaviour.RunOncePerRecord);
                supportPlan2 = (PC_SupportPlan__c) PC_Database.ins(supportPlan2, false);

                //Create Support Plan Activity 2
                supPlanActy2 = PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Case 2');
                supPlanActy2.PC_SupportPlan__c = supportPlan2.Id;
                supPlanActy2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supPlanActy2.PC_ConditionOption__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
                supPlanActy2.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Task","RecordValue":"Task","Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"High"}],"Logic":""}]}';
                supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);

                //Create Support Plan Activity 1
                supPlanActy1 = PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
                supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
                supPlanActy1.PC_NextActivityNumber__c = supPlanActy2.Id;
                supPlanActy1.PC_SupportPlan__c = supportPlan2.Id;
                supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

                supportPlan2.PC_InitialActivity__c = supPlanActy1.Id;
                supportPlan2 = (PC_SupportPlan__c) PC_Database.upd(supportPlan2, false);

                Test.StartTest();
                Task triggerTaskRecord = new Task();
                system.runAs(adminUser) {
                    triggerTaskRecord.Subject = 'Test Task 1';
                    triggerTaskRecord.PC_Channel__c = 'Call';
                    triggerTaskRecord.Status = 'Not Started';
                    triggerTaskRecord.Priority = 'High';
                    triggerTaskRecord = (Task) PC_Database.ins(triggerTaskRecord, false);
                }
                //Deliver the Support Plan Info Platform event with context "ExecuteActions"
                Test.getEventBus().deliver();
                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();

                //Query the Log 1
                PC_SupportPlanActivityLog__c inProgressLog = [SELECT ID, PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
                        WHERE PC_TriggerRecordId__c = :triggerTaskRecord.Id AND PC_SupportPlanActivity__c = :supPlanActy1.Id];

                system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
                system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

                Task firsTask = [SELECT Id,Status FROM Task WHERE Id = :inProgressLog.PC_ActionRecordId__c];
                //Complete first task
                firsTask.Status = 'Completed';
                firsTask = (Task) PC_Database.upd(firsTask, false);

                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();

                Test.StopTest();
                //Query the Log 2
                PC_SupportPlanActivityLog__c completedLog2 = [ SELECT ID,PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
                        WHERE PC_SupportPlanActivity__c = :supPlanActy2.Id];

                system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
                system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);
            }
        } catch(Exception ex){
            system.debug('exception in testSPACriteriaOnTriggerRecordTaskWithRecValue>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    /*
      *This test case tests the execution of Support plan activity criteria on Trigger record task without Record value set as Task
      * and 1st activity is of type user task. Support plan trigger Object is Task.
       */
    @isTest static void testSPACriteriaOnTriggerRecordTaskWithoutRecValue() {
        try{
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegistersForTask = [SELECT Id FROM PC_TriggerHandlerRegister__mdt
            WHERE PC_Active__c = true AND PC_sObject__c = :PC_Constants.PC_TASK AND PC_ApexClass__c = :PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME];

            if (triggerHandlerRegistersForTask != null && !triggerHandlerRegistersForTask.isEmpty()) {
                createTestData();

                //Create Support Plan for Interaction object
                supportPlan2 = PC_Test_Setup.createSupportPlan();
                supportPlan2.Name = 'Test Task Support Plan';
                supportPlan2.PC_IsActive__c = true;
                supportPlan2.PC_TriggerEventObject__c = PC_Constants.PC_TASK;
                supportPlan2.PC_TriggerEventType__c = 'Insert/Update';
                supportPlan2.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supportPlan2.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"High"}],"Logic":""}]}';
                supportPlan2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
                supportPlan2.PC_SupportPlan_Behavior__c = String.valueOf(PC_Constants.SupportPlanBehaviour.RunOncePerRecord);
                supportPlan2 = (PC_SupportPlan__c) PC_Database.ins(supportPlan2, false);

                //Create Support Plan Activity 2
                supPlanActy2 = PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Case 2');
                supPlanActy2.PC_SupportPlan__c = supportPlan2.Id;
                supPlanActy2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supPlanActy2.PC_ConditionOption__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
                supPlanActy2.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Task","Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"High"}],"Logic":""}]}';
                supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);

                //Create Support Plan Activity 1
                supPlanActy1 = PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
                supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
                supPlanActy1.PC_NextActivityNumber__c = supPlanActy2.Id;
                supPlanActy1.PC_SupportPlan__c = supportPlan2.Id;
                supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

                supportPlan2.PC_InitialActivity__c = supPlanActy1.Id;
                supportPlan2 = (PC_SupportPlan__c) PC_Database.upd(supportPlan2, false);

                Test.StartTest();
                Task triggerTaskRecord = new Task();
                system.runAs(adminUser) {
                    triggerTaskRecord.Subject = 'Test Task 1';
                    triggerTaskRecord.PC_Channel__c = 'Call';
                    triggerTaskRecord.Status = 'Not Started';
                    triggerTaskRecord.Priority = 'High';
                    triggerTaskRecord = (Task) PC_Database.ins(triggerTaskRecord, false);
                }
                //Deliver the Support Plan Info Platform event with context "ExecuteActions"
                Test.getEventBus().deliver();
                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();

                //Query the Log 1
                PC_SupportPlanActivityLog__c inProgressLog = [SELECT ID, PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_TriggerRecordId__c = :triggerTaskRecord.Id AND PC_SupportPlanActivity__c = :supPlanActy1.Id];

                system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
                system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

                Task firsTask = [SELECT Id,Status FROM Task WHERE Id = :inProgressLog.PC_ActionRecordId__c];
                //Complete first task
                firsTask.Status = 'Completed';
                firsTask = (Task) PC_Database.upd(firsTask, false);

                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();

                Test.StopTest();
                //Query the Log 2
                PC_SupportPlanActivityLog__c completedLog2 = [ SELECT ID,PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_SupportPlanActivity__c = :supPlanActy2.Id];

                system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
                system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);
            }
        } catch(Exception ex){
            system.debug('exception in testSPACriteriaOnTriggerRecordTaskWithoutRecValue>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    /*
      *This test case tests the execution of Support plan activity criteria on Previous task without Record value set as previousActivity
      * and 1st activity is of type user task. Support plan trigger Object is Task.
       */
    @isTest static void testSPACriteriaOnPrevTaskTriggerRecTask() {
        try{
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegistersForTask = [SELECT Id FROM PC_TriggerHandlerRegister__mdt
            WHERE PC_Active__c = true AND PC_sObject__c = :PC_Constants.PC_TASK AND PC_ApexClass__c = :PC_Constants.SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME];

            if (triggerHandlerRegistersForTask != null && !triggerHandlerRegistersForTask.isEmpty()) {
                createTestData();

                //Create Support Plan for Interaction object
                supportPlan2 = PC_Test_Setup.createSupportPlan();
                supportPlan2.Name = 'Test Task Support Plan';
                supportPlan2.PC_IsActive__c = true;
                supportPlan2.PC_TriggerEventObject__c = PC_Constants.PC_TASK;
                supportPlan2.PC_TriggerEventType__c = 'Insert/Update';
                supportPlan2.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supportPlan2.PC_TriggerEventCondition__c = '{"LstConditionsPerObject":[{"Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"High"}],"Logic":""}]}';
                supportPlan2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
                supportPlan2.PC_SupportPlan_Behavior__c = String.valueOf(PC_Constants.SupportPlanBehaviour.RunOncePerRecord);
                supportPlan2 = (PC_SupportPlan__c) PC_Database.ins(supportPlan2, false);

                //Create Support Plan Activity 2
                supPlanActy2 = PC_Test_Setup.createSupportPlanActivityToCreateRecord('Activity 2: Create Case 2');
                supPlanActy2.PC_SupportPlan__c = supportPlan2.Id;
                supPlanActy2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT;
                supPlanActy2.PC_ConditionOption__c = PC_Constants.PC_COND_OPTION_CONDITIONAL_BUILDER;
                supPlanActy2.PC_Conditional_Logic__c = '{"LstConditionsPerObject":[{"ObjectType":"Task","RecordValue":"previousActivity","Conditions":[{"ConditionNo":1,"FieldName":"Priority","FieldApiName":"Priority","Operator":"Equals","Type":"Picklist","Value":"Normal"}],"Logic":""}]}';
                supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);

                //Create Support Plan Activity 1
                supPlanActy1 = PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
                supPlanActy1.PC_UserTask_Fields__c = PC_Test_Setup.createUserTaskFieldsString(userTaskFieldsLabelMap);
                supPlanActy1.PC_NextActivityNumber__c = supPlanActy2.Id;
                supPlanActy1.PC_SupportPlan__c = supportPlan2.Id;
                supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

                supportPlan2.PC_InitialActivity__c = supPlanActy1.Id;
                supportPlan2 = (PC_SupportPlan__c) PC_Database.upd(supportPlan2, false);

                Test.StartTest();
                Task triggerTaskRecord = new Task();
                system.runAs(adminUser) {
                    triggerTaskRecord.Subject = 'Test Task 1';
                    triggerTaskRecord.PC_Channel__c = 'Call';
                    triggerTaskRecord.Status = 'Not Started';
                    triggerTaskRecord.Priority = 'High';
                    triggerTaskRecord = (Task) PC_Database.ins(triggerTaskRecord, false);
                }
                //Deliver the Support Plan Info Platform event with context "ExecuteActions"
                Test.getEventBus().deliver();
                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();

                //Query the Log 1
                PC_SupportPlanActivityLog__c inProgressLog = [SELECT ID, PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_TriggerRecordId__c = :triggerTaskRecord.Id AND PC_SupportPlanActivity__c = :supPlanActy1.Id];

                system.assertNotEquals(inProgressLog.PC_ActionRecordId__c, null);
                system.assertEquals(inProgressLog.PC_Status__c, PC_Constants.PC_LOG_STATUS_IN_PROGRESS);

                Task firsTask = [SELECT Id,Status FROM Task WHERE Id = :inProgressLog.PC_ActionRecordId__c];
                //Complete first task
                firsTask.Status = 'Completed';
                firsTask = (Task) PC_Database.upd(firsTask, false);

                //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
                Test.getEventBus().deliver();

                Test.StopTest();
                //Query the Log 2
                PC_SupportPlanActivityLog__c completedLog2 = [ SELECT ID,PC_ActionRecordId__c,PC_Status__c FROM PC_SupportPlanActivityLog__c
                WHERE PC_SupportPlanActivity__c = :supPlanActy2.Id];

                system.assertNotEquals(completedLog2.PC_ActionRecordId__c, null);
                system.assertEquals(completedLog2.PC_Status__c, PC_Constants.PC_LOG_STATUS_COMPLETED);
            }
        } catch(Exception ex){
            system.debug('exception in testSPACriteriaOnPrevTaskTriggerRecTask>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }
}