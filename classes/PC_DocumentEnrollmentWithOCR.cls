/**
 * Created by sathekumar on 6/24/2021.
 */

public with sharing class PC_DocumentEnrollmentWithOCR {

    @AuraEnabled
    public static DocumentStatus checkDocumentOcrStatus(String documentId) {
        DocumentStatus documentStatus = new DocumentStatus();
        try {
            documentStatus.ocrServiceEnabled = isOcrServiceEnabled();
            documentStatus.previousOcrQueueStatus = previousOcrQueueStatus(documentId);
            documentStatus.applicantExistOnDocument = isApplicantExistOnDocument(documentId);
            documentStatus.enrollmentCaseExistOnDocument = isEnrollmentCaseExistOnDocument(documentId);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return documentStatus;
    }

    @AuraEnabled
    public static String cancelOCR(String documentId) {
        String message;
        try {
            List<String> ocrQueueFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_SourceDocument__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_IsActive__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields);
            List<PC_OcrQueue__c> ocrQueueList = [SELECT Id, PC_SourceDocument__c, PC_Status__c, PC_IsActive__c FROM PC_OcrQueue__c WHERE PC_SourceDocument__c = :documentId AND PC_Status__c IN ('Queued', 'In Progress') LIMIT 1];
            if (ocrQueueList.size() > 0) {
                PC_OcrQueue__c ocrQueue = ocrQueueList[0];
                ocrQueue.PC_Status__c = PC_Constants.PC_OCR_QUEUE_STATUS_CANCELED;
                ocrQueue.PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
                PC_Database.upd(ocrQueue);
            } else {
                message = System.Label.PC_NotAbleToCancelOcrMessage;
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return message;
    }

    @AuraEnabled
    public static ApplicantOcrDetails getApplicantOcrDetails(String enrollmentCaseId) {
        ApplicantOcrDetails applicantOcrDetails = new ApplicantOcrDetails();
        try {
            applicantOcrDetails.isOcrEnabled = isOcrServiceEnabled();
            if(applicantOcrDetails.isOcrEnabled) {
                // FLS Check for PC_Document__c
                List<String> fields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c') };
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
                String activeApplicantId = [SELECT Id, PC_ActiveApplicant__c FROM Case WHERE Id = :enrollmentCaseId LIMIT 1] ?.PC_ActiveApplicant__c;
                if (String.isNotBlank(activeApplicantId)) {
                    PC_Applicant__c applicantObj = [SELECT Id, PC_IsCreatedUsingOCR__c, PC_IsReviewed__c FROM PC_Applicant__c WHERE Id =: activeApplicantId];
                    applicantOcrDetails.isCreatedUsingOCR = applicantObj.PC_IsCreatedUsingOCR__c;
                    applicantOcrDetails.isReviewed = applicantObj.PC_IsReviewed__c;
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return applicantOcrDetails;
    }


    private static String previousOcrQueueStatus(String documentId) {
        Boolean isValid;
        //FLS Check
        List<String> ocrQueueFields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_SourceDocument__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_IsActive__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields);
        String ocrQueueStatus = [SELECT Id, PC_SourceDocument__c, PC_Status__c, PC_IsActive__c FROM PC_OcrQueue__c WHERE PC_SourceDocument__c = :documentId ORDER BY createdDate DESC LIMIT 1]?.PC_Status__c;
        return ocrQueueStatus;
    }

    private static Boolean isOcrServiceEnabled() {
        String useOCR = PC_SYSTEM.getPatientConnectSetting('PC_UseOCR', PC_Constants.FALSE_STRING);
        return Boolean.valueOf(useOCR);
    }

    private static Boolean isApplicantExistOnDocument(String documentId) {
        // Check FLS for PC_Document__c
        List<String> pcDocumentFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Applicant__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, pcDocumentFields);
        PC_Document__c documentObj = [SELECT Id, PC_Applicant__c FROM PC_Document__c WHERE Id = :documentId];
        if (String.isNotBlank(documentObj.PC_Applicant__c)) {
            return true;
        }
        return false;
    }

    private static Boolean isEnrollmentCaseExistOnDocument(String documentId) {
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
        List<PC_Document_Log__c> docLog = [ SELECT PC_Program__c, PC_Program__r.RecordTypeId FROM PC_Document_Log__c WHERE PC_Document__c = :documentId AND (PC_Program__r.RecordTypeId = :recordTypeId) LIMIT 1];
        if (docLog.isEmpty()) {
            return false;
        } else {
            return true;
        }
    }

    public inherited sharing class DocumentStatus {
        @AuraEnabled public Boolean ocrServiceEnabled { get; set; }
        @AuraEnabled public String previousOcrQueueStatus { get; set; }
        @AuraEnabled public Boolean applicantExistOnDocument { get; set; }
        @AuraEnabled public Boolean enrollmentCaseExistOnDocument { get; set; }

        public DocumentStatus() {
            ocrServiceEnabled = PC_Constants.FALSE_BOOLEAN;
            previousOcrQueueStatus = PC_Constants.EMPTY_STRING;
            applicantExistOnDocument = PC_Constants.FALSE_BOOLEAN;
            enrollmentCaseExistOnDocument = PC_Constants.FALSE_BOOLEAN;
        }
    }

    public inherited sharing class ApplicantOcrDetails {
        @AuraEnabled public Boolean isOcrEnabled { get; set; }
        @AuraEnabled public Boolean isCreatedUsingOCR { get; set; }
        @AuraEnabled public Boolean isReviewed { get; set; }

        public ApplicantOcrDetails() {
            isOcrEnabled = PC_Constants.FALSE_BOOLEAN;
            isCreatedUsingOCR = PC_Constants.FALSE_BOOLEAN;
            isReviewed = PC_Constants.FALSE_BOOLEAN;
        }
    }
}