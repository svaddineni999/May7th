/**************************************************************************************
Apex Class Name     : PC_Test_HomeProgramActivitiesController 
Description         : This class is used for testing PC_HomeProgramActivitiesController ;
CreatedBy           : Deloitte
Created Date        : 11 July 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Cameron Reid              11-July-2016               Initial version
Tejas Patel				  11-Oct-2017				 [PC-2337] Increase Code Coverage
Hitha Avalakki            Feb-26-2021                [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
*************************************************************************************/
@isTest(seeAllData=False) 
private class PC_Test_HomeProgramActivitiesController{
    private static User objUser;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    private static List<Case> programCases;

    /*********************************************************************************
    Method Name    : createTestUser
    Author         : Tejas Patel
    Description    : This method is used for creating test user
    Return Type    : void
    *********************************************************************************/
    private static void createTestUser() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test87.com', 'test87');
        PC_Database.ins(objUser);
    }

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    *********************************************************************************/
    private static void createTestData() {
        createTestUser();
        system.runAs(objUser) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins(oDoc);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment);
            
            //Create 1 patient accounts
        	List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', 1, PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAccounts);
            System.assertEquals(1, patientAccounts.size());

            //Create 1 program cases
            //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
            programCases = PC_Test_Setup.createProgramCases(patientAccounts, 1);
            PC_Database.ins(programCases);
            system.assertEquals(1, programCases.size());

            Task t1= new Task();
            t1.ActivityDate = date.today();
            t1.subject = 'Test Subject - today - In Progress';
            t1.status = 'In Progress';
            t1.ownerId = objUser.id;
            t1.WhatId = programCases[0].id;
            PC_Database.ins(t1);
            
            Task t2= new Task();
            t2.ActivityDate = date.today().addDays(1);
            t2.subject = 'Test Subject - tomorrow - Completed - Starred';
            t2.status = 'Completed';
            t2.ownerId = objUser.id;
            t2.PC_Starred__c = true;
            PC_Database.ins(t2);
            
            Task t3= new Task();
            t3.ActivityDate = date.today().addDays(-1);
            t3.subject = 'Test Subject - yesterday - In Progress - Starred';
            t3.status = 'In Progress';
            t3.ownerId = objUser.id;
            t3.PC_Starred__c = true;
            PC_Database.ins(t3);
            
            Task t4= new Task();
            t4.ActivityDate = date.today();
            t4.subject = 'Test Subject - Today - In Progress - Starred';
            t4.status = 'In Progress';
            t4.ownerId = objUser.id;
            t4.PC_Starred__c = true;
            PC_Database.ins(t4);
            
            Task t5= new Task();
            t5.ActivityDate = date.today();
            t5.subject = 'Test Subject - Today - Completed';
            t5.status = 'Completed';
            t5.ownerId = objUser.id;
            PC_Database.ins(t5);
            
            Task t6= new Task();
            t6.ActivityDate = date.today().addDays(-6);
            t6.subject = 'Test Subject - Overdue';
            t6.status = 'Completed';
            t6.ownerId = objUser.id;
            PC_Database.ins(t6);
            
            Task t7= new Task();
            t7.ActivityDate = date.today().addDays(-6);
            t7.subject = 'Test Subject - Overdue - In Progress - Starred';
            t7.status = 'In Progress';
            t7.ownerId = objUser.id;
            t7.PC_Starred__c = true;
            PC_Database.ins(t7);
            
            Task t8= new Task();
            t8.ActivityDate = date.today().addDays(1);
            t8.subject = 'Test Subject - tomorrow - In Progress - Starred';
            t8.status = 'In Progress';
            t8.ownerId = objUser.id;
            t8.PC_Starred__c = true;
            PC_Database.ins(t8);
        }
    }
    
    /*********************************************************************************
    Method Name    : testGetOverDueActivities
    Author         : Cameron Reid
    Description    : This method is used for testing "GetOverDueActivities"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetOverDueActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesController.activityWrapper[] results = PC_HomeProgramActivitiesController.getOverDueActivities(null, null, null);
            
            System.assertNotEquals(null, results );
            System.assertEquals(2, results.size());
            
            Test.StopTest();
         }
     }
     
     /*********************************************************************************
    Method Name    : testGetActivitiesDueToday
    Author         : Cameron Reid
    Description    : This method is used for testing "getActivitiesDueToday"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetActivitiesDueToday(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesController.activityWrapper[] results = PC_HomeProgramActivitiesController.getActivitiesDueToday(null);
            
            System.assertNotEquals(null, results );
            System.assertEquals(2, results.size());
            
            Test.StopTest();
         }
     }
     
      /*********************************************************************************
    Method Name    : testGetActivitiesDueToday
    Author         : Cameron Reid
    Description    : This method is used for testing "getActivitiesDueTomorrow"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetActivitiesDueTomorrow(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesController.activityWrapper[] results = PC_HomeProgramActivitiesController.getActivitiesDueTomorrow(null);
            
            System.assertNotEquals(null, results );
            System.assertEquals(1, results.size());
            
            Test.StopTest();
         }
     }
     
    /*********************************************************************************
    Method Name    : testgetStarredActivities
    Author         : Cameron Reid
    Description    : This method is used for testing "getStarredActivities"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetStarredActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesController.activityWrapper[] results = PC_HomeProgramActivitiesController.getStarredActivities(null,null,null);
            
            System.assertNotEquals(null, results );
            System.assertEquals(4, results.size());
            
            Test.StopTest();
         }
     }
     
     /*********************************************************************************
    Method Name    : testUpdateTaskStar
    Author         : Cameron Reid
    Description    : This method is used for testing "getStarredActivities"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testUpdateTaskStar(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesController.activityWrapper[] results = PC_HomeProgramActivitiesController.getStarredActivities(null,null,null);
            
            
            System.assertNotEquals(null, results );
            System.assertEquals(4, results.size());
            Integer resultCount = results.size();
            
            Task t1= new Task();
            t1.ActivityDate = date.today();
            t1.subject = 'Test Subject - today - In Progress';
            t1.status = 'In Progress';
            t1.ownerId = objUser.id;
            t1.PC_Starred__c = false;
            PC_Database.ins(t1);
            
            results = PC_HomeProgramActivitiesController.getStarredActivities(null,null,null);
            System.assertNotEquals(null, results );
            System.assertEquals(4, results.size());
            
            PC_HomeProgramActivitiesController.updateTask(t1.id);
            
            results = PC_HomeProgramActivitiesController.getStarredActivities(null,null,null);
            System.assertNotEquals(null, results );
            System.assertEquals(5, results.size());
            
            PC_HomeProgramActivitiesController.updateTask(t1.id);
            
            results = PC_HomeProgramActivitiesController.getStarredActivities(null,null,null);
            System.assertNotEquals(null, results );
            System.assertEquals(resultCount, results.size());
            
            Test.StopTest();
         }
     }
     /*********************************************************************************
    Method Name    : testgetThisWeekActivities
    Author         : Tejas Patel
    Description    : This method is used for testing "getThisWeekActivities"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testgetThisWeekActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesController.activityWrapper[] results = PC_HomeProgramActivitiesController.getThisWeekActivities(null,null);
            System.assertNotEquals(null, results );
            System.assertEquals(5, results.size()); //IN PROGRESS tasks 5

            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testupdatePriority
    Author         : Tejas Patel
    Description    : This method is used for testing "updatePriority"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testupdatePriority(){
        createTestUser();
        system.runAs(objUser) {
            Test.StartTest();

            Task t1= new Task();
            t1.ActivityDate = date.today();
            t1.subject = 'Test Subject - today - In Progress';
            t1.status = 'In Progress';
            t1.ownerId = objUser.id;
            t1.PC_Starred__c = false;
            PC_Database.ins(t1);

            PC_HomeProgramActivitiesController.activityWrapper results = PC_HomeProgramActivitiesController.updatePriority(t1.id);
           system.debug('@@@@ updatePriority :' + results);

            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testcloseTask
    Author         : Tejas Patel
    Description    : This method is used for testing "closeTask"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testcloseTask(){
        createTestUser();
        system.runAs(objUser) {
            Test.StartTest();

            Task t1= new Task();
            t1.ActivityDate = date.today();
            t1.subject = 'Test Subject - today - In Progress';
            t1.status = 'In Progress';
            t1.ownerId = objUser.id;
            t1.PC_Starred__c = false;
            PC_Database.ins(t1);

            PC_HomeProgramActivitiesController.activityWrapper results = PC_HomeProgramActivitiesController.closeTask(t1.id);

            system.debug('@@@@ closeTask :' + results);

            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testoverrideAlert
    Author         : Tejas Patel
    Description    : This method is used for testing "overrideAlert"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testoverrideAlert(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            //Create Alert
            PC_Alert__c alert	= new PC_Alert__c();
            alert.PC_Program__c = programCases[0].id;
            alert.PC_Date_of_Alert__c = date.today();
            PC_Database.ins(alert);
            system.assertEquals(alert.PC_Program__c, programCases[0].id);

            PC_HomeProgramActivitiesController.overrideAlert(alert.id);
            Test.StopTest();
         }
     }
 }