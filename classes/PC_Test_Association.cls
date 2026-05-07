/*********************************************************************************
Class Name      : PC_Test_Association
Description     : This test class for Association trigger
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Roxana Ivan               May 17, 2016              Initial Version
Mayuresh Patil            Apr 07, 2017              [PC-1369] Resolved blocker issue raised by force reviewer scanner tool.
Tejas Patel				  July 12, 2017             PC-1875 ignore test if trigger is disabled in metadata
Ajinkya Deshmukh          July 13, 2017          Updated test class as per new trigger
Ajinkya Deshmukh		  July 31, 2017			 Added WHERE clause in soql
Mayuresh Patil            Oct 03, 2017           [PC-2198] Changed form Private to Public class to resolve access issues when running test classes.
Shabda Bhujad             Feb 08, 2018           [PC-2770] Replaced the like clause with check for record type for security compliance
Tejas Patel               Mar 31, 2018           isActive check on ccAndRiUsers
Tejas Patel				  Apr 06, 2018			 Upgarded the Test class to work with custom metadata deactivation
Shishir Bansal            05-Dec -2019           [PC-5787] Added null check before DML operation
Hitha Avalakki            Feb 26, 2021           [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
*********************************************************************************/
@isTest
public class PC_Test_Association {
    public static final String ACCOUNT_NAME = 'Test Account';
    public static final String CONTACT_NAME = 'Test Contact';
    public static final String PROGRAM_RECORD_TYPE = 'PC_Program';
    public static final String CASE_OBJ = 'Case';
    public static final String TEST_ROLE = 'TEST_ROLE_UNIT';
    public static final String PHYSICIAN_RECORD_TYPE = 'PC_Physician';
    public static final String PAYER_RECORD_TYPE = 'Payer';
    public static final String ACCOUNT_OBJ = 'Account';
    private static final Integer OBJECTS_NUMBER = 5;
    private static User adminUser;
    private static List<User> ccAndRiUsers;
    public static Boolean isTriggerActive = True;

    public static List <CaseTeamRole> caseRoles;
    public static List<Account> patientAccounts;
    public static List<Case> programCases;


    static void setup() {
        try {
            // Create Admin User
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser);

            //Create Case Team Roles
            //caseRoles = PC_Test_Setup.createCaseTeamRole(2, new List<String>{'Reimbursement Specialist', 'Care Coordinator'});
            //PC_Database.ups(caseRoles);

            //Get Active Users
            ccAndRiUsers = [SELECT Id FROM User WHERE Id != :adminUser.Id and IsActive = true LIMIT 2];

            //Create Patient Accounts
            patientAccounts = PC_Test_Setup.createSampleAccounts(ACCOUNT_NAME, OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAccounts);

            //Create Case
            //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
            programCases = PC_Test_Setup.createProgramCases(patientAccounts, 5);
            PC_Database.ins(programCases);

            //Check Cases
            programCases = [SELECT Id FROM Case WHERE AccountId IN:patientAccounts];
            system.assertEquals(programCases.size(), 5);

        } catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
    }

    @isTest static void testPC_MarkAssociationInactiveHandler() {
        if(PC_TriggerHandlerHelper.getTriggerState('PC_Association__c', 'PC_MarkAssociationInactiveHandler') ||
          	PC_TriggerHandlerHelper.getTriggerState('PC_Association__c', 'PC_ProcessNewAssociationHandler')) {
            setup();
            system.runAs(adminUser) {
                try{
                    PC_Association__c riAssociation = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[0].Id, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST);
                    PC_Association__c ccAssociation = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[1].Id, PC_Constants.PC_ROLE_CARE_COORDINATOR);
                    ccAssociation.PC_EndDate__c	= (System.today()-1);
                    Test.startTest();
                    PC_Database.ins(new List<PC_Association__c>{riAssociation,ccAssociation});
                    List<PC_Association__c> checkAssociations = [SELECT Id, PC_Program__c,PC_Role__c, PC_AssociationStatus__c
                                                                 FROM PC_Association__c WHERE PC_Program__c IN : programCases and PC_AssociationStatus__c =: PC_Constants.ACTIVE ];

                    Test.stopTest();
                    // check if Associations have been created
                    if(PC_TriggerHandlerHelper.getTriggerState('PC_Association__c', 'PC_MarkAssociationInactiveHandler')){
                     	System.assertEquals(checkAssociations.size(), 1);
                        PC_Association__c riAssociation1 = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[0].Id, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST);
                			try {
                                if(riAssociation1 !=null) {
                                    insert riAssociation1;
                                }
                			} catch (Exception ex) {
                    			System.Assert(ex.getMessage().contains(Label.PC_ExisitingAssociation));
                			}
                    } else {
                        System.assertEquals(checkAssociations.size(), 2);
                    }
                }catch(Exception ex){
                    PC_Utility.createExceptionLog(ex);
                }

            }
        }
    }

    @isTest static void testPC_ProcessNewAssociationHandler() {
        if(PC_TriggerHandlerHelper.getTriggerState('PC_Association__c', 'PC_ProcessNewAssociationHandler')) {
            setup();
            system.runAs(adminUser) {
                try{
                    PC_Association__c riAssociation1 = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[0].Id, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST);
                    PC_Association__c riAssociation2 = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[1].Id, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST);
                    Test.startTest();
                    PC_Database.ins(new List<PC_Association__c>{riAssociation1});
                    List<PC_Association__c> checkAssociations = [SELECT Id, PC_Program__c,PC_Role__c, PC_AssociationStatus__c
                                                                 FROM PC_Association__c WHERE PC_Program__c IN : programCases and PC_AssociationStatus__c =: PC_Constants.ACTIVE ];


                    // check if Associations have been created
                    System.assertEquals(checkAssociations.size(), 1);

                    PC_Database.ins(new List<PC_Association__c>{riAssociation2});
                    checkAssociations = [SELECT Id, PC_Program__c,PC_Role__c, PC_AssociationStatus__c
                    FROM PC_Association__c WHERE PC_Program__c IN : programCases and PC_AssociationStatus__c =: PC_Constants.ACTIVE ];
                    Test.stopTest();
                    // check if Associations have been created
                    System.assertEquals(checkAssociations.size(), 1);
                }catch(Exception ex){
                    PC_Utility.createExceptionLog(ex);
                }

            }
        }
    }

    @isTest static void testPC_ProcessUpdateAssociationHandler() {
        if(PC_TriggerHandlerHelper.getTriggerState('PC_Association__c', 'PC_ProcessUpdateAssociationHandler')) {
            setup();
            system.runAs(adminUser) {
                try{
                    PC_Association__c riAssociation = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[0].Id, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST);
                    PC_Association__c ccAssociation = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[1].Id, PC_Constants.PC_ROLE_CARE_COORDINATOR);
                    Test.startTest();
                    PC_Database.ins(new List<PC_Association__c>{riAssociation,ccAssociation});
                    riAssociation.PC_AssociationStatus__c	= PC_Constants.INACTIVE;
                    PC_Database.upd(riAssociation);
                    List<PC_Association__c> checkAssociations = [SELECT Id, PC_Program__c,PC_Role__c, PC_AssociationStatus__c
                                                                 FROM PC_Association__c WHERE PC_Program__c IN : programCases and PC_AssociationStatus__c =: PC_Constants.ACTIVE ];
                    Test.stopTest();
                    // check if Associations have been created
                    System.assertEquals(checkAssociations.size(), 1);
                }catch(Exception ex){
                    PC_Utility.createExceptionLog(ex);
                }

            }
        }
    }

    @isTest static void testPC_ProcessDeleteAssociationHandler() {
        if(PC_TriggerHandlerHelper.getTriggerState('PC_Association__c', 'PC_ProcessDeleteAssociationHandler')) {
            setup();
            system.runAs(adminUser) {
                try{
                    PC_Association__c riAssociation = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[0].Id, PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST);
                    PC_Association__c ccAssociation = PC_Test_Setup.createAssociations(programCases[0].Id, null, ccAndRiUsers[1].Id, PC_Constants.PC_ROLE_CARE_COORDINATOR);
                    Test.startTest();
                    PC_Database.ins(new List<PC_Association__c>{riAssociation,ccAssociation});
                    PC_Database.del(riAssociation);
                    List<PC_Association__c> checkAssociations = [SELECT Id, PC_Program__c,PC_Role__c, PC_AssociationStatus__c
                                                                 FROM PC_Association__c WHERE PC_Program__c IN : programCases and PC_AssociationStatus__c =: PC_Constants.ACTIVE ];
                    Test.stopTest();
                    // check if Associations have been created
                    System.assertEquals(checkAssociations.size(), 1);
                }catch(Exception ex){
                    PC_Utility.createExceptionLog(ex);
                }

            }
        }
    }
}