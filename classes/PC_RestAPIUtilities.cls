/***********************************************************************************************************************
Modification Log:
------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
------------------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Jul 27, 2017           Initial Version
Subham Agarwal                 Nov 07, 2017           <PC-2468> Code Refactoring
Subham Agarwal                 Nov 14, 2017           <PC-2494> - Methods added - getHealthPlansByAccountIds, getAddressesByAccountIds
Rohit Kapoor                   Nov 19, 2017           <PC-2499> - methods added - getProgramCoveragesByProgramId, getProgramCoverageByProgramId,
                                                       getProgramCoverageById, getRecordTypeForProgramCoverage, upsertProgCoverage, 
                                                       upsertProgramCoverage,removeNonProgramCoverageFields, transformSobject(listOfSObject, restObjectName)
Rohit Kapoor                   Nov 22, 2017            <PC-2516> - Create a new GET payer service
Rohit Kapoor                   Nov 23, 2017            <PC-2516> - modify castFieldValueBasedOnType() added fieldType =percent & currency
Rohit Kapoor                   DEC 08, 2017            <PC-2498> -  PC-2498 As an external system (mobile/web application), I want to retrieve basic patient information
Vijay Kashikar         		   Dec 12, 2017            PC-2615 Technical - Prefix namespace to the static mappings in REST API
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
Vijay Kashikar                 Jan 11, 2018           <PC-2712> - Remove global scope for some of the methods. Added comments to global methods.
Vijay Kashikar                 Nov 20, 2018           <PC-3649> - Added a check to see if the current user has health cloud permission sets before creating or updating the patient record.
Haritha Reddy                  Jan 22, 2019           <PC-4248> - Added logic to get Account Record Type from Individual Record Type Mapper for provided patientClass in PC_PatientService
Mike Klumpenaar                Feb 20, 2019            PC-4475] Make class and subset of methods global and convert to apex doc.
Vijay Kashikar                 Mar 29, 2019           <PC-2646> - Added limit cluse to patient service SOSL
Vijay Kashikar                 May 29, 2019           <PC-4903> - Updated getRecordType method to support handling of non PC record types
Shishir Bansal                 23-10-2019             [PC-5613 ] udpated the compare condtion on mepkey with innerkey (PC_ADverseEvent2__c)
Haritha Reddy                  May 05,2020            [PC-6249] Added limit to the SOQL queries
Vijay Kashikar                 Nov 06, 2020           [PC-6783] Handled null record type id in upsertAccount
Haritha Reddy                  21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Hitha Avalakki                 Feb 23, 2021             [PC-7442] Replaced the use of RecordTypeId with 'Type' field of Case object to decide if its a program case record
Hitha Avalakki                 Feb 26, 2021              [PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
Hitha Avalakki                 Mar 04, 2021              [PC-7442] Replaced PC_System.getProgramCaseRecordType() with PC_System.getDefaultProgramCaseRecordTypeId()
Hitha Avalakki                 Mar 04,2021               [PC-6067] Replaced fetchCaseRecTypeOnEngagementProg(String engagementProgId) to PC_SYSTEM.getProgramRecordTypeIdBasedOnEngProgramId(String engagementProgId)
Hitha Avalakki                 Mar 19, 2021              [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Haritha Reddy                  Jun 08, 2021              [PC-7683] Added a method 'getAccounts' to fetch Accounts based on query params
Haritha Reddy                  Jun 14, 2021              [PC-7388] Added new methods to get engagement program by id and to get self service settings
Haritha Reddy                  Jun 16, 2021              [PC-7387] Added new method to get interactions based on query parameters
Haritha Reddy                  Jul 05, 2021              <PC-7878> Added new methods to support fetching Reference fields
Haritha Reddy                  Jul 06, 2021              [PC-7879] Added new method to perform update operation on Interaction
***********************************************************************************************************************/
/**
 * Utility class for REST API classes
 *
 * @date 2017-07-27
 */
global inherited sharing class PC_RestAPIUtilities
{
    private static Map<string, object> mappings = null;
    private static Map<string, Map<string, string>> objectFieldMappings_mdt_map = new  Map<string, Map<string, string>>();

    public static Boolean getAllOrNone(RestRequest req)
    {
        Boolean isAllOrNoneCase = true;
        Map<string, string> parameters = req.params;
        system.debug('Total query parameters = ' + parameters.size());
        system.debug('Checking for AllOrNone parameter ' + PC_RestAPIConstants.QUERYPARAMETER_ALL_OR_NONE);
        if(parameters.containsKey(PC_RestAPIConstants.QUERYPARAMETER_ALL_OR_NONE))
        {
            string allOrNoneValue = parameters.get(PC_RestAPIConstants.QUERYPARAMETER_ALL_OR_NONE);
            system.debug('All or none value found and is =  ' + allOrNoneValue);
            if(allOrNoneValue == PC_Constants.TRUE_STRING || allOrNoneValue == PC_Constants.FALSE_STRING)
            {
                isAllOrNoneCase = Boolean.valueOf(allOrNoneValue);
            }
            else
            {
                // throw exception
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.QUERYPARAMETER_ALL_OR_NONE + ' : ' + PC_RestAPIConstants.ErrorMessage_INVALID_QUERY_PARAMETER);
            }
        }
        system.debug('Final All or none value = ' + isAllOrNoneCase);
        return isAllOrNoneCase;
    }

    /**
     * Method to get the absolute request URL
     * @param req - type RestRequest object
     * @return Returns aboslute request URL
     */
    global static string getRequestURL(RestRequest req)
    {
        string requestURL = PC_Constants.EMPTY_STRING;
        string queryString = PC_Constants.EMPTY_STRING;
        Map<string, string> parameters = req.params;
        for(string key: parameters.keySet())
        {
            if(string.isBlank(queryString))
            {
                queryString = queryString + '/?' + key + PC_Constants.PC_EQUALS_SYMBOL + parameters.get(key);
            }
            else
            {
                queryString = queryString + '&' + key + PC_Constants.PC_EQUALS_SYMBOL + parameters.get(key);
            }
        }
        requestURL = req.requestURI + queryString;
        return requestURL;
    }
    /**
     * Method to get the Account record.
     * @param accountId Salesforce accountId of the record
     * @param recordTypeDevName Record Type Developer Name
     * @param restObjectName REST object name of Account eg. patient, provider etc
     * @return Returns Account object with all the fields that are configured for the restObjectName
     */
    global static Account getAccount(string accountId, string recordTypeDevName, string restObjectName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM Account ' + ' WHERE ' + 'Id = ' + '\'' + accountId + '\'' + ' and ' + ' RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\'' + recordTypeDevName + '\'' + ' and  SobjectType = ' + '\'Account\'' + ')';
        system.debug(query);
        List<sObject> accounts = PC_Database.queryWithAccess(query, true);
        if(accounts != null && !accounts.isEmpty())
        {
            return (Account)accounts[0];
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ACCOUNT_NO_ACCOUNT_FOUND);
        }
    }

    /**
     * Method to get all Accounts
     *
     * @param recordTypeDevName Record Type Developer Name
     * @param restObjectName REST object name of Account eg. patient, provider etc
     * @param recordLimit Integer value to limit the number of records to be fetched.
     *
     * @return Returns list of accounts with all the fields that are configured for restObjectName
     */
    global static List<Account> getAllAccounts(string recordTypeDevName, string restObjectName, integer recordLimit)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM Account ' + ' WHERE ' + ' RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\'' + recordTypeDevName + '\'' + ' and  SobjectType = ' + '\'Account\'' + ')' + ' LIMIT ' + recordLimit;
        system.debug(query);
        List<sObject> accounts = PC_Database.queryWithAccess(query, true);
        if(accounts != null && !accounts.isEmpty())
        {
            return (List<Account>)accounts;
        }
        else
        {
            return new  List<Account>();
        }
    }

    /**
     * Method to get patient by ID
     *
     * @param patientId Salesforce ID of the patient
     *
     * @return Returns patient object with all the fields that are configured for the patient REST object
     */
    global static Account getPatientById(string patientId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_PATIENT);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM Account WHERE Id = ' + '\'' + patientId + '\'' + ' and RecordTypeId IN ' + getPatientRecordTypesList();
        system.debug(query);
        List<sObject> accounts = PC_Database.queryWithAccess(query, true);
        if(accounts != null && !accounts.isEmpty())
        {
            return (Account)accounts[0];
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ACCOUNT_NO_ACCOUNT_FOUND);
        }

    }

    /**
     * Method to get order item by ID
     *
     * @param orderItemId Salesforce ID of the order item
     * @param orderNumber Order Number of the associated order
     * @param productId Salesforce ID of the associated product
     *
     * @return Returns order item object with all the fields that are configured for the order item REST object
     */
    public static List<PC_OrderItem__c> getOrderItems(string orderItemId, string orderNumber, String productId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_OrderItem);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string orderItemAPIName = PC_Constants.getQualifiedAPIName
                (PC_RestAPIConstants.REST_OBJECT_TO_SOBJECT_MAPPING.get(PC_RestAPIConstants.REST_OBJECT_NAME_OrderItem));
        Map<String, String> whereClause = new Map<String, String>();
        if(String.isNotBlank(orderNumber)) {
            whereClause.put(PC_Constants.getQualifiedAPIName('PC_Order__r') + '.Name', orderNumber);
        }
        if(String.isNotBlank(productId)) {
            whereClause.put(PC_Constants.getQualifiedAPIName('PC_Product__c'), productId);
        }
        if(String.isNotBlank(orderItemId)) {
            whereClause.put('id', orderItemId);
        }

        String whereClauseString = '';
        for(String key : whereClause.keySet()) {
            if(String.isBlank(whereClauseString)) {
                whereClauseString =
                        key + ' = ' + '\'' + whereClause.get(key) + '\'';
            }
            else {
                whereClauseString +=
                        ' AND ' + key + ' = ' + '\'' + whereClause.get(key) + '\'';
            }

        }
        if(!whereClause.isEmpty()) {
            string query = 'SELECT ' + queryFields + ' FROM ' + orderItemAPIName + ' WHERE ' + whereClauseString + ' LIMIT 1000';
            system.debug(query);
            List<sObject> orderItems = PC_Database.queryWithAccess(query, true);
            if (orderItems != null && !orderItems.isEmpty()) {
                return (List<PC_OrderItem__c>) orderItems;
            }
        }
        return null;

    }

    /**
     * Method to get order
     *
     * @param orderItemId Salesforce ID of the order item
     * @param orderNumber Order Number of the associated order
     * @param productId Salesforce ID of the associated product
     * @param orderSubmittedDate Date on which the order was submitted
     *
     * @return Returns order item object with all the fields that are configured for the order item REST object
     */
    public static List<PC_Order__c> getOrders(string orderId, string orderNumber, String programId, String orderSubmittedDate)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_Order);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string orderAPIName = PC_Constants.getQualifiedAPIName
                (PC_RestAPIConstants.REST_OBJECT_TO_SOBJECT_MAPPING.get(PC_RestAPIConstants.REST_OBJECT_NAME_Order));
        Map<String, String> whereClause = new Map<String, String>();
        if(String.isNotBlank(orderNumber)) {
            whereClause.put('Name', orderNumber);
        }
        if(String.isNotBlank(programId)) {
            whereClause.put(PC_Constants.getQualifiedAPIName('PC_ProgramCase__c'), programId);
        }
        if(String.isNotBlank(orderId)) {
            whereClause.put('id', orderId);
        }
        if(String.isNotBlank(orderSubmittedDate)) {
            whereClause.put('DAY_ONLY' + '(' + PC_Constants.getQualifiedAPIName('PC_SubmittedDate__c') + ')', orderSubmittedDate);
        }

        String whereClauseString = '';
        String prefix = '';
        String suffix = '';
        for(String key : whereClause.keySet()) {
            prefix = '';
            suffix = '';
            if(!key.contains('PC_SubmittedDate__c')) {
                prefix = '\'';
                suffix = '\'';
            }
            if(String.isBlank(whereClauseString)) {
                whereClauseString =
                        key + ' = ' + prefix + whereClause.get(key) + suffix;
            }
            else {
                whereClauseString +=
                        ' AND ' + key + ' = ' + prefix + whereClause.get(key) + suffix;
            }

        }
        system.debug('whereClause = ' + whereClauseString);
        if(!whereClause.isEmpty()) {
            string query = 'SELECT ' + queryFields + ' FROM ' + orderAPIName + ' WHERE ' + whereClauseString + ' LIMIT 1000';
            system.debug(query);
            List<sObject> orders = PC_Database.queryWithAccess(query, true);
            if (orders != null && !orders.isEmpty()) {
                return (List<PC_Order__c>) orders;
            } else {
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.NO_RECORD_FOUND);
            }
        }
        return null;

    }

    /**
     * Method to delete association by ID
     *
     * @param associationId Salesforce ID of the association
     *
     * @return Returns association object that was deleted
     */
    global static PC_Association__c deleteAssociationById(string associationId)
    {
        PC_Association__c association = [Select ID from PC_Association__c where Id = :associationId Limit 1];
        return (PC_Association__c) PC_Database.del(association);
    }

    /**
     * Method to get all the accounts via SOSL query
     *
     * @param patientFieldValues Map of FIELD API name with the value
     * @param recordTypeDevName Record Type Developer Name
     *
     * @return List of Account object matching the criteria passed in patientFieldValues
     */
    global static List<Account> getAccountsViaSOSL(Map<string, string> patientFieldValues, string recordTypeDevName)
    {
        string searchQueryWhereClause = PC_Constants.EMPTY_STRING;
        string searchQueryWhereClausePart = PC_Constants.EMPTY_STRING;
        List<string> values = new  List<string>();
        for(string key: patientFieldValues.keySet())
        {
            searchQueryWhereClausePart = ' ' + string.escapeSingleQuotes(key) + ' = ' + '\'' + string.escapeSingleQuotes(patientFieldValues.get(key)) + '\'';
            
            if(string.isEmpty(searchQueryWhereClause))
            {
                searchQueryWhereClause = searchQueryWhereClausePart;
            }
            else
            {
                searchQueryWhereClause = searchQueryWhereClause + ' AND ' + searchQueryWhereClausePart;
            }
            if(string.isNotEmpty(patientFieldValues.get(key)))
            {
                values.add('"' + patientFieldValues.get(key) + '"');
            }
        }
       
        if(string.isBlank(searchQueryWhereClause))
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.SOQL_LIMITATION), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'Cannot perform patient search without WHERE clause. Aborting...');
        }
        List<string> fields = new  List<string>();
        fields.addAll(patientFieldValues.keySet());
        string queryFields = string.join(fields, ',');
        queryFields = string.escapeSingleQuotes(queryFields);
        system.debug('@pc -> queryfields = ' + queryFields);
        string searchWords = string.join(values, ' AND ');
        searchWords = string.escapeSingleQuotes(searchWords);
        string searchQuery = 'FIND ' + '{' + searchWords + '}' + ' IN ALL FIELDS RETURNING Account ' + ' ( ' + queryFields + ' WHERE ' + ' RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\'' + recordTypeDevName + '\'' + ' and  SobjectType = ' + '\'Account\'' + ') ' + ' ) ' + ' LIMIT 1000';
        system.debug('@RestAPIUtilities -> ' + 'searchQuery -> ' + searchQuery);
        List<List<sObject>> searchResults = search.query(searchQuery);
        List<Account> accounts = searchResults[0];
        return accounts;
    }

    /**
     * Method to get all the program cases for a patient
     *
     * @param patientId Salesforce ID of the patient
     *
     * @return List of program cases for the patient.
     */
    global static List<Case> getCaseProgramsByPatientId(string patientId)
    {
        /* [PC-7442] Replaced the use of RecordTypeId with 'Type' field of Case object to decide if its a program case record */
        return getProgramCasesByPatientId(patientId);
    }

    /**********************************************************************************************
    Method Name    : getProgramCasesByPatientId
    Description    : PC-7442 Get the Program cases for a patient record
    Return Type    : List<Case>
    **********************************************************************************************/
    public static List<Case> getProgramCasesByPatientId(string patientId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
        List<string> fields = new  List<string>();
        String programCaseType = PC_Constants.CASE_PROGRAM_TYPE;
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM Case WHERE AccountId = ' + '\'' + patientId + '\'' + ' and Type=\''+ programCaseType +'\'';
        system.debug(query);
        List<sObject> programCases = PC_Database.queryWithAccess(query, true);
        if(programCases != null && !programCases.isEmpty())
        {
            return (List<Case>)programCases;
        }
        else
        {
            return new  List<Case>();
        }
    }

    /**
     * Method to get all the cases for a patient
     *
     * @param patientId Salesforce ID of the patient
     * @param recordTypeDevName Record Type Developer Name
     *
     * @return List of Cases for the patient
     */
    global static List<Case> getCasesByPatientId(string patientId, string recordTypeDevName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + ' Case ' + +' WHERE ' + ' AccountId = ' + '\'' + patientId + '\'' + ' and ' + ' RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\'' + recordTypeDevName + '\'' + ' and  SobjectType = ' + '\'Case\'' + ')';
        system.debug(query);
        List<sObject> programCases = PC_Database.queryWithAccess(query, true);
        if(programCases != null && !programCases.isEmpty())
        {
            return (List<Case>)programCases;
        }
        else
        {
            return new  List<Case>();
        }
    }

    /**
     * Method to get all the cases by program (PC_Program__c) id
     *
     * @param programId Salesforce id of the program (PC_Program__c)
     *
     * @return List of cases
     */
    global static List<Case> getCasesByProgramId(string programId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + ' Case ' + +' WHERE ' + ' PC_Program__c = ' + '\'' + programId + '\'';
        //+ ' and ' 
        //+ ' RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\'' + recordTypeDevName + '\'' + ')';
        system.debug(query);
        List<sObject> programCases = PC_Database.queryWithAccess(query, true);
        if(programCases != null && !programCases.isEmpty())
        {
            return (List<Case>)programCases;
        }
        else
        {
            return new  List<Case>();
        }
    }

    /**
     * Method to get address by ID
     *
     * @param addressId Salesforce ID of the address record.
     *
     * @return Address record
     */
    global static PC_Address__c getAddress(string addressId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Address__c') + +' WHERE ' + ' Id = ' + '\'' + addressId + '\'';
        system.debug(query);
        List<sObject> addresses = PC_Database.queryWithAccess(query, true);
        if(addresses != null && !addresses.isEmpty())
        {
            return (PC_Address__c)addresses[0];
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ADDRESS_NO_ADDRESS_FOUND);
        }
    }

    /**
     * Method to get all the address for an account ID
     *
     * @param accountId Salesforce ID of the account
     *
     * @return List of addresses for the account.
     */
    global static List<PC_Address__c> getAddressesByAccountId(string accountId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Address__c') + +' WHERE ' + ' PC_Account__c = ' + '\'' + accountId + '\'';
        system.debug(query);
        List<sObject> addresses = PC_Database.queryWithAccess(query, true);
        if(addresses != null && !addresses.isEmpty())
        {
            return (List<PC_Address__c>)addresses;
        }
        else
        {
            return new  List<PC_Address__c>();
        }
    }

    /**
     * Method to get address for the given set of account Ids
     *
     * @param accountIds Set of Account IDs
     *
     * @return Map of account Ids with their list of addresses.
     */
    global static Map<string, List<PC_Address__c>> getAddressesByAccountIds(Set<Id> accountIds)
    {
        string strIds = string.valueOf(accountIds);
        strIds = strIds.replace(',', '\',\'');
        strIds = strIds.replace('{', '(\'');
        strIds = strIds.replace('}', '\')');
        strIds = strIds.replace(' ', '');
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Address__c') + +' WHERE ' + ' PC_Account__c in ' + strIds;
        system.debug(query);
        Map<string, List<PC_Address__c>> mapPatientAddresses = new  Map<string, List<PC_Address__c>>();
        List<sObject> addresses = PC_Database.queryWithAccess(query, true);
        if(addresses != null && !addresses.isEmpty())
        {
            for(PC_Address__c objAddress: (List<PC_Address__c>)addresses)
            {
                if(mapPatientAddresses != null && mapPatientAddresses.containsKey(objAddress.PC_Account__c))
                {
                    List<PC_Address__c> addressList = mapPatientAddresses.get(objAddress.PC_Account__c);
                    addressList.add(objAddress);
                    mapPatientAddresses.put(objAddress.PC_Account__c, addressList);
                }
                else
                {
                    List<PC_Address__c> addressList = new  list<PC_Address__c>();
                    addressList.add(objAddress);
                    mapPatientAddresses.put(objAddress.PC_Account__c, addressList);
                }
            }
        }
        return mapPatientAddresses;
    }

    /**
     * Method to get provider account record
     *
     * @param providerId Salesforce ID of the provider account
     *
     * @return Provider Account
     */
    global static Account getProviderById(string providerId)
    {
        return getAccount(providerId, PC_Constants.PHYSICIAN_RECORD_TYPE, PC_RestAPIConstants.REST_OBJECT_NAME_PROVIDER);
    }

    /**
     * Method to get Accounts by Phone number
     *
     * @param requestParameters Rest API request parameters
     * @param hasPatientClass Set to true if request has Patient class Query parameter
     * @param patientClassValue value set to Patient class key
     *
     * @return Patient Accounts
     */
    public static List<Account> getAccounts(Map<string, string> requestParameters, Boolean hasPatientClass, String patientClassValue) {
        List<Account> filteredAccounts = new List<Account>();
        Map<string, string> reqParams = prepareReqParamMap(requestParameters);
        if(!reqParams.isEmpty()){
            String restObjectName = PC_RestAPIConstants.REST_OBJECT_NAME_ACCOUNT;
            Map<string, string> mapFieldMappings = PC_RestAPIUtilities.getRESTFieldMappingsMap(restObjectName);
            for (string key : reqParams.keySet()) {
                //throw exception if mapping is not defined
                if (!mapFieldMappings.containsKey(key)) {
                    throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_FIELD_MAPPING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'Rest field mapping is missing for ' + key + ' in ' + +restObjectName + +' info.');
                }
            }
            Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ACCOUNT);
            List<string> fields = new List<string>();
            fields.addAll(fieldMappings_mdt_map.keySet());
            string queryFields = string.join(fields, ',');

            string whereClause = PC_Constants.EMPTY_STRING;
            if (hasPatientClass && string.isNotBlank(patientClassValue)) {
                String patientRecordTypes = '(\'' + PC_RestAPIUtilities.getPatientRecordType(patientClassValue) + '\')';
                whereClause = ' WHERE RecordTypeId IN ' + patientRecordTypes;
            }

            List<string> listStr = mapFieldMappings.values();
            string str = JSON.serialize(listStr);
            str = str.replace('","', ',');
            str = str.replace('["', '');
            str = str.replace('"]', '');

            String phoneQueryParamValue = string.valueOf(reqParams.get(PC_RestAPIConstants.PATIENT_PHONE_KEY)).replaceAll('[^0-9]', '');
            string strSearchString = '\'' + phoneQueryParamValue+ '\'';
            String limitQuery = ' LIMIT 100';
            LIST<LIST<sObject>> lstAccounts = search.query('FIND :strSearchString IN ALL FIELDS RETURNING Account(' + str + whereClause + limitQuery +  ')');
            if(Test.isRunningTest()){
                List<Account> lstAccountTest = Database.query('select '+str+' from account '+whereClause);
                lstAccounts[0] = lstAccountTest;
            }
            for(Account account: ((List<Account>)lstAccounts[0])){
                //filter accounts based on phone number
                if(reqParams.containsKey(PC_RestAPIConstants.PATIENT_PHONE_KEY)){
                    Object phoneFieldValue = account.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_PHONE_KEY));
                    if(phoneFieldValue != null && phoneFieldValue != '' && phoneFieldValue != ' ') {
                        String accountPhone = string.valueOf(phoneFieldValue).replaceAll( '[^0-9]', '' );
                        if(accountPhone.contains(phoneQueryParamValue) || phoneQueryParamValue.contains(accountPhone)){
                            filteredAccounts.add(account);
                        }
                    }
                }
            }
        } else {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ACCOUNT_FILTERS_MISSING);
        }
        return filteredAccounts;
    }

    /**
     * Method to get provider by NPI
     *
     * @param npi NPI of the provider
     *
     * @return Provider Account
     */
    global static Account getProviderByNpi(string npi)
    {
        string recordTypeDevName = PC_Constants.PHYSICIAN_RECORD_TYPE;
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_PROVIDER);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM Account ' + ' WHERE ' + ' PC_NPI__c = ' + '\'' + npi + '\'' + ' and ' + ' RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\'' + recordTypeDevName + '\'' + ' and  SobjectType = ' + '\'Account\'' + ')';
        system.debug(query);
        List<sObject> accounts = PC_Database.queryWithAccess(query, true);
        if(accounts != null && !accounts.isEmpty())
        {
            return (Account)accounts[0];
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.PROVIDER_NO_PROVIDER_FOUND);
        }
    }

    /**
     * Method to get payer account by payer ID
     *
     * @param payerId Saleforce ID of the payer
     *
     * @return Payer Account
     */
    global static Account getPayerById(string payerId)
    {
        return getAccount(payerId, PC_Constants.PAYER_RECORD_TYPE, PC_RestAPIConstants.REST_OBJECT_NAME_PAYER);
    }
    
    /*********************************************************************************
    Method Name    : transformPayerReqParams
    Description    : PC-2516 - Create new service for Payer
    parameters     : map<string, string>
    Return Type    : map<string, string>
    *********************************************************************************/
    public static map<string, string> transformPayerReqParams(map<string, string> reqParameters)
    {
        Map<string, string> reqParams = new  Map<string, string>();
        map<string, string> resultParamsMap = new map<string, string>();
        string GET_PARAM_FIND_BY = 'findBy';
        string payerName = null;
        string payerPhone = null;
        if(reqParameters != null && !reqParameters.isEmpty())
        {
            for(string key: reqParameters.keySet())
            {
                reqParams.put(key, string.escapeSingleQuotes(reqParameters.get(key)));
            }
            
        }
        
        string findByValueKey = reqParams.get(GET_PARAM_FIND_BY);
        
        if(findByValueKey == PC_RestAPIConstants.PAYER_NAME_KEY)
        {
            if(reqParams.containsKey(PC_RestAPIConstants.PAYER_NAME_KEY) 
                && reqParams.get(PC_RestAPIConstants.PAYER_NAME_KEY) != null)  
            {
                payerName = string.valueOf(reqParams.get(PC_RestAPIConstants.PAYER_NAME_KEY));
                payerName = payerName.replace('+', ' ');
                payerName = EncodingUtil.urlDecode(payerName, 'UTF-8');
            }
            resultParamsMap.put(PC_RestAPIConstants.PAYER_NAME_KEY, payerName);
        }
        
        if(reqParams.containsKey(PC_RestAPIConstants.PAYER_PHONE_KEY) 
            && reqParams.get(PC_RestAPIConstants.PAYER_PHONE_KEY) != null)  
        {
            payerPhone =  string.valueOf(reqParams.get(PC_RestAPIConstants.PAYER_PHONE_KEY));
            payerPhone = payerPhone.replaceAll(PC_RestAPIConstants.REGULAREXP_ONLY_DIGITS, PC_Constants.EMPTY_STRING);
            payerPhone = payerPhone.trim();
        }

        resultParamsMap.put(PC_RestAPIConstants.PAYER_PHONE_KEY, payerPhone);

        return resultParamsMap;
    }
    /*********************************************************************************
    Method Name    : getPayerUsingURI
    Description    : PC-2516 - Create new service for Payer
    parameters     : string Name, string Phone
    Return Type    : list<Account>    
    *********************************************************************************/
    public static list<Account> getPayerUsingURI(string reqName, string reqPhone)
    {
        string recordTypeDevName = PC_Constants.PAYER_RECORD_TYPE;
        Map<string, string> fieldValues = new  Map<string, string>();
        
        fieldValues.put('NAME', reqName);
        if(string.isNotBlank(reqPhone))
        {
            fieldValues.put('PHONE', reqPhone);
        }
        Map<string, string> fieldMappings_mdt_trans = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_PAYER);
        for(string key: fieldMappings_mdt_trans.keySet())
        {
            if(fieldMappings_mdt_trans.get(key).toUpperCase() == 'NAME' 
                || fieldMappings_mdt_trans.get(key).toUpperCase() == 'PHONE' )
            {
            }
            else
            {
                fieldValues.put(key, PC_Constants.EMPTY_STRING);
            }
        }
        
        List<Account> accs = PC_RestAPIUtilities.getAccountsViaSOSL(fieldValues, recordTypeDevName);
        if(accs != null && !accs.isEmpty())
        {
            return accs;
        }
        else
        {
            return null;
        }
    }

    /**
     * Method to get Manufacturer by it's ID
     *
     * @param manufacturerId Salesforce ID of the manufacturer
     *
     * @return Manufacturer account
     */
    global static Account getManufacturerById(string manufacturerId)
    {
        return getAccount(manufacturerId, PC_Constants.MANUFACTURER_RECORD_TYPE, PC_RestAPIConstants.REST_OBJECT_NAME_MANUFACTURER);
    }

    /**
     * Method to get all Manufacturers
     *
     * @param recordLimit Number of recrods to fetch
     *
     * @return List of Manufacturer accounts
     */
    global static List<Account> getAllManufacturers(integer recordLimit)
    {
        return getAllAccounts(PC_Constants.MANUFACTURER_RECORD_TYPE, PC_RestAPIConstants.REST_OBJECT_NAME_MANUFACTURER, recordLimit);
    }

    /**
     * Method to get all payers
     *
     * @param recordLimit Number of records to fetch
     *
     * @return List of Payer accounts
     */
    global static List<Account> getAllPayers(integer recordLimit)
    {
        return getAllAccounts(PC_Constants.PAYER_RECORD_TYPE, PC_RestAPIConstants.REST_OBJECT_NAME_PAYER, recordLimit);
    }

    /**
     * Method to get manufacturer by name. Makes use of SOSL query.
     *
     * @param name Name of the manufacturer
     *
     * @return Manufacturer account
     */
    global static Account getManufacturerByName(string name)
    {
        string recordTypeDevName = PC_Constants.MANUFACTURER_RECORD_TYPE;
        Map<string, string> fieldValues = new  Map<string, string>();
        fieldValues.put('NAME', name);
        Map<string, string> fieldMappings_mdt_trans = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_MANUFACTURER);
        for(string key: fieldMappings_mdt_trans.keySet())
        {
            system.debug('key = ' + key + ' :::::  value = ' + fieldMappings_mdt_trans.get(key));
            if(fieldMappings_mdt_trans.get(key).toUpperCase() == 'NAME')
            {
            }
            else
            {
                fieldValues.put(key, PC_Constants.EMPTY_STRING);
            }
        }
        List<Account> accs = PC_RestAPIUtilities.getAccountsViaSOSL(fieldValues, recordTypeDevName);
        if(accs != null && !accs.isEmpty())
        {
            return accs[0];
        }
        else
        {
            return null;
        }
    }

    /**
     * Method to get program case associations by caseId
     *
     * @param caseId Salesforce ID of the case.
     *
     * @return List of associations
     */
    global static List<PC_Association__c> getProgramCaseAssociations(string caseId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ASSOCIATION);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Association__c') + +' WHERE ' + ' PC_Program__c = ' + '\'' + caseId + '\'';
        system.debug(query);
        List<sObject> associations = PC_Database.queryWithAccess(query, true);
        if(associations != null && !associations.isEmpty())
        {
            return (List<PC_Association__c>)associations;
        }
        else
        {
            return new  List<PC_Association__c>();
        }
    }


    /**
    * Method to get adverse Event related suspect prescriptions by adverseEventId
    *
    * @param adverseEventId Salesforce ID .
    *
    * @return List of Suspect Prescriptions
    */
    global static List<PC_Suspect_Prescription__c> getAdverseEventSuspectPrescriptions(string adverseEventId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_SUSPECT_PRESCRIPTION);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c') + +' WHERE ' + ' PC_Adverse_Event__c = ' + '\'' + adverseEventId + '\'';
        system.debug(query);
        List<sObject> suspectPrescriptions = PC_Database.queryWithAccess(query, true);
        if(suspectPrescriptions != null && !suspectPrescriptions.isEmpty())
        {
            return (List<PC_Suspect_Prescription__c>)suspectPrescriptions;
        }
        else
        {
            return new  List<PC_Suspect_Prescription__c>();
        }
    }
    /**
    * Method to get adverse Event related suspect prescriptions by adverseEventId
    *
    * @param adverseEventId Salesforce ID .
    *
    * @return List of Suspect Prescriptions
    */
    global static List<PC_Suspect_Prescription__c> getAdverseEvent2SuspectPrescriptions(string adverseEventId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_SUSPECT_PRESCRIPTION);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c') + +' WHERE ' + ' PC_Adverse_Event2__c = ' + '\'' + adverseEventId + '\'';
        system.debug(query);
        List<sObject> suspectPrescriptions = PC_Database.queryWithAccess(query, true);
        if(suspectPrescriptions != null && !suspectPrescriptions.isEmpty())
        {
            return (List<PC_Suspect_Prescription__c>)suspectPrescriptions;
        }
        else
        {
            return new  List<PC_Suspect_Prescription__c>();
        }
    }

    /**
     * Get all support cases for a given case Id
     *
     * @param caseId
     *
     * @return List of cases
     */
    global static List<Case> getSupportCases(string caseId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_CASE_PROGRAM);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + ' Case ' + +' WHERE ' + ' PC_Program__c = ' + '\'' + caseId + '\'';
        system.debug(query);
        List<sObject> supportCases = PC_Database.queryWithAccess(query, true);
        if(supportCases != null && !supportCases.isEmpty())
        {
            return (List<Case>)supportCases;
        }
        else
        {
            return new  List<Case>();
        }
    }

    /**
     * Method to get health plan by ID
     *
     * @param healthPlanId Salesforce ID of the health plan
     *
     * @return Health plan record
     */
    global static PC_Health_Plan__c getHealthPlan(string healthPlanId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Health_Plan__c') + +' WHERE ' + ' Id = ' + '\'' + healthPlanId + '\'';
        system.debug(query);
        List<sObject> healthPlans = PC_Database.queryWithAccess(query, true);
        if(healthPlans != null && !healthPlans.isEmpty())
        {
            return (PC_Health_Plan__c)healthPlans[0];
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.HEALTHPLAN_NO_HEALTHPLAN_FOUND);
        }
    }



     /**
    * Method to get adverse events by patient Id
    *
    * @param patient Id
    *
    * @return List of adverseEvents related to patient Id
    */
    global static List<PC_AdverseEvent__c> getAdverseEvents(String patientId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT);

        system.debug('fieldMappings_mdt_map-->'+fieldMappings_mdt_map);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        //string caseIdListParam =  string.join(caseIdList, ',');
        //system.debug('caseIdListParam-->'+caseIdListParam);
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c') + +' WHERE ' + ' PC_Patient__c =' +'\'' +patientId + '\'';
        system.debug(query);
        List<sObject> adverseEvents = PC_Database.queryWithAccess(query, true);
        if(adverseEvents != null && !adverseEvents.isEmpty())
        {
            return (List<PC_AdverseEvent__c>)adverseEvents;
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS),
                    string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                    PC_RestAPIConstants.ADVERSEEVENT_NO_ADVERSEEVENTS_FOUND);
        }
    }

     /**
    * Method to get adverse events by patient Id
    *
    * @param patient Id
    *
    * @return List of adverseEvents related to patient Id
    */
    global static List<PC_AdverseEvent2__c> getAdverseEvents2(String patientId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT2);

        system.debug('fieldMappings_mdt_map-->'+fieldMappings_mdt_map);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        //string caseIdListParam =  string.join(caseIdList, ',');
        //system.debug('caseIdListParam-->'+caseIdListParam);
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c') + +' WHERE ' + ' PC_Patient__c =' +'\'' +patientId + '\'';
        system.debug(query);
        List<sObject> adverseEvents = PC_Database.queryWithAccess(query, true);
        if(adverseEvents != null && !adverseEvents.isEmpty())
        {
            return (List<PC_AdverseEvent2__c>)adverseEvents;
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS),
                    string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                    PC_RestAPIConstants.ADVERSEEVENT_NO_ADVERSEEVENTS_FOUND);
        }
    }

    /**
     * Method to get List of health plans belonging to an account id.
     *
     * @param accountId Salesforce ID of the account
     *
     * @return List of health plans
     */
    global static List<PC_Health_Plan__c> getHealthPlansByAccountId(string accountId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Health_Plan__c') + +' WHERE ' + ' Patient__c = ' + '\'' + accountId + '\'';
        system.debug(query);
        List<sObject> healthPlans = PC_Database.queryWithAccess(query, true);
        if(healthPlans != null && !healthPlans.isEmpty())
        {
            return (List<PC_Health_Plan__c>)healthPlans;
        }
        else
        {
            return new  List<PC_Health_Plan__c>();
        }
    }

    /**
     * Method to get health plans for a set of accounts
     *
     * @param accountIds
     *
     * @return Map of account id's with the list of health plans
     */
    global static Map<string, List<PC_Health_Plan__c>> getHealthPlansByAccountIds(Set<Id> accountIds)
    {
        string strIds = string.valueOf(accountIds);
        strIds = strIds.replace(',', '\',\'');
        strIds = strIds.replace('{', '(\'');
        strIds = strIds.replace('}', '\')');
        strIds = strIds.replace(' ', '');
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Health_Plan__c') + +' WHERE ' + ' Patient__c in ' + strIds;
        system.debug(query);
        Map<string, List<PC_Health_Plan__c>> mapPatientHealthPlans = new  Map<string, List<PC_Health_Plan__c>>();
        List<sObject> healthPlans = PC_Database.queryWithAccess(query, true);
        if(healthPlans != null && !healthPlans.isEmpty())
        {
            for(PC_Health_Plan__c objHealthPlan: (List<PC_Health_Plan__c>)healthPlans)
            {
                if(mapPatientHealthPlans != null && mapPatientHealthPlans.containsKey(objHealthPlan.Patient__c))
                {
                    List<PC_Health_Plan__c> healthPlanList = mapPatientHealthPlans.get(objHealthPlan.Patient__c);
                    healthPlanList.add(objHealthPlan);
                    mapPatientHealthPlans.put(objHealthPlan.Patient__c, healthPlanList);
                }
                else
                {
                    List<PC_Health_Plan__c> healthPlanList = new  list<PC_Health_Plan__c>();
                    healthPlanList.add(objHealthPlan);
                    mapPatientHealthPlans.put(objHealthPlan.Patient__c, healthPlanList);
                }
            }
        }
        return mapPatientHealthPlans;
    }

    /**
     * Method to get Interactions
     *
     * @param requestParams Query parameters of the Request
     * @param filterCriteria criteria using which interactions to be filtered
     *
     * @return List<SObject>
     */
    public static List<SObject> getInteractions(Map<String,String> requestParams, String filterCriteria) {
        Map<string, string> reqParams = prepareReqParamMap(requestParams);
        if(reqParams.containsKey(PC_RestAPIConstants.PATIENT_ID_KEY)){
            String limitNumber = PC_RestAPIConstants.INTERACTION_DEFAULT_LIMIT_VALUE;
            if(reqParams.containsKey(PC_RestAPIConstants.LIMIT_KEY)){
                limitNumber = reqParams.get(PC_RestAPIConstants.LIMIT_KEY);
            }
            Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_INTERACTION);
            List<string> fields = new  List<string>();
            fields.addAll(fieldMappings_mdt_map.keySet());
            string queryFields = string.join(fields, ',');

            String patientId = reqParams.get(PC_RestAPIConstants.PATIENT_ID_KEY);
            String findByWhereClause = 'PC_Patient_Program__r.AccountId' +' = ' + '\'' + patientId + '\'';

            if(filterCriteria == PC_RestAPIConstants.GET_PARAM_FIND_BY_ENGAGEMENT_PROGRAM_ID){
                String engagementProgramId = reqParams.get(PC_RestAPIConstants.ENGAGEMENT_PROGRAM_ID_KEY);
                findByWhereClause = findByWhereClause + ' AND PC_Patient_Program__r.PC_Engagement_Program__c' +' = ' + '\'' + engagementProgramId + '\'';
            }
            string interactionQuery = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Interaction__c')
                    +' WHERE ' + findByWhereClause
                    +' AND PC_Status__c != ' + '\'' + PC_Constants.PA_INTERACTION_STATUS_ATTENDED + '\''
                    +' AND PC_Status__c != ' + '\'' + PC_Constants.PA_INTERACTION_STATUS_CANCELLED + '\''
                    +' AND PC_Start__c >= TODAY'
                    +' ORDER BY PC_Start__c ASC '
                    +' LIMIT '+ limitNumber;
            system.debug('interactionQuery '+ interactionQuery);
            List<sObject> interactionList = PC_Database.queryWithAccess(interactionQuery, true);
            return interactionList;
        }else{
            throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_QUERY_PARAMS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PATIENT_ID_MISSING);
        }
    }

    /**
     * Method to get Self service Settings
     *
     * @param requestParams Query parameters of the Request
     *
     * @return List<SObject>
     */
    public static List<SObject> getSelfServiceSettings(Map<String,String> requestParams) {
        Map<string, string> reqParams = prepareReqParamMap(requestParams);
        PC_Engagement_Program__c engagementProgram = getEngagementProgramById(reqParams.get(PC_RestAPIConstants.ENGAGEMENT_PROGRAM_ID_KEY));
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_SELF_SERVICE_SETTING);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        List<PC_EngagementProgram__mdt> engagementPrograms = new List<PC_EngagementProgram__mdt>();
        engagementPrograms = [Select Id,PC_EngagementProgramCode__c FROM PC_EngagementProgram__mdt
        WHERE PC_EngagementProgramCode__c =: engagementProgram.PC_Program_Code__c AND PC_IsActive__c = true];

        List<sObject> selfServiceSettingList = new List<sObject>();
        String selfServiceSettingsQuery;
        String vendorName = reqParams.get(PC_RestAPIConstants.VENDOR_NAME_KEY);
        String channel = reqParams.get(PC_RestAPIConstants.CHANNEL_KEY);
        if(String.isNotEmpty(vendorName) && String.isNotEmpty(channel)){
            if(!engagementPrograms.isEmpty()){
                selfServiceSettingsQuery = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_SelfServiceSetting__mdt')
                        +' WHERE PC_EngagementProgram__c = ' + '\'' + engagementPrograms[0].Id + '\''
                        +' AND PC_VendorName__c = ' + '\'' + vendorName + '\''
                        +' AND PC_Active__c = true '
                        +' AND PC_Channel__c = ' + '\'' + channel + '\''
                        +' ORDER BY PC_Order__c ASC';

                system.debug('selfServiceSettingsQuery>> '+selfServiceSettingsQuery);
                selfServiceSettingList = PC_Database.queryWithAccess(selfServiceSettingsQuery, true);
            }
            if(selfServiceSettingList.isEmpty() && !engagementPrograms.isEmpty()){
                selfServiceSettingsQuery = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_SelfServiceSetting__mdt')
                        +' WHERE PC_EngagementProgram__c = ' + '\'' + engagementPrograms[0].Id + '\''
                        +' AND PC_VendorName__c = ' + '\'' + vendorName + '\''
                        +' AND PC_Active__c = true '+
                        ' AND PC_Channel__c = '+'\'' + PC_RestAPIConstants.OTHER_KEY +'\'' +  ' AND PC_OtherChannel__c = ' + '\'' + channel + '\''
                        +' ORDER BY PC_Order__c ASC';

                system.debug('selfServiceSettingsQuery>> '+selfServiceSettingsQuery);
                selfServiceSettingList = PC_Database.queryWithAccess(selfServiceSettingsQuery, true);
            }
        }
        return selfServiceSettingList;
    }

    /**
     * Method to get Engagement Program by Id
     *
     * @param engagementProgramId Engagement Program Id
     *
     * @return PC_Engagement_Program__c
     */
    public static PC_Engagement_Program__c getEngagementProgramById(String engagementProgramId) {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ENGAGEMENT_PROGRAM);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c') + +' WHERE ' + ' Id = ' + '\'' + engagementProgramId + '\'';
        List<sObject> engagementPrograms = PC_Database.queryWithAccess(query, true);
        if(engagementPrograms != null && !engagementPrograms.isEmpty()) {
            return (PC_Engagement_Program__c)engagementPrograms[0];
        } else {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ENGAGEMENT_PROGRAM_NO_ENGAGEMENT_PROGRAM_FOUND);
        }
    }

    /**
     * Method to get Engagement Program by program code
     *
     * @param programCode program code of the engagement program
     *
     * @return Engagement Program
     */
    global static PC_Engagement_Program__c getEngagementProgramByCode(string programCode)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ENGAGEMENT_PROGRAM);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c') + +' WHERE ' + ' PC_Program_Code__c = ' + '\'' + programCode + '\'';
        system.debug(query);
        List<sObject> engagementPrograms = PC_Database.queryWithAccess(query, true);
        if(engagementPrograms != null && !engagementPrograms.isEmpty())
        {
            return (PC_Engagement_Program__c)engagementPrograms[0];
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ENGAGEMENT_PROGRAM_NO_ENGAGEMENT_PROGRAM_FOUND);
        }
    }

    /**
     * Method to get Program Coverages by program Id
     *
     * @param programId Salesforce ID of the case program
     *
     * @return List of sObject of type Program Coverage
     */
    global static List<sObject> getProgramCoveragesByProgramId(string programId)
    {
        string recordTypeDevName = PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        return getProgramCoverageByProgramId(programId, recordTypeDevName);
    }

    /**
     * Method to get Program Coverages by program id and record type
     *
     * @param programId Salesforce ID of the program
     * @param recordTypeDevName Developer name of the record type
     *
     * @return List of sObject of type Program Coverage
     */
    global static List<sObject> getProgramCoverageByProgramId(string programId, string recordTypeDevName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_PROGRAM_COVERAGE);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        string query = 'SELECT ' + queryFields + ' FROM ' + ' PC_Program_Coverage__c' + ' WHERE ' + ' PC_Program__c = ' + '\'' + programId + '\'';
        system.debug(query);
        List<sObject> listOfProgramCoverages = PC_Database.queryWithAccess(query, true);
        if(listOfProgramCoverages != null && !listOfProgramCoverages.isEmpty())
        {
            //return (List<PC_Program_Coverage__c>)listOfProgramCoverages;
            return listOfProgramCoverages;
        }
        else
        {
            //return new  List<PC_Program_Coverage__c>();
            return new  list<sObject>();
        }
    }

    /**
     * Method to get Program coverages by Id
     *
     * @param programCoverageId Salesforce ID of the program coverage
     *
     * @return List of sObjects of type Program Coverage
     */
    global static List<sObject> getProgramCoverageById(string programCoverageId)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_PROGRAM_COVERAGE);
        List<string> fields = new  List<string>();
        fields.addAll(fieldMappings_mdt_map.keySet());
        string queryFields = string.join(fields, ',');
        system.debug('queryFields--' + queryFields);
        string query = 'SELECT ' + queryFields + ' FROM ' + ' PC_Program_Coverage__c' + ' WHERE ' + 'id = ' + '\'' + programCoverageId + '\'';
        system.debug(query);
        List<sObject> listOfProgramCoverages = PC_Database.queryWithAccess(query, true);
        if(listOfProgramCoverages != null && !listOfProgramCoverages.isEmpty())
        {
            return listOfProgramCoverages;
        }
        else
        {
            return new  list<sObject>();
        }
    }

    /**
     * Method to get Patient Record type ID
     *
     * @return Returns Patient Record type ID
     */
    global static string getPatientRecordType()
    {
        return PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
    }

    /**
     * Method to get Patient Record type ID
     *
     * @return Returns Patient Record type ID
     */
    global static string getPatientRecordType(String patientClass)
    {
        String recordTypeName, recordTypeNameSpace;
        if(String.isNotBlank(patientClass)) {
            HealthCloudGA__IndividualRecordTypeMapper__mdt[] recordTypeMappings = [SELECT HealthCloudGA__AccountRecordTypeNamespace__c,
                    HealthCloudGA__AccountRecordType__c,DeveloperName,NamespacePrefix
            FROM HealthCloudGA__IndividualRecordTypeMapper__mdt
            WHERE DeveloperName =: patientClass Limit 1];

            if(!recordTypeMappings.isEmpty()){
                recordTypeName = recordTypeMappings[0].HealthCloudGA__AccountRecordType__c;
                recordTypeNameSpace = recordTypeMappings[0].HealthCloudGA__AccountRecordTypeNamespace__c;
                if(recordTypeName == PC_Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE && recordTypeNameSpace == PC_Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAMESPACE){
                    recordTypeNameSpace = recordTypeMappings[0].NamespacePrefix;
                }
            }else{
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_CONFIGURATION), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_PATIENT_INDIVIDUAL_RECORD_TYPE_MAPPER_NOT_FOUND);
            }
        }else{
            recordTypeName = PC_Constants.PATIENT_RECORD_TYPE;
            recordTypeNameSpace = PC_Constants.OrgNamespace;
        }
        return PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, recordTypeName, recordTypeNameSpace);
    }

    /**
     * Method to get Provider Record type ID
     *
     * @return Returns Provider Record type ID
     */
    global static string getProviderRecordType()
    {
        return PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHYSICIAN_RECORD_TYPE);
    }

    /**
     * Method to get Public Health Plan Record type ID
     *
     * @return Returns Public Health Plan Record type ID
     */
    global static string getPublicHealthPlanRecordType()
    {
        return PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PUBLIC_RECORD_TYPE);
    }

    /**
     * Method to get Private Health Plan Record type ID
     *
     * @return Returns Private Health Plan Record type ID
     */
    global static string getPrivateHealthPlanRecordType()
    {
        return PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PRIVATE_RECORD_TYPE);
    }

    /**
     * Method to get Medical Health Plan Record type ID
     *
     * @return Returns Medical Health Plan Record type ID
     */
    global static string getMedicalHealthPlanRecordType()
    {
        return PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
    }

    /**
     * Method to get Program Case Record type ID
     *
     * @return Returns Program Case Record type ID
     */
    global static string getProgramCaseRecordType()
    {
        //[PC-7442] Replaced PC_System.getProgramCaseRecordType() with PC_System.getDefaultProgramCaseRecordTypeId()
        return PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
    }

    /**
     * Method to get record type ID
     *
     * @param recordTypeDevName Developer name of the record type
     * @param sObjectName API name of the sObject
     *
     * @return
     */
    global static string getRecordType(string recordTypeDevName, string sObjectName)
    {
        if(recordTypeDevName.contains('__')) {
            // Has namespace case
            String namespace = recordTypeDevName.substringBefore('__');
            String recordType = recordTypeDevName.substringAfter('__');
            return PC_System.recordTypeId(sObjectName, recordType, namespace);
        }
        else {
            // Does not has namespace
            String recordTypeId;
            try {
                recordTypeId = PC_System.recordTypeId(sObjectName, recordTypeDevName, NULL);
            }
            catch(Exception ex) {
                recordTypeId = PC_System.recordTypeId(sObjectName, recordTypeDevName);
            }
            return recordTypeId;
        }
    }


    public static string upsertPatient(Map<string, object> patient, String patientClass,  PC_RestAPIConstants.ObjectOperation operation)
    {
        Map<string, string> patient_filtered = removeNonPatientFields(patient);
        String recordTypeId = NULL;
        if(String.isNotBlank(patientClass)) {
            recordTypeId = PC_RestAPIUtilities.getPatientRecordType(patientClass);
        }
        return upsertAccount(patient_filtered, recordTypeId, operation);
    }
    public static string upsertProvider(Map<string, object> provider, PC_RestAPIConstants.ObjectOperation operation)
    {
        Map<string, string> provider_filtered = removeNonProviderFields(provider);
        return upsertAccount(provider_filtered, PC_RestAPIUtilities.getProviderRecordType(), operation);
    }
    public static string upsertAccount(Map<string, object> account, string recordTypeId, PC_RestAPIConstants.ObjectOperation operation)
    {
        Map<string, string> account_filtered = removeNonAccountFields(account);
        Account newAccount = new  Account();
        object keyVal;
        for(string key: account_filtered.keySet())
        {
            system.debug('key=' + key);
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(account_filtered.get(key))), newAccount);
            
            system.debug('value=' + keyVal);
            newAccount.put(key, keyVal);
        }
        //String recordTypeId = PC_RestAPIUtilities.getRecordType(recordTypeDeveloperName);

        if(PC_Utility.hasHealthCloudPermissionSetAssigned()) {
            if (operation == PC_RestAPIConstants.ObjectOperation.oINSERT) {
                if(String.isNotBlank(recordTypeId)) {
                    newAccount.RecordTypeId = recordTypeId;
                }
                //insert newAccount;
                PC_Database.ins(newAccount);
            } else {
                //update newAccount;
                PC_Database.upd(newAccount);
            }
        }
        else {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.PERMISSION_SET_MISSING), string.valueOf(PC_RestAPIConstants.ErrorType.HEALTH_CLOUD), Label.PC_HC_PermissionSet_Missing);
        }
        return newAccount.Id;
    }
    public static string upsertApplicant(Map<string, object> reqApplicantTrans, List<object> reqApplicantAddressesObjListTrans, List<object> reqApplicantHealthPlansObjListTrans, PC_RestAPIConstants.ObjectOperation operation)
    {
        PC_Applicant__c newApplicant = new  PC_Applicant__c();
        object keyVal;
        for(string key: reqApplicantTrans.keySet())
        {
            if(key != PC_RestAPIConstants.RECORD_TYPE_KEY)
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(reqApplicantTrans.get(key))), newApplicant);
                system.debug('key=' + key);
                system.debug('value=' + keyVal);
                newApplicant.put(key, keyVal);
            }
        }
        newApplicant.RecordTypeId = getRecordType(PC_Constants.APPLICANT_ONLINE_RECORD_TYPE, PC_Constants.CANDIDATE_PATIENT_OBJECT);
        /*if(reqApplicantTrans.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY)) {
        newApplicant.RecordTypeId = getRecordType((String) reqApplicantTrans.get(PC_RestAPIConstants.RECORD_TYPE_KEY));
        }*/
        Map<string, object> addressMap;
        Integer addressIndex = 0;
        string newAddrKey;
        for(object address: reqApplicantAddressesObjListTrans)
        {
            addressMap = (Map<string, object>)address;
            for(string key: addressMap.keySet())
            {
                if(addressIndex == 0)
                {
                    newAddrKey = key.replace('?', PC_Constants.EMPTY_STRING);
                }
                else
                {
                    newAddrKey = key.replace('?', string.valueOf(addressIndex));
                }
                system.debug('key=' + key);
                system.debug('newHPKey=' + newAddrKey);
                keyVal = castFieldValueBasedOnType(newAddrKey, string.escapeSingleQuotes(string.valueOf(addressMap.get(key))), newApplicant);
                system.debug('value=' + keyVal);
                newApplicant.put(newAddrKey, keyVal);
            }
            addressIndex++;
        }
        Map<string, object> healthPlanMap;
        Integer healthPlanIndex = 0;
        string newHPKey;
        for(object healthPlan: reqApplicantHealthPlansObjListTrans)
        {
            healthPlanMap = (Map<string, object>)healthPlan;
            for(string key: healthPlanMap.keySet())
            {
                if(healthPlanIndex == 0)
                {
                    newHPKey = key.replace('?', PC_Constants.EMPTY_STRING);
                }
                else
                {
                    newHPKey = key.replace('?', string.valueOf(healthPlanIndex));
                }
                system.debug('key=' + key);
                system.debug('newHPKey=' + newHPKey);
                keyVal = castFieldValueBasedOnType(newHPKey, string.escapeSingleQuotes(string.valueOf(healthPlanMap.get(key))), newApplicant);
                system.debug('value=' + keyVal);
                newApplicant.put(newHPKey, keyVal);
            }
            healthPlanIndex++;
        }
        /*
        Map<String, Object> hcoMap;
        Integer hcoIndex = 0;
        String newHcoKey;
        for(Object hco : reqApplicantHCOsObjListTrans) {
        hcoMap = (Map<String, Object>) hco;
        for(String key : hcoMap.keySet()) {
        if(hcoIndex == 0) {
        newHcoKey = key.replace('?','');
        }
        else {
        newHcoKey = key.replace('?',String.valueOf(hcoIndex));
        }
        system.debug('key=' + key);
        system.debug('newHcoKey=' + newHcoKey);
        keyVal = castFieldValueBasedOnType(newHcoKey, String.escapeSingleQuotes(String.valueOf(hcoMap.get(key))), newApplicant);
        system.debug('value=' + keyVal);
        newApplicant.put(newHcoKey, keyVal);
        }
        
        hcoIndex++;
        
        }
        */
        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newApplicant);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newApplicant);
        }
        return newApplicant.Id;
    }
    public static string upsertCase(Map<string, object> c, string recordTypeId, PC_RestAPIConstants.ObjectOperation operation)
    {
        Map<string, string> case_filtered = removeNonCaseFields(c);
        Case newC = new  Case();
        object keyVal;
        for(string key: case_filtered.keySet())
        {
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(case_filtered.get(key))), newC);
            system.debug('key=' + key);
            system.debug('value=' + keyVal);
            newC.put(key, keyVal);
        }
        //String recordTypeId = PC_RestAPIUtilities.getRecordType(recordTypeDeveloperName);
        newC.RecordTypeId = recordTypeId;
        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newC);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newC);
        }
        return newC.Id;
    }

    public static string upsertAE(Map<string, object> c,PC_RestAPIConstants.ObjectOperation operation)
    {
       Map<string, string> adverseEvent_filtered = removeNonAdverseEventFields(c);
        PC_AdverseEvent__c newAdverseEvent = new  PC_AdverseEvent__c();
        object keyVal;
        for(string key: adverseEvent_filtered.keySet())
        {
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(adverseEvent_filtered.get(key))), newAdverseEvent);
            system.debug('key=' + key);
            system.debug('value=' + keyVal);
            newAdverseEvent.put(key, keyVal);
        }

        system.debug('operation-->'+operation);

        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newAdverseEvent);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newAdverseEvent);
        }
        return newAdverseEvent.Id;

        return null;
    }
    public static string upsertAE2(Map<string, object> c,PC_RestAPIConstants.ObjectOperation operation)
    {
       Map<string, string> adverseEvent_filtered = removeNonAdverseEventFields(c);
        PC_AdverseEvent2__c newAdverseEvent = new  PC_AdverseEvent2__c();
        object keyVal;
        for(string key: adverseEvent_filtered.keySet())
        {
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(adverseEvent_filtered.get(key))), newAdverseEvent);
            system.debug('key=' + key);
            system.debug('value=' + keyVal);
            newAdverseEvent.put(key, keyVal);
        }

        system.debug('operation-->'+operation);
        system.debug('newAdverseEvent-->'+newAdverseEvent);

        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newAdverseEvent);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newAdverseEvent);
        }
        return newAdverseEvent.Id;

        return null;
    }
    public static string upsertProgramCase(Map<string, object> c, PC_RestAPIConstants.ObjectOperation operation)
    {
        String caseRecordTypeId=PC_Constants.EMPTY_STRING;

        if (c.containsKey(PC_Constants.getQualifiedAPIName(PC_RestAPIConstants.REST_OBJECT_TO_SOBJECT_MAPPING.get(PC_RestAPIConstants.REST_OBJECT_NAME_ENGAGEMENT_PROGRAM)))) {
            String engagementProgId = (String) c.get(PC_Constants.getQualifiedAPIName(PC_RestAPIConstants.REST_OBJECT_TO_SOBJECT_MAPPING.get(PC_RestAPIConstants.REST_OBJECT_NAME_ENGAGEMENT_PROGRAM)));

            try{
                caseRecordTypeId=(String)PC_SYSTEM.getProgramRecordTypeIdBasedOnEngProgramId(engagementProgId);
            }
            catch(Exception ex){
                throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_CONFIGURATION), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), ex.getMessage());
            }

        } else {
            caseRecordTypeId = PC_RestAPIUtilities.getProgramCaseRecordType();
        }

        return upsertCase(c, caseRecordTypeId, operation);
    }
    public static string upsertAdverseEvent(Map<string, object> adverseEventMap, PC_RestAPIConstants.ObjectOperation operation)
    {


        return upsertAE(adverseEventMap, operation);
        return null;
    }
    public static string upsertAdverseEvent2(Map<string, object> adverseEventMap, PC_RestAPIConstants.ObjectOperation operation)
    {


        return upsertAE2(adverseEventMap, operation);
        return null;
    }
    public static string upsertSupportCase(Map<string, object> c, PC_RestAPIConstants.ObjectOperation operation)
    {
        if(c.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY))
        {
            string rt = getRecordType(string.valueOf(c.get(PC_RestAPIConstants.RECORD_TYPE_KEY)), 'Case');
            c.remove(PC_RestAPIConstants.RECORD_TYPE_KEY);
            return upsertCase(c, rt, operation);
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MANDATORY_FIELDS_MISSING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.RECORD_TYPE_MISSING);
        }
    }
    public static string upsertAddress(Map<string, object> address, PC_RestAPIConstants.ObjectOperation operation)
    {
        PC_Address__c newAddr = new  PC_Address__c();
        object keyVal;
        for(string key: address.keySet())
        {
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(address.get(key))), newAddr);
            system.debug('key=' + key);
            system.debug('value=' + keyVal);
            newAddr.put(key, keyVal);
        }
        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newAddr);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newAddr);
        }
        return newAddr.Id;
    }
    public static string upsertOrder(Map<string, object> order, PC_RestAPIConstants.ObjectOperation operation)
    {
        PC_Order__c newOrder = new  PC_Order__c();
        object keyVal;
        for(string key: order.keySet())
        {
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(order.get(key))), newOrder);
            system.debug('key=' + key);
            system.debug('value=' + keyVal);
            newOrder.put(key, keyVal);
        }
        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newOrder);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newOrder);
        }
        return newOrder.Id;
    }
    public static Map<string, object> upsertAddresses(List<object> addresses, string patientId, PC_RestAPIConstants.ObjectOperation operation, Boolean allOrNone, string requestURL)
    {
        List<string> addressIds = new  List<string>();
        Map<string, object> returnObjects = new  Map<string, object>();
        Map<string, Map<string, string>> allErrorsMap = new  Map<string, Map<string, string>>();
        List<PC_Address__c> newAddresses = new  List<PC_Address__c>();
        PC_Address__c newAddress;
        Map<string, object> addressMap;
        for(object addressObj: addresses)
        {
            addressMap = new  Map<string, object>();
            addressMap = (Map<string, object>)addressObj;
            newAddress = new  PC_Address__c();
            object keyVal;
            for(string key: addressMap.keySet())
            {               
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(addressMap.get(key))), newAddress);
                newAddress.put(key, keyVal);
            }
            if(string.isNotEmpty(patientId))
            {
                newAddress.PC_Account__c = patientId;
            }
            newAddresses.add(newAddress);
        }
        //List<Map<String, String>> errorMessages = new List<Map<String, String>>();
        Map<string, string> errorMessageMap;
        if(newAddresses != null && !newAddresses.isEmpty())
        {
            if(allOrNone)
            {
                if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
                {
                    PC_Database.ins(newAddresses);
                }
                else
                {
                    PC_Database.upd(newAddresses);
                }
                for(PC_Address__c a: newAddresses)
                {
                    addressIds.add(a.Id);
                }
            }
            else
            {
                Database.SaveResult[] saveResults;
                if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
                {
                    saveResults = PC_Database.insWithBestEffort(newAddresses);
                }
                else
                {
                    saveResults = PC_Database.updWithBestEffort(newAddresses);
                }
                integer i = 0;
                string errorLogRefKey;
                for(Database.SaveResult result: saveResults)
                {
                    errorMessageMap = new  Map<string, string>();
                    if(result.isSuccess())
                    {
                        addressIds.add(result.getId());
                    }
                    else
                    {
                        errorMessageMap = logDBSaveResultErrorMessage(result, requestURL + '\n' + JSON.serialize(addresses.get(i)));
                        //errorMessages.add(errorMessageMap);
                        errorLogRefKey = PC_RestAPIConstants.ERROR_ERROR_CODE_PREFIX + errorMessageMap.get(PC_RestAPIConstants.ERROR_ERROR_LOG_REF);
                        addressIds.add(errorLogRefKey);
                        allErrorsMap.put(errorLogRefKey, errorMessageMap);
                    }
                    i++;
                }
            }
        }
        returnObjects.put('ids', addressIds);
        returnObjects.put('errors', allErrorsMap);
        return returnObjects;
    }
    public static string upsertHealthPlan(Map<string, object> hp, PC_RestAPIConstants.ObjectOperation operation)
    {
        PC_Health_Plan__c newHp = new  PC_Health_Plan__c();
        object keyVal;
        string recordType;
        string recordTypeId;
        for(string key: hp.keySet())
        {
            if(key == PC_RestAPIConstants.RECORD_TYPE_KEY)
            {
                recordType = string.valueOf(hp.get(PC_RestAPIConstants.RECORD_TYPE_KEY));
                if(String.isNotBlank(recordType)) {
                    recordTypeId = getRecordType(recordType, PC_Constants.PC_HEALTH_PLAN);
                }
                newHp.RecordTypeId = recordTypeId;
            }
            else
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(hp.get(key))), newHp);
                system.debug('@hp key=' + key);
                system.debug('@hp value=' + keyVal);
                newHp.put(key, keyVal);
            }
        }
        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            //insert newAccount;
            PC_Database.ins(newHp);
        }
        else
        {
            //update newAccount;
            PC_Database.upd(newHp);
        }
        return newHp.Id;
    }
    public static Map<string, object> upsertHealthPlans(List<object> healthPlans, string patientId, PC_RestAPIConstants.ObjectOperation operation, Boolean allOrNone, string requestURL)
    {
        system.debug('creating healthplans');
        List<string> healthPlansIds = new  List<string>();
        Map<string, Map<string, string>> allErrorsMap = new  Map<string, Map<string, string>>();
        Map<string, object> returnObjects = new  Map<string, object>();
        List<PC_Health_Plan__c> newHealthPlans = new  List<PC_Health_Plan__c>();
        PC_Health_Plan__c newHealthPlan;
        Map<string, object> healthPlanMap;
        for(object healthPlanObj: healthPlans)
        {
            healthPlanMap = new  Map<string, object>();
            healthPlanMap = (Map<string, object>)healthPlanObj;
            newHealthPlan = new  PC_Health_Plan__c();
            if(healthPlanMap.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY))
            {
                string rt = string.valueOf(healthPlanMap.get(PC_RestAPIConstants.RECORD_TYPE_KEY));
                system.debug('Record type = ' + rt);
                if(String.isNotBlank(rt)) {
                    newHealthPlan.RecordTypeId = getRecordType(rt, PC_Constants.PC_HEALTH_PLAN);
                }
                healthPlanMap.remove(PC_RestAPIConstants.RECORD_TYPE_KEY);
            }
            else
            {
                system.debug('Record type missing');
                /*throw new PC_RestException(String.valueOf(PC_RestAPIConstants.ErrorCode.MANDATORY_FIELDS_MISSING),
                String.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                PC_RestAPIConstants.HealthPlan_RecordTypeMissing);*/
            }
            object keyVal;
            for(string key: healthPlanMap.keySet())
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(healthPlanMap.get(key))), newHealthPlan);
                newHealthPlan.put(key, keyVal);
            }
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                if(string.isNotEmpty(patientId))
                {
                    newHealthPlan.Patient__c = patientId;
                }
            }
            newHealthPlans.add(newHealthPlan);
        }
        //List<Map<String, String>> errorMessages = new List<Map<String, String>>();
        Map<string, string> errorMessageMap;
        if(newHealthPlans != null && !newHealthPlans.isEmpty())
        {
            system.debug('Inserting healthPlans');
            if(allOrNone)
            {
                if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
                {
                    //insert newHealthPlans;
                    PC_Database.ins(newHealthPlans);
                }
                else
                {
                    //update newHealthPlans;
                    PC_Database.upd(newHealthPlans);
                }
                for(PC_Health_Plan__c hp: newHealthPlans)
                {
                    healthPlansIds.add(hp.Id);
                }
            }
            else
            {
                Database.SaveResult[] saveResults;
                if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
                {
                    //insert newHealthPlans;
                    saveResults = PC_Database.insWithBestEffort(newHealthPlans);
                }
                else
                {
                    //update newHealthPlans;
                    saveResults = PC_Database.updWithBestEffort(newHealthPlans);
                }
                integer i = 0;
                string errorLogRefKey;
                for(Database.SaveResult result: saveResults)
                {
                    errorMessageMap = new  Map<string, string>();
                    if(result.isSuccess())
                    {
                        healthPlansIds.add(result.getId());
                    }
                    else
                    {
                        errorMessageMap = logDBSaveResultErrorMessage(result, requestURL + '\n' + JSON.serialize(healthPlans.get(i)));
                        //errorMessages.add(errorMessageMap);
                        errorLogRefKey = PC_RestAPIConstants.ERROR_ERROR_CODE_PREFIX + errorMessageMap.get(PC_RestAPIConstants.ERROR_ERROR_LOG_REF);
                        healthPlansIds.add(errorLogRefKey);
                        allErrorsMap.put(errorLogRefKey, errorMessageMap);
                    }
                    i++;
                }
            }
        }
        returnObjects.put('ids', healthPlansIds);
        returnObjects.put('errors', allErrorsMap);
        return returnObjects;
    }
    public static List<string> upsertCases(List<object> cases, string programId, PC_RestAPIConstants.ObjectOperation operation)
    {
        List<string> caseIds = new  List<string>();
        List<Case> newCases = new  List<Case>();
        Case newCase;
        Map<string, object> caseMap;
        for(object caseObj: cases)
        {
            caseMap = new  Map<string, object>();
            caseMap = (Map<string, object>)caseObj;
            newCase = new  Case();
            if(caseMap.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY))
            {
                string rt = string.valueOf(caseMap.get(PC_RestAPIConstants.RECORD_TYPE_KEY));
                system.debug('Record type = ' + rt);
                newCase.RecordTypeId = getRecordType(rt, 'Case');
                caseMap.remove(PC_RestAPIConstants.RECORD_TYPE_KEY);
            }
            else
            {
                system.debug('Record type missing');
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MANDATORY_FIELDS_MISSING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.HEALTHPLAN_RECORD_TYPE_MISSING);
            }
            object keyVal;
            for(string key: caseMap.keySet())
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(caseMap.get(key))), newCase);
                newCase.put(key, keyVal);
            }
            if(string.isNotEmpty(programId))
            {
                newCase.PC_Program__c = programId;
            }
            newCases.add(newCase);
        }
        if(newCases != null && !newCases.isEmpty())
        {
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                //insert newAddresses;
                PC_Database.ins(newCases);
            }
            else
            {
                //update newAddresses;
                PC_Database.upd(newCases);
            }
            for(Case c: newCases)
            {
                caseIds.add(c.Id);
            }
        }
        return caseIds;
    }

    public static List<string> upsertOrderItems(List<object> orderItems, string orderId, PC_RestAPIConstants.ObjectOperation operation)
    {
        List<string> orderItemIds = new  List<string>();
        List<PC_OrderItem__c> newOrderItems = new  List<PC_OrderItem__c>();
        PC_OrderItem__c newOrderItem;
        Map<string, object> orderItemMap;
        for(object orderItemObj: orderItems)
        {
            orderItemMap = new  Map<string, object>();
            orderItemMap = (Map<string, object>)orderItemObj;
            newOrderItem = new  PC_OrderItem__c();
            object keyVal;
            for(string key: orderItemMap.keySet())
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(orderItemMap.get(key))), newOrderItem);
                newOrderItem.put(key, keyVal);
            }
            if(string.isNotEmpty(orderId) && operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                newOrderItem.PC_Order__c = orderId;
            }
            newOrderItems.add(newOrderItem);
        }
        if(newOrderItems != null && !newOrderItems.isEmpty())
        {
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                PC_Database.ins(newOrderItems);
            }
            else
            {
                PC_Database.upd(newOrderItems);
            }
            for(PC_OrderItem__c c: newOrderItems)
            {
                orderItemIds.add(c.Id);
            }
        }
        return orderItemIds;
    }

    public static List<string> upsertSupportCases(List<object> cases, string programId, PC_RestAPIConstants.ObjectOperation operation)
    {
        return upsertCases(cases, programId, operation);
    }
    public static List<string> upsertAssociations(List<object> associations, string programId, PC_RestAPIConstants.ObjectOperation operation)
    {
        system.debug('creating associations');
        List<string> associationsIds = new  List<string>();
        List<PC_Association__c> newAssociations = new  List<PC_Association__c>();
        PC_Association__c newAssociation;
        Map<string, object> associationMap;
        for(object associationObj: associations)
        {
            associationMap = new  Map<string, object>();
            associationMap = (Map<string, object>)associationObj;
            newAssociation = new  PC_Association__c();
            object keyVal;
            for(string key: associationMap.keySet())
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(associationMap.get(key))), newAssociation);
                newAssociation.put(key, keyVal);
            }
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                if(string.isNotEmpty(programId))
                {
                    newAssociation.PC_Program__c = programId;
                }
            }
            newAssociations.add(newAssociation);
        }
        if(newAssociations != null && !newAssociations.isEmpty())
        {
            system.debug('Inserting newAssociations');
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                //insert newHealthPlans;
                PC_Database.ins(newAssociations);
            }
            else
            {
                //update newHealthPlans;
                PC_Database.upd(newAssociations);
            }
            for(PC_Association__c a: newAssociations)
            {
                associationsIds.add(a.Id);
            }
        }
        return associationsIds;
    }

    public static List<string> upsertSuspectPrescriptions(List<object> suspectProducts, string adverseEventId, PC_RestAPIConstants.ObjectOperation operation)
    {
        system.debug('creating suspectPrescriptions');
        List<string> suspectPrescriptionIds = new  List<string>();
        List<PC_Suspect_Prescription__c> newSuspectPrescriptions = new  List<PC_Suspect_Prescription__c>();
        PC_Suspect_Prescription__c newSuspectPrescription;
        Map<string, object> suspectPrescriptionMap;
        for(object suspectProductObj: suspectProducts)
        {
            suspectPrescriptionMap = new  Map<string, object>();
            suspectPrescriptionMap = (Map<string, object>)suspectProductObj;
            newSuspectPrescription = new  PC_Suspect_Prescription__c();
            object keyVal;
            for(string key: suspectPrescriptionMap.keySet())
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(suspectPrescriptionMap.get(key))), newSuspectPrescription);
                newSuspectPrescription.put(key, keyVal);
            }
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                if(string.isNotEmpty(adverseEventId))
                {
                    newSuspectPrescription.PC_Adverse_Event__c = adverseEventId;
                }
            }
            newSuspectPrescriptions.add(newSuspectPrescription);
        }
        if(newSuspectPrescriptions != null && !newSuspectPrescriptions.isEmpty())
        {
            system.debug('Inserting newSuspectPrescriptions');
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                //insert newSuspectPrescriptions;
                PC_Database.ins(newSuspectPrescriptions);
            }
            else
            {
                //update newSuspectPrescriptions;
                PC_Database.upd(newSuspectPrescriptions);
            }
            for(PC_Suspect_Prescription__c a: newSuspectPrescriptions)
            {
                suspectPrescriptionIds.add(a.Id);
            }
        }
        return suspectPrescriptionIds;
    }
    public static List<string> upsertSuspectPrescriptions2(List<object> suspectProducts, string adverseEventId, PC_RestAPIConstants.ObjectOperation operation)
    {
        system.debug('creating suspectPrescriptions');
        List<string> suspectPrescriptionIds = new  List<string>();
        List<PC_Suspect_Prescription__c> newSuspectPrescriptions = new  List<PC_Suspect_Prescription__c>();
        PC_Suspect_Prescription__c newSuspectPrescription;
        Map<string, object> suspectPrescriptionMap;
        for(object suspectProductObj: suspectProducts)
        {
            suspectPrescriptionMap = new  Map<string, object>();
            suspectPrescriptionMap = (Map<string, object>)suspectProductObj;
            newSuspectPrescription = new  PC_Suspect_Prescription__c();
            object keyVal;
            for(string key: suspectPrescriptionMap.keySet())
            {
                keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(suspectPrescriptionMap.get(key))), newSuspectPrescription);
                newSuspectPrescription.put(key, keyVal);
            }
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                if(string.isNotEmpty(adverseEventId))
                {
                    newSuspectPrescription.PC_Adverse_Event2__c = adverseEventId;
                }
            }
            newSuspectPrescriptions.add(newSuspectPrescription);
        }
        if(newSuspectPrescriptions != null && !newSuspectPrescriptions.isEmpty())
        {
            system.debug('Inserting newSuspectPrescriptions');
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                //insert newSuspectPrescriptions;
                PC_Database.ins(newSuspectPrescriptions);
            }
            else
            {
                //update newSuspectPrescriptions;
                PC_Database.upd(newSuspectPrescriptions);
            }
            for(PC_Suspect_Prescription__c a: newSuspectPrescriptions)
            {
                suspectPrescriptionIds.add(a.Id);
            }
        }
        return suspectPrescriptionIds;
    }
    public static map<string, string> getRecordTypeInfoOfSObject(string sObjectAPIName)
    {
        map<string, string> mapOfRecordTypeInfo = new  map<string, string>();
        SObjectType objToken = Schema.getGlobalDescribe().get(string.escapeSingleQuotes(sObjectAPIName));
        DescribeSObjectResult objDef = objToken.getDescribe();
        for(Schema.RecordTypeInfo rtInfo: objDef.getRecordTypeInfos())
        {
            if(rtInfo != null)
            {
                mapOfRecordTypeInfo.put(rtInfo.getName(), rtInfo.getRecordTypeId());
            }
        }
        return mapOfRecordTypeInfo;
    }
    
    /*********************************************************************************
    Method Name    : getRecordTypeForProgramCoverage
    Description    : PC-2499 - Create service for Program Coverage 
                     (to upsert PC_Program_Coverage - in Post Method)
    parameters     : Map<string, object>
    Return Type    : string     
    *********************************************************************************/
    public static string getRecordTypeForProgramCoverage(Map<string, object> mapOfProgramCoverage)
    {
        map<string, string> mapOfRecordTypeInfo;
        string recordType;
        string recordTypeId;
        if(mapOfProgramCoverage != null)
        {
            if(mapOfProgramCoverage.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY) 
                && mapOfProgramCoverage.get(PC_RestAPIConstants.RECORD_TYPE_KEY) != null)
            {
                recordType = string.valueOf(mapOfProgramCoverage.get(PC_RestAPIConstants.RECORD_TYPE_KEY));
                if(string.isNotBlank(recordType))
                {
                    recordTypeId = getRecordType(recordType, PC_Constants.PC_PROGRAM_COVERAGE);
                }
            }
            /*Commenting out after discussing it with Vijay that at present we will not find RecordType
              with the help of Coverage Type field.
            else if(mapOfProgramCoverage.containsKey(PC_RestAPIConstants.PROGRAMCOVERAGE_TYPE_APINAME) 
                && mapOfProgramCoverage.get(PC_RestAPIConstants.PROGRAMCOVERAGE_TYPE_APINAME) != null)
            {
                mapOfRecordTypeInfo = new  map<string, string>();
                mapOfRecordTypeInfo = getRecordTypeInfoOfSObject(PC_Constants.PC_PROGRAM_COVERAGE);
                string reqCoveragetype = string.valueOf(mapOfProgramCoverage.get(PC_RestAPIConstants.PROGRAMCOVERAGE_TYPE_APINAME));
                for(string rtName: mapOfRecordTypeInfo.keySet())
                {
                    if(rtName.contains(reqCoveragetype))
                    {
                        recordTypeId = mapOfRecordTypeInfo.get(rtName);
                        break;
                    }
                }
            }*/
        }
        return recordTypeId;
    }
    /*********************************************************************************
     Method Name    : upsertInteraction
     Description    : upserts Interaction record
     parameters     : interactionMap, operation
     Return Type    : string
     *********************************************************************************/
    public static string upsertInteraction(Map<string, object> interactionMap, PC_RestAPIConstants.ObjectOperation operation) {
        Map<string, string> interaction_filtered = removeNonInteractionFields(interactionMap);
        PC_Interaction__c newInteraction = new  PC_Interaction__c();
        object keyValue;
        for(string key: interaction_filtered.keySet()) {
            keyValue = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(interaction_filtered.get(key))), newInteraction);
            newInteraction.put(key, keyValue);
        }
        PC_Database.upd(newInteraction);
        return newInteraction.Id;
    }

    /*********************************************************************************
    Method Name    : upsertProgCoverage
    Description    : PC-2499 - Create service for Program Coverage 
                     (to upsert PC_Program_Coverage - in Post Method)
    parameters     : Map<string, object>
    Return Type    : string     
    *********************************************************************************/
    public static string upsertProgCoverage(Map<string, object> mapOfProgramCoverage, PC_RestAPIConstants.ObjectOperation operation)
    {
        Map<string, string> programCoverage_filtered = removeNonProgramCoverageFields(mapOfProgramCoverage);
        PC_Program_Coverage__c newProgramCoverage = new  PC_Program_Coverage__c();
        object keyVal;
       
        string recordTypeId = getRecordTypeForProgramCoverage(mapOfProgramCoverage);
        
        if(string.isNotBlank(recordTypeId))
        {
            newProgramCoverage.RecordTypeId = recordTypeId;
        }
        programCoverage_filtered.remove(PC_RestAPIConstants.RECORD_TYPE_KEY);
        for(string key: programCoverage_filtered.keySet())
        {
            keyVal = castFieldValueBasedOnType(key, string.escapeSingleQuotes(string.valueOf(programCoverage_filtered.get(key))), newProgramCoverage);
            system.debug('key=' + key);
            system.debug('value=' + keyVal);
            newProgramCoverage.put(key, keyVal);
        }
       
        if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
        {
            PC_Database.ins(newProgramCoverage);
        }
        else
        {
            PC_Database.upd(newProgramCoverage);
        }
        return newProgramCoverage.Id;
    }

    /*********************************************************************************
    Method Name    : upsertProgramCoverage
    Description    : PC-2499 - Create service for Program Coverage 
                     (to upsert PC_Program_Coverage - in Post Method)
    parameters     : Map<string, object>, PC_RestAPIConstants.ObjectOperation
    Return Type    : string     
    *********************************************************************************/
    public static string upsertProgramCoverage(Map<string, object> pc, PC_RestAPIConstants.ObjectOperation operation)
    {
        return upsertProgCoverage(pc, operation);
    }
    private static Map<string, string> removeNonPatientFields(Map<string, object> patient)
    {
        Map<string, string> patient_filtered = removeNonAccountFields(patient);
        return patient_filtered;
    }
    private static Map<string, string> removeNonProviderFields(Map<string, object> provider)
    {
        Map<string, string> provider_filtered = removeNonAccountFields(provider);
        return provider_filtered;
    }
    private static Map<string, string> removeNonAccountFields(Map<string, object> account)
    {
        Map<string, string> account_filtered = new  Map<string, string>();
        for(string key: account.keySet())
        {
            // ToDo check if field exists, if not do not add field in patient_filtered.
            account_filtered.put(key, string.valueOf(account.get(key)));
        }
        return account_filtered;
    }
    private static Map<string, string> removeNonCaseFields(Map<string, object> c)
    {
        Map<string, string> case_filtered = new  Map<string, string>();
        for(string key: c.keySet())
        {
            // ToDo check if field exists, if not do not add field in patient_filtered.
            case_filtered.put(key, string.valueOf(c.get(key)));
        }
        return case_filtered;
    }
    private static Map<string, string> removeNonAdverseEventFields(Map<string, object> c)
    {
        Map<string, string> adverseEvent_filtered = new  Map<string, string>();
        for(string key: c.keySet())
        {
            // ToDo check if field exists, if not do not add field in patient_filtered.
            adverseEvent_filtered.put(key, string.valueOf(c.get(key)));
        }
        return adverseEvent_filtered;
    }
    private static Map<string, string> removeNonInteractionFields(Map<string, object> c)
    {
        Map<string, string> interaction_filtered = new  Map<string, string>();
        for(string key: c.keySet())
        {
            // ToDo check if field exists, if not do not add field in interaction_filtered.
            interaction_filtered.put(key, string.valueOf(c.get(key)));
        }
        return interaction_filtered;
    }

    /*********************************************************************************
    Method Name    : removeNonProgramCoverageFields
    Description    : PC-2499 - Create service for Program Coverage 
    parameters     : Map<string, object>
    Return Type    : Map<string, string>    
    *********************************************************************************/
    private static Map<string, string> removeNonProgramCoverageFields(Map<string, object> progCoverage)
    {
        Map<string, string> programCoverager_filtered = new  Map<string, string>();
        for(string key: progCoverage.keySet())
        {
            // ToDo check if field exists, if not do not add field in programCoverage_filtered.
            programCoverager_filtered.put(key, string.valueOf(progCoverage.get(key)));
        }
        return programCoverager_filtered;
    }

    /**
     * Method to cast field value based on it's type
     *
     * @param fieldName API name of the field
     * @param fieldValue Type - object. Takes field value
     * @param sObj sObject e.g Account
     *
     * @return Returns fieldValue casted as per the type of the field
     */
    global static object castFieldValueBasedOnType(string fieldName, object fieldValue, sObject sObj)
    {
        try
        {
            Schema.SObjectType sObjType = sObj.getSObjectType();
            system.debug('Casting field ' + fieldName);
            Schema.DisplayType fieldType = sObjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
            object parsedFieldValue;
           
            if(fieldType == Schema.DisplayType.STRING)
            {
                parsedFieldValue = (string)fieldValue;
            }
            else if(fieldType == Schema.DisplayType.DATE)
            {
                if(!string.isEmpty(string.valueOf(fieldValue)))
                {
                    parsedFieldValue = Date.valueOf(string.valueOf(fieldValue));// Date.parse(fieldValue);
                }
            }
            else if(fieldType == Schema.DisplayType.DATETIME)
            {
                string formattedFieldValue = string.valueOf(fieldValue);
                if(!string.isEmpty(formattedFieldValue))
                {
                    formattedFieldValue = formattedFieldValue.replace('T', ' ');
                    formattedFieldValue = formattedFieldValue.substringBeforeLast('.');
                    parsedFieldValue = Datetime.valueOf(formattedFieldValue);
                }
            }
            else if(fieldType == Schema.DisplayType.EMAIL)
            {
                parsedFieldValue = (string)fieldValue;
            }
            else if(fieldType == Schema.DisplayType.PICKLIST)
            {
                parsedFieldValue = (string)fieldValue;
            }
            else if(fieldType == Schema.DisplayType.BOOLEAN)
            {
                string formattedFieldValue = string.valueOf(fieldValue);
                if(!string.isEmpty(formattedFieldValue))
                {
                    parsedFieldValue = Boolean.valueOf(fieldValue);
                }
                else
                {
                    parsedFieldValue = false;
                }
            }
            else if(fieldType == Schema.DisplayType.DOUBLE 
                    || fieldType == Schema.DisplayType.CURRENCY
                    || fieldType == Schema.DisplayType.PERCENT)
            {
                string formattedFieldValue = string.valueOf(fieldValue);
                if(string.isEmpty(formattedFieldValue))
                {
                }
                // nothing to do
                else
                {
                    parsedFieldValue = double.valueOf(fieldValue);
                }
            }
            else if(fieldType == Schema.DisplayType.PHONE)
            {
                parsedFieldValue = (string)fieldValue;
            }
            else if(fieldType == Schema.DisplayType.TEXTAREA)
            {
                parsedFieldValue = (string)fieldValue;
            }
            else
            {
                parsedFieldValue = (string)fieldValue;
            }
            return parsedFieldValue;
        }
        catch(Exception e)
        {
            string errorMessage = 'Exception while casting ' + fieldName + ' with value ' + fieldValue + '.';
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.APEX_ERROR), string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION), errorMessage);
        }
    }
    /**
     * Method to get the rest field mappings as configured in custom meta data
     *
     * @param restObjectName REST object name
     *
     * @return Returns of List of custom meta data records - List<PC_REST_Field_Mapping__mdt>
     */
    global static List<PC_REST_Field_Mapping__mdt> getRESTFieldMappings(string restObjectName)
    {
        map<id,PC_REST_Field_Mapping__mdt> mapOfIntermediateMappings1 = new map<id,PC_REST_Field_Mapping__mdt>([SELECT
            Id, 
            DeveloperName, 
            MasterLabel, 
            NamespacePrefix, 
            PC_REST_Field_Name__c, 
            PC_REST_object_name__c, 
            PC_sObject_Field_Name__c,
            PC_Other_REST_Object_Name__c, 
            PC_Other_sObject_API_Name__c
        FROM
            PC_REST_Field_Mapping__mdt
        WHERE
            PC_REST_object_name__c = : restObjectName
        ORDER BY
            PC_REST_Field_Name__c]);

        //For record having Other specified as Rest Object, also disjunction queries are not allowed in Custom Metadatypes
         map<id,PC_REST_Field_Mapping__mdt> mapOfIntermediateMappings2 = new map<id,PC_REST_Field_Mapping__mdt>([SELECT
            Id, 
            DeveloperName, 
            MasterLabel, 
            NamespacePrefix, 
            PC_REST_Field_Name__c, 
            PC_REST_object_name__c, 
            PC_sObject_Field_Name__c,
            PC_Other_REST_Object_Name__c, 
            PC_Other_sObject_API_Name__c
        FROM
            PC_REST_Field_Mapping__mdt
        WHERE
           PC_Other_REST_Object_Name__c =: restObjectName 
        ORDER BY
            PC_REST_Field_Name__c]);

        mapOfIntermediateMappings1.putAll(mapOfIntermediateMappings2);
        return mapOfIntermediateMappings1.values();
    }

    /**
     * Method to get all the relationship mappings in custom meta data.
     *
     * @return Returns list of all the relation ship mappings - List<PC_REST_Object_Relationship_Mapping__mdt>
     */
    global static List<PC_REST_Object_Relationship_Mapping__mdt> getAllRESTRelationshipMappings()
    {
        return [SELECT
                Id,
                DeveloperName,
                MasterLabel,
                NamespacePrefix,
                PC_Child_REST_Object_Name__c,
                PC_Child_sObject_API_Name__c,
                PC_Parent_REST_Object_Name__c,
                PC_Child_Object_Field_API_Name__c,
                PC_Rest_Object_Field_Name__c
        FROM
                PC_REST_Object_Relationship_Mapping__mdt
        ORDER BY
                PC_Child_REST_Object_Name__c LIMIT 2000];
    }

    /**
     * Method to get the REST API mappings in the static resource file PC_RestAPIMappings
     *
     * @return Map of rest fields with it's corresponding API name
     */
    global static Map<string, object> getRestAPIMappings()
    {
        if(mappings == null)
        {
            StaticResource sr = [SELECT
                Body
            FROM
                StaticResource
            WHERE
                Name = 'PC_RestAPIMappings'];
            mappings = (Map<string, object>)JSON.deserializeUntyped(sr.Body.toString());
        }
        return mappings;
    }

    /**
     * Method to get a consolidated list of mappings in the static file as well as the custom meta data
     *
     * @param restObjectName REST object name
     *
     * @return Map of rest field name with it's corresponding API name
     */
    global static Map<string, string> getRESTFieldMappingsMap(string restObjectName)
    {
        Map<String, String> fieldMap = new Map<String, String>();

        Map<String, Object> objectMapping = (Map<String, Object>) getRestAPIMappings().get(restObjectName);
        Map<String, Object> propertyMappings = (Map<String, Object>) objectMapping.get('propertyMappings');

        String orgNs = PC_Constants.OrgNamespace;
        String sObjectFieldNameInFull;
        for (String restFieldName : propertyMappings.keySet()) {
            Map<String, Object> propertyMapping = (Map<String, Object>) propertyMappings.get(restFieldName);
            String sObjectFieldValue;
            if(PC_SYSTEM.isPersonAccountEnabled()) {
                if(propertyMapping.containskey('alternatePersonAccountSObjectFieldName')){
                    sObjectFieldValue = (String) propertyMapping.get('alternatePersonAccountSObjectFieldName');
                } else {
                    sObjectFieldValue = (String) propertyMapping.get('sObjectFieldName');
                }
            } else {
                sObjectFieldValue = (String) propertyMapping.get('sObjectFieldName');
            }

            if(sObjectFieldValue.toLowerCase().endsWith('__c')) {
                if(String.isNotBlank(orgNs)) {
                    sObjectFieldNameInFull = orgNs  + '__' + sObjectFieldValue;
                }
                else {
                    sObjectFieldNameInFull = sObjectFieldValue;
                }
            }
            else {
                sObjectFieldNameInFull = sObjectFieldValue;
            }

            //fieldMap.put(restFieldName, (String) propertyMapping.get('sObjectFieldName'));
            fieldMap.put(restFieldName, sObjectFieldNameInFull);
        }


        String fieldNameInFull;
        for(PC_REST_Field_Mapping__mdt metaDataRecord : getRESTFieldMappings(restObjectName)) {
            String sObjectFieldName = metaDataRecord.PC_sObject_Field_Name__c;

            /*if(sObjectFieldName.toLowerCase().endsWith('__c')) {
                // not a standard field
                if(string.isBlank(metaDataRecord.NamespacePrefix)) {
                    if(String.isNotBlank(orgNs)) {
                    	fieldNameInFull = orgNs  + '__' + sObjectFieldName;
                    }
                    else {
                        fieldNameInFull = sObjectFieldName;
                    }
                }
                else {
                    fieldNameInFull = metaDataRecord.NamespacePrefix + '__' + sObjectFieldName;
                }
                //fieldNameInFull = String.isEmpty(metaDataRecord.NamespacePrefix)
                  //      ? sObjectFieldName : metaDataRecord.NamespacePrefix + '__' + sObjectFieldName;
            }
            else {
                // is a standard field
                fieldNameInFull = sObjectFieldName;
            }*/
            fieldNameInFull = sObjectFieldName;
            System.debug('In getRESTFieldMappingsMap. FieldNameInFull = ' + fieldNameInFull);
            fieldMap.put(metaDataRecord.PC_REST_Field_Name__c, fieldNameInFull);
        }

        return fieldMap;

    }

    /**
     * Method to get a consolidated list of mappings in the static file as well as custom meta data
     *
     * @param restObjectName REST object anme
     *
     * @return Returns map of field API name with its REST field name
     */
    global static Map<string, string> getRESTFieldMappingsMapTransposed(string restObjectName)
    {
        
        if(!objectFieldMappings_mdt_map.isEmpty() && objectFieldMappings_mdt_map.containsKey(restObjectName))
        {
            return objectFieldMappings_mdt_map.get(restObjectName);
        }
        else
        {
            Map<string, string> fieldMap = new  Map<string, string>();
            Map<string, object> objectMapping;
            Map<string, object> propertyMappings;
            Map<string, object> propertyMapping;
            if((Map<string, object>)getRestAPIMappings().get(restObjectName) != null)
                objectMapping = (Map<string, object>)getRestAPIMappings().get(restObjectName);
            if(objectMapping != null && !objectMapping.isEmpty())
                propertyMappings = (Map<string, object>)objectMapping.get('propertyMappings');
            //Map<string, object> objectMapping = (Map<string, object>)getRestAPIMappings().get(restObjectName);
            //Map<string, object> propertyMappings = (Map<string, object>)objectMapping.get('propertyMappings');
            String fn;
            if(propertyMappings != null && !propertyMappings.isEmpty())
            {
                for(string restFieldName: propertyMappings.keySet())
                {
                    propertyMapping = (Map<string, object>)propertyMappings.get(restFieldName);
                    fn = (string)propertyMapping.get('sObjectFieldName');
                    if(fn.endsWith('__c')) {
                        fn = PC_Constants.getQualifiedAPIName(fn);
                    }
                    fn = fn.toUpperCase();
                    fieldMap.put(fn, restFieldName);
                }
            }
            list<PC_REST_Field_Mapping__mdt> test = getRESTFieldMappings(restObjectName);
            for(PC_REST_Field_Mapping__mdt metaDataRecord: getRESTFieldMappings(restObjectName))
            {
                string sObjectFieldName = metaDataRecord.PC_sObject_Field_Name__c;
                string fieldNameInFull;
                if(sObjectFieldName.endsWith('__c'))
                {
                    // not a standard field
                    //fieldNameInFull = string.isEmpty(metaDataRecord.NamespacePrefix) ? sObjectFieldName : metaDataRecord.NamespacePrefix + '__' + sObjectFieldName;
                    fieldNameInFull = sObjectFieldName;
                }
                else
                {
                    // is a standard field
                    fieldNameInFull = sObjectFieldName;
                }

                fieldMap.put(fieldNameInFull.toUpperCase(), metaDataRecord.PC_REST_Field_Name__c);
            }
            objectFieldMappings_mdt_map.put(restObjectName, fieldMap);
            system.debug('fieldMap--'+ fieldMap);
            return fieldMap;
        }
    }
    //Generic Transform Method
    public static List<Map<string, object>> transformSobjectAccounts(List<Account> accounts, string restObjectName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> accountAsMap;
        for(Account acc: accounts)
        {
            returnListItem = new  Map<string, object>();
            accountAsMap = acc.getPopulatedFieldsAsMap();
            for(string key: accountAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), accountAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }
    /**
     * Method to transform map of field API names into map of rest field names
     *
     * @param objectAsMap Map of API name of the fields with their values
     * @param restObjectName REST object name
     *
     * @return Returns map of field API names with their values into map of rest field names with their values
     */
    global static Map<string, object> transformSobject(Map<string, object> objectAsMap, string restObjectName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        Map<string, object> objectMap_trans = new  Map<string, object>();
        for(string key: objectAsMap.keySet())
        {
            if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
            {
                objectMap_trans.put(fieldMappings_mdt_map.get(key.toUpperCase()), objectAsMap.get(key));
            }
        }
        return objectMap_trans;
    }
    public static object getReferenceFieldValue(String restAPIName, SObject obj) {
        List<String> fieldAPINames = restAPIName.split('\\.');
        object referenceFieldValue;
        SObject objectVal;
        for(integer i = 0 ; i < fieldAPINames.size() ; i++){
            String fieldAPIName = fieldAPINames[i];
            if(i == 0){
                objectVal = obj.getSObject(fieldAPIName);
            }else if(objectVal != null && fieldAPIName.containsIgnoreCase('__r')){
                objectVal = objectVal.getSObject(fieldAPIName);
            }else if(objectVal != null){
                referenceFieldValue = objectVal.get(fieldAPIName);
            }
        }
        return referenceFieldValue;
    }
    global static Map<string, object> transformSobject(SObject obj, string restObjectName) {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        Map<string, object> objectMap_trans = new  Map<string, object>();
        for(string key: fieldMappings_mdt_map.keySet()) {
            object fieldValue;
            if(key.containsIgnoreCase('__r')){
                fieldValue = getReferenceFieldValue(key,obj);
            }else{
                fieldValue = obj.get(key);
            }
            if(fieldValue != null){
                objectMap_trans.put(fieldMappings_mdt_map.get(key.toUpperCase()), fieldValue);
            }
        }
        return objectMap_trans;
    }

    //Rohit- <PC-2499> Generic method to transform raw sObject field => value key pair to restfield Name => value pair
    /**
     * Method to transform list of sObjects into list of map containing rest field name with it's value
     *
     * @param listOfsObjects List of sobject containing it's value
     * @param restObjectName REST object name
     *
     * @return transform list of sObjects into list of map containing rest field name with it's value
     */
    global static list<Map<string, object>> transformSobject(list<sObject> listOfsObjects, string restObjectName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        Map<string, object> mapObjectMap_trans = new  Map<string, object>();
        List<Map<string, object>> listOfObjectsMap_trans = new  List<Map<string, object>>();
        Map<string, object> objectMap = new  Map<string, object>();
        string keyVal = PC_Constants.EMPTY_STRING;
        for(sObject obj: listOfsObjects)
        {
            string sObjectAPIName = obj.getSObjectType().getDescribe().getName();
            objectMap = new  map<string, object>();
            mapObjectMap_trans = new  map<string, object>();
            objectMap = obj.getPopulatedFieldsAsMap();
            for(string key: objectMap.keySet())
            {
                keyVal = string.valueOf(objectMap.get(key));
                if(key == PC_RestAPIConstants.RECORD_TYPE_KEY && !fieldMappings_mdt_map.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY))
                {
                    mapObjectMap_trans.put(key.toUpperCase(), keyVal);
                }
                else
                {
                    if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                    {
                        mapObjectMap_trans.put(fieldMappings_mdt_map.get(key.toUpperCase()), keyVal);
                    }
                    else
                    {
                        throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_FIELD_MAPPING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'Rest field mapping is missing for ' + key + ' in ' + +restObjectName + +' info.');
                    }
                }
            }
            listOfObjectsMap_trans.add(mapObjectMap_trans);
        }
        return listOfObjectsMap_trans;
    }

    /**
     * Method to transform Map of rest field names with their values into a map of API field names with their values
     *
     * @param objectMap Map of rest field names with their values
     * @param restObjectName REST object name
     *
     * @return returns map of API field names with their values
     */
    global static Map<string, object> transformRESTObject(Map<string, object> objectMap, string restObjectName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMap(restObjectName);
        Map<string, object> objectMap_trans = new  Map<string, object>();
        string keyVal = PC_Constants.EMPTY_STRING;
        for(string key: objectMap.keySet())
        {
            keyVal = string.valueOf(objectMap.get(key));
            if(key.equalsIgnoreCase(PC_RestAPIConstants.RECORD_TYPE_KEY))
            {
                objectMap_trans.put(key, keyVal);
            }
            else
            {
                if(fieldMappings_mdt_map.containsKey(key))
                {
                    objectMap_trans.put(fieldMappings_mdt_map.get(key), keyVal);
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_FIELD_MAPPING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'Rest field mapping is missing for ' + key + ' in ' + restObjectName + ' info.');
                }
            }
            
        }
        return objectMap_trans;
    }

    /**
     * Method to transform list of a map containing rest field name with their values into a list of map containing field API names with their field values
     *
     * @param objectsMap List of object with each object being a map of field name with it's field value
     * @param restObjectName REST object name
     *
     * @return Returns list of map containing field API names with their field values
     */
    global static List<Map<string, object>> transformRESTObjects(List<object> objectsMap, string restObjectName)
    {
        
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMap(restObjectName);
        List<Map<string, object>> objectsMap_trans = new  List<Map<string, object>>();
        Map<string, object> objectMap;
        Map<string, object> objectMap_trans;
        for(object objectObj: objectsMap)
        {               
            objectMap = new  Map<string, object>();
            objectMap = (Map<string, object>)objectObj;           
            string keyVal = PC_Constants.EMPTY_STRING;
            objectMap_trans = new  Map<string, object>();
            for(string key: objectMap.keySet())
            {                
                keyVal = string.valueOf(objectMap.get(key));               
                if(key == PC_RestAPIConstants.RECORD_TYPE_KEY && !fieldMappings_mdt_map.containsKey(PC_RestAPIConstants.RECORD_TYPE_KEY))
                {
                    objectMap_trans.put(key, keyVal);
                }
                else
                {
                    if(fieldMappings_mdt_map.containsKey(key))
                    {
                        objectMap_trans.put(fieldMappings_mdt_map.get(key).toUpperCase(), keyVal);
                    }
                    else
                    {
                        throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_FIELD_MAPPING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'Rest field mapping is missing for ' + key + ' in ' + +restObjectName + +' info.');
                    }
                }
            }
            objectsMap_trans.add(objectMap_trans);
        }       
        return objectsMap_trans;
    }
    //Generic Transform Method Ends
    public static List<Map<string, object>> transformSobjectCases(List<case> cases, string restObjectName)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(restObjectName);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> caseAsMap;
        for(Case c: cases)
        {
            returnListItem = new  Map<string, object>();
            caseAsMap = c.getPopulatedFieldsAsMap();
            for(string key: caseAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), caseAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }
    public static List<Map<string, object>> transformSobjectAssociations(List<PC_Association__c> associations)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ASSOCIATION);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> associationAsMap;
        for(PC_Association__c association: associations)
        {
            returnListItem = new  Map<string, object>();
            associationAsMap = association.getPopulatedFieldsAsMap();
            for(string key: associationAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), associationAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }


    public static List<Map<string, object>> transformSobjectSuspectPrescriptions(List<PC_Suspect_Prescription__c> suspectPrescriptions)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_SUSPECT_PRESCRIPTION);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> suspectPrescriptionAsMap;
        for(PC_Suspect_Prescription__c suspectPrescription: suspectPrescriptions)
        {
            returnListItem = new  Map<string, object>();
            suspectPrescriptionAsMap = suspectPrescription.getPopulatedFieldsAsMap();
            for(string key: suspectPrescriptionAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), suspectPrescriptionAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }

    public static List<Map<string, object>> transformSobjectAddresses(List<PC_Address__c> addresses)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> addressAsMap;
        for(PC_Address__c addr: addresses)
        {
            returnListItem = new  Map<string, object>();
            addressAsMap = addr.getPopulatedFieldsAsMap();
            for(string key: addressAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), addressAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }
    public static List<Map<string, object>> transformSobjectHealthPlans(List<PC_Health_Plan__c> healthPlans)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> healthPlanAsMap;
        for(PC_Health_Plan__c hp: healthPlans)
        {
            returnListItem = new  Map<string, object>();
            healthPlanAsMap = hp.getPopulatedFieldsAsMap();
            for(string key: healthPlanAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), healthPlanAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }
    public static List<Map<string, object>> transformSobjectAdverseEvents(List<PC_AdverseEvent__c> adverseEvents)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> adverseEventAsMap;
        for(PC_AdverseEvent__c av: adverseEvents)
        {
            returnListItem = new  Map<string, object>();
            adverseEventAsMap = av.getPopulatedFieldsAsMap();
            for(string key: adverseEventAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), adverseEventAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }
    public static List<Map<string, object>> transformSobjectAdverseEvents2(List<PC_AdverseEvent2__c> adverseEvents)
    {
        Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(PC_RestAPIConstants.REST_OBJECT_NAME_ADVERSE_EVENT2);
        List<Map<string, object>> returnList = new  List<Map<string, object>>();
        Map<string, object> returnListItem;
        Map<string, object> adverseEventAsMap;
        for(PC_AdverseEvent2__c av: adverseEvents)
        {
            returnListItem = new  Map<string, object>();
            adverseEventAsMap = av.getPopulatedFieldsAsMap();
            for(string key: adverseEventAsMap.keySet())
            {
                if(fieldMappings_mdt_map.containsKey(key.toUpperCase()))
                {
                    returnListItem.put(fieldMappings_mdt_map.get(key.toUpperCase()), adverseEventAsMap.get(key));
                }
            }
            returnList.add(returnListItem);
        }
        return returnList;
    }
    
    public static Map<string, object> removeIdField(Map<string, object> inputMap)
    {
        Map<string, object> returnMap = inputMap;
        if(returnMap.containsKey(PC_RestAPIConstants.ID_KEY))
        {
            returnMap.remove(PC_RestAPIConstants.ID_KEY);
        }
        return returnMap;
    }
    public static List<object> removeIdField(List<object> inputMapObjects)
    {
        List<object> returnMapObjects = new  List<object>();
        Map<string, object> returnMapObject;
        for(object inputMapObject: inputMapObjects)
        {
            returnMapObject = new  Map<string, object>();
            returnMapObject = (Map<string, object>)inputMapObject;
            if(returnMapObject.containsKey(PC_RestAPIConstants.ID_KEY))
            {
                returnMapObject.remove(PC_RestAPIConstants.ID_KEY);
            }
            if(returnMapObject.containsKey(PC_RestAPIConstants.ADVERSEEVENT_ID_KEY)){
                returnMapObject.remove(PC_RestAPIConstants.ADVERSEEVENT_ID_KEY);
            }
            returnMapObjects.add(returnMapObject);
        }
        return returnMapObjects;
    }
    public static Map<string, string> logDBSaveResultErrorMessage(Database.SaveResult result, string additionalInfo)
    {
        Map<string, string> errorMessageMap = new  Map<string, string>();
        if(result.isSuccess())
        {
            return errorMessageMap;
        }
        else
        {
            string errorLogRef = PC_Utility.createErrorLog(JSON.serialize(result.getErrors()), additionalInfo);
            errorMessageMap.put(PC_RestAPIConstants.ERROR_ERROR_CODE, string.valueOf(PC_RestAPIConstants.ErrorCode.APEX_ERROR));
            errorMessageMap.put(PC_RestAPIConstants.ERROR_ERROR_TYPE, string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION));
            errorMessageMap.put(PC_RestAPIConstants.ERROR_ERROR_MESSAGE, JSON.serialize(result.getErrors()));
            errorMessageMap.put(PC_RestAPIConstants.ERROR_ERROR_LOG_REF, errorLogRef);
        }
        return errorMessageMap;
    }
    /*global static RestResponse logAndSetRestExceptionResponse(
    RestResponse res, String inputString, integer statusCode,
    PC_RestAPIConstants.ErrorCode errorCode, PC_RestAPIConstants.ErrorType errorType, String errorMessage,
    Exception e)
    {
    String errorLogRef = '';
    if(e != null) {
    errorLogRef = PC_Utility.createExceptionLog(e, inputString);
    }
    
    res.addHeader('Content-Type', 'application/json;charset=UTF-8');
    res.statusCode = statusCode;
    String responseBodyMessage = PC_RestException.getExceptionMessage(errorCode,errorType,errorMessage,errorLogRef);
    res.responseBody = Blob.valueOf(responseBodyMessage);
    
    return res;
    }*/
    /*global static RestResponse logAndSetRestExceptionResponse(
    RestRequest req, RestResponse res, String inputString, integer statusCode,
    PC_RestAPIConstants.ErrorCode errorCode, PC_RestAPIConstants.ErrorType errorType, String errorMessage,
    Exception e)
    {
    String errorLogRef = '';
    if(e != null) {
    String requestURL = getRequestURL(req);
    errorLogRef = PC_Utility.createExceptionLog(e, req.httpMethod + ' ' + requestURL + '\n' + inputString);
    }
    
    res.addHeader('Content-Type', 'application/json;charset=UTF-8');
    res.statusCode = statusCode;
    String responseBodyMessage = PC_RestException.getExceptionMessage(errorCode,errorType,errorMessage,errorLogRef);
    res.responseBody = Blob.valueOf(responseBodyMessage);
    
    return res;
    }*/

    /**
     * Method to log exception and set the appropriate response
     *
     * @param req RestRequest object
     * @param res RestResponse object
     * @param inputString URL identifier
     * @param statusCode Status code identifiable by the browsers like 400, 404, 500.
     * @param errorCode Categorization of the error.
     *                  Valid values - APEX_ERROR, INVALID_ARGUMENTS, MISSING_FIELD_MAPPING, INVALID_JSON_INPUT, MANDATORY_FIELDS_MISSING, NO_RESULTS, SOQL_LIMITATION
     * @param errorType Categorization of the error.
     *                  Valid values - APPLICATION, PATIENT_CONNECT
     * @param errorMessage Error message to be logged
     * @param e Exception object
     *
     * @return return RestResponse
     */
    global static RestResponse logAndSetRestExceptionResponse(RestRequest req, RestResponse res, string inputString, integer statusCode, string errorCode, string errorType, string errorMessage, Exception e)
    {
        string errorLogRef = PC_Constants.EMPTY_STRING;
        if(e != null)
        {
            string requestURL = getRequestURL(req);
            errorLogRef = PC_Utility.createExceptionLog(e, req.httpMethod + ' ' + requestURL + '\n' + inputString);
        }
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        res.statusCode = statusCode;
        string responseBodyMessage = PC_RestException.getExceptionMessage(errorCode, errorType, errorMessage, errorLogRef);
        res.responseBody = Blob.valueOf(responseBodyMessage);
        return res;
    }
    /*global static RestResponse logAndSetRestExceptionResponse(
    RestResponse res, String inputString, integer statusCode,
    String errorCode, String errorType, String errorMessage,
    Exception e)
    {
    String errorLogRef = '';
    if(e != null) {
    errorLogRef = PC_Utility.createExceptionLog(e, inputString);
    }
    
    res.addHeader('Content-Type', 'application/json;charset=UTF-8');
    res.statusCode = statusCode;
    String responseBodyMessage = PC_RestException.getExceptionMessage(errorCode,errorType,errorMessage,errorLogRef);
    res.responseBody = Blob.valueOf(responseBodyMessage);
    
    return res;
    }*/
    public static boolean validateMandatoryFieldsOfPatiet(Map<string, object> reqPatient)
    {
        return (reqPatient.containsKey(PC_RestAPIConstants.PATIENT_FIRST_NAME_KEY) && string.isNotBlank(string.valueOf(reqPatient.get(PC_RestAPIConstants.PATIENT_FIRST_NAME_KEY)))) && (reqPatient.containsKey(PC_RestAPIConstants.PATIENT_LAST_NAME_KEY) && string.isNotBlank(string.valueOf(reqPatient.get(PC_RestAPIConstants.PATIENT_LAST_NAME_KEY)))) && (reqPatient.containsKey(PC_RestAPIConstants.PATIENT_DOB_KEY) && string.isNotBlank(string.valueOf(reqPatient.get(PC_RestAPIConstants.PATIENT_DOB_KEY))));
    }
    public static boolean validateMandatoryFieldsOfApplicant(Map<string, object> reqApplicant)
    {
        return (reqApplicant.containsKey(PC_RestAPIConstants.APPLICANT_FIRST_NAME_KEY) && string.isNotBlank(string.valueOf(reqApplicant.get(PC_RestAPIConstants.APPLICANT_FIRST_NAME_KEY)))) && (reqApplicant.containsKey(PC_RestAPIConstants.APPLICANT_LAST_NAME_KEY) && string.isNotBlank(string.valueOf(reqApplicant.get(PC_RestAPIConstants.APPLICANT_LAST_NAME_KEY)))) && (reqApplicant.containsKey(PC_RestAPIConstants.APPLICANT_DOB_KEY) && string.isNotBlank(string.valueOf(reqApplicant.get(PC_RestAPIConstants.APPLICANT_DOB_KEY))));
    }

    /**
     * Exception handler class. Logs and sets the exception response.
     *
     * @param req RestRequest object
     * @param res RestResponse object. Passed as reference. This method sets the response body with the exception and logged error details.
     * @param e Exception object
     * @param reqString URL identifier
     *
     */
    global static void exceptionHandler(RestRequest req, RestResponse res, Exception e, string reqString)
    {
        string errorCode;
        string errorType;
        string errorMessage;
        integer statusCode = 500;
        if(e  instanceof  System.QueryException)
        {
            errorCode = string.valueOf(PC_RestAPIConstants.ErrorCode.APEX_ERROR);
            errorType = string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION);
            errorMessage = string.valueOf(PC_RestAPIConstants.ERRORMESSAGE_QUERY_EXCEPTION);
            statusCode = 500;
            //reqString = e.getTypeName() + '\n' + '1' + '\n' + reqString;
        }
        else if(e  instanceof  System.JSONException)
        {
            errorCode = string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT);
            errorType = string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION);
            errorMessage = string.valueOf(PC_RestAPIConstants.ERRORMESSAGE_INVALID_JSON_INPUT);
            statusCode = 500;
            //reqString = e.getTypeName() + '\n' + '1' + '\n' + reqString;
        }
        else if(e  instanceof  PC_RestException)
        {
            PC_RestException pcEx = (PC_RestException)e;
            errorCode = pcEx.errorCode;
            errorType = pcEx.errorType;
            errorMessage = pcEx.getMessage();
            statusCode = 400;
            //reqString = e.getTypeName() + '\n' + '2' + '\n' + reqString;
        }
        else
        {
            errorCode = string.valueOf(PC_RestAPIConstants.ErrorCode.APEX_ERROR);
            errorType = string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION);
            errorMessage = e.getMessage();
            statusCode = 500;
            //reqString = e.getTypeName() + '\n' + '3' + '\n' + reqString;
        }
        PC_RestAPIUtilities.logAndSetRestExceptionResponse(req, res, reqString, 500, errorCode, errorType, errorMessage, e);
    }
    public static LIst<sObject> recordSearchViaRequestFilter(Map<string, string> reqHeaders, string restObjectName, string objectName)
    {
        if(reqHeaders != null && reqHeaders.containsKey(PC_RestAPIConstants.CUSTOM_SEARCH_HEADER_KEY))
        {
            Map<string, object> mapCustomFilters = (Map<string, object>)JSON.deserializeUntyped(reqHeaders.get(PC_RestAPIConstants.CUSTOM_SEARCH_HEADER_KEY));
            if(mapCustomFilters != null && mapCustomFilters.containsKey(restObjectName))
            {
                Map<string, object> customFilters = (Map<string, object>)JSON.deserializeUntyped(JSON.serialize(mapCustomFilters.get(restObjectName)));
                if(customFilters != null && customFilters.containsKey('where') && string.isNotBlank(string.valueOf(customFilters.get('where'))))
                {
                    Map<string, string> mapFieldMappings = PC_RestAPIUtilities.getRESTFieldMappingsMap(restObjectName);
                    string strWhereClause = PC_Constants.EMPTY_STRING;
                    strWhereClause = string.valueOf(customFilters.get('where'));
                    for(string str: mapFieldMappings.keySet())
                    {
                        if(strWhereClause.contains(str))
                        {
                            strWhereClause = strWhereClause.replaceAll(str, mapFieldMappings.get(str));
                        }
                    }
                    List<string> fields = new  List<string>();
                    fields.addAll(mapFieldMappings.values());
                    string queryFields = string.join(fields, ',');
                    string query = 'SELECT ' + queryFields + ' FROM ' + objectName + ' WHERE ' + strWhereClause;
                    system.debug(query);
                    List<sObject> objectList = PC_Database.queryWithAccess(query, true);
                    if(objectList != null && !objectList.isEmpty())
                    {
                        return objectList;
                    }
                    else
                    {
                        throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.CUSTOM_SEARCH_NO_RECORD_FOUND);
                    }
                }
                else
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), string.valueOf(PC_RestAPIConstants.CUSTOM_SEARCH_WHERE_CLAUSE_MISSING));
                }
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), string.valueOf(restObjectName + PC_RestAPIConstants.CUSTOM_SEARCH_SEARCH_LOGIC_MISSING));
            }
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), string.valueOf(PC_RestAPIConstants.CUSTOM_SEARCH_HEADER_KEY_MISSING));
        }
    }
    
    public static map<string, string> prepareReqParamMap(map<string, string> reqParameters)
    {
        Map<string, string> reqParams = new  Map<string, string>();
        for(string key: reqParameters.keySet())
        {
            reqParams.put(key, string.escapeSingleQuotes(reqParameters.get(key)));
        }
        return reqParams;
    }
    
    public static LIst<sObject> recordSearchViaRequestParams(Map<string, string> reqParameters, string patientClassKey, Boolean hasPatientClass, string restObjectName, string objectName)
    {
        Map<string, string> reqParams = prepareReqParamMap(reqParameters);

        //check if mandatory fields are present in the request parameters or not                  
        if(PC_RestAPIUtilities.mandatoryFieldSCheck(reqParams.keySet(), PC_RestAPIConstants.PATIENT_SEARCH_MANDATORY_FIELDS))
        {
            Map<string, string> mapFieldMappings = PC_RestAPIUtilities.getRESTFieldMappingsMap(restObjectName);
            for(string key: reqParams.keySet())
            {
                //throw exception if mapping is not defined
                if(!mapFieldMappings.containsKey(key))
                {
                    throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MISSING_FIELD_MAPPING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), 'Rest field mapping is missing for ' + key + ' in ' + +restObjectName + +' info.');
                }
            }
            List<string> listStr = mapFieldMappings.values();
            string str = JSON.serialize(listStr);
            string strWhere = PC_Constants.EMPTY_STRING;
            str = str.replace('","', ',');
            str = str.replace('["', '');
            str = str.replace('"]', '');
            string strSearchString = '\'' + string.valueOf(reqParams.get(PC_RestAPIConstants.PATIENT_FIRST_NAME_KEY)) + '\'' + ' AND ' + '\'' + string.valueOf(reqParams.get(PC_RestAPIConstants.PATIENT_LAST_NAME_KEY)) + '\'';
            //filter records on manufacturerId if present in request
            //strWhere = ' WHERE RecordTypeId IN (SELECT ID FROM RecordType WHERE DeveloperName = ' + '\''+PC_Constants.PATIENT_RECORD_TYPE+'\'' + ' AND  SobjectType = ' + '\'Account\'' + ') ';
            String patientRecordTypes = PC_Constants.EMPTY_STRING;
            if(hasPatientClass && string.isNotBlank(patientClassKey)){
                patientRecordTypes += '(\'' +  PC_RestAPIUtilities.getPatientRecordType(patientClassKey)+ '\')';
            }else{
                patientRecordTypes = getPatientRecordTypesList();
            }
            strWhere = ' WHERE RecordTypeId IN ' +patientRecordTypes;

            if(reqParams.containsKey(PC_RestAPIConstants.MANUFACTURER_ID) && string.isNotBlank(reqParams.get(PC_RestAPIConstants.MANUFACTURER_ID)))
            {
                strWhere += ' AND ' + mapFieldMappings.get(PC_RestAPIConstants.MANUFACTURER_ID) + ' = \'' + reqParams.get(PC_RestAPIConstants.MANUFACTURER_ID) + '\' ';
                reqParams.remove(PC_RestAPIConstants.MANUFACTURER_ID);
            }
            String limitQuery = ' LIMIT 100';
            LIST<LIST<sObject>> lstPatients = search.query('FIND :strSearchString IN ALL FIELDS RETURNING Account(' + str + strWhere + limitQuery +  ')');
            system.debug('done');
            LIST<Account> lstAccount = new  List<Account>();
            boolean addFlag = true;
            if(Test.isRunningTest()){
                List<Account> lstAccountTest = Database.query('select '+str+' from account '+strWhere);
                lstPatients[0] = lstAccountTest;
            }
            for(Account objAccount: ((List<Account>)lstPatients[0]))
            {
                addFlag = true;
                string[] strDate = reqParams.get(PC_RestAPIConstants.PATIENT_DOB_KEY).split('/');
                Integer intDate = integer.valueOf(strDate[1]);
                Integer intMonth = integer.valueOf(strDate[0]);
                Integer intYear = integer.valueOf(strDate[2]);
                Date dateOfBirth = Date.newInstance(intYear, intMonth, intDate);
                if((reqParams.get(PC_RestAPIConstants.PATIENT_FIRST_NAME_KEY).equalsIgnoreCase(string.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_FIRST_NAME_KEY))))) && (reqParams.get(PC_RestAPIConstants.PATIENT_LAST_NAME_KEY).equalsIgnoreCase(string.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_LAST_NAME_KEY))))) && (Date.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_DOB_KEY))) == dateOfBirth) && ((reqParams.containsKey(PC_RestAPIConstants.PATIENT_PHONE_KEY) && string.valueOf(reqParams.get(PC_RestAPIConstants.PATIENT_PHONE_KEY)).replaceAll(PC_RestAPIConstants.REGULAREXP_ONLY_DIGITS, '').equalsIgnoreCase(string.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_PHONE_KEY))).replaceAll(PC_RestAPIConstants.REGULAREXP_ONLY_DIGITS, ''))) || !reqParams.containsKey(PC_RestAPIConstants.PATIENT_PHONE_KEY)) && ((reqParams.containsKey(PC_RestAPIConstants.PATIENT_GENDER_KEY) && string.valueOf(reqParams.get(PC_RestAPIConstants.PATIENT_GENDER_KEY)).equalsIgnoreCase(string.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_GENDER_KEY))))) || !reqParams.containsKey(PC_RestAPIConstants.PATIENT_GENDER_KEY)) && ((reqParams.containsKey(PC_RestAPIConstants.PATIENT_ZIP_KEY) && string.valueOf(reqParams.get(PC_RestAPIConstants.PATIENT_ZIP_KEY)).equalsIgnoreCase(string.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_ZIP_KEY))))) || !reqParams.containsKey(PC_RestAPIConstants.PATIENT_ZIP_KEY)))
                {
                    lstAccount.add(objAccount);
                }
                //ToDo Generic code for if
                //================================================
                /*
                for(string key: reqParams.keySet())
                {
                    Schema.DisplayType fieldType = Account.getSObjectType().getDescribe().fields.getMap().get(mapFieldMappings.get(key)).getDescribe().getType();
                    if(fieldType == Schema.DisplayType.DATE)
                    {
                        string[] strDate = reqParams.get(key).split('/');
                        Integer intDate = integer.valueOf(strDate[1]);
                        Integer intMonth = integer.valueOf(strDate[0]);
                        Integer intYear = integer.valueOf(strDate[2]);
                        Date dateOfBirth = Date.newInstance(intYear, intMonth, intDate);
                        if(dateOfBirth != Date.valueOf(objAccount.get(mapFieldMappings.get(PC_RestAPIConstants.PATIENT_DOB_KEY))))
                        {
                            addFlag = false;
                            break;
                        }
                    }
                    else if(fieldType == Schema.DisplayType.PHONE && !(string.valueOf(objAccount.get(mapFieldMappings.get(key))).replaceAll(PC_RestAPIConstants.REGULAREXP_ONLY_DIGITS, '').equalsIgnoreCase(string.valueOf(reqParams.get(key)).replaceAll(PC_RestAPIConstants.REGULAREXP_ONLY_DIGITS, '')))){
                        addFlag = false;
                        break;
                    }
                    else if(!string.valueOf(objAccount.get(mapFieldMappings.get(key))).equalsIgnoreCase(string.valueOf(reqParams.get(key))))
                    {
                        addFlag = false;
                        break;
                    }
                }
                if(addFlag)
                {
                    lstAccount.add(objAccount);
                }
                //================================================
                */
            }
            if(lstAccount != null && !lstAccount.isEmpty())
            {
                return lstAccount;
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ACCOUNT_NO_ACCOUNT_FOUND);
            }
        }
        else
        {
            throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_JSON_INPUT), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), string.valueOf('Mandatory search filter field missing'));
        }
    }
    public static boolean mandatoryFieldSCheck(set<string> actualFieldSet, set<string> requiredFieldSet)
    {
        return actualFieldSet.containsAll(requiredFieldSet);
    }

    /**********************************************************************************************
    Method Name    : getChildObjectsToFetch
    Description    : PC-2498 - traversing relationships/ Patient related objects to fetch 
    parameters     : Request Parameter, Patient Rest Object Name
    Return Type    : string 
    **********************************************************************************************/
    public static string getChildObjectsToFetch( map<string, string> reqParameters, string restObjectName)
    {
        Map<string, string> reqParams = prepareReqParamMap(reqParameters);
        string childObjectsToFetch;
        if(reqParams.containsKey(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_KEY)
            && reqParams.get(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_KEY) != null)
        {
            if(reqParams.get(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_KEY) == PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_SPECIFIED)
            {
                childObjectsToFetch = reqParams.get(PC_RestAPIConstants.PATIENT_RELATIONSHIPS_KEY);
            }
            else if(reqParams.get(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_KEY) == PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_ALL)
            {
                childObjectsToFetch =PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_ALL;
            }
            else if(reqParams.get(PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_KEY) == PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_NONE)
            {
                childObjectsToFetch =PC_RestAPIConstants.PATIENT_RELATIONSHIP_SCOPE_NONE;
            }

            if(string.isBlank(childObjectsToFetch))
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS),
                                            string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),
                                            PC_RestAPIConstants.SPECIFIED_CHILD_OBJECTS_TO_FETCH_MISSING);
            }
            else
            {
                //return childObjectsToFetch.tolowerCase();
                return childObjectsToFetch;
            }
        }

        return null;
    }

    /**
     * Method to get REST ojbect relationship mappings from custom meta data
     *
     * @param restObjectName REST ojbect name
     *
     * @return Returns list of PC_REST_Object_Relationship_Mapping__mdt
     */
    global static List<PC_REST_Object_Relationship_Mapping__mdt> getRESTObjectRelationShipMappings(string restObjectName)
    {
        return [SELECT
                    Id, 
                    DeveloperName, 
                    MasterLabel, 
                    NamespacePrefix, 
                    PC_Child_REST_Object_Name__c, 
                    PC_Child_sObject_API_Name__c, 
                    PC_Parent_REST_Object_Name__c,
                    PC_Rest_Object_Field_Name__c,
                    PC_Child_Object_Field_API_Name__c

                    FROM
                        PC_REST_Object_Relationship_Mapping__mdt
                    WHERE
                        PC_Parent_REST_Object_Name__c = : restObjectName
                    ORDER BY
                        PC_Child_REST_Object_Name__c];
    }

    /**********************************************************************************************
    Method Name    : traverseRestObjectRelationships
    Description    : PC-2498 - To preapre map from MetaData Rest Object Relationship Mapping
                     - Child Rest Object Name and its corresponding mdt record 
    parameters     : Parent Rest Object Name
    Return Type    : map<string, PC_REST_Object_Relationship_Mapping__mdt>   
    **********************************************************************************************/

    /**
     * Method to get a map of REST child object name with it's relationship mapping
     *
     * @param restObjectName REST object name
     *
     * @return Map of rest child object name with it's relationship mapping  map<string, PC_REST_Object_Relationship_Mapping__mdt>
     */
    global static  map<string, PC_REST_Object_Relationship_Mapping__mdt> traverseRestObjectRelationships(string restObjectName)
    {
        map<string, PC_REST_Object_Relationship_Mapping__mdt> childsMdtMap = new map<string, PC_REST_Object_Relationship_Mapping__mdt>();
        for(PC_REST_Object_Relationship_Mapping__mdt restObjectRelationshipMappings : getRESTObjectRelationShipMappings(restObjectName))
        {
            if(restObjectRelationshipMappings != null)
            {
                childsMdtMap.put(restObjectRelationshipMappings.PC_Child_REST_Object_Name__c, restObjectRelationshipMappings);
            }
        }
        return childsMdtMap;
    }
    
    /**********************************************************************************************
    Method Name    : getChildObjectsByParentId
    Description    : PC-2498 -To prepare a map of map of Rest Object Name to show in response (key)
                     and map of Child Rest Object Name and its corresponding mdt record
    parameters     : Parent Rest Object Name, Parent Record ID
    Return Type    : map<string, map<string, List<sObject>>>   
    **********************************************************************************************/
    public static map<string, map<string, List<sObject>>> getChildObjectsByParentId(string parentRestObjectName,
                                                                                    string parentId)
    {
        map<string,PC_REST_Object_Relationship_Mapping__mdt> mapOfChildMdtRecord = traverseRestObjectRelationships(parentRestObjectName);
        PC_REST_Object_Relationship_Mapping__mdt parentChildMDTRecord;
        map<string, List<sObject>> mapOfChildRestObjects = new map<string, list<sObject>>();
        map<string, map<string, List<sObject>>> mapofmapOfChildRestObjects = new map<string, map<string, List<sObject>>>();
        List<sObject> childsObjects;
        for(string mapKey : mapOfChildMdtRecord.keySet())
        {
            mapOfChildRestObjects = new map<string, list<sObject>>();
            
            parentChildMDTRecord = mapOfChildMdtRecord.get(mapKey);
            
            Map<string, string> fieldMappings_mdt_map = getRESTFieldMappingsMapTransposed(parentChildMDTRecord.PC_Child_REST_Object_Name__c);
            List<string> fields = new  List<string>();
            fields.addAll(fieldMappings_mdt_map.keySet());
            string queryFields = string.join(fields, ',');
            string query = 'SELECT ' + queryFields + ' FROM ' + parentChildMDTRecord.PC_Child_sObject_API_Name__c +' WHERE ' +  parentChildMDTRecord.PC_Child_Object_Field_API_Name__c +'= ' + '\'' + parentId + '\'';
            system.debug(query);
            childsObjects = PC_Database.queryWithAccess(query, true);
            
            mapOfChildRestObjects.put(mapKey, childsObjects);
            map<string, map<string, List<sObject>>>mapofmapOfChildRestObjects_Intermediate = new map<string, map<string, List<sObject>>>();
            
            mapofmapOfChildRestObjects_Intermediate.put(parentChildMDTRecord.PC_Rest_Object_Field_Name__c, mapOfChildRestObjects);
            mapofmapOfChildRestObjects.putAll(mapofmapOfChildRestObjects_Intermediate);
        }

        system.debug('mapOfChildRestObjects--'+ mapofmapOfChildRestObjects);
        if(mapofmapOfChildRestObjects != null && !mapofmapOfChildRestObjects.isEmpty())
        {
            return mapofmapOfChildRestObjects;
        }
        else
        {
            return new  map<string, map<string, List<sObject>>>();
        }
    }

    /**********************************************************************************************
    Method Name    : removeProcessedObject
    Description    : PC-2498 -To remove already process objects from ChildObject of a patient to 
                     fetch
    parameters     : String childToFetch, string Rest Object Name
    Return Type    :string    
    **********************************************************************************************/
    public static string removeProcessedObject(string childToFetch, string objectName)
    {
        if(string.isNotBlank(childToFetch)
            && childToFetch.contains(objectName))
        {
            return childToFetch.remove(objectName);
        }
        else
        {
            return childToFetch;
        }
    }

    /**********************************************************************************************
    Method Name    : removeProcessedObject
    Description    : PC-2498 - to prepare the map with values having Rest Object Name to show in 
                      response
    parameters     : string, string child Rest obj name
    Return Type    : map<string, string>   
    **********************************************************************************************/
    public static map<string, string> createMapOfKeys(string mapKey, set<string> innerMapKeys)
    {
        map<string, string> mapOfKeys = new map<string, string>();
        for(string innerMapKey : innerMapKeys)
        {
            if(mapKey != null && innerMapKey != null)
            {
                //if(mapKey.containsIgnoreCase(innerMapKey))
                if(mapKey.equalsIgnoreCase(innerMapKey))
                {
                    map<string, string> mapOfKeys_Intermediate = new map<string, string>{innerMapKey=> mapKey};
                   
                    mapOfKeys.putAll(mapOfKeys_Intermediate);
                }
            }
        } 
        
        return mapOfKeys;
    }

    /**********************************************************************************************
    Method Name    : getPatientRecordTypesList
    Description    : PC-4214 Get all Patient record types from Individual Record Type Mapper Custom metadata type
                        including PC_Patient
    Return Type    :string
    **********************************************************************************************/
    public static string getPatientRecordTypesList()
    {
        String patientRecordTypes = '\'' +  PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PATIENT_RECORD_TYPE)+ '\',';
        HealthCloudGA__IndividualRecordTypeMapper__mdt[] recordTypeMappers = [SELECT HealthCloudGA__AccountRecordTypeNamespace__c,
                HealthCloudGA__AccountRecordType__c,DeveloperName,NamespacePrefix
        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt LIMIT 2000];

        String recordTypeName, recordTypeNameSpace;

        if(!recordTypeMappers.isEmpty()){
            for(HealthCloudGA__IndividualRecordTypeMapper__mdt individualMapper: recordTypeMappers){
                recordTypeName = individualMapper.HealthCloudGA__AccountRecordType__c;
                recordTypeNameSpace = individualMapper.HealthCloudGA__AccountRecordTypeNamespace__c;
                if(recordTypeName == PC_Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE && recordTypeNameSpace == PC_Constants.ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAMESPACE){
                    recordTypeNameSpace = individualMapper.NamespacePrefix;
                }
                patientRecordTypes += '\'' + PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, recordTypeName, recordTypeNameSpace) + '\',';
            }
            patientRecordTypes = patientRecordTypes.lastIndexOf(',') > 0 ? '(' + patientRecordTypes.substring(0,patientRecordTypes.lastIndexOf(',')) + ')' : patientRecordTypes ;
        }
        return patientRecordTypes;
    }

}