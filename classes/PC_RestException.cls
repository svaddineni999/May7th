/*********************************************************************************************************
Class Name    	: PC_RestException
Description     : Custom REST exception class 
Created By      : Deloitte
Created Date    : Jul 27, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Vijay Kashikar         		   Jul 27, 2017           Initial Version
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
****************************************************************************************************************/
public inherited sharing class PC_RestException extends Exception {
    public String errorCode;
    public String errorType;
    
    public PC_RestException(String errorCode, String errorType, String errorMessage) {
        this.errorCode = errorCode;
        this.errorType = errorType;
        setMessage(errorMessage);

        /*Map<String, String> message = new Map<String, String>();
        message.put('errorCode', errorCode);
        message.put('errorType', errorType);
        message.put('message', errorMessage);
        setMessage(JSON.serialize(message));*/
    }
    public PC_RestException(String errorCode, String errorType, String errorMessage, String errorLogRef) {
        Map<String, String> message = new Map<String, String>();
        message.put('errorCode', errorCode);
        message.put('errorType', errorType);
        message.put('message', errorMessage);
        message.put('errorLogRef', errorLogRef);
        setMessage(JSON.serialize(message));
    }

    public static string getExceptionMessage (PC_RestAPIConstants.ErrorCode errorCode, PC_RestAPIConstants.ErrorType errorType, String errorMessage, String errorLogRef) {
        PC_RestException restException = new PC_RestException(String.valueOf(errorCode), String.valueOf(errorType), errorMessage, errorLogRef);
        return restException.getMessage();
    }
    public static string getExceptionMessage (String errorCode, String errorType, String errorMessage, String errorLogRef) {
        PC_RestException restException = new PC_RestException(errorCode, errorType, errorMessage, errorLogRef);
        return restException.getMessage();
    }
}