/**
 * Created by sathekumar on 4/30/2021.
 */

public with sharing class PC_OCR {
    public enum OperationType { ASYNCHRONOUS, SYNCHRONOUS }
    public enum FileType { JPG, JPEG, PNG, PDF }
    public interface ExtractDocument {
        ExtractDocumentResponse send(ExtractDocumentRequest request);
        OperationType getOperationType(ExtractDocumentRequest request);
        List<String> getSupportedFileTypes();
        // TODO : void updateResults(List<Id> resultRecords, ExtractDocumentRequest request, ExtractDocumentResponse response);
    }

    public interface ResponseParser {
        Map<String, String> getFormData(String response);
    }

    public inherited sharing class ExtractDocumentRequest {
        public String ocrQueueId;
        public String documentId;
        public String fileExtension;
        public ExtractDocumentRequest() {
            this.ocrQueueId = PC_Constants.EMPTY_STRING;
        }
    }

    public inherited sharing class ExtractDocumentResponse {
        public String jobId;
        public HttpResponse httpResponse;
        public PC_Remote_Service_Log__c remoteServiceLog;
        public PC_OcrResponse__c ocrResponse;   
        public ExtractDocumentResponse() {
            this.jobId = PC_Constants.EMPTY_STRING;
            this.remoteServiceLog = new PC_Remote_Service_Log__c();
            this.ocrResponse = new PC_OcrResponse__c();
        }
    }

    public static ExtractDocument getExtractService(String defaultServiceClassName) {
        String handlerClass = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_CLASSNAME, defaultServiceClassName);
        Type t = Type.forName(handlerClass);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof ExtractDocument) {
                ExtractDocument handler = (ExtractDocument) o;
                return handler;
            } else {
                throw new PC_OcrException(System.label.PC_OcrImplementationClassInvalid);
            }
        }
        else {
            throw new PC_OcrException(System.label.PC_OcrServiceClassNotFound);
        }
    }

    /*
    public static ResponseParser getResponseParserClass(String defaultParserClassName) {
        String handlerClass = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_RESPONSE_PARSER_CLASSNAME, defaultParserClassName);
        Type t = Type.forName(handlerClass);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof ResponseParser) {
                ResponseParser handler = (ResponseParser) o;
                return handler;
            } else {
                throw new PC_OcrException(System.label.PC_OcrResponseParserInvalid);
            }
        }
        else {
            throw new PC_OcrException(System.label.PC_OcrResponseParserClassNotFound);
        }
    }
    */

    public class PC_OcrException extends Exception {}
}