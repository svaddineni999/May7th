/*********************************************************************************************************
Class Name      : PC_Constants
Description     : This class is used for storing all the constants used in the entire codebase
Created By      : Deloitte
Created Date    : April 1, 2015
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------------------------
Deloitte               April 1, 2015              Initial Version
Alina Balan            26-May-2016                [PC-20] Added constants for Document object name and for document record types, 
Alina Balan            26-May-2016                [PC-22] Added constants for Patient creation, 
Vasile Paraschiv       10-June-2016               [PC-55] Added constants for SMS use, 
Prachi Nandgaonkar     8-Jan-2016                 [PC-677] Added constants for Doc Splitting 
Prachi Nandgaonkar     3-Mar-2017                 [PC-1238] Updated DOCUMENT_STATUS_NEW to 'New' 
                                                  [PC-1241]Added constant CONTACT_INDIVIDUAL_RECORD_TYPE_NAME for Contact record type name for 'Individual' 
 												  [PC-1241] Added constant for DOCUMENT_SMARTFORM_RECORD_TYPE_NAME for 'Online Form' record type name 
Prachi Nandgaonkar     16-Mar-2017                [PC-1318] Added constants for Applicant record types 
Prachi Nandgaonkar     19-Apr-2017                [PC1430] Added constant for PAYER_RECORD_TYPE
Tejas Patel			   20-Apr-2017			      The Varibales declarations are "False Positive result from ForceReviewer"
Shabda Bhujad		   17-May-2017				  [PC-1616]Added a constant for FAX OUTBOUND record type for Document
Prachi Nandgaonkar     31-May-2017                [PC-1339] Added a constant for ENROLLMENT_FORM_CATEGORY (document tagging category) 
Shabda Bhujad		   05-June-2017				  [PC-1664] -Rollback the changes done for [PC-1339] deleted - ENROLLMENT_FORM_CATEGORY = 'Enrollment Form';
Mayuresh Patil		   12-June-2017				  [PC-1670] -Added constant for DOCUMENT_EMAIL_ATTACHMENT_RECORD_TYPE = 'PC_Email_Attachment';
Shabda Bhujad		   22-June-2017				  [PC-1795] Added RecordType Name for Patient - PATIENT_RECORD_TYPE_NAME
Mayuresh Patil         07-July-2017               [PC-1867] Added constant for DOCUMENT_SPLIT_SERVICE.
Mike Klumpenaar        12-July-2017               [PC-1885] Added PICKLIST_NONE to indicated no picklist option selected.
Prachi Nandgaonkar     8-Aug-2017                 [PC-1730] Added a task status for completed tasks
Mayuresh Patil         9-Aug-2017                 [PC-1898] Added constants for healthplan and coverage recordtypes
Prachi Nandgaonkar     17-Aug-2017                [PC-2061] Added specific record type for referral task creation
Prachi Nandgaonkar     22-Aug-2017                [PC-1998] Added a constant for Prior Authorization record type
Prachi Nandgaonkar     24-Aug-2017                [PC-1704] Added status for referral
Shabda Bhujad		   23-Aug-2017				  [PC-1734] Added constants for PA
Tejas Patel			   29-Aug-2017				  [PC-2118] Added constant for use in PC_Test_ActionCenterLightningController, ActionCenterEngagementProgram = 'PRGA' used in custom-metadata
Mike Klumpenaar        13-Dec-2017                [PC-2601] Added PC_INTERACTION
Shabda Bhujad          11-Jan-2018                [PC-2671] Added logic to skip FLS for Salesforce to Salesforce Connection User
Shabda Bhujad          11-Jan-2018                [PC-2382] Added constants for program coverage picklist values
Prachi Nandgaonkar     27-Feb-2018                [PC-2805] Added constants for Support Plan RunTime activity status
Prachi Nandgaonkar     5-March-2018               [PC-2805] Added constants for template task in Support Plan
Prachi Nandgaonkar     26-March-2018              [PC-2918]Added constants for UBC Pharmacy Benefit lookup (Named Creds and the end point)
Mayuresh Patil         27-March-2018              [] Added Constants for SUPPORTPLANT_LISTVIEWNAME
Mayuresh Patil         29-March-2018              [PC-2940] Added constants for SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED
Vijay Kashikar         17-Apr-2018                [PC-2970] Added new constant NAMED_CRED_PLAN_PBM_UBC
Vijay Kashikar         26-Jun-2018                [PC-3102] Added new constant for CMM custom setting
Vijay Kashikar         20-Nov-2018                [PC-3649] Added new constants for Health Cloud
Vijay Kashikar         29-Nov-2018                Added new constants for namespace and record type developer name
Mayuresh Patil         13-Dec-2018               [PC-4126] Ability to add action center to custom record types
Vijay Kashikar         06-Feb-2019                [PC-4220] Introduced new constants for Contact Record Type.
Vijay Kashikar         25-Feb-2019                [PC-4493] Introduced new constants for Physician Contact Record Type.
Vijay Kashikar         13-Mar-2019                [PC-4603] Introduced new constants for Salesforce user license and user profile name
Vijay Kashikar         29-Apr-2019                [PC-4765] Introduced new constants for Remote Service Log types.
Haritha Reddy          11-Jun-2019                [PC-4910] Added new constants for Patient Connect settings "PC_UseSalesforceFiles", "PC_DocumentPreviewStrictMode".
Tushar Arora           22-May-2019                [PC-4800] Added constant to check if Person Account is Enabled using Custom Setting
Tushar Arora           11-Jun-2019                [PC-4893] Added constants for creation Patient Person Account RecordType and RemoteSiteSetting Details using Post Install Script
Xiukai Ning            24-Jun-2019                [PC-5002] Log Levels in error handling
Tushar Arora           27-Jun-2019                [PC-4893] Added ClientOrgNames for Recordtype Id in PC_System Class
Xiukai Ning            2-Jul-2019                 [PC-5002] Log Levels moved to utility class
Haritha Reddy          03-Jul-2019                [PC-5019] Added new constants for preview types of Document(attachment, file, both)
Tushar Arora           31-Jul-2019                [PC-5086] Added new constant PC_IsPersonAccount.
Tushar Arora           05-Aug-2019                [PC-5255] Added new constants PC_USE_PERSON_ACCOUNT_FOR_PC and PC_DEFAULT_VALUE_OF_USE_PERSON_ACCOUNT_FOR_PC
Vijay Kashikar         08-Aug-2019                [PC-5087] Added new constants PersonEmail field of Person Account.
Tushar Arora           13-Aug-2019                [PC-5308] Added new constants for Person Account Standard fields and Business Account Fields
Vijay Kashikar         20-Aug-2019                [PC-5330] Made PC_Patient record type configurable
Kanteti Kishore        23-Aug-2019                [PC-5331]Protected GeoCode Api Name
Tushar Arora           18-Oct-2019                [PC-5508] Added new constant PC_RecordTypeDeveloperName for Document RecordType Grouping.
Vijay Kashikar         21-Oct-2019                [PC-5538] Added PC_PatientSearchIdentifier and Record_Type_Id for identifying search context.
Hitha Avalakki         25-Oct-2019                [PC-5624] Added new constant LINK_ASSOCIATION_TYPE_ADVERSE_EVENT2 for Adverse Event 2
Hitha Avalakki         12-Nov-2019                [PC-5715] Added new constants PC_AdverseEventObjectInUse, PC_AdverseEvent_Object, PC_AdverseEvent2_Object
Haritha Reddy          10-Jan-2020                 [PC-5600] Added new constants required to read Suspect Prescription additional Fields Configuration
Hitha Avalakki         29-Jan-2020                [PC-5945] Added a constant CASE_PA_RECORD_TYPE_NAME to be used in PC_Trigger_PA_Case
Vijay Kashikar		   17-Feb-2020				  [PC-5999] Added constant for Member Plan Services Permission set.
Chetna Mohapatra       17-Mar-2020                [PC-6008] Added a constant PC_PRE_ENROLLMENT_FORM_FIELDSET in Patient Connect Settings for Enrollment form.
Haritha Reddy          17-Mar-2020                [PC-6033] Added constants which will be used in Support Plan Processing
Kanteti Kishore        14-Apr-2020                [PC-6043] Added constants PC_PicklistType which will be used in conditional builder class
Tushar Arora           14-Apr-2020                Added constants PC_SupportPlanInitiationHandler which will be used in Custom Support Plan Controller Class
Tushar Arora           14-Apr-2020                Added constants Other Sobject which will be used in Custom Support Plan Controller Class for fetching objects
Tushar Arora           14-Apr-2020                [PC-6040]Added constants PC_SupportPlanInitiationHandler which will be used in Custom Support Plan Controller Class
Tushar Arora           14-Apr-2020                [PC-6040]Added constants Other Sobject which will be used in Custom Support Plan Controller Class for fetching objects
Tushar Arora           23-Apr-2020                [PC-6038]Added a constant PC_TRIGGER_EVENT_INSERTUPDATE for migration of support plan .
Chetna Mohapatra       23-Apr-2020                [PC-6118]Added a constant DEFAULT_HEALTH_CARE_PROFESSIONAL_VALUE to be used in AE Wizard for setting a default value for HealthCare Professional Option.
Kishore Kanteti        7-May-2020                 [PC-6264] Added a constant PC_AdverseEventEmailAddressSettingName to be used in AE Mailing in case of No pre-configured recipients.
Kishore Kanteti        6-June-2020                [PC-6202] Added a constant PC_IsDeleted to be used conditional builders apex class to remove in the fields picklist values.
Kishore Kanteti        11-June-2020               [PC-6289] Added constants PC_TaskFieldSetNameForCaseObject,PC_TaskFieldSetNameForNonCaseObjects to be used in PC_SupportPlanBuilderController class.
Kishore Kanteti        15-June-2020               [PC-6143] Added constants system field api names,mandatory,not mandatory to be used in PC_Utility class.
Haritha Reddy          23-June-2020               [PC-6453] Added constants for update record Action types in Support Plan
Kishore Kanteti        7-July-2020                [PC-6451] Added constants for eliminating encrypted,textarea,multiselect fields in Create Update Automation Task.
Kishore Kanteti        9-July-2020                [PC-6452] Added constants that act as picklist options for orderOptions,criteriaOptions,nullsOptions in Create Update Automation Task.
Satheesh Kumar         9-July-2020                [PC-6384] Added new constants for Patient Connect settings "PC_InboundEmailAddressName", "PC_InboundEmailServiceName".
Satheesh Kumar         21-July-2020               [PC-6496] Added new method for getting threadId
Tushar Arora           22-July-2020               [PC-6438] Added new constants for Log a Call recordType.
Kishore Kanteti        30-Sept-2020               [PC-6144] Added Enum builder context for support plan.
Haritha Reddy          23-Oct-2020               [PC-6912] Added support plan behavior enum constant.
Kishore Kanteti        23-Oct-2020               [PC-6913] Added SUPPORTPLAN_DEFAULT_BEHAVIOR for support plan behavior.
Chetna Mohapatra       30-Oct-2020               [PC-6833] Added PC_GLOBAL_SMS_SENDER_NUMBERS for the org wide sender number.
Haritha Reddy          10-Nov-2020               [PC-6893] Added '--PC_Formula--' Constant, Formula Operator and Offset type enums
Haritha Reddy          23-Nov-2020               [PC-7001] Added new constants related to transaction Id
Chetna Mohapatra       25-Nov-2020               [PC-6835] Added new constant PC_MESSAGE_TRANSACTION_ID_KEY.
Kishore Kanteti        16-Dec-2020               [PC-7048] Added constants for Medical Inquiry in adverse event.
Chetna Mohapatra       02-Dec-2020               [PC-6964] Added PC_SMS_SERVICE_NAME to contain the service class name for Integration.
Chetna Mohapatra       04-Dec-2020               [PC-6991] Added PC_TASK_CHANNEL_SMS for task channel of type SMS.
Chetna Mohapatra       15-Dec-2020               [PC-7119] Added PC_TWILIO_NAMED_CREDENTIAL to store Twilio Named Credential name.
Chetna Mohapatra       15-Dec-2020               [PC-7119] Added PC_TWILIO_ACCOUNTSID to store the accountSID pertaining to individual Twilio account.
Kishore Kanteti        21-Dec-2020               [PC-7037] Added constants for event types in adverse event.
Kishore Kanteti        8-Jan-2021               [PC-7183] Added constants for Adverse Event hide/show attributes.
Hitha Avalakki         26-Feb-2021              [PC-7442] Added constants PC_ProgramCaseRecordTypeSettingName,PC_ProgramCaseRecordTypeNamespaceSettingName,PC_ProgramCaseRecordTypeNamespaceDefaultSettingValue,PC_ProgramCaseRecordTypeDefaultSettingValue.
                                                          Added logic to fetch configured/default program case record type developer name and program case record type namespace
Hitha Avalakki         26-Feb-2021              [PC-7442] Added logic to fetch custom program record type namespace
                                                          only when custom program record type is configured in Patient Connect Setting custom metadtaa
Hitha Avalakki         01-Mar-2021              [PC-7442] Removed redundant code
Hitha Avalakki         02-Mar-2021              [PC-7442] Edited logic to fetch CASE_PROGRAM_RECORD_TYPE_NAMESPACE to prevent redundant callouts to
                                                          PC_SYSTEM.getProgramCaseRecordTypeNamespace();
Hitha Avalakki         02-Mar-2021              [PC-7442] Added a comment for CASE_PROGRAM_RECORD_TYPE_NAMESPACE
Haritha Reddy          02-Mar-2021              [PC-7471] Added constant for Field Relationship Manager
Hitha Avalakki         04-Mar-2021              [PC-7442] Added new methods: getProgramCaseRecordTypeNamespace(), getProgramCaseRecordTypeDeveloperName()
Kanteti Kishore        12-Mar-2021              [PC-7485] Added objectNames EmailMessage, EmailMessageRelation, Event and FRM User Permission Set
Hitha Avalakki         19-Mar-2021              [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME with CASE_PROGRAM_TYPE
Kanteti Kishore        23-Mar-2021              [PC-6633] Added constants for Contains And Does Not Contains
Haritha Reddy         21-Mar-2021               [PC-7010] Added constants to store Platform event object names
Haritha Reddy          25-Mar-2021              [PC-7010] Added constants to store Platform event handler names
Haritha Reddy          05-Apr-2021              [PC-6629] Added new constants to store field data types
Satheesh Kumar         14-Apr-2021              [PC-6528] Added new constants for eletter category (Automated Email and Automated Fax)
Chetna Mohapatra       10-Apr-2021              [PC-7534] Added PC_TWILIO_CALLBACKURL storing the setting name containing Twilio's callback URL
Chetna Mohapatra       20-Apr-2021              Added a constant to store CMM string.
Chetna Mohapatra       26-May-2021              [PC-7769] Added PC_APP_MESSAGE to being used as Source Type field value in Message object.
Haritha Reddy          16-Jun-2021              [PC-7387] Added constants to store status values of interaction
Hitha Avalakki         21-June-2021             [PC-7459] Added constants for Engagement Program,Survey and Survey Invitation sobjects
Hitha Avalakki         23-June-2021             [PC-7459] Added constants for Engagement Program,Default PAP Survey name
Hitha Avalakki         07-JuLY-2021             [PC-7870] Added constants for Default Copay Survey name and Patient Connect Setting name for Copay survey
Kishore Kanteti        Jul 12, 2021             [PC-7843] Added Constant PATIENTCONNECTNAMESPACE_WITHUNDERSCORES
Kishore Kanteti        Jul 16, 2021             [PC-7947] Added Other Constant to be used generally in Org with name PC_OTHER
Chetna Mohapatra       Jul 20, 2021             [PC-7948] Added PC_EXTERNAL_RECIPIENTS for being used as a recipient type.
Hitha Avalakki         OCt 11,2021              [PC-8197] Added enum to decide if attachment or salesforce file or both need to be used for document split and document change owner functionality.
Kishore Kanteti        Nov 2,2021               [PC-8266] Added PC_BATCH_SMS_SERVICE_NAME. Patient Connect Setting name is assigned to the variable.
Hitha Avalakki         Nov 07,2021              [PC-8029] Added constant for 'Granted' response value for Care Team member's consent for any service
Kishore Kanteti        Nov 22,2021              [PC-8209] Added constant for Address to Applicant Mapping Setting Name
Haritha Reddy          Jan 21,2022              [PC-8454] Added constant to store the Key value for Previous Activity used in Support plan
Chetna Mohapatra       Mar 17,2022              [PC-8491] Added constant to store Infinitus service name.
Tejas Patel            Mar 07, 2022             [PC-8582] New constant PACKAGE_NAMESPACE added to hold package namespace.
Tejas Patel            Mar 15, 2022             [PC-8582] New constant IS_LICENSED_USER added to check if the user is PC licensed user.
												[PC-8582] New constant MANDATORY_PERMISSIONSET added to hold the product's mandatory permission set
Vijay Kashikar         Jul 13, 2022             [PC-8908] Constant to hold the Developer Name of PC_PersonAccountPatientNamespaceSettingName
*********************************************************************************/
public with sharing class PC_Constants {
    public static final String MANDATORY_PERMISSIONSET = 'PC_AllApexClasses';
    public static final String PATIENT_CONNECT = 'Patient Connect';
    public static final String TIME_ZONE = 'America/New_York';
    public static final String DEFAULT_USER_EMAIL = 'program@sponsor.com';
    public static final String TriggerHandler_sObject = 'Other';
    public static final String ACTIVE = 'Active';
    public static final String INACTIVE = 'Inactive';
    public static final String NA = 'N/A';
    public static final String MAP_KEY_SPLITTER = '|';
    public static final String CONTACT = 'Contact';    
    public static final String CONTACT_INDIVIDUAL_RECORD_TYPE = 'IndustriesIndividual';
    public static final String CONTACT_INDIVIDUAL_RECORD_TYPE_NAME = 'Individual';
    public static final String CONTACT_PATIENT_RECORD_TYPE = 'PC_Patient';
    public static final String CONTACT_PHYSICIAN_RECORD_TYPE = 'PC_Physician';
    public static final String CONTACT_PATIENT_RECORD_TYPE_NAME = 'Patient';
    public static final String PC_CASE = 'Case';
    public static final String PC_ACCOUNT = 'Account';
    public static final String PC_CASEPRODUCT = 'PC_CaseProduct__c';
    public static final String PC_PRODUCT2 = 'Product2';
    public static final String PC_CoverageBenefit = 'coverageBenefit';
    public static final String PC_COVERAGE_BENEFIT_ABBREVIATION = 'CB-';
    public static final String PC_CoverageBenefitItem = 'coverageBenefitItem';
    public static final String PC_COVERAGE_BENEFIT_ITEM_ABBREVIATION = 'CBI-';
    public static final String PC_MEMBER_PLAN_ABBREVIATION= 'MB-';

    public static final String PC_ATTACHMENT = 'Attachment';
    public static final String PC_CONTENTDOCUMENTLINK = 'ContentDocumentLink';
    public static final String PC_CONTENT_DOCUMENT = 'ContentDocument';
    public static final String PC_CASE_TEAM_ROLE = 'CaseTeamRole';
    public static final String PC_EMAIL_TEMPLATE = 'EmailTemplate';
    public static final String PC_APPLICANT = 'Applicant';
    public static final String PC_USER = 'User';
    public static final String PC_CASETEAMMEMBER = 'CaseTeamMember';
    public static final String PC_LISTVIEW = 'ListView';
    public static final String PC_NEW = 'New';
    public static final String PC_AND = 'AND';
    public static final String PC_OR = 'OR';
    public static final String PC_BENEFITCATEGORY_PRODUCT = 'Product';
    public static final String CASE_PROGRAM_TYPE = 'Program';//Case Type picklist value
    public static final String CASE_ENROLLMENT_RECORD_TYPE = 'PC_Enrollment';
    public static final String CASE_ENROLLMENT_RECORD_TYPE_NAME = 'Enrollment';// Added for enrollment cases
    public static final String CASE_PHYSICIAN_RECORD_TYPE = 'PC_Physician'; //Also used to reference Account Physician record type
    public static final String CASE_PA_RECORD_TYPE = 'PC_Prior_Authorization'; //[PC-1998] Added a constant for Prior Authorization record type
    public static final String CASE_PA_RECORD_TYPE_NAME = 'Prior Authorization';
    public static final String CASE_OTHER_RECORD_TYPE = 'Other'; //Added a constant for Other case record type
    public static final String PA_CASE_STATUS_Denied = 'Denied';
    public static final String PA_CASE_STATUS_Canceled = 'Cancelled';
    public static final String PA_CASE_STATUS_Expired = 'Expired';
    public static final String PA_CASE_STATUS_Approved = 'Approved';
    public static final String PA_INTERACTION_STATUS_ATTENDED = 'Attended';
    public static final String PA_INTERACTION_STATUS_CANCELLED = 'Cancelled';
    public static final String CASE_BI_BV_RECORD_TYPE = 'PC_Benefits_Investigation_Benefits_Verification';
    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_ENROLLED = 'Enrolled';
    public static final String EMPTY_STRING = '';
    public static final String UNDEFINED_STRING = 'undefined';
    public static final String PC_NONE_PICKLISTVALUE='--None--';
    public static final String PC_TASK = 'Task';
    public static final String INTERNAL_TASK = 'Internal Task';
    public static final String PSP_TASK_RECORD_TYPE = 'PC_PSP_Task';
    public static final String PSP_TASK_RECORD_TYPE_NAME = 'PSP Task';
    public static final String PC_TASK_CATEGORY = 'Copay';
    public static final String PC_TASK_SUBCATEGORY = 'Requested';
    public static final String PC_TASK_REF_CATEGORY = 'Pharmacy Referral'; //[PC-1730]
    public static final String TEMPLATE_ACTIVITY_RECORD_TYPE_NAME = 'Template Activity';
    public static final String TEMPLATE_ACTIVITY_RECORD_TYPE = 'PC_Template_Activity'; //[PC-2061] Added a task layout API name for creating referral task
    public static final String PC_STATUS_NOT_STARTED = 'Not Started';
    public static final String PC_STATUS_COMPLETED = 'Completed'; //[PC-1730]
    public static final String PC_TASK_STATUS_COMPLETED = 'Completed';
    public static final String PC_PRIORITY_NORMAL = 'Normal';
    public static final String PC_PRIORITY_HIGH = 'High';
    public static final String FAX = 'fax';
    public static final String EMAIL = 'email';
    public static final String UTF = 'UTF-8';
    public static final String SUCCESS = 'SUCCESS';
    public static final String WARNING = 'WARNING';
    public static final String ERROR = 'ERROR';
    public static final String ActionCenterEngagementProgram = 'PRGA';
    public static final boolean TRUE_BOOLEAN = true;
    public static final boolean FALSE_BOOLEAN = false;
    public static final String ACTION_METADATA_COMMUNICATIONS = 'Communications';
    public static final String ACTION_METADATA_WORKFLOWS = 'Workflows';
    public static final String ACTION_METADATA_TOOLS = 'Tools';
    public static final String PC_ALL = 'All';
    public static final String PC_KM = 'km';
    public static final String PC_MI = 'mi';
    public static final String NOT_FOUND = 'NOT FOUND';
    public static final String PC_TEXTAREA = 'TEXTAREA';
    public static final String PC_ENCRYPTEDSTRING = 'ENCRYPTEDSTRING';
    public static final String PC_MULTIPICKLIST = 'MULTIPICKLIST';
    public static final String PC_TASK_CHANNEL_EMAIL = 'Email';
    public static final String PC_TASK_CHANNEL_SMS = 'SMS';
    public static final String PC_TASK_ACTION_COMPONENT_ELETTER = 'PatientConnect__PC_eLetter2';
    public static final String PC_USERTYPE_STANDARD = 'Standard';

    /*Support Plan*/
    public enum ObjectOperation {oUPDATE, oINSERT, oDELETE}
    public enum SupportPlanInfoContext {EvaluateRuleCriteria, ExecuteActions, ProcessSupportPlanRuntimes}
    public enum SupportPlanBehaviour {RunEveryTimeRuleMatches, RunOncePerRecord, RunEveryTimeIfNoPendingRuntime}
    public enum BuilderContext {ConditionalBuilder, PropertyBuilder,PropertyBuilderInUpdate}
    public enum FormulaOperators {Add, Subtract}
    public enum OffsetType {Days, Months, Years}
    public enum UseAttachmentOrSalesforceFile {UseAttachment, UseFile, UseAttachmentAndFile, UseFileAndAttachment}
    // PC-8438 - UseAttachmentAndFile (Prefer Attachment if exist otherwise File), UseFileAndAttachment(Prefer File if exist otherwise Attachment)
    public static final String PC_RECORD_TYPE_NAME = 'Record Type Name';
    public static final String PC_RECORD_TYPE_ID = 'recordTypeId';
    public static final String PC_TRIGGER_EVENT_INSERT = 'Insert';
    public static final String PC_TRIGGER_EVENT_UPDATE = 'Update';
    public static final String PC_TRIGGER_EVENT_INSERTUPDATE = 'Insert/Update';
    public static final String PC_FIELD_TYPE_DATE = 'DATE';
    public static final String PC_FIELD_TYPE_DATETIME = 'DATETIME';
    public static final String PC_FIELD_TYPE_BOOLEAN = 'BOOLEAN';
    public static final String PC_FIELD_TYPE_DOUBLE = 'DOUBLE';
    public static final String PC_FIELD_TYPE_INTEGER = 'INTEGER';
    public static final String PC_FIELD_TYPE_PERCENT = 'PERCENT';
    public static final String PC_FIELD_TYPE_CURRENCY = 'CURRENCY';
    public static final String PC_FIELD_TYPE_REFERENCE = 'REFERENCE';
    public static final String PC_FIELD_TYPE_TIME = 'TIME';
    public static final String PC_FIELD_TYPE_STRING = 'STRING';
    public static final String PC_FIELD_TYPE_EMAIL = 'EMAIL';
    public static final String PC_FIELD_TYPE_URL = 'URL';
    public static final String PC_FIELD_TYPE_PHONE = 'PHONE';
    public static final String PC_LOG_STATUS_IN_PROGRESS = 'In Progress';
    public static final String PC_LOG_STATUS_COMPLETED = 'Completed';
    public static final String PC_LOG_STATUS_FAILED = 'Failed';
    public static final String PC_TASK_STATUS_WAITING = 'Waiting on someone else';
    public static final String PC_TASK_STATUS_CLOSED = 'Closed';
    public static final String PC_ANY_VALUE = '--PC_Any--';
    public static final String PC_TODAY_VALUE = '--PC_Today--';
    public static final String PC_NOW_VALUE = '--PC_Now--';
    public static final String PC_FORMULA_VALUE = '--PC_Formula--';
    public static final String PC_NULL = 'NULL';
    public static final String PC_CREATE_RECORD_ACTION_CLASS = 'PC_CreateRecordAutomationTask';
    public static final String PC_UPDATE_RECORD_ACTION_CLASS = 'PC_UpdateRecordAutomationTask';
    public static final String PC_UPDATE_FIRST_RECORD = 'FIRST_RECORD';
    public static final String PC_UPDATE_ALL_RECORDS = 'ALL_RECORDS';
    public static final String PC_UPDATE_ONLY_RECORD = 'ONLY_RECORD';

    /*Connection User for Salesforce to Salesforce Connection*/
    public static final String CONNECTIONUSER_FName = 'Connection';
    public static final String CONNECTIONUSER_LName = 'User';
    public static final String CONNECTIONUSER_Type = 'PartnerNetwork';

    /*Automated User Type from User Object*/
    public static final String PC_AUTOMATED_PROCESS_USERTYPE = 'AutomatedProcess';
    public static final String PC_ELETTER_AUTOMATED_TASK = 'eLetter';


    /*Support Model/Holiday management*/
    public static final String PC_ROLE_CARE_COORDINATOR = 'Care Coordinator';
    public static final String PC_ROLE_REIMBURSEMENT_SPECIALIST = 'Reimbursement Specialist';
    public static final String WEEKEND_DAY_FORMAT = 'EEEE'; //DO NOT CHANGE
	public static final String PC_ROLE_TELEHOMECARE_CLINICIAN = 'Telehomecare Clinician';
    public static final String PC_SATURDAY = 'Saturday';
    public static final String PC_SUNDAY = 'Sunday';

    /*SMS functionality*/
    public static final String PC_SMS= 'SMS';
    public static final String PC_APP_MESSAGE= 'App Message';
    public static final String PC_SMS_TITLE= 'SMS / Text Chat - ';
    public static final String PC_SMS_SENT = 'Sent';
    public static final String PC_SMS_RECEIVED = 'Received';

    /*SMS Sender2*/
    public static final String PC_GLOBAL_SMS_SENDER_NUMBERS = 'PC_GlobalSMSSenderNumbers';
    public static final String PC_MESSAGE_TRANSACTION_ID_KEY = 'MSG';
    public static final String PC_SMS_SERVICE_NAME= 'PC_SmsServiceClassName';
    public static final String PC_BATCH_SMS_SERVICE_NAME= 'PC_BatchSmsServiceClassName';
    public static final String PC_TWILIO_NAMED_CREDENTIAL= 'PC_TwilioNamedCredentialName';
    public static final String PC_TWILIO_ACCOUNTSID= 'PC_TwilioAccountSid';
    public static final String PC_TWILIO_CALLBACKURL= 'PC_TwilioCallbackURL';
    public static final String PC_TWILIO = 'Twilio';
    public static final String PC_TWILIO_TOKEN_PARAMETER = 'PC_TwilioTokenParameter';
    public static final String PC_EXTERNAL_RECIPIENTS = 'PC_ExternalRecipients';
    public static final String PC_INBOUND_SMS_NOTIFICATION_DEVELOPER_NAME = 'PC_InboundSMSNotification';



    /*Document*/

    public static final String DOCUMENT_OBJECT = PC_Constants.getQualifiedAPIName('PC_Document__c');
    public static final String DOCUMENT_FAX_INBOUND_RECORD_TYPE = 'PC_Fax_Inbound';
    public static final String DOCUMENT_FAX_OUTBOUND_RECORD_TYPE = 'PC_Fax_Outbound'; //Added for Fax-outbound documents
    public static final String DOCUMENT_EMAIL_INBOUND_RECORD_TYPE = 'PC_Email_Inbound';
	public static final String DOCUMENT_EMAIL_ATTACHMENT_RECORD_TYPE = 'PC_Email_Attachment';
    public static final String DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE = 'PC_Email_Outbound';
    public static final String DOCUMENT_SMARTFORM_RECORD_TYPE = 'PC_Online_Form';
    public static final String DOCUMENT_SMARTFORM_RECORD_TYPE_NAME = 'Online Form';
    public static final String DOCUMENT_ARTICLE_KNOWLEDGE_RECORD_TYPE = 'PC_Knowledge_Article';
    public static final String DOCUMENT_MANUALY_UPLOADED = 'PC_Manual_Upload';
    public static final String DOCUMENT_SPLIT_SERVICE = 'PC_Document_Split_Service';
    public static final String DOCUMENT_STATUS_CATEGORIZED = 'In Review';
    public static final String DOCUMENT_STATUS_DISCARDED = 'Discarded';
    public static final String DOCUMENT_STATUS_SPAM = 'Spam';
    public static final String DOCUMENT_STATUS_ILLEGIBLE = 'Illegible';
    public static final String DOCUMENT_STATUS_IN_REVIEW = 'In Review';
    public static final String DOCUMENT_STATUS_REVIEW_NEEDED = 'Review Needed';
    public static final String DOCUMENT_STATUS_ARCHIVED = 'Archived';
    public static final String DOCUMENT_STATUS_NEW = 'New';
    public static final String DOCUMENT_STATUS_SPLIT_IN_PROGRESS = 'Split in Progress';
    public static final String DOCUMENT_STATUS_READY_FOR_SPLIT = 'Ready for Split';
    public static final String DOCUMENT_STATUS_AWAITING_ATTACHMENT = 'Awaiting Attachment';
    public static final String DOCUMENT_STATUS_SPLIT_FAILURE = 'Split Failure';
    public static final String DOCUMENT_STATUS_COMPLETE = 'Complete and Ready for Use';
    public static final String DOCUMENT_STATUS_COMPLETED = 'Completed';
    public static final String DOCUMENT_FIELD_SET = 'PC_Document_FieldSet';
    public static final String ID_PARAM = 'ID';
    public static final String OWNER_ID_PARAM = 'OwnerId';

    /*File*/
    public static final String FILE_SHARING_OPTION_ALLOWED = 'A';
    public static final String FILE_SHARE_TYPE_VIEWER = 'V';
    public static final String DOCUMENT_TYPE_FILE = 'file';
    public static final String DOCUMENT_TYPE_ATTACHMENT = 'attachment';
    public static final String DOCUMENT_TYPE_NONE = 'none';
    public static final String DOCUMENT_TYPE_BOTH = 'both';
    public static final String DOCUMENT_TYPE_CHILD = 'child';
    public static final String DOCUMENT_TYPE_PARENT = 'parent';


    /* Pharmacy Referral */  //[PC-1704]
    public static final String REFERRAL_STATUS_STARTED = 'Started';
    public static final String REFERRAL_STATUS_READY_TO_SEND = 'Ready to Send';
    public static final String REFERRAL_STATUS_SENT = 'Sent';
    public static final String REFERRAL_STATUS_ACTIVE = 'Active';
    public static final String REFERRAL_STATUS_DISCONTINUED = 'Discontinued';
    public static final String REFERRAL_STATUS_ERROR = 'Error';
    public static final String REFERRAL_STATUS_CLOSED = 'Closed';
    public static final String REFERRAL_STATUS_CANCELED = 'Canceled';
    
   
    /*Create Account*/
    public static final String PATIENT_OBJECT = 'Account';
    //public static final String PATIENT_RECORD_TYPE = 'PC_Patient';
    public static final String PC_BUSINESSACCOUNT_PATIENT_RECORD_TYPE = 'PC_Patient';
    private static String patientRecordType;
    public static final String PATIENT_RECORD_TYPE {
        get {
            if(String.isBlank(patientRecordType)) {
                if(PC_SYSTEM.isPersonAccountEnabled()) {
                    patientRecordType = PC_SYSTEM.getPatientConnectSetting(PC_PersonAccountPatientRecordTypeSettingName,
                            PC_PersonAccountPatientRecordTypeDefaultSettingValue);
                }
                else {
                    patientRecordType = PC_BUSINESSACCOUNT_PATIENT_RECORD_TYPE;
                }
            }
            return patientRecordType;
        }
    }
    /*PC-7442: Fetch configured Program Case record type developer name.If program case record type developer name is not configured then we provide
     the default program case record type developer name*/
    private static String DEFAULT_PROGRAM_RECORD_TYPE = 'PC_Program';
    private static String programRecordType;
    private static String programRecordTypeNamespace;
    public static final String CASE_PROGRAM_RECORD_TYPE {
        get {
            if(String.isBlank(programRecordType)){
                programRecordType = getProgramCaseRecordTypeDeveloperName();

                if(String.isBlank(programRecordType)){
                    programRecordType= DEFAULT_PROGRAM_RECORD_TYPE;

                    /*Since the configured program record type developer name is blank, we will return Patient Connect's namespace*/
                    programRecordTypeNamespace = OrgNamespace;
                }
                else{
                    programRecordTypeNamespace = getProgramCaseRecordTypeNamespace();
                }
            }
            return programRecordType;
        }
    }

    public static final String CASE_PROGRAM_RECORD_TYPE_NAMESPACE{
        get {
            //We need to call the setting logic of CASE_PROGRAM_RECORD_TYPE so as we can get the configured/default case record type namespace value
            String caseProgramRecordTypeDevName = CASE_PROGRAM_RECORD_TYPE;
            return programRecordTypeNamespace;
        }
    }

    /*PC-7442: End*/
    public static final String PHARMACY_RECORD_TYPE = 'PC_Pharmacy';
    public static final String PATIENT_ACCOUNT_TYPE_VALUE = 'Patient';
    public static final String FIELD_TRAINING_NURSE_RECORD_TYPE = 'PC_Field_Training_Nurse';
    public static final String PHYSICIAN_RECORD_TYPE = 'PC_Physician';
    public static final String MANUFACTURER_RECORD_TYPE = 'Manufacturer';//Added for Manufacturer account required in Engagement Program
    public static final String NO_OVERRIDE_PARAM = 'nooverride';
    public static final String NO_OVERRIDE_1 = '1';
    public static final String RET_URL_PARAM = 'retURL';
    public static final String RECORD_TYPE_PARAM = 'RecordType';
    public static final String RECORD_TYPE_ID = 'RecordTypeId';
    public static final String PATIENT_BIRTH_DATE_FIELD = 'PC_Patient_Date_of_Birth__c';
    public static final String ACCOUNT_ID_FIELD = 'AccountId';
    public static final String ACCOUNT_INDIVIDUAL_RECORD_TYPE = 'IndustriesIndividual';
    public static final String ACCOUNT_INDIVIDUAL_RECORD_TYPE_NAMESPACE = 'Industries';
    public static final String COMPLETED = 'Completed';
    public static final String SELF = 'Self';
    public static final String CAREGIVER_RECORD_TYPE = 'PC_Caregiver';
    public static final String PAYER_RECORD_TYPE = 'Payer';
    
    /*Create Case*/
    public static final String CASE_ORIGIN_FAX = 'Fax';
    public static final String CASE_ORIGIN_EMAIL = 'Email';
    public static final String CASE_ORIGIN_PHONE = 'Phone';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CASE_ORIGIN_OTHER = 'Other';
    
    /*candidate patient view*/
    public static final String CANDIDATE_PATIENT_OBJECT = PC_Constants.getQualifiedAPIName('PC_Applicant__c');
    public static final String PC_HEALTH_PLAN = PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'); //'PC_Health_Plan__c';
    public static final String HEALTH_PLAN_PRIVATE_RECORD_TYPE = 'PC_Private_Health_Plan';
    public static final String HEALTH_PLAN_PUBLIC_RECORD_TYPE = 'PC_Public_Health_Plan';
    public static final String HEALTH_PLAN_MEDICAL_RECORD_TYPE = 'PC_Medical_Plan';
    public static final String HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE = 'PC_PHARMACY_PLAN';
    public static final String HEALTH_PLAN_TYPE_PUBLIC = 'Public';
    public static final String HEALTH_PLAN_TYPE_PRIVATE = 'Private';
    public static final String HEALTH_PLAN_TYPE_PRIMARY = 'Primary';
    public static final String HEALTH_PLAN_TYPE_SECONDARY = 'Secondary';
    public static final String HEALTH_PLAN_TYPE_TERTIARY = 'Tertiary';
    public static final String PC_PROGRAM_COVERAGE = PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c');
    public static final String PC_SUPPORT_PLAN = PC_Constants.getQualifiedAPIName('PC_SupportPlan__c');
    public static final String PC_INTERACTION = PC_Constants.getQualifiedAPIName('PC_Interaction__c');
    public static final String PC_ERROR_LOG_INFO = 'PC_Error_Log_Info__e';
    public static final String PC_REMOTE_SERVICE_LOG_INFO = 'PC_Remote_Service_Log_Info__e';
    public static final String PC_SUPPORT_PLAN_INFO = 'PC_SupportPlanInfo__e';
    public static final String PC_AUTOMATION_TASK = 'PC_Automation_Task__e';
    public static final String PC_AUTOMATION_TASK_HANDLER = 'PC_AutomationTaskHandler';
    public static final String PC_ERROR_LOG_INFO_HANDLER = 'PC_ErrorLogInfoHandler';
    public static final String PC_REMOTE_SERVICE_LOG_INFO_HANDLER = 'PC_RemoteServiceLogInfoHandler';
    public static final String PC_SUPPORT_PLAN_INFO_HANDLER = 'PC_SupportPlanInfoHandler';
    public static final String APPLICANT_INTERNAL_RECORD_TYPE = 'PC_Internal';
    public static final String APPLICANT_INTERNAL_RECORD_TYPE_NAME = 'Internal';
    public static final String APPLICANT_ONLINE_RECORD_TYPE = 'PC_Online';
    public static final String APPLICANT_ONLINE_RECORD_TYPE_NAME = 'Online';

    /*Program Coverage*/
    public static final String PROGRAM_COVERAGE_PRIVATE_RECORD_TYPE = 'PC_Private_Coverage';
    public static final String PROGRAM_COVERAGE_PUBLIC_RECORD_TYPE = 'PC_Public_Coverage';
    public static final String PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE = 'PC_Pharmacy_Plan';
    public static final String PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE = 'PC_Medical_Coverage';
    public static final String PRIVATE_COVERAGE_TYPE = 'Private Coverage';
    public static final String PUBLIC_COVERAGE_TYPE = 'Public Coverage';
    public static final String PHARMACYPLAN_COVERAGE_TYPE = 'Pharmacy Plan Coverage';

    /*roles*/
    public static final String ROLE_TREATING_PHYSICIAN = 'Treating Physician';
    public static final String ROLE_FIELD_REIMBURSEMENT_MANAGER = 'Field Reimbursement Manager';

    /*Status Indicators*/
    public static final String STATUS_INDICATOR_COMPLETE = 'Complete';
    public static final String STATUS_INDICATOR_INCOMPLETE = 'Incomplete';
    public static final String STATUS_INDICATOR_NOTSTARTED = 'Not Started';
    public static final String STATUS_INDICATOR_INPROGRESS = 'In Progress';
    public static final String STATUS_INDICATOR_OPEN = 'Open';

    public static final String STATUS_INDICATOR_TYPE_COVERAGEAPPROVED = 'PC_COVERAGEAPPROVED';
    public static final String STATUS_INDICATOR_TYPE_PATIENTENROLLMENT = 'PC_PATIENTENROLLED';
    public static final String STATUS_INDICATOR_TYPE_APPOINTMENT = 'PC_APPOINTMENT';
    public static final String STATUS_INDICATOR_TYPE_EDUCATION = 'PC_EDUCATION';
    
    public static final String LINK_ASSOCIATION_TYPE_PROGRAM = 'Program';
    public static final String LINK_ASSOCIATION_TYPE_ENROLLMENT = 'Enrollment';
    public static final String LINK_ASSOCIATION_TYPE_COVERAGE = 'Coverage';
    public static final String LINK_ASSOCIATION_TYPE_ADVERSE_EVENT = 'Adverse Event';
    public static final String LINK_ASSOCIATION_TYPE_ADVERSE_EVENT2 = 'Adverse Event 2';
    public static final String LINK_ASSOCIATION_TYPE_INTERACTION = 'Interaction';
    public static final String LINK_ASSOCIATION_TYPE_PATIENT = 'Patient';
    public static final String SEARCH_PATIENT_FIELDSET_OBJECT = PC_Constants.getQualifiedAPIName('PC_Search_patient');

    public static final String STATUS_INDICATOR_TYPE_CONSENT = 'PC_Consent';
    public static final String STATUS_INDICATOR_TYPE_COVERAGE = 'PC_Coverage';
    public static final String STATUS_INDICATOR_TYPE_ENGAGEMENT = 'PC_Engagement';
    public static final String STATUS_INDICATOR_TYPE_ADHERENCE = 'PC_Adherence';
    public static final String STATUS_INDICATOR_TYPE_LABS = 'PC_Labs';

    public static final String STATUS_LABEL_TYPE_CONSENT = 'Consent';
    public static final String STATUS_LABEL_TYPE_COVERAGE = 'Coverage';
    public static final String STATUS_LABEL_TYPE_ENGAGEMENT = 'Engagement';
    public static final String STATUS_LABEL_TYPE_ADHERENCE = 'Adherence';
    public static final String STATUS_LABEL_TYPE_LABS = 'Labs';

    public static final String STATUS_INDICATOR_NOT_APPLICABLE = 'Not applicable';
    
    //Compliance
    public static final string CASE_INDICATOR_INCOMPLIANT = 'In Progress';
    public static final string CASE_PROGRAMTYPE_AHDERENCE = 'Adherence';
    public static final string CASE_PROGRAMTYPE_COVERAGE = 'Coverage';

    //patient wizard
    public static final String TRUE_STRING = 'true';
    public static final String FALSE_STRING = 'false';
    public static final String YES_STRING = 'Yes';
    public static final String NO_STRING = 'No';
    public static final String NULL_STRING = 'null';
    public static final String ENROLLMENT_FORM_FIELD_SET = 'PC_Enrollment_Form';
    public static final String ENROLLMENT_FORM_LIST_FIELD_SET = 'PC_Enrollment_Form_List';
    public static final String ENROLLMENT_RECORD_TYPE = 'PC_Enrollment';
    public static final String NOT_ENROLLMENT = 'Not Enrollment';
    public static final String NEW_ENROLLMENT = 'New Enrollment';
    public static final String COMPLETED_ENROLLMENT = 'Completed Enrollment';
    public static final String NEW_ENROLLMENT_WITHOUT_APPLICANT = 'New Enrollment Without Applicant';
    public static final String PICKLIST_NONE = '__none';
    public static final String PICKLIST_NONE_VAL = 'None';

    //queue developer name
     public static final String PATIENT_CONNECT_QUEUE = 'Patient_Connect_Queue';

     //alert status
     public static final String ALERT_OVERRIDDEN_STATUS = 'Overridden';

     public static final String ADDRESS_OBJ_API = PC_Constants.getQualifiedAPIName('PC_Address__c');
  	 public static final String MEDICATION_OBJ_API = PC_Constants.getQualifiedAPIName('PC_Medication__c');

     //treatment cycles
     public static final String STATUS_INDICATOR_ENROLLED = 'Enrolled';
     public static final String STATUS_INDICATOR_ONHOLD = 'On Hold';
     public static final String STATUS_INDICATOR_WITHDRAWN = 'Withdrawn';

     public static final String PAP_RECORD_TYPE = 'PC_PAP';

     // Patient Gender Picklist values
     public static final String PATIENT_MALE = 'Male';
     public static final String PATIENT_FEMALE = 'Female';
     // Account HCO role picklist values
     public static final String ACCOUNT_ROLE = 'HCO';

    // Program Coverage - Prior Authorization Required - picklist values
    public static final String PROGRAM_COVERAGE_PRIOR_AUTHORIZATION_REQUIRED_YES = 'Yes';
    public static final String PROGRAM_COVERAGE_PRIOR_AUTHORIZATION_REQUIRED_NO = 'No';
    public static final String PROGRAM_COVERAGE_PENDING_PA = 'Pending PA';

    //HCO Wizard Page RecordType for HCO serach
    public static final String HCO_RecordType = 'HCO';
    
    //Service and Service Permission
    public static final String SERVICE_FUNCTION = 'Referral Notification';
    public static final String SERVICE_COMMUNICATION_CHANNEL = 'Email';
    public static final String PERMISSION_HCP_RESPONSE = 'Granted';
    public static final String PERMISSION_PATIENT_RESPONSE = 'Granted';
    public static final String CARE_TEAM_MEMBER_RESPONSE = 'Granted';

    //Support Plan [PC-2805]
    public static final String SUPPORTPLANRT_ACTIVITY_STATUS_INPROGRESS = 'In Progress';
    public static final String SUPPORTPLANRT_ACTIVITY_STATUS_PENDINGCONDITION = 'Pending Condition';
    public static final String SUPPORTPLANRT_ACTIVITY_STATUS_SKIPACTIVITY = 'Skip Activity';
    public static final String SUPPORTPLANRT_ACTIVITY_STATUS_COMPLETED = 'Completed';
    public static final String SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE = 'No Condition';
    public static final String SUPPORTPLAN_CONDBEHAVIOR_STATUS_WAIT = 'Wait until True';
    public static final String SUPPORTPLAN_CONDBEHAVIOR_STATUS_SKIPFALSE = 'Skip if False';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK = 'User Task';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE = 'Sequence';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE_TASK = 'Sequence Task';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_AUTOMATED_TASK = 'Automation Task';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_CREATE_RECORD = 'Create Record';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_UPDATE_RECORD = 'Update Record';
    public static final String SUPPORTPLAN_ACTIVITY_TYPE_PUBLISH_PLATFORM_EVENT = 'Publish Platform Event';
    public static final String SUPPORTPLANRT_STATUS_IN_PROGRESS = 'In Progress';
    public static final String SUPPORTPLANTASK_REFERENCETYPE_AFTERPREVACTIVITY = 'After completion of previous activity';
    public static final String SUPPORTPLANTASK_REFERENCETYPE_BEFOREREFDATE = 'Before Reference Date';
    public static final String SUPPORTPLANTASK_REFERENCETYPE_AFTERREFDATE = 'After Reference Date';
    public static final String SUPPORTPLANTASK_REFERENCEUNIT_DAYS = 'Days';
    public static final String SUPPORTPLANT_LISTVIEWNAME = 'All';
    public static final String SUPPORTPLAN_USERTASK = 'User Task';
    public static final String SUPPORTPLAN_OVERRIDE_PREVIOUS = 'override previous';
    public static final String SUPPORTPLAN_METADATA_ALL_SP = 'All';
    public static final String SUPPORTPLAN_TASK_STATUS_INPROGRESS = 'In Progress';
    public static final String SUPPORTPLAN_INITIATIONHANDLER_CLASSNAME = 'PC_SupportPlanInitiationHandler';
    public static final String SUPPORTPLAN_OTHER_SOBJECT = 'Other';
    public static final String SUPPORTPLAN_UPDATE_TRIGGER_RECORD = 'updateTriggerRecord';
    public static final String SUPPORTPLAN_UPDATE_LOOKUP_RECORD = 'updateLookupRecord';
    public static final String SUPPORTPLAN_UPDATE_CHILD_RECORDS = 'updateChildRecords';
    public static final String SUPPORTPLAN_DEFAULT_BEHAVIOR = 'RunOncePerRecord';
    public static final String SUPPORTPLAN_TRANSACTION_ID_KEY = 'SPAL';
    public static final String SUPPORTPLAN_PREVIOUS_ACTIVITY_KEY = 'previousActivity';
    public static final String PC_MAX_SP_RECURSIVE_EXECUTIONS_ALLOWED = 'PC_MaxSPRecursiveExecutionsAllowed';

    public static final String PC_TRANSACTION_ID_KEY = 'TID';
    public static final String PC_HYPHEN = '-';

    public static final String PA_STATUS_INITIATED = 'Initiated';
    public static final String PA_STATUS_PA_REQEUST_SUBMITTED_TO_PLAN = 'PA Request Submitted to Plan';
    public static final String PA_STATUS_PLAN_PA_RESPONSE = 'Plan PA Response';
    public static final String PA_STATUS_QUESTION_REQUEST_SUBMITTED_TO_PLAN = 'Question Request Submitted to Plan';
    public static final String PA_STATUS_PLAN_QUESTION_RESPONSE = 'Plan Question Response';
    public static final String PA_STATUS_PLAN_QUESTION_SET_READY_FOR_PROVIDER = 'Plan Question Set Ready for Provider';
    public static final String PA_STATUS_CANCEL_REQUEST_SENT = 'Cancel Request Sent';
    public static final String PA_STATUS_CANCELLED = 'Cancelled';
    public static final String PA_STATUS_ARCHIVED = 'Archived';
    public static final String PA_STATUS_EXPIRED = 'Expired';
    public static final String PA_STATUS_FAILURE = 'Failure';
    public static final String PA_STATUS_PA_SHARED_WITH_PROVIDER = 'PA shared with Provider';
    public static final String PA_STATUS_PA_ACCESSED_BY_PROVIDER = 'PA accessed by Provider';
    public static final String PA_STATUS_SENT_TO_PLAN = 'Sent to Plan';
    public static final String PA_STATUS_APPEALED = 'Appealed';

    public static final String PA_OUTCOME_APPROVED = 'Approved';
    public static final String PA_OUTCOME_DENIED = 'Denied';
    public static final String PA_OUTCOME_PENDING = 'Pending';
    public static final String PA_OUTCOME_CANCELLED = 'Cancelled';
    public static final String PA_OUTCOME_UNKNOWN = 'Unknown';
    public static final String PA_OUTCOME_UNSENT = 'Unsent';
    public static final String PA_OUTCOME_NA = 'N/A';

    public static final String TASK_FIELDS_REQUIRED_FIELDSET = PC_Constants.getQualifiedAPIName('Task_Fields_Required');

    public enum SETTINGS_TYPE { PATIENT_CONNECT_SETTING, INTEGRATION_SETTING } // Refers to the Setting Name in Engagement Program Setting mdt

    //Patient Connect Setting Name Constants
    public static final String PC_PersonAccountPatientRecordTypeSettingName = 'PC_PersonAccountPatientRecordType';
    public static final String PC_PersonAccountPatientNamespaceSettingName = 'PC_PersonAccountPatientRecordTypeNamespace';
    public static final String PC_PersonAccountPatientNamespaceDeveloperName = 'PC_PA_PatientRecordTypeNamespace';
    public static final String PC_PRE_ENROLLMENT_DISPLAY        = 'PC_PreEnrollmentDisplay';
    public static final String PC_PRE_ENROLLMENT_SEARCH         = 'PC_PreEnrollmentSearch';

    public static final String PC_PRE_ENROLLMENT_FORM_FIELDSET   = 'PC_PreEnrollmentFormFieldset';
    public static final String PC_MASTER_PATIENT                 = 'PC_MasterPatient';

    public static final String PC_MANAGED_PACKAGE_USER_CHECK     = 'PC_ManagedPackageUserCheck';

    public static final String PC_ACCOUNT_APPLICANT_MAPPING     = 'PC_AccountToApplicantMapping';
    public static final String PC_ADDRESS_APPLICANT_MAPPING     = 'PC_AddressToApplicantMapping';
    public static final String PC_USE_DOCUMENT_FILES     = 'PC_UseDocumentFiles';
    public static final String PC_DOCUMENT_PREVIEW_STRICT_MODE    = 'PC_DocumentPreviewStrictMode';
    public static final String PC_AUTOMATED_TASK_EMAIL          = 'PC_AutomatedTaskEmail';
    public static final String PC_AE_VF_PAGE_NAME               = 'PC_AdverseEventVFPageName';
    public static final String PC_AE2_DEFAULT_VF_PAGE_NAME       = PC_Constants.getQualifiedAPIName('PC_AdverseEvent2_VF_To_PDF');
    public static final String PC_AE_DEFAULT_VF_PAGE_NAME       = PC_Constants.getQualifiedAPIName('PC_AdverseEvent_VF_To_PDF');
    public static final String PC_AE_MENU_COMPONENT_ATTR       = 'adverseEventMenuCmpAttributes';
    public static final String PC_AE_ADDITIONAL_INFO_TAB_FS       = 'additionalInfoTabFieldSet';
    public static final String PC_AE_HIDE_ADDITIONAL_INFO_TAB       = 'hideAdditionalInfoTab';
    public static final String PC_AE_HIDE_MANUFACTURER_TAB       = 'hideMfr';
    public static final String PC_AE_HIDE_NOTES_SECTION       = 'hideNotes';
    public static final String PC_AE_HIDE_CODING_SECTION_IN_AE_TAB  = 'hideCoding';
    public static final String PC_AE_USE_PRESCRIPTION       = 'usePrescriptionForSuspectProducts';
    public static final String PC_AE_SUSPECT_PRESCRIPTION_RX_FIELD_MAP = 'PC_AESuspectPrescriptionRxFieldMap';
    public static final String PC_AE_SUSPECT_PRESCRIPTION_PRODUCT_FIELD_MAP = 'PC_AESuspectPrescriptionProductFieldMap';
    public static final String PC_AE_MI_SUSPECT_PRESCRIPTION_RX_FIELD_MAP = 'PC_AE_MIPrescriptionRxFieldMap';
    public static final String PC_AE_MI_SUSPECT_PRESCRIPTION_PRODUCT_FIELD_MAP = 'PC_AE_MIPrescriptionProductFieldMap';
    public static final String PC_AE_FIELD_SET_NAME       = 'fieldSetName';
    public static final String PC_AE_FIELD_MAP      = 'fieldsMap';
    public static final String PC_AE_NO_FIELDS_FOUND_ERROR_MESSAGE     = 'No fields found in the fieldset configured in the Patient Connect Setting: ';
    public static final String PC_AE_INVALID_FIELDSET_ERROR_MESSAGE     = 'Invalid Fieldset name configured in the Patient Connect Setting: ';
    public static final String PC_AE_JSON_FORMAT_INCORRECT_ERROR_MESSAGE     = 'JSON Format is incorrect in the Patient Connect Setting: ';
    public static final String PC_AE_FIELD_MAPPING_INCORRECT_ERROR_MESSAGE     = 'Field Mapping is missing or incorrect for following fieldset fields: ';
    public static final String PC_AE_CONTACT_SYSTEM_ADMINISTRATOR_ERROR_MESSAGE     = 'Please contact System Administrator.';

    public static final String PC_AE2_ADDITIONAL_INFO_FIELDSET       = 'PC_AE2AdditionalInfoFieldSet';
    public static final String PC_AE_ADDITIONAL_INFO_FIELDSET       = 'PC_AEAdditionalInfoFieldSet';
    public static final String PC_AE_DEFAULT_ADDITIONAL_INFO_FIELDSET  = PC_Constants.getQualifiedAPIName('PC_AE_Additional_Information');
    public static final String PC_AE2_DEFAULT_ADDITIONAL_INFO_FIELDSET  = PC_Constants.getQualifiedAPIName('PC_AE2_Additional_Information');

    public static final String PC_SUSPECT_PRESCRIPTION_OBJECT = PC_Constants.getQualifiedAPIName('PC_Suspect_Prescription__c');

    public static final String PC_PersonAccountPatientRecordTypeDefaultSettingValue = 'PC_PersonAccountPatient';
    public static final String PC_PersonAccountPatientNamespaceDefaultSettingValue = '';
    public static final String PC_AUTOCOMPLETE_ADDRESS = 'PC_AutoCompleteAddress';
    public static final String PC_INBOUND_EMAIL_ADDRESS_NAME = 'PC_InboundEmailAddressName';
    public static final String PC_INBOUND_EMAIL_SERVICE_NAME = 'PC_InboundEmailServiceName';
    public static final String PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT = 'PC_EletterInsertThreadIdInSubject';

    public static final String PC_UNASSIGNED_TASK_TRIAGE     = 'PC_UnassignedTaskTriage';

    // Eletter
    public static final String PC_ELETTER = 'PC_eLetter';
    public static final String PC_ELETTER_CONTEXT_NEW = 'NEW';
    public static final String PC_ELETTER_CONTEXT_REPLY = 'REPLY';
    public static final String PC_ELETTER_OBJECT_PICKLIST_INTERACTION = 'Interaction';
    public static final String PC_ELETTER_OBJECT_PICKLIST_PROGRAM_COVERAGE = 'Program Coverage';
    public static final String PC_ELETTER_CATEGORY_AUTOMATED_EMAIL = 'Automated Email';
    public static final String PC_ELETTER_CATEGORY_AUTOMATED_FAX = 'Automated Fax';

    public static final String PDF_FORMAT = '.pdf';
    public static final String JPG_FORMAT = '.jpg';
    public static final String TXT_FORMAT = '.txt';
    public static final String LOG_FORMAT = '.log';
    public static final String HTML_FORMAT = '.html';

    public static final String PC_FIELDTYPE_REFERENCE = 'REFERENCE';

    public static final String HTTP_METHOD_POST = 'POST';

    public static final String OUTBOUND = 'Outbound';
    public static final String INBOUND = 'Inbound';

    public static final String REMOTE_SERVICE_TYPE_INBOUND = 'Inbound';
    public static final String REMOTE_SERVICE_TYPE_OUTBOUND = 'Outbound';

    public static final String DEFAULT_AUTOMATION_TASK = 'PC_DefaultAutomationTask';

    /*COVERAGE BENEFIT */

    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MANAGED_MEDICAID = 'Managed Medicaid';
    //public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICAID_MEDICARE = 'Medicaid, Medicare';
    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICAID = 'Medicaid';
    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE = 'Medicare';
    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE_ADVANTAGE = 'Medicare Advantage';
    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE_SUPPLEMENT = 'Medicare Supplemental';
    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_TRICARE_VA = 'Tricare V/A';
    /*public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_GOVERNEMNT_POLICY1 =
                                                              'Government Policy Type from Government Plan Table FEP';*/

    public static final String COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_FEP ='FEP';
    public static final String UNDETERMINED = 'Undetermined';


    //Added to streamline the benefitCategory
    public enum BenefitCategory {
        Administration, Product, OfficeVisit
    }


	//Geolocation fields
    public static final String GEOLOCATION_LATITUDE_FIELD_API = PC_Constants.getQualifiedAPIName('PC_Geolocation__Latitude__s');
    public static final String GEOLOCATION_LONGITUDE_FIELD_API = PC_Constants.getQualifiedAPIName('PC_Geolocation__Longitude__s');
    private static String OrgNS;
    public static String OrgNamespace {
        get {
           	if(OrgNS == null) {
                String className = PC_Constants.class.getName();
                if(className.contains('.')) {
                	OrgNS = className.substringBefore('.');                    
                }
                else {
                    OrgNS = '';                    
                }
            }
            return OrgNS;
        }        
    }

    /*public static final String NAMED_CRED_PHARMACY_CARD_ELIGIBILITY_UBC = 'PC_UBC_CheckEligibility';
    public static final String NAMED_CRED_PHARMACY_COVERAGE_UBC = 'PC_UBC_Pharmacy_Coverage';
    public static final String NAMED_CRED_AUTH_UBC = 'PC_UBC_Token';
    public static final String NAMED_CRED_PLAN_PBM_UBC = 'PC_UBC_Plan_PBMs';
    public static final String NAMED_CRED_PHARMACY_FINDER_UBC = 'PC_UBC_Pharmacy_Finder';*/

    public static final String PC_eBENEFITS_PHARMACY_CARD_SERVICE_TYPE = 'PharmacyCard';
    public static final String PC_eBENEFITS_PHARMACY_COVERAGE_SERVICE_TYPE = 'PharmacyCoverage';
    public static final String PC_eBENEFITS_MEDICAL_COVERAGE_SERVICE_TYPE = 'MedicalCoverage';
    public static final String PC_eBENEFITS_MEDICAL_BENEFIT_SERVICE_TYPE = 'MedicalBenefit';
    public static final String PC_eBENEFITS_PHARMACY_FINDER_SERVICE_TYPE = 'PharmacyFinder';
    public static final String PC_eBENEFITS_TOKEN_SERVICE_TYPE = 'Token';
    public static final String PC_eBENEFITS_PLAN_SERVICE_TYPE = 'Plan';
    public static final String CMM_CREDENTIALS = 'PC_PriorAuthClient_CMM';
    public static final String CMM= 'CMM';

    /*eBenefits2*/
    public static final String INFINITUS= 'Infinitus';
    public static final String PC_eBENEFITS_PHARMACY_BENEFITS_INVESTIGATION_SERVICE_TYPE = 'BRE_PharmacyCoverage';
    public static final String PC_eBENEFITS_MEDICAL_BENEFITS_INVESTIGATION_SERVICE_TYPE = 'BRE_MedicalCoverage';

    public static String getQualifiedAPIName(String objectName) {
        String ns = PC_Constants.OrgNamespace;
        if(ns == '') {
            return objectName;
        }
        else {
            return ns + '__' + objectName;
        }
        //return objectName;
    }

    public static String removeNamespace(String objectName) {
        String ns = PC_Constants.OrgNamespace;
        if(ns == '' || !(objectName.contains(ns))) {
            return objectName;
        }
        else {
            return objectName.replaceAll(ns+'__', '');
        }
    }

    public static final String PC_NONE='None';
    public static final String PC_NONE_LC='none';
    public static final String PC_BEFORE_REFERENCE_DATE='Before Reference Date';
    public static final String PC_AFTER_REFERENCE_DATE='After Reference Date';
    public static final String PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY='After completion of previous activity';
    public static final String PC_ACTIVITY_CREATION_DATE ='Activity Creation Date';
    public static final String PC_COND_OPTION_APEX_CLASS='Apex Class';
    public static final String PC_COND_OPTION_CONDITIONAL_BUILDER='Conditional Builder';
    public static final String PC_COND_BEHAVIOUR_NO_CONDITION='No Condition';
    public static final String PC_ZERO='0';
    public static final String PC_DAYS='Days';
    public static final String PC_Operator_Equals='Equals';
    public static final String PC_Operator_Does_Not_Equals='Does not equals';
    public static final String PC_IN_SEQUENCE='In sequence';
    public static final String PC_ALL_AT_ONCE='All at once';
    public static final String PC_ASCENDING='ASC';
    public static final String PC_DESCENDING='DESC';
    public static final String PC_FIRST='FIRST';
    public static final String PC_LAST='LAST';

    //Operators
    public static final String PC_EQUALS                  =   'Equals';
    public static final String PC_DOESNOT_EQUALS          =   'Does not equals';
    public static final String PC_GREATER_THAN            =   'Greater than';
    public static final String PC_GREATER_THAN_OR_EQUALS  =   'Greater than or equal';
    public static final String PC_LESS_THAN               =   'Less than';
    public static final String PC_LESS_THAN_OR_EQUALS     =   'Less than or equal';
    public static final String PC_HAS_CHANGED             =   'Has changed';
    public static final String PC_HAS_NOT_CHANGED         =   'Has not changed';
    public static final String PC_IS_NULL                 =   'Is null';
    public static final String PC_IS_NOT_NULL             =   'Is not null';
    public static final String PC_CONTAINS                =   'Contains';
    public static final String PC_DOES_NOT_CONTAINS       =   'Does not contains';

    //Operators Symbols
    public static final String PC_EQUALS_SYMBOL                   =   '=';
    public static final String PC_DOESNOT_EQUALS_SYMBOL           =   '!=';
    public static final String PC_GREATER_THAN_SYMBOL             =   '>';
    public static final String PC_GREATER_THAN_OR_EQUALS_SYMBOL   =   '>=';
    public static final String PC_LESS_THAN_SYMBOL                =   '<';
    public static final String PC_LESS_THAN_OR_EQUALS_SYMBOL      =   '<=';
    public static final String PC_IS_NULL_SYMBOL                  =   '= null';
    public static final String PC_IS_NOT_NULL_SYMBOL              =   '!= null';

    // Health Cloud GA constants
    public static final String HealthCloudNamespace = 'HealthCloudGA';
    public static final String HealthCloudPermissionSetLicenseName = 'HealthCloudPermissionSetLicense';
    public static final String HealthCloudMemberServicesPermissionSetLicenseName = 'HealthCloudMemberServices';

    //Patient Connect Namespace
    public static final String PATIENTCONNECTNAMESPACE_WITHUNDERSCORES = 'PatientConnect__';

    public static final String USER_LICENSE_SALESFORCE = 'Salesforce';
    public static final String PROFILE_SALESFORCE_SYS_ADMIN = 'System Administrator';

    public static final String NAMESPACE_KEY = 'Namespace';
    public static final String RECORD_TYPE_DEV_NAME_KEY = 'RecordTypeDevName';

    public static final String PROGRAM_STATUS_ENROLLED = 'Enrolled';
    public static final String PROGRAM_STATUS_ON_HOLD = 'On Hold';
    public static final String PROGRAM_STATUS_WITHDRAWN = 'Withdrawn';
    public static final Map<String, String> PROGRAM_STATUS = new Map<String, String> {
            PROGRAM_STATUS_ENROLLED => 'Enrolled',
            PROGRAM_STATUS_ON_HOLD => 'On Hold',
            PROGRAM_STATUS_WITHDRAWN => 'Withdrawn'
    };
    public static final String PATIENT_SSN_FLD='PC_Social_Security_Number__c';
    public static final String ACCOUNT_IDENTIFIER_OBJ='PC_Account_Identifier__c';
    public static final String ACCOUNT_IDENTIFIER_TYPE_SSN ='SS';
    public static final String ACCOUNT_IDENTIFIER_TYPE_PAYER_ID ='Payer ID';
    public static final String ACCOUNT_IDENTIFIER_ASSIGNER_VMI ='urn:vmi';
    public static final String ACCOUNT_IDENTIFIER_ASSIGNER_US_SSN ='http://hl7.org/fhir/sid/us-ssn';


    public static final String PC_SHOW_DOC_LOG_AND_DESCRIPTION='PC_ShowDocumentLog_ShowDescription';
    //eLetter Framework
    public static final String PC_DEFAULT_EMAIL_TEMPLATE_PREVIEW_COMPONENT=OrgNamespace+':PC_eLetterEmailTemplatePreview';
    public static final String PC_ELETTER_PREVIEW_CLASS_NAME='PC_eLetterPreviewClassName';
    public static final String PC_ELETTER_PREVIEW_COMPONENT_NAME='PC_eLetterPreviewComponent';

    //Work Case Distribution
    public static final String PC_WCD_PROGRAM_CASE='Program Case';
    public static final String PC_WCD_ASSOCIATION='Association';
    public static final String PC_WCD_PATIENT='Patient';
    public static final String PC_ENABLE_WORK_CASE_DISTRIBUTION = 'PC_EnableWorkCaseDistribution';
    public static final String PC_ENABLE_WORK_CASE_REDISTRIBUTION = 'PC_EnableWorkCaseRedistribution';
    public static final String PC_ENABLE_ASYNCHRONOUS_WORK_CASE_DISTRIBUTION = 'PC_EnableAsyncWorkCaseDistribution';
    public static final String PC_WCD_SERVICE_CLASS_NAME = 'PC_WCDServiceClassName';
    public static final String PC_WCD_ROUND_ROBIN_HANDLER = 'PC_WCDRoundRobinService';

    //Creation of Patient Person Account RecordType Using Post-Install Script
    public static final Boolean PC_ISACTIVE = True;
    public static final String PC_PATIENT_PERSONACCOUNT_RECORDTYPE_API = 'PC_Patient';
    public static final String PC_PERSONACCOUNT = 'PersonAccount';
    public static final String PC_PERSONACCOUNT_RECORDTYPE_DESCRIPTION = 'Patient Person Account RecordType';
    public static final String PC_PATIENT_PERSONACCOUNT_RECORDTYPE_LABEL = 'Patient(Person Account)';

    //Creation of RemoteSiteSetting Using Post-Install Script
    public static final String PC_FULLNAME = 'Core_Connect';
    public static final String PC_REMOTESITESETTING_DESCRIPTION = 'Creation of RemoteSiteSetting';

    //Creation of Client OrgNamespace
    public static final String PC_CLIENTORGNAMESPACE = 'PC_ClientOrgNamespace';

    public static final String SPOUSE = 'Spouse';
    //Check Person Account Enablement
    public static final String PC_USE_PERSON_ACCOUNT = 'Use Person Account';
    public static final String PC_ISPERSONACCOUNT = 'isPersonAccount';
    public static final String PC_USE_PERSON_ACCOUNT_FOR_PC = 'PC_UsePersonAccountForPC';
    public static final String PC_DEFAULT_VALUE_OF_USE_PERSON_ACCOUNT_FOR_PC = 'false';

    //Person Account Standard Fields
    public static final String PC_PA_FIRST_NAME = 'FirstName';
    public static final String PC_PA_LAST_NAME = 'LastName';
    public static final String PC_PA_PERSON_EMAIL = 'PersonEmail';
    public static final String PC_PA_PERSON_SALUTATION = 'Salutation';



    // Default reporter type picklist value in AdverseEvent
    public static final String DEFAULT_REPORTER_TYPE_PICKLIST = 'Patient';

    // Default preferredResponseWindow picklist value in AdverseEvent
    public static final String DEFAULT_PREFERRED_RESPONSE_WINDOW = 'Anytime';

    public static final String MEDICALINQUIRY_EVENTTYPE = 'Medical Inquiry';
    public static final String PRODUCTCOMPLAINT_EVENTTYPE = 'Product Complaint';
    public static final String ADVERSEEVENT_EVENTTYPE = 'Adverse Event';

    //Default HealthCare Professional value in AdverseEvent
    public static final String DEFAULT_HEALTH_CARE_PROFESSIONAL_VALUE = 'No';

    //  Adverse Event Date format setting name

    public static final String PC_AE_DOWNLOAD_DATEFORMAT_NAME = 'PC_AdverseEventDownloadDateFormat';

    // Picklist value of PC_SubmissionStatus__c  on Adverse Event
    public static final String PC_AE_SUBMISSION_STATUS = 'Submitted';
    public static final String PC_AE_PATIENT_TAB = 'Patient';
    public static final String PC_AE_ADVERSE_EVENT_TAB = 'AdverseEventInfo';
    public static final String PC_AE_SUSPECT_PRODUCT_TAB = 'suspectProduct';
    public static final String PC_AE_MEDICAL_INQUIRY_TAB = 'medicalInquiry';
    public static final String PC_AE_INITIAL_REPORTER_TAB = 'InitialReporter';
    public static final String PC_AE_MANUFACTURER_TAB = 'Manufacturer';
    public static final String PC_AE_ADDITIONAL_INFO_TAB = 'AdditionalInfo';

    //Protected API Settings
    public static final String PC_GEOCODE_API_NAME = 'PC_GoogleGeocodeApiToken';
    public static final String PC_GEOCODE_API_ENDPOINT_URL_SETTING_NAME = 'PC_GeocodeAPIEndPointURL';
    public static final String PC_GEOCODE_API_ENDPOINT_URL_DEFAULT_VALUE = 'https://maps.googleapis.com/maps/api/geocode/json?address={address}&sensor=false&key={googleAPIKey}';

    public static final String PC_RecordTypeDeveloperName = 'RecordType';

    public static final String PC_PatientSearchIdentifier = 'PC_PatientSearch';

    public static final String PC_ADMIN_ACCESS = 'PC_AdminAccess';

    public static final String PC_Group = 'Group';
    public static final String PC_Queue = 'Queue';
    public static final String PC_AdverseEventObjectInUse= 'PC_AdverseEventObjectInUse';
    public static final String PC_AdverseEvent_Object= 'PC_AdverseEvent__c';
    public static final String PC_AdverseEvent2_Object= 'PC_AdverseEvent2__c';

    //Adverse Event Email
    public static final String PC_AdverseEventEmailAddressSettingName = 'PC_AdverseEventEmailRecipients';

    //Picklist Value
    public static final String PC_PicklistType = 'Picklist';

    //System fields api name
    public static final String PC_IsDeleted = 'IsDeleted';
    public static final String PC_CreatedDate = 'CreatedDate';
    public static final String PC_CreatedById = 'CreatedById';
    public static final String PC_LastModifiedDate = 'LastModifiedDate';
    public static final String PC_LastModifiedById = 'LastModifiedById';
    public static final String PC_SystemModstamp = 'SystemModstamp';
    public static final String PC_LastReferencedDate = 'LastReferencedDate';
    public static final String PC_LastViewedDate = 'LastViewedDate';
    public static final String PC_MasterRecordId = 'MasterRecordId';
    public static final String PC_LastActivityDate = 'LastActivityDate';

    //Mandatory And Non-Mandatory
    public static final String PC_NOTMANDATORY = 'NOT_MANDATORY';
    public static final String PC_MANDATORY = 'MANDATORY';

    //Task Fieldset Name for support plan activity properties
    public static final String PC_TaskFieldSetNameForCaseObject = 'Task_Fields_Required';
    public static final String PC_TaskFieldSetNameForNonCaseObjects = 'PC_TaskFieldSetForNonCaseObjects';

    //Log a call recordType
    public static final String PC_LOGACALL = 'PC_LogCall';

    //Other
    public static final String PC_OTHER = 'Other';

    //PC-7442: Settings related to configured program case record developer name
    public static final String PC_ProgramCaseRecordTypeSettingName = 'PC_ProgramCaseRecordType';
    public static final String PC_ProgramCaseRecordTypeNamespaceSettingName = 'PC_ProgramCaseRecordTypeNamespace';

    /**********************************************************************************************
    Method Name    : getProgramCaseRecordTypeNamespace
    Description    : PC-7442 Get the configured/default namespace for program case record type
    Return Type    : String
    **********************************************************************************************/
    private static String getProgramCaseRecordTypeNamespace(){
        String strProgramCaseRecordTypeNamespace ;

        /* Please note DO NOT use this method, please use PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAMESPACE instead to get the intended values*/
        strProgramCaseRecordTypeNamespace = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ProgramCaseRecordTypeNamespaceSettingName,'');

        return  strProgramCaseRecordTypeNamespace;
    }

    /**********************************************************************************************
    Method Name    : getProgramCaseRecordTypeDeveloperName
    Description    : PC-7442 Get the configured/default program case record type developer name
    Return Type    : String
    **********************************************************************************************/
    private static String getProgramCaseRecordTypeDeveloperName(){
        String strProgramCaseRecordType;

        /* Please note DO NOT use this method, please use PC_Constants.CASE_PROGRAM_RECORD_TYPE instead to get the intended values*/
        strProgramCaseRecordType = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ProgramCaseRecordTypeSettingName, '');

        return  strProgramCaseRecordType;
    }

    //Object Names
    public static final String PC_EMAIL_MESSAGE = 'EmailMessage';
    public static final String PC_EMAIL_MESSAGE_RELATION = 'EmailMessageRelation';
    public static final String PC_EVENT = 'Event';

    //FRM User Permission Set
    public static final String PC_FRMUSER_PERMISSIONSET = 'PC_FRMUserPermissions';

    //OCR
    public static final String PC_OCR_SERVICE_PROVIDER = 'PC_OcrServiceProvider';
    public static final String PC_OCR_SERVICE_CLASSNAME = 'PC_OcrServiceClassName';
    public static final String PC_OCR_RESPONSE_PARSER_CLASSNAME = 'PC_OcrResponseParserClassName';
    public static final String PC_DEFAULT_TEXTRACT_OCRSERVICE_CLASSNAME = PC_Constants.OrgNamespace + '.PC_OcrServiceTextract';
    public static final String PC_DEFAULT_TEXTRACT_RESPONSE_PARSER_CLASSNAME = PC_Constants.OrgNamespace + '.PC_AwsTextractParser';
    public static final String PC_OCR_STATUS_QUEUED = 'Queued';
    public static final String PC_OCR_STATUS_SUCCESS = 'Success';
    public static final String PC_OCR_STATUS_ERROR = 'Error';
    public static final String PC_OCR_QUEUE_STATUS_CANCELED = 'Canceled';
    public static final String PC_OCR_QUEUE_STATUS_COMPLETED = 'Completed';
    public static final String PC_OCR_RESPONSE_STATUS_ENQUEUE = 'OCR Enqueue';
    public static final String PC_OCR_SERVICE_AMAZON_TEXTRACT = 'Amazon Textract';
    // Share type 'V' is the Viewer permission. The user can explicitly view but not edit the shared file.
    public static final String PC_FILE_SHARE_TYPE_VIEWER = 'V';
    public static final String PC_AWS_S3_NAMED_CREDENTIAL_NAME= 'PC_AwsS3NamedCredentialName';
    public static final String PC_OCR_QUEUE_COMPLETION_NOTIFICATION_DEVELOPER_NAME= 'PC_OcrQueueCompletionNotification';
    //Survey
    public static final String PC_ENGAGEMENT_PROGRAM = PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c');
    public static final String PC_SURVEY_INVITATION = 'SurveyInvitation';
    public static final String PC_SURVEY = 'Survey';
    public static final String PATIENT_CONNECT_SETTING_PAP_SURVEY = 'PC_PAPDefaultSurvey';
    public static final String DEFAULT_PAP_SURVEY = 'pc_defaultpapsurvey';
    public static final String PC_SURVEY_INVITATION_RELATED_OBJECT = PC_Constants.getQualifiedAPIName('PC_SurveyInvitationRelatedObjects__c');
    public static final String PATIENT_CONNECT_SETTING_COPAY_SURVEY = 'PC_CopayDefaultSurvey';
    public static final String DEFAULT_COPAY_SURVEY = 'pc_defaultcopaysurvey';
    public static final String SURVEY_CATEGORY_PAP = 'PAP';
    public static final String SURVEY_CATEGORY_COPAY = 'COPAY';
    public static final String SURVEY_RESPONSE_STATUS_COMPLETED = 'Completed';

    private static String LICENSED_USER = PC_Constants.EMPTY_STRING;
    public static final Boolean IS_LICENSED_USER{
        get
            {
                if(String.isBlank(LICENSED_USER)){
                    Boolean licensedUser = PC_Utility.isLicensedUser();
                    LICENSED_USER = (licensedUser == true) ? 'true' : 'false';
                    return licensedUser;
                }else{
                    return Boolean.valueOf(LICENSED_USER);
                }
            }
	}
}