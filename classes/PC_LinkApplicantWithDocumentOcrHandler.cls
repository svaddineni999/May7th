/*****************************************************************************************
Class Name    	: PC_LinkApplicantWithDocumentOcrHandler
Description     : trigger on OCR Result object.
Created By      : Deloitte
Created Date    : Nov 17, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar            Nov 17, 2021           Initial Version
*********************************************************************************************/
public inherited sharing class PC_LinkApplicantWithDocumentOcrHandler extends PC_TriggerHandler {
    override public void afterInsert(){
        LinkApplicantWithDocument((List<PC_OcrResult__c>) newList, (Map<Id, PC_OcrResult__c>) newMap);
    }

    private void LinkApplicantWithDocument(List<PC_OcrResult__c> ocrResultList, Map<Id, PC_OcrResult__c> newOcrResultsByIdsMap) {
        try {
            List<PC_Document__c> listOfDocumentsToLinkApplicant = new List<PC_Document__c>();
            Map<String, String> documentApplicantMap = new Map<String, String>();
            Map<String, String> ocrResultAndQueueMap = new Map<String, String>();
            Map<Id, List<PC_Document_Log__c>> mapOfDocumentLogsByDocumentIds = new Map<Id, List<PC_Document_Log__c>>();
            List<String> ocrQueueIds = new List<String>();
            Set<Id> docIds = new Set<Id>();
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);

            for (PC_OcrResult__c o : ocrResultList) {
                if (o.PC_ResultStatus__c != null && o.PC_ResultStatus__c == 'Success') {
                    if (String.isNotBlank(o.PC_OcrQueue__c)) {
                        ocrResultAndQueueMap.put(o.Id, o.PC_OcrQueue__c);
                    }
                }
            }
            ocrQueueIds = ocrResultAndQueueMap.values();
            Map<Id, PC_OcrQueue__c> ocrQueueMap = new Map<Id, PC_OcrQueue__c>([
                    SELECT Id, Name, PC_SourceDocument__c, PC_Status__c, PC_IsActive__c, OwnerId
                    FROM PC_OcrQueue__c
                    WHERE PC_IsActive__c = true AND PC_Status__c != 'Canceled' AND Id IN :ocrQueueIds
            ]);

            for (PC_OcrResult__c ocrResult : ocrResultList) {
                PC_OcrQueue__c ocrQueue = ocrQueueMap.get(ocrResult.PC_OcrQueue__c);
                if (ocrQueue.PC_Status__c != PC_Constants.PC_OCR_QUEUE_STATUS_CANCELED) {
                    Id resultingRecordId = ocrResult ?.PC_ResultingRecordId__c;
                    if (String.isNotBlank(resultingRecordId) && String.valueOf((resultingRecordId).getSobjectType()) == PC_Constants.CANDIDATE_PATIENT_OBJECT && String.isNotBlank(ocrQueue.PC_SourceDocument__c)) {
                        documentApplicantMap.put(ocrQueue.PC_SourceDocument__c, resultingRecordId);
                    }
                }
            }

            Map<Id, PC_Document__c> documentMap = new Map<Id, PC_Document__c>([Select Id, PC_Applicant__c from PC_Document__c where Id IN :documentApplicantMap.keySet()]);

            for (PC_Document_Log__c docLog : [SELECT PC_Program__c, PC_Document__c, PC_Program__r.RecordTypeId FROM PC_Document_Log__c WHERE PC_Document__c IN :documentMap.keySet() AND (PC_Program__r.RecordTypeId = :recordTypeId)]) {
                if (mapOfDocumentLogsByDocumentIds.containsKey(docLog.PC_Document__c)) {
                    List<PC_Document_Log__c> docLogList = mapOfDocumentLogsByDocumentIds.get(docLog.PC_Document__c);
                    docLogList.add(docLog);
                    mapOfDocumentLogsByDocumentIds.put(docLog.PC_Document__c, docLogList);
                } else {
                    mapOfDocumentLogsByDocumentIds.put(docLog.PC_Document__c, new List<PC_Document_Log__c>{
                            docLog
                    });
                }
            }

            for (PC_Document__c doc : documentMap.values()) {
                if (String.isBlank(doc.PC_Applicant__c)) {
                    doc.PC_Applicant__c = documentApplicantMap.get(doc.Id);
                    listOfDocumentsToLinkApplicant.add(doc);
                } else {
                    List<PC_Document_Log__c> docLogList = new List<PC_Document_Log__c>();
                    docLogList = (mapOfDocumentLogsByDocumentIds.containsKey(doc.Id)) ? mapOfDocumentLogsByDocumentIds.get(doc.Id) : new List<PC_Document_Log__c>();
                    if (docLogList.isEmpty()) {
                        doc.PC_Applicant__c = documentApplicantMap.get(doc.Id);
                        listOfDocumentsToLinkApplicant.add(doc);
                    }
                }
            }
            if (listOfDocumentsToLinkApplicant.size() > 0) {
                PC_Database.upd(listOfDocumentsToLinkApplicant, false);
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }
}