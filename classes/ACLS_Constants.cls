public with sharing class ACLS_Constants {

    public static final String BLANK = '';
    public static final String COMMASEPARATOR = ',';

    //Enagagment program codes
    public static final String ASHF = 'ASHF';

    //Record type constants
    public static final String ACCOUNT_PATIENT_RT = 'PC_Patient';
    public static final String ACCOUNT_MANUFACTURER_RT = 'Manufacturer';
    public static final String CASE_PROGRAM_RT = 'PC_Program';
    public static final String CASE_ENROLLMENT_RT = 'PC_Enrollment';
    public static final String CASE_BI_BV_RT = 'PC_Benefits_Investigation_Benefits_Verification';
    
    public static final String TASK_PSP_RT = 'PC_PSP_Task';
    public static final String CASE_PRIORAUTH_RT = 'PC_Prior_Authorization';
    public static final String CASE_PAP_RT = 'PC_PAP';
    
    public static final String DOCUMENT_EMAIL_OUTBOUND = 'PC_Email_Outbound';
    public static final String DOCUMENT_EMAIL_INBOUND = 'PC_Email_Inbound';
    public static final String DOCUMENT_FAX_OUTBOUND = 'PC_Fax_Outbound';
    
    public static final String CASE_APPEAL_RT = 'PC_Appeal';
    
    public static final String CASE_COPAY_RT = 'PC_Copay'; 
    public static final String FAXOUTBOUND = DOCUMENT_FAX_OUTBOUND;
    public static final String FAX_INBOUND = 'PC_Fax_Inbound';
    public static final String FAX_RECEIVED = 'Received_Fax';
    

    
    //Object Api names
    public static final String ACCOUNT = 'ACCOUNT';
    public static final String OBJ_CASE = 'CASE';
    public static final String OBJ_TASK = 'TASK';
    public static final String OBJ_DOCUMENT = 'PC_Document__c';
    public static final String OBJ_PROGRAM_SERVICE_PERMISSION = 'PC_Program_Service_Permission__c';
    public static final String PCDocument = OBJ_DOCUMENT;
    public static final String OBJ_FAX = 'EFX__efax__c';
    
    


    //Prescription Fields
    public static final String PRODUCT = 'PC_Product__c';
    public static final String STARTDATE = 'PC_Rx_Start_Date__c';
    public static final String REQUESTEDQUANTITY = 'PC_Requested_Quantity__c';
    public static final String RXREFILLS = 'PC_Rx_Refills__c';
    public static final String DAYSSUPPLY = 'PC_Days_Supply__c';
    
    //Blank String
    public static final String STRINGBLANK = '';
    //Hash Symbol
    public static final String HASH = '#';
    //Hyphen Symbol
    public static final String HYPHEN = '-';

    //Label Value Constants
    public static final String LABEL = 'label';
    public static final String VALUE = 'value';

    //Services Requested key in Page State map of Enrollment Processor Additional Info Page
    public static final String STR_SERVICES_REQUESTED = 'servicesRequested';
    public static final String PREFERRED_PHARMACY = 'Pharmacy';

    //String Literals
    public static final String COMMA = ',';
    public static final String SEMICOLON = ';';
    public static final String OPEN_ROUND_BRACKET = '(';
    public static final String CLOSE_ROUND_BRACKET = ')';
    public static final String NEW_LINE = '\n';
    public static final String AND_KEY = '&';
    public static final String EQUALS = '=';
    public static final String SPACE = ' ';
    public static final String YES = 'Yes';
    public static final String NO = 'No';
    public static final String STR_TRUE = 'True';

    //Task Field
    public static final String TASK_COMPLETED = 'Completed';
    public static final String TASK_STATUS_NOT_STARTED ='Not Started';
    public static final String TASK_PRIORITY_HIGH ='High';
    public static final String TASK_CHANNEL_TASK='Task';
    public static final String PSP_TASK_RECORD_TYPE = TASK_PSP_RT;
    
    //Coverage Field
    public static final String COV_SOURCE_AUTOMATED = 'Automated';
    public static final String COV_SOURCE_MANUAL = 'Manual';
    
    
    //Case Fields
    public static final String STATUS = 'Status';
    public static final String OWNERID = 'OwnerId';
    

    //Case status
    public static final String ENROLLED_STATUS = 'Enrolled';
    public static final String COMPLETE_STATUS = TASK_COMPLETED;
    public static final String CLOSED_STATUS = 'Closed';
    public static final String CANCELLED_STATUS = 'Cancelled';
    public static final String INPROGRESS_STATUS = 'In Progress';
    public static final String MISSINGINFO_STATUS = 'Missing Information';
    public static final String NEWSTATUS = 'New';

  

    //HCO
    public static final String HCO = 'HCO';

    //MI Status
    public static final String ACTIVE_STATUS = 'Active';
    public static final String INACTIVE_STATUS = 'Inactive';

   
    //Document Fields
    public static final String DOCSTATUS = STATUS;
    public static final String REVIEW_NEEDED = 'Review Needed';
    public static final String SPLIT_FAILURE = 'Split Failure';

    //Association Roles
    public static final String CARE_COORDINATOR = 'Care Coordinator';
    public static final String CASE_MANAGER = 'Case Manager';

    //Missing Info Categories
    public static final String CONSENT_CATEGORY = 'Consent';
    public static final String PROVIDER_CONSENT = 'Provider Consent';

    //PSP Fields 
    public static final String HCP_RESPONSE = 'PC_HCP_Response__c';
    public static final String PATIENT_RESPONSE = 'PC_Patient_Response__c';

    public static final String ENVIRONMENT_NAME_MDT = 'ACLS_Environment_Name';
    public static final String EXCEPTION_OCCURRED = 'Exception Occurred';
    public static final String INTEGRATION ='Integration';

    //Queue
    public static final String 	ACLS_ADMIN_QUEUE ='ACLS_Admin';

    
    //Omnistudio IP Constants
    public static final String OMNISTUDIO_IP_SOURCE_RECORD_ID = 'sourceRecordId';
    public static final String OMNISTUDIO_IP_TARGET_RECORD_ID = 'objectId';
    public static final String OMNISTUDIO_IP_ELETTER_ID = 'eLetterId';
    public static final String OMNISTUDIO_IP_EXTRACT_RAPTOR = 'extractDataRaptor';
    public static final String OMNISTUDIO_IP_TRANSFORM_RAPTOR = 'transformDataRaptor';
    public static final String OMNISTUDIO_IP_EP_NAME = 'engagementProgramName';
    public static final String OMNISTUDIO_IP_ACCOUNT_ID = 'accountId';
    public static final String OMNISTUDIO_IP_PROGRAM_CASE_ID = 'programCaseId';
    public static final String OMNISTUDIO_IP_GET_EXTRACT_DR = 'getExtractDR';
    public static final String OMNISTUDIO_IP_GET_TRANSFORM_DR = 'getTransfromDR';
    public static final String OMNISTUDIO_IP_RESULT = 'result';
    public static final String OMNISTUDIO_IP_EXTRACT_DR_RESULT = 'extractDRResult';
    public static final String OMNISTUDIO_IP_TRANSFORM_DR_RESULT = 'transformDRResult';
    public static final String OMNISTUDIO_IP_EXTRACT_DR_OUTPUTMAP = 'extractDROutputDataMap';
    public static final String OMNISTUDIO_IP_INTEGRATION_NAME = 'integrationName';

    
    //Integration constants
    public static final String METHOD_POST = 'POST';
    public static final String METHOD_PUT = 'PUT';
    public static final String METHOD_GET = 'GET';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String API_CALLOUT_FAILED = 'API Callout Failed';
    public static final String ERROR = 'ERROR';
    public static final String IN_PROGRESS = 'IN PROGRESS';
    public static final String INTEGERATION_CONFIG_MDT = 'ACLS_IntegrationConfiguration_CustomMetadata';
    

    //Integration - SMS
    public static final String SMS_FIVE9_TOKEN = 'Five9 SMS Token';
    public static final String SMS_FIVE9_OPTIN = 'Five9 SMS OptIn';
    public static final String SMS_FIVE9_SENDSMS = 'Five9 SMS SendSMS';
    public static final String SMS_FIVE9_GETSTATUS = 'Five9 SMS GetStatus';
    public static final String EP_SMS_RAREASSIST_RX = 'ACLS_Send_Message_RareAssistRx';
    public static final String SMS_TOKEN_ERRORLOG1 = 'Unable to get access token for SMS integration';
    public static final String SMS_TOKEN_ERRORLOG2 = 'Integration configuration for Five9 SMS Token is Missing';
    public static final String SMS_OPTIN_ERRORLOG1 = 'Unable to update OptIn/OptOut for SMS integration';
    public static final String SMS_OPTIN_ERRORLOG2 = 'Integration configuration for Five9 Update OptIn is Missing';
    public static final String SMS_SEND_ERRORLOG1 = 'Unable to sent SMS to the patient';
    public static final String SMS_SEND_ERRORLOG2 = 'Integration configuration for Five9 Send SMS is Missing';
    public static final String SMS_OPERATION_OPTIN = 'Opt-In';
    public static final String SMS_OPERATION_OPTOUT = 'Opt-Out';
    public static final String SMS_STATE_OPTIN = 'OPT_IN';
    public static final String SMS_STATE_OPTOUT = 'OPT_OUT';
    public static final String SMS_OPERATION_SEND_SMS = 'Send SMS';
    public static final String SMS_NO_OPERATION_FOUND = 'No Operation found';
    public static final String SMS_FAILED_TO_GET_CONTENT = 'Failed to get the message content';
    public static final String SMS_UNABLE_TO_SEND_SMS = 'Unable to send message to the phonenumber';
    public static final String SMS_UNABLE_TO_OPTIN = 'Unable to optin/OptOut the phonenumber';
    public static final String OUTBOUND_SMS_EXCEPTION = 'Outbound SMS  : Exception Occurred';
    public static final String SMS = 'SMS';
    public static final String SMS_EXCEPTION_COMMENT = 'Error occurred while sending SMS to the patient. Failed to send the SMS';
    public static final String SMS_IP_GETTOKEN = 'ACLS_IP_SMS_GetToken';
    public static final String SMS_MDT_TOKEN = 'Five9 SMS Token';
    public static final String SMS_IP_UPDATEOPTIN = 'ACLS_IP_SMS_UpdateOptIn';
    public static final String SMS_MDT_UPDATEOPTIN = 'Five9 SMS OptIn';
    public static final String SMS_UPDATEOPTIN_DR = 'ACLS_updateOptInSMS_DR';
    public static final String SMS_MDT_SENDMESSAGE = 'Five9 SMS SendSMS';
    public static final String SMS_SENDMESSAGE_DR  = 'ACLS_sendSMS_DR';
    public static final String SMS_IP_SENDMESSAGE  = 'ACLS_IP_SMS_MessageSend';
    public static final String SMS_MDT_GETMESSAGESTATUS = 'Five9 SMS GetStatus';
    public static final String SMS_GETMESSAGESTATUS_DR = 'ACLS_getSmsStatus_CustomMetadata';
    public static final String SMS_IP_GETMESSAGESTATUS = 'ACLS_IP_Sms_GetStatus';


    //Integration - Address Verification
    public static final String MELISSA_ADDRESS = 'Melissa Address';
    public static final String MELISSA_ADDRESS_ERRORLOG = 'Integration configuration for Melissa Address is Missing';
	public static final String Add_ERRORLOG1 = 'Unable to get API details for Melissa integration';
    public static final String Add_ERRORLOG2 = 'Integration configuration for Melissa Api is Missing';
    //Integration - Fax
    public static final String OUTBOUND_FAX_EXCEPTION = 'Outbound Fax : Exception Occurred';
    public static final String OUTBOUND_FAX_INTEGRATION = INTEGRATION;
    public static final String OUTBOUND_FAX_FAX = 'Fax';
    public static final String OUTBOUND_FAX_PREVIEW_ONLY = 'Preview Only';
    public static final String OUTBOUND_FAX_SENT_FAX = 'Sent_Fax';
    public static final String OUTBOUND_FAX_FINE = 'Fine';
    public static final String OUTBOUND_FAX_NEW ='NEW';
    public static final String INBOUND_FAX_EXCEPTION = 'Inbound Fax : Exception Occurred';
    public static final String INBOUND_FAX_INTEGRATION = INTEGRATION;
    public static final String INBOUND_FAX_FAX = 'Fax';
    public static final String FAX_EFAX_TOKEN = 'eFax Fax Token';
    public static final String FAX_EFAX_SENDFAX = 'eFax Fax SendFax';
    public static final String FAX_EFAX_GETSTATUS = 'eFax Fax GetStatus';
    public static final String Fax_ERRORLOG1 = 'Unable to get API details for Fax integration';
    public static final String Fax_ERRORLOG2 = 'Integration configuration for Fax Api is Missing';
    public static final String FAX_CALLOUTEXCEPTION = 'Exception in making callout to eFax';
    public static final String FAX_EXCEPTION_OCCURED = 'Exception occured';
    public static final String FAX_BEARER_TOKEN_NULL= 'Bearer Token is Null';
    public static final String FAX_INTEGRATION_CONFIG_UNAVAIL= 'Integration Configurations are unavialble';
    public static final String FAX_IP_GETTOKEN = 'ACLS_IP_Fax_GetToken';
    public static final String FAX_IP_GET_STATUS = 'ACLS_IP_Fax_GetStatus';
    public static final String FAX_IP_SEND_FAX = 'ACLS_IP_Fax_SendFax';
    public static final String FAX_DR_SEND_FAX = 'ACLS_SendFax_DR';
    public static final String FAX_DR_GET_STATUS = 'ACLS_getFaxStatus_CustomMetadata';
    

    //Integration - eBV
    public static final String RISRX_PHARMACY = 'RisRx Pharmacy';
    public static final String EBV = 'eBV';
    public static final String CALLOUTRESPONSE = 'calloutResponse';
    public static final String EBV_PHARMACY_DETAILS = 'RisRx Pharmacy';
    public static final String EBV_PHARMACY_ERRORLOG1 = 'Unable to get API details for eBV integration';
    public static final String EBV_PHARMACY_ERRORLOG2 = 'Integration configuration for RisRx prevail Api is Missing';
    
    //Integration Split
    public static final String HC_SPLIT = 'HC Split';
    public static final String HC_SPLIT_ERRORLOG1 = 'Unable to get API details for Split integration';
    public static final String HC_SPLIT_ERRORLOG2 = 'Integration configuration for HC Split Api is Missing';

    //SMS Status
    public static final String SMS_STATUS_UNDELIVERED = 'Undelivered';
    public static final String SMS_STATUS_SENDING = 'Sending';
    public static final String SMS_STATUS_FAILED = 'Failed';
    public static final String SMS_STATUS_QUEUED = 'Queued';
    public static final String SMS_STATUS_UNPROCESSED = 'Unprocessed';
    public static final String SMS_STATUS_DELIVERED = 'Delivered';
    public static final String SMS_STATUS_COMPLETED = 'COMPLETED';


    

    // Service Name picklist values  in Remote service log
    public static final String RSL_SERVICE_NAME_FIVE9SMS = 'Five9 SMS';
    public static final String RSL_SERVICE_NAME_MELISSA_ADDRESS = MELISSA_ADDRESS;

    //key Value Constants
    public static final String KEYVAL_TYPE_INTEGDEFAULTS = 'Integration Defaults';
    public static final String KEYVAL_TYPE_VALTRANSFORM = 'Value Transformation';	
    public static final String SENDSMS_BATCHSIZE_KEY = 'ACLS_SendSMS_BatchSize';
    public static final String GETSMSSTATUS_BATCHSIZE_KEY = 'ACLS_GetSMSStatus_BatchSize';
    public static final String KEYVAL_TYPE_BATCHSIZE = 'Batch Size';
    public static final String KEYVAL_TYPE_BATCHFREQ = 'Batch Frequency';

    //error log details
    public static final String CLASS_BATCH_SENDSMS = 'ACLS_SMS_SendSMSBatch';
    public static final String CLASS_SMS_INTEGRATIONHANDLER = 'ACLS_SMSIntegrationHandler';
    public static final String METHOD_BATCH_SENDSMS_EXECUTE = 'execute';
    public static final String METHOD_BATCH_SENDSMS_FINISH = 'finish';
    public static final String CLASS_BATCH_GETSMSSTATUS = 'ACLS_SMS_GetSMSStatusBatch';





}