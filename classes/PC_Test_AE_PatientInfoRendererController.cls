/*********************************************************************************
Class Name      :   PC_Test_AE_PatientInfoRendererController
Description        : Test Class for PC_AE_PatientInfoRendererController Class
Created By        : Haritha Reddy
Created Date     : 28-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          28-11-2018              Initial Version
*********************************************************************************/
@isTest
public class PC_Test_AE_PatientInfoRendererController {
    private static User adminUser;
    private static Case programCase;
    private static PC_AdverseEvent__c aeRec;
    private static Map<Object, Object> patientInfoObj = new Map<Object, Object>{'patId'=>'','age'=>null,'ageType'=>'Year(s)','dob'=>'1992-04-08','gender'=>'','weight'=>null,'weightType'=>'','ethnicity'=>'','race'=>'White'};

    /*********************************************************************************
Method Name    : createTestData
Author         : Haritha Reddy
Description    : This method is used for creating test data
Return Type    : void
Parameter      :
*********************************************************************************/

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
        aeRec = new PC_AdverseEvent__c();
        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;
        aeRec.PC_Patient_Identifier__c = '1234';
        aeRec.PC_Race__c = 'White';
        aeRec.PC_Gender__c= 'Male';

        PC_Database.ins(aeRec, false);
    }

    @isTest
    static void testPatientInfoRetrieval() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_AE_PatientInfoRendererController objCntrl = new PC_AE_PatientInfoRendererController();
            PC_AE_PatientInfoRendererController.getPatientInfoData();
            objCntrl.updateAdverseEvent(aeRec,patientInfoObj);
            PC_AE_PatientInfoRendererController.fetchDataFromAE(aeRec.Id,patientInfoObj);
            PC_AE_PatientInfoRendererController.fetchDataFromPatient(programCase.Id,patientInfoObj);
        }
        Test.StopTest();
    }
}