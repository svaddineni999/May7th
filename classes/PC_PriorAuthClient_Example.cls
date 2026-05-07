/**
 * Created by vkashikar on 7/22/2022.
 */

/**
 * Demonstrates a mock ePA service class. Implements PatientConnect.PC_ePA.Client.
 */
public with sharing class PC_PriorAuthClient_Example implements PC_ePA.Client {
    public static string imageURL = URL.getOrgDomainUrl().toExternalForm() + '/resource/' + PC_Constants.getQualifiedAPIName('PC_Resources') + '/PC_Resources/Images/StatusIndicatorIcons/PC_Adherence_Orange.jpg';
    public static string destinationURL = 'https://example.com';
    /**
     * Implements searchForms method of PC_ePA.Client.
     * Use this to search for ePA forms specific to the chosen Health Plan details and prescription/drug.
     * @param formsRequest has details about the health plan and prescription/drug.
     *
     * @return PC_ePA.FormsResponse having a collection of forms response.
     */
    public PC_ePA.FormsResponse searchForms(PC_ePA.FormsRequest formsRequest) {
        system.debug(formsRequest.healthPlan); // Has the selected health plan details.
        system.debug(formsRequest.product); // Has the selected product details.
        PC_ePA.FormsResponse formsResponse = new PC_ePA.FormsResponse();
        List<PC_ePA.Form> forms = new List<PC_ePA.Form>();
        PC_ePA.Form form = new PC_ePA.Form();
        form.id = 1234;
        form.href = URL.getOrgDomainUrl() + PC_Constants.getQualifiedAPIName('PC_Resources') + '/PC_Resources/Images/MapImages/arrow.png';
        form.name = 'Express Scripts General 1';
        form.description= 'Express Scripts General Request Form';
        form.directions = 'Prior Authorization Form for General Medication Requests. This form can be used for Medicare and non-Medicare requests (Use for Members with an Express Scripts logo on their ID card)';
        form.requestFormId = 'express_scripts_general_1_31622';
        form.thumbnailUrl = imageURL;
        form.previewUrl = imageURL;
        form.is_epa = true;
        form.payer = new PC_ePA.Payer();
        form.payer.phone = '+12345';
        form.payer.fax = '+2345678';
        form.score = 12.0;
        form.active = true;
        form.isEnrollment = false;
        forms.add(form);
        formsResponse.forms = forms;
        return formsResponse;
    }
    /**
     * Implements createSearchFormsRequest of PC_ePA.Client.
     * Used to initialize the search forms request values.
     * @return PC_ePA.FormsRequest having details about the health plan and drug.
     */
    public PC_ePA.FormsRequest createSearchFormsRequest() {
        return new PC_ePA.FormsRequest();
    }

    /**
     * Implements submitPA of PC_ePA.Client.
     * Create the necessary create PA form request
     * @return PC_ePA.PARequest - which holds properties necessary to create a PA request like patient, drug, payer,
     * prescriber, prescription
     */
    public PC_ePA.PARequest submitPA() {
        return new PC_ePA.PARequest();
    }

    /**
     * Used to update the PA case before saving.
     *
     * @param paCase PA case to be updated before saving.
     * @param paResponse Necessary ePA vendor response that can be used to update paCase
     */
    public void updatePACase(Case paCase, PC_ePA.PAResponse paResponse) {
        system.debug(paResponse);
        //PAResponse response = (PAResponse) paResponse.serviceResponseObject;
        //system.debug('after casting');
        //system.debug(response);
        paCase.PC_ePA_URL__c = paResponse.htmlURL;
        paCase.PC_ePA_Ext_Id__c = paResponse.ePA_Id;
        paCase.RecordTypeId = PC_SYSTEM.recordTypeId('Case',PC_Constants.CASE_PA_RECORD_TYPE);

        paCase.PC_PA_Outcome__c = PC_Constants.PA_OUTCOME_PENDING;
        paCase.PC_PA_Status__c = PC_Constants.PA_STATUS_SENT_TO_PLAN;
    }

    /**
     * Implements CreatePA of PC_ePA.Client
     * Used to create a PA request at an ePA service provider
     * @param request PC_ePA.PARequest - holds details necessary to submit a request
     *
     * @return ePA service provider response.
     */
    public PC_ePA.PAResponse CreatePA(PC_ePA.PARequest request) {
        system.debug('Request.payer = ' + request.payer);
        system.debug('Request.patient = ' + request.patient);
        system.debug('Request.prescription = ' + request.prescription);
        system.debug('Request.drug = ' + request.drug);
        system.debug('Request.formId = ' + request.formId);
        system.debug('Request.prescriber = ' + request.prescriber);
        // Use the above values to place the PA request at the ePA service provider.
        PC_ePA.PAResponse response = new PC_ePA.PAResponse();
        response.isSuccess = true;
        response.ePA_Id = '1234';
        response.errorMessage = '';
        response.htmlURL = destinationURL;
        response.is_ePA_created = true;
        response.status = 'Initiated';
        response.serviceResponseObject = NULL; //set the JSON object so that you can use it in updatePA to set the values
        return response;
    }

}