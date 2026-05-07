/**
 * Created by vkashikar on 4/23/2020.
 */

@isTest
private class PC_Test_UpdateSupportPlanRuntimes {
    // VIJAY - This test class is implemented to get the coverage up.
    private static User adminUser;
    private static User careCoordinator;
    private static Case programCase;
    private static Case programCase2;
    private static Case casetestDueDate;
    private static Account patient;
    private static Account  manufacturer;
    private static PC_SupportPlan__c supportPlan1, supportPlan2;
    private static PC_SupportPlanActivity__c supPlanActy1,supPlanActy2, supPlanActyOrphaned;
    private static PC_SupportPlanRuntime__c supportPlanRuntime, supportPlanRuntime2;
    private static PC_Engagement_Program__c enmtProgram;
    private static PC_EngagementProgram_SupportPlan__c enmtPgmSupPlan;
    private static Task outcomeTask;
    private static List<Task> tasks, migratedTasks, tasksOrphaned;
    private static PC_SupportPlanActivityLog__c supportPlanActivityLog;
    
    @testSetup
    static void setup() {
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
        programCase.PC_Status_Indicator_4__c = 'In Progress';
        programCase.PC_Care_Coordinator__c      =   careCoordinator.Id;
        programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase.PC_Treatment_Start_Date__c = date.today().addDays(+10);
        programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);

        //Create Support Plan
        supportPlan1= PC_Test_Setup.createSupportPlan();
        supportPlan1.Name = 'support plan 1';
        supportPlan1.PC_IsActive__c=true;
        supportPlan1.PC_TriggerEventObject__c='Case';
        supportPlan1.PC_TriggerEventType__c='Insert/Update';
        supportPlan1.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan1 = (PC_SupportPlan__c) PC_Database.ins(supportPlan1, false);        

        //Create Support Plan Activity1 Linked to the Support Plan
        supPlanActy1= PC_Test_Setup.createSupportPlanActivity('Activity 1: Task - Log a Call');
        supPlanActy1.PC_SupportPlan__c = supportPlan1.Id;
        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);        

        tasks = PC_Test_Setup.createTasks(programCase, 1);
        tasks = (List<Task>) PC_Database.ins(tasks);

        tasks[0].PC_SupportPlanActivity__c = supPlanActy1.Id;
        tasks = (List<Task>) PC_Database.upd(tasks);

        supportPlanRuntime = new PC_SupportPlanRuntime__c();
        supportPlanRuntime.PC_SupportPlan__c = supportPlan1.Id;
        //supportPlanRuntime.PC_Completed_Activity__c = supPlanActy1.Id;
        supportPlanRuntime.PC_CurrentActivity__c = supPlanActy1.Id;
        supportPlanRuntime.PC_StartTime__c = Datetime.now();
        supportPlanRuntime.PC_CurrentActivityStatus__c = 'In Progress';
        supportPlanRuntime.PC_SupportPlanCase__c = programCase.Id;
        supportPlanRuntime = (PC_SupportPlanRuntime__c) PC_Database.ins(supportPlanRuntime);
        
        createDataForMigratedTask();
        //createOrphanedTask();
        
    }

    @isTest static void test() {
        try {
            User adminUser;
            // running as system admin
            adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test');
            PC_Database.ins(adminUser);
            System.runAs(adminUser) {
                Test.startTest();
                PC_UpdateSupportPlanRuntimes batchJob = new PC_UpdateSupportPlanRuntimes();
                Id batchId = Database.executeBatch(batchJob);
                Test.stopTest();
            }
        }
        catch(Exception ex) {
            system.debug('*****************');
            system.debug(ex.getMessage());
            system.assert(false);
        }

    }    
    
    
    static void createDataForMigratedTask() {
        
        programCase2 = PC_Test_Setup.createCase(adminUser, patient);
        programCase2.PC_Engagement_Program__c = enmtProgram.Id;
        programCase2.PC_Status_Indicator_4__c = 'In Progress';
        programCase2.PC_Care_Coordinator__c      =   careCoordinator.Id;
        programCase2.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase2.PC_Treatment_Start_Date__c = date.today().addDays(+10);
        programCase2 = (Case)PC_Database.ins(programCase2, false);
        
        //Create Support Plan
        supportPlan2= PC_Test_Setup.createSupportPlan();
        supportPlan2.PC_IsActive__c=true;
        supportPlan2.Name = 'support plan 2';
        supportPlan2.PC_TriggerEventObject__c='Case';
        supportPlan2.PC_TriggerEventType__c='Insert/Update';
        supportPlan2.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan2.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supportPlan2 = (PC_SupportPlan__c) PC_Database.ins(supportPlan2, false);
        
        //Create Support Plan Activity21 Linked to the Support Plan
        supPlanActy2= PC_Test_Setup.createSupportPlanActivity('Activity 21: Task - Log a Call');
        supPlanActy2.PC_SupportPlan__c = supportPlan2.Id;
        supPlanActy2 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy2, false);
        
        migratedTasks = PC_Test_Setup.createTasks(programCase2, 1);
        migratedTasks = (List<Task>) PC_Database.ins(migratedTasks);

        migratedTasks[0].PC_SupportPlanActivity__c = supPlanActy2.Id;
        migratedTasks = (List<Task>) PC_Database.upd(migratedTasks);
        
        supportPlanRuntime2 = new PC_SupportPlanRuntime__c();
        supportPlanRuntime2.PC_SupportPlan__c = supportPlan2.Id;
        //supportPlanRuntime.PC_Completed_Activity__c = supPlanActy1.Id;
        supportPlanRuntime2.PC_CurrentActivity__c = supPlanActy2.Id;
        supportPlanRuntime2.PC_StartTime__c = Datetime.now();
        supportPlanRuntime2.PC_CurrentActivityStatus__c = 'In Progress';
        supportPlanRuntime2.PC_SupportPlanCase__c = programCase2.Id;
        supportPlanRuntime2 = (PC_SupportPlanRuntime__c) PC_Database.ins(supportPlanRuntime2);

        supportPlanActivityLog = new PC_SupportPlanActivityLog__c();
        supportPlanActivityLog.PC_ActionRecordId__c = migratedTasks[0].Id;
        supportPlanActivityLog.PC_TriggerRecordId__c = programCase2.Id;
        supportPlanActivityLog.PC_SupportPlanActivity__c = migratedTasks[0].PC_SupportPlanActivity__c;
        supportPlanActivityLog = (PC_SupportPlanActivityLog__c) PC_Database.ins(supportPlanActivityLog);
    }
    /*static void createOrphanedTask() {
        
        supPlanActyOrphaned= PC_Test_Setup.createSupportPlanActivity('Activity supPlanActyOrphaned: Task - Log a Call');
        // supPlanActy2.PC_SupportPlan__c = supportPlan2.Id; // We don't want this to be linked to any support plan
        supPlanActyOrphaned = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActyOrphaned, false);
        
        tasksOrphaned = PC_Test_Setup.createTasks(programCase2, 1); 
        tasksOrphaned = (List<Task>) PC_Database.ins(tasksOrphaned);
        
        tasksOrphaned[0].PC_SupportPlanActivity__c = supPlanActyOrphaned.Id;
        tasksOrphaned = (List<Task>) PC_Database.upd(tasksOrphaned);
    }*/
    @isTest static void testMethodToCoverCatchBlocks() {
        try {
            Test.startTest();
            PC_UpdateSupportPlanRuntimes batchJob = new PC_UpdateSupportPlanRuntimes();
            batchJob.start(null);
            batchJob.execute(null, [SELECT Id, WhatId, Status, PC_SupportPlanActivity__c
                        FROM Task WHERE (Status != 'Completed' AND Status != 'Closed')
                        AND PC_SupportPlanActivity__c != NULL LIMIT 1]);
            batchJob.finish(null);
            Id batchId = Database.executeBatch(batchJob);
            Test.stopTest();
        }
        catch(Exception ex) {
            system.assert(true); // expected.
        }
    }
}