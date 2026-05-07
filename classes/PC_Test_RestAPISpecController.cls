/**********************************************************************************************************
Class Name    	: PC_Test_RestAPISpecController
Description     : Unit test calss for PC_RestAPISpecController
Created By      : Deloitte
Created Date    : 2017-08-29
Modification Log:
-----------------------------------------------------------------------------------------------------------
Developer          Date                   Description
-----------------------------------------------------------------------------------------------------------
Mike Klumpenaar    2017-08-29             Initial Version
**********************************************************************************************************/
@IsTest
private class PC_Test_RestAPISpecController {
    @isTest public static void restApiJsonSpecTest() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            PageReference pageRef = Page.PC_RestAPISpec;
            Test.setCurrentPage(pageRef);

            PC_RestAPISpecController controller = new PC_RestAPISpecController();

            String openApiJson = controller.restApiJsonSpec;
            Map<String, Object> openApi = (Map<String, Object>) JSON.deserializeUntyped(openApiJson);

            String host = pageRef.getHeaders().get('Host');
            System.assertEquals(openApi.get('host'), host);
        }
    }
}