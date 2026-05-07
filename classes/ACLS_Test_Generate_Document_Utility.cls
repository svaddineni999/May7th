/*********************************************************************************
Class Name      : ACLS_Test_Generate_Document_Utility
Description     : Test class for ACLS_Generate_Document_Utility
Created By      : Deloitte
Created Date    : 14-Mar-2023
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                    Description
-----------------------------------------------------------------------------------
Ronak Bansal               14-Mar-2023              Initial Version
*********************************************************************************/
@isTest
public class ACLS_Test_Generate_Document_Utility {
	//test data setup
    @testSetup 
    static void setupTestData() {
        User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        insert usr;
        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_IT_Admin_Permissions');
        lstPsAssignment.add(psAssignment);
        insert lstPsAssignment;
    }
    /*********************************************************************************
    Method Name    : test_generateDocumentFromIP
    Description    : test class to invoke Integration Procedure
    Return Type    : void
    Author         : Deloitte
    *********************************************************************************/
    @isTest 
    public static void test_generateDocumentFromIP() {
       
        List<User> usr = [Select id from user where lastname ='TestCaseManager'];
        System.runAs(usr[0]) {
            Map<String, Id> mapAccRecordTypes = ACLS_Utility.getMapOfRecordtype(ACLS_Constants.ACCOUNT);

            //Creating Manufacturer 
            List<Account> lstAcct = ACLS_TestDataFactory.createAccount(2);
            lstAcct[0].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            lstAcct[1].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            insert lstAcct;
            System.debug('lstAcct!@#$ '+lstAcct);

            List<PC_Engagement_Program__c> lstEngageProgram = ACLS_TestDataFactory.createEngagmentProgram(1);
            lstEngageProgram[0].PC_Program_Code__c = 'ASHF';
            insert lstEngageProgram;
            
            List<PC_eLetter__c> lsteLetter = ACLS_TestDataFactory.createTesteLetter(1) ;
            insert lsteLetter;

            List<Case> lstCase = ACLS_TestDataFactory.createProgramCase(1,lstAcct[1].Id);
            lstCase[0].PC_Engagement_Program__c = lstEngageProgram[0].Id;
            
            //lstCase[0].OwnerId = UserInfo.getUserId();
            lstCase[0].Subject='Test Subject';
            insert lstCase;

            List<PC_Document__c> lstDocument = ACLS_TestDataFactory.createTestDocument(1) ;
            insert lstDocument;



            PC_Engagement_Program_Eletter__c epEletterrecord = new PC_Engagement_Program_Eletter__c(
                PC_Engagement_Program__c = lstEngageProgram[0].id
            );
            epEletterrecord.PC_eLetter__c = lsteLetter[0].id;
            insert epEletterrecord;

            //generateDocumentFromIP(String sourceRecordId, String targetRecordId, String engagementProgramName, String accountId, String programCaseId, String eLetterId, String ipProcedureName, String baseExtractDataRaptorName)
           
            
            Test.startTest();
            Map<String,Object> results = ACLS_Generate_Document_Utility.generateDocumentFromIP(lstCase[0].id,lstDocument[0].id,'','','',lsteLetter[0].id,'ACLS_IP_FaxProcessing','ACLS_Fax_Base_ExtractDataRaptor');
            Test.stopTest();
			
			system.assertNotEquals(results, Null);
           


        }
    }
/*********************************************************************************
    Method Name    : test_callMethod
    Description    : test class to invoke callmethod of Integration Procedure
    Return Type    : void
    Author         : Deloitte
    *********************************************************************************/
        @isTest 
        public static void test_callMethod() {
            List<User> usr = [Select id,lastname from user where lastname ='TestCaseManager'];
            System.assertEquals('TestCaseManager', usr[0].lastname);
        System.runAs(usr[0]) {
            Map<String,Object> arguments = new Map<String,Object>();
            Test.startTest();
            ACLS_Generate_Document_Utility callx = new ACLS_Generate_Document_Utility();
            callx.call('getExtractDR',arguments);
            Test.stopTest();


        }
    }
    @isTest 
        public static void test_callMethod2() {
            List<User> usr = [Select id,lastname from user where lastname ='TestCaseManager'];
            System.assertEquals('TestCaseManager', usr[0].lastname);
        System.runAs(usr[0]) {
            Map<String,Object> arguments = new Map<String,Object>();
            Test.startTest();
            ACLS_Generate_Document_Utility callx = new ACLS_Generate_Document_Utility();
            callx.call('getTransfromDR',arguments);
            Test.stopTest();


        }
    }
    /*********************************************************************************
    Method Name    : test_getExtractDRMethod
    Description    : test class to invoke getExtractDRMethod for remote action of Integration Procedure
    Return Type    : void
    Author         : Deloitte
    *********************************************************************************/
    @isTest 
        public static void test_getExtractDRMethod() {
            List<User> usr = [Select id,lastname from user where lastname ='TestCaseManager'];
            System.assertEquals('TestCaseManager', usr[0].lastname);
        System.runAs(usr[0]) {
            Map<String,Object> arguments1 = new Map<String,Object>();
            Map<String,Object> arguments2 = new Map<String,Object>();
            Map<String,Object> arguments3 = new Map<String,Object>();
            Test.startTest();
            ACLS_Generate_Document_Utility callx = new ACLS_Generate_Document_Utility();
            callx.getExtractDR(arguments1,arguments2,arguments3);
            Test.stopTest();


        }
    }
    /*********************************************************************************
    Method Name    : test_getTransfromDRMethod
    Description    : test class to invoke getTransfromDRMethod for remote action of Integration Procedure
    Return Type    : void
    Author         : Deloitte
    *********************************************************************************/
    @isTest 
        public static void test_getTransfromDRMethod() {
            List<User> usr = [Select id,lastname from user where lastname ='TestCaseManager'];
             System.assertEquals('TestCaseManager', usr[0].lastname);
        System.runAs(usr[0]) {
            Map<String,Object> arguments1 = new Map<String,Object>();
            Map<String,Object> arguments2 = new Map<String,Object>();
            Map<String,Object> arguments3 = new Map<String,Object>();
            Test.startTest();
            ACLS_Generate_Document_Utility callx = new ACLS_Generate_Document_Utility();
            callx.getTransfromDR(arguments1,arguments2,arguments3);
            Test.stopTest();


        }
    }
}