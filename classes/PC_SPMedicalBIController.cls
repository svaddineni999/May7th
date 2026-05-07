/**************************************************************************************************************************************************************************
Class Name      : PC_SPMedicalBIController
Description     : This is the SP Automation Task Component Controller For Medical BI.
Created By      : Chetna Mohapatra
Created Date    : 25-Mar-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra        25-Mar-2022             Initial Version
Satheesh Kumar          12-Oct-2022             [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
 **********************************************************************************************************************************************************************/
public with sharing class PC_SPMedicalBIController {
    static final List<String> MEDICAL_BI_SUPPORTED_OBJECT = new List<String>{'CASE', 'ACCOUNT','PC_CASEPRODUCT__C'};

    @AuraEnabled
    public static MedicalBenefitsInfo getMedicalBIInfo(String supportPlanId){
        MedicalBenefitsInfo medicalBenefitsInfo = new MedicalBenefitsInfo();
        try{
            // FLS Check for Support Plan
            List<String> supportPlanFields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan_Behavior__c') };
            PC_Database.assertAccess(PC_Constants.PC_SUPPORT_PLAN, PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT Id, PC_TriggerEventObject__c, PC_SupportPlan_Behavior__c FROM PC_SupportPlan__c WHERE Id = :supportPlanId][0];
            String triggerEventObjectName = supportPlan.PC_TriggerEventObject__c;
            //remove namespace prefix from triggerEventObjectName when triggerEventObjectName contains namespace
            triggerEventObjectName = triggerEventObjectName.contains('__') ? (triggerEventObjectName.countMatches('__') == 2 ? triggerEventObjectName.substringAfter('__') : triggerEventObjectName): triggerEventObjectName;
            if (String.isNotBlank(triggerEventObjectName) && MEDICAL_BI_SUPPORTED_OBJECT.contains(triggerEventObjectName.toUpperCase())) {
                medicalBenefitsInfo.isValidTriggerEventObject = PC_Constants.TRUE_BOOLEAN;
            } else {
                medicalBenefitsInfo.isValidTriggerEventObject = PC_Constants.FALSE_BOOLEAN;
                medicalBenefitsInfo.notSupportErrorMessage = String.format(System.Label.PC_SPPharmacyeBIUnsupportedErrorMessage, new List<Object>{triggerEventObjectName, String.join( MEDICAL_BI_SUPPORTED_OBJECT, ', ' )});
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return medicalBenefitsInfo;
    }

    public inherited sharing class MedicalBenefitsInfo {
        @AuraEnabled
        public Boolean isValidTriggerEventObject { get; set; }
        @AuraEnabled
        public String notSupportErrorMessage { get; set; }
        public MedicalBenefitsInfo() {
            isValidTriggerEventObject = PC_Constants.FALSE_BOOLEAN;
            notSupportErrorMessage = PC_Constants.EMPTY_STRING;
        }
    }
}