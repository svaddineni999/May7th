/*********************************************************************************************************
Class Name      : PC_PayerService
Description     : REST class for Payer object
Created By      : Deloitte
Created Date    : Aug 04, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Aug 04, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Rohit Kapoor                  Nov 22, 2017            <PC-2516> - Create a new GET payer service
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
****************************************************************************************************************/
/**
 * REST API class to retrieve Payers. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/payer/*' )
global with sharing class PC_PayerService
{
    static final string PAYER_KEY = 'payer';
    static final string PAYERS_KEY = 'payers';
    static final string GET_PARAM_FIND_BY_NAME = 'findByName';
    static final string GET_PARAM_FIND_BY = 'findBy';

    @HttpGet
    global static void doGet()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string reqString = req.requestURI;
        reqString = reqString.toLowerCase();
        string payerId = null;
        string payerName = null;
        string payerPhone = null;
        string name = null;
        list<Account> listOfAccounts = new list<Account>();
        Account account;
        try
        {
            Map<string, string> reqParameters = req.params;
            if(reqString.containsIgnoreCase(GET_PARAM_FIND_BY_NAME))
            {
                // Search by name
                name = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                name = name.replace('+', ' ');
                name = EncodingUtil.urlDecode(name, 'UTF-8');
                if(string.isNotBlank(name))
                {
                    listOfAccounts = PC_RestAPIUtilities.getPayerUsingURI(name, null);
                    getGETResponse(null, listOfAccounts[0]);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PAYER_FINDBYNAME_MISSING);
                }
            }
            else if(reqParameters.containsKey(GET_PARAM_FIND_BY))
            {
                Map<string, string> reqParams = new  Map<string, string>();
                if(string.isBlank(reqParameters.get(GET_PARAM_FIND_BY)))
                {
                    throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS),
                                            string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 
                                            PC_RestAPIConstants.INVALID_PARAMETERS);
                }
                else
                {
                    // Search by name
                    reqParams = PC_RestAPIUtilities.transformPayerReqParams(reqParameters);

                    if(reqParams.containsKey(PC_RestAPIConstants.PAYER_NAME_KEY))
                    {
                        payerName = reqParams.get(PC_RestAPIConstants.PAYER_NAME_KEY);
                        payerPhone = reqParams.get(PC_RestAPIConstants.PAYER_PHONE_KEY);
                        if(string.isBlank(payerName))
                        {
                            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), 
                                                    string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 
                                                    PC_RestAPIConstants.ERRORMESSAGE_PAYER_NAME_MISSING);
                        }
                        else
                        {
                            if(payerName.startsWith(PC_RestAPIConstants.PAYER_NAME_WILD_CHARACTER))
                            {
                                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS),
                                                string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 
                                                PC_RestAPIConstants.INVALID_PARAMETERS);
                            }
                            else if(payerName.length() < 3 )
                            {
                                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS),
                                            string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 
                                            PC_RestAPIConstants.ATLEAST_3_CHARACTERS_PAYER_NAME_REQD);
                            }
                            else{
                                listOfAccounts = PC_RestAPIUtilities.getPayerUsingURI(payerName,payerPhone);
                            }
                            getGETResponse(null, listOfAccounts);
                        }
                    }
                }
            }
            else
            {
                payerId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                if(string.isEmpty(payerId))
                {
                    //find all
                    listOfAccounts = PC_RestAPIUtilities.getAllPayers(1000);
                    getGETResponse(null, listOfAccounts);
                }
                else
                {
                    account = PC_RestAPIUtilities.getPayerById(payerId);
                    getGETResponse(null, account);
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
        Map<string, object> payerMap = PC_RestAPIUtilities.transformSobject(account.getPopulatedFieldsAsMap(), PC_RestAPIConstants.REST_OBJECT_NAME_PAYER);
        res.responseBody = Blob.valueOf(JSON.serialize(payerMap));
    }
    private static void getGETResponse(string getIdentifier, List<Account> accounts)
    {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        List<Map<string, object>> accounts_trans = PC_RestAPIUtilities.transformSobjectAccounts(accounts, PC_RestAPIConstants.REST_OBJECT_NAME_PAYER);
        Map<string, object> rs = new  Map<string, object>();
        rs.put(PAYERS_KEY, accounts_trans);
        res.responseBody = Blob.valueOf(JSON.serialize(rs));
    }
}