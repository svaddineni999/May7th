/*********************************************************************************************************
Class Name      : PC_PharmacyCardLookup_UBC
Description     : Implementor class for PC_PharmaCardLookup
Created By      : Vijay Kashikar
Created Date    : Mar 19, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Mar 19, 2018              Initial Version
Vijay Kashikar         		 May 29, 2018              Added FLS checks
Sahil Garg            		 May 7, 2018               Pharma Card lookup updates for additional info
Vijay Kashikar         		 May 10, 2018              PC-3001 - commented out reading product info while passing the request
Vijay Kashikar         		 Sep 06, 2018              Make service responses to be available as part of global response objects
Shishir Bansal               Sep 25, 2018              Storing UBC Eligibility Lookup Time when using pharmacy card lookup service
Vijay Kashikar               21-Jan-2021               [PC-7102] Added sharing clause
*********************************************************************************************************/
public with sharing class PC_PharmacyCardLookup_UBC implements PC_eBenefits.PharmacyCard {


    public PC_eBenefits.PharmacyCardResponse lookupPharmacyCard(PC_eBenefits.PharmacyCardRequest request) {

        try {
            PC_UBC_Utility client = new PC_UBC_Utility();
            PC_UBC.EligibilityServiceResponse response = new PC_UBC.EligibilityServiceResponse();

            response = client.lookUpPharmacyCard(request);
            system.debug('service response');
            system.debug(JSON.serialize(response));
            PC_eBenefits.PharmacyCardResponse cResponse = client.convertPharmaCardServiceResponse(response);
            cResponse = client.setPharmacyCardResponseLabels(cResponse);
            cResponse.isSuccess = true;
            //system.debug('vj->service response start');
            //system.debug(JSON.serialize(cResponse));
            //system.debug('vj->service response end');
            return cResponse;
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public PC_eBenefits.PharmacyCardRequest createPharmacyCardRequest() {
        return new PC_eBenefits.PharmacyCardRequest();

    }
    public void updateHealthPlan(PC_eBenefits.PharmacyCardResponse response, PC_Health_Plan__c healthPlan) {
        PC_eBenefits_Utility.updatePharmacyHealthPlan(healthPlan, response);
    }




}