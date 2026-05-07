/**********************************************************************************************************************************************
Class Name      : PC_SetMessageNameHandler
Description     : Trigger on Message object that overwrites the value of Message Name .
Created By      : Chetna Mohapatra
Created Date    : Jul 5, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra          Jul 5, 2021           Initial Version
Chetna Mohapatra          Aug 24,2021           [PC-8086]Null check added for recipientName value prior to the assignment of Message Name field value.
Satheesh Kumar            Nov 16, 2021          [PC-8213] Excluded FLS Check and added inherited sharing
************************************************************************************************************************************************/
public inherited sharing class PC_SetMessageNameHandler extends PC_TriggerHandler {
    //This class runs under Trigger context and hence 'with sharing' is not provided.
    override public void beforeInsert(){
        assignMessageName((List<PC_Message__c >) newList);
        System.debug('Messages in New List--' +newList);
    }
    /*********************************************************************************
    Method Name    : assignMessageName
    Author         : Chetna Mohapatra
    Description    : This method is to overwrite the value of message name field
    Return Type    : void
    *********************************************************************************/
    private void assignMessageName(List<PC_Message__c> messages) {
        String recipientName;
        String externalRecipientLabel= System.label.PC_ExternalRecipientLabel;
        Account recAccount= new Account();
        User recUser= new User();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds= new Set<Id>();
        for (PC_Message__c msg : messages) {
            if(msg.PC_ReceiverAccount__c != null && msg.PC_ReceiverUser__c == null){
                accountIds.add(msg.PC_ReceiverAccount__c);
            }else if(msg.PC_ReceiverAccount__c == null && msg.PC_ReceiverUser__c != null){
                userIds.add(msg.PC_ReceiverUser__c);
            }
        }
        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*// FLS Check
        List<String> accountFields = new List<String>{'Id', 'Name'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields);*/
        //Query and store the account details in a Map
        Map<Id, Account> accountMap= new Map<Id, Account>([SELECT Id,Name FROM Account WHERE ID IN: accountIds]);
        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*// FLS Check
        List<String> userFields = new List<String>{'Id', 'Name'};
        PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading, userFields); */
        //Query and store the user details in a Map
        Map<Id, User> userMap= new Map<Id, User>([SELECT Id,Name FROM User WHERE ID IN: userIds]);

        for (PC_Message__c msg : messages) {
            if(msg.PC_ReceiverUser__c == null && msg.PC_ReceiverAccount__c != null){
                if(accountMap.containsKey(msg.PC_ReceiverAccount__c)){
                    recAccount = accountMap.get(msg.PC_ReceiverAccount__c);
                    if (recAccount.Name != null) {
                        recipientName = recAccount.Name;
                    }
                }
            } else if(msg.PC_ReceiverAccount__c == null && msg.PC_ReceiverUser__c != null){
                if(userMap.containsKey(msg.PC_ReceiverUser__c)) {
                    recUser = userMap.get(msg.PC_ReceiverUser__c);
                    if (recUser.Name != null) {
                        recipientName = recUser.Name;
                    }
                }
            } else{
                if(msg.PC_ExternalRecipientName__c != null) {
                    if(String.isNotBlank(externalRecipientLabel)) {
                        recipientName = msg.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                    }else{
                        recipientName = msg.PC_ExternalRecipientName__c + externalRecipientLabel;
                    }
                }
            }
            if(msg.Name == null && recipientName!= null) {
                msg.Name = System.Label.PC_MessageNameLabel + ' ' + recipientName;
            }
        }
    }

}