/*********************************************************************************************************
Class Name      : PC_EngagementProgramService
Description     : REST class for Engagement Program object
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
 * REST API class to retrieve Engagement Program. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/engagementProgram/*' )
global with sharing class PC_EngagementProgramService
{
    static final string ENGAGEMENT_PROGRAM_KEY = 'engagementProgram';
    static final string GET_PARAM_FIND_BY_PROGRAM_CODE = 'findByCode';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string reqString = req.requestURI;
        reqString = reqString.toLowerCase();
        string programCode = null;
        PC_Engagement_Program__c engagementProgram;
        try
        {
            if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_PROGRAM_CODE))
            {
                // Search by Program Code
                programCode = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                if(string.isNotBlank(programCode))
                {
                    programCode = programCode.replace('+', ' ');
                    programCode = string.escapeSingleQuotes(programCode);
                    engagementProgram = PC_RestAPIUtilities.getEngagementProgramByCode(programCode);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PROGRAM_FINDBYCODE_MISSING);
                }
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.INVALID_PARAMETERS);
            }
            getGETResponse(null, engagementProgram);
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    private static void getGETResponse(string getIdentifier, PC_Engagement_Program__c engagementProgram)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Map<string, object> engagementProgramMap = PC_RestAPIUtilities.transformSobject(engagementProgram.getPopulatedFieldsAsMap(), PC_RestAPIConstants.REST_OBJECT_NAME_ENGAGEMENT_PROGRAM);
        res.responseBody = Blob.valueOf(JSON.serialize(engagementProgramMap));
    }
}