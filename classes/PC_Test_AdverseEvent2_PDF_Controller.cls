/**
 * Created by havalakki on 12/13/2018.
 */

@IsTest(seeAllData=False)
private class PC_Test_AdverseEvent2_PDF_Controller {
    private static User objUser2;
    private static Account oPatient;
    private static String ManufacturerId;
    private static PC_AdverseEvent2__c adverseEvent;
    private static final String PATIENT_NAME = 'test patient name';

    @isTest static void createTestData() {
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser2, false);

        Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc, false);

        oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);
        oPatient.ParentId= manufacturerAcc.Id;
        PC_Database.ins(oPatient, false);

        adverseEvent = PC_Test_Setup.newAdverseEvent2(oPatient.Id);
        adverseEvent.PC_Age__c=31;
        adverseEvent.PC_Gender__c='Female';
        adverseEvent.PC_Race__c='Asian';
        adverseEvent.PC_Description__c='Event description';
        adverseEvent.PC_Reporter_First_Name__c='Reporter First name';
        PC_Database.ins(adverseEvent);

    }
    @isTest static void testPDFFunctionality() {
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            ApexPages.StandardController adverseStfController = new ApexPages.StandardController(adverseEvent);
            ApexPages.currentPage().getParameters().put('adverseEventId', adverseEvent.Id);
            ApexPages.currentPage().getParameters().put('fieldsetName', '');
            PC_AdverseEvent2_PDF_Controller pc_adverseEvent_pdf_controller = new PC_AdverseEvent2_PDF_Controller(adverseStfController);
            pc_adverseEvent_pdf_controller.fetchPDFData();
            Test.stopTest();
        }
    }
}