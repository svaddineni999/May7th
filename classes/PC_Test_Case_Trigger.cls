/*********************************************************************************
Class Name      : PC_Test_Case_Trigger
Description     : Test methods for case trigger
Created By      : Roxana Ivan
Created Date    : 26-May-15
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Roxana Ivan               26-May-16              Initial Version
Shabda Bhujad,            Nov 3, 2016            Removed PC_Health_Plan__c, PC_Program_coverage__c field(Case Object)references annotated by @@RemoveHP @@RemoveProgCoverage
Prachi Nandgaonkar
Tejas Patel				  Apr 12, 2017		     Modified DML Update to PC_Database.upd with fls check true
Shabda Bhujad			  May 15, 2017			 Added logic for testing PC-1584 PC-1012
Mayuresh Patil            July 5, 2017           PC-1868 Resolved Force Scanner issues - 	Avoid calling soql without a where clause or limit statement
Tejas Patel				  July 12, 2017          PC-1875 ignore test if trigger is disabled in metadata
Ajinkya Deshmukh          July 13, 2017          Updated test class as per new trigger
Ajinkya Deshmukh		  July 31, 2017			 Added WHERE clause in soql
Mayuresh Patil            Aug 10, 2017           Updated testProgramCoverageCreation method to test PC_Trigger_Case_PatientCoverage
Mayuresh Patil            Aug 18, 2017           PC-2126 program coverage test updated
Hitha Avalakki            Mar 19, 2021           [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
*********************************************************************************/

@isTest
private class PC_Test_Case_Trigger {
    public static final String PHYSICIAN_RECORD_TYPE = 'PC_Physician';
    public static final String PAYER_RECORD_TYPE = 'Payer';
    public static final String ACCOUNT_OBJ = 'Account';

    public static final String ACCOUNT_NAME = 'Test Account';
    private static User adminUser1;
    private static User adminUser2;
    private static final Integer OBJECTS_NUMBER = 3;
    public static Boolean isTriggerActive = True;

    @isTest
    static void testAssociationTrigger() {
        if(isTriggerActive) {
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1);
            List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            // create physician account
            Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(physicianAccount1);
            system.runAs(adminUser1) {
                Test.StartTest();
                PC_Database.ins(patientAccounts);
                // check if 3 patients are created for bulk testing
                system.assertEquals(patientAccounts.size(), 3);
                List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, OBJECTS_NUMBER);
                PC_Database.ins(programCases);
                // check if 2 patients are created for bulk testing
                system.assertEquals(programCases.size(), 3);
                // check if association got created
                List<PC_Association__c> allAssociations = [SELECT Id FROM PC_Association__c WHERE PC_Program__c IN : programCases];
                System.assertEquals(allAssociations.size(), 0);

                // update case for RI and CC
                programCases[0].PC_Reimbursment_Specialist__c = ccAndRiUsers[0].Id;
                programCases[0].PC_Care_Coordinator__c = ccAndRiUsers[1].Id;
                programCases[0].PC_Physician__c = physicianAccount1.Id;
                PC_Database.upd(programCases[0]);
                // check if 2 associations got created
                allAssociations = [SELECT Id, PC_Program__c FROM PC_Association__c WHERE PC_Program__c IN : programCases];
                System.assertEquals(allAssociations.size(),3);
                System.assertEquals(allAssociations[0].PC_Program__c,programCases[0].Id);
                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
    
    @isTest
    static void testAssociationTriggerException() {
        if(isTriggerActive) {
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            system.runAs(adminUser1) {
                Test.StartTest();
                
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                // check before update scenario
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase.PC_Care_Coordinator__c = ccAndRiUsers[0].Id;
                //aCase.PC_Reimbursment_Specialist__c = ccAndRiUsers[0].Id;
                
                try {
                    PC_Database.ins(aCase);
                } catch (Exception ex) {
                    System.Assert(ex.getMessage().contains(Label.PC_SameUserOnCase));
                }
				
                // create physician account
                Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
                PC_Database.ins(physicianAccount1);
                Account physicianAccount2 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
                PC_Database.ins(physicianAccount2);
                // update RI for aCase
                aCase.PC_Reimbursment_Specialist__c = ccAndRiUsers[1].Id;
                aCase.PC_Physician__c = physicianAccount1.Id;
                PC_Database.upd(aCase);
                // check if associations got created
                List<PC_Association__c> allAssociations = [SELECT Id FROM PC_Association__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(allAssociations.size(), 3);
                // update the physician on case
                aCase.PC_Physician__c = physicianAccount2.Id;
                PC_Database.upd(aCase);
                
                Test.stopTest();
            }
        }
    }
    
    @isTest
    static void testAssociationInsert() {
        if(isTriggerActive) {
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            system.runAs(adminUser1) {
                Test.StartTest();
                
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                // create a physician account
                Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
                PC_Database.ins(physicianAccount1);
                // check before update scenario
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase.PC_Care_Coordinator__c = ccAndRiUsers[0].Id;
				aCase.PC_Physician__c = physicianAccount1.Id;
                aCase.PC_Reimbursment_Specialist__c = ccAndRiUsers[1].Id;
                PC_Database.ins(aCase);
                // check if associations got created
                List<PC_Association__c> allAssociations = [SELECT Id FROM PC_Association__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(allAssociations.size(), 3);
                Test.stopTest();
            }
        }
    }

    @isTest
    static void testProgramCoverageCreation() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            // bulk creation of patient accounts
            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                // create health plans
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];
                system.debug('@@accounts ++ '+ accounts);
                List<PC_Health_Plan__c> healthPlans = PC_Test_Setup.createHealthPlans(accounts, OBJECTS_NUMBER);
                healthPlans[0].RecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                healthPlans[0].PC_Plan_Status__c = PC_Constants.ACTIVE;
                healthPlans[0].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PRIVATE;
                healthPlans[1].RecordTypeId = PC_System.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                healthPlans[1].PC_Plan_Status__c = PC_Constants.ACTIVE;
                healthPlans[1].PC_Public_Or_Private__c = PC_Constants.HEALTH_PLAN_TYPE_PUBLIC;
                system.debug('@@healthPlans ++ '+ healthPlans);
                // insert all health plans
                PC_Database.ins(healthPlans);
                // check if health plans are created
                System.assertEquals(healthPlans.size(), 3);
                // create a case
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                PC_Database.ins(aCase);
                // check for details
                List<PC_Program_Coverage__c> programCoverages = [SELECT Id, PC_Health_Plan__c, PC_Coverage_Type__c, RecordType.DeveloperName FROM PC_Program_Coverage__c WHERE PC_Program__c =: aCase.Id];
                System.assertEquals(programCoverages.size(), 3);
                System.assertEquals(PC_Constants.PRIVATE_COVERAGE_TYPE, programCoverages[0].PC_Coverage_Type__c);
                System.assertEquals(PC_Constants.PUBLIC_COVERAGE_TYPE, programCoverages[1].PC_Coverage_Type__c);
                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest
    static void testSubjectLineCreationForCase() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];

                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('Test EP', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);

                // create a case
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase.PC_Engagement_Program__c=engagementProgram.Id;
                PC_Database.ins(aCase);

                Case serviceCase = PC_Test_Setup.newCase(null, 'PC_Alternate_Funding');
                serviceCase.PC_Program__c=aCase.Id;
                PC_Database.ins(serviceCase);

                List<Case> caseList=[SELECT Id, Subject FROM Case WHERE Id=:aCase.Id];

                List<Case> serviceCaseList=[SELECT Id, Subject FROM Case WHERE Id=:serviceCase.Id];

                System.assert(!String.isBlank(caseList[0].Subject) && (caseList[0].Subject.contains(aAccount.PC_First_Name__c)||
                                                caseList[0].Subject.contains(engagementProgram.Name)||
                                                caseList[0].Subject.contains(aCase.Type)));

                System.assert(!String.isBlank(serviceCaseList[0].Subject) && (serviceCaseList[0].Subject.contains(aAccount.PC_First_Name__c)||
                        serviceCaseList[0].Subject.contains(engagementProgram.Name)||
                        serviceCaseList[0].Subject.contains(serviceCase.Type)));

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest
    static void testCheckDuplicatesProcessChange1() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(physicianAccount1);

            Account newPhysicianAccount = PC_Test_Setup.createSampleAccount('New Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(newPhysicianAccount);

            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];

                Account anotherAccount = PC_Test_Setup.createPatient('Patient2222');
                PC_Database.ins(anotherAccount);

                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('Test EP', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);

                // create a case
                engagementProgram = [SELECT Id FROM PC_Engagement_Program__c WHERE Id=: engagementProgram.Id];
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase.PC_Engagement_Program__c=engagementProgram.Id;
                aCase.PC_Care_Coordinator__c =ccAndRiUsers[0].Id;
                aCase.PC_Physician__c = physicianAccount1.Id;
                aCase.Type = PC_Constants.CASE_PROGRAM_TYPE;
                PC_Database.ins(aCase);

                aCase.PC_Physician__c = newPhysicianAccount.Id;
                aCase.Status = PC_Constants.PROGRAM_STATUS_ENROLLED;
                PC_Database.upd(aCase);

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest
    static void testCheckDuplicatesProcessChange2() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(physicianAccount1);

            Account newPhysicianAccount = PC_Test_Setup.createSampleAccount('New Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(newPhysicianAccount);

            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];

                Account anotherAccount = PC_Test_Setup.createPatient('Patient2222');
                PC_Database.ins(anotherAccount);

                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('Test EP', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);

                Account manufacturerAcc1 = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc1, false);

                // create a case
                Case aCase = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase.PC_Engagement_Program__c=engagementProgram.Id;
                aCase.PC_Care_Coordinator__c =ccAndRiUsers[0].Id;
                aCase.PC_Physician__c = physicianAccount1.Id;
                aCase.Type = PC_Constants.CASE_PROGRAM_TYPE;
                PC_Database.ins(aCase);

                Case aCase4 = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
                aCase4.PC_Engagement_Program__c=engagementProgram.Id;
                aCase4.PC_Care_Coordinator__c =ccAndRiUsers[0].Id;
                aCase4.PC_Physician__c = physicianAccount1.Id;
                aCase4.Type = PC_Constants.CASE_PROGRAM_TYPE;
                PC_Database.ins(aCase4);

                aCase4.ParentId = aCase.Id ;
                PC_Database.upd(aCase4);

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest
    static void testCheckDuplicatesProcessChange3() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(physicianAccount1);

            Account newPhysicianAccount = PC_Test_Setup.createSampleAccount('New Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(newPhysicianAccount);

            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];

                Account anotherAccount = PC_Test_Setup.createPatient('Patient2222');
                PC_Database.ins(anotherAccount);

                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('Test EP', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);

                Case aCase3 = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase3.PC_Engagement_Program__c=engagementProgram.Id;
                aCase3.PC_Care_Coordinator__c =ccAndRiUsers[0].Id;
                aCase3.PC_Physician__c = physicianAccount1.Id;
                aCase3.Type = PC_Constants.CASE_PROGRAM_TYPE;
                PC_Database.ins(aCase3);

                aCase3.PC_Physician__c = newPhysicianAccount.Id;
                aCase3.Status = PC_Constants.PROGRAM_STATUS_WITHDRAWN;
                aCase3.PC_Reason_for_Withdrawal__c = 'Choice1';
                PC_Database.upd(aCase3);

                aCase3.Status = PC_Constants.PROGRAM_STATUS_ON_HOLD;
                PC_Database.upd(aCase3);

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest
    static void testCheckDuplicatesProcessChange4() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(physicianAccount1);

            Account newPhysicianAccount = PC_Test_Setup.createSampleAccount('New Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(newPhysicianAccount);

            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];

                Account anotherAccount = PC_Test_Setup.createPatient('Patient2222');
                PC_Database.ins(anotherAccount);

                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('Test EP', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);

                Case aCase1 = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase1.PC_Engagement_Program__c=engagementProgram.Id;
                aCase1.PC_Care_Coordinator__c =ccAndRiUsers[0].Id;
                aCase1.PC_Physician__c = physicianAccount1.Id;
                aCase1.Type = PC_Constants.CASE_PROGRAM_TYPE;
                PC_Database.ins(aCase1);

                aCase1.PC_Physician__c = newPhysicianAccount.Id;
                aCase1.Status = PC_Constants.PROGRAM_STATUS_ON_HOLD;
                PC_Database.upd(aCase1);

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    @isTest
    static void testCheckDuplicatesProcessChange5() {
        if(isTriggerActive){
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1, false);
            List<User> ccAndRiUsers = PC_Test_Setup.createUsers(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test5.com', 'test5', 5);
            PC_Database.ins(ccAndRiUsers);
            ccAndRiUsers = [SELECT Id FROM User WHERE Id  !=: adminUser1.Id and IsActive = true];
            Account physicianAccount1 = PC_Test_Setup.createSampleAccount('Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(physicianAccount1);

            Account newPhysicianAccount = PC_Test_Setup.createSampleAccount('New Physician', PC_Constants.PHYSICIAN_RECORD_TYPE);
            PC_Database.ins(newPhysicianAccount);

            system.runAs(adminUser1) {
                Test.StartTest();
                // create another patient account
                Account aAccount = PC_Test_Setup.createPatient('Patient123');
                PC_Database.ins(aAccount);
                List<Account> accounts = [Select Id FROM Account WHERE Id =: aAccount.Id];

                Account anotherAccount = PC_Test_Setup.createPatient('Patient2222');
                PC_Database.ins(anotherAccount);

                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('Test EP', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);

                Case aCase2 = PC_Test_Setup.newCase(aAccount.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
                aCase2.PC_Engagement_Program__c=engagementProgram.Id;
                aCase2.PC_Care_Coordinator__c =ccAndRiUsers[0].Id;
                aCase2.PC_Physician__c = physicianAccount1.Id;
                aCase2.Type = PC_Constants.CASE_PROGRAM_TYPE;
                PC_Database.ins(aCase2);

                aCase2.PC_Physician__c = newPhysicianAccount.Id;
                aCase2.Status = PC_Constants.PROGRAM_STATUS_WITHDRAWN;
                aCase2.PC_Reason_for_Withdrawal__c = 'Choice1';
                PC_Database.upd(aCase2);

                aCase2.Status = PC_Constants.PROGRAM_STATUS_ON_HOLD;
                PC_Database.upd(aCase2);

                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}