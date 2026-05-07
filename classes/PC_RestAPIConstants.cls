/*********************************************************************************************************
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Vijay Kashikar                 Jul 27, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Added constants
Rohit Kapoor                   Dec 08, 2017           <PC-2498> -  PC-2498 As an external system (mobile/web application), 
                                                        want to retrieve basic patient information
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
Vijay Kashikar                 Jan 25, 2018           <PC-2663> - Constants renamed.
Vijay Kashikar                 Jan 11, 2018           <PC-2712> - Removed global scope for some of the constant as they don't have to be global
Vijay Kashikar                 20 Sep, 2018           [PC-3649] Added a new values for errorCode and errorType
Haritha Reddy                  Jan 22, 2019           <PC-4248> - Added a Constant and new value to errorCode
Mike Klumpenaar                Feb 20, 2019                   [PC-4475] Convert to apex doc.
Vijay Kashikar                 Apr 01, 2019           <PC-2646> - Added SOSL Limit constants
Haritha Reddy                  21-Jan-2021            [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Haritha Reddy                  08-Jun-2021            [PC-7683] Added a constant to hold Account Rest API object
Haritha Reddy                  14-Jun-2021            [PC-7388] Added constants related to engagement program settings rest service
Haritha Reddy                  16-Jun-2021            [PC-7387] Added constants related to Interaction rest service
****************************************************************************************************************/

/**
 * REST Constants Class
 *
 * @date 2017-0-27
 */
global inherited sharing class PC_RestAPIConstants {
    public static Final String ERRORMESSAGE_ID_MISSING = 'id parameter value is missing';
    public static Final String ERRORMESSAGE_QUERY_EXCEPTION = 'failed to execute the query';
    public static Final String ERRORMESSAGE_INVALID_JSON_INPUT= 'invalid JSON';
    public static Final String ERRORMESSAGE_INVALID_RECORD_ID= 'invalid record id';
    public static Final String ERRORMESSAGE_QUERY_PARAMETERS_MISSING = 'Query parameters are missing';
    public static Final String ERRORMESSAGE_MANUFACTURER_FINDBYNAME_MISSING = 'findByName parameter value is missing';
    public static Final String ERRORMESSAGE_PAYER_FINDBYNAME_MISSING = 'findByName parameter value is missing';
    public static Final String ERRORMESSAGE_PROVIDER_FINDBYNPI_MISSING = 'findByNPI parameter value is missing';
    public static Final String ERRORMESSAGE_PROGRAM_FINDBYCODE_MISSING = 'findByCode parameter value is missing';
    public static Final String ERRORMESSAGE_PROGRAM_FINDBYPROGRAMID_MISSING = 'findByProgramId parameter value is missing';
    public static Final String ERRORMESSAGE_ACCOUNT_FILTERS_MISSING = 'Filters are missing. Please add at least one filter';
    public static Final String ERRORMESSAGE_PATIENT_MANDATORY_FIELDS_MISSING = 'Mandatory fields missing. Verify if firstName, lastName, dateOfBirth and name are passed';
    public static Final String ERRORMESSAGE_PATIENT_INDIVIDUAL_RECORD_TYPE_MAPPER_NOT_FOUND = 'Specified patientClass not found in Individual Record Type Mapper';
    public static Final String ERRORMESSAGE_PATIENT_PATIENT_CLASS_CANNOT_BE_UPDATED = 'patientClass is invalid while doing PUT operation';
    public static Final String ERRORMESSAGE_APPLICANT_MANDATORY_FIELDS_MISSING = 'Mandatory fields missing. Verify if firstName, lastName, dateOfBirth and name are passed';
    public static Final String ERRORMESSAGE_INVALID_QUERY_PARAMETER = 'Invalid query parameter value found';
    public static Final String ERRORMESSAGE_PATIENT_ID_MISSING = 'patient id parameter value is missing';
    public static Final String ERRORMESSAGE_PROGRAM_ID_MISSING = 'program id parameter value is missing';
    public static Final String ERRORMESSAGE_ASSOCIATION_FIELD_MISSING_INSERT = 'Mandatory fields missing. Verify if Role, ProgramId, accountId/username are passed.';
    public static Final String ERRORMESSAGE_ASSOCIATION_FIELD_MISSING_UPDATE = 'Mandatory fields missing. Verify if AssociationId and AssociationStatus are passed.';
    public static Final String ERRORMESSAGE_ASSOCIATION_UNEXPECTED_ERROR = 'An unexpected error occurred.Please contact System Administrator';
    public static Final String ERRORMESSAGE_ADVERSE_EVENT_INVALID_JSON = 'Adverse Event and the related suspect products cannot be updated because of invaid JSON';
    public static Final String ERRORMESSAGE_ORDERITEM_INVALID_FIELD_ORDER_IN_UPSERT = 'order key should not be specified in orderItems';

    //global static Final String Patient_NoPatientFound = 'No patient found';
    public static Final String ACCOUNT_NO_ACCOUNT_FOUND = 'No record found';
    public static Final String NO_RECORD_FOUND = 'No record found';
    //global static Final String Patient_MoreThanOnePatientFound = 'More than one patient found';

    public static Final String PROVIDER_NO_PROVIDER_FOUND = 'No provider found';

    public static Final String ADDRESS_NO_ADDRESS_FOUND = 'No Address found';

    public static Final String HEALTHPLAN_NO_HEALTHPLAN_FOUND = 'No health plan found';
    public static Final String ADVERSEEVENT_NO_ADVERSEEVENTS_FOUND = 'No adverse events found';
    public static Final String HEALTHPLAN_RECORD_TYPE_MISSING = 'No/Invalid value found for RecordType';
    public static Final String RECORD_TYPE_MISSING = 'No/Invalid value found for RecordType';
    public static Final String ENGAGEMENT_PROGRAM_NO_ENGAGEMENT_PROGRAM_FOUND = 'No engagment program found';


    public static Final String PROGRAM_INVALID_PARAMETERS = 'Invalid Parameters';
    public static Final String INVALID_PARAMETERS = 'Invalid Parameters';

    public static Final String INVALID_ASSOCIATION_ID = 'Invalid Association Id';

    public static Final String RESPONSE_MESSAGE_KEY = 'message';

    // custom meta data settings
    global static final String REST_OBJECT_NAME_ACCOUNT = 'Account';
    global static final String REST_OBJECT_NAME_PATIENT = 'Patient';
    global static final String REST_OBJECT_NAME_PROVIDER = 'Physician';
    global static final String REST_OBJECT_NAME_ADDRESS = 'Address';
    global static final String REST_OBJECT_NAME_HEALTHPLAN = 'HealthPlan';
    global static final String REST_OBJECT_NAME_MANUFACTURER = 'Manufacturer';
    global static final String REST_OBJECT_NAME_ENGAGEMENT_PROGRAM = 'EngagementProgram';
    global static final String REST_OBJECT_NAME_SELF_SERVICE_SETTING = 'SelfServiceSetting';
    global static final String REST_OBJECT_NAME_INTERACTION = 'Interaction';
    global static final String REST_OBJECT_NAME_PAYER = 'Payer';
    global static final String REST_OBJECT_NAME_CASE_PROGRAM = 'Case';
    global static final String REST_OBJECT_NAME_ASSOCIATION = 'Association';
    global static final String REST_OBJECT_NAME_APPLICANT = 'Applicant';
    global static final String REST_OBJECT_NAME_APPLICANT_ADDRESS = 'Applicant/Address';
    global static final String REST_OBJECT_NAME_APPLICANT_HEALTHPLAN = 'Applicant/HealthPlan';
    global static final String REST_OBJECT_NAME_APPLICANT_HCO = 'Applicant/HCO';
    global static final String REST_OBJECT_NAME_PROGRAM_COVERAGE = 'ProgramCoverage';
    global static final string REST_OBJECT_NAME_ADVERSE_EVENT = 'AdverseEvent';
    global static final string REST_OBJECT_NAME_ADVERSE_EVENT2 = 'AdverseEvent2';
    global static final string REST_OBJECT_NAME_SUSPECT_PRESCRIPTION = 'SuspectPrescription';
    global static final String REST_OBJECT_NAME_Order = 'Order';
    global static final String REST_OBJECT_NAME_OrderItem = 'OrderItem';

    global static final String QUERYPARAMETER_ALL_OR_NONE = 'allOrNone';

    /**
     * Maps he REST resource names to SF object names.
     */
    global static final Map<String, String> REST_OBJECT_TO_SOBJECT_MAPPING = new Map<String, String> {
            REST_OBJECT_NAME_Address => 'Account',
            REST_OBJECT_NAME_Applicant => 'PC_Applicant__c',
            REST_OBJECT_NAME_APPLICANT_ADDRESS => 'PC_Applicant__c',
            REST_OBJECT_NAME_APPLICANT_HEALTHPLAN => 'PC_Applicant__c',
            REST_OBJECT_NAME_Association => 'PC_Association__c',
            REST_OBJECT_NAME_CASE_PROGRAM => 'Case',
            REST_OBJECT_NAME_ENGAGEMENT_PROGRAM => 'PC_Engagement_Program__c',
            REST_OBJECT_NAME_HealthPlan => 'PC_Health_Plan__c',
            REST_OBJECT_NAME_Patient => 'Account',
            REST_OBJECT_NAME_Provider => 'Account',
            REST_OBJECT_NAME_Payer => 'Account',
            REST_OBJECT_NAME_Manufacturer => 'Account',
            REST_OBJECT_NAME_PROGRAM_COVERAGE => 'PC_Program_Coverage__c',
            REST_OBJECT_NAME_ADVERSE_EVENT => 'PC_AdverseEvent__c',
            REST_OBJECT_NAME_ORDER => 'PC_Order__c',
            REST_OBJECT_NAME_OrderItem => 'PC_OrderItem__c'
    };
    
    global static final Set<String> PATIENT_SEARCH_MANDATORY_FIELDS = new Set<String> {'firstName','dateOfBirth','lastName'};
    
    global enum ObjectOperation {oUPDATE, oINSERT, oDELETE}
    global enum ErrorCode {MISSING_QUERY_PARAMS, APEX_ERROR, INVALID_RECORD_ID, INVALID_ARGUMENTS, MISSING_FIELD_MAPPING, INVALID_JSON_INPUT, MANDATORY_FIELDS_MISSING, NO_RESULTS, SOQL_LIMITATION, PERMISSION_SET_MISSING,INVALID_CONFIGURATION}
    global enum ErrorType {APPLICATION, PATIENT_CONNECT, HEALTH_CLOUD}

    global static final String ERROR_ERROR_LOG_REF = 'errorLogRef';
    global static final String ERROR_ERROR_CODE = 'errorCode';
    global static final String ERROR_ERROR_TYPE = 'errorType';
    global static final String ERROR_ERROR_MESSAGE = 'message';
    global static final String ERROR_ERROR_CODE_PREFIX = 'ERROR:';
    global static final string RECORD_TYPE_KEY = 'recordType';
    global static final string RECORD_TYPE_ID_KEY = 'recordTypeId';
    global static final string ID_KEY = 'id';
    global static final string ADVERSEEVENT_ID_KEY = 'adverseEventId';

    public static final string PATIENT_FIRST_NAME_KEY = 'firstName';
    public static final string PATIENT_LAST_NAME_KEY = 'lastName';
    public static final string PATIENT_DOB_KEY = 'dateOfBirth';
    public static final string PATIENT_NAME_KEY = 'name';
    public static final string PATIENT_PHONE_KEY = 'phone';
    public static final string PATIENT_ZIP_KEY = 'primaryZipcode';
    public static final string PATIENT_GENDER_KEY = 'gender';
    public static final string PATIENT_PATIENT_CLASS_KEY = 'patientClass';
    public static final string MANUFACTURER_ID = 'manufacturerId';
    public static final string APPLICANT_FIRST_NAME_KEY = 'firstName';
    public static final string APPLICANT_LAST_NAME_KEY = 'lastName';
    public static final string APPLICANT_DOB_KEY = 'dateOfBirth';
    public static final string APPLICANT_NAME_KEY = 'name';
    public static final string ENGAGEMENT_PROGRAM_ID_KEY = 'engagementProgramId';
    public static final string PATIENT_ID_KEY = 'patientId';
    public static final string LIMIT_KEY = 'limit';
    public static final string INTERACTION_DEFAULT_LIMIT_VALUE = '5';
    public static final string VENDOR_NAME_KEY = 'vendorName';
    public static final string CHANNEL_KEY = 'channel';
    public static final string OTHER_KEY = 'Other';

    public static final string GET_PARAM_FIND_BY_PATIENT_ID = 'findByPatientId';
    public static final string GET_PARAM_FIND_BY_ENGAGEMENT_PROGRAM_ID = 'findByEngagementProgramId';

    public static Final String CUSTOM_SEARCH_NO_RECORD_FOUND = 'No record found';
    public static final string CUSTOM_SEARCH_HEADER_KEY = 'X-customSearchFilter';
    public static Final String CUSTOM_SEARCH_WHERE_CLAUSE_MISSING = 'where condition missing in request header';
    public static Final String CUSTOM_SEARCH_SEARCH_LOGIC_MISSING = ' custom search logic missing in request header';
    public static Final String CUSTOM_SEARCH_HEADER_KEY_MISSING = 'custom search header X-customSearchFilter missing in request header';

    public static string PROGRAMCOVERAGE_TYPE_APINAME = 'PC_Coverage_Type__c';
    public static FINAL string REGULAREXP_ONLY_DIGITS =  '[^0-9]';
    public static final string PAYER_NAME_KEY = 'name';
    public static final string PAYER_PHONE_KEY = 'phone';
    public static final string ERRORMESSAGE_PAYER_NAME_MISSING = 'name parameter\'s value is missing';
    public static final string ATLEAST_3_CHARACTERS_PAYER_NAME_REQD = 'atleast 3 characters Payer name requried';
    public static final string PAYER_NAME_WILD_CHARACTER = '*';
    
    //PC-2498
    public static final string PATIENT_RELATIONSHIP_SCOPE_ALL = 'all';
    public static final string PATIENT_RELATIONSHIP_SCOPE_SPECIFIED = 'specified';
    public static final string PATIENT_RELATIONSHIP_SCOPE_NONE = 'none';
    public static final string PATIENT_RELATIONSHIP_SCOPE_KEY = 'relationshipScope';
    public static final string PATIENT_RELATIONSHIPS_KEY = 'relationships';
    public static final string ADVERSE_EVENT_REST_OBJECT_NAME= 'adverseEvent';
    public static final string ADDRESSES_REST_FIELD_NAME= 'addresses';
    public static final string HEALTH_PLANS_REST_FIELD_NAME= 'healthPlans';
    public static final String SPECIFIED_CHILD_OBJECTS_TO_FETCH_MISSING = 'please provide relationships parameter and its value';
    public static final String CHILDOBJS_RELATIONSHIP_MISSING = 'Following child objects relationships are missing for';

    public static final Integer RECORDS_LIMIT = 100;
    public static final String PATIENT_SEACH_LIMIT_EXCEPTION = '# records exceeds returned for this search exceeds the limit of ' +  RECORDS_LIMIT + '. Please refine the search and try again.';


}