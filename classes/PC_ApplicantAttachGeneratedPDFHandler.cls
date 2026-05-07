/*********************************************************************************************************
Trigger Handler Name    : PC_ApplicantAttachGeneratedPDF
Description     : trigger on PC_Applicant__c object.
Created By      : Tetiana Danylyshyn
Created Date    : June 1, 2016
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#      	Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tetiana Danylyshyn            	June 1, 2016          	Initial Version
Shabda Bhujad,        		  	Nov 4, 2016				Removed PC_Brand__c,  PC_Country__c field(Document Object)references annotated by @@RemoveBranCntryRef
Prachi Nandgaonkar
Shabda Bhujad					Dec 06, 2016			Added FLS check to attachGeneratedPDF method
Prachi Nandgoankar              Mar 3, 2017             Replaced references to PC_SYSTEM.recordTypeId by PC_SYSTEM.getRecordTypeIdByName [PC-1242]
Prachi Nandgaonkar              Mar 16 2017             Added updateRecordType() to add record type for online form applicants [PC-1321]
Ajinkya Deshmukh				Jun 23, 2017			FLS Check Added (Code Merge)
Mike Klumpenaar                 23-Jun-2017             Revert to using PC_SYSTEM.recordTypeId to resolve transaction issue [PC-1817]
Mayuresh Patil                  Jul 26, 2017            Updated CRUD/FLS checks
Shabda Bhujad                   Nov 14, 2017            PC-2485 Removing the reference to trigger state
Shabda Bhujad                   Dec 14, 2017            PC-1884 Logical breakdown of the trigger handlers
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Shishir Bansal                   Dec-06-2019            [PC-5792] Avoid hardcoding of string variable
Satheesh Kumar                   Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_ApplicantAttachGeneratedPDFHandler extends PC_TriggerHandler{
    public static final String TEST_STRING = 'TestString';
    public static final String SHARING_OPTION = 'A';
    public static final String SHARING_TYPE = 'V';

    override public void afterInsert(){
        List<PC_Applicant__c> applicants = (List<PC_Applicant__c>)newList;
        // PC_Source__c is a check box - checked when the applicant is created by online form
        if (applicants.size() == 1 && applicants[0].PC_Source__c) {
            attachGeneratedPDF(applicants[0].Id, applicants[0].PC_Last_Name__c, applicants[0].PC_Engagement_Program__c);
        }
    }
    /*********************************************************************************
       Method Name    : attachGeneratedPDF
       Author         : Tetiana Danylyshyn
       Description    : This method creats generated from form attachment and document
       Return Type    : void
       Parameter      : List of incoming candidate patient records - Trigger.new
       *********************************************************************************/
    @future(callout=true)
    private static void attachGeneratedPDF(Id cpId, String patientName, String engagementProgram) {
        Id docRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE);
        List<Group> docQueue =[SELECT Id FROM Group WHERE DeveloperName =: PC_Constants.PATIENT_CONNECT_QUEUE];
        PC_Document__c doc = new PC_Document__c(RecordTypeId = docRecordTypeId, PC_Applicant__c = cpId, PC_Engagement_Program__c = engagementProgram);
        if (docQueue.size() > 0) {
            doc.OwnerId = docQueue[0].Id;
        }

        try {
            PC_Database.ins(doc, false);
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }

        //creates document log of initial version of candidate patient record from online form
        PC_Document_Log__c docLog = new PC_Document_Log__c();
        docLog.PC_Document__c = doc.Id;
        try {
            PC_Database.ins(docLog, false);
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }

        //creates attachment of initial version of candidate patient record from online form

        Boolean useSalesforceFiles = false;
        useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();

        if(useSalesforceFiles){

            /*ContentVersion contentVersion_1 = new ContentVersion(
                    Title = patientName + PC_Constants.PDF_FORMAT,
                    PathOnClient = 'Penguins.jpg',
                    VersionData = Blob.valueOf('Test Content')
                    IsMajorVersion = true
            );*/


            ContentVersion contentVersion_1 = new ContentVersion();
            pageReference pdf = Page.PC_ConvertedForm;
            pdf.getParameters().put('id', cpId);
            contentVersion_1.title = patientName + PC_Constants.PDF_FORMAT;
            contentVersion_1.PathOnClient = patientName + PC_Constants.PDF_FORMAT;
            if (!test.isRunningTest()) {
                //attach.Body = pdf.getContent();
                contentVersion_1.versiondata = pdf.getContent();
            } else {
                //attach.Body = Blob.valueOf(TEST_STRING);
                contentVersion_1.versiondata =  Blob.valueOf(TEST_STRING);
            }

            contentVersion_1.SharingOption = SHARING_OPTION;
            try {
                PC_Database.ins(contentVersion_1, false);//CRUD/FLS check enforced in the database ins method ,but it's not meaning in this handler as the trigger is always running in System Mode

               if(contentVersion_1.id != null) {

                   ContentDocumentLink cdl = new ContentDocumentLink();
                   cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.id].ContentDocumentId;
                   cdl.LinkedEntityId =doc.Id ;
                   cdl.ShareType = SHARING_TYPE;
                   PC_Database.ins(cdl, false);
               }
            } catch (Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
        }

        else {




            Attachment attach = new Attachment();
            pageReference pdf = Page.PC_ConvertedForm;
            pdf.getParameters().put('id', cpId);
            if (!test.isRunningTest()) {
                attach.Body = pdf.getContent();
            } else {
                attach.Body = Blob.valueOf('TestString');
            }
            attach.Name = patientName + PC_Constants.PDF_FORMAT;
            attach.IsPrivate = false;
            attach.ParentId = doc.Id;
            try {
                PC_Database.ins(attach, false);
            } catch (Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
        }
    }
}