/*********************************************************************************************************
Trigger Name    : PC_Error_Log_Info_Trigger
Description     : Trigger on PC_Error_Log_Info__e object.
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------
Deloitte               May 17, 2016             Initial Version
Shishir Bansal         Dec 05, 2019             [PC-5787]Added null check before insert statement
Satheesh Kumar         Jun 05, 2020             [PC-5571] Retrying failed platform event only 9 times before logging an error
Haritha Reddy          Mar 21, 2021             [PC-7010] Made changes to process Error log info only if error log info handler
                                                is active in Trigger handler register
***************************************************************************************************/
trigger PC_Error_Log_Info_Trigger on PC_Error_Log_Info__e (after insert) {

    List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_ERROR_LOG_INFO_HANDLER,PC_Constants.PC_ERROR_LOG_INFO,null);

    if(!trigglerHandlerList.isEmpty() && trigglerHandlerList != null && trigglerHandlerList.size()>0){
        List<PC_Error_Log__c> errorLogs = new List<PC_Error_Log__c>();
        PC_Error_Log__c errorLog ;
        try {
            for(PC_Error_Log_Info__e pe : (List<PC_Error_Log_Info__e>)Trigger.new) {
                system.debug('trace>>'+pe.PC_Stack_Trace__c);
                errorLog = new PC_Error_Log__c();
                errorLog.PC_Additional_Information__c = pe.PC_Additional_Information__c == null ? '' : pe.PC_Additional_Information__c;
                errorLog.PC_Error_Datetime__c = pe.PC_Error_DateTime__c;
                errorLog.PC_Error_Message__c = pe.PC_Error_Message__c;
                errorLog.PC_Stack_Trace__c = pe.PC_Stack_Trace__c;
                errorLog.PC_Class_Name__c = pe.PC_Class_Name__c;
                errorLog.PC_Method_Name__c = pe.PC_Method_Name__c;
                errorLog.PC_Line_Number__c = pe.PC_Line_Number__c;
                errorLog.PC_Record_ID__c = pe.PC_Record_ID__c;
                errorLog.PC_Log_Level__c = pe.PC_Log_Level__c;
                try {
                    errorLog.PC_Running_User__c = (ID) pe.PC_Running_User__c;
                }
                catch(Exception ex) {
                    system.debug('Invalid ID found for Running User ' + pe.PC_Running_User__c);
                }
                errorLog.PC_Additional_Information__c = errorLog.PC_Additional_Information__c +
                        '---System Info---ReplayId:' + pe.ReplayId + '---';
                errorLogs.add(errorLog);
            }
            if(errorLogs !=null && !errorLogs.isEmpty() ) {
                insert errorLogs;
            }
        }catch(Exception ex){
            if (EventBus.TriggerContext.currentContext().retries < 9) {
                throw new EventBus.RetryableException('Exception in Error Log Info Platform Event, Retry # :' + EventBus.TriggerContext.currentContext().retries);
            }else{
                system.debug('Retried 9 times');
                system.debug(ex.getMessage());
            }
        }
    }else{
        System.debug('Trigger Handler Register not found for sObject '+PC_Constants.PC_ERROR_LOG_INFO);
    }
}