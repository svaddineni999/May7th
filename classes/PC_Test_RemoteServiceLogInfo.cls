/*********************************************************************************
Class Name      : PC_Test_RemoteServiceLogInfo
Description     : Test Class for PC_Remote_Service_Log_Info_Trigger Trigger
Created By      : Deloitte
Created Date    : Jun 5, 2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Satheesh Kumar          Jun 5, 2020              Initial Version
Chetna Mohapatra        Apr 23, 2021             Modified the logic for platform event creation to set the service name.
*********************************************************************************/
@isTest
public with sharing class PC_Test_RemoteServiceLogInfo {
    @isTest static void testRetryException() {
        Test.startTest();

        List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_REMOTE_SERVICE_LOG_INFO_HANDLER,PC_Constants.PC_REMOTE_SERVICE_LOG_INFO,null);
        System.assert(triggerHandlerRegisterList.size()>0);
        // Publish a test event
        PC_Remote_Service_Log_Info__e remoteServiceEvent = new PC_Remote_Service_Log_Info__e ( PC_Callback_Request__c = 'Test Request',PC_Service_Name__c = PC_Constants.CMM);
        Database.SaveResult sr = EventBus.publish(remoteServiceEvent);
        // Deliver the initial event message.
        // This will fire the associated event trigger.
        Test.getEventBus().deliver(); 
 
        String remoteServiceLog_PE_API_Name = PC_Constants.getQualifiedAPIName('PC_Remote_Service_Log_Info__e');             
        for(Integer i=0;i<9;i++) {                           
            // Get info about all subscribers to the event
            System.debug('remoteServiceLog_PE_API_Names=' + remoteServiceLog_PE_API_Name);
            EventBusSubscriber[] subscribers = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:remoteServiceLog_PE_API_Name];
            
            for (EventBusSubscriber sub : subscribers) {  
                System.debug('sub.Retries=' + sub.Retries);
                System.debug('sub.lastError=' + sub.lastError);
                if (sub.Name == 'PC_Remote_Service_Log_Info_Trigger') {
                    System.assertEquals(i+1, sub.Retries);
                } 
            }
            // Deliver the retried event
            Test.getEventBus().deliver(); 
        }
        Test.stopTest();    
    }
}