/*********************************************************************************************************
Class Name      : PC_TriggerHandlerDispatcher
Description     : Class to dispatch the appropriate trigger handler apex class for an object trigger using 
configurations from custom metadata 'PC_TriggerHandlerRegister__mdt'
Created By      : Deloitte
Created Date    : Oct 18, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------            
Prachi Nandgaonkar,        Oct 18, 2016           Initial Version
Shabda Bhujad
Tejas Patel                 Jan 17, 2018          [PC-2622]Allow for custom objects viw PC_CustomObject__c text field
Prachi Nandgaonkar          Jan 18, 2018          [PC-2622]Made class global and executeTrigger() global to allow 
												  clients to use our trigger framework
Tejas Patel                 Apr 06, 2018          Logic to run either Standard or Custom Object Trigger
Xiukai Ning                 APR 26, 2019          PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                  Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                  We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora                Jan 03,2020           [PC-5816]Updating the Salesforce Api Version of PC_TriggerHandlerDispatcher Class.
Tushar Arora                feb 25,2020           [PC-6019]Updating the Salesforce Api Version to 48.0 of PC_TriggerHandlerDispatcher Class.
Vijay Kashikar              Apr 13,2020           [PC-6183] Made changes so that registered trigger handlers are triggered even for namespace based objects.
Haritha Reddy               Mar 23,2021           [PC-7580] Replaced logic to query Trigger handler Register list with PC_System method.
Tejas Patel                 Mar 07, 2022          [PC-8582] Adding licensedUser check to bypass any trigger logic for unlicensed users.
Vijay Kashikar              Jul 05, 2022          [PC-8722] Added logic to bypass Trigger Handler Registers
****************************************************************************************************************/
/**
 *   Class to dispatch the appropriate trigger handler apex class for an object trigger using
 *   configurations from custom metadata 'PC_TriggerHandlerRegister__mdt'
 */
global class PC_TriggerHandlerDispatcher {
    global void executeTriggers()  {
        Boolean isLicensedUser;
        if(Test.isRunningTest()){
            isLicensedUser = true;
        }else{
            isLicensedUser = PC_Constants.IS_LICENSED_USER;
        }
        if(isLicensedUser){
            String sObjectName = getTriggerSObject();
            String sObjectNameWithNamespace = getTriggerSObjectWithNamespace();
            List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = PC_SYSTEM.getTriggerHandlerRegisters(sObjectName,sObjectNameWithNamespace);

            //system.debug('@@query***'+ query);
            //Check if there are triggler handler entries for the object in metadata
            if (!trigglerHandlerList.isEmpty()){
                //Loop through the list of trigger handler classes and execute in the order of execution mentioned in custom metadata
                for(PC_TriggerHandlerRegister__mdt aTriggerMetadata :  trigglerHandlerList){
                    //Get the Type corresponding to the trigger handler class name
                    Type t = Type.forName(aTriggerMetadata.PC_ApexClass__c);
                    //Check if there the apex class exists
                    try {
                        if (t != null) {
                            if(!PC_TriggerHandler.isBypassed(aTriggerMetadata.DeveloperName, aTriggerMetadata.NamespacePrefix)) {
                                Object o = t.newInstance();
                                Exception e = new System.TypeException();

                                if (o instanceof PC_TriggerHandler) {
                                    //Instantiate the type. The type of the instantiated object is the base trigger handler class
                                    PC_TriggerHandler handler = (PC_TriggerHandler) o;
                                    handler.execute(sObjectName);
                                } else {
                                    e.setMessage('Registered trigger handler with class name = ' + aTriggerMetadata.PC_ApexClass__c +
                                            'should be of the type PC_TriggerHandler');
                                    throw e;
                                }
                            }
                            else {
                                system.debug('Trigger Handler register with developer name ' + aTriggerMetadata.DeveloperName +
                                        ' and NamespacePrefix = ' + aTriggerMetadata.NamespacePrefix + ' is bypassed');
                            }
                        } else {
                            System.debug('Registered trigger handler class not found');
                        }
                    } catch (Exception e) {
                        PC_Utility.logAndThrowException(e);
                    }

                }
            }
            else {
                System.debug('No trigger handlers registed in custom metadata PC_TriggerHandlerRegister__mdt for object ' + sObjectName);
            }
        }else{
            //No managed package logic will be triggered for unlicensed users
        }
	}
  
    /******************************************************************************************
	Method Name    : getTriggerSObject
	Author         : Prachi Nandgaonkar, Shabda Bhujad
	Description    : This method is used for retrieving the sobject type of the trigger object
	Return Type    : string sobject type 
	Parameter      : 
	******************************************************************************************/
    private String getTriggerSObject() {
        String result = null;
        if (Trigger.new != null && !Trigger.new.isEmpty()) {
            result = Trigger.new[0].getSObjectType().getDescribe().getLocalName();
        }
        else if (Trigger.old != null && !Trigger.old.isEmpty()) {
            result = Trigger.old[0].getSObjectType().getDescribe().getLocalName();
        }
        return result;
    }
    /**
     * Returns trigger object name along with its namespace.
     * @return trigger object name along with its namespace.
     */
    private String getTriggerSObjectWithNamespace() {
        String result = null;
        if (Trigger.new != null && !Trigger.new.isEmpty()) {
            result = Trigger.new[0].getSObjectType().getDescribe().getName();
        }
        else if (Trigger.old != null && !Trigger.old.isEmpty()) {
            result = Trigger.old[0].getSObjectType().getDescribe().getName();
        }
        return result;
    }
}