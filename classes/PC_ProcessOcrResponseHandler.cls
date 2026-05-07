/*****************************************************************************************
Class Name    	: PC_ProcessOcrResponseHandler
Description     : trigger on OCR Response object.
Created By      : Deloitte
Created Date    : May 03, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 03, 2021           Initial Version
Satheesh Kumar             Nov 09, 2021           [PC-8308] Updated query to respect 'Create results post OCR completion' config
Satheesh Kumar             Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
*********************************************************************************************/

public inherited sharing class PC_ProcessOcrResponseHandler extends PC_TriggerHandler {
    override public void afterUpdate() {
        processOcrResponse((Map<Id, PC_OcrResponse__c >) oldMap, (List<PC_OcrResponse__c >) newList);
    }

    private void processOcrResponse(Map<Id, PC_OcrResponse__c > oldMap, List<PC_OcrResponse__c > newList) {
        system.debug('oldMap---'+oldMap);
        Set<Id> ocrResponseIds = new Set<Id>();
        List<PC_OcrResponse__c> ocrResponseList = new List<PC_OcrResponse__c>();
        Map<Id, String> ocrResponseAndQueueMap = new Map<Id, String>();
        Map<Id, List<PC_OcrTemplateMapping__c>> responseTemplateMapping;
        Map<Id, PC_OcrQueue__c> ocrQueueMap = new Map<Id, PC_OcrQueue__c>();
        Map<Id, List<PC_OcrResult__c>> mapOfOcrResultsByQueueIds = new Map<Id, List<PC_OcrResult__c>>();
        List<PC_OcrQueue__c> updatedQueueList = new List<PC_OcrQueue__c>();
        List<PC_OcrQueue__c> ocrQueueNoResultsList = new List<PC_OcrQueue__c>();
        try {
            for (PC_OcrResponse__c o : newList) {
                //Only Status Changed from OCR Enqueue to Success
                if (o.PC_OcrStatus__c != null && o.PC_OcrStatus__c == 'Success' && o.PC_OcrStatus__c != oldMap.get(o.Id).PC_OcrStatus__c) {
                    //if (o.PC_OcrStatus__c != null && o.PC_OcrStatus__c == 'Success' && ((oldMap != null && o.PC_OcrStatus__c != oldMap.get(o.Id).PC_OcrStatus__c) || oldMap == null)) {
                    if (String.isNotBlank(o.PC_OcrQueue__c)) {
                        ocrResponseAndQueueMap.put(o.Id, o.PC_OcrQueue__c);
                        ocrResponseIds.add(o.Id);
                        ocrResponseList.add(o);
                    }
                }
            }
            system.debug('ocrResponseAndQueueMap-----' + ocrResponseAndQueueMap);
            if (ocrResponseList.size() > 0) {
                Set<String> ocrQueueIds = new Set<String>(ocrResponseAndQueueMap.values());
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                /*FLS Check for OCR Queue fields
                List<String> ocrQueueFields = new List<String>{
                        'Id', PC_Constants.getQualifiedAPIName('PC_SourceDocument__c'), PC_Constants.getQualifiedAPIName('PC_SourceDocument__r.Name'),
                        PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'),
                        PC_Constants.getQualifiedAPIName('PC_NotifyStatus__c'), PC_Constants.getQualifiedAPIName('PC_IsActive__c'),
                        PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__r.PC_CreateResultsAfterOCRCompletion__c'), 'OwnerId'
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields); */
                /** Get map of all OCR Queues */
                ocrQueueMap = new Map<Id, PC_OcrQueue__c>([
                        SELECT Id, Name, PC_SourceDocument__c, PC_SourceDocument__r.Name, PC_OcrTemplateType__c, PC_Status__c, PC_NotifyStatus__c, PC_IsActive__c, OwnerId, PC_OcrTemplateType__r.PC_CreateResultsAfterOCRCompletion__c
                        FROM PC_OcrQueue__c
                        WHERE PC_IsActive__c = true AND PC_OcrTemplateType__c != null AND PC_OcrTemplateType__r.PC_CreateResultsAfterOCRCompletion__c = true
                        AND Id IN :ocrQueueIds
                ]);
                ocrQueueNoResultsList = [
                        SELECT Id, Name, PC_SourceDocument__c, PC_SourceDocument__r.Name, PC_OcrTemplateType__c, PC_Status__c, PC_NotifyStatus__c, PC_IsActive__c, OwnerId, PC_OcrTemplateType__r.PC_CreateResultsAfterOCRCompletion__c
                        FROM PC_OcrQueue__c
                        WHERE PC_IsActive__c = true AND PC_OcrTemplateType__r.PC_CreateResultsAfterOCRCompletion__c = false
                        AND Id IN :ocrQueueIds
                ];
                sendNotification(ocrQueueNoResultsList, new Map<Id, List<PC_OcrResult__c>>());
                if(!ocrQueueMap.isEmpty()) {
                    Set<Id> ocrTemplateTypeList = new Set<Id>();
                    Map<Id, String> ocrResponseToTemplateTypeMap = new Map<Id, String>();
                    for (Id ocrResponseId : ocrResponseAndQueueMap.keySet()) {
                        String templateTypeId = ocrQueueMap.get(ocrResponseAndQueueMap.get(ocrResponseId)) ?.PC_OcrTemplateType__c;
                        ocrTemplateTypeList.add(templateTypeId);
                        ocrResponseToTemplateTypeMap.put(ocrResponseId, templateTypeId);
                    }
                    system.debug('ocrResponseToTemplateTypeMap-----' + ocrResponseToTemplateTypeMap);

                    /** Get map of OCR Template Type to OCR Template Mapping.
                    Map<TemplateTypeId, List<PC_OcrTemplateMapping__c>> */
                    Map<Id, List<PC_OcrTemplateMapping__c>> mapOfTemplateTypeIdToTemplateMappings = PC_OcrResponseHelper.getOcrTemplateMapping(ocrTemplateTypeList);

                    List<sObject> finalRecordList = new List<sObject>();
                    Map<Id, List<sObject>> ocrQueueToSobjectListMap = new Map<Id, List<sObject>>();
                    for (PC_OcrResponse__c ocrResponse : ocrResponseList) {
                        String templateTypeId = ocrResponseToTemplateTypeMap.get(ocrResponse.Id);
                        List<PC_OcrTemplateMapping__c> templateMappings = mapOfTemplateTypeIdToTemplateMappings.get(templateTypeId);
                        if (templateMappings == null || templateMappings.size() == 0) {
                            throw new PC_ProcessOcrResponseHandlerException(System.Label.PC_NoActiveTemplateMappingFound);
                        }
                        List<sObject> recordList = PC_OcrResponseHelper.parseResponseJsonAsSobjects(ocrResponse, mapOfTemplateTypeIdToTemplateMappings.get(templateTypeId));
                        String queueId = ocrResponseAndQueueMap.get(ocrResponse.Id);
                        if (ocrQueueToSobjectListMap.containsKey(ocrResponseAndQueueMap.get(ocrResponse.Id))) {
                            List<sObject> sObjList = ocrQueueToSobjectListMap.get(queueId);
                            sObjList.addAll(recordList);
                            ocrQueueToSobjectListMap.put(queueId, sObjList);
                        } else {
                            ocrQueueToSobjectListMap.put(queueId, recordList);
                        }
                        finalRecordList.addAll(recordList);
                    }
                    system.debug('final recordList-----' + finalRecordList);

                    // Create Salesforce content Records based on response mapping
                    if (finalRecordList.size() > 0) {
                        //PC_Database.ins(finalRecordList, true);
                        //Database.SaveResult[] contentRecordsSaveResults = PC_Database.ins(finalRecordList);
                        PC_Database.ins(finalRecordList, false);
                    }

                    system.debug('after insert final recordList-----' + finalRecordList);
                    system.debug('after insert ocrQueueToSobjectListMap-----' + ocrQueueToSobjectListMap);
                    List<PC_OcrResult__c> ocrResults = createOcrResultRecord(ocrQueueToSobjectListMap, mapOfOcrResultsByQueueIds);

                    // Insert OCR Result Records
                    if (ocrResults.size() > 0) {
                        PC_Database.ins(ocrResults, false);
                    }

                    //Update OCR Queue Status
                    Map<String, Boolean> ocrQueueStatusMap = new Map<String, Boolean>();
                    for (PC_OcrResult__c ocrResultObj : ocrResults) {
                        if (ocrQueueStatusMap.containsKey(ocrResultObj.PC_OcrQueue__c)) {
                            Boolean ocrStatus = ocrQueueStatusMap.get(ocrResultObj.PC_OcrQueue__c);
                            ocrQueueStatusMap.put(ocrResultObj.PC_OcrQueue__c, (ocrResultObj.PC_ResultStatus__c == 'Success' && ocrStatus));
                        } else {
                            ocrQueueStatusMap.put(ocrResultObj.PC_OcrQueue__c, (ocrResultObj.PC_ResultStatus__c == 'Success'));
                        }
                    }
                    system.debug('ocrQueueStatusMap---->' + ocrQueueStatusMap);
                    system.debug('mapOfOcrResultsByQueueIds---->' + mapOfOcrResultsByQueueIds);
                    updatedQueueList = updateOcrQueueStatus(ocrQueueMap, ocrQueueStatusMap);
                    //linkResultingRecordWithDocument(ocrQueueToSobjectListMap, ocrQueueMap);
                    sendNotification(updatedQueueList, mapOfOcrResultsByQueueIds);
                }
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
            updateOcrQueueToError(ocrQueueMap);
            createErrorTask(ocrQueueMap, ex.getMessage());
        }
    }

    /*private List<PC_Document__c> linkResultingRecordWithDocument(Map<Id, List<sObject>> ocrQueueToSobjectListMap, Map<Id, PC_OcrQueue__c> ocrQueueMap) {
        List<PC_Document__c> listOfDocumentsToLinkApplicant = new List<PC_Document__c>();
        Map<String, String> documentApplicantMap = new Map<String, String>();
        Map<Id, List<PC_Document_Log__c>> mapOfDocumentLogsByDocumentIds = new Map<Id, List<PC_Document_Log__c>>();
        Set<Id> docIds = new Set<Id>();
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);

        for (String queueId : ocrQueueToSobjectListMap.keySet()) {
            PC_OcrQueue__c ocrQueue = ocrQueueMap.get(queueId);
            if(ocrQueue.PC_Status__c != 'Canceled') {
                for (sObject sObj : ocrQueueToSobjectListMap.get(queueId)) {
                    Id resultingRecordId = sObj?.Id;
                    if (String.isNotBlank(resultingRecordId) && String.valueOf((resultingRecordId).getSobjectType()) == PC_Constants.CANDIDATE_PATIENT_OBJECT && String.isNotBlank(ocrQueue.PC_SourceDocument__c)) {
                        documentApplicantMap.put(ocrQueue.PC_SourceDocument__c, resultingRecordId);
                    }
                }
            }
        }

        List<PC_Document__c> documentList = [Select Id, PC_Applicant__c from PC_Document__c where Id IN :documentApplicantMap.keySet()];
        system.debug('documentList---'+documentList);

        for (PC_Document__c doc : documentList) {
            docIds.add(doc.Id);
        }
        for (PC_Document_Log__c docLog : [SELECT PC_Program__c, PC_Document__c, PC_Program__r.RecordTypeId FROM PC_Document_Log__c WHERE PC_Document__c IN :docIds AND (PC_Program__r.RecordTypeId = :recordTypeId)]) {
            if (mapOfDocumentLogsByDocumentIds.containsKey(docLog.PC_Document__c)) {
                List<PC_Document_Log__c> docLogList = mapOfDocumentLogsByDocumentIds.get(docLog.PC_Document__c);
                docLogList.add(docLog);
                mapOfDocumentLogsByDocumentIds.put(docLog.PC_Document__c, docLogList);
            } else {
                mapOfDocumentLogsByDocumentIds.put(docLog.PC_Document__c, new List<PC_Document_Log__c>{ docLog });
            }
        }

        for (PC_Document__c doc : documentList) {
            if (String.isBlank(doc.PC_Applicant__c)) {
                doc.PC_Applicant__c = documentApplicantMap.get(doc.Id);
                listOfDocumentsToLinkApplicant.add(doc);
            } else {
                List<PC_Document_Log__c> docLogList = new List<PC_Document_Log__c>();
                docLogList = (mapOfDocumentLogsByDocumentIds.containsKey(doc.Id))? mapOfDocumentLogsByDocumentIds.get(doc.Id) : new List<PC_Document_Log__c>();
                system.debug('docLogList--->' + docLogList);
                if (docLogList.isEmpty()) {
                    doc.PC_Applicant__c = documentApplicantMap.get(doc.Id);
                    listOfDocumentsToLinkApplicant.add(doc);
                }
            }
        }
        if(listOfDocumentsToLinkApplicant.size() > 0) {
            PC_Database.upd(listOfDocumentsToLinkApplicant, false);
        }
        return listOfDocumentsToLinkApplicant;
    }*/

    private void sendNotification(List<PC_OcrQueue__c> updatedQueueList, Map<Id, List<PC_OcrResult__c>> mapOfOcrResultsByQueueIds) {
        List<CustomNotificationType> notificationTypes = new List<CustomNotificationType>();
        List<PC_OcrResult__c> ocrResults = new List<PC_OcrResult__c>();
        String notificationBody = PC_Constants.EMPTY_STRING;
        String notificationTargetId = PC_Constants.EMPTY_STRING;
        String notificationTargetPageRef = PC_Constants.EMPTY_STRING;
        String notificationTitle = PC_Constants.EMPTY_STRING;
        String namespace = 'c';
        try {
            // Get the Id for our custom notification type
            notificationTypes = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =: PC_Constants.PC_OCR_QUEUE_COMPLETION_NOTIFICATION_DEVELOPER_NAME];
            if (notificationTypes.size() > 0) {
                for (PC_OcrQueue__c queueRecord : updatedQueueList) {
                    if (queueRecord != null &&  queueRecord.PC_NotifyStatus__c && (queueRecord?.PC_Status__c == 'Completed' || queueRecord?.PC_Status__c == 'In Progress')){
                        notificationTitle = queueRecord.Name + ' - '+ System.Label.PC_ExtractionCompletedSuccessfully;
                        ocrResults = mapOfOcrResultsByQueueIds.get(queueRecord.Id);
                        if (ocrResults != null && ocrResults.size() == 1 && String.isNotBlank(ocrResults[0].PC_ResultingRecordId__c)) {
                            Id resultingRecordId = ocrResults[0].PC_ResultingRecordId__c;
                            Schema.SObjectType objType = resultingRecordId.getSobjectType();
                            String objectLabel = objType.getDescribe().getLabel();
                            namespace = (String.isNotBlank(PC_Constants.OrgNamespace)) ? PC_Constants.OrgNamespace : namespace;
                            notificationTargetPageRef = '{' +
                                                            '"type": "standard__component",' +
                                                            '"attributes": {' +
                                                                    '"componentName": "'+namespace+'__PC_OcrReviewDocument"' +
                                                                    '},' +
                                                            '"state":{' +
                                                                    '"'+namespace+'__recordId":"'+queueRecord.PC_SourceDocument__c+'", ' +
                                                                    '"'+namespace+'__templateCategories":"[]", ' +
                                                                    '"ws":"/lightning/r/'+namespace+'__PC_Document__c/'+queueRecord.PC_SourceDocument__c+'/view",' +
                                                                    '"'+namespace+'__launchFrom":"TRIGGER"' +
                                                                '}' +
                                                        '}';
                            notificationBody = String.format(System.Label.PC_OcrNotificationBody, new List<String>{ objectLabel });
                        } else if (ocrResults != null && ocrResults.size() > 1 && String.isNotBlank(ocrResults[0].PC_ResultingRecordId__c)) {
                            notificationBody = String.format(System.Label.PC_OpenProcessedDocumentMessage, new List<String>{queueRecord ?.PC_SourceDocument__r ?.Name});
                            notificationTargetId = queueRecord.PC_SourceDocument__c;
                        } else {
                            namespace = (String.isNotBlank(PC_Constants.OrgNamespace)) ? PC_Constants.OrgNamespace : namespace;
                            notificationTargetPageRef = '{' +
                                    '"type": "standard__component",' +
                                    '"attributes": {' +
                                    '"componentName": "'+namespace+'__PC_OcrReviewDocument"' +
                                    '},' +
                                    '"state":{' +
                                    '"'+namespace+'__recordId":"'+queueRecord.PC_SourceDocument__c+'", ' +
                                    '"'+namespace+'__templateCategories":"[]", ' +
                                    '"ws":"/lightning/r/'+namespace+'__PC_Document__c/'+queueRecord.PC_SourceDocument__c+'/view",' +
                                    '"'+namespace+'__launchFrom":"TRIGGER"' +
                                    '}' +
                                    '}';
                            notificationBody = System.Label.PC_DocumentReviewOCRNotificationMessage;
                        }
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        // Set the contents for the notification
                        notification.setTitle(notificationTitle);
                        notification.setBody(notificationBody);

                        // Set the notification type and target
                        notification.setNotificationTypeId(notificationTypes[0].Id);
                        if(String.isNotBlank(notificationTargetId)) {
                            notification.setTargetId(notificationTargetId);
                        } else {
                            notification.setTargetPageRef(notificationTargetPageRef);
                        }
                        Set<String> recipientsIds = new Set<String>();
                        recipientsIds.add(queueRecord.OwnerId);
                        // Actually send the notification
                        try {
                            notification.send(recipientsIds);
                        } catch (Exception e) {
                            System.debug('Problem sending notification: ' + e.getMessage());
                            PC_Utility.createExceptionLog(e);
                        }
                    }
                }
            } else {
                throw new PC_ProcessOcrResponseHandlerException(String.format(System.Label.PC_CustomNotificationTypeNotExist , new List<Object>{
                        PC_Constants.PC_OCR_QUEUE_COMPLETION_NOTIFICATION_DEVELOPER_NAME
                }));
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }

    private List<PC_OcrQueue__c> updateOcrQueueToError(Map<Id, PC_OcrQueue__c> ocrQueueMap) {
        List<PC_OcrQueue__c> ocrQueueList = new List<PC_OcrQueue__c>();
        for (String queueId : ocrQueueMap.keySet()) {
            PC_OcrQueue__c ocrQueueObj = new PC_OcrQueue__c();
            ocrQueueObj = ocrQueueMap.get(queueId);
            ocrQueueObj.PC_Status__c = 'Failed';
            ocrQueueObj.PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
            ocrQueueList.add(ocrQueueObj);
        }
        PC_Database.upd(ocrQueueList, false);
        return ocrQueueList;
    }

    private List<Task> createErrorTask(Map<Id, PC_OcrQueue__c> ocrQueueMap, String errorDescription) {
        List<Task> taskList = new List<Task>();
        for (String queueId : ocrQueueMap.keySet()) {
            Task t = new Task();
            t.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
            t.ActivityDate = system.today();
            t.Status = PC_Constants.PC_TASK_STATUS_WAITING;
            t.Priority = PC_Constants.PC_PRIORITY_HIGH;
            t.PC_Channel__c = PC_Constants.PC_TASK;
            t.Subject = System.label.PC_ClientSideErrorMessage;
            t.Description = errorDescription;
            t.OwnerId = ocrQueueMap.get(queueId)?.OwnerId;
            t.WhatId = queueId;
            taskList.add(t);
        }
        PC_Database.ins(taskList, false);
        return taskList;
    }

    public static List<PC_OcrResult__c> createOcrResultRecord(Map<Id, List<sObject>> ocrQueueToSobjectListMap, Map<Id, List<PC_OcrResult__c>> mapOfOcrResultsByQueueIds) {
        List<PC_OcrResult__c> ocrResults = new List<PC_OcrResult__c>();
        for (String queueId : ocrQueueToSobjectListMap.keySet()) {
            List<PC_OcrResult__c> tempOcrResults = new List<PC_OcrResult__c>();
            for (sObject sObj : ocrQueueToSobjectListMap.get(queueId)) {
                if (String.isNotBlank(sObj.Id)) {
                    PC_OcrResult__c ocrResult = new PC_OcrResult__c();
                    ocrResult.PC_ResultingRecordId__c = sObj.Id;
                    ocrResult.PC_ResultStatus__c = 'Success';
                    ocrResult.PC_OcrQueue__c = queueId;
                    //ocrResult.PC_OcrResponse__c = 'a2V2E000000bGwp';
                    tempOcrResults.add(ocrResult);
                } else {
                    PC_OcrResult__c ocrResult = new PC_OcrResult__c();
                    ocrResult.PC_ResultStatus__c = 'Error';
                    ocrResult.PC_ResultDetails__c = 'Something went wrong. Please contact your system administrator.';
                    ocrResult.PC_OcrQueue__c = queueId;
                    tempOcrResults.add(ocrResult);
                }
            }
            mapOfOcrResultsByQueueIds.put(queueId, tempOcrResults);
            ocrResults.addAll(tempOcrResults);
        }
        return ocrResults;
    }

    public static List<PC_OcrQueue__c> updateOcrQueueStatus(Map<Id, PC_OcrQueue__c> ocrQueueMap, Map<String, Boolean> ocrQueueStatusMap) {
        List<PC_OcrQueue__c> ocrQueueList = new List<PC_OcrQueue__c>();
        for (String queueId : ocrQueueMap.keySet()) {
            PC_OcrQueue__c ocrQueueObj = new PC_OcrQueue__c();
            ocrQueueObj = ocrQueueMap.get(queueId);
            ocrQueueObj.PC_Status__c = (ocrQueueStatusMap.get(queueId) == true) ? 'Completed' : 'Failed';
            ocrQueueObj.PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
            ocrQueueList.add(ocrQueueObj);
        }
        system.debug('ocrQueueMap.values()---->'+ocrQueueList);
        PC_Database.upd(ocrQueueList, false);
        return ocrQueueList;
    }

    public inherited sharing class PC_ProcessOcrResponseHandlerException extends Exception {}
}