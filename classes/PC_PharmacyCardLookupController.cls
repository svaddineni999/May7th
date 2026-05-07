/*********************************************************************************************************
Class Name      : PC_PharmacyCardLookupController
Description     : Controller class for PC_PharmaCardLookup
Created By      : Vijay Kashikar
Created Date    : Jan 01, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Jan 01, 2018              Initial Version
Vijay Kashikar         		 May 29, 2018              Added FLS checks
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************************************/
public with sharing class  PC_PharmacyCardLookupController {
    @AuraEnabled
    public static HealthPlansWithLabel getRelatedHealthPlans(String caseId) {
        try {
            List<String> caseFields = new List<String>();
            caseFields.add('ID');
            caseFields.add('AccountId');
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);
            Case currentCase = [Select Id, AccountId from Case where id=:caseId];

            if(currentCase != null && currentCase.AccountId != null
                    ) {
                String patientId = currentCase.AccountId;
                String recordTypeId;
                recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);

                List<String> healthPlanFields = new List<String>();
                healthPlanFields.add('ID');
                healthPlanFields.add('Name');
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('ID_Policy_No__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Plan_Status__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Plan_Type__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Rx_Bin__c'));
                PC_Database.assertAccess(PC_Constants.PC_HEALTH_PLAN,PC_Database.Operation.Reading, healthPlanFields);
                List<PC_Health_Plan__c> healthPlans = [SELECT ID, Name,
                        PC_Group_name__c, ID_Policy_No__c,
                        PC_Plan_Status__c, PC_Plan_Type__c,
                        PC_Rx_Bin__c
                FROM PC_Health_Plan__c where Patient__c =:patientId and RecordTypeId = :recordTypeId
                ORDER BY LastModifiedDate DESC];
                return new HealthPlansWithLabel(healthPlans);
            }
            else {
                //throw new AuraHandledException(); 
                PC_Utility.throwAuraHandledException(PC_eBenefits_Utility.getMissingAccountMessageEBV());
            }
            // throw exception
            return null;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }


    public inherited sharing class HealthPlansWithLabel {
        //@AuraEnabled public List<PC_Health_Plan__c> healthPlans;
        @AuraEnabled public List<HealthPlan> healthPlans;
        @AuraEnabled public String nameLabel;
        @AuraEnabled public String groupNameLabel;
        @AuraEnabled public String policyNumberLabel;
        @AuraEnabled public String planStatusLabel;
        @AuraEnabled public String planTypeLabel;
        @AuraEnabled public String rxBinLabel;
        @AuraEnabled public String idLabel;

        public HealthPlansWithLabel(List<PC_Health_Plan__c> hps) {
            //this.healthPlans = hps;
            healthPlans = new List<HealthPlan>();
            idLabel = PC_Health_Plan__c.ID.getDescribe().getLabel();
            nameLabel = PC_Health_Plan__c.Name.getDescribe().getLabel();
            groupNameLabel = PC_Health_Plan__c.PC_Group_name__c.getDescribe().getLabel();
            policyNumberLabel = PC_Health_Plan__c.ID_Policy_No__c.getDescribe().getLabel();
            planStatusLabel = PC_Health_Plan__c.PC_Plan_Status__c.getDescribe().getLabel();
            planTypeLabel = PC_Health_Plan__c.PC_Plan_Type__c.getDescribe().getLabel();
            rxBinLabel = PC_Health_Plan__c.PC_Rx_Bin__c.getDescribe().getLabel();

            HealthPlan healthPlan;
            for(PC_Health_Plan__c hp : hps) {
                healthPlan = new HealthPlan();
                healthPlan.Id = hp.Id;
                healthPlan.Name = hp.Name;
                healthPlan.groupName = hp.PC_Group_name__c;
                healthPlan.policyNumber = hp.ID_Policy_No__c;
                healthPlan.planStatus = hp.PC_Plan_Status__c;
                healthPlan.planType = hp.PC_Plan_Type__c;
                healthPlan.rxBin = hp.PC_Rx_Bin__c;
                healthPlans.add(healthPlan);
            }

        }
    }

    public inherited sharing class HealthPlan {
        @AuraEnabled public String Name;
        @AuraEnabled public String groupName;
        @AuraEnabled public String policyNumber;
        @AuraEnabled public String planStatus;
        @AuraEnabled public String planType;
        @AuraEnabled public String rxBin;
        @AuraEnabled public String Id;
    }

    @AuraEnabled
    public static PC_eBenefits.PharmacyCardRequest getPharmacyCardholderInfo(string caseId) { //todo move all the implementation to utility name-> getPharmacyCardService
        try {
            PC_eBenefits.PharmacyCard handler = PC_eBenefits.getPharmacyCardService();
            PC_eBenefits.PharmacyCardRequest request = handler.createPharmacyCardRequest();
            PC_eBenefits_Utility.updatePharmacyCardRequest(caseId, request);
            system.debug('patient Info - ' + JSON.serialize(request));
            return request;
        }
        catch (AuraHandledException ex) {
            PC_Utility.publishErrorLog(ex,ex.getMessage());
            PC_Utility.throwAuraHandledException(ex.getMessage());
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }



    @AuraEnabled
    public static PC_eBenefits.PharmacyCardResponse getPharmacyCardLookupResponse(String caseId, String requestObjJSONString) {
        try {
            PC_eBenefits.PharmacyCardRequest request = (PC_eBenefits.PharmacyCardRequest) JSON.deserialize(requestObjJSONString, PC_eBenefits.PharmacyCardRequest.class);
            system.debug(JSON.serialize(request));
            PC_eBenefits.PharmacyCard handler = PC_eBenefits.getPharmacyCardService();
            PC_eBenefits.PharmacyCardResponse response = handler.lookupPharmacyCard(request);
            system.debug('response - ' + JSON.serialize(response));
            if(!response.isSuccess) {
                return null;
            }
            return response;
        }
        catch(Exception ex) {
            PC_Utility.publishErrorLog(ex,ex.getMessage());
            PC_Utility.throwAuraHandledException(ex.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static PC_Health_Plan__c savePharmaCard(String caseId, String requestObjJSONString, String responseObjJSONString) {
        try {
            PC_eBenefits.PharmacyCardRequest request = (PC_eBenefits.PharmacyCardRequest) JSON.deserializeStrict(requestObjJSONString, PC_eBenefits.PharmacyCardRequest.class);
            system.debug(JSON.serialize(request));
            PC_eBenefits.PharmacyCardResponse response = (PC_eBenefits.PharmacyCardResponse) JSON.deserializeStrict(responseObjJSONString, PC_eBenefits.PharmacyCardResponse.class);
            system.debug(JSON.serialize(response));
            PC_eBenefits.PharmacyCard handler = PC_eBenefits.getPharmacyCardService();
            PC_Health_Plan__c healthPlan = new PC_Health_Plan__c();

            //CRUD/FLS Check for case
            List<String> caseFields = new List<String>{'AccountId'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);

            Case currentCase = [Select AccountId from Case where id=:caseId];
            healthPlan.Patient__c = currentCase.AccountId;

            handler.updateHealthPlan(response, healthPlan);
            sObject insertedHealthPlans = PC_Database.ins(healthPlan, true);
            return (PC_Health_Plan__c)insertedHealthPlans;
        }
        catch(Exception ex) {
            PC_Utility.publishErrorLog(ex,ex.getMessage());
            PC_Utility.throwAuraHandledException(ex.getMessage());
        }
        return null;
    }




}