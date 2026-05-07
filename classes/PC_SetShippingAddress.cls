/*********************************************************************************************************
Trigger Name    : PC_SetShippingAddress
Description     : Trigger handler class on Order Object to set Shipping address
Created By      : Deloitte
Created Date    : Jan 11, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel                     Jan 11, 2021            Initial Version
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Hitha Avalakki          25-May-2021             [PC-7545]: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Satheesh Kumar          Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_SetShippingAddress extends PC_TriggerHandler {
    override public void beforeInsert(){
        setShippingDetails((List<PC_Order__c>) newList);
    }

    override public void beforeUpdate(){
        setShippingDetails((Map<Id, PC_Order__c>) newMap, (Map<Id, PC_Order__c>) oldMap, (List<PC_Order__c>) newList);
    }

    /*********************************************************************************
    Method Name    : checkPatientRecType
    Author         : Kanteti Kishore
    Description    : This method checks whether the record type for patient lookup is of patient or not.
    Return Type    : void
    Parameter      : List of incoming Pharmacy Referral records - Trigger.new
    *********************************************************************************/
    private void setShippingDetails(Map<Id, PC_Order__c> newMap, Map<Id, PC_Order__c> oldMap, List<PC_Order__c> newList) {
        try {
            Set<Id> shipToIds = new Set<Id>();
            for(Id i : newMap.keySet()){
                if(String.isNotBlank(String.valueOf(newMap.get(i).PC_ShipTo__c))){
                    if(String.isNotBlank(String.valueOf(oldMap.get(i).PC_ShipTo__c))){
                        if(String.valueOf(newMap.get(i).PC_ShipTo__c) == String.valueOf(oldMap.get(i).PC_ShipTo__c)){
                            //No Change in the Ship To Lookup
                        }else{
                            shipToIds.add(newMap.get(i).PC_ShipTo__c);
                        }
                    }else{
                        shipToIds.add(newMap.get(i).PC_ShipTo__c);
                    }
                }else{
                }
            }

            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /*//FLS check for Account
            List<String> accountFields= new List<String>{PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Address_2__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address_3__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_City__c'),PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading,accountFields); */

            //if(shipToIds.size() != 0){
                Map<Id, Account> accMap = new Map<Id, Account>([Select Id, PC_Primary_Address_1__c, PC_Primary_Address_2__c, PC_Primary_Address_3__c, PC_Primary_City__c, PC_Primary_State__c,
                        PC_Primary_Zip_Code__c From Account Where Id in :shipToIds]);
            //}

            for(PC_Order__c o : newList){
                if(accMap.containsKey(o.PC_ShipTo__c)) {
                    o.PC_OrderAddress1__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Address_1__c;
                    o.PC_OrderAddress2__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Address_2__c;
                    o.PC_OrderAddress3__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Address_3__c;
                    o.PC_OrderAddressCity__c = accMap.get(o.PC_ShipTo__c).PC_Primary_City__c;
                    o.PC_OrderAddressState__c = accMap.get(o.PC_ShipTo__c).PC_Primary_State__c;
                    o.PC_OrderAddressZipCode__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Zip_Code__c;
                }
            }
        }catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
    }

    /*********************************************************************************
    Method Name    : checkPatientRecType
    Author         : Kanteti Kishore
    Description    : This method checks whether the record type for patient lookup is of patient or not.
    Return Type    : void
    Parameter      : List of incoming Pharmacy Referral records - Trigger.new
    *********************************************************************************/
    private void setShippingDetails(List<PC_Order__c> newList) {
        try {
            Set<Id> shipToIds = new Set<Id>();
            for(PC_Order__c o : newList){
                if(String.isNotBlank(String.valueOf(o.PC_ShipTo__c))){
                    shipToIds.add(o.PC_ShipTo__c);
                }
            }

            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /*//FLS check for Account
            List<String> accountFields= new List<String>{PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Address_2__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address_3__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_City__c'),PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading,accountFields); */

            //if(shipToIds.size() != 0){
                Map<Id, Account> accMap = new Map<Id, Account>([Select Id, PC_Primary_Address_1__c, PC_Primary_Address_2__c, PC_Primary_Address_3__c, PC_Primary_City__c, PC_Primary_State__c,
                        PC_Primary_Zip_Code__c From Account Where Id in :shipToIds]);
            //}

            for(PC_Order__c o : newList){
                if(accMap.containsKey(o.PC_ShipTo__c)) {
                    o.PC_OrderAddress1__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Address_1__c;
                    o.PC_OrderAddress2__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Address_2__c;
                    o.PC_OrderAddress3__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Address_3__c;
                    o.PC_OrderAddressCity__c = accMap.get(o.PC_ShipTo__c).PC_Primary_City__c;
                    o.PC_OrderAddressState__c = accMap.get(o.PC_ShipTo__c).PC_Primary_State__c;
                    o.PC_OrderAddressZipCode__c = accMap.get(o.PC_ShipTo__c).PC_Primary_Zip_Code__c;
                }
            }

        }catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
    }

}