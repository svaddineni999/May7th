/**
 * Created by vkashikar on 6/25/2018.
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Chetna Mohapatra          21-Apr-2021                 [PC-7534] Added handleCMMRequest, processCMMRequest method
Haritha Reddy             21-Apr-2021                 [PC-7490] Added methods updateCase, getPACase.
Chetna Mohapatra          05-May-2021                [PC-7721] Added Service Type in Remote Service Log when handling CMM's callback request.
*********************************************************************************/

public with sharing class PC_PriorAuthClient_CMM implements PC_ePA.Client{

    //public static string namedCred = PC_Constants.getQualifiedAPIName(PC_Constants.NAMED_CRED_AUTH_CMM);
    public static final string getForms_URL = '/forms?v=1{queryString}';
    public static final string createPA_URL = '/requests?v=1&api_id={api_id}';
    //public static string getFormById_URL = 'forms/{Id}?v=1&api_id=' + PC_API_ID;

    public PC_ePA.FormsResponse searchForms(PC_ePA.FormsRequest formsRequest) {
        PC_Integration_Settings__c cmmSettings = getCredentials();
        Map<String, String> params = new Map<String, String>();
        params.put('drug_id', formsRequest.product.ndc); //formsRequest.product.ndc
        if(!String.isEmpty(formsRequest.healthPlan.bin)) {
            params.put('q','bin');
            params.put('bin',formsRequest.healthPlan.bin); //formsRequest.healthPlan.bin
        }
        else if(!String.isEmpty(formsRequest.healthPlan.pcn)) {
            params.put('q','pcn');
            params.put('pcn',formsRequest.healthPlan.pcn); //formsRequest.healthPlan.bin
        }
        else {
            PC_Utility.throwAuraHandledException('Cannot continue since PCN or BIN is mandatory');
        }

        params.put('api_id',cmmSettings.username__c);
        params.put('state', formsRequest.healthPlan.state); //formsRequest.healthPlan.state
        PC_PriorAuthClient_CMM.FormsResponse cmmFormsResponse = getFormsHelper(params, cmmSettings);
        return convertFormsResponse(cmmFormsResponse);
        //return getFormsHelper(params);
    }

    public PC_ePA.FormsRequest createSearchFormsRequest() {

        return new PC_ePA.FormsRequest();
    }

    public PC_ePA.PARequest submitPA() {
        return new PC_ePA.PARequest();
    }

    public void updatePACase(Case paCase, PC_ePA.PAResponse paResponse) {
        system.debug('in updatePACase');
        system.debug('printing response received');
        system.debug(paResponse);
        PAResponse response = (PAResponse) paResponse.serviceResponseObject;
        system.debug('after casting');
        system.debug(response);
        paCase.PC_ePA_URL__c = paResponse.htmlURL;
        paCase.PC_ePA_Ext_Id__c = paResponse.ePA_Id;
        paCase.RecordTypeId = PC_SYSTEM.recordTypeId('Case',PC_Constants.CASE_PA_RECORD_TYPE);
        String status = '';
        String outcome = '';
        if(!String.isBlank(response.request.workflow_status) && response.request.workflow_status.toLowerCase() != 'null') {
            status = response.request.workflow_status;
        }
        if(!String.isBlank(response.request.plan_outcome) && response.request.plan_outcome.toLowerCase() != 'null') {
            outcome = response.request.plan_outcome;
        }
        Statuses statuses = new Statuses(status, outcome);

        paCase.PC_PA_Outcome__c = statuses.outcome;
        paCase.PC_PA_Status__c = statuses.status;
        system.debug('printing serviceResponseObject received');
        system.debug(response);
    }

    public static final String PA_STATUS_NEW = 'New';
    public static final String PA_STATUS_PA_REQEUST = 'PA Request';
    public static final String PA_STATUS_PA_RESPONSE = 'PA Response';
    public static final String PA_STATUS_QUESTION_REQUEST = 'Question Request';
    public static final String PA_STATUS_QUESTION_RESPONSE = 'Question Response';
    public static final String PA_STATUS_CANCEL_REQUEST_SENT = 'Cancel Request Sent';
    public static final String PA_STATUS_PROVIDER_CANCEL = 'Provider Cancel';
    public static final String PA_STATUS_ARCHIVED = 'Archived';
    public static final String PA_STATUS_EXPIRED = 'Expired';
    public static final String PA_STATUS_FAILURE = 'Failure';
    public static final String PA_STATUS_SHARED = 'Shared';
    public static final String PA_STATUS_SHARED_OR_ACCESSED_ONLINE = 'Shared \\ Accessed Online';
    public static final String PA_STATUS_SENT_TO_PLAN = 'Sent to Plan';
    public static final String PA_STATUS_APPEALED = 'Appealed';


    public static final String PA_OUTCOME_FAVORABLE = 'Favorable';
    public static final String PA_OUTCOME_UNFAVORABLE = 'Unfavorable';
    public static final String PA_OUTCOME_PENDING = 'Pending';
    public static final String PA_OUTCOME_CANCELLED = 'Cancelled';
    public static final String PA_OUTCOME_UNKNOWN = 'Unknown';
    public static final String PA_OUTCOME_UNSENT = 'Unsent';
    public static final String PA_OUTCOME_NA = 'N/A';
    public static final String PA_OUTCOME_NULL = 'Null';

    public inherited sharing class Statuses {


        public String status;
        public String outcome;
        public Statuses(String pStatus, String pOutcome) {
            String st = String.isBlank(pStatus) ? '' : pStatus.toLowerCase();
            String oc = String.isBlank(pOutcome) ? '' : pOutcome.toLowerCase();
            if(st == PA_STATUS_NEW.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_INITIATED;
            }
            else if(st == PA_STATUS_PA_REQEUST.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_PA_REQEUST_SUBMITTED_TO_PLAN;
            }
            else if (st == PA_STATUS_PA_RESPONSE.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_PLAN_PA_RESPONSE;
                if(oc == PA_OUTCOME_FAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_APPROVED;
                }
                else if(oc == PA_OUTCOME_UNFAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_DENIED;
                }
                else if(oc == PA_OUTCOME_PENDING.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_PENDING;
                }
            }
            else if(st == PA_STATUS_QUESTION_REQUEST.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_QUESTION_REQUEST_SUBMITTED_TO_PLAN;
            }
            else if(st == PA_STATUS_QUESTION_RESPONSE.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_PLAN_QUESTION_RESPONSE;
                if(oc == PA_OUTCOME_FAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_APPROVED;
                }
                else if(oc == PA_OUTCOME_UNFAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_DENIED;
                }
                else if(oc == PA_OUTCOME_NA.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_NA;
                }
                else if(String.isBlank(oc) || oc == PA_OUTCOME_NULL.toLowerCase()) {
                    this.status = PC_Constants.PA_STATUS_PLAN_QUESTION_SET_READY_FOR_PROVIDER;
                }
            }
            else if(st == PA_STATUS_CANCEL_REQUEST_SENT.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_CANCEL_REQUEST_SENT;
            }
            else if(st == PA_STATUS_PROVIDER_CANCEL.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_CANCELLED;
                if(oc == PA_OUTCOME_CANCELLED.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_CANCELLED;
                }
            }
            else if(st == PA_STATUS_ARCHIVED.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_ARCHIVED;
                if(oc == PA_OUTCOME_FAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_APPROVED;
                }
                else if(oc == PA_OUTCOME_UNFAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_DENIED;
                }
                else if(oc == PA_OUTCOME_UNKNOWN.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_UNKNOWN;
                }
                else if(oc == PA_OUTCOME_CANCELLED.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_CANCELLED;
                }
                else if(oc == PA_OUTCOME_UNSENT.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_UNSENT;
                }
            }
            else if(st == PA_STATUS_EXPIRED.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_EXPIRED;
            }
            else if(st == PA_STATUS_FAILURE.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_CANCELLED;
            }
            else if(st == PA_STATUS_SHARED.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_PA_SHARED_WITH_PROVIDER;
            }
            else if(st == PA_STATUS_SHARED_OR_ACCESSED_ONLINE) {
                this.status = PC_Constants.PA_STATUS_PA_ACCESSED_BY_PROVIDER;
            }
            else if(st == PA_STATUS_SENT_TO_PLAN.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_SENT_TO_PLAN;
                if(oc == PA_OUTCOME_FAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_APPROVED;
                }
                else if(oc == PA_OUTCOME_UNFAVORABLE.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_DENIED;
                }
                else if(oc == PA_OUTCOME_PENDING.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_PENDING;
                }
                else if(oc == PA_OUTCOME_UNKNOWN.toLowerCase()) {
                    this.outcome = PC_Constants.PA_OUTCOME_UNKNOWN;
                }
            }
            else if(st == PA_STATUS_APPEALED.toLowerCase()) {
                this.status = PC_Constants.PA_STATUS_APPEALED;
            }
        }

    }
    public PC_ePA.PAResponse CreatePA(PC_ePA.PARequest request) {
        PAResponse response = createPAHelper(request, getCredentials());
        system.debug('CMM response converted to CMM reponse object');
        system.debug(response);

        PC_ePA.PAResponse paResponse = convertCretePAResponse(response);
        system.debug('CMM response converted to ePA reponse object');
        system.debug(paResponse);
        return paResponse;
    }
    public static PC_ePA.PAResponse convertCretePAResponse(PAResponse response) {
        PC_ePA.PAResponse paResponse = new PC_ePA.PAResponse();
        paResponse.isSuccess = false;
        paResponse.serviceResponseObject = (object) response;
        if(response != null && response.request != null) {
            if(response.request.tokens != null && !response.request.tokens.isEmpty() &&
                    response.request.events != null && !response.request.events.isEmpty())
            {
                paResponse.isSuccess = true;
                paResponse.htmlURL = response.request.tokens[0].html_url;
                paResponse.status = response.request.events[0].type;
                paResponse.ePA_Id = response.request.id;
            }
        }
        return paResponse;
    }

    public static PC_ePA.FormsResponse convertFormsResponse(FormsResponse cmmFormsResponse) {
        PC_ePA.FormsResponse formsResponse = new PC_ePA.FormsResponse();
        PC_ePA.Form form;
        List<PC_ePA.Form> forms = new List<PC_ePA.Form>();
        PC_ePA.Payer payer;
        for(Form cmmForm : cmmFormsResponse.forms) {
            form =  new PC_ePA.Form();
            form.name = cmmForm.name;
            form.description = cmmForm.description;
            form.directions = cmmForm.directions;
            form.active = cmmForm.active;
            form.href = cmmForm.href;
            form.is_epa = cmmForm.is_epa;
            form.isEnrollment = cmmForm.is_enrollment;
            form.previewUrl = cmmForm.preview_url;
            form.score = cmmForm.score;
            form.requestFormId = cmmForm.request_form_id;
            form.thumbnailUrl = cmmForm.thumbnail_url;
            form.id = cmmForm.id;

            payer = new PC_ePA.Payer();
            payer.name = cmmForm.contact_name;
            payer.phone = cmmForm.contact_phone;
            payer.fax = cmmForm.contact_fax;
            form.payer = payer;

            forms.add(form);
        }
        formsResponse.forms = forms;
        system.debug('printing formsResponse');
        system.debug(formsResponse);
        return formsResponse;
    }
    private static FormsResponse getFormsHelper(Map<String, String> queryParam, PC_Integration_Settings__c cmmSettings) {
        String queryString = '';
        for(String key : queryParam.keySet()) {
            queryString += '&' + key + '=' + queryParam.get(key);
        }

        //String path = getForms_URL.replace('{queryString}',queryString);
        HttpRequest req = new HttpRequest();
        String url = getForms_URL.replace('{queryString}',queryString);
        req.setEndpoint(cmmSettings.endpoint_Url__c + url);
        req.setMethod('GET');
        req.setTimeout(30000);
        req.setHeader('Accept', 'application/json, text/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cache-Control', 'no-cache');
        //req.setHeader('Authorization', 'Bearer ' + '{' + PC_API_ID + '}' + '+x-no-pass');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug(res.getBody());
        system.debug('status code -> ' + res.getStatusCode());
        if(res.getStatusCode() != 200) {
            String message = Label.PC_ePA_Search_Forms_Fail_Message + ' ';
            try {
                PC_PriorAuthClient_CMM.Errors2 cmmErrors = (PC_PriorAuthClient_CMM.Errors2) JSON.deserialize(res.getBody(), PC_PriorAuthClient_CMM.Errors2.class);
                for (Error err : cmmErrors.errors) {
                    message += err.message + '. ';
                }
            }
            catch(Exception ex) {
                PC_Utility.publishErrorLog(ex, 'Needs attention! Received a different format of errors from CMM');
            }
            PC_Utility.throwAuraHandledException(message);
        }
        system.debug('CMM request -- ');
        system.debug(req);
        system.debug('CMM Response body -- ');

        //FormsResponse pcFormsResponse = new FormsResponse();
        FormsResponse pcFormsResponse1 = (FormsResponse) System.JSON.deserialize(res.getBody(), FormsResponse.class);
        system.debug('pcFormsResponse -> ' + pcFormsResponse1);
        return pcFormsResponse1;
    }

    private static PAResponse createPAHelper(PC_ePA.PARequest paRequest, PC_Integration_Settings__c cmmSettings) {
        system.debug('pa request received');
        system.debug(paRequest);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cmmSettings.endpoint_Url__c + createPA_URL.replace('{api_id}',cmmSettings.username__c));
        req.setMethod('POST');
        req.setTimeout(30000);
        req.setHeader('Accept', 'application/json, text/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cache-Control', 'no-cache');


        Blob authBearerTokenBlob = Blob.valueOf(cmmSettings.username__c + ':x-no-pass');
        String authBearerToken = EncodingUtil.base64Encode(authBearerTokenBlob);
        //req.setHeader('Authorization', 'Bearer ' + authBearerToken);
        //req.setHeader('api_id', PC_API_ID);
        req.setHeader('Authorization', 'Bearer '+ cmmSettings.username__c + '+x-no-pass');

        //req.setHeader('Authorization', 'Bearer ' + authBearerToken);

        PARequest request = new PARequest();
        request.patient.first_name = paRequest.patient.firstName;
        request.patient.last_name = paRequest.patient.lastName;
        request.patient.date_of_birth = paRequest.patient.birthDate.month() + '/' +
                paRequest.patient.birthDate.day() + '/' + paRequest.patient.birthDate.year();
        request.patient.phone_number = paRequest.patient.phone;
        request.patient.email = paRequest.patient.email;
        request.patient.pbm_member_id = paRequest.patient.pbmMemberId;

        if(paRequest.patient.gender == PC_Constants.PATIENT_MALE) {
            request.patient.gender = 'M';
        }
        else if(paRequest.patient.gender == PC_Constants.PATIENT_FEMALE) {
            request.patient.gender = 'F';
        }

        if(paRequest.patient.address != null) {
            Address address = new Address();
            address.city = paRequest.patient.address.city;
            address.state = paRequest.patient.address.state;
            address.zip = paRequest.patient.address.postalCode;
            address.street_1 = paRequest.patient.address.addressOne;
            address.street_2 = paRequest.patient.address.addressTwo;
            request.patient.address = address;
        }

        Prescription pre = new Prescription();
        request.prescription.drug_id = paRequest.drug.ndc;

        request.prescription.frequency = paRequest.prescription.frequency;


        if(paRequest.prescription.daysSupply != null) {
            request.prescription.days_supply = String.valueOf(paRequest.prescription.daysSupply);
        }
        if(paRequest.prescription.requestedQuantity !=null) {
            request.prescription.quantity = String.valueOf(paRequest.prescription.requestedQuantity);

        }
        if(paRequest.prescription.refills != null) {
            request.prescription.refills = String.valueOf(paRequest.prescription.refills);
        }
        request.prescription.name  = paRequest.prescription.product.name;
        request.prescription.ndc = paRequest.prescription.product.ndc;
        request.prescription.quantity_unit_of_measure = paRequest.prescription.product.quantityUnitOfMeasure;



        request.state = paRequest.patient.state;
        request.formId = paRequest.formId;

        Payer payer = new Payer();
        payer.bin = paRequest.payer.bin;
        payer.pcn = paRequest.payer.pcn;
        payer.group_id = paRequest.payer.groupId;
        payer.drug_benefit_name = paRequest.payer.drugBenefitName;
        //payer.medical_benefit_name = paRequest.payer.medicalBenefitName;

        request.payer = payer;

        Prescriber prescriber = new Prescriber();

        //prescriber.name = paRequest.prescriber.name;
        if(paRequest.prescriber != null) {
            prescriber.first_name = paRequest.prescriber.firstName;
            prescriber.last_name = paRequest.prescriber.lastName;
            prescriber.npi = paRequest.prescriber.npi;
            prescriber.ncpdpid = '';
            prescriber.phone_number = paRequest.prescriber.phone;
            prescriber.fax_number = paRequest.prescriber.fax;
            Address presciberAddress = new Address();
            if (paRequest.prescriber.address != null) {
                presciberAddress.street_1 = paRequest.prescriber.address.addressOne;
                presciberAddress.street_2 = paRequest.prescriber.address.addressTwo;
                presciberAddress.state = paRequest.prescriber.address.state;
                presciberAddress.city = paRequest.prescriber.address.city;
                presciberAddress.zip = paRequest.prescriber.address.postalCode;
            }
            prescriber.address = presciberAddress;
        }

        request.prescriber = prescriber;

        system.debug('vj -> request object -> ' + request);
        Map<String, Object> body = new Map<String, Object>();
        body.put('request',request);

        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('CMM request -- ');
        system.debug(req);
        system.debug('CMM Request body -- ');
        system.debug(req.getBody());
        system.debug('status code -> ' + res.getStatusCode());
        system.debug('CMM Response body -- ');
        system.debug(res.getBody());

        if(res.getStatusCode() != 201) {
            String message = Label.PC_ePA_Create_PA_Fail_Message;

            try {
                PC_PriorAuthClient_CMM.Errors cmmErrors = (PC_PriorAuthClient_CMM.Errors) JSON.deserialize(res.getBody(), PC_PriorAuthClient_CMM.Errors.class);
                for (String err : cmmErrors.errors) {
                    message += err + '. ';
                }
            }
            catch(Exception ex) {
                PC_Utility.publishErrorLog(ex, 'Needs attention! Received a different format of errors from CMM');
            }
            PC_Utility.throwAuraHandledException(message);
        }
        PAResponse response = (PAResponse) System.JSON.deserialize(res.getBody(), PAResponse.class);
        return response;
    }

    public static PC_Integration_Settings__c getCredentials() {
        PC_Integration_Settings__c cmmSettings = PC_Integration_Settings__c.getValues(PC_Constants.CMM_CREDENTIALS);
        if(cmmSettings == null) {
            PC_Utility.throwAuraHandledException('Custom Setting not found for CMM');
        }
        return cmmSettings;
    }

    public static void handleCMMRequest(String requestBody, String requestURL, String cmmServiceName) {
        String serviceType= PC_Constants.REMOTE_SERVICE_TYPE_INBOUND;
        PC_Remote_Service_Log__c record = PC_RemoteServiceLogHandler.createRemoteServiceLog(cmmServiceName, requestURL, requestBody, '', '',serviceType);
        PC_RemoteServiceLogHandler.publishRemoteServiceLogInfo(record);
    }

    public static void processCMMRequest(String callbackRequest,PC_Remote_Service_Log_Info__e sc ){
        Case c = new Case();
        if (String.isNotBlank(callbackRequest)) {
            //PC_RemoteServiceLogHandler.updateCase(callbackResponse); // is it bulkified?
            system.debug('scallback');
            system.debug(JSON.serialize(sc));
            updateCase(callbackRequest);
        }
    }

    public static Case updateCase(String reqString) {
        if(String.isNotBlank(reqString)) {
            PC_PriorAuthClient_CMM.PAResponse paResponse = (PC_PriorAuthClient_CMM.PAResponse) JSON.deserialize(reqString, PC_PriorAuthClient_CMM.PAResponse.class);
            String paId = paResponse.request.id;
            Case paCase = getPACase(paId);
            String status = PC_Constants.EMPTY_STRING;
            String outcome = PC_Constants.EMPTY_STRING;
            if(paCase != null) {
                if (!String.isBlank(paResponse.request.workflow_status) && paResponse.request.workflow_status.toLowerCase() != PC_Constants.NULL_STRING) {
                    status = paResponse.request.workflow_status;
                    system.debug('cmm status = ' + status);
                }
                if (!String.isBlank(paResponse.request.plan_outcome) && paResponse.request.plan_outcome.toLowerCase() != PC_Constants.NULL_STRING) {
                    outcome = paResponse.request.plan_outcome;
                    system.debug('cmm outcome = ' + outcome);
                }
                PC_PriorAuthClient_CMM.Statuses statuses = new PC_PriorAuthClient_CMM.Statuses(status, outcome);

                paCase.PC_PA_Outcome__c = statuses.outcome;
                paCase.PC_PA_Status__c = statuses.status;
                PC_Database.upd(paCase,true);
                return paCase;
            }
        }
        return null;
    }

    private static Case getPACase(String paId) {
        List<Case> cases = [SELECT Id FROM Case WHERE PC_ePA_Ext_Id__c=:paId];
        if(cases != null && !cases.isEmpty()) {
            return cases[0];
        }
        return null;
    }
    public inherited sharing class FormsResponse{
        public Form[] forms;

        /*public static FormsResponse parse(String json){
            return (FormsResponse) System.JSON.deserialize(json, FormsResponse.class);
        }

        static testMethod void testParse() {
            String json=		'{"forms":[{"id":31622,"href":"https://master-api.integration.covermymeds.com/forms/31622","name":"express_scripts_general_1","description":"Express Scripts General Request Form","directions":"Prior Authorization Form for General Medication Requests. This form can be used for Medicare and non-Medicare requests (Use for Members with an Express Scripts logo on their ID card)","request_form_id":"express_scripts_general_1_31622","thumbnail_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/90/express_scripts_general_1_31622.jpg","preview_url":"https://master-api.integration.covermymeds.com/forms/pdf/thumbs/270/express_scripts_general_1_31622.jpg","is_epa":false,"contact_name":"Express Scripts","contact_phone":"(800) 417-8164","contact_fax":"(800) 357-9577","score":14.0,"active":true,"is_enrollment":false}]}';
            fromJSON obj = parse(json);
            System.assert(obj != null);
        }*/
    }
    /**
    * Provides properties to hold errors
    */
    public inherited sharing class Errors {
        public List<String> errors;
    }
    /**
    * Provides properties to hold errors
    */
    public inherited sharing class Errors2 {
        public List<Error> errors;
    }
    /**
    * Provides properties to hold errors
    */
    public inherited sharing class Error {
        public String code;
        public String message;
        public String debug;
    }
    /**
    * Provides properties to hold patient info
    */
    public inherited sharing class Patient{
        /**
        * Property to hold first name
        */
        public string first_name;
        /**
        * Property to hold last name
        */
        public string last_name;
        /**
        * Property to hold gender
        */
        //@AuraEnabled public string gender;
        /**
        * Property to hold birthdate
        */
        public String date_of_birth;
        /**
        * Property to hold address
        */
        public Address address;
        /**
        * Property to hold member_id
        */
        public string member_id;
        /**
        * Property to hold member_id
        */
        public string pbm_member_id;
        /**
        * Property to hold member_id
        */
        public string phone_number;
        /**
        * Property to hold member_id
        */
        public string email;
        /**
        * Property to hold member_id
        */
        public string gender;


    }
    /**
    * Provides properties to hold patient info
    */
    public inherited sharing class Address {
        /**
        * Property to hold street 1 address
        */
        public string street_1;
        /**
        * Property to hold street 2 address
        */
        public string street_2;
        /**
        * Property to hold city address
        */
        public string city;
        /**
        * Property to hold street 1 address
        */
        public string state;
        /**
        * Property to hold zip
        */
        public string zip;

    }
    /**
    * Provides properties to hold Prescriber
    */
    public inherited sharing class Prescriber {
        /**
        * Property to hold Salesforce ID
        */
        public string id;
        /**
        * Property to hold name
        */
        public string name;
        /**
        * Property to hold first name
        */
        public string first_name;
        /**
        * Property to hold last name
        */
        public string last_name;
        /**
        * Property to hold name NCPDP
        */
        public string ncpdpid;
        /**
        * Property to hold NPI
        */
        public string npi;
        /**
        * Property to hold phone number
        */
        public string phone_number;
        /**
        * Property to hold fax number
        */
        public string fax_number;
        /**
         * Property to hold address
         */
        public Address address;
    }
    /**
    * Provides properties to hold PAYER info
    */
    public inherited sharing class Payer{
        /**
        * Property to hold BIN
        */
        @AuraEnabled public string bin;
        /**
        * Property to hold PCN
        */
        @AuraEnabled public string pcn;
        /**
        * Property to hold group id
        */
        @AuraEnabled public string group_id;
        /**
        * Property to hold benefitiary name
        */
        @AuraEnabled public String medical_benefit_name;
        /**
        * Property to hold state
        */
        @AuraEnabled public string drug_benefit_name;
    }
    /**
    * Provides properties to hold prescription details
    */
    public inherited sharing class Prescription{
        public string drug_id;
        public string frequency ;
        public string days_supply ;
        public string quantity ;
        public string refills;
        public string strength;
        public string name;
        public string ndc;
        public string quantity_unit_of_measure;


    }
    public inherited sharing class PARequest {
        public Patient patient;
        public Prescription prescription;
        public String state;
        public String formId;
        public List<Tokens> tokens;
        public List<Events> events;
        public String workflow_status;
        public String plan_outcome;
        public String id;
        public Payer payer;
        public Prescriber prescriber;

        public PARequest() {
            patient = new Patient();
            prescription = new Prescription();
            tokens = new List<Tokens>();
            events = new List<Events>();
            prescriber = new Prescriber();
        }
    }
    public inherited sharing class PAResponse {
        public PARequest request;
    }
    inherited sharing class Tokens {
        public String id;	//gjvs8pfo653o8k8p4xiu
        public String request_id;	//L9M4V3
        public String href;	//https://master-api.integration.covermymeds.com/requests/tokens/gjvs8pfo653o8k8p4xiu
        public String html_url;	//https://master-cmm.integration.covermymeds.com/request/view/L9M4V3?token_id=gjvs8pfo653o8k8p4xiu
        public String pdf_url;	//https://master-cmm.integration.covermymeds.com/request/send/L9M4V3?token_id=gjvs8pfo653o8k8p4xiu
        public String thumbnail_url;	//https://master-api.integration.covermymeds.com/forms/pdf/thumbs/200/model_form_1.jpg
    }
    inherited sharing class Events {
        //public String time;	//2018-06-29T03:51:41Z
        public String type;	//REQUEST_CREATED
        //public cls_remote_user remote_user;
        //public cls_subtype subtype;
    }
    public inherited sharing class Form {
        public Integer id;	//31622
        public String href;	//https://master-api.integration.covermymeds.com/forms/31622
        public String name;	//express_scripts_general_1
        public String description;	//Express Scripts General Request Form
        public String directions;	//Prior Authorization Form for General Medication Requests. This form can be used for Medicare and non-Medicare requests (Use for Members with an Express Scripts logo on their ID card)
        public String request_form_id;	//express_scripts_general_1_31622
        public String thumbnail_url;	//https://master-api.integration.covermymeds.com/forms/pdf/thumbs/90/express_scripts_general_1_31622.jpg
        public String preview_url;	//https://master-api.integration.covermymeds.com/forms/pdf/thumbs/270/express_scripts_general_1_31622.jpg
        public boolean is_epa;
        public String contact_name;	//Express Scripts
        public String contact_phone;	//(800) 417-8164
        public String contact_fax;	//(800) 357-9577
        public Decimal score;	//14
        public boolean active;
        public boolean is_enrollment;
    }
}