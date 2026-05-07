@RestResource (urlMapping = '/1.0/ocr/*' )
global class PC_OcrService {
	public static String OCR_SERVICE = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_PROVIDER, PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT);
    
    @HttpPost
    global static void doPost()
    {
        processOcrResponse();
    }
    
    private static void processOcrResponse()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');     
         system.debug('req.requestBody--->'+req.requestBody);
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        system.debug('req.requestBody--->'+reqString);
        
        //Savepoint sp = Database.setSavepoint();
        Map<string, object> ocrInfo;

        List<String> recordsIds = new List<String>();
        String fileName, jobId, ocrResponseId, ocrQueueId, ocrResponse;
        PC_OcrResponse__c ocrResponseObj;
        try
        {
            // Convert request info as Map
            ocrInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            system.debug('ocrInfo---'+ocrInfo.get('jobId'));
            fileName = String.valueOf(ocrInfo.get('jobId'));
            jobId = fileName.substringBeforeLast('.');
            ocrResponse = String.valueOf(ocrInfo.get('response'));
            system.debug('ocrResponse---'+ocrResponse);
            
            //Create Remote Service Log for Inbound request
        	PC_Remote_Service_Log__c rslRecord = PC_RemoteServiceLogHandler.createRemoteServiceLog(OCR_SERVICE, '/1.0/ocr', OCR_SERVICE + ' Response', '', '', PC_Constants.REMOTE_SERVICE_TYPE_INBOUND);
            recordsIds.add(rslRecord.Id);
            system.debug('rslRecord.Id--->'+rslRecord.Id);
            
            //Get OCR Response record using jobId
            
            if(String.isNotBlank(jobId)){
                createResponseFileAndShareRecords(jobId, ocrResponse, recordsIds);
            } else {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'jobId parameter value is missing');
            }
            
            Map<string, String> responseMap = new Map<string, String>();
            responseMap.put('id', rslRecord.Id);
            res.responseBody = Blob.valueOf(JSON.serialize(responseMap));
        }
        catch(Exception e)
        {
            system.debug('Exception----'+e.getStackTraceString());
            //Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
    
    @future(callout=true)
    public static void createResponseFileAndShareRecords(String jobId, String ocrResponse, List<Id> recordsIds) {
        PC_OcrResponse__c ocrResponseObj;
        String ocrQueueId;
        try {
            ocrResponseObj = getOcrResponseByJobId(jobId);
            ocrQueueId = ocrResponseObj.PC_OcrQueue__c;
            recordsIds.add(ocrResponseObj.Id);
            
            ContentVersion cv = PC_LaunchOcrServiceHandler.createResponseJsonFile(ocrQueueId, ocrResponse);
            PC_LaunchOcrServiceHandler.shareFileToRecords(cv.Id, recordsIds);
            if (ocrResponseObj != null && cv.id != null) {
                ocrResponseObj.PC_OcrStatus__c = PC_Constants.PC_OCR_STATUS_SUCCESS;
                PC_Database.upd(ocrResponseObj);
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
            PC_LaunchOcrServiceHandler.createErrorTask(ocrQueueId, ex.getMessage());
            // Update OCR Queue
            List<PC_OcrQueue__c> ocrQueueList = [Select Id, PC_Status__c FROM PC_OcrQueue__c WHERE Id = :ocrQueueId LIMIT 1];
            if(ocrQueueList.size() > 0) {
                PC_OcrQueue__c ocrQueue = ocrQueueList[0];
                ocrQueue.PC_Status__c = 'Failed';
                ocrQueue.PC_IsActive__c = PC_Constants.FALSE_BOOLEAN;
                PC_Database.upd(ocrQueue);
            }
            
            // Update OCR Response
            if(ocrResponseObj != null){
                ocrResponseObj.PC_OcrStatus__c = PC_Constants.PC_OCR_STATUS_ERROR;
                ocrResponseObj.PC_AdditionalInformation__c = ex.getMessage();
                PC_Database.upd(ocrResponseObj);
            }
        }
    }
    
    private static PC_OcrResponse__c getOcrResponseByJobId(String JobId){
        return [SELECT Id, PC_OcrQueue__c, PC_OcrService__c, PC_OcrStatus__c, PC_OcrServiceResponseId__c from PC_OcrResponse__c where PC_OcrServiceResponseId__c =:JobId LIMIT 1];
    }
}