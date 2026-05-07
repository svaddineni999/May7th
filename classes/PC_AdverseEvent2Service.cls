/*********************************************************************************
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Shishir Bansal         May 22, 2019                 Initial Version
Shishir Bansal         May 26, 2019                 [PC-4616] Implementing Get service to fetch Adverse event details
                                                    for a patientId.
Shishir Bansal         May 26, 2019                 [PC-4617] Implementing Post service to create Adverse event for
                                                    a patient record id.
Shishir Bansal         May 26, 2019                 [PC-4618] Implementing Update service to update Adverse event for
                                                     a patient record id.
Shsihir Bansal         May 29,2019                  Code Refactoring, adding comments to the methods and
                                                    removing system.debug statements
Shishir Bansal        Dec-06-2019                   [PC-5792] Avoid hardcoding of string variable
*********************************************************************************/

/**
 * REST API class to create, update and retrieve Adverse events 2. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/adverseEvent2/*' )
global with sharing class PC_AdverseEvent2Service {

    static final String SUSPECT_PRODUCTS_KEY = 'suspectProducts';
    static final String ADVERSE_EVENTS_KEY = 'adverseEvents';
    static final String SUSPECT_PRODUCT_ADVERSE_EVENTS_KEY = 'adverseEventId';
    static final String Id = 'id';


    /**
     * doGet Method with @HttpGet annotation to get adverse Events based on
     * PatientId
     * @param patientId in the request URL
     */
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        try
        {

            string patientId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            if(string.isNotBlank(patientId)) {
                List<PC_AdverseEvent2__c> adverseEventList = new List<PC_AdverseEvent2__c>();
                adverseEventList = PC_RestAPIUtilities.getAdverseEvents2(patientId);
                getGETResponse(null, adverseEventList);

            }

        }catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }

    /**
    * doPost Method with @HttpPost annotation to save adverse Event along with suspect Products
    * based on patientId(mandatory value)
    *
    * @param JSON in the request body
    */
    @HttpPost
    global static void doPost()
    {
        processAdverseEventUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }


    /**
    * doPut Method with @HttpPut annotation to update adverse Event along with suspect Products
    * based on patientId(mandatory value)
    *
    * @param JSON in the request body
    */
    @HttpPut
    global static void doPut()
    {
        processAdverseEventUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }

    /**
    * Upserting adverseEvent and related suspectPrescription records
    * @param operation
    */
    private static void processAdverseEventUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        String reqString = reqBlob.toString();
        Map<String,Object> adverseEventsInfo;
        List<Object> suspectProducts = new  List<Object>();
        Savepoint sp = Database.setSavepoint();
        String requestURL;
        try
        {
            // Convert request info as Map
            adverseEventsInfo = (  Map<String, Object>)JSON.deserializeUntyped(reqString);//
            requestURL = PC_RestAPIUtilities.getRequestURL(req);
            // Read the different components in the request string.
            Map<String, Object> reqAdverseEvent = (Map<String, Object>)adverseEventsInfo;
            SYSTEM.DEBUG('reqAdverseEvent'+reqAdverseEvent);
            List<Object> reqSuspectProductObjList = new  List<Object>();


            if(reqAdverseEvent.containsKey(SUSPECT_PRODUCTS_KEY))
            {
                reqSuspectProductObjList = (List<Object>)reqAdverseEvent.get(SUSPECT_PRODUCTS_KEY);
                SYSTEM.DEBUG('reqSuspectProductObjList'+reqSuspectProductObjList);
                reqAdverseEvent.remove(SUSPECT_PRODUCTS_KEY);
                SYSTEM.DEBUG('reqAdverseEvent. remove'+reqAdverseEvent);
            }

            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                SYSTEM.DEBUG('reqAdverseEvent. remove'+reqAdverseEvent);
                reqAdverseEvent = PC_RestAPIUtilities.removeIdField(reqAdverseEvent);
                reqSuspectProductObjList = PC_RestAPIUtilities.removeIdField(reqSuspectProductObjList);
                SYSTEM.DEBUG('reqSuspectProductObjList. remove'+reqSuspectProductObjList);
            }
            /* if(operation == PC_RestAPIConstants.ObjectOperation.oUPDATE)
             {

                 String adverseEventId  = String.valueOf(reqAdverseEvent.get(Id));
                 if(reqSuspectProductObjList.size()>0){

                     for(Object suspectProduct : reqSuspectProductObjList){

                         Map<String, Object> suspectPrescription = (Map<String, Object>)suspectProduct;
                         if(suspectPrescription.containsKey(SUSPECT_PRODUCT_ADVERSE_EVENTS_KEY)) {
                             String suspectAdverseEventId = String.valueOf(suspectPrescription.get(SUSPECT_PRODUCT_ADVERSE_EVENTS_KEY));
                             if (adverseEventId != suspectAdverseEventId){
                                 throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT),
                                         string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                                         PC_RestAPIConstants.ERRORMESSAGE_ADVERSE_EVENT_INVALID_JSON);
                             }
                         }
                     }
                 }
             }*/

            // Get Rest object mapping from custom metadata
            Map<String, Object> reqAdverseEventTrans = PC_RestAPIUtilities.transformRESTObject(reqAdverseEvent, PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT2);
            List<Object> reqSuspectProductObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqSuspectProductObjList, PC_RestAPIConstants.REST_OBJECT_NAME_SUSPECT_PRESCRIPTION);
            // Create sObjects
            String adverseEventId = PC_RestAPIUtilities.upsertAdverseEvent2(reqAdverseEventTrans, operation);
            List<String> suspectProductIds = PC_RestAPIUtilities.upsertSuspectPrescriptions2(reqSuspectProductObjListTrans, adverseEventId, operation);
            // Create responseBody
            Map<String, Object> rsBodyList = new  Map<String, Object>();
            rsBodyList.put(ADVERSE_EVENTS_KEY, adverseEventId);
            rsBodyList.put(SUSPECT_PRODUCTS_KEY, suspectProductIds);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }

    /**
    * getting response in JSON format of all the related  adverseEvent and related suspectPrescription records
    * @param getIdentifier , adverseEventList
    */
    private static void getGETResponse(string getIdentifier,  List<PC_AdverseEvent2__c> adverseEventList)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');

        List<Map<string, object>> adverseEvent_trans = PC_RestAPIUtilities.transformSobjectAdverseEvents2(adverseEventList);
        List<PC_Suspect_Prescription__c> suspectProducts = new List<PC_Suspect_Prescription__c>();
        List<Map<String, Object>> suspectProducts_map;
        Map<String, Object> adverseEvent_map = new  Map<String, Object>();
        Map<String, Object> adverseEvents_map = new  Map<String, Object>();
        List<PC_Suspect_Prescription__c> suspectPrescriptions;
        List<Map<String, Object>> suspectPrescriptions_map;
        List<Object> progs = new  List<Object>();
        String adverseEventId;
        for(PC_AdverseEvent2__c adverseEvent: adverseEventList){
            adverseEvent_map = PC_RestAPIUtilities.transformSobject(adverseEvent.getPopulatedFieldsAsMap(),
                    PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT2);
            adverseEventId = adverseEvent.Id;
            suspectPrescriptions = PC_RestAPIUtilities.getAdverseEvent2SuspectPrescriptions(adverseEventId);
            suspectPrescriptions_map = PC_RestAPIUtilities.transformSobjectSuspectPrescriptions(suspectPrescriptions);
            adverseEvent_map.put(SUSPECT_PRODUCTS_KEY, suspectPrescriptions_map);
            progs.add(adverseEvent_map);
        }
        adverseEvents_map.put(ADVERSE_EVENTS_KEY, progs);

        res.responseBody = Blob.valueOf(JSON.serialize(adverseEvents_map));
    }
}