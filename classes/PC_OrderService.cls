/************************************************************************************************************************************
Class Name      : PC_OrderService
Description     : REST class for Order object
Created By      : Deloitte
Created Date    : Nov 12, 2020
Modification Log:
---------------------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
---------------------------------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Nov 12, 2020           Initial Version
******************************************************************************************************************************************/
/**
 * REST API class to retrieve, create and update Orders. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/order/*' )
global with sharing class PC_OrderService {

    static final string ORDER_KEY = 'order';
    static final string ERRORS_KEY = 'errors';
    static final string ACCOUNT_KEY = 'account';
    static final string ORDERITEMS_KEY = 'orderItems';
    static string CHILD_OBJECTS_TO_FETCH;
    static final string QUERY_PARAM_ORDER_NUMBER = 'orderNumber';
    static final string QUERY_PARAM_PROGRAM_CASE = 'programCase';
    static final string QUERY_PARAM_SUBMITTED_DATE = 'submittedDate';

    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string orderId;
        orderId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        orderId = string.escapeSingleQuotes(orderId);
        Map<string, string> reqParams = req.params;
        system.debug('QueryParams...');
        system.debug(reqParams);
        validateQueryParams(orderId, reqParams);
        try
        {
            if(string.isNotBlank(orderId))
            {
                List<PC_Order__c> orders = PC_RestAPIUtilities.getOrders(orderId, null, null, null);
                getGETResponse(orders, false);
            }
            else
            {
                reqParams = req.params;
                String orderNumber = reqParams.get(QUERY_PARAM_ORDER_NUMBER);
                String programId = reqParams.get(QUERY_PARAM_PROGRAM_CASE);
                String submittedDate = reqParams.get(QUERY_PARAM_SUBMITTED_DATE);
                if(String.isBlank(orderNumber) && String.isBlank(programId) && String.isBlank(submittedDate)) {
                    throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_INVALID_QUERY_PARAMETER);
                }
                List<PC_Order__c> orders = PC_RestAPIUtilities.getOrders(orderId, orderNumber, programId, submittedDate);
                getGETResponse(orders, true);
            }
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }

    private static void validateQueryParams(String orderId, Map<String, String> reqParams) {
        Boolean isValid = true;
        if(String.isBlank(orderId)) {
            if(reqParams == null || reqParams.isEmpty()) {
                isValid = false;
            }
        }
        else {
            system.debug('orderId=' + orderId);
            if(!orderId.startsWith(PC_Order__c.sObjectType.getDescribe().getKeyPrefix())) {
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


    private static void getGETResponse(List<PC_Order__c> orders, Boolean responseAsArray) {
        RestResponse res = RestContext.response;

        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        map<string, list<sObject>> mapOfChildRestObjects = new map<string, list<sObject>>();
        map<string, string> mapOfKeys = new map<string, string>();

        //list<Map<string, object>> orderObjectsByStrings = PC_RestAPIUtilities.transformSobject(orders, PC_RestAPIConstants.REST_OBJECT_NAME_Order);

        List<PC_OrderItem__c> orderItems;
        List<Map<string, object>> orderItemObjectMaps;
        Map<String, Object> orderMap = new  Map<String, Object>();
        List<Map<String, Object>> ordersMap = new List<Map<String, Object>>();
        String orderId;
        for(PC_Order__c order: orders)
        {
            orderMap = PC_RestAPIUtilities.transformSobject(order.getPopulatedFieldsAsMap(), PC_RestAPIConstants.REST_OBJECT_NAME_Order);
            orderId = order.Id;
            orderItems = PC_RestAPIUtilities.getOrderItems(null, order.Name, null);
            if(orderItems != null && !orderItems.isEmpty()) {
                orderItemObjectMaps = PC_RestAPIUtilities.transformSobject(orderItems, PC_RestAPIConstants.REST_OBJECT_NAME_OrderItem);
                orderMap.put(ORDERITEMS_KEY, orderItemObjectMaps);
            }
            ordersMap.add(orderMap);
        }

        if(responseAsArray) {
            res.responseBody = Blob.valueOf(JSON.serialize(ordersMap));
        }
        else {
            if(ordersMap != null && !ordersMap.isEmpty()) {
                res.responseBody = Blob.valueOf(JSON.serialize(ordersMap[0]));
            }
        }

    }

    @HttpPost
    global static void doPost()
    {
        processOrderUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    @HttpPut
    global static void doPut()
    {
        processOrderUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }

    private static void processOrderUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> orderInfo;
        Savepoint sp = Database.setSavepoint();

        try
        {
            // Convert request info as Map
            orderInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);

            // Read the different components in the request string.
            Map<string, object> reqOrder = (Map<string, object>)orderInfo;
            List<object> reqOrderItemsObjList = new  List<object>();

            if(reqOrder.containsKey(ORDERITEMS_KEY))
            {
                reqOrderItemsObjList = (List<object>)reqOrder.get(ORDERITEMS_KEY);
            }
            reqOrder.remove(ORDERITEMS_KEY);
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqOrder = PC_RestAPIUtilities.removeIdField(reqOrder);
                if(reqOrderItemsObjList != null && !reqOrderItemsObjList.isEmpty())
                {
                    reqOrderItemsObjList = PC_RestAPIUtilities.removeIdField(reqOrderItemsObjList);

                }
            }
            for(Object reqOrderItemObj : reqOrderItemsObjList) {
                Map<String, Object> reqOrderItemMap = (Map<String, Object>) reqOrderItemObj;
                if(reqOrderItemMap != null && reqOrderItemMap.containsKey(ORDER_KEY)) {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ORDERITEM_INVALID_FIELD_ORDER_IN_UPSERT);
                }

            }
            Map<string, object> reqOrderTrans = PC_RestAPIUtilities.transformRESTObject(reqOrder, PC_RestAPIConstants.REST_OBJECT_NAME_Order);
            List<object> reqOrderItemObjListTrans;
            if(reqOrderItemsObjList != null && !reqOrderItemsObjList.isEmpty())
            {
                reqOrderItemObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqOrderItemsObjList, PC_RestAPIConstants.REST_OBJECT_NAME_OrderItem);
            }
            // Create sObjects
            string orderId = PC_RestAPIUtilities.upsertOrder(reqOrderTrans, operation);
            Map<string, object> orderItems = new  Map<string, object>();

            if(reqOrderItemObjListTrans != null && !reqOrderItemObjListTrans.isEmpty())
            {
                List<String> upsertedOrderItems = PC_RestAPIUtilities.upsertOrderItems(reqOrderItemObjListTrans, orderId, operation);
                orderItems.put('ids', upsertedOrderItems);
            }
            else
            {
                orderItems.put('ids', new  List<string>());
            }

            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(ORDER_KEY, orderId);
            rsBodyList.put(ORDERITEMS_KEY, orderItems.get('ids'));
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
}