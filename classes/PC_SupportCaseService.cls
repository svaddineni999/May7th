/*********************************************************************************************************
Class Name      : PC_SupportCase
Description     : REST class for Support Case(Case) object
Created By      : Deloitte
Created Date    : Aug 08, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Aug 08, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
****************************************************************************************************************/
/**
 * REST API class to retrieve, create support cases. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/supportCase/*' )
global with sharing class PC_SupportCaseService
{
    static final string SUPPORT_CASE_KEY = 'supportCase';
    static final string GET_PARAM_FIND_BY_PROGRAM_ID = 'findByProgramId';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string reqString = req.requestURI;
        reqString = reqString.toLowerCase();
        string programId = null;
        List<Case> supportCases;
        try
        {
            if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_PROGRAM_ID))
            {
                // Search by Program Id
                programId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                if(string.isNotBlank(programId))
                {
                    programId = string.escapeSingleQuotes(programId);
                    supportCases = PC_RestAPIUtilities.getCasesByProgramId(programId);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PROGRAM_FINDBYPROGRAMID_MISSING);
                }
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.INVALID_PARAMETERS);
            }
            getGETResponse(null, supportCases);
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    @HttpPost
    global static void doPost()
    {
        processSupportCaseUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    private static void processSupportCaseUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> supportCaseInfo;
        Savepoint sp = Database.setSavepoint();
        try
        {
            // Convert request info as Map
            supportCaseInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            Map<string, object> reqSupportCase = (Map<string, object>)supportCaseInfo;
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqSupportCase = PC_RestAPIUtilities.removeIdField(reqSupportCase);
            }
            // Get Rest object mapping from custom metadata
            Map<string, object> reqSupportCaseTrans = PC_RestAPIUtilities.transformRESTObject(reqSupportCase, PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
            // Create sObjects
            string supportCaseId = PC_RestAPIUtilities.upsertSupportCase(reqSupportCaseTrans, operation);
            // Create responseBody
            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(SUPPORT_CASE_KEY, supportCaseId);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
    private static void getGETResponse(string getIdentifier, List<Case> supportCases)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> supportCasesMap = PC_RestAPIUtilities.transformSobjectCases(supportCases, PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
        res.responseBody = Blob.valueOf(JSON.serialize(supportCasesMap));
    }
}