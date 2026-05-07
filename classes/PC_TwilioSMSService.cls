/**************************************************************************************************************************************************************************
Class Name      : PC_TwilioSMSService
Description     : This is the implementation class for Twilio SMS Service Integration.
Created By      : Chetna Mohapatra
Created Date    : 01-Dec-2020
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra         01-Dec-2020            Initial Version
Satheesh Kumar           19-Mar-2021            [PC-7374] Capture SMS Sid and SMS Vendor Name in message record
Chetna Mohapatra         07-Apr-2021            [PC-7547] Replaced getPatientConnectSetting() with getIntegrationSetting() to fetch Twilio based configurations.
Chetna Mohapatra         07-Apr-2021            Modified the deprecated Message Resource i.e.endpoint URI to facilitate successful delivery  of messages.
Chetna Mohapatra         20-Apr-2021            [PC-7534] Added StatusCallback parameter in the Message API Request.
Chetna Mohapatra         21-Apr-2021            [PC-7534] Added methods getResponseMap() to manage Twilio's initial outbound response and,
                                                handleTwilioRequest() to handle Twilio's callback request.
Haritha Reddy            20-Apr-2021            [PC-7490] Removed queued status assignment to Message Status Details and added updateMessageStatusAndCreateActivity()
Chetna Mohapatra         05-May-2021           [PC-7721] Added Service Type in Remote Service Log when handling Twilio's callback request.
Chetna Mohapatra        11-May-2021           [PC-7686] Made the Twilio token parameter configurable in the callback URL.
Chetna Mohapatra        26-May-2021           [PC-7769] Value assignment for Message Source Type field post Twilio's callout.
Chetna Mohapatra        10-Jun-2021           [PC-7732] Added logic for Remote Service Log creation to log each outbound Message API request.
Chetna Mohapatra        24-Jun-2021           [PC-7690] Logic for External Recipient Numbers to be added as 'To' number.
Chetna Mohapatra        28-Jun-2021           [PC-7762] Modified the error description for Message delivery failure as per Twilio provided error code.
Chetna Mohapatra        05-Jul-2021           [PC-7885] Modified the WHERE clause in the query for updating Case & Message post Twilio's Status callback.
Chetna Mohapatra        06-Jul-2021           [PC-7872] Templates related enhancements and improvements.
Chetna Mohapatra        02-Aug-2021           [PC-8026] Changes to identify External SMS Recipients in the Case Activity Timeline.
Chetna Mohapatra        12-Aug-2021           [PC-8189] Added methods getInboundMessageDetails(),getInboundSenderInfo(), getInboundReceiverInfo(),getInboundMessageRecord()
                                                      for Inbound SMS capability.
Chetna Mohapatra        14-Aug-2021           [PC-8259]Modified query to get unique case specific to Program recordType associated with Inbound SMS Sender Account.
Chetna Mohapatra        29-Oct-2021           [PC-8298] Task due date value changed from Date.today() to System.today() and createMessageErrorTask() made public.
Chetna Mohapatra        10-Nov-2021           [PC-8136] Error task creation on the Message and parallel event creation on the case for Outbound Messages.
Chetna Mohapatra        12-Nov-2021           [PC-8323] Default setting value hardcoded for the Twilio Named Credential Name Integration settings.
***************************************************************************************************************************************************************************/
public with sharing class PC_TwilioSMSService implements PC_SMS.Sender {

    public static String messageId,transactionId,caseId,selectedRecipient,smsContent,responseBody,requestBody,ownerId;
    public static final String PC_TWILIO_PACKAGED_NAMEDCREDENTIAL= 'PC_Twilio';
    public static Map<Id, PC_Message__c> messages ;
    public static Map<String, HttpResponse > responseMap= new Map<String, HttpResponse>();
    public static Map<String, HttpResponse> callOutMap= new Map<String, HttpResponse>();
    public static HTTPResponse twilioResponse= new HttpResponse();
    public static String externalRecipientLabel= System.label.PC_ExternalRecipientLabel;
    /**
     * This method has implementation involved for message sending process using Twilio
     * @param request
     */
    public static void send(PC_SMS.SenderRequest request) {
        try {// FLS Check
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Content__c'),
                    PC_Constants.getQualifiedAPIName('PC_ReceiverAccount__r') + '.' +
                            PC_Constants.getQualifiedAPIName('HealthCloudGA__PrimaryContact__r') + '.' + 'phone',
                    PC_Constants.getQualifiedAPIName('PC_ReceiverAccount__r') + '.' + 'phone',
                    PC_Constants.getQualifiedAPIName('PC_ReceiverUser__r') + '.' + 'phone',
                    PC_Constants.getQualifiedAPIName('PC_ReceiverAccount__r') + '.' + 'name',
                    PC_Constants.getQualifiedAPIName('PC_ReceiverUser__r') + '.' + 'name',
                    PC_Constants.getQualifiedAPIName('PC_ExternalRecipientNumber__c'),
                    PC_Constants.getQualifiedAPIName('PC_ExternalRecipientName__c'),
                    PC_Constants.getQualifiedAPIName('PC_FromAlias__c'),
                    PC_Constants.getQualifiedAPIName('PC_TransactionId__c'),
                    PC_Constants.getQualifiedAPIName('PC_Case__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'), PC_Database.Operation.Reading, fields);

            messages = new Map<Id, PC_Message__c>([SELECT Id,PC_Content__c,PC_ReceiverAccount__r.HealthCloudGA__PrimaryContact__r.phone,
            PC_ReceiverAccount__r.phone,PC_ReceiverUser__r.phone,PC_ReceiverAccount__r.name,
            PC_ReceiverUser__r.name,PC_ExternalRecipientNumber__c,PC_ExternalRecipientName__c,PC_FromAlias__c,
            PC_TransactionId__c,PC_Case__c FROM PC_Message__c WHERE Id IN:request.messageIds]);

            responseMap  = getResponseMap(messages);
            Integer statusCode;
            ownerId = UserInfo.getUserId();
            List<Task> taskList= new List<Task>();
            List<Event> eventList = new List<Event>();
            for(String eachMessageId: responseMap.keySet()) {
                statusCode = responseMap.get(eachMessageId).getStatusCode();
                responseBody = responseMap.get(eachMessageId).getBody();

                if (statusCode != null && (statusCode == 201 || statusCode == 200)) {
                    PC_Message__c msg= messages.get(eachMessageId);
                    system.debug('msg--->' +msg);
                    SuccessResponse response = parseSuccessResponse(responseBody);
                    if (msg.PC_ReceiverAccount__c == null && msg.PC_ReceiverUser__c != null) {
                        selectedRecipient = msg.PC_ReceiverUser__r.name;
                    }else if(msg.PC_ReceiverUser__c == null && msg.PC_ReceiverAccount__c != null) {
                        selectedRecipient = msg.PC_ReceiverAccount__r.name ;
                    }else{
                        if(String.isNotBlank(externalRecipientLabel)) {
                            selectedRecipient = msg.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                        }else{
                            selectedRecipient = msg.PC_ExternalRecipientName__c + externalRecipientLabel;
                        }
                    }
                    system.debug('Success response-->' +response);
                    msg.PC_Message_Status__c=response.status;
                    msg.PC_SMSId__c = response.sid;
                    msg.PC_SMSVendorName__c = PC_Constants.PC_TWILIO;
                    msg.PC_Source_Type__c= PC_Constants.PC_SMS;
                } else {
                    PC_Message__c msg= messages.get(eachMessageId);
                    system.debug('msg--->' +msg);
                    Task t = new Task();
                    Event event= new Event();
                    ErrorResponse response = parseErrorResponse(responseBody);
                    system.debug('Error response-->' +response);
                    if (msg.PC_ReceiverAccount__c == null && msg.PC_ReceiverUser__c != null) {
                        selectedRecipient = msg.PC_ReceiverUser__r.name;
                    }else if((msg.PC_ReceiverUser__c == null && msg.PC_ReceiverAccount__c != null) ) {
                        selectedRecipient = msg.PC_ReceiverAccount__r.name ;
                    }else{
                        if(String.isNotBlank(externalRecipientLabel)) {
                            selectedRecipient = msg.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                        }else{
                            selectedRecipient = msg.PC_ExternalRecipientName__c + externalRecipientLabel;
                        }
                    }
                    String subject = System.label.PC_MessageErrorTaskSubject+ ' ' +selectedRecipient;
                    String errorDetails= JSON.serialize(response);
                    event= createMessageRelatedEvent(caseId, ownerId, subject, errorDetails);
                    eventList.add(event);
                    t= createMessageErrorTask(msg.Id,caseId, ownerId, subject, errorDetails);
                    taskList.add(t);
                    PC_Utility.createErrorLog(errorDetails);
                    msg.PC_Message_Status__c=PC_SMS.PC_SMS_FAILED;
                    msg.PC_MessageStatusDetails__c=response.message;
                    msg.PC_SMSVendorName__c = PC_Constants.PC_TWILIO;
                    msg.PC_Source_Type__c= PC_Constants.PC_SMS;
                }
            }
            if(taskList.size()>0) {
                PC_Database.ins(taskList,true);
            }
            if(eventList.size()>0) {
                PC_Database.ins(eventList,true);
                System.debug('Integration Unsuccessful...');
            }
            System.debug('message values' +messages.values());
            PC_Database.upd(messages.values(),true);//Message Record Updation

        } catch(CalloutException calloutEx){
            PC_Utility.createExceptionLog(calloutEx);
        }catch (Exception ex) {
            String errorMessage = ex.getMessage();
            PC_Utility.createExceptionLog(ex);
        }
    }
   /**
    * This method returns the Map of response from Twilio based on the messageIds.
    *
    * @param messages
    *
    * @return  Map<String, HttpResponse>-returns the responseMap
    */
   public static Map<String, HttpResponse> getResponseMap( Map<Id, PC_Message__c> messages){
       List<PC_Remote_Service_Log__c> remoteServiceLogs = new List<PC_Remote_Service_Log__c>();
       for (PC_Message__c eachMsg : messages.values()) {
           CallOutParameters values= new CallOutParameters();
           if (eachMsg.PC_ReceiverAccount__c == null && eachMsg.PC_ReceiverUser__c != null) {
               values.toPhNumber = eachMsg.PC_ReceiverUser__r.phone ;
           } else if(eachMsg.PC_ReceiverUser__c == null && eachMsg.PC_ReceiverAccount__c != null){
               if(eachMsg.PC_ReceiverAccount__r.HealthCloudGA__PrimaryContact__r.phone !=null) {
                   values.toPhNumber = eachMsg.PC_ReceiverAccount__r.HealthCloudGA__PrimaryContact__r.phone ;
               }else {
                   values.toPhNumber = eachMsg.PC_ReceiverAccount__r.phone ;
               }
           } else{
               values.toPhNumber= eachMsg.PC_ExternalRecipientNumber__c;
           }
           values.fromPhNumber = eachMsg.PC_FromAlias__c;
           smsContent= (eachMsg.PC_Content__c).unescapeHtml4();
           values.smsBody= EncodingUtil.urlEncode(smsContent, 'UTF-8');

           messageId = eachMsg.Id;
           transactionId = eachMsg.PC_TransactionId__c;
           caseId = eachMsg.PC_Case__c;

           values.accountSid=PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_TWILIO_ACCOUNTSID, '');
           if (String.isBlank(values.accountSid)) {
               throw new PC_SMS.SMSException(System.label.PC_TwilioAccountSidMissing);
           }
           else {
               callOutMap = doCallout(values);
               for (String callOutRequest : callOutMap.keySet()) {
                   requestBody= callOutRequest;
               }
               for (HttpResponse callOutResponse : callOutMap.values()) {
                    twilioResponse= callOutResponse;
               }
           }
           responseMap.put(messageId,twilioResponse );
           String twilioServiceName= PC_Constants.PC_TWILIO;
           String serviceType= PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND;
           String responseBody= twilioResponse.getBody();
           remoteServiceLogs.add(PC_RemoteServiceLogHandler.getRemoteServiceLog(twilioServiceName, '', requestBody, responseBody, '',serviceType));
       }
       PC_Database.ins(remoteServiceLogs);//Bulk-Insert
       return responseMap;
   }
        /*********************************************************************************
        Method Name    : doCallOut
        Author         : Chetna Mohapatra
        Description    : Callout Method for Salesforce to make callouts to Twilio Api service
        Return Type    : HTTPResponse
        Parameter      : CallOutParameters Wrapper
        *********************************************************************************/
        public static  Map<String, HttpResponse>  doCallOut( CallOutParameters values){
            HTTPResponse twilioResponse= new HttpResponse();
            HttpRequest req = new HttpRequest();
            String twilioCallbackURL, twilioTokenParameter= PC_Constants.EMPTY_STRING;
            String uriString = 'Accounts/' + values.accountSid + '/Messages.json';
            String namedCredentialWithNamespace= PC_Constants.PATIENTCONNECTNAMESPACE_WITHUNDERSCORES+PC_TWILIO_PACKAGED_NAMEDCREDENTIAL;
            String namedCredential = PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_TWILIO_NAMED_CREDENTIAL, namedCredentialWithNamespace);
            if (String.isBlank(namedCredential)) {
                PC_SMS.SMSException ex = new PC_SMS.SMSException();
                ex.setMessage(System.label.PC_MissingNamedCredentials);
                throw ex;
            } else {
                req.setEndpoint('callout:' + namedCredential + '/' + uriString);//Named Credentials
            }
            req.setMethod('POST');
            String VERSION = '3.2.0';

            req.setHeader('X-Twilio-Client', 'salesforce-' + VERSION);
            req.setHeader('User-Agent', 'twilio-salesforce/' + VERSION);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Accept-Charset', 'utf-8');

            twilioCallbackURL= PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_TWILIO_CALLBACKURL, '');
            twilioTokenParameter= PC_SYSTEM.getIntegrationSetting(PC_Constants.PC_TWILIO_TOKEN_PARAMETER, '');

            //For getting custom metadata values when Test class is running.
            if (Test.isRunningTest()) {
                twilioCallbackURL= 'https://patientconnectmsg-developer-edition.na91.force.com/TwilioReceiveSMS/services/apexrest/pccore/1.0/RemoteServiceLog/?name=';
                twilioTokenParameter = 'twilio';
            }

            if (String.isBlank(twilioCallbackURL)) {
                throw new PC_SMS.SMSException(System.label.PC_TwilioCallbackURLMissing);
            }
            if (String.isBlank(twilioTokenParameter)) {
                throw new PC_SMS.SMSException(System.label.PC_TwilioTokenParameterMissing);
            }
            //combination of Twilio callback URL along with Twilio token parameter
            String finalCallbackURL = twilioCallbackURL+twilioTokenParameter;
            req.setBody('To=' + EncodingUtil.urlEncode(values.toPhNumber, 'UTF-8') +
            '&From=' + EncodingUtil.urlEncode(values.fromPhNumber, 'UTF-8') + '&Body=' +values.smsBody+'&StatusCallback='+EncodingUtil.urlEncode(finalCallbackURL,'UTF-8'));

            Http http = new Http();
            twilioResponse = http.send(req);//callout
            DateTime start = System.Now();
            String requestBody=EncodingUtil.urlDecode(req.getBody(),'UTF-8');
            callOutMap.put(requestBody,twilioResponse);
            return callOutMap;
        }
    /**
     * This method handles the Callback Request made by Twilio using the Remote Service Log.
     *
     * @param- requestBody,requestBody,twilioServiceName
     */
    public static void handleTwilioRequest(String requestBody, String requestURL,String twilioServiceName) {
        String serviceType= PC_Constants.REMOTE_SERVICE_TYPE_INBOUND;
        PC_Remote_Service_Log__c record = PC_RemoteServiceLogHandler.createRemoteServiceLog(twilioServiceName, requestURL, requestBody, '', '',serviceType);
        PC_RemoteServiceLogHandler.publishRemoteServiceLogInfo(record);

    }
    /**
     * This method updates message with final status and creates Activity based on the status from Twilio's callback
     *
     * @param messageStatusMap - Map of SMS ID and Message Status
     */
    public static void updateMessageStatusAndCreateActivity(Map<String, String> messageStatusMap, List<String> errorCode) {
        List<PC_Message__c> messageList = new List<PC_Message__c>();
        messageList = getMessageList(messageStatusMap.keySet());
        List<Event> successEventList = new List<Event>();
        List<Event> errorEventList = new List<Event>();
        List<Task> errorTaskList = new List<Task>();
        String subject;
        if(messageList != null && !messageList.isEmpty() ){
            for(PC_Message__c messageRecord: messageList){
                String status = messageStatusMap.get(messageRecord.PC_SMSId__c);
                System.debug('Status in Update method' +status);
                messageRecord.PC_Message_Status__c = status;
                String selectedRecipient;
                if (messageRecord.PC_ReceiverAccount__c == null && messageRecord.PC_ReceiverUser__c != null) {
                    selectedRecipient = messageRecord.PC_ReceiverUser__r.name;
                } else if(messageRecord.PC_ReceiverUser__c == null && messageRecord.PC_ReceiverAccount__c != null){
                    selectedRecipient = messageRecord.PC_ReceiverAccount__r.name;
                } else{
                    if(String.isNotBlank(externalRecipientLabel)) {
                        selectedRecipient = messageRecord.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                    }else{
                        selectedRecipient = messageRecord.PC_ExternalRecipientName__c + externalRecipientLabel;
                    }
                }
                if(status == PC_SMS.PC_SMS_DELIVERED){
                    subject= System.label.PC_MessageSuccessEventSubject1 + ' ' +selectedRecipient;
                    String description= subject+ '\n' +System.Label.PC_MessageEventDescription + ' ' + messageRecord.PC_TransactionId__c;
                    messageRecord.PC_MessageStatusDetails__c = System.label.PC_MessageSuccessDetails;
                    Event successEvent = createMessageRelatedEvent(messageRecord.PC_Case__c,messageRecord.ownerId,subject,description);
                    successEventList.add(successEvent);
                } else if(status == PC_SMS.PC_SMS_UNDELIVERED){
                    String errorDescription= System.label.PC_MessageUndeliveredError+ ' ' +errorCode;
                    messageRecord.PC_MessageStatusDetails__c = errorDescription;
                    subject= System.label.PC_MessageUndeliveredTaskSubject+ ' ' +selectedRecipient;
                    //Error task on related Message
                    Task errorTask = createMessageErrorTask(messageRecord.Id,messageRecord.PC_Case__c,messageRecord.ownerId,subject,errorDescription);
                    errorTaskList.add(errorTask);
                    //Parallel event on the related Case
                    Event errorEvent = createMessageRelatedEvent(messageRecord.PC_Case__c,messageRecord.ownerId,subject,errorDescription);
                    errorEventList.add(errorEvent);
                    PC_SMS.SMSException smsException = new PC_SMS.SMSException();
                    smsException.setMessage(errorDescription);
                    PC_Utility.publishErrorLog(smsException, errorDescription);
                }
            }
            if(messageList != null && !messageList.isEmpty() ) {
                PC_Database.upd(messageList,true);
            }
            if(successEventList != null && !successEventList.isEmpty() ) {
                PC_Database.ins(successEventList,true);
            }
            if(errorEventList != null && !errorEventList.isEmpty() ) {
                PC_Database.ins(errorEventList,true);
            }
            if(errorTaskList != null && !errorTaskList.isEmpty() ) {
                PC_Database.ins(errorTaskList,true);
            }
        }
    }
    /*********************************************************************************
    Method Name    : getMessageList
    Description    : This method is used to fetch Message record list.
    Return Type    : List<PC_Message__c>
    Parameter      : Set<Id> messageIdSet
    *********************************************************************************/
    private static List<PC_Message__c> getMessageList(Set<String> messageIdSet) {
        List<String> fields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_Message_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_TransactionId__c'),
                PC_Constants.getQualifiedAPIName('PC_ReceiverAccount__r.name'),
                PC_Constants.getQualifiedAPIName('PC_ReceiverUser__r.name'),
                PC_Constants.getQualifiedAPIName('PC_ExternalRecipientName__c'),
                PC_Constants.getQualifiedAPIName('PC_ExternalRecipientNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_MessageStatusDetails__c'),
                PC_Constants.getQualifiedAPIName('PC_SMSId__c'),
                PC_Constants.getQualifiedAPIName('PC_Case__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'), PC_Database.Operation.Reading, fields);
        //Remove any null and empty values from the messageIdSet if present.
        messageIdSet.remove(null);
        messageIdSet.remove('');
        List<PC_Message__c> messageList = new List<PC_Message__c>();
        messageList = [SELECT Id, PC_Case__c, PC_Message_Status__c, PC_MessageStatusDetails__c, PC_SMSId__c, ownerId,
        PC_ReceiverAccount__r.name, PC_ReceiverUser__r.name,PC_ExternalRecipientName__c,PC_ExternalRecipientNumber__c, PC_TransactionId__c
        FROM PC_Message__c WHERE PC_SMSId__c IN: messageIdSet AND PC_SMSVendorName__c=: PC_Constants.PC_TWILIO ];
        system.debug('messagelist---' +messageList);
        return messageList;
    }
    /****************************************************************************************
    Method Name    : getInboundMessageDetails
    Description    : This method returns all the Inbound Message details in form of a wrapper
    Return Type    :
    Parameter      : List of PC_Remote_Service_Log_Info__e instances
    *****************************************************************************************/
    public static void getInboundMessageDetails(List<PC_Remote_Service_Log_Info__e> remoteServiceLogInfoList){
        Set<String> senderNumberSet = new Set<String>();
        Set<String> receiverNumberSet = new Set<String>();
        Map<String, String> parameters;
        for(PC_Remote_Service_Log_Info__e rsl: remoteServiceLogInfoList){
            System.PageReference pageReference = new System.PageReference('/' + rsl.PC_Callback_URL2__c);
            parameters = pageReference.getParameters();
            if (parameters != null) {
                String senderNumber=parameters.get('From').trim();
                if(senderNumber != null) {
                    senderNumberSet.add(senderNumber);
                }
                String receiverNumber=parameters.get('To').trim();
                if(receiverNumber != null) {
                    receiverNumberSet.add(receiverNumber);
                }
            }
        }
        InboundSenderDetails senderDetails= getInboundSenderInfo(senderNumberSet);
        Map<String, Account> receiverDetails= getInboundReceiverInfo(receiverNumberSet);
        Account senderAccount,receiverAccount;
        User senderUser;
        Case senderCase;
        List<PC_Message__c> messageList= new List<PC_Message__c>();
        for(PC_Remote_Service_Log_Info__e rsl: remoteServiceLogInfoList) {
            for (String senderPhone : senderNumberSet) {
                if (!senderDetails.senderAccountPhoneMap.isEmpty() && senderDetails.senderUserPhoneMap.isEmpty()) {
                    senderAccount = senderDetails.senderAccountPhoneMap.get(senderPhone);
                }else if(!senderDetails.senderUserPhoneMap.isEmpty() && senderDetails.senderAccountPhoneMap.isEmpty()){
                    senderUser = senderDetails.senderUserPhoneMap.get(senderPhone);
                }
            }
            for (Account acc : senderDetails.senderAccountList) {
                if(!senderDetails.senderAccountCaseMap.isEmpty() && senderDetails.senderAccountCaseMap !=null) {
                    senderCase = senderDetails.senderAccountCaseMap.get(acc.Id);
                }
            }
            for(String receiverPhone:receiverNumberSet){
                if (receiverDetails != null) {
                    receiverAccount = receiverDetails.get(receiverPhone);
                }
            }
            messageList.add(getInboundMessageRecord(parameters, senderAccount, senderUser, senderCase, receiverAccount));
        }
        if(!messageList.isEmpty() && messageList != null) {
            PC_Database.ins(messageList,true);//bulk-insert
        }
    }

    /****************************************************************************************
   Method Name    : getInboundSenderInfo
   Description    : This method returns all the Inbound Sender details in form of a wrapper
   Return Type    : InboundSenderDetails
   Parameter      : Set<String> senderNumberSet
   *****************************************************************************************/
    public static InboundSenderDetails getInboundSenderInfo(Set<String> senderNumberSet){
        InboundSenderDetails inboundSenderDetails= new InboundSenderDetails();
        if(!senderNumberSet.isEmpty()){
            //FLS Check for Account
            List<String> fields = new List<String>{'Phone',PC_Constants.getQualifiedAPIName('HealthCloudGA__PrimaryContact__r') + '.' + 'Phone'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);

            List<Account> senderAccountList= new List<Account>([SELECT Id,Phone, HealthCloudGA__PrimaryContact__r.Phone FROM Account WHERE Phone IN: senderNumberSet OR
            HealthCloudGA__PrimaryContact__r.Phone IN: senderNumberSet]);

            //FLS check for User
            List<String> userFields= new List<String>{'Phone'};
            PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading,userFields);

            List<User> senderUserList= new List<User>( [SELECT Id,Phone FROM User WHERE Phone IN:senderNumberSet ]);

            if(!senderAccountList.isEmpty() && senderAccountList.size()==1 && senderUserList.isEmpty()){
                //FLS Check for case
                List<String> caseFields = new List<String>{'Account.Name'};
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                //Query to find the case associated with the Account
                List<Case> caseList= new List<Case>([SELECT Id, Account.Name FROM Case WHERE AccountId IN:senderAccountList AND Type =: PC_Constants.CASE_PROGRAM_TYPE]);
                if(caseList != null && !caseList.isEmpty() && caseList.size()==1) {
                    for (Case associatedCase : caseList) {
                        if (associatedCase.Account != null) {
                            inboundSenderDetails.senderAccountCaseMap.put(associatedCase.Account.Id, associatedCase);
                        }
                    }
                }
                for(Account acc :senderAccountList){
                    if(acc.Phone != null && acc.HealthCloudGA__PrimaryContact__r.Phone == null){
                        inboundSenderDetails.senderAccountPhoneMap.put(acc.Phone, acc);

                    }else{
                        inboundSenderDetails.senderAccountPhoneMap.put(acc.HealthCloudGA__PrimaryContact__r.Phone, acc);
                    }
                }
            }else if(!senderUserList.isEmpty() && senderUserList.size()==1 && senderAccountList.isEmpty()){
                for(User user:senderUserList){
                    if(user.Phone != null){
                        inboundSenderDetails.senderUserPhoneMap.put(user.Phone, user);
                    }
                }
            }
           inboundSenderDetails.senderAccountList= senderAccountList;
        }
        return inboundSenderDetails;
    }
    /****************************************************************************************
     Method Name    : getInboundReceiverInfo
     Description    : This method returns all the Inbound Receiver Account List
     Return Type    : List<Account> receiverAccountList
     Parameter      : Set<String> receiverNumberSet
    *****************************************************************************************/
    public static Map<String,Account> getInboundReceiverInfo(Set<String> receiverNumberSet){
        Map<String, Account> receiverAccountPhoneMap =  new  Map<String, Account>();
        if(!receiverNumberSet.isEmpty()) {
            //FLS Check for Account
            List<String> fields = new List<String>{
                    'Phone', PC_Constants.getQualifiedAPIName('HealthCloudGA__PrimaryContact__r') + '.' + 'Phone'
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);

            List<Account> receiverAccountList = new List<Account>([
                    SELECT Id,Phone, HealthCloudGA__PrimaryContact__r.Phone
                    FROM Account
                    WHERE Phone IN:receiverNumberSet OR
                    HealthCloudGA__PrimaryContact__r.Phone IN:receiverNumberSet
            ]);

            for(Account acc :receiverAccountList){
                if(acc.Phone != null && acc.HealthCloudGA__PrimaryContact__r.Phone == null){
                    receiverAccountPhoneMap.put(acc.Phone, acc);
                }else{
                    receiverAccountPhoneMap.put(acc.HealthCloudGA__PrimaryContact__r.Phone, acc);
                }
            }
        }
        return receiverAccountPhoneMap;
    }

    /****************************************************************************************
    Method Name    : getInboundMessageRecord
    Description    : This method returns an instance of Message record without inserting it.
    Return Type    : PC_Message__c
    Parameter      : Map<String, String> parameters- Twilio Inbound SMS request parameters
    *****************************************************************************************/
     public static PC_Message__c getInboundMessageRecord(Map<String,String> parameters, Account senderAccount,User senderUser, Case senderCase, Account receiverAccount ) {
         String senderNumber, recipientNumber, messageBody, messageStatus, messageId;
         String transactionId=PC_Utility.generateTransactionId(PC_Constants.PC_MESSAGE_TRANSACTION_ID_KEY);
         PC_Message__c msgRecord = new PC_Message__c();
         msgRecord.PC_Type__c= PC_Constants.INBOUND;
         msgRecord.PC_SMSVendorName__c = PC_Constants.PC_TWILIO;
         msgRecord.PC_TransactionId__c=transactionId;
         msgRecord.PC_Message_Date__c = datetime.now();
         msgRecord.PC_Source_Type__c= PC_Constants.PC_SMS;
         if(senderAccount != null){
            msgRecord.PC_SenderAccount__c= senderAccount.Id;
         }
         if(senderUser != null){
             msgRecord.PC_SenderUser__c= senderUser.Id;
         }
         if(senderCase != null){
             msgRecord.PC_Case__c= senderCase.Id;
         }
         if(receiverAccount!= null){
             msgRecord.PC_ReceiverAccount__c= receiverAccount.Id;
         }
         //Getting the Inbound Message details from Twilio Request
         senderNumber = parameters.get('From');
         if(senderNumber != null){
             msgRecord.PC_Sender__c= senderNumber;
         }
         recipientNumber=parameters.get('To');
         if(recipientNumber != null){
             msgRecord.PC_Receiver__c= recipientNumber;
         }
         messageBody=parameters.get('Body');
         if(messageBody != null){
             msgRecord.PC_Content__c= messageBody;
         }
         messageStatus=parameters.get('SmsStatus');
         if(messageStatus != null){
             msgRecord.PC_Message_Status__c= messageStatus;
         }
         messageId=parameters.get('SmsSid');
         if( messageId!= null){
             msgRecord.PC_SMSId__c= messageId;
         }
         System.debug('MSG RECORD--' +msgRecord);
        return msgRecord;
     }
        /*********************************************************************************
      Method Name    : createMessageErrorTask
      Author         : Chetna Mohapatra
      Description    : This method is used for creating error task for failure of outbound message
      Return Type    : task
      Parameter      : String whatId, String ownerId, String subject
      *********************************************************************************/
        public static task createMessageErrorTask(String whatId,String caseId, String ownerId, String subject, String description) {
            Task task = new Task();
            task.WhatId = whatId;
            task.PC_Program__c= caseId;
            task.OwnerId = (String.isNotBlank(ownerId) ? ownerId : UserInfo.getUserId());
            task.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PSP_TASK_RECORD_TYPE);
            task.PC_Direction__c = PC_Constants.OUTBOUND;
            task.PC_Channel__c = PC_Constants.PC_TASK_CHANNEL_SMS;
            task.Description = description;
            task.Subject = subject;
            task.Priority = PC_Constants.PC_PRIORITY_NORMAL;
            task.ActivityDate = System.today();
            task.Status = PC_Constants.PC_TASK_STATUS_WAITING;
            return task;

        }
        /*********************************************************************************
            Method Name    : createMessageRelatedEvent
            Author         : Chetna Mohapatra
            Description    : This method is used for creating an event on success of Message
            Return Type    : event
            Parameter      : String whatId, String ownerId, String subject, String description
            *********************************************************************************/
        public static event createMessageRelatedEvent (String whatId, String ownerId, String subject, String description) {
            Event event = new Event();
            event.WhatId = whatId; //record id
            event.OwnerId = (String.isNotBlank(ownerId) ? ownerId : UserInfo.getUserId()); //user id
            event.Subject = subject;
            event.Description =description ;
            event.StartDateTime = system.now();
            event.EndDateTime = system.now();
            return event;
        }

        /**
         *  Wrappers for containing the Twilio Api Response body
         */
        //Error Response Wrapper
        public with sharing class ErrorResponse {
            @AuraEnabled public Integer code;
            @AuraEnabled public String message;
            @AuraEnabled public String more_info;
            @AuraEnabled public Integer status;
        }
        public static ErrorResponse parseErrorResponse(String json) {
            ErrorResponse errorDetails= new ErrorResponse();
            try {
                 errorDetails = (ErrorResponse) System.JSON.deserialize(json, ErrorResponse.class);
            }
            catch(Exception ex){
                String errorMessage = ex.getMessage();
                PC_Utility.createErrorLog(errorMessage);
            }
            return errorDetails;
        }

        //Success Response Wrapper
        public with sharing class SuccessResponse {
            public String status;
            public String direction;
            public String sid;
        }

        public static SuccessResponse parseSuccessResponse(String json) {
            return (SuccessResponse) System.JSON.deserialize(json, SuccessResponse.class);
        }
        /**
         * Wrapper for Http CallOut Parameters
         */
        public with sharing class CallOutParameters{
            @AuraEnabled public String accountSid;
            @AuraEnabled public String fromPhNumber;
            @AuraEnabled public String toPhNumber;
            @AuraEnabled public String smsBody;


            public CallOutParameters(){
                this.accountSid=PC_Constants.EMPTY_STRING;
                this.fromPhNumber=PC_Constants.EMPTY_STRING;
                this.toPhNumber=PC_Constants.EMPTY_STRING;
                this.smsBody=PC_Constants.EMPTY_STRING;


            }
            public CallOutParameters(String accountSid,String fromPhNumber,String toPhNumber,String smsBody){
                this.accountSid=accountSid;
                this.fromPhNumber=fromPhNumber;
                this.toPhNumber=toPhNumber;
                this.smsBody=smsBody;

            }
        }
       /**
        * Wrapper for Inbound Message Details
        */
        public with sharing class InboundSenderDetails {
            @AuraEnabled public Map<String,Account> senderAccountPhoneMap{ get; set; }
            // Map of Sender Phone Number & Account.
            @AuraEnabled public List<Account> senderAccountList{ get; set; }
            // List of Sender Accounts.
            @AuraEnabled public Map<String,User> senderUserPhoneMap { get; set; }
            // Map of Sender Phone Number & User.
            @AuraEnabled public Map<String,Case> senderAccountCaseMap { get; set; }
            // Map of Sender Account Id & associated Case.

            public InboundSenderDetails() {
                senderAccountPhoneMap = new Map<String,Account>();
                senderAccountList=new List<Account>();
                senderUserPhoneMap=new Map<String, User>();
                senderAccountCaseMap= new Map<String, Case>();
            }
        }

     }