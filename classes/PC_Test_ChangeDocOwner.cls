/*
* Class Name      : PC_Test_ChangeDocOwner
* Created By      : Tejas Patel
* @Created Date   : Apr 10, 2019
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Tejas Patel	        10-Apr-2019			        Initial Version
*/

@isTest
public class PC_Test_ChangeDocOwner {
    private static User adminUser;
    private static PC_Document__c testDoc;
    private static List<PC_ChangeDocOwnerLightningController.ActionIconsWrapper> testActionIconsWrapper;

    @testSetup static void setup() {

        //Create Doc
        PC_Document__c doc = new PC_Document__c();
        doc=PC_Test_Setup.createDocWithStatusAndRecordType(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE,PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT);
        doc = (PC_Document__c) PC_Database.ins(doc,false);
    }

    @isTest static void testGetDocDetails() {
        //Create admin User
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        adminUser = (User) PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();
            PC_Document__c doc = new PC_Document__c();
            doc = [SELECT ID, RecordType.DeveloperName FROM PC_Document__c LIMIT 1];
            testDoc = PC_ChangeDocOwnerLightningController.getDocDetails(doc.Id);
            System.assertNotEquals(testDoc,null);
            System.assertEquals(testDoc.RecordType.DeveloperName,doc.RecordType.DeveloperName);
            Test.stopTest();

        }
    }

    @isTest static void testSetupActionIcons() {
        //Create admin User
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        adminUser = (User) PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();
            PC_Document__c doc = new PC_Document__c();
            doc = [SELECT ID, RecordType.DeveloperName FROM PC_Document__c LIMIT 1];
            PC_Document_Action_Setting__mdt a = new PC_Document_Action_Setting__mdt();
            PC_ChangeDocOwnerLightningController.ActionIconsWrapper ac = new PC_ChangeDocOwnerLightningController.ActionIconsWrapper(a);
            testActionIconsWrapper = PC_ChangeDocOwnerLightningController.setupActionIcons(doc.Id);
            System.assertEquals(testActionIconsWrapper.size(),0);
            Test.stopTest();

        }
    }
}