/*********************************************************************************************************
Class Name      : PC_Test_SupportPlanInfoTrigger
Description     : Test Class for PC_SupportPlanInfo_Trigger.
Created By      : Haritha Reddy
Created Date    : Aug 21, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy               Aug 21, 2020          Initial Version
****************************************************************************************************************/
@isTest
public with sharing class PC_Test_SupportPlanInfoTrigger {

    @isTest static void testResumingBatchSizeTrigger() {

        Test.startTest();

        List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_SUPPORT_PLAN_INFO_HANDLER,PC_Constants.PC_SUPPORT_PLAN_INFO,null);
        System.assert(triggerHandlerRegisterList.size()>0);

        // Publish 2 test events
        List<PC_SupportPlanInfo__e> eventList = new List<PC_SupportPlanInfo__e>();
        for(Integer i=0;i<2;i++) {
            PC_SupportPlanInfo__e oneEvent = new PC_SupportPlanInfo__e();
            oneEvent.PC_Context__c = 'ProcessSupportPlanRuntimes';
            eventList.add(oneEvent);
        }
        Database.SaveResult[] srs = EventBus.publish(eventList);
        for(Database.SaveResult sr : srs) {
            System.assertEquals(true, sr.isSuccess());
        }
        // Deliver the first test event message.
        // This will fire the associated event trigger.
        Test.getEventBus().deliver();

        // Get old position of this subscriber
        EventBusSubscriber subOld = [SELECT Name, Position, Topic FROM EventBusSubscriber
                                        WHERE Topic =: PC_Constants.getQualifiedAPIName('PC_SupportPlanInfo__e') AND Name LIKE '%PC_SupportPlanInfoTrigger'];
        System.debug('subOld>> '+subOld);

        // Refire the trigger for the last event (2nd).
        Test.getEventBus().deliver();

        // VERIFICATION
        // Get new position of this subscriber
        EventBusSubscriber subNew = [SELECT Name, Position, Topic FROM EventBusSubscriber
                                        WHERE Topic =: PC_Constants.getQualifiedAPIName('PC_SupportPlanInfo__e')  AND Name LIKE '%PC_SupportPlanInfoTrigger'];
        System.debug('subNew>> '+subNew);

        System.assertEquals(subOld.Position + 1, subNew.Position);

        Test.stopTest();

    }
}