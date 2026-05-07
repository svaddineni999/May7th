/*********************************************************************************
Class Name      : PC_Test_ErrorLogInfo
Description     : Test Class for PC_Error_Log_Info_Trigger Trigger
Created By      : Deloitte
Created Date    : Jun 6, 2020
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Satheesh Kumar          Jun 6, 2020              Initial Version
*********************************************************************************/
@isTest
public with sharing class PC_Test_ErrorLogInfo {
    @isTest static void testRetryException() {
        
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String additional_Info = '';
        while (additional_Info.length() < 32768) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           additional_Info += chars.substring(idx, idx+1);
        }
        
        Test.startTest();

        List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_ERROR_LOG_INFO_HANDLER,PC_Constants.PC_ERROR_LOG_INFO,null);
        System.assert(triggerHandlerRegisterList.size()>0);
        // Publish a test event
        PC_Error_Log_Info__e errorLog = new PC_Error_Log_Info__e(
            PC_Error_DateTime__c = DateTime.Now(),
            PC_Error_Message__c = 'Retry Excetion Failed 9 Times',
            PC_Running_User__c = UserInfo.getUserId(),
            PC_Stack_Trace__c = 'test',
            PC_Additional_Information__c = additional_Info // assigning string of length 32768 to make DMLexception manually in PC_Error_Log_Info__e trigger.
        );
        Database.SaveResult sr = EventBus.publish(errorLog);
        // Deliver the initial event message.
        // This will fire the associated event trigger.
        Test.getEventBus().deliver(); 
 
        String errorLog_PE_API_Name = PC_Constants.getQualifiedAPIName('PC_Error_Log_Info__e');             
        for(Integer i=0;i<9;i++) {                           
            // Get info about all subscribers to the event
            System.debug('errorLog_PE_API_Name=' + errorLog_PE_API_Name);
            EventBusSubscriber[] subscribers = [SELECT Name, Type, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic=:errorLog_PE_API_Name];
            
            for (EventBusSubscriber sub : subscribers) {  
                System.debug('sub.Retries=' + sub.Retries);
                System.debug('sub.lastError=' + sub.lastError);
                if (sub.Name == 'PC_Error_Log_Info_Trigger') {
                    System.assertEquals(i+1, sub.Retries);
                } 
            }
            // Deliver the retried event
            Test.getEventBus().deliver(); 
        }
        Test.stopTest();    
    }
}