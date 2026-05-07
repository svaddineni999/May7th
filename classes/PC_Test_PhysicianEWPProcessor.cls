/**
 * Class Name      : PC_Test_PhysicianEWProcessor
 * Created By      : Vijay Kashikar
 * @Created Date   : Feb 17, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Vijay        17-Feb-2017           Initial Version
 */
@isTest
public class PC_Test_PhysicianEWPProcessor {
	private static final String engagementProgramName = 'PCPCP'; 
    @isTest static void run() {
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@testpc.com','UserName');
        PC_Database.ins(adminUser);
        
        System.runAs(adminUser) {
            Test.StartTest();
            
            List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
            manufacturers = (List<Account>) PC_Database.ups(manufacturers);
            Account manufacturer = manufacturers[0];
            
            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ups(patient);
            
            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
            engagementProgram.PC_Program_Code__c = engagementProgramName;
            engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);            
            
            Case enrollmentCase = PC_Test_Setup.createEnrollment(engagementProgram.Id);
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);
            
            Case programCase = PC_Test_Setup.createCase(adminUser, patient);
            programCase.AccountId = patient.Id;
            programCase.PC_Engagement_Program__c = engagementProgram.Id;
            programCase = (Case) PC_Database.ups(programCase);
            
            enrollmentCase.PC_Program__c = programCase.Id;
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);
            
            List<Account> physicians = PC_Test_Setup.createAccounts('physicianEewp', 1, 'PC_Physician');
            physicians = PC_Database.ups(physicians);    
            
            //creating pageState as desired by the processor
            Map<String, Object> pageState = new Map<String, Object>();
            Map<String,Object> selectedPhysicians = new Map<String,Object>();
            selectedPhysicians.put('Id', physicians[0].Id);
            pageState.put('selectedResult', selectedPhysicians);
            
            PC_PhysicianEWPProcessor.processEnrollment(enrollmentCase, pageState);
            
			String pId = enrollmentCase.PC_Program__c;
            Case programCase_Updated = [SELECT Id, PC_Program__c, PC_Physician__c FROM Case WHERE Id = :pId];   
            system.assertEquals(programCase_Updated.PC_Physician__c, null, 'Success');
            Test.stopTest();
            
        }
    }
}