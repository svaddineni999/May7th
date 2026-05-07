/*********************************************************************************************************
Class Name      : PC_Test_InfinitusBIService
Description     : Test class for Infinitus specific Pharmacy & Medical BI service via BRE.
Created By      : Chetna Mohapatra
Created Date    : April 21, 2022
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Chetna Mohapatra          April 21, 2022                    Initial Version
*********************************************************************************************************/
 @isTest
 public class PC_Test_InfinitusBIService {
     private static User adminUser;
     private static Account patient;
     private static Case programCase;
     private static Task task;


    @testSetup static void setup() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'Service22@test.com', 'test22');
        PC_Database.ins(adminUser);

        //Create Account
        Id accRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PC_BUSINESSACCOUNT_PATIENT_RECORD_TYPE);
        patient = PC_Test_Setup.createAccount('MyPatient',accRecordTypeId);
        patient = (Account) PC_Database.ins(patient, false);
        system.assertNotEquals(patient.Id, null);

        //Create Case
        programCase = PC_Test_Setup.createCase(adminUser, patient);
        PC_Database.ins(programCase,false);
        system.assertNotEquals(programCase.Id, null);

        //Create Task
        task = new Task();
        task.WhatId= programCase.Id;
        task.OwnerId= adminUser.Id;
        task.PC_Program__c= programCase.Id;
        task.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
        task.Status = PC_Constants.PC_TASK_STATUS_WAITING;
        PC_Database.ins(task,false);
        system.assertNotEquals(task.Id, null);

    }
    @isTest static void testCallout() {
        Case caseRecord = [Select Id from Case LIMIT 1];
        User adminUser22 = [Select Id from User WHERE username = 'Service22@test.com'];
        Task spTask= [Select Id from Task WHERE PC_Program__c=:caseRecord.Id LIMIT 1];
        System.runAs(adminUser22) {
            Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new PC_Infinitus_MockHttpResponseGenerator());
            // Call method to test which causes a fake response to be sent from the class that implements HttpCalloutMock.
            //Pharmacy BI Callout
           PC_SPPharmacyBenefitsInvestigation.doPharmacyEbenefitsCallout(caseRecord.Id, spTask.Id);
            //Medical BI Callout
            PC_SPMedicalBenefitsInvestigation.doMedicalBenefitsCallout(caseRecord.Id,spTask.Id);
            Test.stopTest();
        }

    }
}