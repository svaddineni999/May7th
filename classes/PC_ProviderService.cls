/*********************************************************************************************************
Class Name      : PC_ProviderService
Description     : REST class for Account(HCO) object
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
 * REST API class to retrieve, create and update physician. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/physician/*' )
global with sharing class PC_ProviderService
{
    static final string PROVIDER_KEY = 'physician';
    static final string ADDRESSES_KEY = 'addresses';
    static final string GET_PARAM_FIND_BY_NPI = 'findByNPI';
    static final string ADDRESS_ERRORS_KEY = 'addressErrors';
    static final string ERRORS_KEY = 'errors';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string reqString = req.requestURI;
        reqString = reqString.toLowerCase();
        string providerId = null;
        string npi = null;
        Account acc;
        try
        {
            if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_NPI))
            {
                // Search by NPI
                npi = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                if(string.isNotBlank(npi))
                {
                    npi = npi.replace('+', ' ');
                    npi = string.escapeSingleQuotes(npi);
                    acc = PC_RestAPIUtilities.getProviderByNpi(npi);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
                }
            }
            else
            {
                providerId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                providerId = string.escapeSingleQuotes(providerId);
                if(string.isNotBlank(providerId))
                {
                    acc = PC_RestAPIUtilities.getProviderById(providerId);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
                }
            }
            getGETResponse(null, acc);
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    @HttpPost
    global static void doPost()
    {
        processProviderUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    @HttpPut
    global static void doPut()
    {
        processProviderUpsert(PC_RestAPIConstants.ObjectOperation.oUpdate);
    }
    private static void processProviderUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> providerInfo;
        Savepoint sp = Database.setSavepoint();
        string requestURL;
        try
        {
            // Convert request info as Map
            providerInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            Boolean allOrNone = PC_RestAPIUtilities.getAllOrNone(req);
            requestURL = PC_RestAPIUtilities.getRequestURL(req);
            // Read the different components in the request string.
            Map<string, object> reqProvider = (Map<string, object>)providerInfo;
            List<object> reqAddressesObjList = new  List<object>();
            if(reqProvider.containsKey(ADDRESSES_KEY))
            {
                reqAddressesObjList = (List<object>)reqProvider.get(ADDRESSES_KEY);
                // Remove address from provider info. This will leave us with only the provider related data.
                reqProvider.remove(ADDRESSES_KEY);
            }
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqProvider = PC_RestAPIUtilities.removeIdField(reqProvider);
                reqAddressesObjList = PC_RestAPIUtilities.removeIdField(reqAddressesObjList);
            }
            // Get Rest object mapping from custom metadata
            Map<string, object> reqProviderTrans = PC_RestAPIUtilities.transformRESTObject(reqProvider, PC_RestAPIConstants.REST_OBJECT_NAME_PROVIDER);
            List<object> reqAddressesObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqAddressesObjList, PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
            // Create sObjects
            string providerId = PC_RestAPIUtilities.upsertProvider(reqProviderTrans, operation);
            Map<string, object> addresses = PC_RestAPIUtilities.upsertAddresses(reqAddressesObjListTrans, providerId, operation, allOrNone, requestURL);
            // Create responseBody
            Map<string, object> rsBodyList = new  Map<string, object>();
            rsBodyList.put(PROVIDER_KEY, providerId);
            rsBodyList.put(ADDRESSES_KEY, addresses.get('ids'));
            if(allOrNone)
            {
            }
            // do not add errors, since there won't be any!
            else
            {
                Map<string, Map<string, string>> addressErrors = (Map<string, Map<string, string>>)addresses.get('errors');
                if(addressErrors != null && addressErrors.size() > 0)
                {
                    rsBodyList.put(ERRORS_KEY, addressErrors);
                }
            }
            res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
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
        Map<string, object> physicianMap = PC_RestAPIUtilities.transformSobject(account.getPopulatedFieldsAsMap(), PC_RestAPIConstants.REST_OBJECT_NAME_PROVIDER);
        List<PC_Address__c> patientAddresses = PC_RestAPIUtilities.getAddressesByAccountId(account.Id);
        List<Map<string, object>> patientAddressesMap = PC_RestAPIUtilities.transformSobjectAddresses(patientAddresses);
        physicianMap.put(ADDRESSES_KEY, patientAddressesMap);
        res.responseBody = Blob.valueOf(JSON.serialize(physicianMap));
    }
}