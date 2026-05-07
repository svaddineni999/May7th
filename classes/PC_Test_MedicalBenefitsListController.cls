/*********************************************************************************
Class Name        : PC_Test_MedicalBenefitsListController
Description       : Test Class for PC_MedicalBenefitsListController Class
Created By        : Haritha Reddy
Created Date      : 13-12-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          08-04-2018              Initial Version
Shishir Bansal        10-Dec-2019              [PC-5792] Avoid hardcoding of string variable
*********************************************************************************/
@isTest
public with sharing class PC_Test_MedicalBenefitsListController {
    private static User adminUser;
    private static Case programCase;
    private static List<Id> caseList = new List<Id>();
    private static PC_Program_Coverage__c programCoverage;
    private static memberPlan memberPlan;
    private static coverageBenefit coverageBenefit;
    private static coverageBenefitItem coverageBenefitItem;
    @testSetup static void setUp() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);
        PC_Test_Setup.assignHealthCloudPermissionSet(adminUser.Id);
    }
    private static void createTestData() {
        adminUser = [SELECT ID FROM User LIMIT 1];
        Account patient = PC_Test_Setup.createSampleAccount(PC_Constants.EMPTY_STRING, PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);
        caseList.add(programCase.Id);

        //insert Program Coverage Record
        Id medicalCoverageRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);
        programCoverage = new PC_Program_Coverage__c();
        programCoverage.PC_Program__c = programCase.Id;
        programCoverage.recordTypeId = medicalCoverageRecordTypeId;
        PC_Database.ins(programCoverage, false);

        memberPlan = new memberPlan();
        memberPlan.Name = 'TestPlan';
        memberPlan.MemberId = patient.Id;
        PC_Database.ins(memberPlan, false);

        //insert Coverage Benefit Record
        coverageBenefit =  new coverageBenefit();
        coverageBenefit.Name = 'Test Coverage Benefit';
        coverageBenefit.MemberPlanId = memberPlan.Id;
        coverageBenefit.PC_ProgramCoverage__c = programCoverage.Id;
        coverageBenefit.PC_CoverageLevel__c = PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;
        PC_Database.ins(coverageBenefit, false);

        //insert Coverage Benefit Item Record
        coverageBenefitItem =  new coverageBenefitItem();
        coverageBenefitItem.Name = 'Test Coverage Benefit Item';
        coverageBenefitItem.CoverageBenefitId = coverageBenefit.Id;
        coverageBenefitItem.BenefitCategory = PC_Constants.PC_BENEFITCATEGORY_PRODUCT;
        PC_Database.ins(coverageBenefitItem, false);
    }

    @isTest
    static void testInitialDataLoad() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_MedicalBenefitsListController.getRelProgramCoverages(caseList);
        }
        Test.StopTest();
    }
}