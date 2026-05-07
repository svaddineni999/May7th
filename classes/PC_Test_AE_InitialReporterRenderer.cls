/*********************************************************************************
Class Name      : PC_Test_AE_InitialReporterRenderer
Description     : Test Class for PC_AE_InitialReporterRendererController Class
Created By      : Xiukai Ning
Created Date    : 30-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Xiukai Ning          30-11-2018              Initial Version
*********************************************************************************/
@IsTest
public with sharing class PC_Test_AE_InitialReporterRenderer {

    private static Map<Object, Object> initialReporterObj = new Map<Object, Object>{'firstName'=>'','lastName'=>'','address'=>'','city'=>'','state'=>'','zip'=>'','email'=>'','phone'=>'','occupation'=>'', 'IRalsoSentReportToFDA'=>''};



    @isTest
    static void testInitialReporterDataPopulation() {

        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        Case caseRecord = [Select Id from Case  LIMIT 1];
        Account patient  = [Select Id from Account Limit 1];
        PC_AdverseEvent__c aeRec = [Select Id from PC_AdverseEvent__c LIMIT 1];
        Test.StartTest();
        system.runAs(adminUser) {
            PC_AE_InitialReporterRendererController objCntrl = new PC_AE_InitialReporterRendererController();
            PC_AE_InitialReporterRendererController.getInitialReporterData(null, null, String.valueOf(patient.Id));
            PC_AE_InitialReporterRendererController.getReporterDataBasedOnRole(String.valueOf(caseRecord.Id),'HCO');
            objCntrl.updateAdverseEvent(aeRec,initialReporterObj);
            PC_AE_InitialReporterRendererController.getDataFromAE(aeRec.Id,initialReporterObj);
        }
        Test.StopTest();
    }



    /*********************************************************************************
    Method Name    : setup
    Author         : Shishir Bansal
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @testSetup static void setup() {




        Account patient = new Account();
        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient.PC_Status__c = PC_Constants.ACTIVE;
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        Case programCase = PC_Test_Setup.createProgram(patient);
        //programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);

        PC_AdverseEvent__c aeRec = new PC_AdverseEvent__c();

        //insert Adverse Event Record

        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;

        aeRec.PC_Reporter_First_Name__c = 'TestFirst';
        aeRec.PC_Reporter_Last_Name__c = 'TestLast';
        aeRec.PC_ReporterAddress__c = '123 Lake';
        aeRec.PC_Reporter_City__c = 'Test City';
        aeRec.PC_Reporter_State__c = 'FL';
        aeRec.PC_Reporter_Country__c = 'US';
        aeRec.PC_Reporter_Zip_Code__c = '12345';
        aeRec.PC_Reporter_Email__c = 'test@test.com';
        aeRec.PC_Reporter_Phone__c = '1115557890';
        aeRec.PC_Adverse_Event_Reporter__c = 'Nurse';
        aeRec.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c = 'No';

        PC_Database.ins(aeRec, false);

        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, 'HCO');
        Account hcoAccount = new Account ();

        hcoAccount.PC_First_Name__c = 'firstHCO';
        hcoAccount.PC_Last_Name__c = 'lastHCO';
        hcoAccount.Name = 'firstHCO lastHCO';
        hcoAccount.RecordTypeId = recordTypeId;

        PC_Database.ins(hcoAccount);

        PC_Association__c association = PC_Test_Setup.createAssociations(programCase.Id , hcoAccount.Id , null , 'HCO');
        PC_Database.ins(association);

        PC_Address__c hcoAddress =  PC_Test_Setup.createAddress(hcoAccount.Id);
        PC_Database.ins(hcoAddress);

    }
}