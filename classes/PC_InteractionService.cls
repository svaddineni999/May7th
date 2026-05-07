/*********************************************************************************************************
Class Name      : PC_InteractionService
Description     : REST class for Interaction object
Created By      : Haritha Reddy
Created Date    : Jun 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy                Jun 15, 2021           [PC-7387] Initial Version
Haritha Reddy                Jul 06, 2021           [PC-7879] Added Put request changes
****************************************************************************************************************/
/**
 * REST API class to retrieve interactions.
 */
@RestResource (urlMapping = '/1.0/interaction/*' )
global with sharing class PC_InteractionService {

    static final string INTERACTION_KEY = 'interaction';
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string reqString = req.requestURI;
        Map<string, string> reqParams = req.params;
        try {
            if(!reqParams.isEmpty()) {
                List<PC_Interaction__c> interactionList = new List<PC_Interaction__c>();
                if(reqString.containsIgnoreCase(PC_RestAPIConstants.GET_PARAM_FIND_BY_ENGAGEMENT_PROGRAM_ID))
                {
                    interactionList = PC_RestAPIUtilities.getInteractions(reqParams,PC_RestAPIConstants.GET_PARAM_FIND_BY_ENGAGEMENT_PROGRAM_ID);
                }
                else if(reqString.containsIgnoreCase(PC_RestAPIConstants.GET_PARAM_FIND_BY_PATIENT_ID))
                {
                    interactionList = PC_RestAPIUtilities.getInteractions(reqParams,PC_RestAPIConstants.GET_PARAM_FIND_BY_PATIENT_ID);
                }
                getGETResponse(null, interactionList);
            } else {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_QUERY_PARAMS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_QUERY_PARAMETERS_MISSING);
            }
        } catch(Exception e) {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    private static void getGETResponse(string getIdentifier, List<sObject> interactionList) {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> interactionsMap = PC_RestAPIUtilities.transformSobject(interactionList, PC_RestAPIConstants.REST_OBJECT_NAME_INTERACTION);
        res.responseBody = Blob.valueOf(JSON.serialize(interactionsMap));
    }

    @HttpPut
    global static void doPut() {
        processInteractionUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }

    private static void processInteractionUpsert(PC_RestAPIConstants.ObjectOperation operation) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        system.debug(reqString);
        Map<string, object> mapOfInteractionRequest;
        string requestURL;
        try {
            mapOfInteractionRequest = (map<string, Object>)JSON.deserializeUntyped(reqString);
            requestURL = PC_RestAPIUtilities.getRequestURL(req);

            // Read the different components in the request string.
            Map<string, object> mapReqInteraction = (Map<string, object>)mapOfInteractionRequest;
            // Get Rest object mapping from custom metadata
            Map<string, object> mapOfReqInteractionTrans = PC_RestAPIUtilities.transformRESTObject(mapReqInteraction, PC_RestAPIConstants.REST_OBJECT_NAME_INTERACTION);
            // Create sObjects
            string interactionId = PC_RestAPIUtilities.upsertInteraction(mapOfReqInteractionTrans, operation);

            // Create responseBody
            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(INTERACTION_KEY, interactionId);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));

        } catch(exception e) {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
}