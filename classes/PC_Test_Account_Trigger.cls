/*********************************************************************************
Class Name      : PC_Test_Account_Trigger
Description     : This test class for Account trigger
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tetiana Danylyshyn         May 17, 2016            Initial Version
Tetiana Danylyshyn         June 09, 2016           Added testCarediverFieldPopulation()  
Alina BAlan                August 01, 2016         Added testupdatePermissionSetAssignment, createTestData
Shabda Bhujad,             Nov 8, 2016             Removed the updatePermissionSetAssignment since Portal functionality is not included in the current version of managed package
Prachi Nandgaonkar                                 Ref @@RemovePortalPermissionSet  
Shabda Bhujad			   July 12, 2017		   [PC-1875] Added the check the test outcomes only if the trigger handler is active. 			
*********************************************************************************/
@isTest
public class PC_Test_Account_Trigger {
    public static final String ACCOUNT_NAME = 'Test Account';
    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 6;
    
    /*********************************************************************************
    Method Name    : updateAccountNameTest
    Author         : Tejas Patel
    Description    : This method is used for testing the PC_UpdateAccountName trigger
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest 
    static void updateAccountNameTest() {
        if(PC_TriggerHandlerHelper.getTriggerState('Account', 'PC_UpdateAccountName')) {
        	//Create Admin Users
    		adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        	PC_Database.ins(adminUser);
        
        	//Create Bulk Patinet Accounts
        	List<Account> accounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        
        	system.runAs(adminUser) {
            	Test.StartTest();
            	//Before Insert Test
            	PC_Database.ins(accounts);
            	
                // check if 6 patients are created for bulk testing
                system.assertEquals(accounts.size(), OBJECTS_NUMBER);
                // check if after insert account trigger is Updating the Name
                Account testAcc = new Account();
                testAcc	= [Select Name from Account where Id =: accounts[5].Id];
                system.assertEquals(testAcc.Name, 'Patient Last Name 5, Patient First Name 5');
            
            	//Before Update Test
            	// Update accounts first name to fire the trigger
            	for(integer i = 0; i < accounts.size(); i ++){
                	accounts[i].PC_First_Name__c = ACCOUNT_NAME + ' ' + i;
            	}
            	PC_Database.upd(accounts);
                // check if after update account trigger is Updating NAme
                testAcc	= [Select Name from Account where Id =: accounts[5].Id];
                system.assertEquals(testAcc.Name, accounts[5].PC_Last_Name__c +', ' + accounts[5].PC_First_Name__c);
            
            	Test.StopTest();
        	}
        }
    }
    
    /*********************************************************************************
    Method Name    : createAndUpdateContactsTest
    Author         : Tejas Patel
    Description    : This method is used for testing the PC_CreateAndUpdateContacts trigger
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest 
    static void createAndUpdateContactsTest() {
        if(PC_TriggerHandlerHelper.getTriggerState('Account', 'PC_CreateAndUpdateContacts')) {
        	//Create Admin Users
    		adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        	PC_Database.ins(adminUser);
        	system.runAs(adminUser) {
            	Test.StartTest();
        		//Create Bulk Patinet Accounts
        		List<Account> accounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        		PC_Database.ins(accounts);
        		// Test Contacts Creation
        		List<Id> accId = new List<Id>();
        		for (Account a : accounts){
            		accId.add(a.Id);
        		}
        		List<Contact> contacts = [Select Id from Contact where AccountId in :accId];
        		system.assertEquals(contacts.size(), OBJECTS_NUMBER);
        
        		// Test Contact Update
        		// Update accounts first name to fire the trigger
       			for(integer i = 0; i < accounts.size(); i ++){
      				accounts[i].PC_First_Name__c = ACCOUNT_NAME + ' ' + i;
      			}
        		PC_Database.upd(accounts);
                Account testAcc = new Account();
                testAcc	= [Select Name from Account where Id =: accounts[0].Id];
            	accId.clear();
        		for (Account a : accounts){
            		accId.add(a.Id);
        		}
            	contacts.clear();
        		contacts = [Select Id, LastName from Contact where AccountId in :accId];
        		system.assertEquals(contacts[0].LastName, testAcc.Name);
            	Test.StopTest();
    		}
        }
    }
    
    /*********************************************************************************
    Method Name    : updateRelatedCasesTest
    Author         : Tejas Patel
    Description    : This method is used for testing the PC_UpdateRelatedCases trigger
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest 
    static void updateRelatedCasesTest() {
        if(PC_TriggerHandlerHelper.getTriggerState('Account', 'PC_UpdateRelatedCases')) {
        	//Create Admin Users
    		adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        	PC_Database.ins(adminUser);
        	system.runAs(adminUser) {
            	Test.StartTest();
            	//Create Bulk Patinet Accounts
        		List<Account> accounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        		PC_Database.ins(accounts);
            
            	// Creating Cases for only first 2 accounts
            	Case patient1Case = PC_Test_Setup.createCase(adminUser, accounts[0]);
            	Case patient2Case = PC_Test_Setup.createCase(adminUser, accounts[1]);
            	PC_Database.ins(patient1Case, false);
            	PC_Database.ins(patient2Case, false);
            
            	// Update accounts first name to fire the trigger
            		for(integer i = 0; i < accounts.size(); i ++){
                		accounts[i].PC_First_Name__c = ACCOUNT_NAME + ' ' + i;
            		}
            		PC_Database.upd(accounts);
            
            	Case case1 = [Select Id, Account.PC_First_Name__c from Case where Id =: patient1Case.Id];
            	system.assertEquals(case1.Account.PC_First_Name__c, accounts[0].PC_First_Name__c);
            
            	Test.StopTest();
    		}
    	}
    }
}