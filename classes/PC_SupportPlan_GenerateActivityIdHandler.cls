/*********************************************************************************************************
Class Name      : PC_SupportPlan_GenerateActivityIdHandler
Description     : Trigger handler on Support Plan Activity to generate a unique internal activity number
Created By      : Prachi Nandgaonkar
Created Date    : March 6, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar          March 6, 2018            Initial Version
Tejas Patel                 Feb 20, 2019             PC-4480 Trigger will run for blank PC_InternalActivityNumber__c, usefull during migartion
Xiukai Ning                 Feb 28, 2019             PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                     Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                     We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_SupportPlan_GenerateActivityIdHandler extends PC_TriggerHandler{
		
    override public void afterInsert() {
        	generateIntActivityNum();
    }
    
   
    /*********************************************************************************
    Method Name    : generateIntActivityNum
    Author         : Prachi Nandgaonkar
    Description    : Creates unique Internal Activity Number for all Support Plan Activities
    Return Type    : void
    Parameter      : newList              
    *********************************************************************************/
    private void generateIntActivityNum(){
        List<PC_SupportPlanActivity__c> lstActivity = [SELECT Id, PC_InternalActivityNumber__c 
                                                       FROM PC_SupportPlanActivity__c
                                                       WHERE Id IN :Trigger.newMap.keySet()];
        List<PC_SupportPlanActivity__c> lstActivityToUpd = new List<PC_SupportPlanActivity__c>();
        try{
            If(!lstActivity.isEmpty()){
                for(PC_SupportPlanActivity__c a: lstActivity){
                    if(String.isBlank(a.PC_InternalActivityNumber__c)){
                        a.PC_InternalActivityNumber__c = a.Id; //Copy Salesforce record id
                        lstActivityToUpd.add(a);
                    }
                }
            }
            if(!lstActivityToUpd.isEmpty()){
                PC_Database.upd(lstActivityToUpd, false);
            }
        }catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }
}