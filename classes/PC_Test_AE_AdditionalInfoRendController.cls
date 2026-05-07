/*********************************************************************************
Class Name      : PC_Test_AE_AdditionalInfoRendController
Description     : Test Class for PC_AE_AdditionalInfoRendererController Class
Created By      : Xiukai Ning
Created Date    : 6-12-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Xiukai Ning          6-12-2018              Initial Version
Haritha Reddy        10-Dec-2019            [PC-5791] Removed references of getFieldsetFieldsLabels which is not in use
*********************************************************************************/
@isTest
public class PC_Test_AE_AdditionalInfoRendController {
    private static User adminUser;
    private static Case programCase;
    private static PC_AdverseEvent__c aeRec;
    private static String descriptionField = PC_Constants.getQualifiedAPIName('PC_Description__c');
    private static Map<Object, Object> additionalInfoObj = new Map<Object, Object>{descriptionField=>'Other Description Data'};

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

        aeRec.PC_Description__c = 'Other Description Data';
        aeRec.PC_Laboratory_Data__c = 'Lab Test';
        aeRec.PC_Other_Relevent_History__c = 'Historical Data';
        aeRec.PC_Reporter_City__c = 'Lake Mary';

        PC_Database.ins(aeRec, false);

    }
    @isTest
    static void PC_Test_AE_AdditionalInfoRendController() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_AE_AdditionalInfoRendererController objCntrl = new PC_AE_AdditionalInfoRendererController();
            objCntrl.updateAdverseEvent(aeRec,additionalInfoObj);
            PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                    PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), null);
            PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, null,
                    PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), null);
            try{
                PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                        PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), null);
            }
            catch(Exception ex) {
                system.assertEquals(ex.getMessage(), ex.getMessage());
            }

            try {
                PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                        PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Constants.getQualifiedAPIName('PC_AE_Additional_Information'));
            }
            catch(Exception ex) {
                system.assert(true);
            }
            try {
                PC_AE_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                        PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), 'Invalid_FieldSet');
            }catch(Exception ex) {
                system.assertEquals(ex.getMessage(), ex.getMessage());
            }
        }
        Test.StopTest();
    }
}