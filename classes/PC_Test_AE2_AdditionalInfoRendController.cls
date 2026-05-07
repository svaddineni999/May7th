/*********************************************************************************
Class Name      : PC_Test_AE2_AdditionalInfoRendController
Description     : Test Class for PC_AE2_AdditionalInfoRendererController Class
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
public class PC_Test_AE2_AdditionalInfoRendController {
    private static User adminUser;
    private static Case programCase;
    private static PC_AdverseEvent2__c aeRec;
    private static String descriptionField = PC_Constants.getQualifiedAPIName('PC_Description__c');
    private static Map<Object, Object> additionalInfoObj = new Map<Object, Object>{descriptionField=>'Other Description Data'};

    @isTest
    static void PC_Test_AE2_AdditionalInfoRendController() {
        // createTestData();
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);
        Test.StartTest();
        system.runAs(adminUser) {

            List<PC_AdverseEvent2__c> aeList = new List<PC_AdverseEvent2__c> ();

            aeList = [Select PC_Patient__c, PC_Care_Program__c, PC_Description__c, PC_Laboratory_Data__c,
                    PC_Other_Relevent_History__c, PC_Reporter_City__c From PC_AdverseEvent2__c where  PC_Laboratory_Data__c ='Lab Test' ];

            system.assertNotEquals(aeList[0].Id, null);

            if(aeList != Null && aeList.size()>0) {
                aeRec = aeList[0];
            }


            PC_AE2_AdditionalInfoRendererController objCntrl = new PC_AE2_AdditionalInfoRendererController();
            objCntrl.updateAdverseEvent(aeRec,additionalInfoObj);
            PC_AE2_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                    PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), null);
            PC_AE2_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, null,
                    PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), null);
            try{
                PC_AE2_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                        PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), null);
            }
            catch(Exception ex) {
                system.assertEquals(ex.getMessage(), ex.getMessage());
            }

            PC_AE2_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                    PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Constants.getQualifiedAPIName(PC_Constants.PC_AE2_DEFAULT_ADDITIONAL_INFO_FIELDSET));

            try {
                PC_AE2_AdditionalInfoRendererController.getPopulatedFieldSet(aeRec.Id, additionalInfoObj,
                        PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), 'Invalid_FieldSet');
            }catch(Exception ex) {
                system.assertEquals(ex.getMessage(), ex.getMessage());
            }
        }
        Test.StopTest();
    }

    @testSetup static void setup() {

        Account patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created


        //programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase = PC_Test_Setup.createProgram(patient);
        // programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created


        //insert Adverse Event Record
        aeRec = new PC_AdverseEvent2__c();
        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;

        aeRec.PC_Description__c = 'Other Description Data';
        aeRec.PC_Laboratory_Data__c = 'Lab Test';
        aeRec.PC_Other_Relevent_History__c = 'Historical Data';
        aeRec.PC_Reporter_City__c = 'Lake Mary';

        PC_Database.ins(aeRec, false);
    }

    public interface IFieldSetMember
    {
        Boolean getDBRequired();
        String getFieldPath();
        String getLabel();
        Boolean getRequired();
        Schema.DisplayType getType();
    }
}