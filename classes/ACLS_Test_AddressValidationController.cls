@isTest
private class ACLS_Test_AddressValidationController {   
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
    @isTest
    static void testVerifyAddress() {
        List<User> usr = [Select id from user where lastname ='TestCaseManager'];
        System.runAs(usr[0]) {
        // Create test data
        String actuala1 = '123 Main St';
        String actuala2 = 'Apt 4B';
        String actualpostal = '90210-1234';
        String actualstate = 'CA';
        String actualcity = 'Beverly Hills';
        String actualcountry = 'United States';
        
        // Set up mock HTTP response
        String mockResponse = '{"Records": [{"AddressLine1": "123 Main St","AddressLine2": "Apt 4B","City": "Beverly Hills","State": "CA","PostalCode": "90210-1234"}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse, 200));
        
        // Call the method to be tested
        Test.startTest();
        Map<String, Object> result = ACLS_AddressValidationController.verifyAddress(actuala1, actuala2, actualpostal, actualstate, actualcity,actualcountry);
        Test.stopTest();
        /*// Verify the expected values
        System.assertEquals('123 Main St', result.get('PC_Address_1__c'));
        System.assertEquals('Apt 4B', result.get('PC_Address_2__c'));
        System.assertEquals('Beverly Hills', result.get('PC_City__c'));
        System.assertEquals('CA', result.get('PC_State__c'));
        
        System.assertEquals('90210', result.get('PC_Zip_Code__c'));
        System.assertEquals('1234', result.get('ACLS_Zip_Code_Extension__c'));*/
        }
    }
    
    // Helper class to generate mock HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String mockResponse;
        private Integer mockStatus;
        
        public MockHttpResponseGenerator(String mockResponse, Integer mockStatus) {
            this.mockResponse = mockResponse;
            this.mockStatus = mockStatus;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockResponse);
            res.setStatusCode(mockStatus);
            return res;
        }
    }
}