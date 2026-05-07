/**
 * Created by vkashikar on 6/30/2021.
 */

@isTest
private with sharing class PC_Test_PurgeBatchScheduler {
    @testSetup
    static void setup() {

    }

    @isTest static void testScheduler() {
        Test.startTest();
        PC_PurgeBatchScheduler scheduler = new PC_PurgeBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}