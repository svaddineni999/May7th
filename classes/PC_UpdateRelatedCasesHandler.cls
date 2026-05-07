/*********************************************************************************************************
Class Name      : PC_UpdateRelatedCases 
Description     : trigger on Account object update the realted cases on updation of Accounts
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel            		Jan 4, 2018        		Initial Version
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_UpdateRelatedCasesHandler extends PC_TriggerHandler{
 	override public void afterUpdate(){
        updateRelatedCases((Map<Id, Account>) oldMap, (List<Account>) newList);
    }
    
    /*********************************************************************************
    Method Name    : updateRelatedCases
    Author         : Vasile Paraschiv
    Description    : Fire the update on cases related to accounts when the account name was modified
    Return Type    : void
    Parameter      : oldMap, newList              
    *********************************************************************************/
    private void updateRelatedCases(Map<Id, Account> oldMap, List<Account> newList){
        List <Id> modifiedAccountIds = new List <Id>();
        List <Case> casesToUpdate = new List <Case>();

        try {
            for(Account accountObj : newList) {
                if(accountObj.Id != null && (oldMap != null && oldMap.containsKey(accountObj.Id))) {
                    Account oldAccountObj = oldMap.get(accountObj.Id);
                    if (accountObj.PC_First_Name__c != oldAccountObj.PC_First_Name__c || accountObj.PC_Last_Name__c != oldAccountObj.PC_Last_Name__c){
                        modifiedAccountIds.add(accountObj.Id);
                    }
                }
            }
            if (modifiedAccountIds.size() > 0) {
                casesToUpdate = getRelatedCases(modifiedAccountIds);
            }
            if (casesToUpdate.size() > 0) {
                casesToUpdate = (List<Case>)PC_Database.upd(casesToUpdate, false);
            }
        } catch(Exception ex) {
                PC_Utility.createExceptionLog(ex);
        }
    }
    
    /*********************************************************************************
    Method Name    : getRelatedCases
    Author         : Vasile Paraschiv
    Description    : Get a list of cases related to the account ids
    Return Type    : List<Case>
    Parameter      : List <Id> accountIds         
    *********************************************************************************/
    private List<Case> getRelatedCases(List <Id> accountIds) {
        return [SELECT Id FROM Case WHERE accountId IN :accountIds];
    }
}