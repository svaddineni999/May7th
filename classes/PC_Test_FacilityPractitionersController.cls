/*********************************************************************************
Class Name      : PC_Test_FacilityPractitionersController
Description     : Test Class for PC_FacilityPractitionersController Class
Created By      : Haritha Reddy
Created Date    : 22-Nov-2021
Modification Log:
----------------------------------------------------------------------------------
Developer                Date               Description
-----------------------------------------------------------------------------------
Haritha Reddy            22-Nov-2021        Initial Version
*********************************************************************************/
@isTest
public class PC_Test_FacilityPractitionersController {
    private static User adminUser,careCoordinator;
    private static Account patient,physician,hcoAccount;
    private static Case programCase;
    private static Contact phyContact;
    private static PC_Interaction__c interactonRecord;

    @testSetup static void setup() {
        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testCCUser2@test.com', 'test2');
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account)PC_Database.ins(patient, false);
        system.assertNotEquals(patient.Id, null);

        Id hcoRecordTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.HCO_RecordType);
        hcoAccount = PC_Test_Setup.createAccount('testHCO', hcoRecordTypeId);
        hcoAccount.PC_NPI__c = '111';
        hcoAccount = (Account) PC_Database.ups(hcoAccount);

        ID physicianId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PHYSICIAN_RECORD_TYPE);
        physician  = PC_Test_Setup.createAccount('test Physician1', physicianId);
        physician.PC_Date_of_Birth__c = Date.today();
        physician.PC_Gender__c = 'Male';
        physician.PC_Specialist_Type__c = 'Cardiologist';
        physician.Type = 'Specialist';
        physician.PC_Sub_Type__c = 'Other';
        physician.PC_Individual_Type__c = 'Individual';
        physician = (Account) PC_Database.ins(physician, false);

        phyContact = [Select Id from Contact where AccountId = : physician.id];

        HealthcarePractitionerFacility facility1  = new HealthcarePractitionerFacility();
        facility1.AccountId = hcoAccount.Id;
        facility1.PractitionerId = phyContact.Id;
        facility1.isPrimaryFacility = true;
        facility1.Name = 'test facility 1';
        facility1 = (HealthcarePractitionerFacility) PC_Database.ins(facility1, false);

        programCase = PC_Test_Setup.createCase(careCoordinator, patient);
        programCase.PC_Care_Coordinator__c = careCoordinator.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
        system.assertNotEquals(programCase.Id, null);

        interactonRecord = new PC_Interaction__c();
        interactonRecord.PC_Patient_Program__c = programCase.Id;
        interactonRecord.PC_Participants__c = 'HCO; Care Coordinator';
        interactonRecord.PC_Status__c = 'Requested';
        PC_Database.ins(interactonRecord, false);
    }

    @isTest static void testGetInitData() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        adminUser = (User) PC_Database.ins(adminUser);

        PC_Interaction__c interacton = [Select Id from PC_Interaction__c Limit 1];
        String selectedLocationId = [Select Id from Account WHERE Name = 'testHCO' LIMIT 1][0].Id;
        Account phyAccount = [Select Id from Account where Type = 'Specialist'];
        Contact phyContact = [Select Id from Contact where AccountId = : phyAccount.id];
        List<String> selectedParticipantList = new List<String>();
        selectedParticipantList.add(phyContact.id);

        Test.StartTest();
        system.runAs(adminUser) {
            PC_FacilityPractitionersController.getInitData(selectedLocationId);
            PC_FacilityPractitionersController.saveInteractionParticipants(interacton.id,selectedParticipantList);
        }
        Test.StopTest();
    }
}