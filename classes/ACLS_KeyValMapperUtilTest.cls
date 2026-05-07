@isTest
public class ACLS_KeyValMapperUtilTest {
	/**@testSetup 
    static void setupTestData() {
        User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        usr.Username = 'testKeyValmap@testAhsfield1.com';
        usr.email = 'testKeyValmap@testAhsfield1.com';
        usr.alias = 'teMap';
        insert usr;
        system.runAs(usr) {
        // Assigning Required Permission set to Test user
        ACLS_TestDataFactory.assignUserPermissionSet(usr.Id, 'ACLS_Base_RW_Permissions');
    	}
    }*/
    @istest
    public static void testUtil(){
        Test.startTest();
        List<ACLS_KeyValue__mdt> lstkeyValueRecord = ACLS_TestDataFactory.createKeyValue(1);
            String value = ACLS_KeyValMapperUtil.getValue('ACLS_TestKeyMap');
        	String configType = ACLS_KeyValMapperUtil.CONFIG_1;
        	System.assertEquals(value,'TestVal');
        	value =  ACLS_KeyValMapperUtil.getEPCodeValue('TestKey1',configType,'TestCode');
        	value = ACLS_KeyValMapperUtil.getValue('TestKey',configType);
            ACLS_KeyValMapperUtil.getKeyValueMap(configType,'TestCode');
        Test.stopTest();        
    }
}