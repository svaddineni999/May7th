/*************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar         Mar 11, 2018              	Initial Version
****************************************************************************************************************/
/**
 * Trigger on Contact object.
 */

trigger PC_Contact_Trigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers();
}