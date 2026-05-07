/*********************************************************************************************************
Trigger Name    : PC_Trigger_CandidatePatient 
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
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_CandidatePatient extends PC_TriggerHandler {
    public static final String TEST_STRING = 'TestString';

    override public void beforeInsert(){
       	updateRecordType((List<PC_Applicant__c>) newList);
    }

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
            PC_Database.ins(doc, false);//CRUD/FLS check enforced in the database ins method, but it's not meaning in this handler as the trigger is always running in System Mode
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }
        
        //creates document log of initial version of candidate patient record from online form
        PC_Document_Log__c docLog = new PC_Document_Log__c();
        docLog.PC_Document__c = doc.Id;
        try {
            PC_Database.ins(docLog, false);//CRUD/FLS check enforced in the database ins method, but it's not meaning in this handler as the trigger is always running in System Mode
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }
        
        //creates attachment of initial version of candidate patient record from online form
        Attachment attach = new Attachment();
        pageReference pdf = Page.PC_ConvertedForm;
        pdf.getParameters().put('id',cpId);
        if(!test.isRunningTest()){
            attach.Body = pdf.getContent();
        } else{
            attach.Body = Blob.valueOf(TEST_STRING);
        }
        attach.Name = patientName + PC_Constants.PDF_FORMAT;
        attach.IsPrivate = false;
        attach.ParentId = doc.Id;
        try {
            PC_Database.ins(attach, false);//CRUD/FLS check enforced in the database ins method ,but it's not meaning in this handler as the trigger is always running in System Mode
        } catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }

    /*********************************************************************************
    Method Name    : updateRecordType
    Author         : Prachi Nandgaonkar
    Description    : This method  updates record type for applicants created via Online Form submission [PC-1321]
    Return Type    : void
    Parameter      : List of incoming applicant records - Trigger.new
    *********************************************************************************/
    private void updateRecordType(List<PC_Applicant__c> applicants) {
       List<PC_Applicant__c> applicantsToUpdate = new List<PC_Applicant__c>();
        if(applicants.size() > 0){
            Id applicantRecTypeId = PC_SYSTEM.recordTypeId(PC_Constants.CANDIDATE_PATIENT_OBJECT, PC_Constants.APPLICANT_ONLINE_RECORD_TYPE);
			/*
			* No FLS Check Needed. This should run in the system context.
			*/
            for (PC_Applicant__c a : applicants) {
                if (a.PC_Source__c) {
                    a.RecordTypeId = applicantRecTypeId;
                    applicantsToUpdate.add(a);
                }
            }
        }
	}
}