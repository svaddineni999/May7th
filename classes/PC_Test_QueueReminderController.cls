/*********************************************************************************************************
Class Name    	: PC_Test_QueueReminderController
Description     : Test class for PC_QueueReminderController
Created By      : Deloitte
Created Date    : May 4, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti             May 4, 2021           Initial Version
****************************************************************************************************************/

@IsTest
public with sharing class PC_Test_QueueReminderController{

    private static User objUser;
    private static PC_SupportPlan__c oSupPlan;
    private static final String USER_ALIAS = 'test1';
    private static final String USER_EMAIL = 'user@t1234.com';

    @testSetup static void createTestData(){
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, USER_EMAIL, USER_ALIAS);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser){
            oSupPlan = PC_Test_Setup.createSupportPlan();
            oSupPlan.PC_TriggerEventObject__c = PC_Constants.getQualifiedAPIName('PC_Interaction__c');
            PC_Database.ins(oSupPlan, false);
        }
    }

    @isTest private static void testGetReminderOptions(){
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        system.runAs(objUser){
            Test.startTest();
            PC_SupportPlan__c supportPlan = [SELECT Id, PC_TriggerEventObject__c FROM PC_SupportPlan__c LIMIT 1];
            PC_QueueReminderController.ReminderOptions resultOptions = PC_QueueReminderController.getReminderOptions(supportPlan.Id);
            Test.stopTest();
        }
    }
}