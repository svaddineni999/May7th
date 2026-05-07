/*************************************************************************************************************************************
Class Name      : PC_PharmacyEbenefitsLookup_Example
Description     : Implementing class for PC_PharmaCardLookup.cmp
Created By      : Deloitte
Created Date    : Mar 21, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar         		   May 21, 2018           Initial Version
Vijay Kashikar         		   May 29, 2018           Added FLS checks
Shishir Bansal                 July 18, 2018         added address as a parameter to the updatePharmacy method
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
****************************************************************************************************************************************************/

public with sharing class PC_PharmacyEbenefitsLookup_Example implements PC_eBenefits.PharmacyBenefits2{

    public PC_eBenefits.PharmacyBenefitsRequest createPharmacyBenefitsRequest() {
        return new PC_eBenefits.PharmacyBenefitsRequest();
    }

    public PC_eBenefits.PharmacyBenefitsResponse lookupPharmacyBenefits(PC_eBenefits.PharmacyBenefitsRequest request) {

        try {
            //system.debug('1 '+prescriptionId);
            PC_UBC_Utility utility = new PC_UBC_Utility();
            //PC_UBC.PharmacyCoverageServiceInput serviceInput = utility.getServiceInput(caseId, healthPlanId, pharmacyId, prescriptionId, daysSupply, requestedQuantity);
            //system.debug('2');
            //system.debug(serviceInput);
            //PC_UBC_eBenefitsServiceClient client = new PC_UBC_eBenefitsServiceClient();
            //utility.authenticateViaNamedCreds();
            //system.debug('3');
            //PC_UBC_eBenefitsServiceResponse serviceResponse1 = client.checkEbenefits(serviceInput);

            PC_UBC.PharmacyCoverageServiceResponse serviceResponse1 = utility.example2();
            PC_eBenefits.PharmacyBenefitsResponse benefitDetails1  = getPharmacyBenefitInfoHelper(serviceResponse1);


            return benefitDetails1;

        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.createExceptionLog(ex);
            PC_eBenefits.PharmacyBenefitsResponse benefitDetails1 = new PC_eBenefits.PharmacyBenefitsResponse();

            benefitDetails1.isSuccess = false;
            benefitDetails1.errorMessage = ex.getMessage();
            benefitDetails1.eBenefitsServiceResponse = null;
            return  benefitDetails1;

        }
        //return null;
    }

    public static PC_eBenefits.PharmacyBenefitsResponse getPharmacyBenefitInfoHelper(PC_UBC.PharmacyCoverageServiceResponse serviceResponse1) {
        PC_eBenefits.PharmacyBenefitsResponse benefitDetails1 =
                new PC_eBenefits.PharmacyBenefitsResponse();

        if(serviceResponse1 == null) {
            benefitDetails1.eBenefitsServiceResponse = null;
            benefitDetails1.isSuccess=false;
        }
        else {
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

            benefitDetails1.eBenefitsServiceResponse.priorAuthorization.isRequired = serviceResponse1.isPriorAuthRequired;
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

        pcIndividual1.applied = serviceResponse.accumulators.outOfPocket.individual.remaining;
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
        for(PC_UBC.coverageAlerts coverageAlerts : serviceResponse.coverageAlerts) {
            pcCoverageAlert = new PC_eBenefits.coverageAlerts();
            pcCoverageAlert.name = coverageAlerts.name;
            pcCoverageAlert.id = coverageAlerts.id;
            pcCoverageAlert.description =coverageAlerts.description;
            pcCoverageAlerts.add(pcCoverageAlert);
        }

        pcResponse.daysSupplyPriced = serviceResponse.daysSupplyPriced;
        pcResponse.metricQuantityPriced = serviceResponse.metricQuantityPriced;
        pcResponse.coverageAlerts = pcCoverageAlerts;
        pcResponse.pricing = pcPricing;
        pcResponse.accumulators = pcAccumulators;

        PC_eBenefits.PriorAuthorization priorAuthorization = new PC_eBenefits.PriorAuthorization();
        priorAuthorization.isRequired = serviceResponse.isPriorAuthRequired;
        pcResponse.priorAuthorization = priorAuthorization;

        system.debug('pcrespnse object values');
        system.debug(json.serialize(pcResponse));
        return pcResponse;
    }

    private static String covertToCurrencyFormat(Decimal amount) {
        // Scale and round upto 2 digits
        //Decimal scaledDecimal = d.setScale(2);
        // prepend currency symbol
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


    public static PC_eBenefits.PharmacyCardRequest getPharmacyCardholderInfo(String caseId) {

        try {
            PC_eBenefits.PharmacyCardRequest cardHolderInfo = new PC_eBenefits.PharmacyCardRequest();

            List<String> fields = new List<String>();
            fields.add('AccountId');
            fields.add('Account.Name');
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Gender__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'ID');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'Name');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__r') + '.' + 'Id');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Product__c'));
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

            Case currentCase = [Select Id,
                    AccountId, Account.Name, Account.PC_Date_of_Birth__c, Account.PC_Gender__c,
                    Account.PC_First_Name__c, Account.PC_Last_Name__c,
                    Account.PC_Primary_Zip_Code__c,
                    PC_Physician__r.Id, PC_Physician__r.PC_First_Name__c, PC_Physician__r.PC_Last_Name__c,
                    PC_Physician__r.Name, PC_Physician__r.PC_NPI__c,
                    PC_Program_Product__r.Id, PC_Program_Product__r.PC_Product__c
            from Case where id=:caseId];
            if(currentCase != null) {
                PC_eBenefits.Patient patient = new PC_eBenefits.Patient();
                if(String.isNotBlank(currentCase.AccountId)) {
                    Account.Type.getDescribe().getLabel();

                    patient.FirstName = currentCase.Account.PC_First_Name__c;
                    patient.LastName = currentCase.Account.PC_Last_Name__c;
                    //patient.Birthdate = currentCase.Account.PC_Date_of_Birth__c != null ? (currentCase.Account.PC_Date_of_Birth__c).format() : null;
                    patient.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(currentCase.Account.PC_Date_of_Birth__c);
                    patient.dob = currentCase.Account.PC_Date_of_Birth__c;
                    PC_eBenefits.Address primaryAddr = new PC_eBenefits.Address();
                    primaryAddr.postalCode = currentCase.Account.PC_Primary_Zip_Code__c;
                    patient.Address = primaryAddr;
                    patient.Gender = currentCase.Account.PC_Gender__c;

                    patient.nameLabel = Account.Name.getDescribe().getLabel();
                    patient.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
                    patient.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
                    primaryAddr.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
                }

                cardHolderInfo.patient = patient;

                system.debug(cardHolderInfo.patient);

                PC_eBenefits.Physician physician = new PC_eBenefits.Physician();
                if(String.isNotBlank(currentCase.PC_Physician__r.Id)) {
                    //physician.Id = currentCase.PC_Physician__r.Id;
                    physician.NPI = currentCase.PC_Physician__r.PC_NPI__c;
                    physician.FirstName = currentCase.PC_Physician__r.PC_First_Name__c;
                    physician.LastName = currentCase.PC_Physician__r.PC_Last_Name__c;
                }
                physician.nameLabel = Account.Name.getDescribe().getLabel();
                physician.npiLabel = Account.PC_NPI__c.getDescribe().getLabel();

                cardHolderInfo.physician = physician;

                system.debug(cardHolderInfo.physician);

                String productId = currentCase.PC_Program_Product__r.PC_Product__c;
                PC_eBenefits.Drug pro = new PC_eBenefits.Drug();

                List<String> productFields = new List<String>{'ProductCode','Name',PC_Constants.getQualifiedAPIName('PC_NDC__c')};
                PC_Database.assertAccess(PC_Constants.PC_PRODUCT2, PC_Database.Operation.Reading, productFields);

                if(String.isNotBlank(productId)) {
                    Product2 product = [Select Id, ProductCode, Name, PC_NDC__c from Product2 where id = :productId ];

                    //pro.Id = product.Id;
                    pro.NDC = product.PC_NDC__c;
                    pro.Label = product.Name;
                }
                cardHolderInfo.product = pro;

                system.debug(cardHolderInfo);
            }
            return cardHolderInfo;
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public void updateProgramCoverage(PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, PC_Program_Coverage__c programCoverage) {
        PC_eBenefits_Utility.updatePharmacyProgramCoverage(programCoverage, pharmacyBenefitsDetails);
    }

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

}