/*********************************************************************************************************
Class Name      : PC_UpdateAccountNameHandler
Description     : trigger on Account object to update Account name before Insert and Update
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel                 Jan 4, 2018             Initial Version
Vijay Kashikar              Nov 29, 2018            [PC-3649] Added a condition to see if the accounts are patient connect individual accounts
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora               Jun 26, 2019            [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Satheesh Kumar             Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_UpdateAccountNameHandler extends PC_TriggerHandler {
    override public void beforeInsert(){
       updateAccountName((List<Account>) newList);
    }

    override public void beforeUpdate(){
        updateAccountName((List<Account>) newList);  
    }
    
    /*********************************************************************************
    Method Name    : updateAccountName
    Author         : Prachi Nandgaonkar 
    Description    : This method  updates Account Name field on account with Account Last Name and Account First Name PC-475
    Return Type    : void
    Parameter      : List of incoming account records - Trigger.new              
    *********************************************************************************/
    private void updateAccountName(List<Account> accounts) {
        List<Account> accountsToUpdate = new List<Account>();

        //Map<String, String> recordTypeKeyValueWrappers;
        for (Account a : accounts) {

            if (a.PC_Individual_Type__c == 'Individual' &&
                    String.isNotBlank(a.PC_First_Name__c) && String.isNotBlank(a.PC_Last_Name__c ))
            {
                //recordTypeKeyValueWrappers = PC_SYSTEM.recordTypeDeveloperNameAndNamespaceById(a.RecordTypeId);

                    a.Name = a.PC_Last_Name__c + ', ' + a.PC_First_Name__c;
                    accountsToUpdate.add(a);

            }else {
                accountsToUpdate.add(a);
            }
        }
    }    
}