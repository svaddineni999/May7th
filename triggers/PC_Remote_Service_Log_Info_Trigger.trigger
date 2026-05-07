/*********************************************************************************************************
Trigger Name    : PC_Remote_Service_Log_Info_Trigger
Description     : Trigger on PC_Remote_Service_Log_info__e object.
Created By      : Deloitte
Created Date    : May 07, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar         May 07,2018             Initial Version
Satheesh Kumar         June 05,2020            [PC-5571] Retrying failed platform event only 9 times before logging an error
Haritha Reddy          Mar 21, 2021            [PC-7010] Made changes to process PC_Remote_Service_Log_Info only if the corresponding handler
                                                is active in Trigger handler register
Chetna Mohapatra      Apr 20, 2021            [PC-7534] Code to process PC_Remote_Service_Log_Info following Twilio's Callback Request.
Chetna Mohapatra      Jun 28, 2021            [PC-7762] Passing Twilio Error code to update both Case & Message record post delivery failure callback.
Chetna Mohapatra      Oct 12, 2021            [PC-8144] Changes to process the Twilio's Inbound Message Request.
***************************************************************************************************/
 trigger PC_Remote_Service_Log_Info_Trigger on PC_Remote_Service_Log_info__e (after insert) {
    List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_REMOTE_SERVICE_LOG_INFO_HANDLER,PC_Constants.PC_REMOTE_SERVICE_LOG_INFO,null);

    if(!trigglerHandlerList.isEmpty() && trigglerHandlerList != null && trigglerHandlerList.size()>0) {
        system.debug('in service callback trigger handler');
        try {
            String eachErrorCode,smsSid,smsStatus;
            Map<String, String> smsIdStatusMap =  new  Map<String, String>();
            List<PC_Remote_Service_Log_Info__e> remoteServiceLogInfoList= new List<PC_Remote_Service_Log_Info__e>();
            List<PC_Remote_Service_Log_Info__e> infinitusCallbackDetails= new List<PC_Remote_Service_Log_Info__e>();
            List<String> errorCodeList = new List<String>();
            for (PC_Remote_Service_Log_Info__e sc : Trigger.New) {
                if (sc.PC_Service_Name__c == PC_Constants.PC_TWILIO) {
                    System.PageReference pageReference = new System.PageReference('/' + sc.PC_Callback_URL2__c);
                    Map<String, String> parameters = pageReference.getParameters();
                    if(parameters.containsKey('serviceType')){
                        //List with inbound message request
                        remoteServiceLogInfoList.add(sc);
                    }
                    //SMS Status Callback
                    smsSid=parameters.get('SmsSid');
                    smsStatus=parameters.get('SmsStatus');
                    if(smsSid != null) {
                        smsIdStatusMap.put(smsSid,smsStatus);
                    }
                    eachErrorCode= parameters.get('ErrorCode');
                    if(eachErrorCode != null) {
                        errorCodeList.add(eachErrorCode);
                    }
                } else if (sc.PC_Service_Name__c == PC_Constants.CMM) {
                        String callbackRequest = sc.PC_Callback_Request__c;
                        PC_PriorAuthClient_CMM.processCMMRequest(callbackRequest, sc);

                } else if(sc.PC_Service_Name__c == PC_Constants.INFINITUS){
                        //Infinitus Status Callback
                        infinitusCallbackDetails.add(sc);
                }
                else {
                        system.debug(sc.PC_Service_Name__c+ ' service is not supported');
                }
            }
            if(!remoteServiceLogInfoList.isEmpty()) {
                //Inbound Message Processing
               PC_TwilioSMSService.getInboundMessageDetails(remoteServiceLogInfoList);
            }
            if(!smsIdStatusMap.isEmpty()){
                PC_TwilioSMSService.updateMessageStatusAndCreateActivity(smsIdStatusMap, errorCodeList);
            }
            if(infinitusCallbackDetails!=null && !infinitusCallbackDetails.isEmpty()){
               PC_Infinitus.processInfinitusCallbackDetails(infinitusCallbackDetails);
            }
              
        } catch (Exception ex) {
            if (EventBus.TriggerContext.currentContext().retries < 9) {
                throw new EventBus.RetryableException('Exception in Remote Service Log Platform Event, Retry # :' + EventBus.TriggerContext.currentContext().retries);
            } else {
                system.debug('Retried 9 times');
                system.debug(ex.getMessage());
                PC_Utility.publishErrorLog(ex, 'from service callback info event object.');
            }
        }
    }else{
        System.debug('Trigger Handler Register not found for sObject '+PC_Constants.PC_REMOTE_SERVICE_LOG_INFO);
    }
}