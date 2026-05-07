/*********************************************************************************
Class Name      : PC_Test_PA_Case_Trigger
Description     : Test methods for PA Case Trigger Handler
Created By      : Shabda Bhujad
Created Date    : 25-Sep-2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shabda Bhujad			  Sep, 25 2017			 Initial version
Mayuresh Patil            Aug 20, 2018              PC-3241 Adding access to medical health plan recordtype
*********************************************************************************/
@isTest
private class PC_Test_PA_Case_Trigger {
    private static User adminUser1;
    private static final Integer OBJECTS_NUMBER = 3;
    public static Boolean isTriggerActive = PC_TriggerHandlerHelper.getTriggerState('Case', 'PC_Trigger_PA_Case');
    @isTest
    static void testActivePAonProgramCoverage() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            
            system.runAs(adminUser1) {
                Test.StartTest();
                /* 
                 * Create Patient account
                 */
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                /* 
                 * Create health plans
                 */
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];
                
                List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(accounts, OBJECTS_NUMBER);
                healthPlans[0].RecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                healthPlans[0].PC_Plan_Status__c = PC_Constants.ACTIVE;
                healthPlans[0].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;
                healthPlans[1].RecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                healthPlans[1].PC_Plan_Status__c = PC_Constants.ACTIVE;
                healthPlans[1].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;
                PC_Database.ins(healthPlans);
                System.assertEquals(healthPlans.size(), 3);
                /*
                 * Create a program case
                 */
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                PC_Database.ins(aCase);
                
                List<PC_Program_Coverage__c> programCoverages = [SELECT Id, PC_hasActivePA__c FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(FALSE, programCoverages[0].PC_hasActivePA__c);
                System.assertEquals(FALSE, programCoverages[1].PC_hasActivePA__c);
                /* 
                 * Create Prescription
                 */
                PC_Prescription__c patientPrescription = new PC_Prescription__c();
                patientPrescription.PC_Patient_Account__c = aAccount.Id;
                patientPrescription.PC_Program_Case__c = aCase.Id;                
                PC_Database.ins(patientPrescription);
                
                List<PC_Prescription__c> prescriptions = [Select Id FROM PC_Prescription__c WHERE Id =: patientPrescription.Id];
                /*
                 * Create a PA case with the Program Coverage created for program case and Prescription related to the program case
                 */
                Case paCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PA_RECORD_TYPE);
                paCase.PC_Program__c = aCase.Id;
                paCase.PC_Program_Coverage__c = programCoverages[0].Id;
                paCase.PC_PA_Prescription__c= prescriptions[0].Id;
                PC_Database.ins(paCase);                
                /*
                 * Check if the hasActivePA is false on Program Coverage and Prescription since the PC_PA_Status__c value on Case is null
                 */
                programCoverages = [SELECT Id, PC_hasActivePA__c FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(FALSE,programCoverages[0].PC_hasActivePA__c);
                System.assertEquals(FALSE, programCoverages[1].PC_hasActivePA__c);
                
                prescriptions = [Select Id,PC_hasActivePA__c FROM PC_Prescription__c WHERE PC_Program_Case__c =: aCase.Id];
                System.assertEquals(FALSE,prescriptions[0].PC_hasActivePA__c);
                /*
                 * Update the PA Case Status to Denied and check if the hasActivePA is false on Program Coverage and Prescription
				 */                
                List<Case> paCases = [Select Id, PC_PA_Status__c FROM Case WHERE PC_Program__c =: aCase.Id];
                paCases[0].PC_PA_Status__c = PC_Constants.PA_CASE_STATUS_Denied;
                PC_Database.upd(paCases);
                
                programCoverages = [SELECT Id, PC_hasActivePA__c FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(FALSE,programCoverages[0].PC_hasActivePA__c);
                
                prescriptions = [Select Id,PC_hasActivePA__c FROM PC_Prescription__c WHERE PC_Program_Case__c =: aCase.Id];
                System.assertEquals(FALSE,prescriptions[0].PC_hasActivePA__c);

                /*
                 * Update the PA Case Status to Approved and check if the hasActivePA is true on Program Coverage and Prescription
				 */
                List<Case> paCasesList = [Select Id, PC_PA_Status__c FROM Case WHERE PC_Program__c =: aCase.Id];
                paCasesList[0].PC_PA_Status__c = PC_Constants.PA_CASE_STATUS_Approved;
                PC_Database.upd(paCasesList);

                programCoverages = [SELECT Id, PC_hasActivePA__c FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(TRUE,programCoverages[0].PC_hasActivePA__c);

                prescriptions = [Select Id,PC_hasActivePA__c FROM PC_Prescription__c WHERE PC_Program_Case__c =: aCase.Id];
                System.assertEquals(TRUE,prescriptions[0].PC_hasActivePA__c);
                Test.stopTest();
            }
        } 
        else {
            System.debug('The Trigger is DeActivated : ' + isTriggerActive);
        }
    }

}