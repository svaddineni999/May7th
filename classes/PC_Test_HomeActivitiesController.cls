/**************************************************************************************
Apex Class Name     : PC_Test_HomeActivitiesController 
Description         : This class is used for testing PC_HomeActivitiesController ;
CreatedBy           : Deloitte
Created Date        : 23 Mar 2018
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Sahil Garg              23 Mar 2018              Initial version
Soumya Soumya           25 May 2018              [PC-42] Home Page Grouping
Hitha Avalakki          26 Feb 2021              [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
*************************************************************************************/
@isTest(seeAllData=False) 
private class PC_Test_HomeActivitiesController{
    private static User objUser;
    private static User objUser2;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    private static List<Case> programCases;
    private static String validActionComponent = 'PatientConnect__PC_eLetter2';
    private static String invalidActionComponent = 'INVALID';

    /*********************************************************************************
    Method Name    : createTestUser
    Author         : Tejas Patel
    Description    : This method is used for creating test user
    Return Type    : void
    *********************************************************************************/
    private static void createTestUser() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test87.com', 'test87');
        PC_Database.ins(objUser);

        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user2@test87.com', 'test2');
        PC_Database.ins(objUser2);
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
            //PC_Database.ins(oDoc);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            //PC_Database.ins(oAttachment);
            
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
            t1.PC_ActionComponent__c = validActionComponent;
            PC_Database.ins(t1);
            
            Task t2= new Task();
            t2.ActivityDate = date.today().addDays(1);
            t2.subject = 'Test Subject - tomorrow - Completed - Starred';
            t2.status = 'Completed';
            t2.ownerId = objUser.id;
            t2.PC_Starred__c = true;
            t2.PC_ActionComponent__c = validActionComponent;
            PC_Database.ins(t2);
            
            Task t3= new Task();
            t3.ActivityDate = date.today().addDays(-1);
            t3.subject = 'Test Subject - yesterday - In Progress - Starred';
            t3.status = 'In Progress';
            t3.ownerId = objUser.id;
            t3.PC_Starred__c = true;
            t3.PC_ActionComponent__c = validActionComponent;
            PC_Database.ins(t3);
            
            Task t4= new Task();
            t4.ActivityDate = date.today();
            t4.subject = 'Test Subject - Today - In Progress - Starred';
            t4.status = 'In Progress';
            t4.ownerId = objUser.id;
            t4.PC_Starred__c = true;
            t4.PC_ActionComponent__c = validActionComponent;
            PC_Database.ins(t4);
            
            Task t5= new Task();
            t5.ActivityDate = date.today();
            t5.subject = 'Test Subject - Today - Completed';
            t5.status = 'Completed';
            t5.ownerId = objUser.id;
            t5.PC_ActionComponent__c = validActionComponent;
            PC_Database.ins(t5);
            
            Task t6= new Task();
            t6.ActivityDate = date.today().addDays(-6);
            t6.subject = 'Test Subject - Overdue';
            t6.status = 'Completed';
            t6.ownerId = objUser.id;
            t6.PC_ActionComponent__c = validActionComponent;
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

        system.runAs(objUser2) {
            Task t9= new Task();
            t9.ActivityDate = date.today().addDays(1);
            t9.subject = 'Test Subject - tomorrow - In Progress - Starred';
            t9.status = 'In Progress';
            t9.ownerId = objUser2.id;
            t9.PC_Starred__c = true;
            PC_Database.ins(t9);
        }
    }
    
 

     /*********************************************************************************
    Method Name    : testgetThisWeekActivities
    Author         : Tejas Patel
    Description    : This method is used for testing "getThisWeekActivities"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testgetAllTasksPagination(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
              
        //     PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getAllTasksPagination(1,3,null,null,false);
            System.assertNotEquals(null, results );

            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getAllTasksPagination(1,3,null,null,true);
            System.assert(results2.activityWrapper.size() >= results.activityWrapper.size());

            Test.StopTest();
         }
     }

    @isTest static void testgetHighPriorityTasksPagination(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_Alert__c alert	= new PC_Alert__c();
            alert.PC_Program__c = programCases[0].id;
            alert.PC_Date_of_Alert__c = date.today();
            PC_Database.ins(alert);
             PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.activityWrapper actWrapper= new  PC_HomeActivitiesController.activityWrapper(altWrapper);
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getHighPriorityTasksPagination(1,3, null, null, false);
            System.assertNotEquals(null, results );

            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getHighPriorityTasksPagination(1,3, null, null, true);
            System.assert(results2.activityWrapper.size() >= results.activityWrapper.size());

           

            Test.StopTest();
         }
     }

    @isTest static void testTasksWithinRange() {
        createTestData();
        system.runAs(objUser) {
            Test.startTest();
            Date today = date.today();
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getAllTasksPagination(1,3, null, today, true);
            system.debug('*********');
            system.debug(results.activityWrapper.size());
            System.assertNotEquals(null, results );

            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getAllTasksPagination(1,3, today.addDays(3), today.addDays(6), true);
            system.debug(results2.activityWrapper.size());
            System.assert(results2.activityWrapper.size() == 0);

            Test.stopTest();
        }
    }

    @isTest static void testgetOverDueActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_Alert__c alert	= new PC_Alert__c();
            alert.PC_Program__c = programCases[0].id;
            alert.PC_Date_of_Alert__c = date.today();
            PC_Database.ins(alert);
             PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.activityWrapper actWrapper= new  PC_HomeActivitiesController.activityWrapper(altWrapper);
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getOverDueActivities(1,3, null, null, false);
            System.assertNotEquals(null, results );

            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getOverDueActivities(1,3, null, null, true);
            System.assert(results2.activityWrapper.size() >= results.activityWrapper.size());

            Test.StopTest();
         }
     }

    @isTest static void testgetActivitiesDueToday(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_Alert__c alert	= new PC_Alert__c();
            alert.PC_Program__c = programCases[0].id;
            alert.PC_Date_of_Alert__c = date.today();
            PC_Database.ins(alert);
             PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.activityWrapper actWrapper= new  PC_HomeActivitiesController.activityWrapper(altWrapper);
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getActivitiesDueToday(1,3, null, null, false);
            System.assertNotEquals(null, results );

            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getActivitiesDueToday(1,3, null, null, true);
            System.assert(results2.activityWrapper.size() >= results.activityWrapper.size());

            Test.StopTest();
         }
     }

    @isTest static void testgetActivitiesDueTomorrow(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_Alert__c alert	= new PC_Alert__c();
            alert.PC_Program__c = programCases[0].id;
            alert.PC_Date_of_Alert__c = date.today();
            PC_Database.ins(alert);
             PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.activityWrapper actWrapper= new  PC_HomeActivitiesController.activityWrapper(altWrapper);
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getActivitiesDueTomorrow(1,3, null, null, false);
            System.assertNotEquals(null, results );

            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getActivitiesDueTomorrow(1,3, null, null, true);
            System.assert(results2.activityWrapper.size() >= results.activityWrapper.size());

            Test.StopTest();
         }
     }

    @isTest static void testgetAllAlertsPagination(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_Alert__c alert	= new PC_Alert__c();
            alert.PC_Program__c = programCases[0].id;
            alert.PC_Date_of_Alert__c = date.today();
            PC_Database.ins(alert);
             PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.activityWrapper actWrapper= new  PC_HomeActivitiesController.activityWrapper(altWrapper);
            PC_HomeActivitiesController.pageActivityWrapper results = PC_HomeActivitiesController.getAllAlertsPagination(1,3,false);
            System.assertNotEquals(null, results );
            PC_HomeActivitiesController.pageActivityWrapper results2 = PC_HomeActivitiesController.getAllAlertsPagination(1,3,true);
            System.assertNotEquals(null, results2 );
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

            PC_HomeActivitiesController.activityWrapper results = PC_HomeActivitiesController.updatePriority(t1.id);
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

            PC_HomeActivitiesController.activityWrapper results = PC_HomeActivitiesController.closeTask(t1.id);

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

            PC_HomeActivitiesController.overrideAlert(alert.id);
            Test.StopTest();
         }
     }
    /*********************************************************************************
    Method Name    : testgetAllGroupedByTasks
    Description    : This method is used for testing "getAllGroupedByTasks"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testGetAllGroupedByTasks(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();

        //     PC_HomeActivitiesController.alertWrapper altWrapper= new  PC_HomeActivitiesController.alertWrapper(alert);
            PC_HomeActivitiesController.groupedActivityWrapper results = PC_HomeActivitiesController.getAllGroupedByTasks('Physician',1,3,0, false);
            System.assertNotEquals(null, results );
           	PC_HomeActivitiesController.groupedActivityWrapper patientresults = PC_HomeActivitiesController.getAllGroupedByTasks('Patient',1,3,0, false);
            System.assertNotEquals(null, patientresults );

            PC_HomeActivitiesController.groupedActivityWrapper patientresults2 = PC_HomeActivitiesController.getAllGroupedByTasks('Patient',1,3,0, true);
            System.assert(patientresults2.activityMapWrapper.size() >= patientresults.activityMapWrapper.size());
            Test.StopTest();
         }
     }
   	/*********************************************************************************
    Method Name    : testGetFilterByValues
    Description    : This method is used for testing "getAllGroupedByTasks"
    Return Type    : void
    *********************************************************************************/
    @isTest static void testGetFilterByValues(){

        Map<String, String> results = PC_HomeActivitiesController.getFilterByValues();
        System.assertNotEquals(null, results );

     }
 }