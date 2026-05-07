/*********************************************************************************************************
Class Name      : PC_Test_InboundEmailService2
Description     : Test class to cover PC_InboundEmailService2
Created By      : Satheesh Kumar
Created Date    : Aug 4, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar 			   July 15, 2020          Initial Version
****************************************************************************************************************/
@isTest
private class PC_Test_InboundEmailService2 {

    private static User adminUser;
    private static User careCoordinator;
    private static Account patient;
    private static Account  manufacturer;
    private static PC_Engagement_Program__c enmtProgram;
    private static Case programCase;
    private static PC_Document__c caseDocument;
    private static final String DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE = 'PC_Email_Outbound';

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Satheesh Kumar
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test67.com', 'test67');
        PC_Database.ins(adminUser, false);
        system.assertNotEquals(adminUser.Id, null);

        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t2.com', 'test2');
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient = (Account) PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        //Create Manufacturer
        List<Account> manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account) PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram = PC_Test_Setup.createEngagementProgram('TestPgm', manufacturer.Id);
        enmtProgram.PC_Program_Code__c = 'TestPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c = enmtProgram.Id;
        programCase.PC_Care_Coordinator__c = careCoordinator.Id;
        programCase.PC_Enrollment_Date__c = date.today().addDays(-10);
        programCase.PC_Treatment_Start_Date__c = date.today();
        programCase.IsEscalated = false;
        programCase.HealthCloudGA__FinancialValue__c = 10;
        programCase = (Case) PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);

        //Create PC Document
        caseDocument = PC_Test_Setup.createDocument(DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW, 'TestPgm2');
        PC_Database.ins(caseDocument);
        system.assertNotEquals(caseDocument.Id, null);

        //Create Attachment for PC Document
        Attachment pcAttachment = PC_Test_Setup.createAttachment(caseDocument.Id); // Creating one  attachment for PC Document
        PC_Database.ins(pcAttachment);
    }

    /*********************************************************************************
    Method Name    : testInboundEmailServiceMethod
    Description    : test inbound functionality
    Parameters     : none
    Return Type    : void
    *********************************************************************************/
    @isTest static void testInboundEmailServiceMethod(){
        try {
            createTestData();
            System.runAs(adminUser) {
                // Create a new email, envelope object and Attachment
                Messaging.InboundEmail email = new Messaging.InboundEmail();
                Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
                String threadId = '[ ref:'+programCase.Id+'.'+caseDocument.Id+':ref ]';
                system.debug('threadId--->'+threadId);
                email.fromAddress = 'user001@test.com';
                email.toAddresses = new String[]{'testuser@test.com'};
                email.subject = 'Test Email'+' '+threadId;
                email.fromName = 'test test';
                email.plainTextBody = 'Hello, this a test email body. For testing purposes only. Phone:123456 Bye';
                email.htmlBody = '<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns:m="http://schemas.microsoft.com/office/2004/12/omml" xmlns="http://www.w3.org/TR/REC-html40">' +

                        '<head>' +
                        '<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">' +
                        '<meta name="Generator" content="Microsoft Word 15 (filtered medium)">' +
                        '</style><!--[if gte mso 9]><xml>' +
                        '<o:shapedefaults v:ext="edit" spidmax="1026" />' +
                        '</xml><![endif]--><!--[if gte mso 9]><xml>' +
                        '<o:shapelayout v:ext="edit">' +
                        '<o:idmap v:ext="edit" data="1" />' +
                        '</o:shapelayout></xml><![endif]-->' +
                        '</head>' +
                        '<body lang="EN-US" link="#0563C1" vlink="#954F72">' +
                        '<div class="WordSection1">' +
                        '<p class="MsoNormal">Hi Team, <o:p></o:p></p>' +
                        '<p class="MsoNormal"><o:p>&nbsp;</o:p></p>' +
                        '<p class="MsoNormal"><o:p>&nbsp;</o:p></p>' +
                        '<p class="MsoNormal"><o:p>&nbsp;</o:p></p>' +
                        '<p class="MsoNormal"><img width="371" height="297" style="width:3.8611in;height:3.0972in" id="Picture_x0020_1" src="cid:image001.png@01D53264.D0C49440"><o:p></o:p></p>' +
                        '<p class="MsoNormal"><o:p>&nbsp;</o:p></p>' +
                        '<p class="MsoNormal"><o:p>&nbsp;</o:p></p>' +
                        '<p class="MsoNormal">Regards,<o:p></o:p></p>' +
                        '<p class="MsoNormal">Shishir<o:p></o:p></p>' +
                        '</div>' +
                        '<p>This message (including any attachments) contains confidential information intended for a specific individual and purpose, and is protected by law. If you are not the intended recipient, you should delete this message and any disclosure, copying, or distribution' +
                        'of this message, or the taking of any action based on it, by you is strictly prohibited.</p>' +
                        '<p>Deloitte refers to a Deloitte member firm, one of its related entities, or Deloitte Touche Tohmatsu Limited (&quot;DTTL&quot;). Each Deloitte member firm is a separate legal entity and a member of DTTL. DTTL does not provide services to clients. Please see www.deloitte.com/about' +
                        'to learn more.</p>' +
                        '<p>v.E.1</p>' +
                        '</body>' +
                        '</html>';

                //create test BinaryAttachment
                Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];
                Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
                binaryAttachment.Filename = 'image001.png';
                binaryAttachment.mimeTypeSubType = 'image/png';

                String algorithmName = 'HMacSHA1';
                Blob b = Crypto.generateMac(algorithmName, Blob.valueOf('test'), Blob.valueOf('test_key'));
                binaryAttachment.Body = b;


                Messaging.InboundEmail.Header hditem = new Messaging.InboundEmail.Header();
                binaryAttachment.headers = new Messaging.InboundEmail.Header[1];
                hditem.name = '<image001.png@01D53264.D0C49440>'; hditem.value = '<image001.png@01D53264.D0C49440>';
                binaryAttachment.headers[0] = hditem;


                binaryAttachments[0] = binaryAttachment;
                email.binaryAttachments = binaryAttachments;

                //create test TextAttachment
                Messaging.Inboundemail.TextAttachment[] textAttachments = new Messaging.Inboundemail.TextAttachment[1];
                Messaging.Inboundemail.TextAttachment textAttachment = new Messaging.Inboundemail.TextAttachment();
                textAttachment.Filename = 'test1.txt';
                textAttachment.Body = 'test body';
                textAttachments[0] = textAttachment ;
                email.textAttachments = textAttachments;

                envelope.fromAddress = 'user@acme.com';

                Test.StartTest();


                Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();


                PC_InboundEmailService2 controller = new PC_InboundEmailService2();
                Messaging.InboundEmailResult result = controller.handleInboundEmail(email, envelope);
                System.assertEquals(result.success, true);

                // Exception Case
                /*Messaging.InboundEmail emailException = new Messaging.InboundEmail();
                Messaging.InboundEnvelope envelopeException = new Messaging.InboundEnvelope();
                Messaging.InboundEmailResult resultnew = controller.handleInboundEmail(emailException, envelopeException);
                System.assertEquals(resultnew.success, false); */

                Boolean isInboundFilesInserted = PC_InboundEmailService2.createInboundRecord(email, envelope, true);
                System.assertEquals(isInboundFilesInserted, true);

                Boolean isInboundAttachmentsInserted = PC_InboundEmailService2.createInboundRecord(email, envelope, false);
                System.assertEquals(isInboundAttachmentsInserted, true);

                PC_InboundEmailService2 inboundEmailService = new PC_InboundEmailService2();
                Messaging.InboundEmailResult negativeResult = inboundEmailService.handleInboundEmail(null, envelope);
                System.assertEquals(negativeResult.success, false);
                Test.StopTest();
            }
        }catch (Exception ex) {
            system.debug('exception in testInboundEmailServiceMethod >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }
}