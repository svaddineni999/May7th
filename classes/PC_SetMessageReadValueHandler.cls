/**********************************************************************************************************************************************
Class Name      : PC_SetMessageReadValueHandler
Description     : Trigger on Message object that sets Message Read field value for an Outbound message only after its status changes to Delivered.
Created By      : Chetna Mohapatra
Created Date    : Oct 25, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra          Oct 25, 2021           Initial Version
Satheesh Kumar            Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
************************************************************************************************************************************************/
public inherited sharing class PC_SetMessageReadValueHandler extends PC_TriggerHandler {
    //This class runs under Trigger context and hence 'with sharing' is not provided.
    override public void beforeUpdate(){
        setMessageReadValue((List<PC_Message__c >) newList);
    }
    /******************************************************************************************************
    Method Name    : setMessageReadValue
    Author         : Chetna Mohapatra
    Description    : This method is to set the Message Read field value for an Outbound message only after
                     its status changes to Delivered.
    Return Type    : void
    Parameter      : List of new Message records- messages
    *******************************************************************************************************/
    private void setMessageReadValue(List<PC_Message__c> messages) {
        for (PC_Message__c msg : messages) {
            if (msg.PC_Type__c == PC_Constants.OUTBOUND && msg.PC_Message_Status__c== PC_SMS.PC_SMS_DELIVERED) {
                msg.PC_Message_Read__c = true;
            }
        }
    }

}