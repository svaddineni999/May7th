/************************************************************************************************************************************
Class Name      : PC_PatientService
Description     : REST class for Patient object
Created By      : Deloitte
Created Date    : Jul 27, 2017
Modification Log:
---------------------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
---------------------------------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Jul 27, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Subham Agarwal                 Nov 14, 2017           <PC-2494> - Patient custom filter logic implemented
Rohit Kapoor                   Dec 8, 2017            <PC-2498> - As an external system (mobile/web application), I want to 
                                                       retrieve basic patient information New methods for PUT (verb) added
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
Haritha Reddy                  Jan 25, 2019           <PC-4248> - Added logic to get value of patientClass
Vijay Kashikar                 Apr 01, 2019           <PC-2646> - Related data will no be sent while doing a patient search via SOSL
******************************************************************************************************************************************/
/**
 * REST API class to retrieve, create and update Patient. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/patient/*' )
global with sharing class PC_PatientService
{
    static final string PATIENT_KEY = 'patient';
    static final string ADDRESSES_KEY = 'addresses';
    static final string HEALTHPLANS_KEY = 'healthPlans';
    static final string ADDRESS_ERRORS_KEY = 'addressErrors';
    static final string HEALTHPLAN_ERRORS_KEY = 'healthPlanErrors';
    static final string ERRORS_KEY = 'errors';
    static final string ACCOUNT_KEY = 'account';
    static final string ADVERSE_EVENT_KEY = 'adverseEvent';
    static string CHILD_OBJECTS_TO_FETCH;
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string patientId;
        patientId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        patientId = string.escapeSingleQuotes(patientId);
        Map<string, string> reqParams = req.params; 
        try
        {
            String pateintClassKey = reqParams.get(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
            Boolean hasPatientClass = reqParams.containsKey(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
            if(hasPatientClass){
                reqParams.remove(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
            }

            if(reqParams.containsKey(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_KEY))
            {
                CHILD_OBJECTS_TO_FETCH =PC_RestAPIUtilities.getChildObjectsToFetch(reqParams,
                                                                                    PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT);

            }
            if(string.isNotBlank(patientId) && patientId.startsWith(Account.sObjectType.getDescribe().getKeyPrefix()))
            {
                    Account account = PC_RestAPIUtilities.getPatientById(patientId);
                    getGETResponse(null, account);
            }
            else
            {
                reqParams = req.params;
                List<Account> accounts = (List<Account>)PC_RestAPIUtilities.recordSearchViaRequestParams(reqParams,pateintClassKey,hasPatientClass,PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT, ACCOUNT_KEY);
                getGETResponse(null, accounts);             
            }
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    @HttpPost
    global static void doPost()
    {
        processPatientUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    @HttpPut
    global static void doPut()
    {
        processPatientUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }
    private static void processPatientUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> patientInfo;
        Savepoint sp = Database.setSavepoint();
        string requestURL;
        try
        {
            // Convert request info as Map
            patientInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            Boolean allOrNone = PC_RestAPIUtilities.getAllOrNone(req);
            requestURL = PC_RestAPIUtilities.getRequestURL(req);
            system.debug('AllOrNone value = ' + allOrNone);
            // Read the different components in the request string.
            // Todo no need to read from patient key
            // Todo rest fields be case sensitive
            Map<string, object> reqPatient = (Map<string, object>)patientInfo;
            List<object> reqAddressesObjList = new  List<object>();
            string patientClass = string.valueOf(reqPatient.get(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY));
            Boolean hasPatientClass = reqPatient.containsKey(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);

            if (operation == PC_RestAPIConstants.ObjectOperation.oUPDATE && string.isNotBlank(patientClass)){
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_CONFIGURATION), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PATIENT_PATIENT_CLASS_CANNOT_BE_UPDATED);
            }
            if(hasPatientClass) {
                reqPatient.remove(PC_RestAPIConstants.PATIENT_PATIENT_CLASS_KEY);
            }
            if(reqPatient.containsKey(ADDRESSES_KEY) && !(string.valueOf(reqPatient.get(ADDRESSES_KEY)) == '({})' || string.valueOf(reqPatient.get(ADDRESSES_KEY)) == '()'))
            {
                reqAddressesObjList = (List<object>)reqPatient.get(ADDRESSES_KEY);
            }
            reqPatient.remove(ADDRESSES_KEY);
            List<object> reqHealthPlans = new  List<object>();
            if(reqPatient.containsKey(HEALTHPLANS_KEY) && !(string.valueOf(reqPatient.get(HEALTHPLANS_KEY)) == '({})' || string.valueOf(reqPatient.get(HEALTHPLANS_KEY)) == '()'))
            {
                reqHealthPlans = (List<object>)reqPatient.get(HEALTHPLANS_KEY);
            }
            reqPatient.remove(HEALTHPLANS_KEY);
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqPatient = PC_RestAPIUtilities.removeIdField(reqPatient);
                if(reqAddressesObjList != null && !reqAddressesObjList.isEmpty())
                {
                    reqAddressesObjList = PC_RestAPIUtilities.removeIdField(reqAddressesObjList);
                   
                }
                if(reqHealthPlans != null && reqHealthPlans.size() > 0)
                {
                    reqHealthPlans = PC_RestAPIUtilities.removeIdField(reqHealthPlans);
                }
            }
            // Get Rest object mapping from custom metadata
            if(PC_RestAPIUtilities.validateMandatoryFieldsOfPatiet(reqPatient))
            {
                Map<string, object> reqPatientTrans = PC_RestAPIUtilities.transformRESTObject(reqPatient, PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT);
                List<object> reqAddressesObjListTrans;
                if(reqAddressesObjList != null && !reqAddressesObjList.isEmpty())
                {
                   
                    reqAddressesObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqAddressesObjList, PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
                   
                }
                List<object> reqHealthPlansTrans;
                if(reqHealthPlans != null && reqHealthPlans.size() > 0)
                {
                    reqHealthPlansTrans = PC_RestAPIUtilities.transformRESTObjects(reqHealthPlans, PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
                }
                // Create sObjects
                string patientId = PC_RestAPIUtilities.upsertPatient(reqPatientTrans, patientClass, operation);
                Map<string, object> addresses = new  Map<string, object>();
              
                if(reqAddressesObjListTrans != null && !reqAddressesObjListTrans.isEmpty())
                {
                    addresses = PC_RestAPIUtilities.upsertAddresses(reqAddressesObjListTrans, patientId, operation, allOrNone, requestURL);
                }
                else
                {
                    addresses.put('ids', new  List<string>());
                }
                Map<string, object> healthPlans = new  Map<string, object>();
                if(reqHealthPlansTrans != null && reqHealthPlansTrans.size() > 0)
                {
                    healthPlans = PC_RestAPIUtilities.upsertHealthPlans(reqHealthPlansTrans, patientId, operation, allOrNone, requestURL);
                }
                else
                {
                    healthPlans.put('ids', new  List<string>());
                }
                Map<string, object> rsBodyList = new  Map<string, object>();
                rsBodyList.put(PATIENT_KEY, patientId);
                rsBodyList.put(ADDRESSES_KEY, addresses.get('ids'));
                rsBodyList.put(HEALTHPLANS_KEY, healthPlans.get('ids'));
                if(allOrNone)
                {
                }
                // do not add errors, since there won't be any!
                else
                {
                    Map<string, Map<string, string>> addressErrors = (Map<string, Map<string, string>>)addresses.get('errors');
                    Map<string, Map<string, string>> healthPlanErrors = (Map<string, Map<string, string>>)healthPlans.get('errors');
                    Map<string, Map<string, string>> allErrors = new  Map<string, Map<string, string>>();
                    if(addressErrors != null && addressErrors.size() > 0)
                    {
                        //rsBodyList.put(ADDRESS_ERRORS_KEY, addresses.get('errors'));
                        allErrors.putAll(addressErrors);
                    }
                    if(healthPlanErrors != null && healthPlanErrors.size() > 0)
                    {
                        //rsBodyList.put(HEALTHPLAN_ERRORS_KEY, healthPlans.get('errors'));
                        allErrors.putAll(healthPlanErrors);
                    }
                    if(allErrors != null && allErrors.size() > 0)
                    {
                        rsBodyList.put(ERRORS_KEY, allErrors);
                    }
                }
                res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MANDATORY_FIELDS_MISSING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PATIENT_MANDATORY_FIELDS_MISSING);
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
    private static void getGETResponse(string getIdentifier, Account account)
    {
        RestResponse res = RestContext.response;
       
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        map<string, list<sObject>> mapOfChildRestObjects = new map<string, list<sObject>>();
        map<string, string> mapOfKeys = new map<string, string>();

        Map<string, object> patientMap = PC_RestAPIUtilities.transformSobject(account.getPopulatedFieldsAsMap(), PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT);
        if(string.isNotBlank(CHILD_OBJECTS_TO_FETCH) &&
                (CHILD_OBJECTS_TO_FETCH.containsIgnoreCase('address') 
            || CHILD_OBJECTS_TO_FETCH.containsIgnoreCase(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_ALL)))
        {
            List<PC_Address__c> patientAddresses = PC_RestAPIUtilities.getAddressesByAccountId(account.Id);
            List<Map<string, object>> patientAddressesMap = PC_RestAPIUtilities.transformSobjectAddresses(patientAddresses);
            if(patientAddressesMap != null && !patientAddressesMap.isEmpty())
            {
                patientMap.put(ADDRESSES_KEY, patientAddressesMap);
            }
            CHILD_OBJECTS_TO_FETCH = PC_RestAPIUtilities.removeProcessedObject(CHILD_OBJECTS_TO_FETCH, PC_RestAPIConstants.ADDRESSES_REST_FIELD_NAME);
            
        }
        if(string.isNotBlank(CHILD_OBJECTS_TO_FETCH)
            && (CHILD_OBJECTS_TO_FETCH.containsIgnoreCase(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_ALL)
            || CHILD_OBJECTS_TO_FETCH.containsIgnoreCase(PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN.tolowerCase())))
            
        {
            List<PC_Health_Plan__c> patientHealthPlans = PC_RestAPIUtilities.getHealthPlansByAccountId(account.Id);
            List<Map<string, object>> patientHealthPlansMap = PC_RestAPIUtilities.transformSobjectHealthPlans(patientHealthPlans);
            if(patientHealthPlansMap != null && !patientHealthPlansMap.isEmpty())
            {
                patientMap.put(HEALTHPLANS_KEY, patientHealthPlansMap);
            }
            CHILD_OBJECTS_TO_FETCH = PC_RestAPIUtilities.removeProcessedObject(CHILD_OBJECTS_TO_FETCH, PC_RestAPIConstants.HEALTH_PLANS_REST_FIELD_NAME);
        }

        //PC-2498 - As an external system (mobile/web application), I want to retrieve basic patient information
        map<string, map<string, List<sObject>>> mapOfMapOfChildRestObjects = PC_RestAPIUtilities.getChildObjectsByParentId(PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT,
                                                                                                                            string.valueOf(account.id));
        if(string.isNotBlank(CHILD_OBJECTS_TO_FETCH) && mapOfMapOfChildRestObjects != null && !mapOfMapOfChildRestObjects.isEmpty())
        {
            if(CHILD_OBJECTS_TO_FETCH.contains(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_ALL))
            {
                for(string mapKey : mapOfMapOfChildRestObjects.keySet())
                {
                    map<string, list<sObject>>mapOfChildRestObjects_Intermediate = new map<string, list<sObject>>(mapOfMapOfChildRestObjects.get(mapKey));
                    mapOfChildRestObjects.putAll(mapOfChildRestObjects_Intermediate);
                   
                    map<string, string> mapOfKeys_Intermediate = new map<string, string>(PC_RestAPIUtilities.createMapOfKeys(mapKey, mapOfChildRestObjects.keySet()));
                    mapOfKeys.putAll(mapOfKeys_Intermediate);
                }
            }
            else if(!CHILD_OBJECTS_TO_FETCH.contains(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_NONE))
            {
               string childParentRelationship_NotFound;
               for(string childObj : CHILD_OBJECTS_TO_FETCH.split(','))
                {
                    if(mapOfMapOfChildRestObjects.containsKey(childObj) && mapOfMapOfChildRestObjects.get(childObj) != null)
                    {
                       map<string, list<sObject>>mapOfChildRestObjects_Intermediate = new map<string, list<sObject>>(mapOfMapOfChildRestObjects.get(childObj));
                       mapOfChildRestObjects.putAll(mapOfChildRestObjects_Intermediate); 
                    }
                    else
                    {
                        if(string.isBlank(childParentRelationship_NotFound))
                        {
                            childParentRelationship_NotFound = childObj;
                           
                        }
                        else if(string.isNotBlank(childParentRelationship_NotFound) && !childParentRelationship_NotFound.contains(childObj))
                        {
                            childParentRelationship_NotFound += ',' + childObj;
                        }
                        childParentRelationship_NotFound = childParentRelationship_NotFound.removeEnd(',');

                    }
                    mapOfKeys.putAll(PC_RestAPIUtilities.createMapOfKeys(childObj, mapOfChildRestObjects.keySet()));
                }
                
                if(string.isNotBlank(childParentRelationship_NotFound))
                {
                    
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS),
                                                string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                                                PC_RestAPIConstants.CHILDOBJS_RELATIONSHIP_MISSING + ' '+ PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT +': '+ childParentRelationship_NotFound);
                }
            }
        }
        if(mapOfChildRestObjects != null && !mapOfChildRestObjects.isEmpty())
        {
            for(string mapKey : mapOfChildRestObjects.keySet())
            { 
                if(mapOfKeys != null && !mapOfKeys.isEmpty() && mapOfKeys.containsKey(mapKey))
                {
                    List<Map<string, object>> patientChildObjectsMap = PC_RestAPIUtilities.transformSobject(mapOfChildRestObjects.get(mapKey),mapKey);
                    Map<string, object> patientMap_intermediate = new Map<string, object>();
                    
                    if(patientChildObjectsMap != null && !patientChildObjectsMap.isEmpty())
                    {
                        patientMap_intermediate= new Map<string, object>{mapOfKeys.get(mapKey)=> patientChildObjectsMap};
                    }
                    if(patientMap_intermediate != null && !patientMap_intermediate.isEmpty())
                    {
                        patientMap.putAll(patientMap_intermediate); 
                    }
                }
            }
        }
        res.responseBody = Blob.valueOf(JSON.serialize(patientMap));
    }
    private static void getGETResponse(string getIdentifier, List<Account> listAccounts)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> patientMap = PC_RestAPIUtilities.transformSobjectAccounts(listAccounts, PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT);
        /*Set<Id> setPatientIds = new  Set<Id>();
        for(Account objAccount: listAccounts)
        {
            setPatientIds.add(objAccount.Id);
        }
        if(setPatientIds.size() > PC_RestAPIConstants.RECORDS_LIMIT) {
            // this limit check is imposed to avoid failure of queries since we end up querying related objects such as health plans
            // for the list of accounts returned.
            throw new PC_RestException(PC_RestAPIConstants.PATIENT_SEACH_LIMIT_EXCEPTION);
        }
        Map<string, List<PC_Health_Plan__c>> patientHealthPlansMap = PC_RestAPIUtilities.getHealthPlansByAccountIds(setPatientIds);
        for(Map<string, object> patient: patientMap)
        {
            if(patientHealthPlansMap != null && !patientHealthPlansMap.isEmpty() && patientHealthPlansMap.containsKey(string.valueOf(patient.get('id'))))
            {
                patient.put(HEALTHPLANS_KEY, PC_RestAPIUtilities.transformSobjectHealthPlans(patientHealthPlansMap.get(string.valueOf(patient.get('id')))));
            }
            else
            {
                patient.put(HEALTHPLANS_KEY, new  List<PC_Health_Plan__c>());
            }
        }
        Map<string, List<PC_Address__c>> patientAddressesMap = PC_RestAPIUtilities.getAddressesByAccountIds(setPatientIds);
        for(Map<string, object> patient: patientMap)
        {
            if(patientAddressesMap != null && !patientAddressesMap.isEmpty() && patientAddressesMap.containsKey(string.valueOf(patient.get('id'))))
            {
                patient.put(ADDRESSES_KEY, PC_RestAPIUtilities.transformSobjectAddresses(patientAddressesMap.get(string.valueOf(patient.get('id')))));
            }
            else
            {
                patient.put(ADDRESSES_KEY, new  List<Map<string, object>>());
            }
        }*/
        res.responseBody = Blob.valueOf(JSON.serialize(patientMap));
    }
}