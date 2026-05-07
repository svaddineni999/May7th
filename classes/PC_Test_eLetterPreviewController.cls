/**
 * Created by havalakki on 4/10/2019.
 */

@IsTest
private class PC_Test_eLetterPreviewController {

    @isTest static void testPreviewEletterContent() {

        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@testpc.com', 'UserName');
        PC_Database.ins(adminUser);

        System.runAs(adminUser) {

            PC_eLetter__c eletter = PC_Test_Setup.createEletter();
            PC_Database.ins(eletter);

            EmailTemplate emailTemplate = PC_Test_Setup.createEmailTemplate(eletter.PC_Template_Name__c);
            PC_Database.ins(emailTemplate);

            Id accountRecordTypeId = PC_System.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PATIENT_RECORD_TYPE);
            Account account = PC_Test_Setup.createAccount('Patient Name', accountRecordTypeId);
            PC_Database.ins(account);

            Contact contactRecord = PC_Test_Setup.createContact(account.Id);
            PC_Database.ins(contactRecord);

            Case programCase = PC_Test_Setup.newCase(account.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            PC_Database.ins(programCase);


            PC_eLetterPreviewController.previewEletterContent(String.valueOf(eletter.Id), programCase.Id);
        }
    }
}