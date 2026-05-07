/*********************************************************************************
Class Name      : PC_SupportPlan_CloneController
Description     : Clones the Support Plan and Corresponding Activities
Created By      : Tejas Patel
Created Date    : 19-Feb-2019
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tejas Patel          19-Feb-2019                   Initial Version
Tejas Patel          20-Feb-2019                   PC-4470 Error Handling
Tejas Patel          26-Feb-2019                   Error Handling DML exception
Haritha Reddy        17-Dec-2019                   [PC-5791] Added error handling for getFieldLabels method &
                                                    replaced references of createExceptionLog with logAndThrowException
Kanteti Kishore      16-Apr-2020                   [PC-6191] Added fields in support plan query for cloning.
Vijay Kashikar       21-Jan-2021                    [PC-7102] Added sharing clause
*/
public with sharing class PC_SupportPlan_CloneController {
    /*********************************************************************************
      Method Name    : cloneSupportPlan
      Author         : Tejas Patel
      Description    : This method Clones the Original SP
      Return Type    : cloneSupportPlanResponse
      Parameter      : recordId of Orginal SP
     *********************************************************************************/
    @AuraEnabled
    public static cloneSupportPlanResponse cloneSupportPlan(Id recordId, String clonedSPName){
        Id clonedSPId;
        PC_SupportPlan__c originalSP;
        PC_SupportPlan__c clonedSP;
        Set<Id> clonedSPIdList = new Set<Id>();
        Map<Id,Id> originalToClonedIdMap = new Map<Id,Id>();
        List<PC_SupportPlanActivity__c> clonedSupportActivity = new List<PC_SupportPlanActivity__c>();
        List<PC_SupportPlanActivity__c> retrieveClonedSupportActivity = new List<PC_SupportPlanActivity__c>();
        List<PC_SupportPlanActivity__c> updSupportActivity = new List<PC_SupportPlanActivity__c>();
        cloneSupportPlanResponse returnClonedSP;
        try{
            originalSP  = [SELECT Id, Name, PC_ConditionBehavior__c, PC_Description__c, PC_InitialActivity__c, PC_IsActive__c, PC_StartCondition__c,
                    PC_Version__c,PC_SupportPlan_Behavior__c ,PC_Conditional_Logic__c, PC_Condition_Option__c,PC_TriggerEventType__c,PC_TriggerEventObject__c,PC_TriggerEventCondition__c,
                    PC_TriggerEventConditionOption__c,PC_TriggerEventConditionalBehavior__c from PC_SupportPlan__c Where Id = :recordId];
            clonedSP                = originalSP.clone(false, true, false, false); //Deep Clone the SP
            clonedSP.Name           = clonedSPName; //Update the Name
            clonedSP.PC_IsActive__c = false; // Deactivate the SP
            clonedSP                = (PC_SupportPlan__c) PC_Database.ins(clonedSP);
            clonedSPId              = clonedSP.Id;

            List<PC_SupportPlanActivity__c> supportActivity = [SELECT Id, Name, PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                    PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c,PC_InternalActivityNumber__c,
                    PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_SubType__c,PC_ActionClass__c, PC_Operators__c,
                    PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_AutomationTaskJSON__c, PC_ClonedFrom__c, PC_GroupActivityExecution__c
            FROM PC_SupportPlanActivity__c WHERE PC_SupportPlan__c =: recordId];

            for(PC_SupportPlanActivity__c spAct : supportActivity){
                PC_SupportPlanActivity__c cloneSPAct    = spAct.clone(false, true, false, false);
                cloneSPAct.PC_SupportPlan__c            = clonedSPId; // Update to the new SP
                cloneSPAct.PC_ClonedFrom__c             = spAct.PC_InternalActivityNumber__c; //Place holder for the internal Id
                cloneSPAct.PC_InternalActivityNumber__c = PC_Constants.EMPTY_STRING; // need to clear, due to unique constraint
                clonedSupportActivity.add(cloneSPAct);
            }
            if(!clonedSupportActivity.isEmpty()){
                clonedSupportActivity = (List<PC_SupportPlanActivity__c>)PC_Database.ins(clonedSupportActivity);
                for( PC_SupportPlanActivity__c s : clonedSupportActivity){
                    clonedSPIdList.add(s.Id) ;
                }
            }

            if(!clonedSupportActivity.isEmpty()){ //Need to Query again to get the new PC_InternalActivityNumber__c; after insert trigger
                retrieveClonedSupportActivity = [SELECT Id, PC_InternalActivityNumber__c, PC_ClonedFrom__c, PC_ActivitySequence__c, PC_AlternateActivity__c,
                        PC_InitialSequenceActivity__c,  PC_NextActivityNumber__c FROM PC_SupportPlanActivity__c WHERE Id IN : clonedSPIdList];
            }

            for(PC_SupportPlanActivity__c spActMap : retrieveClonedSupportActivity){//Create a map from the old to new ids.
                originalToClonedIdMap.put(spActMap.PC_ClonedFrom__c,spActMap.PC_InternalActivityNumber__c);
            }

            for(PC_SupportPlanActivity__c spAct : retrieveClonedSupportActivity){//Update the ids
                PC_SupportPlanActivity__c spActMap = new PC_SupportPlanActivity__c();
                spActMap.Id                             =  spAct.Id;
                spActMap.PC_ActivitySequence__c         =  originalToClonedIdMap.get(spAct.PC_ActivitySequence__c);
                spActMap.PC_AlternateActivity__c        =  originalToClonedIdMap.get(spAct.PC_AlternateActivity__c);
                spActMap.PC_InitialSequenceActivity__c  =  originalToClonedIdMap.get(spAct.PC_InitialSequenceActivity__c);
                spActMap.PC_NextActivityNumber__c       =  originalToClonedIdMap.get(spAct.PC_NextActivityNumber__c);
                updSupportActivity.add(spActMap);
            }

            clonedSP.PC_InitialActivity__c = originalToClonedIdMap.get(clonedSP.PC_InitialActivity__c);
            PC_Database.upd(clonedSP);

            if(!updSupportActivity.isEmpty()){
                updSupportActivity = (List<PC_SupportPlanActivity__c>)PC_Database.upd(updSupportActivity);
            }
            returnClonedSP          = new cloneSupportPlanResponse(clonedSPId);
        }catch (System.DmlException dmlex){
            returnClonedSP = new cloneSupportPlanResponse(dmlex);
            PC_Utility.createExceptionLog(dmlex);
        }catch (Exception ex){
            returnClonedSP = new cloneSupportPlanResponse(ex);
            PC_Utility.createExceptionLog(ex);
        }
        return returnClonedSP;
    }

    /*********************************************************************************
      Method Name    : cloneSupportPlan
      Author         : Tejas Patel
      Description    : This method Clones the Original SP
      Return Type    : cloneSupportPlanResponse
      Parameter      : recordId of Orginal SP
     *********************************************************************************/
    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 					= new FieldLabels();
        try {
            fieldlabels.supportPlanName = PC_SupportPlan__c.Name.getDescribe().getLabel();
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return fieldlabels;
    }

    public inherited sharing class FieldLabels {
        //Support Plan Fields
        @AuraEnabled public String supportPlanName { get; set; }

        public FieldLabels() {
        }
    }

    public inherited sharing class cloneSupportPlanResponse {
        @AuraEnabled public Boolean exceptionFlag {get; set;}
        @AuraEnabled public Id clonedSupportPlanId {get; set;}
        @AuraEnabled public List<String> exceptionMessage {get; set;}
        @AuraEnabled public String exceptionType {get; set;}

        public cloneSupportPlanResponse(System.DmlException dmlex) {
            exceptionFlag       = true;
            clonedSupportPlanId = null;
            exceptionMessage    = new List<String>();
            for(Integer i=0; i<dmlex.getNumDml(); i++){
                String dmlMsg = dmlex.getDmlMessage(i);
                exceptionMessage.add(dmlMsg);
            }
            exceptionType       = dmlex.getTypeName();
        }

        public cloneSupportPlanResponse(Exception ex) {
            exceptionFlag       = true;
            clonedSupportPlanId = null;
            exceptionMessage    = new List<String>();
            exceptionMessage.add(ex.getMessage());
            exceptionType       = ex.getTypeName();
        }

        public cloneSupportPlanResponse(Id clonedSPId) {
            exceptionFlag       = false;
            clonedSupportPlanId = clonedSPId;
            exceptionMessage    = null;
            exceptionType       = null;
        }

        public cloneSupportPlanResponse() {}
    }

}