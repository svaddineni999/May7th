/*********************************************************************************************************
Class Name      : PC_EngagementProgramSettingsService
Description     : REST class to fetch settings configured for Engagement Program
Created By      : Haritha Reddy
Created Date    : Jun 10, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy                 Jun 14, 2021         [PC-7388] Initial Version
****************************************************************************************************************/
/**
 * REST API class to retrieve settings configured for Engagement Program
 */
@RestResource (urlMapping = '/1.0/engagementProgramSettings/*' )
global with sharing class PC_EngagementProgramSettingsService {

    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<string, string> reqParams = req.params;
        try {
            if(!reqParams.isEmpty()) {
                List<sObject> selfServiceSettingList = PC_RestAPIUtilities.getSelfServiceSettings(reqParams);
                getGETResponse(null, selfServiceSettingList);
            } else {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_QUERY_PARAMS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_QUERY_PARAMETERS_MISSING);
            }
        } catch(Exception e) {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    private static void getGETResponse(string getIdentifier, List<sObject> selfServiceSettingList) {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> selfServiceSettingsMap = PC_RestAPIUtilities.transformSobject(selfServiceSettingList, PC_RestAPIConstants.REST_OBJECT_NAME_SELF_SERVICE_SETTING);
        res.responseBody = Blob.valueOf(JSON.serialize(selfServiceSettingsMap));
    }
}