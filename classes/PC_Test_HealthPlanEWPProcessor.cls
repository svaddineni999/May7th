/**
 * Class Name      : PC_Test_HealthPlanEWProcessor
 * Created By      : Vijay Kashikar
 * @Created Date   : Feb 20 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Vijay        20-Feb-2017           Initial Version
 */
@isTest
public class PC_Test_HealthPlanEWPProcessor {
	private static final String engagementProgramName = 'HPEWP'; 
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
            enrollmentCase.AccountId = patient.Id;
            enrollmentCase = (Case) PC_Database.ups(enrollmentCase);
            
            List<Account> payers = PC_Test_Setup.createAccounts('testPayer', 1, 'Payer');
            payers = (List<Account>) PC_Database.ups(payers);
            
            List<Account> patients = new List<Account>();
            patients.add(patient);
            
            /*List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(patients, 1);*/
            
            
            PC_Health_Plan__c hp = new PC_Health_Plan__c();
            
            String pObjectName = PC_Constants.PC_HEALTH_PLAN;
            String pDeveloperName =  'Private Health Plan';
            
            RecordType rt = [Select Id, developerName, Name From RecordType Where SobjectType = :pObjectName LIMIT 1];
            hp.RecordTypeId = rt.Id;
            hp.PC_Payer__c = payers[0].Id;
            hp.PC_Cardholder_Relationship_to_Patient__c='Child';
            
            List<Object> values = new List<Object>();
            PC_HealthPlanEWPLightningController.healthPlanPageWrapper h = 
                new PC_HealthPlanEWPLightningController.healthPlanPageWrapper(hp, new List<String>());
            
           	h.recordName = rt.Name;
            
            Object h_map = JSON.deserializeUntyped(JSON.serialize(h));
            values.add(h_map);

            //PC-4721:Test class code coverage
            PC_Health_Plan__c hp1 = new PC_Health_Plan__c();

            RecordType rt1 = [Select Id, developerName, Name From RecordType Where SobjectType = :pObjectName LIMIT 1];
            hp1.RecordTypeId = rt1.Id;
            hp1.PC_Payer__c = payers[0].Id;
            hp1.PC_Cardholder_Relationship_to_Patient__c='Self';

            PC_HealthPlanEWPLightningController.healthPlanPageWrapper h1 =
                    new PC_HealthPlanEWPLightningController.healthPlanPageWrapper(hp1, new List<String>());

            h1.recordName = rt1.Name;

            Object h_map1 = JSON.deserializeUntyped(JSON.serialize(h1));
            values.add(h_map1);

            //PC-4721:Test class code coverage
            
            //creating pageState as desired by the processor
            Map<String, Object> pageState = new Map<String, Object>();            
            pageState.put('lstHealthPlan', values);
             
            PC_HealthPlanEWPProcessor.processEnrollment(enrollmentCase, pageState);
            String aId = patient.Id;
            
            // this query is to ensure that all the data has been related properly
            List<PC_Health_Plan__c> updatedItems = [SELECT Id from PC_Health_Plan__c WHERE Patient__c = :aId LIMIT 1];
            if(updatedItems != null && updatedItems.size() > 0) {
                system.debug('success');
                system.assert(true, 'success');
            }
            else {
                system.debug('fail');
                system.assert(false, 'failed');
            }
            Test.stopTest();	
        }
    }
}