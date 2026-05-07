/*********************************************************************************************************
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer           Date            Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar      Jul 27, 2016    Initial Version
Subham Agarwal      Nov 8, 2017     <PC-2468> - Review current API design and propose updates to framework
Vijay Kashikar      Jan 11, 2018    <PC-2663> - Constants renamed.
Mike Klumpenaar     2019-03-2019    PC-
****************************************************************************************************************/

/**
 * REST API class to create, update and retrieve addresses. Please refer Rest API Documentation for usage.
 *
 * @date 2016-07-17
 */
@RestResource (urlMapping = '/1.0/address/*' )
global with sharing class PC_AddressService
{
    static final string ADDRESSES_KEY = 'addresses';
    static final string ADDRESS_KEY = 'address';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string addressId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        addressId = string.escapeSingleQuotes(addressId);
        try
        {
            if(string.isNotBlank(addressId))
            {
                PC_Address__c address = PC_RestAPIUtilities.getAddress(addressId);
                getGETResponse(null, address);
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
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
        processAddressUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    @HttpPut
    global static void doPut()
    {
        processAddressUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }

    private static void processAddressUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> addressInfo;
        Savepoint sp = Database.setSavepoint();
        try
        {
            // Convert request info as Map
            addressInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                addressInfo = PC_RestAPIUtilities.removeIdField(addressInfo);
            }
            Map<string, object> reqAddressObjTrans = PC_RestAPIUtilities.transformRESTObject(addressInfo, PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
            // Create sObjects            
            string addressId = PC_RestAPIUtilities.upsertAddress(reqAddressObjTrans, operation);
            // Create responseBody
            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(ADDRESS_KEY, addressId);
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
    private static void getGETResponse(string getIdentifier, PC_Address__c address)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<PC_Address__c> addresses = new  List<PC_Address__c>();
        addresses.add(address);
        List<Map<string, object>> addresses_trans = PC_RestAPIUtilities.transformSobjectAddresses(addresses);
        res.responseBody = Blob.valueOf(JSON.serialize(addresses_trans[0]));
    }
}