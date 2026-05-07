@isTest
public class ACLS_UtilityTest {
    
    @testSetup 
    static void dataSetup() {
        Map<String,Id> mapAccRecordTypes = ACLS_Utility.getMapOfRecordtype(ACLS_Constants.ACCOUNT);
        
        try{
            //Creating Manufacturer
            Account manufacturer = new Account(Name = 'Test Manufacturer' , recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT));
            insert manufacturer;
            
            //Creating Enagagement program            
            PC_Engagement_Program__c testEP = new PC_Engagement_Program__c(Name = 'Test EP', PC_Program_Code__c = 'testep', PC_Manufacturer__c = manufacturer.Id);
            insert testEP;
            
            //Creating User
            User usr = ACLS_Utility.createTestUser('ACLS Base Profile','TestUser');
            insert usr;
        }
        catch(Exception e){
            PC_Utility.createExceptionLog(e);
        }
    }
    
    @isTest
    public static void test_getEpCode() {
        //Retrieve EP
        PC_Engagement_Program__c ep = [SELECT Id, PC_Program_Code__c FROM PC_Engagement_Program__c  WHERE  PC_Program_Code__c = 'testep' LIMIT 1 ];
        Set<Id> setEPIds = new Set<Id>();
        setEPIds.add(ep.Id);
        
        Map<Id,PC_Engagement_Program__c> mapEpCode = ACLS_Utility.getEpCode(setEPIds);
        System.assertEquals(ep.PC_Program_Code__c, mapEpCode.get(ep.Id).PC_Program_Code__c);
    }
    
    @isTest
    public static void test_getRcordtypeIdByDeveloperName() {
        System.assert(ACLS_Utility.getRecordtypeIdByDeveloperName(ACLS_Constants.OBJ_CASE, ACLS_Constants.CASE_PROGRAM_RT) != null); 
    }
    
    @isTest
    public static void test_getMapOfRecordtype() {
        System.assert(ACLS_Utility.getMapOfRecordtype('Account').size() > 0); 
    }
    @isTest
    public static void test_createTestUser() {
        System.assert(ACLS_Utility.createTestUser('System Administrator','TestName')!= null); 
    }
    @isTest
    public static void test_assignPermissions() {
        User usr = [SELECT id FROM User WHERE lastname = 'TestUser' LIMIT 1];
        System.assert(ACLS_Utility.assignPermissions(usr.Id,'ACLS_Base_Permissions')!= null); 
    }
    @isTest
    public static void test_convertGMTtoEST() {
        DateTime inputDate = DateTime.newInstance(2022, 9, 29, 13, 31, 46);
        DateTime resultDate = DateTime.newInstance(2022, 9, 29, 9, 31, 46);
        system.assertEquals(resultDate, ACLS_Utility.convertGMTtoEST(inputDate), 'Assertion failed');
    }
    @isTest
    public static void test_convertDatetoDateTime() {
        Date inputDate = Date.newInstance(2022, 9, 29);
        DateTime resultDate = DateTime.newInstance(2022, 9, 29, 11, 0, 0);
        system.assertEquals(resultDate, ACLS_Utility.convertDatetoDateTime(inputDate), 'Assertion failed');
    }
    @isTest
    public static void test_getMapOfRecordtypeById() {
        System.assert(ACLS_Utility.getMapOfRecordtypeById('Account').size() > 0); 
    }
    @isTest
    public static void test_getPickListValuesIntoList() {
        System.assert(ACLS_Utility.getPickListValuesIntoList('Account','HealthCloudGA__CountryOfBirth__pc').size() > 0); 
    }
    
    @isTest
    public static void test_getFieldLabelFromFieldAPI() {
        System.assertEquals('Program Code',ACLS_Utility.getFieldLabelFromFieldAPI('PC_Engagement_Program__c','PC_Program_Code__c'),'Field Exception occured'); 
    }

    @isTest
    public static void test_createINTErrorLogs() {
        Test.startTest();
        ACLS_Utility.createINTErrorLogs(null, 'Test Class Error Message', 'Test class stack trace', 'Testing additional info error', 'test', 'ACLS_Utility', 'createINTErrorLogs', null);
        
        Test.stopTest();
        List<PC_Error_Log__c> eg = [Select id, PC_Class_Name__c from PC_Error_Log__c where PC_Class_Name__c = 'ACLS_Utility'];
        system.assertEquals(eg.size()>0, true);

    }
	
	@isTest
    public static void test_createTask() {
        User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'casemanager12345');
        usr.alias = 'uqusr1';
        usr.email = 'test123@testAshfield.com';
        usr.Username = 'test123@testAhsfield1.com';
        insert usr;
        Map<String, Id> mapAccRecordTypes = ACLS_Utility.getMapOfRecordtype(ACLS_Constants.ACCOUNT);
        
        //Creating Manufacturer 
        List<Account> lstAcct = ACLS_TestDataFactory.createAccount(2);
        lstAcct[0].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
        lstAcct[1].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
        insert lstAcct;
        Test.startTest();
        Task tsk = ACLS_Utility.createTask('Inbound Fax : Exception Occurred', 'Integration', 'Fax', System.today(), usr.id, lstAcct[1].id, '<error message>');
        insert tsk;
        Test.stopTest();
        List<Task> error = [Select id, Subject from Task where Subject = 'Inbound Fax : Exception Occurred'];
        system.assertEquals(error.size()>0, true);
    }
    
     @isTest
    public static void test_logErrors() {
        Test.startTest();
        
        PC_Error_Log__c record = ACLS_Utility.logErrors(null, 'ACLS_Utility', 'logErrors');
        insert record;
        Test.stopTest();
        List<PC_Error_Log__c> error = [Select id, PC_Error_Message__c,PC_Class_Name__c from PC_Error_Log__c where PC_Class_Name__c='ACLS_Utility'];
        system.assertEquals(error.size()>0, true);
    }
}