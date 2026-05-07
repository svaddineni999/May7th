/*********************************************************************************************************
Class Name      : PC_HealthPlanService
Description     : REST class for Health Plan object
Created By      : Deloitte
Created Date    : Jul 27, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Jul 27, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
****************************************************************************************************************/
/**
 * REST API class to retrieve, create and update Health plans. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/healthPlan/*' )
global with sharing class PC_HealthPlanService
{
    static final string HEALTHPLANS_KEY = 'healthPlans';
    static final string HEALTHPLAN_KEY = 'healthPlan';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try
        {
            string healthPlanId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            if(string.isNotBlank(healthPlanId))
            {
                healthPlanId = string.escapeSingleQuotes(healthPlanId);
                PC_Health_Plan__c healthPlan = PC_RestAPIUtilities.getHealthPlan(healthPlanId);
                getGETResponse(null, healthPlan);
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
            }
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, '');
        }
    }
    @HttpPost
    global static void doPost()
    {
        //processHealthPlansUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
        processHealthPlanUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    @HttpPut
    global static void doPut()
    {
        //processHealthPlansUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
        processHealthPlanUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }
    /*private static void processHealthPlansUpsert(PC_RestAPIConstants.ObjectOperation operation) {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    res.statusCode = 200;
    res.addHeader('Content-Type', 'application/json;charset=UTF-8');
    Blob reqBlob = req.requestBody;
    String reqString = reqBlob.toString();
    Map<String, Object> healthPlansInfo;
    Savepoint sp = Database.setSavepoint();
    try {
    // Convert request info as Map
    healthPlansInfo = (Map<String, Object>) JSON.deserializeUntyped(reqString);
    
    // Read the different components in the request string.
    List<Object> reqHealthPlansObjList = (List<Object>) healthPlansInfo.get(HEALTHPLANS_KEY);
    
    
    // Get Rest object mapping from custom metadata
    List<Object> reqHealthPlansListTrans = PC_RestAPIUtilities.transformRESTHealthPlans(reqHealthPlansObjList, PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
    
    
    // Create sObjects
    List<String> healthPlanIds = PC_RestAPIUtilities.upsertHealthPlans(reqHealthPlansListTrans, null, operation);
    
    
    // Create responseBody
    Map<String, Object> rsBodyList = new Map<String, Object>();
    rsBodyList.put(HEALTHPLANS_KEY,healthPlanIds);
    res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
    
    }
    catch(PC_RestException pcException) {
    Database.rollback(sp);
    res.statusCode = 412;
    
    Map<String, Object> rsBodyList = new Map<String, Object>();
    rsBodyList.put('message',pcException.getMessage());
    rsBodyList.put('lineNumber','Not Applicable');
    rsBodyList.put('cause','Invalid Data');
    rsBodyList.put('stackTrace','Not Applicable');
    
    res.responseBody = Blob.valueof(JSON.serialize(rsBodyList));
    }
    catch(Exception e){
    Database.rollback(sp);
    res.statusCode = 500;
    Map<String, Object> rsBodyList = new Map<String, Object>();
    rsBodyList.put('message',e.getMessage());
    rsBodyList.put('lineNumber',e.getLineNumber());
    rsBodyList.put('cause',e.getCause());
    rsBodyList.put('stackTrace',e.getStackTraceString());
    
    res.responseBody = Blob.valueof(JSON.serialize(rsBodyList));
    }
    finally {
    
    }
    }*/
    private static void processHealthPlanUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> healthPlansInfo;
        Savepoint sp = Database.setSavepoint();
        try
        {
            // Convert request info as Map
            healthPlansInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                healthPlansInfo = PC_RestAPIUtilities.removeIdField(healthPlansInfo);
            }
            // Get Rest object mapping from custom metadata            
            Map<string, object> reqHealthPlanTrans = PC_RestAPIUtilities.transformRESTObject(healthPlansInfo, PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
            // Create sObjects            
            string healthPlanId = PC_RestAPIUtilities.upsertHealthPlan(reqHealthPlanTrans, operation);
            // Create responseBody
            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(HEALTHPLAN_KEY, healthPlanId);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
    private static void getGETResponse(string getIdentifier, PC_Health_Plan__c healthPlan)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<PC_Health_Plan__c> hps = new  List<PC_Health_Plan__c>();
        hps.add(healthPlan);
        List<Map<string, object>> hps_trans = PC_RestAPIUtilities.transformSobjectHealthPlans(hps);
        res.responseBody = Blob.valueOf(JSON.serialize(hps_trans[0]));
    }
}