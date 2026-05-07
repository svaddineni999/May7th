/**********************************************************************************************************************************************
Class Name      : PC_SetMessagePreviousStatusHandler
Description     : Trigger on Message object that sets the Previous Status with the value available in the Status field before update.
Created By      : Chetna Mohapatra
Created Date    : May 5, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra          May 5, 2021           Initial Version
Satheesh Kumar            Nov 16, 2021          [PC-8213] Excluded FLS Check and added inherited sharing
************************************************************************************************************************************************/
 public inherited sharing class PC_SetMessagePreviousStatusHandler extends PC_TriggerHandler {
 //This class runs under Trigger context and hence 'with sharing' is not provided.
    override public void beforeUpdate(){
        assignPreviousStatus((List<PC_Message__c >) newList, (Map<Id, PC_Message__c>) oldMap);
    }
    /*********************************************************************************
    Method Name    : assignPreviousStatus
    Author         : Chetna Mohapatra
    Description    : This method is to assign value to message previous status
    Return Type    : void
    Parameter      : List of incoming message records - Trigger.new
    *********************************************************************************/
     private void assignPreviousStatus(List<PC_Message__c> messages, Map<Id,PC_Message__c> oldMap) {
        for (PC_Message__c msg : messages) {
            if (oldMap.get(msg.Id).PC_Type__c == PC_Constants.OUTBOUND) {
                msg.PC_MessagePreviousStatus__c = oldMap.get(msg.Id).PC_Message_Status__c;
            }
        }
     }

 }