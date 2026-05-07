/*********************************************************************************************************
Class Name      : PC_TriggerHandlerHelper
Description     : Class to get information to handle triggers using configurations from custom metadata 'PC_TriggerHandlerRegister__mdt'
Created By      : Deloitte
Created Date    : July 06, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Shabda Bhujad       	July 06, 2017           Initial Version
Tejas Patel             Jan 17, 2018            [PC-2622]Allow for custom objects viw PC_CustomObject__c text field
Prachi Nandgaonkar      Jan 18, 2018            [PC-2622]Made class global and executeTrigger() global to allow 
												clients to use our trigger framework
Tejas Patel             Apr 06, 2018            Logic to run either Standard or Custom Object Trigger
Xiukai Ning             APR 26, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora            Jan 03,2020             [PC-5816]Updating the Salesforce Api Version of PC_TriggerHandlerHelper Class.
Tushar Arora            feb 25,2020             [PC-6019]Updating the Salesforce Api Version to 48.0 of PC_TriggerHandlerHelper Class.
****************************************************************************************************************/
/**
 * Class to get information to handle triggers using configurations from custom metadata 'PC_TriggerHandlerRegister__mdt'
 */
global class PC_TriggerHandlerHelper {
    global static List<PC_TriggerHandlerRegister__mdt> getTriggerHandlerList(String sObjectName)  {
        String apexClass_API_Name = PC_Constants.getQualifiedAPIName('PC_ApexClass__c');
        String active_API_Name = PC_Constants.getQualifiedAPIName('PC_Active__c');
        String orderOfExecution_API_Name = PC_Constants.getQualifiedAPIName('PC_OrderOfExecution__c');
        String triggerHandlerRegister_mdt_API_Name = PC_Constants.getQualifiedAPIName('PC_TriggerHandlerRegister__mdt');
        String query;
        String other = PC_Constants.TriggerHandler_sObject;
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = new List<PC_TriggerHandlerRegister__mdt>();
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList_StandardObject = new List<PC_TriggerHandlerRegister__mdt>();
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList_CustomObject = new List<PC_TriggerHandlerRegister__mdt>();

        query = 'SELECT '
                + apexClass_API_Name + ', '
                + active_API_Name + ', '
                + orderOfExecution_API_Name
                + ' FROM '
                + triggerHandlerRegister_mdt_API_Name
                + ' WHERE PC_sObject__c =: sObjectName AND PC_Active__c = true ORDER BY PC_OrderOfExecution__c ASC';

        trigglerHandlerList_StandardObject =    Database.query(query);
        if(trigglerHandlerList_StandardObject.isEmpty()) {
            query = 'SELECT '
                    + apexClass_API_Name + ', '
                    + active_API_Name + ', '
                    + orderOfExecution_API_Name
                    + ' FROM '
                    + triggerHandlerRegister_mdt_API_Name
                    + ' WHERE PC_sObject__c =: other AND PC_OtherObject__c =: sObjectName AND PC_Active__c = true ORDER BY PC_OrderOfExecution__c ASC';

            trigglerHandlerList_CustomObject = Database.query(query);
            trigglerHandlerList.addAll(trigglerHandlerList_CustomObject);
        }

        trigglerHandlerList.addAll(trigglerHandlerList_StandardObject);

        return trigglerHandlerList;
	}
    
    global static boolean getTriggerState(String triggerObject, String apexHandlerName) {
        Boolean isTriggerActive = False; 
        List<PC_TriggerHandlerRegister__mdt>  trigrLst = getTriggerHandlerList(triggerObject);
            for(integer i=0; i<trigrLst.size(); i++) {
                if(trigrLst[i].PC_ApexClass__c == apexHandlerName) {
                    isTriggerActive=true;
                }   
            }
        return isTriggerActive;
    }
}