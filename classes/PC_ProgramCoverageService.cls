/*********************************************************************************************************
Class Name      : PC_ProgramCoverageService
Description     : REST class for Program Coverage object
Created By      : Deloitte
Created Date    : Nov 14, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Rohit Kapoor                   Nov 14, 2017           Initial Version
Rohit Kapoor                   Nov 19, 2017           General modifications
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
****************************************************************************************************************/
/**
 * REST API class to retrieve, create and update program coverages. Please refer Rest API Documentation for usage.
 */
@RestResource(urlMapping='/1.0/programCoverage/*')
global with sharing class PC_ProgramCoverageService  {

    static final string PROGRAMCOVERAGE_KEY = 'programCoverage';
    static final string PROGRAMCOVERAGES_KEY = 'programcoverages';
    static final string GET_PARAM_FIND_BY_PROGRAM_ID = 'findByProgramId';
    
    @HttpGet
    global static void doGet() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        string reqString = req.requestURI;
        string programCoverageId;
        string programId;
        string URL_ID_PARAMETER;
        list<sObject> listOfProgramCoverage;

        try
        {
            if(string.isNotBlank(reqString))
            {
                URL_ID_PARAMETER = reqString.substring(reqString.lastIndexOf('/') + 1);
            }
            else
            {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS),
                                            string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 
                                            PC_RestAPIConstants.INVALID_PARAMETERS);
            }
            system.debug('URL_ID_PARAMETER--'+ URL_ID_PARAMETER);
            if(string.isBlank(URL_ID_PARAMETER))
            {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), 
                                                string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                                                PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
            }
            else if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_PROGRAM_ID))
            {
                //find Program Coverage by Program case record Id
                programId = string.escapeSingleQuotes(URL_ID_PARAMETER);
                listOfProgramCoverage = PC_RestAPIUtilities.getProgramCoveragesByProgramId(programId);
            }
            else
            {
                //find Program Coverage by its record Id
                programCoverageId = string.escapeSingleQuotes(URL_ID_PARAMETER);
                listOfProgramCoverage = PC_RestAPIUtilities.getProgramCoverageById(programCoverageId);
                
            }

            system.debug('listOfProgramCoverage--'+ listOfProgramCoverage);
            getGETResponse(null, listOfProgramCoverage);
        }
        catch(exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, '');
        }
    }

    @HttpPost
    global static void doPost() {

        processProgramsCoverageUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }

    @HttpPut
    global static void doPut() {

        processProgramsCoverageUpsert(PC_RestAPIConstants.ObjectOperation.oUpdate);

    }

    private static void processProgramsCoverageUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        system.debug(reqString);
        Map<string, object> mapOfProgramCoverageRequest;
        Savepoint sp = Database.setSavepoint();
        string requestURL;
        try
        {
            mapOfProgramCoverageRequest = (map<string, Object>)JSON.deserializeUntyped(reqString);
            requestURL = PC_RestAPIUtilities.getRequestURL(req);

            // Read the different components in the request string.
            Map<string, object> mapReqProgramCoverage = (Map<string, object>)mapOfProgramCoverageRequest;
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                mapReqProgramCoverage = PC_RestAPIUtilities.removeIdField(mapReqProgramCoverage);
            } 

            // Get Rest object mapping from custom metadata
            Map<string, object> mapOfReqProgramCoverageTrans = PC_RestAPIUtilities.transformRESTObject(mapReqProgramCoverage, PC_RestAPIConstants.REST_OBJECT_NAME_PROGRAM_COVERAGE);
            // Create sObjects
            string programCoverageId = PC_RestAPIUtilities.upsertProgramCoverage(mapOfReqProgramCoverageTrans, operation);
            
            // Create responseBody
            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(PROGRAMCOVERAGE_KEY, programCoverageId);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList)); 
        }
        catch(exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }

    private static void getGETResponse(string getIdentifer, list<sObject> listOfProgramCoverages)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        list<Object> listOfProgCoverages = new list<Object>();
        map<string, Object> mapOfprogramCoverages = new map<string, Object>();
        map<string, Object> mapOfTransformedProgramCoverage = new map<string, Object>();
        List<Map<string, object>> listOfProgramCoverage = new List<Map<string, object>>();
        if(listOfProgramCoverages != null && !listOfProgramCoverages.isEmpty())
        {
            //listOfProgramCoverage = PC_RestAPIUtilities.transformSobjectProgramCoverage(listOfProgramCoverages,PC_RestAPIConstants.REST_OBJECT_NAME_PROGRAM_COVERAGE);
            listOfProgramCoverage = PC_RestAPIUtilities.transformSobject(listOfProgramCoverages,PC_RestAPIConstants.REST_OBJECT_NAME_PROGRAM_COVERAGE);
       
        } 
        for(Object pc: listOfProgramCoverages)
        {
            PC_Program_Coverage__c progCoverage = (PC_Program_Coverage__c)pc;
            mapOfTransformedProgramCoverage = PC_RestAPIUtilities.transformSobject(progCoverage.getPopulatedFieldsAsMap(), 
                                                                PC_RestAPIConstants.REST_OBJECT_NAME_PROGRAM_COVERAGE);
            if(mapOfTransformedProgramCoverage != null && !mapOfTransformedProgramCoverage.isEmpty())
            {
                listOfProgCoverages.add(mapOfTransformedProgramCoverage);
            }

        }  
        
        mapOfprogramCoverages.put(PROGRAMCOVERAGES_KEY, listOfProgCoverages); 
        
       
        res.responseBody = Blob.valueOf(JSON.serialize(mapOfprogramCoverages));
         
    }
}