/**
 * Created by tejapatel on 9/30/2019.
 */
/*Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Haritha Reddy			   22 Apr,2020			 [PC-6033] Test methods modified as per BRE Processing Upgrade
Kanteti Kishore			   11 May,2021			 [PC-7697] Test method added for testing Queue Reminder Subtype
Kanteti Kishore			   17 Sep,2021			 [PC-8127] Test method(testErrorCase) added for testing Error Scenario
Kanteti Kishore			   12 Oct,2021			 [PC-8178] Added test methods for testing Multiple Recipients Scenario while creating reminder queues.
Satheesh Kumar			   25 Oct,2021			 [PC-8235] Added test method for creating OCR queue.
Chetna Mohapatra           02  Mar,2022          [PC-8529] Added test method for testing Outcome tasks without Related To field.
Chetna Mohapatra           27  Apr,2022          [PC-8646] Added test methods for Automation tasks of type Pharmacy & Medical BI/BV.
*************************************************************************************/
@isTest
public with sharing class PC_Test_AutomationTask {
    static final String MOCK_SENDER = 'PC_Test_MockELetterSender';
    private static string eLetterId;
    private static Account patient;
    private static List<Account> physician;
    private static Account  manufacturer;
    private static User objUser;
    private static PC_SupportPlan__c supPlan;
    private static PC_SupportPlanActivity__c supPlanActy1;
    private static PC_Interaction__c interaction1;
    private static User careCoordinator;
    private static User reimbursmentSpecialist;
    private static PC_Engagement_Program__c enmtProgram;
    private static PC_EngagementProgram_SupportPlan__c enmtPgmSupPlan;
    private static Case caseOne;
    private static EmailTemplate emailTemplate;
    private static PC_Engagement_Program_Eletter__c caseEngagementProgramEletter;

    private static PC_Document__c oDoc;
    private static final String DOCUMENT_NAME = 'ocrTestDocumentText';
    private static final String OCR_TEMPLATE_TYPE_NAME = 'testOcrTemplateType1';
    private static final String OCR_TEMPLATE_MAPPING_NAME = 'testEnrollmentForm_CreateApplicant';

    private static String triggerObjectType='PC_Message__c';
    private static List<Schema.SObjectType> objectsWithActivitiesEnabled;

    private static void createTestData() {
        // create a record for the custom setting
        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_eLetter_Sender_Class__c = MOCK_SENDER;
        PC_Database.ins(cSetting);

        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t1234.com', 'test1');
        PC_Database.ins(objUser);

        //Create Patient
        patient = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient.PC_Email__c = 'peharitha@deloitte.com';
        patient.PC_Gender__c='Female';
        patient = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);


        //Create Physician
        physician = PC_Test_Setup.newAccounts('physician',1);
        physician[0].PC_Email__c = 'peharitha@deloitte.com';
        physician[0].PC_Date_of_Birth__c=Date.today();
        physician[0].PC_Gender__c='Female';
        physician[0].Phone='34567863456';
        physician[0] = (Account) PC_Database.ins(physician[0], false);

        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t2.com', 'test2');
        careCoordinator.Phone = '93457543223';
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        //Create Reimbursment Specialist
        reimbursmentSpecialist = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@t12.com', 'test12');
        reimbursmentSpecialist = (User) PC_Database.ins(reimbursmentSpecialist);


        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram('TestPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c = 'TestPgm';
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        //Create Support Plan
        supPlan= PC_Test_Setup.createSupportPlan();
        supPlan.PC_IsActive__c=true;
        supPlan.PC_TriggerEventObject__c='Case';
        supPlan.PC_TriggerEventType__c='Update';
        supPlan.PC_TriggerEventConditionalBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supPlan.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supPlan = (PC_SupportPlan__c) PC_Database.ins(supPlan, false);

        //Create Engagement Program Support Plan Junction Object
        enmtPgmSupPlan= PC_Test_Setup.createEnggmtPgmSupPlan();
        enmtPgmSupPlan.PC_EngagementProgram__c=enmtProgram.Id;
        enmtPgmSupPlan.PC_SupportPlan__c=supPlan.Id;
        enmtPgmSupPlan = (PC_EngagementProgram_SupportPlan__c)PC_Database.ins(enmtPgmSupPlan, false);

        //Create eLetter
        PC_eLetter__c eletter = new PC_eLetter__c (
                Name = 'PC Reffaral',
                PC_Target_Recipients__c = 'Care Coordinator; Treating Physician',
                PC_Communication_Language__c = 'English',
                PC_Send_to_User__c= false,
                PC_Source_Object__c = 'Case'
        );
        eletter = (PC_eLetter__c) PC_Database.ins(eletter);
        eLetterId = (String) eletter.Id;

        //Create Email Template
        system.runAs(objUser) {
            EmailTemplate emailTemplate = new EmailTemplate (
                    developerName = 'Email_Template_Name',
                    FolderId = UserInfo.getUserId(),
                    TemplateType = 'Text',
                    Name = 'Email Template Name',
                    Body = 'This is an Email Body',
                    IsActive = TRUE
            );
            PC_Database.ins(emailTemplate);
        }

        // Create Engagement Program Eletter for Case
        caseEngagementProgramEletter = new PC_Engagement_Program_Eletter__c();
        caseEngagementProgramEletter.PC_eLetter__c = eLetterId;
        caseEngagementProgramEletter.PC_Engagement_Program__c = enmtProgram.Id;
        caseEngagementProgramEletter.PC_PreConfiguredSMSRecipients__c = '[{"name" : "Richard Sean", "phone": "+919861157655", "role": "ENT"}]';
        PC_Database.ins(caseEngagementProgramEletter,false);
        system.assertNotEquals(caseEngagementProgramEletter.Id, null);

        //Create Support Plan Activity1
        supPlanActy1= PC_Test_Setup.createSupportPlanActivity('SupportPlan Activity 1');
        supPlanActy1.PC_ActivityType__c              = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
        supPlanActy1.PC_SubType__c                   = PC_Constants.PC_ELETTER_AUTOMATED_TASK;
        supPlanActy1.PC_ConditionBehavior__c         = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        supPlanActy1.PC_SupportPlan__c = supPlan.Id;
        supPlanActy1.PC_ActionClass__c = 'PC_SendAutoEletterHelper';
        supPlanActy1.PC_AutomationTaskJSON__c = '{"eLetterID":"'+eLetterId+'","eLetterName":"PC Reffaral","targetRecepient":[{"communicationLanguage":"English;French","recepient":"Care Coordinator","selected":true},{"communicationLanguage":"English;French","recepient":"Treating Physician","selected":true}]}';
        supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.ins(supPlanActy1, false);

        //Update Support Plan
        supPlan.PC_InitialActivity__c = supPlanActy1.Id;
        supPlan = (PC_SupportPlan__c) PC_Database.upd(supPlan, false);

        caseOne = PC_Test_Setup.createCase(careCoordinator,patient);
        caseOne.PC_Engagement_Program__c=enmtProgram.Id;
        caseOne.PC_Care_Coordinator__c      =   careCoordinator.Id;
        //caseOne.PC_Reimbursment_Specialist__c      =   reimbursmentSpecialist.Id;
        caseOne.PC_Physician__c             =   physician[0].Id;
        caseOne = (Case) PC_Database.ins(caseOne, false);

        //Populating the objectsWithActivitiesEnabled List.
        objectsWithActivitiesEnabled= new List<Schema.SObjectType>();
        for (Schema.SObjectType whatIdObjectType : Task.WhatId.getDescribe().getReferenceTo()) {
            objectsWithActivitiesEnabled.add(whatIdObjectType);
        }
    }

    private static void createOcrTestData(){
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        // Create Document and attach Pdf
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, 'Eng_Pgm' + 'A');
        oDoc.RecordTypeId = recordTypeId;
        oDoc.PC_Document_Name__c = DOCUMENT_NAME;
        PC_Database.ins(oDoc, false);

        //Attach file to PC Document
        PC_Test_Setup.createFile(oDoc.Id);

        //Attach Attachment to PC Document
        Attachment pcAttachmentPdf = PC_Test_Setup.createAttachment(oDoc.Id);
        PC_Database.ins(pcAttachmentPdf, false);

        //Create template type
        PC_OcrTemplateType__c ocrTemplateTypeObj = new PC_OcrTemplateType__c();
        ocrTemplateTypeObj.Name = OCR_TEMPLATE_TYPE_NAME;
        ocrTemplateTypeObj.PC_APIName__c = OCR_TEMPLATE_TYPE_NAME;
        ocrTemplateTypeObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
        PC_Database.ins(ocrTemplateTypeObj, false);

        //Create template type mappings
        PC_OcrTemplateMapping__c ocrTemplateMappingObj = new PC_OcrTemplateMapping__c();
        ocrTemplateMappingObj.Name = OCR_TEMPLATE_MAPPING_NAME;
        ocrTemplateMappingObj.PC_OcrTemplateType__c = ocrTemplateTypeObj.Id;
        ocrTemplateMappingObj.PC_TargetObject__c = PC_Constants.getQualifiedAPIName('PC_Applicant__c');
        ocrTemplateMappingObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
        ocrTemplateMappingObj.PC_FieldMapping__c = '{"properties": {},"formFields":[{"formField": "First Name", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_First_Name__c')+'"},'+
                '{"formField": "Last Name", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Last_Name__c')+'"},'+
                '{"formField": "Email", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Patient_Email__c')+'"},'+
                '{"formField": "Date of Birth", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')+'"},'+
                '{"formField": "Phone Number", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Phone__c')+'"},'+
                '{"formField": "City", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_City__c')+'"},'+
                '{"formField": "State", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_State__c')+'"},'+
                '{"formField": "Zip", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Zip_Code__c')+'"}]}';
        PC_Database.ins(ocrTemplateMappingObj, false);
    }

    @isTest static void testEletter() {
        try{
            createTestData();
            /*Test.startTest();
                system.runAs(objUser) {
                    Task task = PC_SupportPlanEngine.createTask(caseOne.Id, supPlanActy1,System.today());
                    PC_SendAutoEletterHelper helperClass= new PC_SendAutoEletterHelper();
                    helperClass.performAction('Case',caseOne.Id, supPlanActy1.PC_AutomationTaskJSON__c, task.Id );
                }
            Test.stopTest();*/

            Test.startTest();

            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_AUTOMATION_TASK_HANDLER,PC_Constants.PC_AUTOMATION_TASK,null);
            System.assert(triggerHandlerRegisterList.size()>0);

            system.runAs(objUser) {
                caseOne.Status = 'In Treatment';
                update caseOne;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
        }catch(Exception ex){
            system.debug('exception>>'+ex.getMessage());
            system.assert(false);
        }
    }


    public static void createAddress(Id accounId){

        PC_Address__c address = new PC_Address__c();
        address.PC_Account__c = accounId;
        address.PC_Address_1__c = 'test address line 1';
        address.PC_Address_2__c = 'test address line 2';
        address.PC_City__c = 'EDWARDSVILLE';
        address.PC_State__c = 'MA';
        address.PC_Zip_Code__c = '62025';
        address.PC_Primary_Address__c = true;

        address = (PC_Address__c)PC_Database.ins(address, false);
    }
    @isTest public static void testCreateQueueReminder(){
        createTestData();
        try {
            //Update Support Plan
            supPlan.PC_TriggerEventObject__c = PC_Constants.getQualifiedAPIName('PC_Interaction__c');
            supPlan.PC_TriggerEventType__c='Insert/Update';
            supPlan = (PC_SupportPlan__c) PC_Database.upd(supPlan, false);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Queue Reminder';
            supPlanActy1.PC_ActionClass__c = 'PC_CreateReminderQueueHelper';
            String orgNamespace = PC_Constants.OrgNamespace;
            String reminderSetting = 'PC_AppointmentEmailReminder';
            PC_ReminderQueueUtility.QueueReminderSetting automationJSON = new PC_ReminderQueueUtility.QueueReminderSetting();
            automationJSON.handleExistingQueueCriteria = String.valueOf(PC_ReminderQueueUtility.HandleExistingQueueCriteria.TAKE_NO_ACTION);
            automationJSON.reminderSettingName = reminderSetting;
            automationJSON.reminderChannel = PC_Constants.EMAIL;
            supPlanActy1.PC_AutomationTaskJSON__c = JSON.serialize(automationJSON);
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                interaction1 = PC_Test_Setup.newInteraction(caseOne.Id);
                interaction1.PC_Start__c = System.today();
                interaction1 = (PC_Interaction__c) PC_Database.ins(interaction1, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }

    @isTest public static void testCreateQueueReminderWithMultipleRecipients(){
        createTestData();
        try {
            //Update Eletter
            PC_eLetter__c eLetterToUpdate = [SELECT Id FROM PC_eLetter__c WHERE Id =: eLetterId];
            eLetterToUpdate.Name = 'Sample eLetter';
            eLetterToUpdate.PC_Template_Name__c = 'Email_Template_Name';
            PC_Database.upd(eLetterToUpdate);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Queue Reminder';
            supPlanActy1.PC_ActionClass__c = 'PC_CreateReminderQueueHelper';
            String orgNamespace = PC_Constants.OrgNamespace;
            String reminderSetting = 'PC_SMSReminder';
            PC_ReminderQueueUtility.QueueReminderSetting automationJSON = new PC_ReminderQueueUtility.QueueReminderSetting();
            automationJSON.handleExistingQueueCriteria = String.valueOf(PC_ReminderQueueUtility.HandleExistingQueueCriteria.TAKE_NO_ACTION);
            automationJSON.reminderSettingName = reminderSetting;
            automationJSON.reminderChannel = PC_Constants.PC_SMS;
            supPlanActy1.PC_AutomationTaskJSON__c = JSON.serialize(automationJSON);
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                caseOne.PC_Treatment_Start_Date__c = System.today() ;
                caseOne = (Case) PC_Database.upd(caseOne, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
            /*List<PC_ReminderQueue__c> createdQueues = new List<PC_ReminderQueue__c>([SELECT Id FROM PC_ReminderQueue__c]);
            System.assertEquals(3,createdQueues.size());*/
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
    @isTest public static void testQueueReminderWithMultipleRecipientsError(){
        createTestData();
        try {
            //Update Eletter
            PC_eLetter__c eLetterToUpdate = [SELECT Id FROM PC_eLetter__c WHERE Id =: eLetterId];
            eLetterToUpdate.Name = 'Sample eLetter';
            eLetterToUpdate.PC_Template_Name__c = 'Email_Template_Name';
            PC_Database.upd(eLetterToUpdate);

            caseEngagementProgramEletter.PC_PreConfiguredSMSRecipients__c = '[{"name" : Richard Sean", "phone": "+919861157655", "role": "ENT"}]';
            PC_Database.upd(caseEngagementProgramEletter);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Queue Reminder';
            supPlanActy1.PC_ActionClass__c = 'PC_CreateReminderQueueHelper';
            String orgNamespace = PC_Constants.OrgNamespace;
            String reminderSetting = 'PC_SMSReminder';
            PC_ReminderQueueUtility.QueueReminderSetting automationJSON = new PC_ReminderQueueUtility.QueueReminderSetting();
            automationJSON.handleExistingQueueCriteria = String.valueOf(PC_ReminderQueueUtility.HandleExistingQueueCriteria.TAKE_NO_ACTION);
            automationJSON.reminderSettingName = reminderSetting;
            automationJSON.reminderChannel = PC_Constants.PC_SMS;
            supPlanActy1.PC_AutomationTaskJSON__c = JSON.serialize(automationJSON);
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                caseOne.PC_Treatment_Start_Date__c = System.today() ;
                caseOne = (Case) PC_Database.upd(caseOne, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
            /*List<PC_ReminderQueue__c> createdQueues = new List<PC_ReminderQueue__c>([SELECT Id FROM PC_ReminderQueue__c]);
            System.assertEquals(0,createdQueues.size());*/
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
    @isTest public static void testErrorCase(){
        createTestData();
        try {

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Queue Reminder';
            supPlanActy1.PC_ActionClass__c = 'PC_SupportPlanEngine';

            String orgNamespace = PC_Constants.OrgNamespace;
            String reminderSetting = 'PC_AppointmentEmailReminder';
            PC_ReminderQueueUtility.QueueReminderSetting automationJSON = new PC_ReminderQueueUtility.QueueReminderSetting();
            automationJSON.handleExistingQueueCriteria = String.valueOf(PC_ReminderQueueUtility.HandleExistingQueueCriteria.TAKE_NO_ACTION);
            automationJSON.reminderSettingName = reminderSetting;
            automationJSON.reminderChannel = PC_Constants.EMAIL;

            supPlanActy1.PC_AutomationTaskJSON__c = JSON.serialize(automationJSON);

            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                caseOne.Status = 'In Treatment';
                update caseOne;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
            List<Task> errorTasks = new List<Task>([SELECT Id,Status,Description FROM Task WHERE Status =: PC_Constants.PC_TASK_STATUS_WAITING]);
            System.assertEquals(false,errorTasks.isEmpty());
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
    @isTest static void testPharmacy(){
        createTestData();
        try {
            createAddress(patient.Id);
            system.assertNotEquals(patient.Id, null);

            //Physician
            List<Account> physicians = PC_Test_Setup.createAccounts('PHY', 1, PC_Constants.PHYSICIAN_RECORD_TYPE);
            physicians[0].PC_NPI__c = '111111';
            physicians = PC_Database.ins(physicians);
            createAddress(physicians[0].Id);

            Product2 product = new Product2();
            product.ProductCode = 'pc';
            product.PC_Manufacturer__c = manufacturer.Id;
            product.Name = 'n';
            product = (Product2) PC_Database.ins(product);

            PC_Engagement_Program_Product__c engagement_program_product = new PC_Engagement_Program_Product__c();
            engagement_program_product.PC_Product__c = product.Id;
            engagement_program_product.PC_Engagement_Program__c = enmtProgram.Id;
            engagement_program_product = (PC_Engagement_Program_Product__c) PC_Database.ins(engagement_program_product);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Pharmacy Card Lookup';
            supPlanActy1.PC_ActionClass__c = 'PC_PharmacyLookupAutomatedTask';
            supPlanActy1.PC_AutomationTaskJSON__c = '';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser) {
                caseOne.AccountId = patient.Id;
                caseOne.PC_Physician__c = physicians[0].Id;
                caseOne.PC_Program_Product__c = engagement_program_product.Id;
                update caseOne;
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();

        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

    }

    @isTest public static void testCreateOcrQueue(){
        createTestData();
        createOcrTestData();
        try {
            //Update Support Plan
            supPlan.PC_TriggerEventObject__c = PC_Constants.getQualifiedAPIName('PC_Document__c');
            supPlan.PC_TriggerEventType__c = 'Update';
            supPlan = (PC_SupportPlan__c) PC_Database.upd(supPlan, false);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Queue Document To OCR';
            supPlanActy1.PC_ActionClass__c = 'PC_CreateOcrDocumentQueueHelper';
            String templateTypeName = OCR_TEMPLATE_TYPE_NAME;
            PC_OcrQueueUtil.OcrAutomationTaskSetting automationJSON = new PC_OcrQueueUtil.OcrAutomationTaskSetting();
            automationJSON.templateTypeName = templateTypeName;
            supPlanActy1.PC_AutomationTaskJSON__c = JSON.serialize(automationJSON);
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                oDoc.PC_Page_Count__c = 5;
                PC_Database.upd(oDoc, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }

    @isTest public static void testPharmacyBenefitsInvestigation(){
        createTestData();
        try {
            //Update Support Plan
            supPlan.PC_TriggerEventObject__c = 'Case';
            supPlan.PC_TriggerEventType__c = 'Insert/Update';
            supPlan = (PC_SupportPlan__c) PC_Database.upd(supPlan, false);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Pharmacy Benefits Investigation';
            supPlanActy1.PC_ActionClass__c = 'PC_SPPharmacyBenefitsInvestigation';
            supPlanActy1.PC_AutomationTaskJSON__c = '';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                caseOne.Description = 'Pharmacy' ;
                caseOne = (Case) PC_Database.upd(caseOne, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
    @isTest public static void testMedicalBenefitsInvestigation(){
        createTestData();
        try {
            //Update Support Plan
            supPlan.PC_TriggerEventObject__c = 'Case';
            supPlan.PC_TriggerEventType__c = 'Insert/Update';
            supPlan = (PC_SupportPlan__c) PC_Database.upd(supPlan, false);

            //Update Support Plan Activity1
            supPlanActy1.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK;
            supPlanActy1.PC_SubType__c = 'Medical Benefits Investigation';
            supPlanActy1.PC_ActionClass__c = 'PC_SPMedicalBenefitsInvestigation';
            supPlanActy1.PC_AutomationTaskJSON__c = '';
            supPlanActy1 = (PC_SupportPlanActivity__c) PC_Database.upd(supPlanActy1, false);

            Test.startTest();
            system.runAs(objUser){
                caseOne.Description = 'Medical' ;
                caseOne = (Case) PC_Database.upd(caseOne, false);
            }
            //Deliver the Support Plan Info Platform event with context "ExecuteActions"
            Test.getEventBus().deliver();
            //Deliver the Support Plan Info Platform event with context "ProcessSupportPlanRuntimes"
            Test.getEventBus().deliver();
            Test.stopTest();
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }

    @isTest static void testHandlingObjectsWithActivitiesDisabled(){
        try {
            createTestData();
            Test.StartTest();
            System.runAs(objUser) {
                PC_AutomationTaskHelper.handleObjectsWithActivitiesDisabled(triggerObjectType, objectsWithActivitiesEnabled);
            }
            Test.StopTest();
        }catch(Exception ex){
            system.assert(false);
        }
    }
}