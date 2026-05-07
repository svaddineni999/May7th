/*********************************************************************************
Test Class Name : PC_Test_AttachmentController
Description     : Test class for PC_AttachmentController
Created By      : Satheesh Kumar
Created Date    : Jul 09, 2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Satheesh Kumar           Jul 09, 2020            Initial Version
*********************************************************************************/

@IsTest
private class PC_Test_AttachmentController {
    private static User adminUser;
    private static User careCoordinator;
    private static Account patient;
    private static Account  manufacturer;
    private static PC_Engagement_Program__c enmtProgram;
    private static Case programCase;
    private static Attachment attachment;
    private static PC_Interaction__c interaction;
    private static PC_Program_Coverage__c programCoverage;
    private static final String DOCUMENT_EMAIL_ATTACHMENT_RECORD_TYPE = 'PC_Email_Attachment';
    private static final String DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE = 'PC_Email_Outbound';
    private static Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
    private static Boolean useFileStrictMode = PC_SYSTEM.useDocumentPreviewInStrictMode();

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Satheesh Kumar
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

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

        //Create Attachment
        attachment = PC_Test_Setup.createAttachment(programCase.Id); // Creating 1st attachment for case record
        PC_Database.ins(attachment);
        //check if attachment is created
        system.assertNotEquals(attachment.Id, null);

        Attachment attachment2 = PC_Test_Setup.createAttachment(programCase.Id); // Creating 2nd attachment for case record
        PC_Database.ins(attachment2);
        //check if 2nd attachment is created
        system.assertNotEquals(attachment.Id, null);

        ContentDocument contentDocument = PC_Test_Setup.createFile(programCase.Id); // Creating one file for case
        system.assertNotEquals(ContentDocument.Id, null);

        //Create PC Document
        PC_Document__c pcDocument = PC_Test_Setup.createDocument(DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW, 'TestPgm2');
        PC_Database.ins(pcDocument);
        //Create Attachment for PC Document
        Attachment pcAttachment = PC_Test_Setup.createAttachment(pcDocument.Id); // Creating 1st attachment for PC Document
        PC_Database.ins(pcAttachment);
        Attachment pcAttachment2 = PC_Test_Setup.createAttachment(pcDocument.Id); // Creating 2nd attachment for PC Document
        PC_Database.ins(pcAttachment2);

        ContentDocument PCContentDocument = PC_Test_Setup.createFile(pcDocument.Id);  // Creating 3rd attachments as file for PC Document
        system.assertNotEquals(PCContentDocument.Id, null);

        //Create Document Log for linking PC Document with case
        PC_Document_Log__c pcDocumentLog = new PC_Document_Log__c();
        pcDocumentLog.PC_Document__c = pcDocument.Id;
        pcDocumentLog.PC_Association_Type__c = 'Case: Program';
        pcDocumentLog.PC_Association_Record_Name__c = programCase.CaseNumber;
        pcDocumentLog.PC_Program__c = programCase.Id;
        pcDocumentLog.PC_Association_Record_ID__c = programCase.Id;
        PC_Database.ins(pcDocumentLog);

        //Query the Document Log
        PC_Document_Log__c docLog  = [SELECT Id, PC_Program__c FROM PC_Document_Log__c WHERE PC_Program__c =:programCase.Id];
        system.assertNotEquals(docLog.Id, null);


        // Create Interaction Record
        interaction = PC_Test_Setup.newInteraction(programCase.Id);
        PC_Database.ins(interaction);
        // check if interaction record is created
        system.assertNotEquals(interaction.Id, null);
        // Create one attachment for Interaction Record
        Attachment interactionAttachment = PC_Test_Setup.createAttachment(interaction.Id);
        PC_Database.ins(interactionAttachment);

        // Create Program Coverage Record
        programCoverage = PC_Test_Setup.createProgramCoverage(programCase.Id);
        PC_Database.ins(programCoverage);
        // check if interaction record is created
        system.assertNotEquals(programCoverage.Id, null);
        // Create one attachment for Program Coverage Record
        Attachment progCoverageAttachment = PC_Test_Setup.createAttachment(programCoverage.Id);
        PC_Database.ins(progCoverageAttachment);
    }

    @isTest static void testGetCaseAttachments() {
        try {
            Test.startTest();
            /*
            * Below method will create case with 2 attachments, 1 file, 1 PC Document with 2 attachment and 1 file,
            * 1 Interaction Record for case with 1 attachment, 1 Program Coverage Record for case with 1 attachment
            */
            createTestData();

            //getAttachments(recordId, showAttachmentsOfRecord,showAttachmentsUsingDocumentLog,showAttachmentsOfRelatedCase,showAllAttachmentsOfDocument)
            system.runAs(adminUser) {
                // Case Object - Test Cases
                if(useSalesforceFiles && useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCase.Id, true, false, false, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCase.Id, true, true, false, false).size());
                }
                if(!useSalesforceFiles && useFileStrictMode){
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCase.Id, true, false, false, false).size());
                    System.assertEquals(3, PC_AttachmentController.getAttachments(programCase.Id, true, true, false, false).size());
                }
                if(!useSalesforceFiles && !useFileStrictMode){
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCase.Id, true, false, false, false).size());
                    System.assertEquals(3, PC_AttachmentController.getAttachments(programCase.Id, true, true, false, false).size());
                }
                if(useSalesforceFiles && !useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCase.Id, true, false, false, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCase.Id, true, true, false, false).size());
                }
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception in testGetAttachments >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    @isTest static void testGetInteractionAttachments() {
        try {
            Test.startTest();

            /*
            * Below method will create case with 2 attachments, 1 file, 1 PC Document with 2 attachment and 1 file,
            * 1 Interaction Record for case with 1 attachment, 1 Program Coverage Record for case with 1 attachment
            */
            createTestData();

            //getAttachments(recordId, showAttachmentsOfRecord,showAttachmentsUsingDocumentLog,showAttachmentsOfRelatedCase,showAllAttachmentsOfDocument)
            system.runAs(adminUser) {
                // Interaction Object - Test Cases
                if(useSalesforceFiles && useFileStrictMode){
                    System.assertEquals(0, PC_AttachmentController.getAttachments(interaction.Id, true, false, false, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, true).size());
                    System.assertEquals(1, PC_AttachmentController.getAttachments(interaction.Id, false, false, true, true).size());
                }
                if(!useSalesforceFiles && useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(interaction.Id, true, false, false, false).size());
                    System.assertEquals(3, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, false).size());
                    System.assertEquals(4, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, true).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(interaction.Id, false, false, true, true).size());
                }
                if(!useSalesforceFiles && !useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(interaction.Id, true, false, false, false).size());
                    System.assertEquals(3, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, false).size());
                    System.assertEquals(4, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, true).size());
                }
                if(useSalesforceFiles && !useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(interaction.Id, true, false, false, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(interaction.Id, false, true, true, true).size());
                    System.assertEquals(1, PC_AttachmentController.getAttachments(interaction.Id, false, false, true, true).size());
                }
            }

            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception in testGetAttachments >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    @isTest static void testGetProgramCoverageAttachments() {
        try {
            Test.startTest();

            /*
            * Below method will create case with 2 attachments, 1 file, 1 PC Document with 2 attachment and 1 file,
            * 1 Interaction Record for case with 1 attachment, 1 Program Coverage Record for case with 1 attachment
            */
            createTestData();

            //getAttachments(recordId, showAttachmentsOfRecord,showAttachmentsUsingDocumentLog,showAttachmentsOfRelatedCase,showAllAttachmentsOfDocument)
            system.runAs(adminUser) {
                // Program Coverage Object - Test Cases
                if(useSalesforceFiles && useFileStrictMode){
                    System.assertEquals(0, PC_AttachmentController.getAttachments(programCoverage.Id, true, false, false, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, true).size());
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCoverage.Id, false, false, true, true).size());
                }
                else if(!useSalesforceFiles && useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCoverage.Id, true, false, false, false).size());
                    System.assertEquals(3, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, false).size());
                    System.assertEquals(4, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, true).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCoverage.Id, false, false, true, true).size());
                }
                else if(!useSalesforceFiles && !useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCoverage.Id, true, false, false, false).size());
                    System.assertEquals(3, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, false).size());
                    System.assertEquals(4, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, true).size());
                }
                else if(!useSalesforceFiles && !useFileStrictMode){
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCoverage.Id, true, false, false, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, false).size());
                    System.assertEquals(2, PC_AttachmentController.getAttachments(programCoverage.Id, false, true, true, true).size());
                    System.assertEquals(1, PC_AttachmentController.getAttachments(programCoverage.Id, false, false, true, true).size());
                }
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception in testGetAttachments >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }

    @isTest static void testGetRecordAttachments() {
        try {
            Test.startTest();
            createTestData();
            system.runAs(adminUser) {
                System.assertEquals(1, PC_AttachmentController.getRecordAttachments(new List<String>{attachment.Id}).size());
            }
            Test.stopTest();
        } catch (Exception ex) {
            system.debug('exception in testGetRecordAttachments >>' + ex.getMessage());
            system.assert(false, ex.getMessage());
        }
    }
}