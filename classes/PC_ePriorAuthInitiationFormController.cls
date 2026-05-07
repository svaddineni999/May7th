/*********************************************************************************************************
Class Name      : PC_ePriorAuthInitiationFormController
Description     : Controller for PC_ePriorAuthInitiationForm
Created By      : Vijay Kashikar
Created Date    : Jan 01, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar              20 June, 2019              Initial Version
Kanteti Kishore             13-Dec-2019                [PC-5795] Reduced parameters for submitPA method
*********************************************************************************************************/
public with sharing class PC_ePriorAuthInitiationFormController {
    @AuraEnabled
    public static PC_ePA.InitiationFormData getData(Id caseId, String overridePrescriptionWithCoverage ) {
        try {
            system.debug('in getData');
            system.debug('overridePrescriptionwithCoverage-->'+overridePrescriptionWithCoverage);
            List<PC_ePA.HealthPlan> healthPlans = PC_ePA.getHealthPlansByCaseId(caseId);
            List<PC_ePA.Prescription> prescriptions = new List<PC_ePA.Prescription>();
            List<PC_ePA.ProgramCoverage> programCoverages = new List<PC_ePA.ProgramCoverage>();

            if(overridePrescriptionWithCoverage == PC_Constants.FALSE_STRING) {
                prescriptions = PC_ePA.getPrescriptionsByCaseId(caseId);
            }

            else if(overridePrescriptionWithCoverage == PC_Constants.TRUE_STRING) {
                programCoverages = PC_ePA.getProgramCoveragesByCaseId(caseId);
            }


            PC_ePA.InitiationFormData formData = new PC_ePA.InitiationFormData();
            formData.healthPlans = healthPlans;
            formData.prescriptions = prescriptions;
            formData.healthPlanLabels = PC_ePA.getHealthPlanLabels();
            formData.prescriptionLabels = PC_ePA.getPrescriptionLabels();
            formData.patient = PC_ePA.getPatientByCaseId(caseId);
            formData.patientLabels = PC_ePA.getPatientLabels();
            formData.searchFormLabels = PC_ePA.getFormLabels();
            formData.programCoverages = programCoverages;
            formData.programCoveragesLabel =PC_ePA.getProgramCoverageLabels();
            system.debug('formData-->'+formData);
            return formData;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    @AuraEnabled
    public static PC_ePA.FormsResponse searchPAForms(Id caseId, Id pbmId, Id productId) {
        system.debug('in getPharmacyBenefitInfo');
        PC_ePA.FormsResponse response = new PC_ePA.FormsResponse();
        try {
            PC_ePA.Client handler = PC_ePA.getClientService();
            system.debug('handler -> ' + handler);
            PC_ePA.FormsRequest formsRequest = handler.createSearchFormsRequest();
            system.debug('formsRequest -> ' + formsRequest);
            PC_ePA.updateFormsRequest(caseId, pbmId, productId, formsRequest);
            system.debug('updated formsRequest -> ' + formsRequest);
            response = handler.searchForms(formsRequest);
            system.debug('search form response - ' + JSON.serialize(response));
            return response;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            //response.errorMessage = ex.getMessage();
        }
        return null;
    }
    @AuraEnabled

    public static PC_ePA.PAResponse submitPA(Map<String,String> ePADetails) {
        try {
            Id caseId = (Id) ePADetails.get('caseId');
            Id pbmId = (Id) ePADetails.get('pbmId');
            Id prescriptionId = (Id) ePADetails.get('prescriptionId');
            Id programCoverageId = (Id) ePADetails.get('programCoverageId');
            String overridePrescriptionWithCoverage = '';
            overridePrescriptionWithCoverage = ePADetails.get('overridePrescriptionWithCoverage');
            String formId = '';
            formId = ePADetails.get('formId');

            PC_ePA.Client handler = PC_ePA.getClientService();
            system.debug('handler -> ' + handler);



            PC_ePA.PARequest request = handler.submitPA();
            PC_ePA.updatePARequest(ePADetails, request);
             system.debug('request -->'+request);
            PC_ePA.PAResponse response = handler.createPA(request);
            system.debug('search form response - ' + response);

            try {
                Case paCase = new Case();
                //paCase.PC_PA_Prescription__c = PC_ePA.getPrescriptionsByCaseId(caseId);
                //Id physicianId = PC_ePA.getPhysicianIdByCaseId(caseId);
                Case programCase = PC_ePA.getCase(caseId);

                //if(!String.isBlank(physicianId)) {
                    paCase.PC_Physician__c = programCase.PC_Physician__c;
                //}
                paCase.PC_Program__c = caseId;
                paCase.PC_PA_Submitted_On__c = Date.today();
                paCase.PC_Health_Plan__c = pbmId;
                paCase.PC_Engagement_Program__c = programCase.PC_Engagement_Program__c;
                paCase.PC_Program_Product__c = programCase.PC_Program_Product__c;

                if( overridePrescriptionWithCoverage ==PC_Constants.TRUE_STRING ) {
                    paCase.PC_Program_Coverage__c = programCoverageId;
                    List<PC_Program_Coverage__c> programCoverages = [Select PC_Prescription__c from PC_Program_Coverage__c where id = :programCoverageId LIMIT 1];
                    if(programCoverages != null && !programCoverages.isEmpty()) {
                        paCase.PC_PA_Prescription__c = programCoverages[0].PC_Prescription__c;
                    }
                }
                else{
                    paCase.PC_PA_Prescription__c = prescriptionId;
                }

                handler.updatePACase(paCase, response);
                PC_Database.ins(paCase);

                response.paCaseId = paCase.Id;
                response.isSuccess = true;
                response.is_ePA_created = true;

                return response;
            }
            catch(Exception ex) {
                response.isSuccess = false;
                String message = 'PA case could not be created. However, the ePA was submitted successfully.';
                if(String.isNotBlank(response.htmlURL)) {
                    response.is_ePA_created = true;
                    message = message;// + ' -> ' + response.htmlURL;
                }
                response.errorMessage = message;
                PC_Utility.publishErrorLog(ex, message + '--> ' + response.htmlURL);
                return response;
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            //response.errorMessage = ex.getMessage();
        }
        return null;
    }

}