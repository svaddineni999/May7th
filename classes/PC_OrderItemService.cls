/************************************************************************************************************************************
Class Name      : PC_OrderItemService
Description     : REST class for Order object
Created By      : Deloitte
Created Date    : Nov 17, 2020
Modification Log:
---------------------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
---------------------------------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Nov 17, 2020           Initial Version
******************************************************************************************************************************************/
/**
 * REST API class to retrieve, create and update Order Items. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/orderItem/*' )
global with sharing class PC_OrderItemService {
    static final string ORDERITEM_KEY = 'orderItem';
    static final string QUERY_PARAM_ORDER_NUMBER = 'orderNumber';
    static final string QUERY_PARAM_PRODUCT_ID = 'productId';

    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string orderItemId;
        orderItemId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        orderItemId = string.escapeSingleQuotes(orderItemId);
        system.debug('orderItemId = ' + orderItemId);
        Map<string, string> reqParams = req.params;
        validateQueryParams(orderItemId, reqParams);
        try
        {
            if(string.isNotBlank(orderItemId))
            {
                List<PC_OrderItem__c> orderItems = PC_RestAPIUtilities.getOrderItems(orderItemId, null, null);
                getGETResponse(orderItems, false);
            }
            else if(reqParams != null && !reqParams.isEmpty()) {
                String orderNumber = reqParams.get(QUERY_PARAM_ORDER_NUMBER);
                String productId = reqParams.get(QUERY_PARAM_PRODUCT_ID);
                if(String.isBlank(orderNumber) && String.isBlank(productId)) {
                    throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_INVALID_QUERY_PARAMETER);
                }
                List<PC_OrderItem__c> orderItems = PC_RestAPIUtilities.getOrderItems(null, orderNumber, productId);
                getGETResponse(orderItems, true);

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
        processOrderItemUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    @HttpPut
    global static void doPut()
    {
        processOrderItemUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }
    private static void processOrderItemUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> orderItemInfo;
        Savepoint sp = Database.setSavepoint();

        try
        {
            // Convert request info as Map
            orderItemInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);

            // Read the different components in the request string.
            Map<string, object> reqOrderItem = (Map<string, object>)orderItemInfo;

            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqOrderItem = PC_RestAPIUtilities.removeIdField(reqOrderItem);
            }
            Map<string, object> reqOrderItemTrans = PC_RestAPIUtilities.transformRESTObject(reqOrderItem, PC_RestAPIConstants.REST_OBJECT_NAME_OrderItem);
            List<Map<string, object>> reqOrderItemsTrans = new List<Map<string, object>>();
            reqOrderItemsTrans.add(reqOrderItemTrans);
            // Create sObjects
            List<string> orderIds = PC_RestAPIUtilities.upsertOrderItems(reqOrderItemsTrans, null, operation);

            if(orderIds != null && !orderIds.isEmpty())
            {
                Map<string, object> rsBodyList = new  Map<string, object>();
                rsBodyList.put(ORDERITEM_KEY, orderIds[0]);
                res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }

    private static void validateQueryParams(String orderItemId, Map<String, String> reqParams) {
        Boolean isValid = true;
        if(String.isBlank(orderItemId)) {
            if(reqParams == null || reqParams.isEmpty()) {
                isValid = false;
            }
        }
        else {
            system.debug('orderItemId=' + orderItemId);
            if(!orderItemId.startsWith(PC_OrderItem__c.sObjectType.getDescribe().getKeyPrefix())) {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_RECORD_ID), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_INVALID_RECORD_ID);
            }
            if(reqParams != null && !reqParams.isEmpty()) {
                isValid = false;
            }
        }
        if(!isValid) {
            throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_INVALID_QUERY_PARAMETER);
        }
    }

    private static void getGETResponse(List<PC_OrderItem__c> orderItems, Boolean responseAsArray) {
        RestResponse res = RestContext.response;

        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');

        if(orderItems == null || orderItems.isEmpty()) {
            throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.NO_RECORD_FOUND);
        }
        map<string, list<sObject>> mapOfChildRestObjects = new map<string, list<sObject>>();
        map<string, string> mapOfKeys = new map<string, string>();

        list<Map<string, object>> orderItemObjectsByStrings = PC_RestAPIUtilities.transformSobject(orderItems, PC_RestAPIConstants.REST_OBJECT_NAME_OrderItem);

        if(responseAsArray) {
            res.responseBody = Blob.valueOf(JSON.serialize(orderItemObjectsByStrings));
        }
        else {
            if(orderItemObjectsByStrings != null && !orderItemObjectsByStrings.isEmpty()) {
                res.responseBody = Blob.valueOf(JSON.serialize(orderItemObjectsByStrings[0]));
            }
        }

    }

}