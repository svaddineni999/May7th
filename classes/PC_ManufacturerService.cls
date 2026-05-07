/*********************************************************************************************************
Class Name      : PC_ManufacturerService
Description     : REST class for Manufacturer object
Created By      : Deloitte
Created Date    : Aug 04, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Aug 04, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Subham Agarwal                 Nov 20, 2017           Added code to decode the input paramters.
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
Vijay Kashikar                 Jan 25, 2018           <PC-2663> - Constants renamed.
****************************************************************************************************************/
/**
 * REST API class to retrieve Manufacturers. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/manufacturer/*' )
global with sharing class PC_ManufacturerService
{
    static final string MANUFACTURER_KEY = 'manufacturer';
    static final string MANUFACTURERS_KEY = 'manufacturers';
    static final string GET_PARAM_FIND_BY_NAME = 'findByName';
    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string reqString = req.requestURI;
        reqString = reqString.toLowerCase();
        string manufacturerId = null;
        string accName = null;
        Account acc;
        try
        {
            if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_NAME))
            {
                // Search by name
                accName = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
				accName = EncodingUtil.urlDecode(accName, 'UTF-8');
                if(string.isNotBlank(accName))
                {
                    accName = accName.replace('+', ' ');
                    acc = PC_RestAPIUtilities.getManufacturerByName(accName);
                    getGETResponse(null, acc);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_MANUFACTURER_FINDBYNAME_MISSING);
                }
            }
            else
            {
                manufacturerId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                if(string.isEmpty(manufacturerId))
                {
                    // get all manufacturers
                    List<Account> accs = PC_RestAPIUtilities.getAllManufacturers(1000);
                    getGETResponse(null, accs);
                }
                else
                {
                    acc = PC_RestAPIUtilities.getManufacturerById(manufacturerId);
                    getGETResponse(null, acc);
                }
            }
        }
        catch(Exception e)
        {
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }
    private static void getGETResponse(string getIdentifier, Account account)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Map<string, object> patientMap = PC_RestAPIUtilities.transformSobject(account.getPopulatedFieldsAsMap(), PC_RestAPIConstants.REST_OBJECT_NAME_MANUFACTURER);
        res.responseBody = Blob.valueOf(JSON.serialize(patientMap));
    }
    private static void getGETResponse(string getIdentifier, List<Account> accounts)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> accounts_trans = PC_RestAPIUtilities.transformSobjectAccounts(accounts, PC_RestAPIConstants.REST_OBJECT_NAME_MANUFACTURER);
        Map<string, object> rs = new  Map<string, object>();
        rs.put(MANUFACTURERS_KEY, accounts_trans);
        res.responseBody = Blob.valueOf(JSON.serialize(rs));
    }
}