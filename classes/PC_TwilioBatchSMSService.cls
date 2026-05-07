/**************************************************************************************************************************************************************************
Class Name      : PC_TwilioBatchSMSService
Description     : This is the service class for Twilio SMS Service Integration using Batch Apex.
Created By      : Chetna Mohapatra
Created Date    : Oct 27,2021
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra         Oct 27,2021           Initial Version

************************************************************************************************************************************************************************/
public with sharing class PC_TwilioBatchSMSService implements PC_SMS.BatchSender {
    /**
     * This method has implementation involved for message sending process using Twilio service
     * @param request
     * @author -Chetna Mohapatra
     * @return response
     */
    public static PC_SMS.BatchSenderResponse send(PC_SMS.BatchSenderRequest request) {
        Map<String, PC_Message__c> messages = new Map<String, PC_Message__c>();
        PC_SMS.BatchSenderResponse batchSenderResponse = new PC_SMS.BatchSenderResponse();
        String messageKey, selectedRecipient, responseBody, ownerId, caseId,errorDetails= PC_Constants.EMPTY_STRING;
        String externalRecipientLabel = System.label.PC_ExternalRecipientLabel;
        try {
            for (PC_Message__c eachMessage : request.messageDetails) {
                if (eachMessage.PC_Case__c != null && eachMessage.PC_Receiver__c != null) {
                    messageKey = eachMessage.PC_Case__c + eachMessage.PC_Receiver__c ;
                    messages.put(messageKey, eachMessage);
                }
            }
            Map<String, HttpResponse > responseMap = new Map<String, HttpResponse>();
            responseMap = getInitialResponseMap(messages);
            Integer statusCode;
            ownerId = UserInfo.getUserId();
            List<Task> taskList = new List<Task>();
            List<Event> eventList= new List<Event>();
            for (String eachMessageKey : responseMap.keySet()) {
                statusCode = responseMap.get(eachMessageKey).getStatusCode();
                responseBody = responseMap.get(eachMessageKey).getBody();

                if (statusCode != null && (statusCode == 201 || statusCode == 200)) {
                    PC_Message__c msg = messages.get(eachMessageKey);
                    caseId = msg.PC_Case__c;
                    PC_TwilioSMSService.SuccessResponse response = PC_TwilioSMSService.parseSuccessResponse(responseBody);
                    system.debug('Success response-->' + response);
                    msg.PC_Message_Status__c = response.status;
                    msg.PC_SMSId__c = response.sid;
                    msg.PC_SMSVendorName__c = PC_Constants.PC_TWILIO;
                    msg.PC_Source_Type__c = PC_Constants.PC_SMS;
                } else {
                    PC_Message__c msg = messages.get(eachMessageKey);
                    caseId = msg.PC_Case__c;
                    Event event= new Event();
                    PC_TwilioSMSService.ErrorResponse response = PC_TwilioSMSService.parseErrorResponse(responseBody);
                    system.debug('Error response-->' + response);
                    if (msg.PC_ReceiverAccount__c == null && msg.PC_ReceiverUser__c != null) {
                        selectedRecipient = msg.Name;
                    } else if ((msg.PC_ReceiverUser__c == null && msg.PC_ReceiverAccount__c != null)) {
                        selectedRecipient = msg.Name ;
                    } else {
                        if (String.isNotBlank(externalRecipientLabel)) {
                            selectedRecipient = msg.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                        } else {
                            selectedRecipient = msg.PC_ExternalRecipientName__c + externalRecipientLabel;
                        }
                    }
                    String subject = System.label.PC_MessageErrorTaskSubject + ' ' + selectedRecipient;
                    errorDetails = JSON.serialize(response);
                    event= PC_TwilioSMSService.createMessageRelatedEvent(caseId, ownerId, subject, errorDetails);
                    eventList.add(event);
                    PC_Utility.createErrorLog(errorDetails);
                    msg.PC_Message_Status__c = PC_SMS.PC_SMS_FAILED;
                    msg.PC_MessageStatusDetails__c = response.message;
                    msg.PC_SMSVendorName__c = PC_Constants.PC_TWILIO;
                    msg.PC_Source_Type__c = PC_Constants.PC_SMS;
                }
            }

            if (eventList.size() > 0) {
                PC_Database.ins(eventList, true);
            }
            System.debug('message values' + messages.values());

            Map<String, PC_Message__c> messagesMap = new Map<String, PC_Message__c>((List<PC_Message__c>) PC_Database.ins(messages.values(), true));//Message Record Insertion
            batchSenderResponse.messageIds.addAll(messagesMap.keySet());
            //error task creation for failed Message requests.
            if (messagesMap != null && !messagesMap.isEmpty()){
                 for (PC_Message__c msg : messagesMap.values()){
                     if (msg.PC_Message_Status__c == PC_SMS.PC_SMS_FAILED){
                         Task t = new Task();
                         if (msg.PC_ReceiverAccount__c == null && msg.PC_ReceiverUser__c != null) {
                             selectedRecipient = msg.Name;
                         } else if ((msg.PC_ReceiverUser__c == null && msg.PC_ReceiverAccount__c != null)) {
                             selectedRecipient = msg.Name ;
                         } else {
                             if (String.isNotBlank(externalRecipientLabel)) {
                                 selectedRecipient = msg.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                             } else {
                                 selectedRecipient = msg.PC_ExternalRecipientName__c + externalRecipientLabel;
                             }
                         }
                         String subject = System.label.PC_MessageErrorTaskSubject + ' ' + selectedRecipient;
                         t = PC_TwilioSMSService.createMessageErrorTask(msg.Id,caseId,ownerId,subject,errorDetails);
                         taskList.add(t);
                     }
                     msg.Name = null;
                 }
                if (taskList.size() > 0) {
                    PC_Database.ins(taskList, true);
                    System.debug('Integration Unsuccessful...');
                }
            }

        } catch (CalloutException calloutEx) {
            PC_Utility.createExceptionLog(calloutEx);
        } catch (Exception ex) {
            String errorMessage = ex.getMessage();
            PC_Utility.createExceptionLog(ex);
        }
        return batchSenderResponse;
    }
    /**
    * This method returns the Map of initial response from Twilio based on unique messageKey.
    *
    * @param Map<String,String> messages-contains unique messageKey and message details
    * @return  Map<String, HttpResponse>-returns the responseMap
    * @author Chetna Mohapatra
    */
    public static Map<String, HttpResponse> getInitialResponseMap(Map<String, PC_Message__c> messages) {
        List<PC_Remote_Service_Log__c> remoteServiceLogs = new List<PC_Remote_Service_Log__c>();
        Map<String, HttpResponse> callOutMap = new Map<String, HttpResponse>();
        HTTPResponse twilioResponse = new HttpResponse();
        Map<String, HttpResponse > responseMap = new Map<String, HttpResponse>();
        String requestBody = PC_Constants.EMPTY_STRING;
        PC_Message__c eachMsg = new PC_Message__c();
        Map<String, String> toPhnNumberMap = new Map<String, String>();
        toPhnNumberMap = getToPhoneNumberMap(messages);
        for (String eachMsgKey : messages.keySet()) {
            eachMsg = messages.get(eachMsgKey);
            PC_TwilioSMSService.CallOutParameters values = new PC_TwilioSMSService.CallOutParameters();

            if (eachMsg.PC_ReceiverUser__c != null || eachMsg.PC_ReceiverAccount__c != null){
                if(toPhnNumberMap.get(eachMsg.PC_Receiver__c) != null){
                    values.toPhNumber = toPhnNumberMap.get(eachMsg.PC_Receiver__c);
                }else{
                    PC_SMS.SMSException ex = new PC_SMS.SMSException();
                    ex.setMessage(System.label.PC_NoPhoneNumberAvailable+ ' '+eachMsg.Name);
                    throw ex;
                }
            }else{
                values.toPhNumber = eachMsg.PC_ExternalRecipientNumber__c;
            }
            values.fromPhNumber = eachMsg.PC_FromAlias__c;
            values.smsBody = EncodingUtil.urlEncode((eachMsg.PC_Content__c).unescapeHtml4(), 'UTF-8');

            values.accountSid = PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_TWILIO_ACCOUNTSID, '');
            if (String.isBlank(values.accountSid)) {
                PC_SMS.SMSException ex = new PC_SMS.SMSException();
                ex.setMessage(System.label.PC_TwilioAccountSidMissing);
                throw ex;
            } else {
                callOutMap = PC_TwilioSMSService.doCallout(values);
                for (String callOutRequest : callOutMap.keySet()) {
                    requestBody = callOutRequest;
                }
                for (HttpResponse callOutResponse : callOutMap.values()) {
                    twilioResponse = callOutResponse;
                }
            }
            responseMap.put(eachMsgKey, twilioResponse);
            String twilioServiceName = PC_Constants.PC_TWILIO;
            String serviceType = PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND;
            String responseBody = twilioResponse.getBody();
            remoteServiceLogs.add(PC_RemoteServiceLogHandler.getRemoteServiceLog(twilioServiceName, '', requestBody, responseBody, '', serviceType));
        }
        PC_Database.ins(remoteServiceLogs);//Bulk-Insert
        return responseMap;
    }
    /**
     * This method returns a Map containing the receiver Id and Phone number
     * @param messages
     * @return receiverPhoneIdMap
     * @author Chetna Mohapatra
     */
    public static Map<String, String> getToPhoneNumberMap(Map<String, PC_Message__c> messages) {
        PC_Message__c eachMsg = new PC_Message__c();
        List<Id> receiverAccountIds = new List<Id>();
        List<Id> receiverUserIds = new List<Id>();
        Map<String, String> receiverIdPhoneMap = new Map<String, String>();
        for (String eachMsgKey : messages.keySet()) {
            eachMsg = messages.get(eachMsgKey);
            if (eachMsg.PC_ReceiverAccount__c != null && eachMsg.PC_ReceiverUser__c == null) {
                receiverAccountIds.add(eachMsg.PC_ReceiverAccount__c);
            } else {
                receiverUserIds.add(eachMsg.PC_ReceiverUser__c);
            }
        }

        if (receiverAccountIds != null && !receiverAccountIds.isEmpty()) {
            String receiverPhoneNumber = PC_Constants.EMPTY_STRING;
            List<Account> receiverAccounts = new List<Account>([SELECT Id, Phone, HealthCloudGA__PrimaryContact__r.phone FROM Account WHERE Id IN:receiverAccountIds]);
            if (receiverAccounts != null && !receiverAccounts.isEmpty()) {
                for (Account receiverAccount : receiverAccounts) {
                    if (receiverAccount.HealthCloudGA__PrimaryContact__r.phone != null && receiverAccount.phone == null) {
                        receiverPhoneNumber = receiverAccount.HealthCloudGA__PrimaryContact__r.phone;
                    } else {
                        receiverPhoneNumber = receiverAccount.phone;
                    }
                    receiverIdPhoneMap.put(receiverAccount.Id, receiverPhoneNumber);
                }
            }
        }
        if (receiverUserIds != null && !receiverUserIds.isEmpty()) {
            String receiverPhoneNumber = PC_Constants.EMPTY_STRING;
            List<User> receiverUsers = new List<User>([SELECT Id, User.Phone FROM User WHERE Id IN:receiverUserIds]);
            if (receiverUsers != null && !receiverUsers.isEmpty()) {
                for (User receiverUser : receiverUsers) {
                    if (receiverUser.Phone != null) {
                        receiverPhoneNumber = receiverUser.Phone;
                        receiverIdPhoneMap.put(receiverUser.Id, receiverPhoneNumber);
                    }
                }
            }
        }
        return receiverIdPhoneMap;
    }
}