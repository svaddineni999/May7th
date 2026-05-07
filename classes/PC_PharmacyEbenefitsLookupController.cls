/*********************************************************************************************************
Class Name      : PC_PharmacyEbenefitsLookupController
Description     : Controller class for PC_PharmacyEbenefitsLookup
Created By      : Vijay Kashikar
Created Date    : Mar 19, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Mar 19, 2018              Initial Version
Vijay Kashikar         		 May 29, 2018              Added FLS checks
Shishir Bansal              June 22, 2018             added new fields to capture pharmacy details PC-3180
Shishir Bansal              June 26, 2018              added days suppy and quantity values to Program coverage
Vijay Kashikar              Sep  20, 2018              [PC-3777] Made changes so that duplicate pharmacies are not created while saving ebenefit investigation record.
Vijay Kashikar              21-Jan-21                 [PC-7102] Added FLS Checks
*********************************************************************************************************/
public with sharing class PC_PharmacyEbenefitsLookupController {



    @AuraEnabled
    public static PC_eBenefits.PharmacyBenefitsOptions getEBenefitsInfo(String caseId) {
        try {
            PC_eBenefits.PharmacyBenefits2 handler = (PC_eBenefits.PharmacyBenefits2) PC_eBenefits.getPharmacyBenefitsService();
            PC_eBenefits.PharmacyBenefitsOptions request = PC_eBenefits_Utility.getPharmacyBenefitsOptions(caseId);
            system.debug('patient Info - ' + JSON.serialize(request));
            return request;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    @AuraEnabled
    public static PC_eBenefits.PharmacyBenefitsResponse getPharmacyBenefitInfo(String caseId,
            String healthPlanId, String prescriptionId, String pharmacyId, Boolean isExternalPharmacy,
            Decimal daysSupply, Decimal requestedQuantity, Integer index, String eBenefitsPharmacyJson)
    {
        system.debug('in getPharmacyBenefitInfo');
        system.debug('pharmacyBaseObjectJson -> ' + eBenefitsPharmacyJson);
        PC_eBenefits.PharmacyBenefitsResponse response = new PC_eBenefits.PharmacyBenefitsResponse();
        try {
            PC_eBenefits.PharmacyBenefits2 handler = (PC_eBenefits.PharmacyBenefits2) PC_eBenefits.getPharmacyBenefitsService();


            PC_eBenefits.PharmacyBenefitsRequest pharmacyRequest = handler.createPharmacyBenefitsRequest(); // Blank constructor of Request Body

            PC_eBenefits_Utility.updatePharmacyRequest(caseId, healthPlanId, prescriptionId, pharmacyId,isExternalPharmacy,
                    daysSupply, requestedQuantity, index, pharmacyRequest);

            pharmacyRequest.caseId = caseId;                   //Added new attribute - ACLS
            pharmacyRequest.healthPlanId = healthPlanId;       //Added new attribute - ACLS
            pharmacyRequest.prescriptionId = prescriptionId;   //Added new attribute - ACLS

            response = handler.lookupPharmacyBenefits(pharmacyRequest);
            response.pharmacyId = pharmacyId;
            response.healthPlanId = healthPlanId;
            response.caseId = caseId;
            response.prescriptionId = prescriptionId;
            response.index = index;
            response.pharmacy = (PC_eBenefits.Pharmacy) JSON.deserialize(eBenefitsPharmacyJson, PC_eBenefits.Pharmacy.class);
            system.debug('patient Info - ' + JSON.serialize(response));
            //throw new PC_eLetter.SenderException('Please update the HealthPlan with BIN, PCN, Group, and MemberID. ');
            return response;
        }
        catch(Exception ex) {
            PC_Utility.publishErrorLog(ex, '');
            response.errorMessage = ex.getMessage();
        }
        response.pharmacyId = pharmacyId;
        response.healthPlanId = healthPlanId;
        response.caseId = caseId;
        response.prescriptionId = prescriptionId;
        response.index = index;
        response.isSuccess = false;
        return response;


    }

    @AuraEnabled
    public static PC_Program_Coverage__c createProgramCoverage(String pharmacyBenefitsDetails_JSON) {
        try {
            PC_eBenefits.PharmacyBenefits2 handler = (PC_eBenefits.PharmacyBenefits2) PC_eBenefits.getPharmacyBenefitsService();
            system.debug('createProgramCoverage. pharmacyBenefitsDetails_JSON -> '+pharmacyBenefitsDetails_JSON);
            PC_eBenefits.PharmacyBenefitsResponse coverageDetails = (PC_eBenefits.PharmacyBenefitsResponse) JSON.deserialize(pharmacyBenefitsDetails_JSON, PC_eBenefits.PharmacyBenefitsResponse.class);
            system.debug('coverageDetails -> '+coverageDetails);
            PC_Program_Coverage__c newProgCoverage = new PC_Program_Coverage__c();
            newProgCoverage.PC_Program__c = coverageDetails.caseId;
            newProgCoverage.PC_Health_Plan__c = coverageDetails.healthPlanId;
            //Boolean isExtenalPharmacy = PC_eBenefits_Utility.isExternalPharmacy(coverageDetails.pharmacyId);
            Boolean isExtenalPharmacy =coverageDetails.pharmacy.isExternalPharmacy;
            
            

            if(isExtenalPharmacy) {
                List<Account> pharmacies = PC_eBenefits_Utility.getPharmaciesBy_NPI_OR_NCPDP(coverageDetails.pharmacy.npi, coverageDetails.pharmacy.ncpdp);
                Account existingPharmacy;
                if (pharmacies == null || pharmacies.isEmpty()) {
                    existingPharmacy = null;
                } else if (pharmacies.size() == 1) {
                    existingPharmacy = pharmacies[0];
                } else {
                    PC_eBenefits_Utility.eBenefitsException ex = new PC_eBenefits_Utility.eBenefitsException();
                    ex.setMessage(String.format(Label.PC_Ebenefits_Duplicate_Pharmacy, new List<String>{
                            coverageDetails.pharmacy.npi, coverageDetails.pharmacy.ncpdp
                    }));
                    throw ex;
                }
                if(existingPharmacy == null || String.isBlank(existingPharmacy.Id)) {
                    Account newPharmacy = new Account();
                    PC_Address__c newPharmacyAddress = new PC_Address__c();
                    newPharmacy.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHARMACY_RECORD_TYPE);
                    handler.updatePharmacy(coverageDetails, newPharmacy, newPharmacyAddress);
                    system.debug('record to insert-->' + newPharmacy);
                    Account newPharmacyAccount = (Account) PC_Database.ins(newPharmacy);
                    newPharmacyAddress.PC_Account__c = newPharmacyAccount.Id;
                    PC_Address__c newPharmacyAccAddress = (PC_Address__c) PC_Database.ins(newPharmacyAddress);
                    newProgCoverage.PC_Pharmacy__c = newPharmacyAccount.Id;
                }
                else {
                    newProgCoverage.PC_Pharmacy__c = existingPharmacy.Id;
                }

            }
            else {
                //newProgCoverage.PC_Pharmacy__c = PC_eBenefits_Utility.getPharmacyIdBy_Id_Or_ExtId(coverageDetails.pharmacyId);
                newProgCoverage.PC_Pharmacy__c = coverageDetails.pharmacyId;

            }

            newProgCoverage.PC_Prescription__c = coverageDetails.prescriptionId;
            if(coverageDetails.eBenefitsServiceResponse.pricing.patient!= null)
                newProgCoverage.PC_Rx_Pay_Amt__c = coverageDetails.eBenefitsServiceResponse.pricing.patient;
            if(coverageDetails.eBenefitsServiceResponse.accumulators.deductible.individual.applied!= null )
                newProgCoverage.PC_Rx_Applied_Deductible__c  = coverageDetails.eBenefitsServiceResponse.accumulators.deductible.individual.applied;
            if(coverageDetails.eBenefitsServiceResponse.accumulators.deductible.individual.remaining!= null)
                newProgCoverage.PC_Rx_Remaining_Deductible__c     = coverageDetails.eBenefitsServiceResponse.accumulators.deductible.individual.remaining;
            if(coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.applied!= null)
                newProgCoverage.PC_Rx_Applied_Out_Of_Pocket__c =   coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.applied;
            if(coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.remaining!= null)
                newProgCoverage.PC_Rx_Remaining_Out_Of_Pocket__c =coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.remaining;


            newProgCoverage.PC_Days_Priced__c = coverageDetails.eBenefitsServiceResponse.daysSupplyPriced;
            newProgCoverage.PC_Quantity_Priced__c =  coverageDetails.eBenefitsServiceResponse.metricQuantityPriced;

            handler.updateProgramCoverage(coverageDetails, newProgCoverage);

            PC_Program_Coverage__c insertedProgCoverage = (PC_Program_Coverage__c) PC_Database.ins(newProgCoverage, true);
            String pcId = insertedProgCoverage.Id;

            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('NAME');
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'), PC_Database.Operation.Reading, fields);

            PC_Program_Coverage__c pc = [SELECT ID, NAME FROM PC_Program_Coverage__c where id = :pcId];
            return pc;
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }

        return null;
    }


    @AuraEnabled
    public static PC_eBenefits.Patient getCardHolderInfo(Id healthPlanId) {
        return PC_eBenefits_Utility.getCardHolderInfo_helper(healthPlanId);
    }

    @AuraEnabled
    public static PC_eBenefits.Physician getPhysicianForPrescription(Id prescriptionId ) {
        try {
            system.debug('prescriptionId'+prescriptionId);
            PC_Prescription__c prescription;
            PC_eBenefits.Physician physician;

            //PC_eBenefits.PharmacyCardResponse eligResponse;
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Physician_Account__c')};
            
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),PC_Database.Operation.Reading, fields);

            List<String> accountFields = new List<String>();
            accountFields.add(PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            accountFields.add(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            accountFields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

            if(prescriptionId!=null) {
                prescription =  [Select Id, PC_Physician_Account__c, PC_Physician_Account__r.PC_First_Name__c,PC_Physician_Account__r.PC_Last_Name__c,PC_Physician_Account__r.PC_NPI__c FROM  PC_Prescription__c where Id = :prescriptionId];
            }
             physician = new PC_eBenefits.Physician();


            physician.nameLabel = Case.PC_Physician__c.getDescribe().getLabel();
            physician.npiLabel = Case.PC_Physician__c.getDescribe().getLabel() +' '+ Account.PC_NPI__c.getDescribe().getLabel();
            if(String.isNotBlank(prescription.PC_Physician_Account__c)) {

                physician.npi = prescription.PC_Physician_Account__r.PC_NPI__c;
                physician.firstName =  prescription.PC_Physician_Account__r.PC_First_Name__c;
                physician.lastName =  prescription.PC_Physician_Account__r.PC_Last_Name__c;
                physician.id =  prescription.PC_Physician_Account__c;
            }
            return physician;

        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

}