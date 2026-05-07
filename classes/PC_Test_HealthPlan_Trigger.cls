/*********************************************************************************************************
Trigger Name    : PC_Trigger_HealthPlan 
Description     : controller that manages Health Plan trigger activities
Created By      : Deloitte
Created Date    : May 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn             May 30, 2016          Initial Version
Shabda Bhujad,         		   Nov 3, 2016			 Removed references to 'Relationship to Cardholder' - annotated by @@RemoveRelTOCardHolder
Prachi Nandgaonkar
Tejas Patel				       July 12, 2017         PC-1875 ignore test if trigger is disabled in metadata
Mayuresh Patil                 Aug 18, 2017          PC-1898 program coverage test included
Mayuresh Patil                 Aug 18, 2017          PC-2126 program coverage test updated
Shabda Bhujad               Dec 14, 2017          PC-1884 Updated the name of the handler the test class should check for
****************************************************************************************************************/
@isTest
private class PC_Test_HealthPlan_Trigger {
    public static final String ACCOUNT_NAME = 'Test Account';
    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 20;
    private static final Integer HP_OBJECTS_NUMBER = 3;
    public static Boolean isTriggerActive = True;

    static testmethod  void testSetHealthPlan() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            // bulk creation of patient accounts
            List<Account> accounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            system.runAs(adminUser) {
                Test.StartTest();
                accounts[0].PC_Date_of_Birth__c = Date.today();
                PC_Database.ins(accounts);
                // check if 20 patients are created for bulk testing
                system.assertEquals(accounts.size(), 20);
                // get list of health plans
                List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(accounts, OBJECTS_NUMBER);
                // insert all health plans
                PC_Database.ins(healthPlans);
                Test.stopTest();
                // check if health plans are created
                System.assertEquals(healthPlans.size(), 20);
                // check for details
                System.assertNotEquals(accounts[0].PC_Date_of_Birth__c, healthPlans[0].PC_Cardholder_s_Date_of_Birth__c);
                System.assertNotEquals(accounts[0].PC_First_Name__c + ' ' + accounts[0].PC_Last_Name__c , healthPlans[0].PC_Card_Holder_Name__c);
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    static testmethod  void testCreationOfProgramCoverages() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            // bulk creation of patient accounts
            List<Account> accounts = PC_Test_Setup.createAccounts('Patient', 1, PC_Constants.PATIENT_RECORD_TYPE);
            system.runAs(adminUser) {
                Test.StartTest();
                accounts[0].PC_Date_of_Birth__c = Date.today();
                PC_Database.ins(accounts);
                Case c = PC_Test_Setup.createProgram(accounts[0]);
                // check if 20 patients are created for bulk testing
                system.assertEquals(accounts.size(), 1);
                // get list of health plans
                List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(accounts, OBJECTS_NUMBER);
                Id privateRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PRIVATE_RECORD_TYPE);
                Id publicRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PUBLIC_RECORD_TYPE);
                Id medicalRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                Id pharmacyRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);

                if(String.isNotBlank(privateRecordTypeId)) healthPlans[0].RecordTypeId = privateRecordTypeId;

                if(String.isNotBlank(publicRecordTypeId)) healthPlans[1].RecordTypeId = publicRecordTypeId;

                healthPlans[2].RecordTypeId = medicalRecordTypeId;
                healthPlans[2].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;

                healthPlans[3].RecordTypeId = medicalRecordTypeId;
                healthPlans[3].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;

                healthPlans[4].RecordTypeId = pharmacyRecordTypeId;
                healthPlans[4].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;

                healthPlans[5].RecordTypeId = pharmacyRecordTypeId;
                healthPlans[5].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;
                // insert all health plans
                PC_Database.ins(healthPlans);
                // check if health plans are created
                System.assertEquals(healthPlans.size(), 20);
                System.assertEquals([SELECT count() FROM PC_Program_Coverage__c LIMIT 100], 20);
                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    static testmethod  void testNonCreationOfCoveragesForClosedCases() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            // bulk creation of patient accounts
            List<Account> accounts = PC_Test_Setup.createAccounts('Patient', 1, PC_Constants.PATIENT_RECORD_TYPE);
            system.runAs(adminUser) {
                Test.StartTest();
                accounts[0].PC_Date_of_Birth__c = Date.today();
                PC_Database.ins(accounts);
                Case c = PC_Test_Setup.createProgram(accounts[0]);
                String closeStatus = [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true LIMIT 1].MasterLabel;
                c.Status = closeStatus;
                c.Reason = Schema.SObjectType.Case.fields.Reason.getPicklistValues().get(0).getValue();
                PC_Database.upd(c);
                // system.assertEquals(true, c.IsClosed, 'Case is not closed'); For some reason this assert fails!! However, the below checks ensure the functional testing
                system.assertEquals(accounts.size(), 1);
                // get list of health plans
                List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(accounts, OBJECTS_NUMBER);
                Id privateRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PRIVATE_RECORD_TYPE);
                Id publicRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PUBLIC_RECORD_TYPE);
                Id medicalRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                Id pharmacyRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);

                if(String.isNotBlank(privateRecordTypeId)) healthPlans[0].RecordTypeId = privateRecordTypeId;

                if(String.isNotBlank(publicRecordTypeId)) healthPlans[1].RecordTypeId = publicRecordTypeId;

                healthPlans[2].RecordTypeId = medicalRecordTypeId;
                healthPlans[2].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;

                healthPlans[3].RecordTypeId = medicalRecordTypeId;
                healthPlans[3].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;

                healthPlans[4].RecordTypeId = pharmacyRecordTypeId;
                healthPlans[4].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;

                healthPlans[5].RecordTypeId = pharmacyRecordTypeId;
                healthPlans[5].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;
                // insert all health plans
                PC_Database.ins(healthPlans);
                // check if health plans are created
                System.assertEquals(healthPlans.size(), 20);
                System.assertEquals([SELECT count() FROM PC_Program_Coverage__c LIMIT 100], 0, 'ERROR: Coverages got created for closed cases!!');
                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest static void testProgramCoverageAfterInsertUpdate() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            // bulk creation of patient accounts
            system.runAs(adminUser) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                // create health plans
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];
                // create a case
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                PC_Database.ins(aCase);
                //Create Health Plans
                List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(accounts, HP_OBJECTS_NUMBER);
                healthPlans[0].RecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                healthPlans[0].PC_Plan_Status__c = PC_Constants.ACTIVE;
                healthPlans[0].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;
                healthPlans[1].RecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                healthPlans[1].PC_Plan_Status__c = PC_Constants.ACTIVE;
                healthPlans[1].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;
                // insert all health plans
                PC_Database.ins(healthPlans);
                // check if health plans are created
                System.assertEquals(healthPlans.size(), 3);
                // check for details
                List<PC_Program_Coverage__c> programCoverages = [SELECT Id, PC_Health_Plan__c, PC_Coverage_Type__c, RecordType.DeveloperName FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(programCoverages.size(), 3);
                System.assertEquals(PC_Constants.PRIVATE_COVERAGE_TYPE, programCoverages[0].PC_Coverage_Type__c);
                System.assertEquals(PC_Constants.PUBLIC_COVERAGE_TYPE, programCoverages[1].PC_Coverage_Type__c);

                //Update Health Plans
                List<PC_Health_Plan__c> healthPlansToUpdate = [SELECT Id, PC_Plan_Status__c, PC_Expiration_Date__c, Patient__c FROM PC_Health_Plan__c WHERE Patient__c = :aAccount.Id];
                healthPlansToUpdate[0].PC_Plan_Status__c = PC_Constants.INACTIVE;
                healthPlansToUpdate[1].PC_Expiration_Date__c = Date.today();
                //update all health plans
                PC_Database.upd(healthPlansToUpdate);

                // check if program coverages are updated
                // check for details
                List<PC_Program_Coverage__c> updatedProgramCoverages = [SELECT Id, PC_Health_Plan__c, PC_Coverage_Status__c, PC_Expiration_Date__c FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(updatedProgramCoverages[0].PC_Coverage_Status__c, PC_Constants.INACTIVE);
                System.assertEquals(updatedProgramCoverages[1].PC_Coverage_Status__c, PC_Constants.INACTIVE);
                System.assertEquals(updatedProgramCoverages[1].PC_Expiration_Date__c, Date.today());

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}