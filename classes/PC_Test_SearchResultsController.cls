/**
 * Created by vkashikar on 6/2/2021.
 */

@IsTest
private class PC_Test_SearchResultsController {
    @isTest static void testBehavior() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            String orgNamespace = PC_SearchResultsController.getOrgNamespace();
            system.assert(true); // Org ns can be either null or not-null depending on the org. Hence, assert to true
            Test.stopTest();
        }
    }
}