/*********************************************************************************************************
Class Name      : PC_RemoteServiceLogHandler
Description     :
Created By      : Vijay Kashikar
Created Date    : July 05, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar          July 05, 2018              Initial Version
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy           21-Jan-2021           [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Chetna Mohapatra        20-Apr-2021           [PC-7534] Code for handling Twilio's Callback Request.
Chetna Mohapatra        21-Apr-2021           Modified the code for handling CMM'S Callback.
Chetna Mohapatra        05-May-2021           [PC-7721] Service Type value population when creating Remote service log records.
Chetna Mohapatra        11-May-2021           [PC-7686] Made the Twilio token configurable as the callback query parameter and added a separate variable as Service name.
Chetna Mohapatra        10-Jun-2021           [PC-7732] Added a method getRemoteServiceLog() to return an instance of Remote Service Log record.
*********************************************************************************************************/
/**
 * REST API class to create Remote Service Logs.
 */
@RestResource (urlMapping = '/1.0/RemoteServiceLog/*' )
global with sharing class PC_RemoteServiceLogHandler {
    //global enum ObjectOperation {oUPDATE, oINSERT};
    private static final String serviceNameKey = 'name';
    public static final String cmmServiceName = PC_Constants.CMM;
    public static final String infinitusServiceName = PC_Constants.INFINITUS;
    public static final String twilioServiceName= PC_Constants.PC_TWILIO;
    public static String twilioTokenParameter= PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_TWILIO_TOKEN_PARAMETER, '');
    @HttpPost
    global static void doPost() {
        processUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    private static void processUpsert(PC_RestAPIConstants.ObjectOperation operation) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try {
            res.statusCode = 501;
            res.addHeader('Content-Type', 'application/json;charset=UTF-8');
            Blob reqBlob = req.requestBody;
            string reqString = PC_Constants.EMPTY_STRING;
            if(reqBlob != null)
            {
                reqString = reqBlob.toString();
            }
            Map<string, string> parameters = req.params;
            String requestURL = getRequestURL(req);

            if(parameters.containsKey(serviceNameKey) && parameters.get(serviceNameKey) == cmmServiceName) {
                // all good
                PC_PriorAuthClient_CMM.handleCMMRequest(reqString, requestURL, cmmServiceName);
                res.statusCode = 201;
            } else if(parameters.containsKey(serviceNameKey) && parameters.get(serviceNameKey) == twilioTokenParameter){
                PC_TwilioSMSService.handleTwilioRequest(reqString, requestURL, twilioServiceName);
                res.statusCode = 200;
                res.responseBody= Blob.valueOf('ok');
            } else if(parameters.containsKey(serviceNameKey) && parameters.get(serviceNameKey) == infinitusServiceName){
                System.debug('Infinitus Callback Request--' +reqString+'URL-- '+requestURL);
                res.statusCode = 200;
                res.responseBody= Blob.valueOf('ok');
                PC_Infinitus.handleInfinitusCallback(reqString, requestURL, infinitusServiceName);
            } else {
                PC_Error_Log__c errorLog = createErrorLog('Incorrect or missing service name and token in the request URL. Hence aborting the callback...', req.requestBody.toString(), req.requestURI);
                res.responseBody = Blob.valueOf('ERROR. "name" key missing ->' + JSON.serialize(errorLog.Id));
            }
        }
        catch(Exception ex) {
            res.statusCode = 501;
            PC_Error_Log__c errorLog = createErrorLog(ex.getMessage(), ex.getStackTraceString(), req.requestURI + '\\n' + req.requestBody.toString());
            res.responseBody = Blob.valueOf('ERROR ->' + JSON.serialize(errorLog.Id));
        }
    }

    public static void publishErrorLog(String additionalInfo) {
        PC_Error_Log_Info__e errLog = new PC_Error_Log_Info__e(
                PC_Error_DateTime__c = DateTime.Now(),
                PC_Error_Message__c = PC_Constants.EMPTY_STRING,
                PC_Running_User__c = UserInfo.getUserId(),
                PC_Stack_Trace__c = PC_Constants.EMPTY_STRING,
                PC_Additional_Information__c = additionalInfo
        );
        Database.SaveResult result = EventBus.publish(errLog);
        if(result != null && result.isSuccess()) {
            // published successfully
            system.debug('Error log info published successfully');
        }
        else {
            // critical error.
            system.debug('Critical Error. Error log info publish failed');
        }
    }
    public static void publishRemoteServiceLogInfo(PC_Remote_Service_Log__c log) {
        PC_Remote_Service_Log_Info__e logInfo = new PC_Remote_Service_Log_Info__e(
                PC_Additional_Information__c = log.PC_Additional_Information__c,
                PC_Callback_Request__c = log.PC_Callback_Request__c,
                PC_Callback_Response__c = log.PC_Callback_Response__c,
                PC_Callback_URL2__c = log.PC_Callback_URL2__c,
                PC_Service_Name__c = log.PC_Service_Name__c,
                PC_Running_User__c = UserInfo.getUserId()
        );
        Database.SaveResult result = EventBus.publish(logInfo);
        if(result != null && result.isSuccess()) {
            // published successfully
            system.debug('PC_Remote_Service_Log_Info__e log info published successfully');
        }
        else {
            // critical error.
            system.debug('Critical Error. PC_Remote_Service_Log_Info__e info publish failed');
        }
    }

    private static PC_Error_Log__c createErrorLog(String errorMessage, String stackTrace, String additionalInfo) {
        PC_Error_Log__c errLog = new PC_Error_Log__c(PC_Error_Datetime__c = DateTime.Now(),
                PC_Error_Message__c = errorMessage,
                PC_Running_User__c = UserInfo.getUserId(),
                PC_Stack_Trace__c = stackTrace,
                PC_Additional_Information__c = additionalInfo);
        if(errlog != null){
            insert errlog;
        }
        return errLog;
    }

    public static PC_Remote_Service_Log__c createRemoteServiceLog(String serviceName, String callbackURL, String request, String response, String additionalInfo, String serviceType) {
       system.debug(serviceName);
       system.debug(callbackURL);
       system.debug(response);
       system.debug(additionalInfo);

        PC_Remote_Service_Log__c record = new PC_Remote_Service_Log__c(
                PC_Running_User__c = UserInfo.getUserId(),
                PC_Additional_Information__c = additionalInfo,
                PC_Callback_URL2__c = callbackURL,
                PC_Callback_Request__c = request,
                PC_Callback_Response__c = response,
                PC_Service_Name__c = serviceName,
                PC_Service_Type__c= serviceType
        );
        if(record != null){
            PC_Database.ins(record,true);
        }
        return record;
    }
    /**
     * This method returns an instance of Remote service log record without inserting it.
     */
    public static PC_Remote_Service_Log__c getRemoteServiceLog(String serviceName, String callbackURL, String request, String response, String additionalInfo, String serviceType) {

        PC_Remote_Service_Log__c record = new PC_Remote_Service_Log__c(
                PC_Running_User__c = UserInfo.getUserId(),
                PC_Additional_Information__c = additionalInfo,
                PC_Callback_URL2__c = callbackURL,
                PC_Callback_Request__c = request,
                PC_Callback_Response__c = response,
                PC_Service_Name__c = serviceName,
                PC_Service_Type__c= serviceType
        );
        return record;
    }

    private static string getRequestURL(RestRequest req)
    {
        string requestURL = PC_Constants.EMPTY_STRING;
        string queryString = PC_Constants.EMPTY_STRING;
        Map<string, string> parameters = req.params;
        for(string key: parameters.keySet())
        {
            system.debug('key = ' + key);
            if(string.isBlank(queryString))
            {
                queryString = queryString + '/?' + key + PC_Constants.PC_EQUALS_SYMBOL + parameters.get(key);
            }
            else
            {
                queryString = queryString + '&' + key + PC_Constants.PC_EQUALS_SYMBOL + parameters.get(key);
            }
        }
        requestURL = req.requestURI + queryString;
        return requestURL;
    }
}