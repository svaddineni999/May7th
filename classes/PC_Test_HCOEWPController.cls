/**
 * Class Name      : PC_Test_HCOEWPController
 * Created By      : Ajinkya
 * @Created Date   : January 31, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Ajinkya             10-January-2017           Initial Version
 * Ajinkya             12-April-2017           	 Update testMethodCreate() and created testMethodCreate1()
 * Prachi Nandgaonkar  19-April-2017             [PC-1379] Updated definition of getApplicantHCO() to query applicant object with activeApplicant 
 * 											     input parameter to handle multiple applicants on same enrollment case
 * Shabda Bhujad	   11-July-2017				 [PC-1885] Updated the test for getHCOType to get Map
 */
@isTest
public class PC_Test_HCOEWPController {
    public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm'; 
    
    
    @isTest static void testMethodCreate() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ins(patient, false);
            // patient is created
            system.assertNotEquals(patient.Id, null);
            
            PC_Address__c  patAddress = PC_Test_Setup.createAddress(Patient.Id);
            patAddress = (PC_Address__c)PC_Database.ins(patAddress, false);
            // address is created
            system.assertNotEquals(patAddress.Id, null);
            
            List<Id> accountIds = new List<Id>();
            accountIds.add(Patient.Id);
            PC_HCOEWPController.HCORecord fields                    = PC_HCOEWPController.getFields();
            system.assertEquals(fields.type, 'Account Type');
            Account hcotypes2                                       = PC_HCOEWPController.getHCOTypes2();
            system.assertEquals(hcotypes2.Type, null);
            Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> hcotypes 	= PC_HCOEWPController.getHCOTypes('');
            system.assertEquals(1, hcotypes.size());
            List<PC_HCOEWPController.HCORecord>searchrecordsbyid    = PC_HCOEWPController.searchRecordsByIds(accountIds);
            system.assertEquals(searchrecordsbyid[0].recordTypeName, 'Patient');
            List<PC_HCOEWPController.HCORecord> searchrecords       = PC_HCOEWPController.searchRecords('testpatient', 'test');
            
            Test.StopTest();
        }
    }
    
    @isTest static void testMethodCreate1() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            
            List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>) PC_Database.ups(manufacturers);
            Account manufacturer = manufacturers[0];
            
            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
            engagementProgram.PC_Program_Code__c = engagementProgramName;
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);
            // check if engagement program is created
            system.assertNotEquals(engagementProgram.Id, Null);
            
            Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);
            // check if enrollment Case is created
            system.assertNotEquals(enrollmentCase.Id, Null);
            
            PC_Applicant__c aApplicant = PC_Test_Setup.createApplicant('applicant Name', enrollmentCase.Id);
            aApplicant = (PC_Applicant__c)PC_Database.ins(aApplicant, false);
            // check if applicant is created
            system.assertNotEquals(aApplicant.Id, Null);
            
            List<PC_HCOEWPController.HCORecord> getAllHCO = PC_HCOEWPController.getApplicantHCO(enrollmentCase.Id, aApplicant.Id);
            system.assertEquals(getAllHCO.size(), 0);
            Test.stopTest();
        }
    }
}