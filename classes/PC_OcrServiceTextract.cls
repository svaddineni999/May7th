/*****************************************************************************************
Class Name    	: PC_OcrServiceTextract
Description     : AWS Textract Service Class.
Created By      : Deloitte
Created Date    : May 03, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 03, 2021           Initial Version
*********************************************************************************************/

public with sharing class PC_OcrServiceTextract extends PC_AWS implements PC_OCR.ExtractDocument {
    public static String OCR_SERVICE = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_PROVIDER, PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT);
    public static String secretAccessKey, secretAccessKeyApiName;

    /**
     * Post initialization logic (after constructor, before send)
     */
    public override void init() {
        //endpoint = new Url('https://textract.ap-south-1.amazonaws.com');
        //resource = '/';
        //region = 'ap-south-1';
        //service = 'textract';
        //accessKey = 'AKIA2DIHURRIZY74LGFZ';
        service = 'textract';
        region = PC_SYSTEM.getIntegrationSetting('PC_AwsRegion', PC_Constants.EMPTY_STRING);
        accessKey = PC_SYSTEM.getIntegrationSetting('PC_AwsAccessKeyID', PC_Constants.EMPTY_STRING);
        secretAccessKeyApiName = PC_SYSTEM.getIntegrationSetting('PC_AWSSecretAccessKeyProtectedApiName', PC_Constants.EMPTY_STRING);
        endpoint = new Url('https://' + service + '.' + region + '.amazonaws.com');
        resource = '/';
        method = HttpMethod.XPOST;

        if (Test.isRunningTest()) {
            region = 'ap-south-1';
            accessKey = 'AKIA2DIHUIIIZY74LGFZ'; // Invalid Access Key
            secretAccessKeyApiName = 'secretAccessKeyApiName';
        }
        if (String.isBlank(region)) {
            throw new PC_OCR.PC_OcrException(System.Label.PC_AWSRegionNotConfigured);
        }
        if (String.isBlank(accessKey)) {
            throw new PC_OCR.PC_OcrException(System.Label.PC_MissingAWSAccessKeyID);
        }
        if (String.isBlank(secretAccessKeyApiName)) {
            throw new PC_OCR.PC_OcrException(System.Label.PC_MissingAWSAccessKeyID);
        }

        setHeader('X-AMZ-Target', 'Textract.AnalyzeDocument');
        setHeader('Content-Type', 'application/x-amz-json-1.1');

        //	Remember to set "payload" here if you need to specify a body
        //payload = Blob.valueOf('{"Document": {"S3Object": {"Name": "pc.png","Bucket": "deloitte1ch1pc1vj1sample"}}}');

        secretAccessKey = PC_SYSTEM.getProtectedApiSetting(secretAccessKeyApiName);
        if (Test.isRunningTest()) {
            secretAccessKey = 'knr8UtE373M17MxLC3+FlKqOYrjhxo5dMFxx'; // Invalid Secret Access Key
        }
        if (String.isBlank(secretAccessKey)) {
            throw new PC_OCR.PC_OcrException(System.Label.PC_MissingAWSSecretAccessKeyAPIName);
        }
        // Create Signing Key
        createSigningKey(secretAccessKey);
    }


    /**
     * Send method will check whether it is a pdf or image file type and make the callout to AWS Service.
     * If image, it will Call Synchronous AWS Textract Rest API. If pdf, it will upload document to S3 bucket
     *
     * @param extractDocumentRequest PC_OCR.ExtractDocumentRequest having ocr Queue id and document Id.
     */
    public PC_OCR.ExtractDocumentResponse send(PC_OCR.ExtractDocumentRequest extractDocumentRequest) {
        PC_OCR.ExtractDocumentResponse extractDocumentResponse = new PC_OCR.ExtractDocumentResponse();
        try {
            system.debug('----Inside PC_OcrService_Textract----');
            String ocrQueueId = extractDocumentRequest.ocrQueueId;
            String documentContentId = getDocumentContentId(ocrQueueId);
            if (documentContentId == null) {
                throw new PC_OCR.PC_OcrException('Source Content Id is blank/ not valid');
            }

            String extension = PC_OcrSubmitter.getDocumentExtension(extractDocumentRequest.documentId);
            String timeStamp = String.valueOf(DateTime.now().getTime());
            String jobId = documentContentId + '-' + timeStamp;
            if (String.isNotBlank(extension) && extension.equalsIgnoreCase('pdf')) {
                // Async logic will come here
                String fileNameWithExtension = jobId + '.' + extension.toLowerCase();
                HttpRequest req = new HttpRequest();
                req.setMethod('PUT');
                String namedCredential = PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_AWS_S3_NAMED_CREDENTIAL_NAME, '');
                if (String.isBlank(namedCredential)) {
                    PC_LaunchOcrServiceHandler.PC_LaunchOcrServiceException ex = new PC_LaunchOcrServiceHandler.PC_LaunchOcrServiceException();
                    ex.setMessage(System.label.PC_MissingNamedCredentialsAWS);
                    throw ex;
                } else {
                    req.setEndpoint('callout:' + namedCredential + '/' + fileNameWithExtension);//Named Credentials
                }
                Blob pdfBlob = getDocumentAsBlob(documentContentId);
                req.setBodyAsBlob(pdfBlob);

                Http http = new Http();
                HTTPResponse response = http.send(req);
                system.debug(response);
                String ocrResponseStatus = PC_Constants.EMPTY_STRING, ocrAdditionalInfo;
                extractDocumentResponse.jobId = jobId;
                if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    ocrResponseStatus = PC_Constants.PC_OCR_RESPONSE_STATUS_ENQUEUE;
                    system.debug(response.getStatusCode());
                    system.debug(response.getStatus());
                    system.debug(response.getBody());
                } else {
                    ocrResponseStatus = PC_Constants.PC_OCR_STATUS_ERROR;
                    ocrAdditionalInfo = response.getBody();
                    system.debug(response.getStatusCode());
                    system.debug(response.getStatus());
                    system.debug(response.getBody());
                }
                extractDocumentResponse.ocrResponse = createOcrResponse(extractDocumentRequest.ocrQueueId, ocrResponseStatus, ocrAdditionalInfo, jobId);
                extractDocumentResponse.remoteServiceLog = createRemoteServiceLog(documentContentId, response);
                extractDocumentResponse.httpResponse = response;
            } else {
                String documentBody = PC_Constants.EMPTY_STRING;
                Blob fileContent = getDocumentAsBlob(documentContentId);
                if (fileContent != null && fileContent.size() > 0) {
                    documentBody = EncodingUtil.base64Encode(fileContent);
                }
                String textractPayload = '{"Document":{"Bytes":"' + documentBody + '"},"FeatureTypes": ["FORMS"]}';
                String textractPayloadForLog = '{"Document":{"Bytes":"Blob(recordId:' + documentContentId + ')"},"FeatureTypes": ["FORMS"]}';
                payload = Blob.valueOf(textractPayload);

                HttpRequest request = generateHttpRequest();
                HttpResponse response = sendRequest(request);
                String ocrResponseStatus = PC_Constants.EMPTY_STRING, ocrAdditionalInfo;
                extractDocumentResponse.jobId = jobId;
                if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    ocrResponseStatus = PC_Constants.PC_OCR_RESPONSE_STATUS_ENQUEUE;
                    system.debug('Success');
                    system.debug(response.getStatusCode());
                    system.debug(response.getStatus());
                    system.debug(response.getBody());
                } else {
                    ocrResponseStatus = PC_Constants.PC_OCR_STATUS_ERROR;
                    ocrAdditionalInfo = response.getBody();
                    system.debug('Error');
                    system.debug(response.getStatusCode());
                    system.debug(response.getStatus());
                    system.debug(response.getBody());
                }
                extractDocumentResponse.ocrResponse = createOcrResponse(extractDocumentRequest.ocrQueueId, ocrResponseStatus, ocrAdditionalInfo, jobId);
                extractDocumentResponse.remoteServiceLog = createRemoteServiceLog(textractPayloadForLog, response);
                extractDocumentResponse.httpResponse = response;
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return extractDocumentResponse;
    }

    /**
     * Method used to create remote service log object
     * @param rslPayload Request Payload
     * @param response HttpResponse for the callout
     */
    public PC_Remote_Service_Log__c createRemoteServiceLog(String rslPayload, HttpResponse response) {
        PC_Remote_Service_Log__c rslObj = new PC_Remote_Service_Log__c();
        rslObj.PC_Running_User__c = UserInfo.getUserId();
        rslObj.PC_Callback_Request__c = rslPayload;
        rslObj.PC_Callback_Response__c = '[' + response.getBody() + ']';
        rslObj.PC_Service_Name__c = OCR_SERVICE;
        rslObj.PC_Service_Type__c = PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND;
        rslObj.PC_StatusCode__c = String.valueOf(response.getStatusCode());
        return rslObj;
    }

    /**
     * Method used to create OCR Response object
     * @param ocrQueueId Id of the Ocr Queue record
     * @param callOutStatus Status of the callout
     * @param ocrAdditionalInfo used to store additional information like error message
     * @param jobId jobId for the HTTP callout
     */
    public PC_OcrResponse__c createOcrResponse(String ocrQueueId, String callOutStatus, String ocrAdditionalInfo, String jobId) {
        PC_OcrResponse__c ocrResponseObj = new PC_OcrResponse__c();
        ocrResponseObj.PC_OcrQueue__c = ocrQueueId;
        ocrResponseObj.PC_OcrService__c = OCR_SERVICE;
        ocrResponseObj.PC_OcrStatus__c = callOutStatus;
        ocrResponseObj.PC_OcrServiceResponseId__c = jobId;
        ocrResponseObj.PC_AdditionalInformation__c = ocrAdditionalInfo;
        return ocrResponseObj;
    }

    /**
     * Method used to get Content Id (contentDocument Id or attachment Id) of the document.
     * @param ocrQueueId Id of the Ocr Queue record
     */
    private String getDocumentContentId(String ocrQueueId) {
        //FLS Check
        List<String> ocrQueueFields = new List<String>{'Id', 'PC_SourceContentId__c', 'PC_SourceDocument__c', 'PC_Status__c'};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrQueue__c'), PC_Database.Operation.Reading, ocrQueueFields);
        return [Select Id, PC_SourceContentId__c, PC_SourceDocument__c, PC_Status__c from PC_OcrQueue__c WHERE Id = :ocrQueueId and PC_Status__c = 'Queued'] ?.PC_SourceContentId__c;
    }

    /**
    * Method returns the blob data of the document based on content Id(contentDocument Id or attachment Id)
    * @param contentId Content Id of the document
    */
    public Blob getDocumentAsBlob(String contentId) {
        Blob fileContent;
        Schema.SObjectType sObjType = ((Id) contentId).getSobjectType();
        if (sObjType == Schema.ContentVersion.SObjectType) {
            //FLS Check
            List<String> cvFields = new List<String>{ 'Id', 'VersionData', 'FileExtension', 'ContentDocumentId' };
            PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, cvFields);
            fileContent = [SELECT Id, VersionData,ContentDocumentId,FileExtension FROM ContentVersion WHERE Id = :contentId] ?.versionData;
        } else {
            //FLS Check
            List<String> attachmentFields = new List<String>{'Id', 'Body'};
            PC_Database.assertAccess('Attachment', PC_Database.Operation.Reading, attachmentFields);
            fileContent = [SELECT Id, Body FROM Attachment WHERE Id = :contentId] ?.Body;
        }
        return fileContent;
    }

    /**
    * Method used to get the operation type of the callout. Whether the callout is SYNCHRONOUS or ASYNCHRONOUS.
    * @param extractDocumentRequest PC_OCR.ExtractDocumentRequest having ocr Queue id and document Id.
    */
    public PC_OCR.OperationType getOperationType(PC_OCR.ExtractDocumentRequest extractDocumentRequest) {
        String extension = PC_OcrSubmitter.getDocumentExtension(extractDocumentRequest.documentId);
        if (String.isNotBlank(extension) && extension.equalsIgnoreCase('pdf')) {
            return PC_OCR.OperationType.ASYNCHRONOUS;
        } else {
            return PC_OCR.OperationType.SYNCHRONOUS;
        }
    }

    /**
    * Method used to get the supported file types for OCR Service
    */
    public List<String> getSupportedFileTypes() {
        List<String> supportedFileTypes = new List<String>();
        supportedFileTypes.add(PC_OCR.FileType.JPG.name().toLowerCase());
        supportedFileTypes.add(PC_OCR.FileType.JPEG.name().toLowerCase());
        supportedFileTypes.add(PC_OCR.FileType.PNG.name().toLowerCase());
        supportedFileTypes.add(PC_OCR.FileType.PDF.name().toLowerCase());
        return supportedFileTypes;
    }
}