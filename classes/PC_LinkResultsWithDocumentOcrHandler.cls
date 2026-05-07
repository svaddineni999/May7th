/**
 * Created by sathekumar on 11/17/2021.
 */

public inherited sharing class PC_LinkResultsWithDocumentOcrHandler extends PC_TriggerHandler {
    override public void afterInsert() {
        LinkNonApplicantWithDocument((List<PC_OcrResult__c>) newList, (Map<Id, PC_OcrResult__c>) newMap);
    }

    private void LinkNonApplicantWithDocument(List<PC_OcrResult__c> ocrResultList, Map<Id, PC_OcrResult__c> newOcrResultsByIdsMap) {
        String associationRecordName = PC_Constants.EMPTY_STRING;
        String recordTypeName = PC_Constants.EMPTY_STRING;
        String objectLabel = PC_Constants.EMPTY_STRING;
        String sObjectType = PC_Constants.EMPTY_STRING;
        String targetRecordId = PC_Constants.EMPTY_STRING;
        String documentId = PC_Constants.EMPTY_STRING;
        Map<String, Schema.SObjectType> sObjectMap = Schema.getGlobalDescribe();

        PC_Document_Log__c pcDocumentLog = new PC_Document_Log__c();
        List<PC_Document_Log__c> pcDocumentLogList = new List<PC_Document_Log__c>();
        Set<Id> ocrResultIds = new Set<Id>();
        Set<String> targetRecordIds = new Set<String>();
        Set<String> documentIds = new Set<String>();
        Map<String, String> documentAndAssociationRecordIdMap = new Map<String, String>();
        try {
            ocrResultIds = newOcrResultsByIdsMap.keySet();
            Map<Id, PC_OcrResult__c> ocrResultMap = new Map<Id, PC_OcrResult__c>([
                    SELECT Id, Name, PC_OcrQueue__r.PC_SourceDocument__c, PC_ResultingRecordId__c, PC_ResultStatus__c, PC_OcrQueue__r.OwnerId
                    FROM PC_OcrResult__c
                    WHERE PC_OcrQueue__c != null AND PC_ResultingRecordId__c != null AND PC_ResultStatus__c = 'Success' AND Id IN :ocrResultIds
            ]);

            for (PC_OcrResult__c ocrResult : ocrResultMap.values()) {
                if (String.isNotBlank(ocrResult.PC_ResultingRecordId__c)) {
                    targetRecordIds.add(ocrResult ?.PC_ResultingRecordId__c);
                }
                if (String.isNotBlank(ocrResult ?.PC_OcrQueue__r ?.PC_SourceDocument__c)) {
                    documentIds.add(ocrResult ?.PC_OcrQueue__r ?.PC_SourceDocument__c);
                }
            }

            Map<Id, PC_Document_Log__c> documentLogMap = new Map<Id, PC_Document_Log__c>([
                    SELECT Name, PC_Document_Log__c, PC_Document__c, PC_Association_Record_Id__c, PC_Association_Type__c, PC_Association_Record_Name__c
                    FROM PC_Document_Log__c
                    WHERE PC_Document__c IN :documentIds AND PC_Association_Record_Id__c IN :targetRecordIds
            ]);

            for (PC_Document_Log__c documentLog : documentLogMap.values()) {
                documentAndAssociationRecordIdMap.put(documentLog.PC_Document__c, documentLog.PC_Association_Record_Id__c);
            }

            for (PC_OcrResult__c ocrResult : ocrResultMap.values()) {
                targetRecordId = ocrResult ?.PC_ResultingRecordId__c;
                documentId = ocrResult ?.PC_OcrQueue__r ?.PC_SourceDocument__c;
                system.debug('targetRecordId--->' + targetRecordId);
                system.debug('documentId--->' + documentId);
                if (String.isNotBlank(targetRecordId)) {
                    sObjectType = String.valueOf(Id.valueOf(targetRecordId).getSobjectType());
                    objectLabel = sObjectMap.get(sObjectType).getDescribe().getLabel();
                    if (sObjectType != PC_Constants.CANDIDATE_PATIENT_OBJECT) {
                        if (! (documentAndAssociationRecordIdMap.containsKey(documentId) && documentAndAssociationRecordIdMap.get(documentId) == targetRecordId)) {
                            system.debug('isLinkLogExists--->true');
                            recordTypeName = PC_Utility.getRecordTypeNameByRecordId(targetRecordId);

                            List<sObject> sObj = new List<sObject>();
                            String query = 'Select Id, Name from ' + sObjectType + ' where id = \'' + targetRecordId + '\'';
                            sObj = PC_Database.queryWithAccess(query, false);
                            if (!sObj.isEmpty()) {
                                associationRecordName = (String) sObj[0].get('Name');
                            }
                            pcDocumentLog.PC_Document__c = documentId;
                            pcDocumentLog.PC_Association_Record_ID__c = targetRecordId;
                            pcDocumentLog.PC_Association_Record_Name__c = associationRecordName;
                            pcDocumentLog.PC_Association_Type__c = (String.isNotBlank(recordTypeName)) ? objectLabel + ': ' + recordTypeName : objectLabel;
                            pcDocumentLogList.add(pcDocumentLog);
                        }
                    }
                }
            }
            system.debug('pcDocumentLogList--->' + pcDocumentLogList.size());
            if (pcDocumentLogList.size() > 0) {
                system.debug('pcDocumentLogList--->' + pcDocumentLogList);
                PC_Database.ins(pcDocumentLogList, false);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
}