/*********************************************************************************************************
Trigger Name    : PC_Trigger_HealthPlan
Description     : controller that manages Health Plan trigger activities
Created By      : Deloitte
Created Date    : May 30, 2016
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Roxana Ivan                    June 2, 2016          Initial Version
Shabda Bhujad,         		   Nov 3, 2016			 Removed references to 'Relationship to Cardholder' - annotated by @@RemoveRelTOCardHolder
Prachi Nandgaonkar
Prachi Nandgaonkar             Feb 17, 2017          Updated processSelfRelationship() to add a conditional check
Ajinkya Deshmukh			   Jun 23, 2017			 FLS Check Added (Code Merge)
Shabda Bhujad                  Nov 14, 2017          PC-2485 Removing the reference to trigger state
Shabda Bhujad                  Dec 14, 2017          PC-1884 Logical breakdown of the trigger handlers
Xiukai Ning                    Feb 28, 2019          PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                     Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                     We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                 Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_UpdateHPFieldsForSelfRelationHandler extends PC_TriggerHandler {
    override public void beforeInsertUpdate(){
        processSelfRelationship(newList, (Map<Id, PC_Health_Plan__c>)oldMap);
    }

    /*********************************************************************************
    Method Name    : processSelfRelationship
    Author         : Roxana Ivan
    Description    : This method  processes self service
    Return Type    : void
    Parameter      : List of incoming account records - Trigger.new
    *********************************************************************************/
    private void processSelfRelationship(List<PC_Health_Plan__c> newHealthPlans, Map<Id, PC_Health_Plan__c> oldHealthPlans) {
        Set<Id> patientIds = new Set<Id>();
        Map<Id, Account> patients = new Map<Id, Account>();

        List<PC_Health_Plan__c> healthPlansToUpdate = new List<PC_Health_Plan__c>();
        for (PC_Health_Plan__c healthPlan : newHealthPlans) {
            if (healthPlan.PC_Cardholder_Relationship_to_Patient__c == PC_Constants.SELF && healthPlan.Patient__c != null
                    &&  (oldHealthPlans == null || oldHealthPlans.get(healthPlan.Id).Patient__c != healthPlan.Patient__c || oldHealthPlans.get(healthPlan.Id).PC_Cardholder_Relationship_to_Patient__c != healthPlan.PC_Cardholder_Relationship_to_Patient__c)) {
                healthPlansToUpdate.add(healthPlan);
                patientIds.add(healthPlan.Patient__c);
            }
        }
        patients = new Map<Id, Account>([SELECT Id, PC_First_Name__c, PC_Last_Name__c, PC_Date_of_Birth__c
        FROM Account
        WHERE Id
                IN: patientIds]);
        if(healthPlansToUpdate.size() > 0 ){
            for (PC_Health_Plan__c newHealthPlan : healthPlansToUpdate) {
                if(patients.containsKey(newHealthPlan.Patient__c)) {
                    Account patient = patients.get(newHealthPlan.Patient__c);
                    newHealthPlan.PC_Cardholder_s_Date_of_Birth__c = patient.PC_Date_of_Birth__c;
                    newHealthPlan.PC_Card_Holder_Name__c = patient.PC_First_Name__c + ' ' + patient.PC_Last_Name__c;
                }
            }
        }
    }

}