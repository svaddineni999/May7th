/**************************************************************************************************************************************************************************
Class Name      : PC_SPPharmacyBIController
Description     : This is the SP Automation Task Component Controller For Pharmacy BI.
Created By      : Satheesh Kumar & Chetna Mohapatra
Created Date    : 25-Feb-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra
& Satheesh Kumar        25-Feb-2022             Initial Version
Satheesh Kumar          12-Oct-2022             [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
 **********************************************************************************************************************************************************************/
public with sharing class PC_SPPharmacyBIController {
    static final List<String> PHARMACY_BI_SUPPORTED_OBJECT = new List<String>{'CASE', 'ACCOUNT','PC_CASEPRODUCT__C'};

    @AuraEnabled
    public static PharmacyBenefitsInfo getPharmacyInfo(String supportPlanId){
        PharmacyBenefitsInfo pharmacyBenefitsInfo = new PharmacyBenefitsInfo();
        try{
            // FLS Check for Support Plan
            List<String> supportPlanFields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan_Behavior__c') };
            PC_Database.assertAccess(PC_Constants.PC_SUPPORT_PLAN, PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT Id, PC_TriggerEventObject__c, PC_SupportPlan_Behavior__c FROM PC_SupportPlan__c WHERE Id = :supportPlanId][0];
            String triggerEventObjectName = supportPlan.PC_TriggerEventObject__c;
            //remove namespace prefix from triggerEventObjectName when triggerEventObjectName contains namespace
            triggerEventObjectName = triggerEventObjectName.contains('__') ? (triggerEventObjectName.countMatches('__') == 2 ? triggerEventObjectName.substringAfter('__') : triggerEventObjectName): triggerEventObjectName;

            if (String.isNotBlank(triggerEventObjectName) && PHARMACY_BI_SUPPORTED_OBJECT.contains(triggerEventObjectName.toUpperCase())) {
                pharmacyBenefitsInfo.isValidTriggerEventObject = PC_Constants.TRUE_BOOLEAN;
            } else {
                pharmacyBenefitsInfo.isValidTriggerEventObject = PC_Constants.FALSE_BOOLEAN;
                pharmacyBenefitsInfo.notSupportErrorMessage = String.format(System.Label.PC_SPPharmacyeBIUnsupportedErrorMessage, new List<Object>{triggerEventObjectName, String.join( PHARMACY_BI_SUPPORTED_OBJECT, ', ' )});
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return pharmacyBenefitsInfo;
    }

    public inherited sharing class PharmacyBenefitsInfo {
        @AuraEnabled
        public Boolean isValidTriggerEventObject { get; set; }
        @AuraEnabled
        public String notSupportErrorMessage { get; set; }
        public PharmacyBenefitsInfo() {
            isValidTriggerEventObject = PC_Constants.FALSE_BOOLEAN;
            notSupportErrorMessage = PC_Constants.EMPTY_STRING;
        }
    }
}