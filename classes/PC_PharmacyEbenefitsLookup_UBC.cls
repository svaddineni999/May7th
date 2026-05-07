/*********************************************************************************************************
Class Name      : PC_PharmacyEbenefitsLookup_UBC
Description     : Implementation class for PC_eBenefits.PharmacyEbenefits of UBC
Created By      : Vijay Kashikar
Created Date    : Jan 01, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Jan 01, 2018              Initial Version
Vijay Kashikar         		 May 29, 2018               Added FLS checks
Shishir Bansal              July 18, 2018              Added address parameter to the updatePharmacy method
Vijay Kashikar         		Sep 06, 2018                Make service responses to be available as part of global response objects
Shishir Bansal              OCt 09, 2018              Make use of pharmacy API instead of depending on External ID while doing RTBC requests for Default Pharmacies
Shishir Bansal              Sep 28, 2018              adding logic to reduce number of calls made to ubc by using pharmacycardlookupId and responsetime
Shishir Bansal              06-Dec-2019               [PC-5792] Avoid hardcoding of string variable
Haritha Reddy               21-Jan-2021               [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************************************/
public with sharing class PC_PharmacyEbenefitsLookup_UBC implements PC_eBenefits.PharmacyBenefits2 {
    public static final String PHARMACY_KEY = 'Pharmacy';
    public static final String AUTHORITY_KEY = 'PharmacyEligibility.Benefits';

    public PC_eBenefits.PharmacyBenefitsRequest createPharmacyBenefitsRequest() {
        return new PC_eBenefits.PharmacyBenefitsRequest();
    }
    public PC_eBenefits.PharmacyBenefitsResponse lookupPharmacyBenefits(PC_eBenefits.PharmacyBenefitsRequest request) {

        try {
            //PC_eBenefits.PharmacyCardRequest pharmacyCardRequest = client.getPharmacyCardRequest(healthPlanId, physicianId);
            PC_eBenefits.PharmacyCardRequest pharmacyCardRequest = new PC_eBenefits.PharmacyCardRequest();
            pharmacyCardRequest.patient = request.patient;
            pharmacyCardRequest.physician = request.physician;
            PC_PharmacyCardLookup_UBC lookup_ubc = new PC_PharmacyCardLookup_UBC();
            //PC_eBenefits.PharmacyCardResponse pharmacyCardResponse;
            Datetime createdAfter = PC_eBenefits_Utility.getCardLookupRequestDateThreshold();

            if (request.card.pharmacyCardLookupID != null) {
                if (createdAfter != null) {
                    if (request.card.pharmacyCardLookupRequestTime == null || request.card.pharmacyCardLookupRequestTime >= createdAfter) {
                        //do nothing
                        //pharmacyCardResponse = lookup_ubc.lookupPharmacyCard(pharmacyCardRequest);

                    } else {

                        String exMessage = Label.PC_PharmaCardLookupResponse_ThresholdErrorMessage;
                        AuraHandledException ex = new AuraHandledException(exMessage);
                        ex.setMessage(exMessage);
                        PC_Utility.logAndThrowException(ex, exMessage);

                    }
                }


                PC_UBC_Utility client = new PC_UBC_Utility();
                //PC_UBC.PharmacyCoverageServiceInput serviceInput = client.getServiceInput(caseId, healthPlanId, pharmacyId, prescriptionId, daysSupply, requestedQuantity);
                PC_UBC.PharmacyCoverageServiceInput serviceInput = client.getServiceInput(request);
                system.debug('serviceInput-->' + serviceInput);

                String pharmacyCardResponseId = request.card.pharmacyCardLookupID;
                if (pharmacyCardResponseId != null) {
                    List<PC_UBC.AdditionalIds> additionalIds = new List<PC_UBC.AdditionalIds>();
                    PC_UBC.AdditionalIds pharmacyCardResponseAdditionalId = new PC_UBC.AdditionalIds();
                    pharmacyCardResponseAdditionalId.authority = AUTHORITY_KEY;
                    pharmacyCardResponseAdditionalId.id = pharmacyCardResponseId;
                    pharmacyCardResponseAdditionalId.issuedId = pharmacyCardResponseId;
                    PC_UBC.AdditionalIds pharmacyAdditionalId = new PC_UBC.AdditionalIds();
                    //String pharmacyAId = PC_UBC_Utility.getPharmacyAdditionalId(pharmacyId);
                    String pharmacyAId = '';

                    if (request.pharmacy != null && String.isNotBlank(request.pharmacy.extId)) {

                        pharmacyAId = request.pharmacy.extId;
                    } else {
                        // sending parameters for searching pharmacy outside salesforce and getting details
                        PC_eBenefits.PharmacySearchParams searchPharmacyParams = new PC_eBenefits.PharmacySearchParams();
                        searchPharmacyParams.isLongTerm = false;
                        searchPharmacyParams.isMailOrder = false;
                        searchPharmacyParams.isRetail = false;
                        searchPharmacyParams.isSpecialty = false;
                        searchPharmacyParams.npi = request.pharmacy.npi;
                        searchPharmacyParams.searchBy = PC_eBenefits.PharmacySearchBy.NPI_NCPDP_POSTALCODE;
                        searchPharmacyParams.zipCode = request.pharmacy.zipCode;
                        searchPharmacyParams.ncpdp = request.pharmacy.ncpdp;

                        PC_UBC_Utility ubcSearchParamObj = new PC_UBC_Utility();
                        List<PC_UBC.Pharmacy> ubcPharmacyList = ubcSearchParamObj.searchPharmacies(searchPharmacyParams);

                        if (ubcPharmacyList == null || ubcPharmacyList.isEmpty()) {
                            PC_Utility.throwAuraHandledException(Label.PC_PharmacyFinder_UBC_No_Pharmacies_Found);
                        } else if (ubcPharmacyList != null && !ubcPharmacyList.isEmpty() && ubcPharmacyList.size() == 1) {
                            pharmacyAId = ubcPharmacyList[0].id;
                        } else {
                            PC_Utility.throwAuraHandledException(Label.PC_PharmacyFinder_UBC_Unique_Result_Not_Found);
                        }

                    }

                    if (String.isNotEmpty(pharmacyAId)) {
                        pharmacyAdditionalId.authority = PHARMACY_KEY;
                        pharmacyAdditionalId.id = pharmacyAId;
                        pharmacyAdditionalId.issuedId = pharmacyAId;

                        additionalIds.add(pharmacyCardResponseAdditionalId);
                        additionalIds.add(pharmacyAdditionalId);

                        serviceInput.additionalIds = additionalIds;


                        client.authenticateViaNamedCreds();

                        PC_UBC.PharmacyCoverageServiceResponse serviceResponse1 = client.checkPharmacyCoverageBenefits(serviceInput);

                        //PC_UBC.PharmacyCoverageServiceResponse serviceResponse1 = client.example2();
                        PC_eBenefits.PharmacyBenefitsResponse benefitDetails1 = getPharmacyBenefitInfoHelper(serviceResponse1);
                        benefitDetails1.allServiceReponses = serviceResponse1.allServiceResponses;
                        /*if(benefitDetails1.allServiceReponses == null) {
                            benefitDetails1.allServiceReponses = new Map<String, String>();
                        }
                         benefitDetails1.allServiceReponses.putAll(pharmacyCardResponse.allServiceResponses);*/

                        //system.debug('vj->service response start');
                        //system.debug(JSON.serialize(benefitDetails1));
                        //system.debug('vj->service response end');

                        return benefitDetails1;
                    } else {
                        PC_Utility.throwAuraHandledException(Label.PC_PharmaCardLookup_PharmacyID_NotAvailable);

                    }
                }


                else {
                    PC_Utility.throwAuraHandledException(Label.PC_PharmaCardLookup_PatientNotFound);
                }
            } else {

                //String exMessage = 'Pharmacy Card Lookup Id is blank.Please make a fresh Pharmacy Card Lookup service request.';
                String exMessage = Label.PC_PharmaCardLookup_Id_Not_Found;
                AuraHandledException ex = new AuraHandledException(exMessage);
                ex.setMessage(exMessage);
                PC_Utility.logAndThrowException(ex, exMessage);

            }
        }

        catch (exception ex) {
            system.debug('message ' + ex.getMessage() + ' line ' + ex.getStackTraceString());
            PC_Utility.createExceptionLog(ex);
            PC_eBenefits.PharmacyBenefitsResponse benefitDetails1 = new PC_eBenefits.PharmacyBenefitsResponse();

            benefitDetails1.isSuccess = false;
            benefitDetails1.eBenefitsServiceResponse = null;
            benefitDetails1.errorMessage = ex.getMessage();
            return benefitDetails1;

        }
        return null;
    }

    public static PC_eBenefits.PharmacyBenefitsResponse getPharmacyBenefitInfoHelper(PC_UBC.PharmacyCoverageServiceResponse serviceResponse1) {
        PC_eBenefits.PharmacyBenefitsResponse benefitDetails1 =
                new PC_eBenefits.PharmacyBenefitsResponse();

        if (serviceResponse1 == null) {
            benefitDetails1.eBenefitsServiceResponse = null;
            benefitDetails1.isSuccess = false;
        } else if (serviceResponse1.responseStatus != null && serviceResponse1.responseStatus.isError) {
            benefitDetails1.eBenefitsServiceResponse = null;
            benefitDetails1.isSuccess = false;
            benefitDetails1.errorMessage = serviceResponse1.responseStatus.internalMessage;
        } else if (serviceResponse1.modelState != null) {
            benefitDetails1.eBenefitsServiceResponse = null;
            benefitDetails1.isSuccess = false;
            String errorMessage = '';
            List<String[]> msgs = serviceResponse1.modelState.values();
            List<String> new_m;
            for (String[] m : msgs) {
                new_m = new List<String>();
                for (String n : m) {
                    if (String.isNotEmpty(n) && !n.equalsIgnoreCase(PC_Constants.NULL_STRING)) {
                        new_m.add(n);
                    }
                }
                errorMessage += String.join(new_m, ',');
                errorMessage += '.';
            }
            benefitDetails1.errorMessage = errorMessage;
        } else {
            benefitDetails1.eBenefitsServiceResponse = convertServiceResponse(serviceResponse1);

            benefitDetails1.eBenefitsServiceResponse.accumulators.deductible.individual.remainingInDollarCurrency =
                    covertToCurrencyFormat(benefitDetails1.eBenefitsServiceResponse.accumulators.deductible.individual.remaining);
            benefitDetails1.eBenefitsServiceResponse.accumulators.deductible.individual.appliedInDollarCurrency =
                    covertToCurrencyFormat(benefitDetails1.eBenefitsServiceResponse.accumulators.deductible.individual.applied);

            benefitDetails1.eBenefitsServiceResponse.accumulators.outOfPocket.individual.remainingInDollarCurrency =
                    covertToCurrencyFormat(benefitDetails1.eBenefitsServiceResponse.accumulators.outOfPocket.individual.remaining);
            benefitDetails1.eBenefitsServiceResponse.accumulators.outOfPocket.individual.appliedInDollarCurrency =
                    covertToCurrencyFormat(benefitDetails1.eBenefitsServiceResponse.accumulators.outOfPocket.individual.applied);

            benefitDetails1.eBenefitsServiceResponse.pricing.patientInDollarFormat =
                    covertToCurrencyFormat(benefitDetails1.eBenefitsServiceResponse.pricing.patient);
            benefitDetails1.isExternalPharmacy = PC_eBenefits_Utility.isExternalPharmacy(serviceResponse1.pharmacy.id);
            Map<String, Object> additionalInfo = new Map<String, Object>();
            additionalInfo.put('pharmacy', serviceResponse1.pharmacy);
            //additionalInfo.put('isPriorAuthRequired ' ,serviceResponse1.isPriorAuthRequired );
            //additionalInfo.put('drugDbSourceCode',serviceResponse1.prescription.product.drugDbSourceCode);
            benefitDetails1.eBenefitsServiceResponse.priorAuthorization = new PC_eBenefits.PriorAuthorization();
            benefitDetails1.eBenefitsServiceResponse.priorAuthorization.isRequired = serviceResponse1.isPriorAuthRequired;
            benefitDetails1.eBenefitsServiceResponse.product = new PC_eBenefits.Product();
            //benefitDetails1.eBenefitsServiceResponse.product.drugDbSourceCode = serviceResponse1.prescription.product.drugDbSourceCode;
            //benefitDetails1.additinalInfo = additionalInfo;
        }
        return benefitDetails1;
    }


    public static PC_eBenefits.PharmacyEbenefitsServiceResponse convertServiceResponse(PC_UBC.PharmacyCoverageServiceResponse serviceResponse) {
        system.debug('server response');
        system.debug(json.serialize(serviceResponse));
        PC_eBenefits.PharmacyEbenefitsServiceResponse pcResponse = new PC_eBenefits.PharmacyEbenefitsServiceResponse();
        PC_eBenefits.accumulators pcAccumulators = new PC_eBenefits.accumulators();
        PC_eBenefits.outOfPocket pcOutOfPocket = new PC_eBenefits.outOfPocket();
        PC_eBenefits.individual pcIndividual1 = new PC_eBenefits.individual();

        pcIndividual1.applied = serviceResponse.accumulators.outOfPocket.individual.applied;
        system.debug(serviceResponse.accumulators.outOfPocket.individual.applied);
        system.debug(pcIndividual1.appliedInDollarCurrency);
        pcIndividual1.remaining = serviceResponse.accumulators.outOfPocket.individual.remaining;
        pcOutOfPocket.individual = pcIndividual1;
        pcAccumulators.outOfPocket = pcOutOfPocket;

        PC_eBenefits.deductible pcDeductible = new PC_eBenefits.deductible();
        PC_eBenefits.individual pcIndividual2 = new PC_eBenefits.individual();
        pcIndividual2.applied = serviceResponse.accumulators.deductible.individual.applied;
        pcIndividual2.remaining = serviceResponse.accumulators.deductible.individual.remaining;
        pcDeductible.individual = pcIndividual2;
        pcAccumulators.deductible = pcDeductible;

        PC_eBenefits.pricing pcPricing = new PC_eBenefits.pricing();
        pcPricing.patient = serviceResponse.pricing.patient;

        List<PC_eBenefits.coverageAlerts> pcCoverageAlerts = new List<PC_eBenefits.coverageAlerts>();
        PC_eBenefits.coverageAlerts pcCoverageAlert;
        for (PC_UBC.coverageAlerts coverageAlerts : serviceResponse.coverageAlerts) {
            pcCoverageAlert = new PC_eBenefits.coverageAlerts();
            pcCoverageAlert.name = coverageAlerts.name;
            pcCoverageAlert.id = coverageAlerts.id;
            pcCoverageAlert.description = coverageAlerts.description;
            pcCoverageAlerts.add(pcCoverageAlert);
        }

        pcResponse.daysSupplyPriced = serviceResponse.daysSupplyPriced;
        pcResponse.metricQuantityPriced = serviceResponse.metricQuantityPriced;
        pcResponse.coverageAlerts = pcCoverageAlerts;
        pcResponse.pricing = pcPricing;
        pcResponse.accumulators = pcAccumulators;

        List<PC_eBenefits.PharmacyType> pharmacyTypes = new List<PC_eBenefits.PharmacyType>();
        PC_eBenefits.PharmacyType pharmacyType;
        for (String pType : serviceResponse.pharmacy.pharmacyType) {
            pharmacyType = new PC_eBenefits.PharmacyType();
            pharmacyType.type = pType;
            pharmacyTypes.add(pharmacyType);
        }
        pcResponse.pharmacyType = pharmacyTypes;

        system.debug('pcrespnse object values');
        system.debug(json.serialize(pcResponse));
        return pcResponse;
    }

    private static String covertToCurrencyFormat(Decimal amount) {
        // Scale and round upto 2 digits
        //Decimal scaledDecimal = d.setScale(2);
        // prepend currency symbol
        if (amount != null) {
            Decimal rA = amount;
            List<String> args = new String[]{
                    PC_Constants.PC_ZERO, 'number', '###,###,##0.00'
            };
            String s = String.format(rA.format(), args);
            String strFormattedCurrency = '$ ' + s;
            return strFormattedCurrency;
        } else {
            return null;
        }
    }

    public void updateProgramCoverage(PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, PC_Program_Coverage__c programCoverage) {
        PC_eBenefits_Utility.updatePharmacyProgramCoverage(programCoverage, pharmacyBenefitsDetails);

        programCoverage.PA_Required__c = PC_UBC_Utility.getPARequired(pharmacyBenefitsDetails);
    }

    public void updatePharmacy(PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, Account pharmacy, PC_Address__c address) {
        PC_UBC_Utility.updatePharmacy(pharmacyBenefitsDetails, pharmacy, address);
    }

}