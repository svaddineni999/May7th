/***********************************************************************************************************************
Class Name      : PC_LaunchOcrServiceHandler
Description     : Enqueue Document for OCR Process.
Created By      : Satheesh Kumar
Created Date    : Apr 30, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar			 Apr 30, 2020			  Initial version
Satheesh Kumar           Nov 16, 2021             [PC-8213] Excluded FLS Check and added inherited sharing
*************************************************************************************************************************/

public inherited sharing class PC_LaunchOcrServiceHandler extends PC_TriggerHandler {
    override public void afterInsert() {
        launchOcrProcess((List<PC_OcrQueue__c>) newList);
    }

    private void launchOcrProcess(List<PC_OcrQueue__c> newList) {
        system.debug('newList--->'+newList);
        try {
            String ocrService = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_PROVIDER, PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT);
            if(Test.isRunningTest()) {
                ocrService = PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT;
            }
            if (String.isNotBlank(ocrService)) {
                try {
                    if (ocrService.equalsIgnoreCase(PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT)) {
                        for (PC_OcrQueue__c ocrQueue : newList) {
                            if (ocrQueue.PC_Status__c == PC_Constants.PC_OCR_STATUS_QUEUED && ocrQueue.PC_IsActive__c && String.isNotBlank(ocrQueue.PC_SourceContentId__c)) {
                                callOcrService(ocrQueue.Id, ocrQueue.PC_SourceDocument__c);
                            }
                        }
                    } else {
                        throw new PC_LaunchOcrServiceException(String.format('Configured {0} Service is not valid. Please contact your system administrator', new List<Object>{ocrService}));   // Log exception: Info.
                    }
                } catch (PC_LaunchOcrServiceException ex) {
                    PC_Utility.createExceptionLog(ex);
                }
            } else {
                //Throw error when OCR service is not configured
                PC_LaunchOcrServiceException ocrServiceException = new PC_LaunchOcrServiceException();
                ocrServiceException.setMessage(System.label.PC_OcrServiceNotConfigured);
                throw ocrServiceException;
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    @future(callout=true)
    public static void callOcrService(String ocrQueueId, String documentId) {
        try {
            PC_OCR.ExtractDocument handler = PC_OCR.getExtractService(PC_Constants.PC_DEFAULT_TEXTRACT_OCRSERVICE_CLASSNAME);
            PC_OCR.ExtractDocumentRequest request = new PC_OCR.ExtractDocumentRequest();
            request.ocrQueueId = ocrQueueId;
            request.documentId = documentId;
            // Call OCR Service
            PC_OCR.ExtractDocumentResponse response = handler.send(request);
            // Get OCR Operation Type
            PC_OCR.OperationType operationType = handler.getOperationType(request);
            if(String.isNotBlank(response.jobId)){
                // Handle Response
                handlerOcrResponse(ocrQueueId, response, operationType);
            } else {
                throw new PC_LaunchOcrServiceException('JobId is blank in the response. It is mandatory to process OCR.');
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
            createErrorTask(ocrQueueId, ex.getMessage());
            //Update OCR Queue Status to Failed
            PC_OcrQueue__c ocrQueue = [Select Id, PC_Status__c FROM PC_OcrQueue__c WHERE Id = :ocrQueueId LIMIT 1];
            ocrQueue.PC_Status__c = 'Failed';
            ocrQueue.PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
            PC_Database.upd(ocrQueue, false);
        }
    }

    public static ContentVersion createResponseJsonFile(String ocrQueueId, String responseString) {
        ContentVersion contentVersion = new ContentVersion();
        try {
            contentVersion.Title = ocrQueueId + '_ResponseJson.txt';
            contentVersion.PathOnClient = ocrQueueId + '_ResponseJson.txt';
            contentVersion.VersionData = Blob.valueOf(responseString);
            PC_Database.ins(contentVersion, false);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return contentVersion;
    }

    public static List<ContentDocumentLink> shareFileToRecords(String contentVersionId, List<String> recordsIds) {
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        try {
            String contentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId] ?.ContentDocumentId;
            for (String recordId : recordsIds) {
                ContentDocumentLink contentDocLink = new ContentDocumentLink();
                contentDocLink.ContentDocumentId = contentDocumentId;
                contentDocLink.LinkedEntityId = recordId;
                contentDocLink.ShareType = PC_Constants.PC_FILE_SHARE_TYPE_VIEWER;
                contentDocumentLinkList.add(contentDocLink);
            }
            PC_Database.ins(contentDocumentLinkList, false);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return contentDocumentLinkList;
    }

    public static Task createErrorTask(String whatId, String errorDescription) {
        Task t = new Task();
        t.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
        t.ActivityDate = system.today();
        t.Status = PC_Constants.PC_TASK_STATUS_WAITING;
        t.Priority = PC_Constants.PC_PRIORITY_HIGH;
        t.PC_Channel__c = PC_Constants.PC_TASK;
        t.Subject = System.label.PC_ClientSideErrorMessage;
        t.Description = errorDescription;
        t.OwnerId = UserInfo.getUserId();
        if (String.isNotEmpty(whatId)) {
            t.WhatId = whatId;
        }
        PC_Database.ins(t, false);
        return t;
    }

    public static void handlerOcrResponse(String ocrQueueId, PC_OCR.ExtractDocumentResponse response, PC_OCR.OperationType operationType){
        Boolean isLongResponse = false;
        PC_OcrResponse__c ocrResObj = new PC_OcrResponse__c();
        List<String> recordsIds = new List<String>();
        String responseString = PC_Constants.EMPTY_STRING;
        if (response.remoteServiceLog != null) {
            responseString = response.remoteServiceLog.PC_Callback_Response__c;
            if (String.isNotBlank(responseString) && responseString.length() > 131072) {
                response.remoteServiceLog.PC_Callback_Response__c = PC_Constants.EMPTY_STRING;
                isLongResponse = true;
            }
            // Create Remote Service Log Record
            PC_Remote_Service_Log__c rsLog = (PC_Remote_Service_Log__c) PC_Database.ins(response.remoteServiceLog, false);
            recordsIds.add(rsLog.Id);
        }
        if (response.ocrResponse != null) {
            ocrResObj = (PC_OcrResponse__c) PC_Database.ins(response.ocrResponse, false);
            recordsIds.add(ocrResObj.Id);
        }

        if (response.httpResponse.getStatusCode() == 200 || response.httpResponse.getStatusCode() == 201) {
            //Update OCR Queue Status to In Progress
            PC_OcrQueue__c ocrQueue = [Select Id, PC_Status__c FROM PC_OcrQueue__c WHERE Id = :ocrQueueId LIMIT 1];
            ocrQueue.PC_Status__c = 'In Progress';
            PC_Database.upd(ocrQueue, false);

            //Share Response with OCR Response record and update OCR Response status to 'Success'
            if (operationType == PC_OCR.OperationType.SYNCHRONOUS) {
                ContentVersion cv = createResponseJsonFile(ocrQueueId, responseString);
                shareFileToRecords(cv.Id, recordsIds);
                if (ocrResObj != null) {
                    ocrResObj.PC_OcrStatus__c = PC_Constants.PC_OCR_STATUS_SUCCESS;
                    PC_Database.upd(ocrResObj, false);
                }
            }
        } else {
            createErrorTask(ocrQueueId, response.httpResponse.getBody());
            //Update OCR Queue Status to In Progress
            PC_OcrQueue__c ocrQueue = [Select Id, PC_Status__c FROM PC_OcrQueue__c WHERE Id = :ocrQueueId LIMIT 1];
            ocrQueue.PC_Status__c = 'Failed';
            ocrQueue.PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
            PC_Database.upd(ocrQueue, false);
        }
    }

    public inherited sharing class PC_LaunchOcrServiceException extends Exception {}
}