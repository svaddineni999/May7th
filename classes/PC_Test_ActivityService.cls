/*********************************************************************************************************
Class Name      : PC_Test_ActivityService
Description     : This class will be used to test PC_ActivityService class
Created By      : Kishore Kanteti
Created Date    : August 4, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore	           Aug 4,2020          	Initial Version
************************************************************************************************************/
@IsTest
public class PC_Test_ActivityService {
    private static String subject = 'Task Creation Test';
    private static User adminUser;

    @isTest static void testeLetterTask(){
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            PC_Document__c document = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
            PC_Database.ins(document, false);
            Test.startTest();
            Task returnedTask =  PC_ActivityService.eLetterTask(document.id,document.id,subject);
            Test.stopTest();
        }
    }
}