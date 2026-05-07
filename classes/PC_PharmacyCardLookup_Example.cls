/*********************************************************************************************************
Class Name      : PC_PharmacyCardLookup_Example
Description     : Implementor class for PC_PharmaCardLookup
Created By      : Vijay Kashikar
Created Date    : Mar 19, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Mar 19, 2018              Initial Version
Vijay Kashikar         		 May 29, 2018              Added FLS checks
*********************************************************************************************************/
public with sharing class PC_PharmacyCardLookup_Example implements PC_eBenefits.PharmacyCard {
    private String accessToken = null;
    private static final String PHARMACY_DETAILS_API_URL = 'https://api-tr-connectedhealth.dev.ubcpsc.com/plans/PBMs/?AbbreviatedName={1}';

    public PC_eBenefits.PharmacyCardResponse lookupPharmacyCard(PC_eBenefits.PharmacyCardRequest request) {

        try {

            PC_PharmacyCardLookup_Example client = new PC_PharmacyCardLookup_Example();
            PC_eBenefits.PharmacyCardResponse cResponse = new PC_eBenefits.PharmacyCardResponse();
            cResponse.bin = '003858';
            cResponse.insuranceGroupId = '3320057AAA8008N';
            cResponse.insuranceGroupName = 'MO BLUE ACCESS CH E+';
            cResponse.isSuccess = true;
            cResponse.mailCoverage = true;
            cResponse.pcn = 'A4';
            cResponse.planName = 'PN';
            cResponse.policyID = 'QTUAN2210932';
            cResponse.retailCoverage = false;
            cResponse.longTermCareCoverage = true;
            cResponse.specialtyCoverage = false;

            PC_eBenefits.Patient subscriber = new PC_eBenefits.Patient();
            subscriber.gender = 'Male';
            //subscriber.birthdate = '01/01/1990';
            subscriber.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(Date.today());
            subscriber.dob = Date.today();
            subscriber.firstName = 'Test';
            subscriber.lastName = 'Man';
            cResponse.subscriber = subscriber;

            PC_eBenefits.Address subscriberAddress = new PC_eBenefits.Address();
            subscriberAddress.city = 'Boston';
            subscriberAddress.state = 'MA';
            subscriberAddress.postalCode = '0172';
            subscriber.address = subscriberAddress;

            cResponse = client.setResponseLabels(cResponse);

            return cResponse;
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    public PC_eBenefits.PharmacyCardResponse setResponseLabels(PC_eBenefits.PharmacyCardResponse response) {
        if(response != null) {
            response.planNameLabel = 'PN';
            response.pcnLabel = PC_Health_Plan__c.PC_Rx_PCN__c.getDescribe().getLabel();
            response.insuranceGroupNameLabel = PC_Health_Plan__c.PC_Group_name__c.getDescribe().getLabel();
            response.insuranceGroupIdLabel = PC_Health_Plan__c.Group_No__c.getDescribe().getLabel();
            response.binLabel = PC_Health_Plan__c.PC_Rx_Bin__c.getDescribe().getLabel();
            response.policyIDLabel = PC_Health_Plan__c.ID_Policy_No__c.getDescribe().getLabel();
            response.mailCoverageLabel = PC_Health_Plan__c.PC_Has_Mail_Coverage__c.getDescribe().getLabel();
            response.retailCoverageLabel = PC_Health_Plan__c.PC_Has_Retail_Coverage__c.getDescribe().getLabel();
            response.longTermCareCoverageLabel = PC_Health_Plan__c.PC_Has_LTC_Coverage__c.getDescribe().getLabel();
            response.specialtyCoverageLabel = PC_Health_Plan__c.PC_Has_Specialty_Coverage__c.getDescribe().getLabel();


            response.subscriber.nameLabel = Account.Name.getDescribe().getLabel();
            response.subscriber.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
            response.subscriber.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
            response.subscriber.cardHolderRelationshipLabel =PC_Health_Plan__c.PC_Cardholder_Relationship_to_Patient__c.getDescribe().getLabel();


            response.subscriber.address.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
            response.subscriber.address.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
            response.subscriber.address.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
            return response;
        }
        else {
            return null;
        }


    }
    public PC_eBenefits.PharmacyCardRequest createPharmacyCardRequest() {

        //return PC_eBenefits_Utility.createPharmacyCardRequest(caseId);
        return new PC_eBenefits.PharmacyCardRequest();
    }
    public void updateHealthPlan(PC_eBenefits.PharmacyCardResponse response, PC_Health_Plan__c healthPlan) {
        PC_eBenefits_Utility.updatePharmacyHealthPlan(healthPlan, response);
    }
}