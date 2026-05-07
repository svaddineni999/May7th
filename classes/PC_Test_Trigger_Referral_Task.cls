/*********************************************************************************
Class Name      : PC_Test_Trigger_Referral_Task
Description     : Test class for Pharmacy Referrer task generating trigger handler class
Created By      : Prachi Nandgaonkar
Created Date    : Aug 9, 2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Prachi Nandgaonkar              Aug 8, 2017        [PC-1730] Initial Version			
Prachi Nandgaonkar              Aug 17, 2017       [PC-2061] Added specific record type for referral task creation
Prachi Nandgaonkar              Sept 1, 2017       [PC-2180] Changed task record type from Template to PSP
Tejas Patel						Nov 11, 2017	   [PC-2065] Moved the variable taskSubject into the scope of the user
Hitha Avalakki                  Nov 27, 2019       [PC-5757] Added a LIMIT to query in testTaskCreation() method
Hitha Avalakki                  Feb 26, 2021       [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
*********************************************************************************/
@isTest
public class PC_Test_Trigger_Referral_Task {
    public static final String ACCOUNT_OBJ = 'Account';
    public static final String ACCOUNT_NAME = 'Test Account';
    private static User adminUser1;
    private static final Integer OBJECTS_NUMBER = 3;
    public static Boolean isTriggerActive = PC_TriggerHandlerHelper.getTriggerState('PC_Pharmacy_Referral__c', 'PC_Trigger_Referral_Task');

    @isTest
    static void testTaskCreation() {
        if(isTriggerActive) {
            //Create admin user
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1);
            
            //Create multiple patient accounts
            List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            system.runAs(adminUser1) {
                Test.StartTest();
    			String taskSubject = System.Label.PC_Referral_Task_Subject;
                PC_Database.ins(patientAccounts);
                // check if 3 patients are created for bulk testing
                system.assertEquals(3, patientAccounts.size());
                
                //Creatae multiple program cases
                //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
                List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, OBJECTS_NUMBER);
                PC_Database.ins(programCases);
                // check if 3 cases are created for bulk testing
                system.assertEquals(3, programCases.size());
                
                //Create multiple pharmacy referrals
                List<PC_Pharmacy_Referral__c> referrals = PC_Test_Setup.createReferrals(programCases, OBJECTS_NUMBER);
                PC_Database.ins(referrals);
                // check if 3 referrals are created for bulk testing
                system.assertEquals(3, referrals.size());
                
                //Check if task for created for first referral
                List<Case> programCaseList = [SELECT Id FROM Case LIMIT 1];
                Task t1 =  [SELECT Id, RecordType.Name, WhatId, PC_Pharmacy_Referral__c, Subject, Status, PC_Channel__c, Priority, PC_Category__c, PC_Sub_Category__c, OwnerId, ActivityDate  
                    	    FROM Task
                            WHERE WhatId =: programCaseList[0].Id];
                // check if task for referral 1 was created with correct fields
                system.assertEquals(programCaseList[0].Id, t1.WhatId);
                system.assertEquals(PC_Constants.PSP_TASK_RECORD_TYPE_NAME, t1.RecordType.Name); //[PC-2061] Added record type assertion
                system.assertEquals(referrals[0].Id, t1.PC_Pharmacy_Referral__c);
                //system.assertEquals(taskSubject, t1.Subject);
                system.assertEquals(PC_Constants.PC_STATUS_COMPLETED, t1.Status);
                system.assertEquals(PC_Constants.PC_TASK, t1.PC_Channel__c);
                system.assertEquals(PC_Constants.PC_PRIORITY_NORMAL, t1.Priority);
                system.assertEquals(PC_Constants.PC_TASK_REF_CATEGORY, t1.PC_Category__c);
                system.assertEquals(PC_Constants.PC_TASK_SUBCATEGORY, t1.PC_Sub_Category__c);
                system.assertEquals(Date.today(), t1.ActivityDate);                                        
                
                      
                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}