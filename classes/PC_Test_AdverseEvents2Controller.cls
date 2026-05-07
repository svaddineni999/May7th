/*********************************************************************************
Class Name      :   PC_Test_AdverseEvents2Controller
Description        : Test Class for PC_AdverseEvents2Controller Class
Created By        : Haritha Reddy
Created Date     : 13-12-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          13-12-2018              Initial Version
Shishir Bansal         10-11-2019              [PC-5570]  added few AE records with parent child relation and assert statement
*********************************************************************************/
@isTest
public with sharing class PC_Test_AdverseEvents2Controller {
    private static User adminUser;
    private static Case programCase;
    private static PC_Suspect_Prescription__c spRec = new PC_Suspect_Prescription__c();
    private static List<Id> caseList = new List<Id>();
    private static PC_AdverseEvent2__c aeRec;
    private static PC_Prescription__c prescription;
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        Account patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);
        caseList.add(programCase.Id);

        //insert Adverse Event Record
        aeRec = new PC_AdverseEvent2__c();
        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;
        aeRec.PC_Patient_Identifier__c = patient.Id;
        aeRec.PC_Race__c = 'White';
        aeRec.PC_Gender__c= 'Male';
        aeRec.PC_VersionNumber__c= 1;
        PC_Database.ins(aeRec, false);

        PC_AdverseEvent2__c  parentAERecord = new PC_AdverseEvent2__c();
        parentAERecord = PC_Test_Setup.newAdverseEvent2(patient.Id);
        parentAERecord.PC_Care_Program__c = programCase.Id;
        parentAERecord.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;
        parentAERecord.PC_VersionNumber__c = 1;

        PC_Database.ins(parentAERecord, false);
        PC_AdverseEvent2__c  childAERecord = new PC_AdverseEvent2__c();
        childAERecord = PC_Test_Setup.newAdverseEvent2(patient.Id);
        childAERecord.PC_Care_Program__c = programCase.Id;
        childAERecord.PC_ParentAdverseEvent__c = parentAERecord.Id;
        childAERecord.PC_VersionNumber__c = 2;

        PC_Database.ins(childAERecord, false);




        //insert prescription Record related to Program Case
        prescription = new PC_Prescription__c();
        prescription.PC_Rx_Start_Date__c = date.today().addDays(-10);
        prescription.PC_Rx_End_Date__c = date.today().addDays(10);
        prescription.PC_Program_Case__c = programCase.Id;
        PC_Database.ins(prescription, false);

        //insert Suspect prescription Record related to Adverse Event
        spRec.PC_Adverse_Event2__c = aeRec.Id;
        PC_Database.ins(spRec, false);

    }

    @isTest
    static void testInitialDataLoad() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_AdverseEvents2Controller cntrlObj = new PC_AdverseEvents2Controller();


            PC_AdverseEvents2Controller.InitData initData = new PC_AdverseEvents2Controller.InitData();

            initData = PC_AdverseEvents2Controller.getRelAERecs(caseList);
            PC_AdverseEvents2Controller.getAEDownloadPDFPageName();
            PC_AdverseEvents2Controller.getAdverseEventConfigData(aeRec.Id);

           // system.assert(initData.AEList.size()>0);



        }
        Test.StopTest();
    }
}