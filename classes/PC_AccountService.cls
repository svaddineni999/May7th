/************************************************************************************************************************************
Class Name      : PC_AccountService
Description     : REST class for Account object
Created By      : Deloitte
Created Date    : Jun 08, 2021
Modification Log:
---------------------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
---------------------------------------------------------------------------------------------------------------------------------------
Haritha Reddy                 Jun 08, 2021           [PC-7683] Initial Version
******************************************************************************************************************************************/
/**
 * REST API class to retrieve Accounts. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/account/*' )
global with sharing class PC_AccountService {
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<string, string> reqParams = req.params;
        try
        {
            Boolean hasPatientClass = reqParams.containsKey(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
            String patientClassValue;
            if(hasPatientClass){
                patientClassValue = reqParams.get(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
                reqParams.remove(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
            }
            // filter Accounts based on query parameters
            List<Account> accountList = PC_RestAPIUtilities.getAccounts(reqParams,hasPatientClass,patientClassValue);
            getGETResponse(null, accountList);
        } catch(Exception e) {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }

    private static void getGETResponse(string getIdentifier, List<Account> listAccounts) {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> accountMap = PC_RestAPIUtilities.transformSobjectAccounts(listAccounts, PC_RestAPIConstants.REST_OBJECT_NAME_ACCOUNT);
        res.responseBody = Blob.valueOf(JSON.serialize(accountMap));
    }
}