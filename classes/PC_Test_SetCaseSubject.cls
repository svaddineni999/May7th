/**
 * Created by tejapatel on 10/19/2020.
 */
/*********************************************************************************
Class Name      : PC_Test_SetCaseSubject
Description     : Test class for Case Subject update.
Created By      : Deloitte
Created Date    : Oct 20, 2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tejas Patel                 Oct 20, 2020           Initial Version
*********************************************************************************/
@isTest(seeAllData=false)
public with sharing class PC_Test_SetCaseSubject {
    private static User adminUser;
    private static ID programCaseType       = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE,PC_Constants.CASE_PROGRAM_RECORD_TYPE);
    private static ID enrollmentCaseType    = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE,PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
    private static Id serviceCaseType       = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE,PC_Constants.CASE_PA_RECORD_TYPE);

    private static Account patient;
    private static Account  manufacturer;
    private static PC_Applicant__c applicant;

    private static PC_Engagement_Program__c enmtProgram;

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Haritha Reddy
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        patient = PC_Test_Setup.createPatient('TestAccount');
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        applicant = PC_Test_Setup.createApplicant('TestApplicant');
        applicant = (PC_Applicant__c)PC_Database.ins(applicant, false);
        // check if patient is created
        system.assertNotEquals(applicant.Id, null);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram('TestPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c = 'TestPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);
    }

    @isTest static void testEnrollmentCase() {
        createTestData();
        system.runAs(adminUser){
            Test.startTest();
                List<Case> enrollmentCases = new List<Case>();
                Case enrollmentCase1 = new Case();
                enrollmentCase1.RecordTypeId = enrollmentCaseType;
                enrollmentCases.add(enrollmentCase1);

                Case enrollmentCase2 = new Case();
                enrollmentCase2.RecordTypeId = enrollmentCaseType;
                enrollmentCase2.PC_ActiveApplicant__c = applicant.Id;
                //enrollmentCase2.PC_ActiveApplicant__r = applicant;
                enrollmentCases.add(enrollmentCase2);

                Case enrollmentCase3 = new Case();
                enrollmentCase3.RecordTypeId = enrollmentCaseType;
                enrollmentCase3.PC_ActiveApplicant__c = applicant.Id;
                //enrollmentCase3.PC_ActiveApplicant__r = applicant;
                enrollmentCase3.AccountId = patient.Id;
                //enrollmentCase3.Account = patient;
                enrollmentCases.add(enrollmentCase3);

                Case enrollmentCase4 = new Case();
                enrollmentCase4.RecordTypeId = enrollmentCaseType;
                enrollmentCase4.PC_ActiveApplicant__c = applicant.Id;
                //enrollmentCase4.PC_ActiveApplicant__r = applicant;
                enrollmentCase4.AccountId = patient.Id;
                //enrollmentCase4.Account = patient;
                enrollmentCase4.PC_Engagement_Program__c = enmtProgram.Id;
                //enrollmentCase4.PC_Engagement_Program__r = enmtProgram;
                enrollmentCases.add(enrollmentCase4);

                enrollmentCases = (List<Case>) PC_Database.ins(enrollmentCases);
                List<Case> getCases = [SELECT Id, AccountId, Account.PC_First_Name__c, Account.PC_Last_Name__c, PC_Engagement_Program__c, PC_Engagement_Program__r.Name,
                        PC_ActiveApplicant__c, PC_ActiveApplicant__r.PC_First_Name__c, PC_ActiveApplicant__r.PC_Last_Name__c, Type, Subject FROM Case];
                for (Case e : getCases){
                    if(e.AccountId != null){
                        system.assertEquals(e.Subject.contains(e.Account.PC_First_Name__c),true);
                    }else if(e.PC_ActiveApplicant__c != null){
                        system.assertEquals(e.Subject.contains(e.PC_ActiveApplicant__r.PC_First_Name__c),true);
                    }else{
                        system.assertEquals(e.Subject.contains(e.Type),true);
                    }
                }
            Test.stopTest();
        }
    }
}