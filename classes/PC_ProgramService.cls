/*********************************************************************************************************
Class Name      : PC_ProgramService
Description     : REST class for Program/Case object
Created By      : Deloitte
Created Date    : Aug 08, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Aug 08, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
Haritha Reddy                  Jul 05, 2021           <PC-7878> - Modified logic to support fetching Reference fields
****************************************************************************************************************/
/**
 * REST API class to retrieve, create programs. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/program/*' )
global with sharing class PC_ProgramService
{
    static final String PROGRAM_KEY = 'program';
    static final String PROGRAMS_KEY = 'programs';
    static final String ASSOCIATIONS_KEY = 'associations';
    static final String SUPPORT_CASES_KEY = 'supportCases';
    static final String GET_PARAM_FIND_BY_PATIENT_ID = 'findByPatientId';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String reqString = req.requestURI;
        reqString = reqString.toLowerCase();
        String patientId = null;
        List<Case> programCases;
        try
        {
            if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_PATIENT_ID))
            {
                // Search by Patient Id
                patientId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                if(String.isNotBlank(patientId))
                {
                    patientId = String.escapeSingleQuotes(patientId);
                    programCases = PC_RestAPIUtilities.getCaseProgramsByPatientId(patientId);
                }
                else
                {
                    throw new  PC_RestException(String.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), String.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
                }
            }
            else
            {
                throw new  PC_RestException(String.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), String.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.PROGRAM_INVALID_PARAMETERS);
            }
            getGETResponse(null, programCases);
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, '');
        }
    }
    @HttpPost
    global static void doPost()
    {
        processProgramsUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    private static void processProgramsUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        String reqString = reqBlob.toString();
        system.debug(reqString);
        Map<String, Object> programCasesInfo;
        Savepoint sp = Database.setSavepoint();
        String requestURL;
        try
        {
            // Convert request info as Map
            programCasesInfo = (Map<String, Object>)JSON.deserializeUntyped(reqString);
            requestURL = PC_RestAPIUtilities.getRequestURL(req);
            // Read the different components in the request string.
            Map<String, Object> reqProgram = (Map<String, Object>)programCasesInfo;
            List<Object> reqAssociationsObjList = new  List<Object>();
            if(reqProgram.containsKey(ASSOCIATIONS_KEY))
            {
                reqAssociationsObjList = (List<Object>)reqProgram.get(ASSOCIATIONS_KEY);
                reqProgram.remove(ASSOCIATIONS_KEY);
            }
            List<Object> reqSupportObjList = new  List<Object>();
            if(reqProgram.containsKey(SUPPORT_CASES_KEY))
            {
                reqSupportObjList = (List<Object>)reqProgram.get(SUPPORT_CASES_KEY);
                reqProgram.remove(SUPPORT_CASES_KEY);
            }
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqProgram = PC_RestAPIUtilities.removeIdField(reqProgram);
                reqAssociationsObjList = PC_RestAPIUtilities.removeIdField(reqAssociationsObjList);
                reqSupportObjList = PC_RestAPIUtilities.removeIdField(reqSupportObjList);
            }
            // Get Rest object mapping from custom metadata
            Map<String, Object> reqProgramTrans = PC_RestAPIUtilities.transformRESTObject(reqProgram, PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
            List<Object> reqAssociationsObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqAssociationsObjList, PC_RestAPIConstants.REST_OBJECT_NAME_ASSOCIATION);
            List<Object> reqSupportObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqSupportObjList, PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
            // Create sObjects
            String programId = PC_RestAPIUtilities.upsertProgramCase(reqProgramTrans, operation);
            List<String> associationIds = PC_RestAPIUtilities.upsertAssociations(reqAssociationsObjListTrans, programId, operation);
            List<String> supportCaseIds = PC_RestAPIUtilities.upsertSupportCases(reqSupportObjListTrans, programId, operation);
            // Create responseBody
            Map<String, Object> rsBodyList = new  Map<String, Object>();
            rsBodyList.put(PROGRAM_KEY, programId);
            rsBodyList.put(ASSOCIATIONS_KEY, associationIds);
            rsBodyList.put(SUPPORT_CASES_KEY, supportCaseIds);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
    private static void getGETResponse(String getIdentifier, List<Case> programCases)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Object> progs = new  List<Object>();
        Map<String, Object> program_map = new  Map<String, Object>();
        Map<String, Object> programs_map = new  Map<String, Object>();
        String caseId;
        List<PC_Association__c> associations;
        List<Case> supportCases;
        List<Map<String, Object>> associations_map;
        List<Map<String, Object>> supportCases_map;
        for(Case c: programCases)
        {
            program_map = PC_RestAPIUtilities.transformSobject(c, PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
            caseId = c.Id;
            associations = PC_RestAPIUtilities.getProgramCaseAssociations(caseId);
            associations_map = PC_RestAPIUtilities.transformSobjectAssociations(associations);
            program_map.put(ASSOCIATIONS_KEY, associations_map);
            supportCases = PC_RestAPIUtilities.getSupportCases(caseId);
            supportCases_map = PC_RestAPIUtilities.transformSobjectCases(supportCases, PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
            program_map.put(SUPPORT_CASES_KEY, supportCases_map);
            progs.add(program_map);
        }
        programs_map.put(PROGRAMS_KEY, progs);
        res.responseBody = Blob.valueOf(JSON.serialize(programs_map));
    }
}