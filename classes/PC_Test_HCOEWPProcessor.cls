/**
 * Class Name      : PC_Test_HCOEWProcessor
 * Created By      : Vijay Kashikar
 * @Created Date   : Feb 15, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Vijay        15-Feb-2017           Initial Version
 */
@isTest
public class PC_Test_HCOEWPProcessor {
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
            
            List<Account> hcos = PC_Test_Setup.createAccounts('hcoewp', 1, 'HCO');
            hcos = PC_Database.ups(hcos);           
            
            //creating pageState as desired by the processor
            Map<String, Object> pageState = new Map<String, Object>();
            List<String> hcoIds = new List<String>();
            hcoIds.add(hcos[0].Id);
            pageState.put('selectedHCOIds', hcoIds);
            
            PC_HCOEWPProcessor.processEnrollment(enrollmentCase, pageState);
            
            String pId = programCase.Id;
            String hId = hcos[0].Id;
            String role = PC_Constants.ACCOUNT_ROLE;
            
            // this query is to ensure that all the data has been related properly
            List<PC_Association__c> existingHCOs = [SELECT Id from PC_Association__c WHERE PC_Program__c = :pId 
                                            AND PC_Account__c = :hId AND PC_Role__c = :role LIMIT 1];
            if(existingHCOs != null && existingHCOs.size() > 0) {
                system.assert(true, 'success');
            }
            else {
                system.assert(false, 'failed');
            }
            Test.stopTest();			
        }
    }
}