/*********************************************************************************************************
Trigger Name    :ACLS_ContentDocumentLink_Trigger
Description     : Trigger on ContentDocumentLink object. 
Created By      : Deloitte
Created Date    : March 23, 2023
****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
March 23, 2023	Nandita Vyas				US-647				Created Inbound Document Record
*****************************************************************************************************************/
trigger ACLS_ContentDocumentLink_Trigger on ContentDocumentLink (after insert) {
    new PC_TriggerHandlerDispatcher().executeTriggers();

}