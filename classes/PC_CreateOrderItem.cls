/*********************************************************************************************************
Trigger Name    : PC_CreateOrderItem
Description     : Trigger handler class on Order Object to create OrderItem if Prescription field is populated.
Created By      : Deloitte
Created Date    : Aug 5, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore                 Aug 5, 2019            Initial Version
Vijay Kashikar                  21-Jan-21              [PC-7102] Added FLS Checks
Hitha Avalakki                  25-May-2021            [PC-7545]: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Satheesh Kumar                  Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_CreateOrderItem extends PC_TriggerHandler {

    override public void afterInsert(){
        createOrderItem((List<PC_Order__c>)newList);
    }

    /*********************************************************************************
    Method Name    : checkPatientRecType
    Author         : Kanteti Kishore
    Description    : This method checks whether the record type for patient lookup is of patient or not.
    Return Type    : void
    Parameter      : List of incoming Pharmacy Referral records - Trigger.new
    *********************************************************************************/
    private void createOrderItem(List<PC_Order__c> orders) {
        try {
            Map<Id,PC_Order__c> ordersToUpdate = new Map<Id,PC_Order__c>();
            Map<Id,Id> orderPrescription = new Map<Id,Id>();
            Set<Id> prescriptionSet = new Set<Id>();
            List<Id> prescriptionList = new List<Id>();

            List<PC_OrderItem__c> orderItemList       = new List<PC_OrderItem__c>();

            //Get the list and map of Orders with Prescription and set of all Prescriptions
            for(PC_Order__c o : orders){
                if(o.PC_Prescription__c != Null){
                    ordersToUpdate.put(o.Id,o);
                    orderPrescription.put(o.Id,o.PC_Prescription__c);
                    prescriptionSet.add(o.PC_Prescription__c);
                }
            }

            //fetch all the Product id's of the Prescription records
            prescriptionList.addAll(prescriptionSet);
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /* List<String> prescriptionFields = new List<String>();
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__c'));
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Requested_Quantity__c'));
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Days_Supply__c'));
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),PC_Database.Operation.Reading, prescriptionFields);*/

            Map<Id,PC_Prescription__c> fetchPrescriptions = new Map<Id,PC_Prescription__c>([SELECT ID, PC_Product__c, PC_Requested_Quantity__c, PC_Days_Supply__c FROM PC_Prescription__c where Id in :prescriptionList]);
            //Loop through the Orders with prescription and create order Item if Product Id available.
            for(Id oId : orderPrescription.keySet()){
                Id prescriptionId               =  orderPrescription.get(oId);
                PC_Prescription__c prescription = fetchPrescriptions.get(prescriptionId);

                if(prescription.PC_Product__c != Null){
                    PC_OrderItem__c orderItem       = new PC_OrderItem__c();
                    orderItem.PC_Product__c         = prescription.PC_Product__c;
                    orderItem.PC_Order__c           = oId;
                    orderItem.PC_DaysSupply__c      = prescription.PC_Days_Supply__c;
                    orderItem.PC_Quantity__c        = prescription.PC_Requested_Quantity__c;
                    orderItemList.add(orderItem);
                }
            }
            PC_Database.ins(orderItemList, false);
        }catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
    }
}