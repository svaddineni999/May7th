/***************************************************************************************************************
Class Name      : PC_SMSSender2_Example
Description     : This is an example class for integration with external Sms Service.
Created By      : Chetna Mohapatra
Created Date    : 16-Dec-2020

Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy           20-Apr-2021             [PC-7490] Removed queued status assignment to Message Status Details
Chetna Mohapatra        06-Jul-2021             [PC-7873] Modifications and additional comments as per 14.0 changes.
Chetna Mohapatra        02-Aug-2021             [PC-8026] Changes to identify External SMS Recipients in the Case Activity Timeline.
****************************************************************************************************************/
 public with sharing class PC_SMSSender2_Example implements PC_SMS.Sender {

    public void send(PC_SMS.SenderRequest request) {
        List<PC_Message__c> messages ;
        String selectedRecipients,recipient,caseId,transactionId;
        String externalRecipientLabel= System.label.PC_ExternalRecipientLabel;
        /**
         * The messageIds have been exposed as a part of request since the Message records are created on initiating Message sending irrespective of any third-party integration.
         * So when attempting an integration with a third-party vendor, based on the Api response received by the vendor,
         * the fields pertaining to the PC_Message__c present in a Message record can be updated using the messageIds obtained from the request.
         * Thereafter to attempt an integration with a  third-party vendor, we'll need to query the required fields from the records of PC_Message__c object such as,
         * like sender number, recipient number and message body and initiate a webservice callout to any external vendor to facilitate the channel for Messaging service.*/

        List<Event> successEventList = new List<Event>();
        Event successEvent;
        /**FLS or CRUD Check*/
        List<String> msgFields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_Case__c'),
                PC_Constants.getQualifiedAPIName('PC_ReceiverAccount__r.name'),
                PC_Constants.getQualifiedAPIName('PC_ReceiverUser__r.name'),
                PC_Constants.getQualifiedAPIName('PC_TransactionId__c'),
                PC_Constants.getQualifiedAPIName('PC_Message_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_MessageStatusDetails__c'),
                PC_Constants.getQualifiedAPIName('PC_ExternalRecipientName__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'), PC_Database.Operation.Reading, msgFields);

        /** Query for getting the necessary fields from the Message record using the Ids in the request**/
        messages = new List<PC_Message__c>([SELECT Id, PC_Case__c,PC_ReceiverAccount__r.name, PC_ReceiverUser__r.name,PC_ExternalRecipientName__c, PC_TransactionId__c,PC_Message_Status__c, PC_MessageStatusDetails__c FROM PC_Message__c WHERE Id IN:request.messageIds]);

        /** Thereafter, we can loop over the list of Messages and initiate a callout for each Message,
        * For example, for(eachMessage:ListofMessages){
        *                 make a webservice callout
        *                 }
        * Service callouts to third party vendors can be done as per the following example:-
       * Http http = new Http();
       * HttpRequest req = new HttpRequest();//Initialize the external webservice callout request
       * req.setEndpoint('https://th-apex-http-callout.herokuapp.com/animals');//To access this external website, create a Remote Site Setting for the same.
       * req.setMethod('POST');//Using Http POST Method
       * req.setHeader('Content-Type', 'application/json;charset=UTF-8');
       * req.setBody('{"name":"mighty moose"}');//set the request body with any parameters needed to facilitate the message.
       * HttpResponse res = http.send(req);//Send across the request that was created before,decompose the components of that request and get a response
       *
       * Once the request is initiated, we can get the immediate API response for our request from the Third-party vendor and based on the success or failure of the request
       * update the Message records and use a logging mechanism such as our Remote Service Logs(PC_Remote_Service_Log__c) to log the request and response details.
       * Also we can use the activity timeline of the Case associated with the message to create events or task indicating the Message status.
       *
       * From the Third-party API Response, we can get the External ID of the Message initiated and then poll the ID using Http GET Method to get additional details on
       * the Message after it reached the Third-party server. Also we can create a callback mechanism to receive updates from Third-party on the Message and use the
       * Remote Service Logs(PC_Remote_Service_Log__c) to log the callback details or use them in Message records and Case activity timeline
       */
        for (PC_Message__c eachMsg : messages) {
            eachMsg.PC_Message_Status__c = PC_SMS.PC_SMS_DELIVERED;
            eachMsg.PC_SMSId__c=  String.valueOf(System.now().getTime());
            if (eachMsg.PC_ReceiverAccount__r.name == null && eachMsg.PC_ReceiverUser__r.name != null) {
                recipient = eachMsg.PC_ReceiverUser__r.name;
            } else if (eachMsg.PC_ReceiverUser__c == null && eachMsg.PC_ReceiverAccount__c != null) {
                recipient = eachMsg.PC_ReceiverAccount__r.name ;
            } else {
                if(String.isNotBlank(externalRecipientLabel)) {
                    recipient = eachMsg.PC_ExternalRecipientName__c + ' ' + externalRecipientLabel;
                }else{
                    recipient = eachMsg.PC_ExternalRecipientName__c + externalRecipientLabel;
                }
            }
            eachMsg.PC_MessageStatusDetails__c = System.label.PC_MessageSuccessDetails;
            caseId = eachMsg.PC_Case__c;
            transactionId = eachMsg.PC_TransactionId__c;
            String ownerId= UserInfo.getUserId();
            String subject= System.label.PC_MessageSuccessEventSubject1 + ' ' +recipient;
            String description= subject+ '\n' +System.Label.PC_MessageEventDescription + ' ' + transactionId;
            successEvent = PC_TwilioSMSService.createMessageRelatedEvent(caseId,ownerId,subject,description);
            successEventList.add(successEvent);
        }
        if(successEventList != null && !successEventList.isEmpty() ) {
            PC_Database.ins(successEventList,true);
        }
        PC_Database.upd(messages,true);
    }
 }