/*******************************************************************************************
Class Name      : PC_Test_Task_Trigger 
Description     : Test methods for task trigger
Created By      : Deloitte
Created Date    : May 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                 May 30, 2016          Initial Version
Prachi Nandgaonkar,       	Nov 10, 2016          Renamed PC_Task_Subtype__c to PC_Channel__c
Shabda Bhujad
Tejas Patel				   July 12, 2017          PC-1875 ignore test if trigger is disabled in metadata
****************************************************************************************************************/
@isTest
public with sharing class PC_Test_Task_Trigger {
    
    public static final String ACCOUNT_NAME = 'Test Account';
    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 20;
    public static Boolean isTriggerActive = True;

    @isTest
    static void testTaskTrigger() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            // bulk creation of patient accounts
            List<Account> accounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            system.runAs(adminUser) {
                Test.StartTest();
                PC_Database.ins(accounts, false);
                // check if 20 patients are created for bulk testing
                system.assertEquals(accounts.size(), 20);
                Case programCase = PC_Test_Setup.newCase(accounts[0].Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                PC_Database.ins(programCase, false);
                Case biBvCase = PC_Test_Setup.newCase(programCase.Id, accounts[0].Id, PC_Constants.CASE_BI_BV_RECORD_TYPE);
                PC_Database.ins(biBvCase, false);
                // check if the case is created
                List<Task> patient1Tasks = PC_Test_Setup.createTasks(programCase, OBJECTS_NUMBER);
                PC_Database.ins(patient1Tasks, false);
                List<Task> patient2Tasks = PC_Test_Setup.createTasks(biBvCase, OBJECTS_NUMBER);
                PC_Database.ins(patient2Tasks, false);
                System.assertEquals(patient1Tasks.size(), 20);
                System.assertEquals(patient2Tasks.size(), 20);
                // update the task status to completed
                patient2Tasks[0].PC_Category__c = PC_CONSTANTS.PC_TASK_CATEGORY;
                patient2Tasks[0].PC_Sub_Category__c = PC_CONSTANTS.PC_TASK_SUBCATEGORY;
                patient2Tasks[1].PC_Category__c = PC_CONSTANTS.PC_TASK_CATEGORY;
                patient2Tasks[1].PC_Sub_Category__c = PC_CONSTANTS.PC_TASK_SUBCATEGORY;
                patient2Tasks[1].PC_Channel__c = null;
                PC_Database.upd(patient1Tasks);
                PC_Database.upd(patient2Tasks);
                // check if the close date is updated to today
                System.assertNotEquals(patient1Tasks[0].PC_Close_Date__c, Datetime.now());
                System.assertNotEquals(patient1Tasks[1].PC_Close_Date__c, Datetime.now());

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}