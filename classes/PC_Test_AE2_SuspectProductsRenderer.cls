/*********************************************************************************
Class Name      :   PC_Test_AE_SuspectProductsRenderer
Description        : Test Class for PC_Test_AE2_SuspectProductsRenderer Class
Created By        : Haritha Reddy
Created Date     : 12-12-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          12-12-2018              Initial Version
*********************************************************************************/
@isTest
public with sharing class PC_Test_AE2_SuspectProductsRenderer {
    private static User adminUser;
    private static Case programCase;
    private static PC_AdverseEvent2__c aeRec;
    private static PC_Suspect_Prescription__c spRec;
    private static PC_Prescription__c prescription;
    private static PC_AE2_SuspectProductsRendererController.SuspectPrescriptionWrapper suspectPresObj = new PC_AE2_SuspectProductsRendererController.SuspectPrescriptionWrapper();
    private static Map<Object, Object> suspectProductInfoObj = new Map<Object, Object>();
    private static Map<Object, Object> suspectProductInfoObj1 = new Map<Object, Object>
    {'product'=>'Asprin','ndc'=>'123','lot'=>'34','expirationDate'=>'','productStrength'=>'2','manufacturer'=>'ABE',
    'concomitant'=>'','dose'=>'3','frequency'=>'1','route'=>'Oral','diagnosis'=>'','prodCompounded'=>'Yes','eventAbated'=>'',
    'prodOTC'=>'No','eventReappeared'=>'yes','therapyStartDate'=>'','therapyEndDate'=>''};

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

        //insert Adverse Event Record
        aeRec = new PC_AdverseEvent2__c();
        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;
        aeRec.PC_Patient_Identifier__c = patient.Id;
        aeRec.PC_Race__c = 'White';
        aeRec.PC_Gender__c= 'Male';
        PC_Database.ins(aeRec, false);

        //insert prescription Record related to Program Case
        prescription = new PC_Prescription__c();
        prescription.PC_Rx_Start_Date__c = date.today().addDays(-10);
        prescription.PC_Rx_End_Date__c = date.today().addDays(10);
        prescription.PC_Program_Case__c = programCase.Id;
        PC_Database.ins(prescription, false);

        //insert prescription Record related to Program Case
        spRec = new PC_Suspect_Prescription__c();
        spRec.PC_Adverse_Event2__c = aeRec.Id;
        PC_Database.ins(spRec, false);

        List<String> delSPList = new List<String>();
        delSPList.add(spRec.Id);

        suspectProductInfoObj1.put('deletedSPList',delSPList);
    }

    @isTest
    static void testInitialDataLoad() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_AE2_SuspectProductsRendererController cntrlObj = new PC_AE2_SuspectProductsRendererController();
            PC_AE2_SuspectProductsRendererController.getPrescriptionData(programCase.Id, aeRec.Id, true,false);
            PC_AE2_SuspectProductsRendererController.prePopulateSuspectPrescriptionForm(null,null,prescription.Id, suspectProductInfoObj);

            List<PC_AE2_SuspectProductsRendererController.SuspectPrescriptionWrapper> newSPList = new List<PC_AE2_SuspectProductsRendererController.SuspectPrescriptionWrapper>();
            suspectPresObj = PC_AE2_SuspectProductsRendererController.addSuspectPrescription(aeRec.Id, suspectProductInfoObj1);
            newSPList.add(suspectPresObj);
            suspectProductInfoObj1.put('newSuspectPrescriptionList',newSPList);
            suspectProductInfoObj1.put('updatedSuspectPrescriptionList',newSPList);


            cntrlObj.updateAdverseEvent(aeRec, suspectProductInfoObj1);

        }
        Test.StopTest();
    }
}