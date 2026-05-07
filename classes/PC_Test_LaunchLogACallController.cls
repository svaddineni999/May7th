/**
 * Created by tusarora on 7/22/2020.
 */

@IsTest
public class PC_Test_LaunchLogACallController {
    @isTest static void testGetLogACallRecordTypeId() {
        Test.StartTest();
            Id logACallRecordTypeId = PC_LaunchLogACallController.getLogACallRecordTypeInfo();
            System.AssertNotEquals(null,logACallRecordTypeId);
        Test.StopTest();
    }
}