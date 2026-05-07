/*************************************************************************************************************************************
Class Name      : ACLS_eBVPharmacy_IntegrationHandler
Description     : Implementation class for PC_PharmacyEbenefitsLookupController.cmp
Created By      : Deloitte
Created Date    : April 07, 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Ronak Bansal         		  April 07,2023           Initial Version
****************************************************************************************************************************************************/

public with sharing class ACLS_eBVPharmacy_IntegrationHandler implements PC_eBenefits.PharmacyBenefits2{
    @testvisible private static HttpResponse res;
    public static final String CLASSNAME = 'ACLS_eBVPharmacy_IntegrationHandler';
    public static final String METHODNAME = 'lookupPharmacyBenefits';
    public static final String PERSONCODE = 'PersonCode';
    public static final String RELATIONSHIPCODE = 'relationshipCode';
    public static final String GROUPNO = 'GroupNo';

    /********************************************************************************************************************
    Method Name    : createPharmacyBenefitsRequest
    Description    : returns a non parameterized constructor
    Return Type    : PC_eBenefits.PharmacyBenefitsRequest
    Parameter      : none
    *********************************************************************************************************************/
    public PC_eBenefits.PharmacyBenefitsRequest createPharmacyBenefitsRequest() {
        return new PC_eBenefits.PharmacyBenefitsRequest();
    }

    /********************************************************************************************************************
    Method Name    : lookupPharmacyBenefits
    Description    : perform callout to get the pharmacy eBV response results.
    Return Type    : PC_eBenefits.PharmacyBenefitsResponse
    Parameter      : PC_eBenefits.PharmacyBenefitsRequest
    *********************************************************************************************************************/
    
    public PC_eBenefits.PharmacyBenefitsResponse lookupPharmacyBenefits(PC_eBenefits.PharmacyBenefitsRequest request) {
        PC_eBenefits.PharmacyBenefitsResponse benefitDetails = new PC_eBenefits.PharmacyBenefitsResponse();
        PC_Remote_Service_Log__c eBVPharmacyRSL = new PC_Remote_Service_Log__c();
        try {
            ACLS_IntegrationConfig__mdt eBVPharmacyDetails = ACLS_Utility.getIntegrationConfigs(ACLS_Constants.RISRX_PHARMACY, ACLS_Utility.getCurrentEnvironment());
            //List<ACLS_IntegrationConfig__mdt> eBVPharmacyDetails = new List<ACLS_IntegrationConfig__mdt>([Select Id,ACLS_IntegrationName__c,ACLS_Integration_Procedure_Name__c,ACLS_Environment__c,ACLS_BaseURL__c,ACLS_Endpoint__c,ACLS_APIKey__c,ACLS_Headers__c,ACLS_Timeout__c from ACLS_IntegrationConfig__mdt Where ACLS_IntegrationName__c =: ACLS_Constants.EBV_PHARMACY_DETAILS and ACLS_Environment__c =: ACLS_Utility.getCurrentEnvironment()]);
            PC_Health_Plan__c selectedHealthPlan = [Select id, PC_Rx_Bin__c, PC_Rx_PCN__c, PC_Rx_Grp__c, Group_No__c, PC_PBMMember_Id__c FROM PC_Health_Plan__c where id =:request.healthPlanId];

            //Validate Request
            validateeBVRequest(request, selectedHealthPlan);

            //Prepare Request
            String eBVRequestBody = geteBVRequestBody(request, selectedHealthPlan);

            if(eBVPharmacyDetails!= null){

                Map<String, String> mapHeader = (Map<String,String>) JSON.deserialize(eBVPharmacyDetails.ACLS_Headers__c, Map<String,String>.class); 
                
                //Perform Callout
                //HttpResponse res = ACLS_Http_RequestResponse_Util.handleHTTPCallouts(ACLS_Constants.METHOD_POST, mapHeader, eBVPharmacyDetails[0].ACLS_BaseURL__c+eBVPharmacyDetails[0].ACLS_Endpoint__c, eBVRequestBody, Integer.valueOf(eBVPharmacyDetails[0].ACLS_Timeout__c), null);
                //HttpResponse res = new HttpResponse();
                            if(!Test.isRunningTest()) {
                             res = ACLS_IP_Callouts_Utility.makeCalloutFromIP(eBVPharmacyDetails.ACLS_BaseURL__c+eBVPharmacyDetails.ACLS_Endpoint__c,eBVRequestBody,mapHeader,null, 120000,eBVPharmacyDetails.ACLS_Integration_Procedure_Name__c);
                             //System.debug('res '+res);
                            }
                //Create remote service log record
                createRemoteServiceLog(eBVRequestBody, eBVPharmacyDetails.ACLS_BaseURL__c+eBVPharmacyDetails.ACLS_Endpoint__c, res);
                if(res!=null && res.getStatusCode() == 200){
                    System.debug('Success Response Get bOdy --- '+res.getBody());
                    ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper responseBody = (ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper)JSON.deserialize(res.getBody(),ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper.class);
                    benefitDetails = geteBVResponseBody(responseBody, benefitDetails);
                }
                else{
                    //Create exception task
                    Task exceptionTask = ACLS_Utility.createTask(ACLS_Constants.EBV + ' : ' +ACLS_Constants.EXCEPTION_OCCURRED, ACLS_Constants.INTEGRATION, ACLS_Constants.EBV, DATE.today(), ACLS_Constants.ACLS_ADMIN_QUEUE, request.caseId, 'Error occurred while performing Pharmacy eBV.Failed to get the Coverage Investigation Results');
                    insert exceptionTask;

                    //Create error log and throw exception
                    ACLS_Utility.createINTErrorLogs(null, Label.ACLS_eBV_Error, '', 'Response received is null \n', '', CLASSNAME, METHODNAME, request.caseId);
                    throweBenefitsException(Label.ACLS_eBV_Error);
                }
            }
            else{
                //Create error log and throw exception
                ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.EBV_PHARMACY_ERRORLOG1, '', ACLS_Constants.EBV_PHARMACY_ERRORLOG2 + '\n', '', CLASSNAME, METHODNAME, request.caseId);
                throweBenefitsException(Label.ACLS_eBV_Error);
            }
            return benefitDetails;
        }
        catch (exception ex){
            //ACLS_Utility.createINTErrorLogs(ex, '', '', Label.ACLS_eBV_Error, '', CLASSNAME, METHODNAME, request.caseId);
            benefitDetails.isSuccess = false;
            benefitDetails.errorMessage = ex.getMessage();
            benefitDetails.eBenefitsServiceResponse = null;
            return benefitDetails;
        }
    }

    /********************************************************************************************************************
    Method Name    : validateeBVRequest
    Description    : validate if all the required attributes in the request body is present or not
    Return Type    : void
    Parameter      : PC_eBenefits.PharmacyBenefitsRequest request, PC_Health_Plan__c selectedHealthPlan
    *********************************************************************************************************************/
    public static void validateeBVRequest(PC_eBenefits.PharmacyBenefitsRequest request, PC_Health_Plan__c selectedHealthPlan){
        if(selectedHealthPlan.PC_Rx_Bin__c == null || selectedHealthPlan.PC_Rx_PCN__c == null || 
            selectedHealthPlan.Group_No__c == null || selectedHealthPlan.PC_PBMMember_Id__c == null){
                throweBenefitsException(Label.ACLS_PharmaCardLookup_Missing_HealthPlanInfo);
        }
    }

    /********************************************************************************************************************
    Method Name    : geteBVRequestBody
    Description    : prepare the request body to perform pharmacy eBV callout
    Return Type    : String
    Parameter      : PC_eBenefits.PharmacyBenefitsRequest request, PC_Health_Plan__c selectedHealthPlan
    *********************************************************************************************************************/
    public static String geteBVRequestBody(PC_eBenefits.PharmacyBenefitsRequest request, PC_Health_Plan__c selectedHealthPlan){

        Case currentCase = [Select Id, Account.Name, Account.ACLS_Unique_Id__c, Account.PC_Date_of_Birth__c From Case where id=:request.caseId];
        String personCode = ACLS_KeyValMapperUtil.getValue(PERSONCODE, ACLS_Constants.KEYVAL_TYPE_INTEGDEFAULTS);
        String relationshipCode = ACLS_KeyValMapperUtil.getValue(RELATIONSHIPCODE, ACLS_Constants.KEYVAL_TYPE_INTEGDEFAULTS);
        Date birthDate = currentCase.Account?.PC_Date_of_Birth__c;
        String formattedBirthDate = String.valueOf(date.newinstance(birthDate.year(), birthDate.month(), birthDate.day()));
        
        ACLS_eBVPharmacy_IntegrationWrapper.eBV_RequestWrapper ebvRequestWrapper = new ACLS_eBVPharmacy_IntegrationWrapper.eBV_RequestWrapper(
            new ACLS_eBVPharmacy_IntegrationWrapper.PatientInfo(currentCase.Account.ACLS_Unique_Id__c, request.patient.firstName, request.patient.lastName, formattedBirthDate, request.patient.gender, request.patient.address.postalCode, relationshipCode),
            new ACLS_eBVPharmacy_IntegrationWrapper.HealthPlanInfo(selectedHealthPlan.PC_Rx_Bin__c, selectedHealthPlan.PC_Rx_PCN__c, selectedHealthPlan.Group_No__c, selectedHealthPlan.PC_PBMMember_Id__c, personCode),
            new ACLS_eBVPharmacy_IntegrationWrapper.DrugInfo(request.drug.ndc, null, Double.valueOf(request.prescription.requestedQuantity), Integer.valueOf(request.prescription.daysSupply)),
            new ACLS_eBVPharmacy_IntegrationWrapper.ProviderInfo(request.physician.npi)
        );

        String eBVRequestBody = JSON.serialize(ebvRequestWrapper);
        eBVRequestBody = eBVRequestBody.replace(GROUPNO, 'Group');

        return eBVRequestBody;
    }

    /********************************************************************************************************************
    Method Name    : geteBVResponseBody
    Description    : parse the response body from pharmacy eBV callout
    Return Type    : PC_eBenefits.PharmacyBenefitsResponse
    Parameter      : String letterId,Id caseRecordId,Id engagementProgramId,List<PC_eLetter_Recipient> eLetterRecipients
    *********************************************************************************************************************/
    public static PC_eBenefits.PharmacyBenefitsResponse geteBVResponseBody(ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper responseBody, PC_eBenefits.PharmacyBenefitsResponse benefitDetails){

        PC_eBenefits.PharmacyEbenefitsServiceResponse pcResponse = new PC_eBenefits.PharmacyEbenefitsServiceResponse();
        PC_eBenefits.accumulators pcAccumulators = new PC_eBenefits.accumulators();
        PC_eBenefits.coverageAlerts pcCoverageAlert = new PC_eBenefits.coverageAlerts();

        PC_eBenefits.outOfPocket pcOutOfPocket = new PC_eBenefits.outOfPocket();
        pcOutOfPocket.individual = new PC_eBenefits.individual();
        pcAccumulators.outOfPocket = pcOutOfPocket;
        
        PC_eBenefits.deductible pcDeductible = new PC_eBenefits.deductible();
        pcDeductible.individual = new PC_eBenefits.individual();
        pcAccumulators.deductible = pcDeductible;
        
        pcResponse.accumulators = pcAccumulators;
        pcResponse.priorAuthorization = new PC_eBenefits.PriorAuthorization();
        pcResponse.pricing = new PC_eBenefits.pricing();

        pcResponse.coverageAlerts = new List<PC_eBenefits.coverageAlerts>();
        benefitDetails.eBenefitsServiceResponse = pcResponse;

        if(responseBody == null) {
            benefitDetails.eBenefitsServiceResponse = null;
            benefitDetails.isSuccess=false;
        }
        else{
            if(!responseBody.coveragePreferredResult?.isEmpty()){

                benefitDetails.eBenefitsServiceResponse.accumulators.deductible.individual.remainingInDollarCurrency = ACLS_Utility.checkCurrencyValue(responseBody.coveragePreferredResult[0].accumulatorAccrual?.remainingDeductibleAmount);
                benefitDetails.eBenefitsServiceResponse.accumulators.deductible.individual.appliedInDollarCurrency = ACLS_Utility.checkCurrencyValue(responseBody.coveragePreferredResult[0].accumulatorAccrual?.amountAppliedToPeriodicDeductible);
                benefitDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.remainingInDollarCurrency = ACLS_Utility.checkCurrencyValue(responseBody.coveragePreferredResult[0].accumulatorAccrual?.OOPRemaining);
                benefitDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.appliedInDollarCurrency = ACLS_Utility.checkCurrencyValue(responseBody.coveragePreferredResult[0].accumulatorAccrual?.OOPMax);
                benefitDetails.eBenefitsServiceResponse.pricing.patientInDollarFormat = ACLS_Utility.checkCurrencyValue(responseBody.coveragePreferredResult[0].patientPayAmount);
                benefitDetails.eBenefitsServiceResponse.priorAuthorization.isRequired = responseBody.coveragePreferredResult[0].isPARequired;

                pcCoverageAlert.description = ACLS_KeyValMapperUtil.getValue(responseBody.coveragePreferredResult[0].scenarioId, ACLS_Constants.KEYVAL_TYPE_VALTRANSFORM);
                benefitDetails.eBenefitsServiceResponse.coverageAlerts = new List<PC_eBenefits.coverageAlerts>{pcCoverageAlert};

            }
            benefitDetails.eBenefitsServiceResponse.serviceResponse = JSON.serialize(responseBody);
        }
        return benefitDetails;
    }

    /********************************************************************************************************************
    Method Name    : covertToCurrencyFormat
    Description    : Converts a decimal to Currency format
    Return Type    : String
    Parameter      : Decimal amount
    *********************************************************************************************************************/
    @TestVisible
    private static String covertToCurrencyFormat(Decimal amount) {
        if(amount != null) {
            Decimal rA = amount;
            List<String> args = new String[]{PC_Constants.PC_ZERO,'number','###,###,##0.00'};
            String s = String.format(rA.format(), args);
            String strFormattedCurrency = '$ ' + s;
            return strFormattedCurrency;
        }
        else {
            return null;
        }
    }

    /********************************************************************************************************************
    Method Name    : updateProgramCoverage
    Description    : Populate the api response value into the coverage instance
    Return Type    : void
    Parameter      : PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, PC_Program_Coverage__c programCoverage
    *********************************************************************************************************************/
    public void updateProgramCoverage(PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, PC_Program_Coverage__c programCoverage) {

        ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper responseBody = (ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper) JSON.deserialize(pharmacyBenefitsDetails.eBenefitsServiceResponse.serviceResponse, ACLS_eBVPharmacy_IntegrationWrapper.eBV_ResponseWrapper.class);

        PC_eBenefits_Utility.updatePharmacyProgramCoverage(programCoverage, pharmacyBenefitsDetails);

        programCoverage.ACLS_Coverage_Source__c                 = ACLS_Constants.COV_SOURCE_AUTOMATED;
        programCoverage.ACLS_eBV_Transaction_Unique_ID__c       = responseBody?.transId;
        programCoverage.ACLS_eBV_Coverage_Status__c             = (!(pharmacyBenefitsDetails?.eBenefitsServiceResponse?.coverageAlerts.isEmpty()))? pharmacyBenefitsDetails?.eBenefitsServiceResponse?.coverageAlerts[0].description : null;

        if(responseBody!=null && !(responseBody.coveragePreferredResult.isEmpty())){
            programCoverage.PC_CoordinatedPlanBenefits__c           = (responseBody.coveragePreferredResult[0].CoB == true)? 'Yes' : (responseBody.coveragePreferredResult[0].CoB == false)? 'No' : null;
            programCoverage.PC_Coverage_Type__c                     = ACLS_KeyValMapperUtil.getValue(responseBody.coveragePreferredResult[0].planType, ACLS_Constants.KEYVAL_TYPE_VALTRANSFORM);
            programCoverage.PC_Program_Coverage__c                  = responseBody.coveragePreferredResult[0].coverageStatus;
            programCoverage.PC_Rx_Pay_Amt__c                        = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].patientPayAmount);
            programCoverage.ACLS_eBV_Additional_Information__c      = responseBody.coveragePreferredResult[0].rejectDesc;
            programCoverage.ACLS_Specialty_Pharmacy__c              = (responseBody.coveragePreferredResult[0].SPPName!=null)? String.join(responseBody.coveragePreferredResult[0].SPPName, ',') : null;
            programCoverage.ACLS_Has_Mandatory_Contracted_SP__c     = (responseBody.coveragePreferredResult[0].hasMandatoryContractedSP == true)? 'Yes' : (responseBody.coveragePreferredResult[0].hasMandatoryContractedSP == false)? 'No' : null;
            programCoverage.ACLS_Is_Product_on_Formulary__c         = (responseBody.coveragePreferredResult[0].isProductOnFormulary == true)? 'Yes' : (responseBody.coveragePreferredResult[0].isProductOnFormulary == false)? 'No' : null;
            programCoverage.ACLS_Product_Formulary_Tier__c          = (responseBody.coveragePreferredResult[0].productFormularyTier!=null)? String.valueOf(responseBody.coveragePreferredResult[0].productFormularyTier) : null;
            programCoverage.PA_Required__c                          = (responseBody.coveragePreferredResult[0].isPARequired == true)? 'Yes' : (responseBody.coveragePreferredResult[0].isPARequired == false)? 'No' : null;
            programCoverage.ACLS_Effective_From__c                  = ACLS_Utility.convertToDateFormat(responseBody.coveragePreferredResult[0].planInfo?.StartDate);
            programCoverage.PC_Expiration_Date__c                   = ACLS_Utility.convertToDateFormat(responseBody.coveragePreferredResult[0].planInfo?.EndDate);
            programCoverage.ACLS_Year_Plan__c                       = (responseBody.coveragePreferredResult[0].planInfo?.IsCalendarYearPlan == true)? 'Calendar' : (responseBody.coveragePreferredResult[0].planInfo?.IsCalendarYearPlan == false)? 'Year' : null;
            programCoverage.ACLS_PA_Phone__c                        = responseBody.coveragePreferredResult[0].planInfo?.PAPhone;
            programCoverage.ACLS_PA_Fax__c                          = responseBody.coveragePreferredResult[0].planInfo?.PAFax;
            programCoverage.PC_Deductible__c                        = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.accumulatedDeductibleAmount);
            programCoverage.PC_Rx_Remaining_Deductible__c           = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.remainingDeductibleAmount);
            programCoverage.PC_Rx_Applied_Deductible__c             = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.amountAppliedToPeriodicDeductible);
            programCoverage.ACLS_Does_Deductible_Apply_to_OOP__c    = (responseBody.coveragePreferredResult[0].accumulatorAccrual?.isDeductibleAppliedToOOP == true)? true : false;
            programCoverage.PC_Annual_Out_of_Pocket__c              = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.OOPMax);
            programCoverage.PC_Rx_Remaining_Out_Of_Pocket__c        = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.OOPRemaining);
            programCoverage.PC_Coinsurance_Percent__c               = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.coInsurancePercent);
            programCoverage.ACLS_Annual_Cap__c                      = ACLS_Utility.convertToDecimalFormat(responseBody.coveragePreferredResult[0].accumulatorAccrual?.annualCap);
        }
        //Update Health Plan
        if(responseBody!=null && !responseBody.coveragePreferredResult?.isEmpty()){
            PC_Health_Plan__c healthPlan = new PC_Health_Plan__c(
                Id = programCoverage.PC_Health_Plan__c,
                PC_Plan_Type__c = responseBody.coveragePreferredResult[0].planOrder,
                ACLS_PBM_Phone__c = responseBody.coveragePreferredResult[0].planInfo?.PBMPhone
            );
            update healthPlan;
        }  
    }

    /********************************************************************************************************************
    Method Name    : updatePharmacy
    Description    : Populate the api response value into the pharmacy instance
    Return Type    : void
    Parameter      : PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, Account pharmacy , PC_Address__c pharmacyAddress
    *********************************************************************************************************************/
    public void updatePharmacy(PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, Account pharmacy , PC_Address__c pharmacyAddress) {

        pharmacy.PC_NPI__c                              =   pharmacyBenefitsDetails.pharmacy.npi;
        pharmacy.PC_NCPDP__c                            =   pharmacyBenefitsDetails.pharmacy.ncpdp;
        pharmacy.PC_External_ID__c                      =   pharmacyBenefitsDetails.pharmacy.extId;
        pharmacy.Name                                   =   pharmacyBenefitsDetails.pharmacy.name;
        pharmacy.fax                                    =   pharmacyBenefitsDetails.pharmacy.fax;
        pharmacy.phone                                  =   pharmacyBenefitsDetails.pharmacy.phone;

        pharmacyAddress.PC_Zip_Code__c                          =   pharmacyBenefitsDetails.pharmacy.zipCode;
        pharmacyAddress.PC_Address_1__c                         =   pharmacyBenefitsDetails.pharmacy.address.addressOne;
        pharmacyAddress.PC_City__c                              =   pharmacyBenefitsDetails.pharmacy.address.city;

        pharmacyAddress.PC_Primary_Address__c                   =   true;
    }

    /********************************************************************************************************************
    Method Name    : createRemoteServiceLog
    Description    : Create instance of Remote service logs
    Return Type    : void
    Parameter      : String splitRequestBody, String endPoint, HttpResponse res
    *********************************************************************************************************************/
    public static void createRemoteServiceLog(String eBVRequestBody, String endPoint, HttpResponse res){
        PC_Remote_Service_Log__c eBVPharmacyRSL = PC_RemoteServiceLogHandler.getRemoteServiceLog(ACLS_Constants.EBV_PHARMACY_DETAILS, endPoint, eBVRequestBody, res?.getBody(), 'Callout made to perform Pharmacy eBV using RisRx Prevail API', PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND);
        eBVPharmacyRSL.PC_StatusCode__c = (res!=null)? String.valueOf(res.getStatusCode()) : '';
        insert eBVPharmacyRSL;
    }

    /********************************************************************************************************************
    Method Name    : throweBenefitsException
    Description    : Create instance of Remote service logs
    Return Type    : void
    Parameter      : String splitRequestBody, String endPoint, HttpResponse res
    *********************************************************************************************************************/
    public static void throweBenefitsException(String errorMessage){
        PC_eBenefits_Utility.eBenefitsException ex = new PC_eBenefits_Utility.eBenefitsException();
        ex.setMessage(errorMessage);
        throw ex;
    }
}