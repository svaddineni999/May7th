/*********************************************************************************************************
Trigger Name    : PC_SetAddressFields
Description     : trigger on PC_Address__c object.
Created By      : Tetiana Danylyshyn
Created Date    : May 17, 2016
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tetiana Danylyshyn             	May 17, 2016          	Initial Version
Alina Balan                    	July 11, 2016         	Added "updatePrimaryAddressOnAccount" method
Shabda Bhujad					Dec 05, 2016			Added FLS check to updatePrimaryAddressOnAccount,updatePrimaryAddress methods
Ajinkya Deshmukh				June 07, 2017			FLS Check Added
Mayuresh Patil                  July 26, 2017           Updated comments for FLS/CRUD checks
Mayuresh Patil                  Nov 1, 2017             Removed google map API to be replaced by salesforce geocoding
Shabda Bhujad                   Nov 14, 2017            PC-2485 Removing the reference to trigger state
Shabda Bhujad                   Dec 18, 2017            PC-1884 Logical breakdown of the trigger handlers
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_SetAddressFieldsHandler extends PC_TriggerHandler {

    override public void beforeInsert() {
        setAddressFields(newList);
    }

    override public void beforeInsertUpdate() {
        processUpdate((List<PC_Address__c>) newList, (Map<Id, PC_Address__c>) oldMap);
    }
    private void setAddressFields(List<PC_Address__c> addresses) {
        for (PC_Address__c a : addresses) {
            //set status if none was set already
            if (a.PC_Status__c != PC_Constants.ACTIVE && a.PC_Status__c != PC_Constants.INACTIVE) {
                a.PC_Status__c = PC_Constants.ACTIVE;
            }
            //set start date
            if (a.PC_Start_Date__c == null) {
                a.PC_Start_Date__c = Date.today();
            }
        }
    }

    private void processUpdate(List<PC_Address__c> newList, Map<Id, PC_Address__c> oldMap) {
        List<PC_Address__c> addressesToUpdate = new List<PC_Address__c> ();
        for (PC_Address__c addressObj : newList) {
            if (addressObj.Id != null && (oldMap != null && oldMap.containsKey(addressObj.Id))) {
                PC_Address__c oldAddressObj = oldMap.get(addressObj.Id);
                if (addressObj.PC_Status__c == PC_Constants.INACTIVE && addressObj.PC_End_Date__c > Date.today()) {
                    addressObj.PC_End_Date__c = Date.today();

                }
                if (addressObj.PC_End_Date__c < Date.today() && oldAddressObj.PC_End_Date__c != addressObj.PC_End_Date__c) {
                    addressObj.PC_Status__c = PC_Constants.INACTIVE;
                }
            }
        }
    }
}