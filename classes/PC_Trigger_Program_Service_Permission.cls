/*********************************************************************************************************
Trigger Name    : PC_Trigger_Program_Service_Permission
Description     : trigger on PC_Program_Service_Permission__c object. 
Created By      : Tejas Patel
Created Date    : May 23, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel             	 May 23, 2017            Initial Version
Ajinkya Deshmukh			 Jun 23, 2017			 FLS Check Added (Code Merge)
Shabda Bhujad                Nov 14, 2017            PC-2485 Removing the reference to trigger state
Xiukai Ning                  Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                     Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                     We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar               Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Program_Service_Permission extends PC_TriggerHandler {
    
    override public void beforeInsertUpdate(){
        updateEndDate((List<PC_Program_Service_Permission__c>)newList);     
    }
    
	/*********************************************************************************
	Method Name    : updateEndDate
	Author         : Tejas Patel
	Description    : This method  updates the EndDate field
	Return Type    : void
	Parameter      : List of incoming account records - Trigger.new               
	*********************************************************************************/
    private void updateEndDate(List<PC_Program_Service_Permission__c> servicePermission) {
        List<PC_Program_Service_Permission__c> servicePermissionsToUpdate = new List<PC_Program_Service_Permission__c>();
        
        Set<id> serviceIds = new Set<id>();
        for (PC_Program_Service_Permission__c a : servicePermission){
            serviceIds.add(a.PC_Service__c); 
        }

        List<PC_Service__c> services = [SELECT PC_Default_Expiration_Days__c 
        								FROM PC_Service__c 
        								WHERE Id 
        								IN :serviceIds];
        
        for (PC_Program_Service_Permission__c a : servicePermission) {
            for(PC_Service__c b : services) {
                if(a.PC_Service__c == b.Id) {
                    if (a.PC_End_Date__c != null) {
                        servicePermissionsToUpdate.add(a);
                    } else if (b.PC_Default_Expiration_Days__c == 0 || b.PC_Default_Expiration_Days__c == null || a.PC_Start_Date__c == null){
                        a.PC_End_Date__c = null;
                        servicePermissionsToUpdate.add(a);
                    } else if (b.PC_Default_Expiration_Days__c > 0 && a.PC_Start_Date__c != null) {
                        a.PC_End_Date__c = a.PC_Start_Date__c.addDays((Integer)b.PC_Default_Expiration_Days__c);
                        servicePermissionsToUpdate.add(a);
                    }
                }
            }
        }
    }
}