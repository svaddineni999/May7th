/************************************************************************************************************************************************************************
Class Name      : PC_SMSSender2Controller
Description     : This class is used for facilitating SMS service in PatientConnect.
Created By      : Chetna Mohapatra
Created Date    : Oct 28,2020
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra        Oct 28, 2020             Initial Version
Chetna Mohapatra        May 25, 2021             [PC-7716]-Changes made in sendMessage method to returns Message related details for client-side processing.
Chetna Mohapatra        Jun 03, 2021             [PC-7730] Removed the event for Draft status after Message record creation .
Chetna Mohapatra        Jun 24, 2021             [PC-7690] Changes for adding Templates in Messaging.
Chetna Mohapatra        Jul 06, 2021             [PC-7872] Template related enhancements and improvements.
Chetna Mohapatra        Jul 13. 2021             [PC-7902] Query changes in both getElettersAsPerEngagementProg() and getPreConfiguredRecipients() methods.
Chetna Mohapatra        Jul 20, 2021             [PC-7948] Changes in getRenderedMailTemplate() and sendMessage() methods.
Chetna Mohapatra        Sept 08, 2021            [PC-7752,7753]- Changes made for getting both Org-wide and Engagement Program Specific Phone Numbers as the sender number.
Kishore Kanteti         Oct 12, 2021             [PC-8178]- Added methods to get recipients for different caseIds.getRecipientsInfo(),getRecipients(),getPreConfiguredRecipientsMap()
Kishore Kanteti         Oct 19, 2021             [PC-8266]- Added wrapper method callSMSServiceViaFuture() to reuse callSMSService() for synchronous purpose.
Chetna Mohapatra        Oct 25, 2021             [PC-8186]- Removed the value assignments for PC_Message_Read__c field during Message record creation.
*************************************************************************************************************************************************************************/

public with sharing class PC_SMSSender2Controller {

/*****************************************************************************************************************
Method Name    :sendMessage
Author         : Chetna Mohapatra
Description    :To create/insert a message record having all details related to a message after clicking send.
Parameter      :String messageBody, String caseId, String sender, String selectedRecipients
Return type    :Boolean
*****************************************************************************************************************/
    @AuraEnabled
    public static MessageDetails sendMessage(String messageBody, String caseId, String sender, String selectedRecipients, String eletterId) {
        List<PC_Message__c> msgList= new List<PC_Message__c> ();
        PC_Engagement_Program_Eletter__c selectedEngagementProgramEletter = new PC_Engagement_Program_Eletter__c();
        MessageDetails messageDetailsToReturn = new MessageDetails();
        Map<String, String> recipientSpecificMessages= new Map<String,String>();
        try {
            List<SMSRecipient> recipients = (List<SMSRecipient>) System.JSON.deserialize(selectedRecipients, List<SMSRecipient>.class);
            //Rendering the body of the Template as Message body per recipient
            List<RenderedMailTemplate> ListRenderedMailTemplates = new List<RenderedMailTemplate>();
            if (eLetterId != null) {
                ListRenderedMailTemplates.addAll(getRenderedMailTemplate(caseId, selectedRecipients, eletterId));
                if (!ListRenderedMailTemplates.isEmpty()) {
                    for (RenderedMailTemplate renderedTemplate : ListRenderedMailTemplates) {
                         String msgBody = renderedTemplate.renderedTextBody;
                        recipientSpecificMessages.put(renderedTemplate.recipientId,msgBody);
                    }
                }
            }
            for(SMSRecipient rec:recipients) {
               if(eletterId != null) {
                   rec.msgBody = recipientSpecificMessages.get(rec.Id);

               }else{
                    rec.msgBody= messageBody;
               }
            }
            //FLS Check
            List<String> engagementProgEletterFields = new List<String>();
            engagementProgEletterFields = new List<String>{'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_eLetter__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterFields);

            if(eletterId!=null) {
                //get the eletter Name from Engagement Program eletter
                selectedEngagementProgramEletter = [
                        SELECT Id,Name,PC_eLetter__c
                        FROM PC_Engagement_Program_Eletter__c
                        WHERE PC_eLetter__r.Id = :eletterId LIMIT 1
                ];
            }
            //get the transaction Id
            String transactionId=PC_Utility.generateTransactionId(PC_Constants.PC_MESSAGE_TRANSACTION_ID_KEY);
            //create Message Record
            msgList=createMessageRecord(caseId,sender, recipients, transactionId,selectedEngagementProgramEletter);
            System.debug('Final msg recipient list->' +msgList);
            //Message record insertion & FLS check
            PC_Database.ins(msgList, true);
            //Message details to be returned for client-side processing.
            if(msgList.size()>0){
                List<String> msgFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_Case__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'), PC_Database.Operation.Reading, msgFields);
                List<PC_Message__c> messageDetails = new List<PC_Message__c>();
                messageDetails = [SELECT Id,Name, PC_Case__c FROM PC_Message__c WHERE Id IN: msgList];
                messageDetailsToReturn.messages= messageDetails;
                messageDetailsToReturn.messageObjectName=PC_Constants.getQualifiedAPIName('PC_Message');
                messageDetailsToReturn.messageRelationshipName=PC_Constants.getQualifiedAPIName('Messages__r');
            }
            List<Id> allMessageIds = new List<Id>();
            for(PC_Message__c eachMsg :msgList ){
                allMessageIds.add(eachMsg.Id);
                system.debug('each message id>>' +eachMsg.Id);
            }
            String serviceName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_SMS_SERVICE_NAME,'');
            system.debug('serviceName->' +serviceName);
            if(String.isNotBlank(serviceName)) {
                if(isServiceClassValid(serviceName)){
                    callSmsService(serviceName,allMessageIds);      //Calling the sms service
                }
                else {
                    PC_SMS.SMSException ex = new PC_SMS.SMSException();
                    ex.setMessage(System.Label.PC_IntegrationFailureMessage);
                    throw ex;
                }
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return messageDetailsToReturn;

    }
    /**************************************************************************************************************************
   Method Name    : createMessageRecord
   Author         : Chetna Mohapatra
   Description    : This method is used for creating a message record.
   Return Type    : List<PC_Message__c>
   Parameter      : String messageBody, String caseId, String sender,List<SMSRecipient> recipient, String transactionId
   **************************************************************************************************************************/
    public static List<PC_Message__c> createMessageRecord(String caseId, String sender,List<SMSRecipient> recipients, String transactionId,PC_Engagement_Program_Eletter__c selectedEngagementProgramEletter){
        List<PC_Message__c> msgList= new List<PC_Message__c> ();
        for(SMSRecipient rec: recipients){
            PC_Message__c msg = new PC_Message__c();
            msg.PC_Case__c = caseId;
            msg.PC_Content__c = rec.msgBody.escapeHtml4();
            msg.PC_Hide_from_Feed__c = false;
            msg.PC_Message_Date__c = datetime.now();
            msg.PC_Sender__c = UserInfo.getUserId();
            if(rec.recipientType==PC_Constants.PC_ACCOUNT){

                msg.PC_ReceiverAccount__c=rec.Id;
            }
            else if(rec.recipientType==PC_Constants.PC_USER){
                msg.PC_ReceiverUser__c=rec.Id;
            }
            else{
                msg.PC_ExternalRecipientNumber__c= rec.phone;
                msg.PC_ExternalRecipientName__c= rec.name;
            }
            if(selectedEngagementProgramEletter!=null){
                msg.PC_SMSEletter__c= selectedEngagementProgramEletter.Id ;
            }
            msg.PC_Receiver__c = rec.Id;
            msg.PC_Type__c = PC_Constants.OUTBOUND;
            msg.PC_Message_Status__c=PC_SMS.PC_SMS_DRAFT;
            msg.PC_TransactionId__c=transactionId;
            msg.PC_FromAlias__c=sender;

            msgList.add(msg);

        }
        return msglist;
    }
    /*********************************************************************************
      Method Name    : callBatchSmsService
      Author         : Kishore Kanteti
      Description    : This method is used for calling the Batch Sms Service Class
      Return Type    : PC_SMS.BatchSenderResponse
      Parameter      : String serviceClassName, List<PC_Message__c> messages
   ********************************************************************************************/
    public static PC_SMS.BatchSenderResponse callBatchSmsService( String serviceClassName,List<PC_Message__c> messages){

        //Integration with third-party vendor
        Type t = Type.forName(serviceClassName);
        Object o = t.newInstance();
        PC_SMS.BatchSender processor = (PC_SMS.BatchSender) o;
        PC_SMS.BatchSenderRequest request = new PC_SMS.BatchSenderRequest();
        request.messageDetails = messages;
        return processor.send(request);
    }
    /*********************************************************************************
      Method Name    : callSmsService
      Author         : Chetna Mohapatra
      Description    : This method is used for calling the Sms Service Class
      Return Type    : void
      Parameter      : String serviceName, List<Id> allMessageIds
   ********************************************************************************************/
    @future(callout=true)
    public static void callSmsService( String serviceName,List<Id> allMessageIds){

        //Integration with third-party vendor
        Type t = Type.forName(serviceName);
        Object o = t.newInstance();
        PC_SMS.Sender processor = (PC_SMS.Sender) o;
        PC_SMS.SenderRequest request = new PC_SMS.SenderRequest();
        system.debug('allMessageIds->' +allMessageIds);
        request.messageIds= allMessageIds;
        processor.send(request);
    }
    /*********************************************************************************
     Method Name    : isBatchServiceClassValid
     Author         : Kishore Kanteti
     Description    : This is a valid check method for the Batch Service Class
     Return Type    : Boolean
     Parameter      : String serviceClassName
    ********************************************************************************************/
    public static Boolean isBatchServiceClassValid( String serviceClassName){

        Type t = Type.forName(serviceClassName);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof PC_SMS.BatchSender) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }
    /*********************************************************************************
     Method Name    : isServiceClassValid
     Author         : Chetna Mohapatra
     Description    : This is a valid method for the Service Class
     Return Type    : Boolean
     Parameter      : String serviceName
    ********************************************************************************************/
    public static Boolean isServiceClassValid( String serviceName){

        Type t = Type.forName(serviceName);
        if (t != null) {
            Object o = t.newInstance();
            if (o instanceof PC_SMS.Sender) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }
    /********************************************************************************
    Method Name    : getInitInfo
    Description    : Retrieve all the SMSSender2 data.
   *********************************************************************************/
    @AuraEnabled
    public static SMSSenderInfo getInitInfo(String caseId, List <String> smsCategoryList){
        SMSSenderInfo initInfo = new SMSSenderInfo();
        try {
            List<SMSSender> senders = getSenders(caseId);
            List<SMSRecipient> recipients = getRecipients(caseId);
            List<EletterTemplate>eletterTemplateList = getEletterTemplates(caseId, smsCategoryList);

            initInfo.senders = senders;
            initInfo.recipients = recipients;
            initInfo.eletterTemplateList= eletterTemplateList;
        }
        catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }

        return initInfo;
    }

    /*********************************************************************************
     Retrieve all the sender numbers from where the message will be sent.
     * @param- String caseId
     * @return- List<SMSSender>
    *********************************************************************************/
    private static List<SMSSender> getSenders(String caseId) {
        List<SMSSender> senderData,engagementProgramPhoneNumber= new List<SMSSender>();
        if(caseId != null) {
            engagementProgramPhoneNumber = getEngagementProgramSpecificPhoneNumber(caseId);
            if (!engagementProgramPhoneNumber.isEmpty()) {
                senderData = engagementProgramPhoneNumber;
            } else{
                PC_SMS.SMSException ex = new PC_SMS.SMSException();
                ex.setMessage(System.Label.PC_SenderNumberUnavailableError);
                throw ex;
            }
        }
        return  senderData;
    }

    /**************************************************************************************************
     *This method helps fetch Engagement Program Specific Sender Phone Number using the Global SMS Sender Number Setting
     * @param- String caseId
     * @return- List<SMSSender>
     **************************************************************************************************/
    private static List<SMSSender> getEngagementProgramSpecificPhoneNumber(String caseId){
        List<SMSSender> engagementProgramSpecificPhoneNumberList= new List<SMSSender>();
        String valueInJSON, engagementProgramCode;
        Case caseEngagementProgramDetails= new Case();
        //CRUD/FLS Check for case
        List<String> caseFields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_Engagement_Program__r') + '.' +
                'PC_Program_Code__c'};
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);
        //Query to get the Program code w.r.t the Engagement Program of the Case.
        if(caseId != null) {
            caseEngagementProgramDetails = [SELECT PC_Engagement_Program__r.PC_Program_Code__c FROM Case WHERE Id = :caseId];
            engagementProgramCode = caseEngagementProgramDetails.PC_Engagement_Program__r.PC_Program_Code__c;
            valueInJSON = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PC_GLOBAL_SMS_SENDER_NUMBERS,
                    PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, ''
            );
        }
        if(String.isNotBlank(valueInJSON)){
            engagementProgramSpecificPhoneNumberList=(List<SMSSender>) System.JSON.deserialize(valueInJSON, List<SMSSender>.class);
        }
        return engagementProgramSpecificPhoneNumberList;
    }

    /*********************************************************************************
     Method Name    : getRecipients
     Description    : Retrieve the recipient data for the sending the message to.
     Parameter      : String caseId   - current case Id
    *********************************************************************************/

    public static List<SMSRecipient> getRecipients(String caseId) {
        List<SMSRecipient> recipientsDetails= new List<SMSRecipient>();
        //CRUD/FLS Check for case
        List<String> caseFields = new List<String>{'AccountId', 'Account.Name' ,'Account.phone',
                'Account.HealthCloudGA__PrimaryContact__r.phone', 'Account.PC_Preferred__c'
        };
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);

        //FLS check for association
        List<String> assocFields= new List<String>{
                'Id',PC_Constants.getQualifiedAPIName('PC_Associated_User_Name__c'),PC_Constants.getQualifiedAPIName('PC_Role__c'),
                PC_Constants.getQualifiedAPIName('PC_Account__c'),PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                PC_Constants.getQualifiedAPIName('PC_AssociationStatus__c')

        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'),PC_Database.Operation.Reading,assocFields);

        //Query to get field values from Case object and Association i.e. a child object of Case.
        Case recipientDetails = [
                SELECT AccountId, Account.Name,Account.phone, Account.HealthCloudGA__PrimaryContact__r.phone, Account.PC_Preferred__c,
                (SELECT Id,PC_Associated_User_Name__c, toLabel(PC_Role__c), PC_Account__c, PC_Associated_User__c FROM Associations__r WHERE PC_AssociationStatus__c = 'Active')
                FROM case
                where id = :caseId
        ];

        SMSRecipient patient = new SMSRecipient();
        if (recipientDetails.Account != null) {
            patient.name = recipientDetails.Account.Name;
            patient.role = PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE;
            if(recipientDetails.Account.HealthCloudGA__PrimaryContact__r.phone != null) {
                patient.phone = recipientDetails.Account.HealthCloudGA__PrimaryContact__r.phone;
            }else{
                patient.phone= recipientDetails.Account.phone;
            }
            patient.recipientType = PC_Constants.PC_ACCOUNT;
            patient.Id = recipientDetails.AccountId;
            patient.communicationPreference = recipientDetails.Account.PC_Preferred__c;
            if (patient.phone == null) {
                patient.disableSms = True;
                patient.hasNoPhoneNumber = True;
            }
            system.debug('patient' + patient);
            recipientsDetails.add(patient);
        }
        Map<ID, String> accAssociation = new Map<ID, String>();
        Map<ID, String> userAssociation = new Map<ID, String>();
        for (PC_Association__c association : recipientDetails.Associations__r) {
            if (association.PC_Account__c == null && association.PC_Associated_User__c != null) {
                userAssociation.put(association.Id, association.PC_Associated_User__c);
            } else {
                accAssociation.put(association.Id, association.PC_Account__c);
            }
        }
        //FLS check for User
        List<String> userFields= new List<String>{'Name','Phone'};
        PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading,userFields);

        //Map to store values from user object
        Map<ID,User> usersMap = new Map<ID,User>([Select Name,Phone from User where Id IN: userAssociation.values()]);
        System.debug('usersMap' +usersMap);

        //FLS check for Account
        List<String> accountFields= new List<String>{'Name','Phone', PC_Constants.getQualifiedAPIName('PC_Preferred__c'), PC_Constants.getQualifiedAPIName('HealthCloudGA__PrimaryContact__r') + '.' + 'Phone'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading,accountFields);

        //Map to store values from account object
        Map<ID,Account> accountsMap =new Map<ID,Account>([Select Name,Phone, PC_Preferred__c, HealthCloudGA__PrimaryContact__r.Phone from Account where Id IN: accAssociation.values()]);
        System.debug('accountsMap' +accountsMap);

        for (PC_Association__c association : recipientDetails.Associations__r) {
            if (userAssociation.containsKey(association.Id)) {
                SMSRecipient recipient = new SMSRecipient();
                recipient.name = usersMap.get(association.PC_Associated_User__c).Name;
                recipient.Id = association.PC_Associated_User__c;
                recipient.role = association.PC_Role__c;
                recipient.phone = String.valueOf(usersMap.get(association.PC_Associated_User__c).phone);
                recipient.recipientType = PC_Constants.PC_USER;
                if (recipient.phone == null) {
                    recipient.disableSms = True;
                    recipient.hasNoPhoneNumber = True;
                }
                System.debug('recipient' + recipient);
                recipientsDetails.add(recipient);


            } else {
                System.debug('association' + association);
                System.debug('accountsMap.get(association.PC_Account__c)' + accountsMap.get(association.PC_Account__c));
                SMSRecipient recipient = new SMSRecipient();
                recipient.name = accountsMap.get(association.PC_Account__c).Name;
                recipient.Id = association.PC_Account__c;
                recipient.role = association.PC_Role__c;
                if(accountsMap.get(association.PC_Account__c).HealthCloudGA__PrimaryContact__r.Phone != null) {
                    recipient.phone = String.valueOf(accountsMap.get(association.PC_Account__c).HealthCloudGA__PrimaryContact__r.Phone);
                }else{
                    recipient.phone= String.valueOf(accountsMap.get(association.PC_Account__c).Phone);
                }
                recipient.communicationPreference = accountsMap.get(association.PC_Account__c).PC_Preferred__c;
                recipient.recipientType = PC_Constants.PC_ACCOUNT;
                if (recipient.phone == null) {
                    recipient.disableSms = True;
                    recipient.hasNoPhoneNumber = True;
                }
                System.debug('recipient' + recipient);
                recipientsDetails.add(recipient);
            }
        }
        System.debug('recipientDetails-->' +recipientDetails);
        return recipientsDetails;
    }
    /**
   * Retrieves available eLetters by object type
   *
   * @param recordId   recordId for getting available eletter
   * @return  List<EletterTemplate>
   */
    public static List<EletterTemplate> getEletterTemplates(String recordId, List <String> smsCategoryList) {
        List<EletterTemplate> availableElettersForSMS = new List<EletterTemplate>();
        List<String> eletterIds = new List<String>();
        List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = new List<PC_Engagement_Program_Eletter__c>();
        Id recId= Id.valueOf(recordId);
        String objType = String.valueOf(recId.getSobjectType());
        String recordTypeName = PC_Constants.EMPTY_STRING;
        Id caseId ;
        try {
            recordTypeName = PC_Utility.getRecordTypeNameByRecordId(recordId);
            caseId = recordId;
            engagementProgramEletters = getElettersAsPerEngagementProg(caseId, objType, recordTypeName, smsCategoryList);
            for (PC_Engagement_Program_Eletter__c epe : engagementProgramEletters) {
                if(! eletterIds.contains(epe.PC_eLetter__r.Id)){
                    eletterIds.add(epe.PC_eLetter__r.Id);
                    availableElettersForSMS.add(new EletterTemplate(epe));
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return availableElettersForSMS  ;
    }
    /**
    *Retrieves available eLetters by engagement program of object.
    *
    * @param caseRecordId -case Record Id
    * @param objType -object type of the eletter object
    * @param recordTypeName - object record type of eletter object
    * @param smsCategoryList - eletter category list specific to SMS
    *
    * @return  List<PC_Engagement_Program_Eletter__c>
    */
    public static List<PC_Engagement_Program_Eletter__c> getElettersAsPerEngagementProg(Id caseRecordId, String objType, String recordTypeName, List <String> smsCategoryList) {
        List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = new List<PC_Engagement_Program_Eletter__c>();
        List<Case> caseObject = new List<Case>();
        String queryString, whereConditionString, orderByString = PC_Constants.EMPTY_STRING;
        List<String> whereConditions = new List<String>();
        List<String> selectedCategory = new List<String>();
        try {
            //FLS check for case
            List<String> caseFields = new List<String>{'Id', 'RecordTypeId', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);
            caseObject = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id =:caseRecordId LIMIT 1];
            if (caseObject.size() > 0 && caseObject[0].PC_Engagement_Program__c != null) {
                String caseEngagementProgram = caseObject[0].PC_Engagement_Program__c;
                List<String> eLetterFields = new List<String>();
                eLetterFields = new List<String>{
                        'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_Source_Object__c'),
                        PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_Object_Record_Types__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);
                List<Id> eLetterIdsList = new List<Id>();
                List<String> engagementProgEletterFields = new List<String>();
                engagementProgEletterFields = new List<String>{
                        'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterFields);
                for (String category : smsCategoryList){
                    selectedCategory.add('\''+ String.escapeSingleQuotes(category) +'\'');
                }
                whereConditions.add('PC_Engagement_Program__c = :caseEngagementProgram');
                whereConditions.add('PC_eLetter__r.PC_Source_Object__c = :objType');
                if(selectedCategory.size() > 0){
                    whereConditions.add('PC_eLetter__r.PC_Category__c INCLUDES (' + String.join(selectedCategory, ',') + ')');
                }
                if (!String.isBlank(recordTypeName)) {
                    whereConditions.add('PC_eLetter__r.PC_Object_Record_Types__c INCLUDES (:recordTypeName)');
                }
                whereConditionString = String.join(whereConditions, ' AND ');
                if(String.isNotBlank(whereConditionString)){
                    whereConditionString = 'WHERE ' + whereConditionString;
                }
                orderByString= 'ORDER BY PC_eLetter__r.Name ASC, LastModifiedDate DESC';
                queryString = 'SELECT Id, PC_Description__c, PC_eLetter__r.Id, PC_eLetter__r.Name, PC_eLetter__r.PC_Description__c, PC_eLetter__r.PC_Category__c FROM PC_Engagement_Program_Eletter__c '+whereConditionString+orderByString;
                engagementProgramEletters = database.query(queryString);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return engagementProgramEletters;
    }
    /**
    * Retrieves eLetters recipients and eletter template info based on eletter id
    *
    * @param letterId       Id of the eletter
    * @param recordId       recordId for getting recipients and rendered template
    * @return EletterInfo   This returns values of both eLetterRecipients and rendered eletterTemplate
    */
    @AuraEnabled
    public static EletterInfo getEletterInfo(String letterId, Id recordId) {
        EletterInfo eLetterInfo = new EletterInfo();
        String eLetterTemplateName,engagementProgramId,templatePlainTextBody = PC_Constants.EMPTY_STRING;
        EmailTemplate emailTemplate;
        List<SMSRecipient> eLetterRecipients,preConfiguredRecipients;
        try {
            PC_eLetter__c eLetter = new PC_eLetter__c();
            if (String.isNotBlank(letterId)) {
                eLetter = PC_eLetterService.getELetter(letterId);
                if (eLetter != null && eLetter.PC_Template_Name__c != null) {
                    eLetterTemplateName = eLetter.PC_Template_Name__c;
                    emailTemplate = PC_eLetter2Controller.getEmailTemplateDetails(eLetterTemplateName);
                    templatePlainTextBody= emailTemplate.Body;
                } else {
                    throw new AuraHandledException(System.Label.PC_Eletter2_ErrorEmailTemplate);
                }
                eLetterRecipients = getRecipients(recordId);//get the list of recipients
                // FLS Check
                List<String> caseFields = new List<String>{'Id','Name',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
                PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

                engagementProgramId = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id =:recordId LIMIT 1] ?.PC_Engagement_Program__c ;

                preConfiguredRecipients= getPreConfiguredRecipients( engagementProgramId, letterId);//external recipients
                //FLS Check
                List<String> eletterFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Allow_Send_to_Patient__c'),
                        PC_Constants.getQualifiedAPIName('PC_Target_Recipients__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'),PC_Database.Operation.Reading, eletterFields);
                PC_eletter__c selectedELetter = new PC_eletter__c();
                selectedELetter= [SELECT PC_Allow_Send_to_Patient__c,PC_Target_Recipients__c FROM PC_eletter__c WHERE Id=:letterId ];
                List<String> eLetterRoles = new List<String>();
                if(selectedELetter.PC_Target_Recipients__c != null) {
                    eLetterRoles = selectedELetter.PC_Target_Recipients__c.split(';');
                }
                //setting the eletterRecipient list based on the PC_Allow_Send_to_Patient__c,PC_Target_Recipients__c values.
                List<SMSRecipient> tempRecList= new List<SMSRecipient>();
                for (Integer i = 0; i <eLetterRecipients.size(); i++) {
                    if (eLetterRecipients[i].role == PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE) {
                        if (selectedELetter.PC_Allow_Send_to_Patient__c) {
                            tempRecList.add(eLetterRecipients[i]);
                        }
                    } else if (!eLetterRoles.isEmpty() && eLetterRoles.contains(eLetterRecipients[i].role)) {
                        tempRecList.add(eLetterRecipients[i]);
                    }
                }
                //Assign tempRecList to the eLetterRecipient List
                eLetterRecipients=tempRecList;
                //Adding the Pre Configured SMS Recipients to the eLetterRecipient List
                for(SMSRecipient rec:preConfiguredRecipients){
                    if(String.isNotBlank(rec.name) && String.isNotBlank(rec.phone) && rec.name!=null && rec.phone!=null){
                        rec.Id= generateDummyId();
                        rec.recipientType = PC_Constants.PC_EXTERNAL_RECIPIENTS;
                        eLetterRecipients.add(rec);
                    }else{
                        throw new PC_eLetter2Controller.Eletter2Exception(System.Label.PC_IncorrectPreConfiguredSMSRecipients_Error);
                    }
                }
            }
            eLetterInfo = new EletterInfo(eLetterRecipients, templatePlainTextBody);
            System.debug('eletterInfo===' +eLetterInfo);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return eLetterInfo;
    }

    /**
     * This method helps generate a dummy Id for non-case/external recipients
     * @param- void
     * @return- String dummyId
     */
    public static String generateDummyId()
    {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String dummyId = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        return dummyId;
    }

    /**
   * This method gets the PreConfiguredRecipients based on the eletterId
   * @param engagementProgramId    Engagement Program Id
   * @param eletterId              Eletter Record Id
   *
   * @return List<SMSRecipient>
   */
    public static List<SMSRecipient> getPreConfiguredRecipients(String engagementProgramId, String eletterId) {
        List<SMSRecipient> preConfiguredRecipients = new List<SMSRecipient>();
        String preConfiguredRecipientsString;
        try {
            // FLS for Engagement Program ELetter
            List<String> engagementProgEletterFields = new List<String>();
            engagementProgEletterFields = new List<String>{
                    'Id', PC_Constants.getQualifiedAPIName('PC_PreConfiguredSMSRecipients__c'), PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterFields);

            if (String.isNotBlank(eletterId) && String.isNotBlank(engagementProgramId)) {
                preConfiguredRecipientsString = [SELECT Id, PC_PreConfiguredSMSRecipients__c, PC_Engagement_Program__c, PC_eLetter__c FROM PC_Engagement_Program_Eletter__c WHERE PC_eLetter__c = :eletterId and PC_Engagement_Program__c = :engagementProgramId ORDER BY PC_eLetter__r.Name ASC, LastModifiedDate DESC LIMIT 1] ?. PC_PreConfiguredSMSRecipients__c;
                if (String.isNotBlank(preConfiguredRecipientsString)) {
                    try {
                        preConfiguredRecipients = (List<SMSRecipient>) System.JSON.deserialize(preConfiguredRecipientsString, List<SMSRecipient>.class);
                    } catch (Exception ex) {
                        throw new PC_eLetter2Controller.Eletter2Exception(System.Label.PC_IncorrectPreConfiguredSMSRecipients_Error);
                    }
                }
            }
        }
        catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        System.debug('preConfiguredRecipients--> ' +preConfiguredRecipients);
        return preConfiguredRecipients;
    }

    /**
   * retrieves rendered email template based on whatId and whoid.
   *
   * @param recordId         id of the source object.
   * @param caseRecordId     whatId for rendering email template
   * @param eletterId        eletter Id to get Template name.
   *
   * @return RenderedMailTemplate  Returns rendered email template details
   */
    @AuraEnabled
    public static List<RenderedMailTemplate> getRenderedMailTemplate(Id recordId,String selectedRecipients,Id eletterId) {
        List<RenderedMailTemplate> renderedMailTemplateList = new List<RenderedMailTemplate>();
        PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
        Messaging.SingleEmailMessage singleEmailMessage;
        List<SMSRecipient> recipient = (List<SMSRecipient>) System.JSON.deserialize(selectedRecipients, List<SMSRecipient>.class);
        String templatePlainTextBody,recipientId;
        try {
            for(SMSRecipient rec: recipient) {
                recipientId = rec.Id;
                RenderedMailTemplate renderedMailTemplate = new RenderedMailTemplate();
                if (recipientId != null) {
                    renderedMailTemplate.recipientId= recipientId;
                    if (rec.recipientType == PC_Constants.PC_ACCOUNT) {
                        //FLS check for Contact
                        List<String> accountFields = new List<String>{
                                'Id', 'HealthCloudGA__PrimaryContact__c'
                        };
                        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
                        List<Account> accList = [
                                Select Id,HealthCloudGA__PrimaryContact__c
                                From Account
                                where id = :recipientId
                        ];
                        if (accList.size() > 0) {
                            if (accList[0].HealthCloudGA__PrimaryContact__c != null) {
                                recipientId = accList[0].HealthCloudGA__PrimaryContact__c;
                            } else {
                                recipientId = accList[0].Id;
                            }
                        } else {
                            recipientId = null;
                        }
                    }
                    if(rec.recipientType == PC_Constants.PC_EXTERNAL_RECIPIENTS){
                        previewRequest.whoId = null;
                    }else {
                        previewRequest.whoId = recipientId;
                    }
                }
                if (recordId != null) {
                    previewRequest.whatId = recordId;
                }
                if (eLetterId != null) {
                    EmailTemplate emailTemplate = new emailTemplate();
                    PC_eLetter__c eLetter = PC_eLetterService.getELetter(eLetterId);
                    if (eLetter != null && eLetter.PC_Template_Name__c != null) {
                        emailTemplate = PC_SYSTEM.getEmailTemplateDetails(eLetter.PC_Template_Name__c);
                        previewRequest.templateId = emailTemplate.Id;
                        templatePlainTextBody = emailTemplate.Body;
                    }
                    //Get eLetter content for preview
                    if (previewRequest.templateId != null) {
                        singleEmailMessage = Messaging.renderStoredEmailTemplate(previewRequest.templateId, previewRequest.whoId, previewRequest.whatId);
                    }
                    if (singleEmailMessage != null) {
                        renderedMailTemplate.renderedTextBody = singleEmailMessage.getPlainTextBody();
                        renderedMailTemplate.plainTextBody = templatePlainTextBody;
                    }
                }
                renderedMailTemplateList.add(renderedMailTemplate);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        System.debug('renderedMailTemplateList--->' +renderedMailTemplateList);
        return renderedMailTemplateList;
    }
    /********************************************************************************
      Description          : Wrappers for loading the SMSSender2 data
      *********************************************************************************/
    public with sharing class SMSSender {
         @AuraEnabled public String name { get; set; }
        //Stores the display name of the sender.
        @AuraEnabled public String phone { get; set; }
        //Stores the phone number specific to the sender

        public SMSSender() {
            this.name = PC_Constants.EMPTY_STRING;
            this.phone = PC_Constants.EMPTY_STRING;
        }
        public SMSSender(String name, String phone) {
            this.name = name;
            this.phone = phone;
        }
    }
    public with sharing class SMSRecipient{

        @AuraEnabled public String Id{get; set;}
        //Stores the Id of the recipient
        @AuraEnabled public String name{get; set;}
        //Stores the name of the Recipient
        @AuraEnabled public String role{get; set;}
        //Stores the type of the Account & role of the user acting as recipient
        @AuraEnabled public String phone{get; set;}
        //Stores the phone number of the recipient.
        @AuraEnabled public String communicationPreference {get;set;}
        //Stores the communication preference of the recipient.
        @AuraEnabled public Boolean sendSms{get; set;}
        // Boolean check for Sending sms
        @AuraEnabled  public Boolean disableSms {get;set;}
        //Boolean check for disabling recipients
        @AuraEnabled public Boolean hasNoPhoneNumber{get;set;}
        //Boolean check for availability of phone number
        @AuraEnabled public String recipientType{get;set;}
        //Stores the type of the recipient i.e. user or account
        @AuraEnabled public String msgBody{get;set;}
        //Stores the Association record Id
        @AuraEnabled public String associationId{get; set;}
        public SMSRecipient() {
            this.name = PC_Constants.EMPTY_STRING;
            this.role = PC_Constants.EMPTY_STRING;
            this.phone = PC_Constants.EMPTY_STRING;
            this.communicationPreference = PC_Constants.EMPTY_STRING;
            this.sendSms= False;// Set to false by default.
            this.disableSms=False;//Set to false by default.
            this.hasNoPhoneNumber=False;//Set to false by default.
            this.Id=PC_Constants.EMPTY_STRING;
            this.recipientType=PC_Constants.EMPTY_STRING;
            this.msgBody=PC_Constants.EMPTY_STRING;
            this.associationId=PC_Constants.EMPTY_STRING;

        }
        public SMSRecipient(String name , String role, String phone, Boolean sendSms, Boolean disableSms, Boolean hasNoPhoneNumber,String Id,String recipientType,String msgBody ) {
            this.name = name;
            this.role = role;
            this.phone = phone;
            this.sendSms= sendSms;
            this.disableSms= disableSms;
            this.hasNoPhoneNumber=hasNoPhoneNumber;
            this.Id=Id;
            this.recipientType=recipientType;
            this.msgBody=msgBody;
        }

    }
    /**
   * Wrapper for the eletter template.
   */
    public class EletterTemplate {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String categories { get; set; }
        @AuraEnabled public String engProgEletterDescription { get; set; }

        public EletterTemplate(PC_Engagement_Program_Eletter__c epe) {
            name = epe.PC_eLetter__r.Name;
            value = epe.PC_eLetter__r.Id;
            categories  = epe.PC_eLetter__r.PC_Category__c; // value is separated by Semicolon(;)
            description = epe.PC_eLetter__r.PC_Description__c;
            engProgEletterDescription = epe.PC_Description__c;
        }
    }
    /**
  * Wrapper for the eLetter Recipients and rendered template
  */
    public class EletterInfo {
        @AuraEnabled public List<SMSRecipient> eLetterRecipients { get; set; }
        @AuraEnabled public String templatePlainTextBody{get; set;}

        public EletterInfo() {
        }
        public EletterInfo(List<SMSRecipient> eLetterRecipients, String templatePlainTextBody ) {
            this.eLetterRecipients = eLetterRecipients;
            this.templatePlainTextBody= templatePlainTextBody;
        }
    }
    /**
   * Wrapper for the rendered mail template.
   */
    public class RenderedMailTemplate {
        @AuraEnabled public String recipientId{get; set;}
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String templateType { get; set; }
        @AuraEnabled public String renderedTextBody { get; set; }
        @AuraEnabled public String plainTextBody { get; set; }

        public RenderedMailTemplate() {
            this.recipientId= PC_Constants.EMPTY_STRING;
            this.name = PC_Constants.EMPTY_STRING;
            this.templateType = PC_Constants.EMPTY_STRING;
            this.renderedTextBody= PC_Constants.EMPTY_STRING;
            this.plainTextBody = PC_Constants.EMPTY_STRING;
        }

        public RenderedMailTemplate(String recipientId,String name, String templateType, String renderedTextBody,String plainTextBody) {
            this.recipientId= recipientId;
            this.name = name;
            this.templateType = templateType;
            this.renderedTextBody= renderedTextBody;
            this.plainTextBody = plainTextBody;
        }
    }

    public with sharing class SMSSenderInfo {
        @AuraEnabled public List<SMSSender> senders { get; set; }
        //Stores the list of data related to the sender.
        @AuraEnabled public List<SMSRecipient> recipients { get; set; }
        //Stores the list of data related to the recipient.
        @AuraEnabled public List<EletterTemplate> eletterTemplateList{ get; set;}
        //Stores the list of eletterTemplates

        public SMSSenderInfo() {
        }
        public SMSSenderInfo(List<SMSSender> senders, List<SMSRecipient> recipients,List<EletterTemplate> eletterTemplateList) {
            this.senders = senders;
            this.recipients = recipients;
            this.eletterTemplateList = eletterTemplateList;
        }
    }
    /**
     * Wrapper for Message related details to be returned on send.
     */
    public inherited sharing class MessageDetails{
        @AuraEnabled public List<PC_Message__c> messages {get; set;}
        @AuraEnabled public String messageObjectName {get; set;}
        @AuraEnabled public String messageRelationshipName{get; set;}
        public List<MessageRecipientDetail> messageRecipientDetails{get; set;}
        public MessageDetails(){
            messageRecipientDetails = new List<MessageRecipientDetail>();
        }
    }

    public inherited sharing class RecipientsInfoResponse{
        public List<RecipientsByCaseId> recipientDetails{get;set;}
        public RecipientsInfoResponse(){
            recipientDetails = new List<RecipientsByCaseId>();
        }
    }
    public inherited sharing class RecipientsByCaseId{
        public List<SMSRecipient> recipients{get;set;}
        public String caseId{get;set;}
        public RecipientsByCaseId(){
            recipients = new List<SMSRecipient>();
            caseId = '';
        }
    }
    /**
    * Retrieves eLetters and case association recipients based on eletter id and caseIds
    *
    * @param letterId       Id of the eletter
    * @param caseIds       caseIds for getting recipients
    * @return getRecipientsInfo   This returns values of both eLetterRecipients and rendered eletterTemplate
    */
    public static RecipientsInfoResponse getRecipientsInfo(String letterId, List<String> caseIds) {
        RecipientsInfoResponse recipientsInfo = new RecipientsInfoResponse();
        String engagementProgramId = PC_Constants.EMPTY_STRING;
        List<SMSRecipient> eLetterRecipients,preConfiguredRecipients;
        List<String> engagementProgramIds = new List<String>();

        // FLS Check
        List<String> caseFields = new List<String>{'Id','Name',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

        Map<String,Case> casesMap = new Map<String,Case>([SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id IN: caseIds]);
        for(Case eachCase : casesMap.values()){
            engagementProgramIds.add(eachCase.PC_Engagement_Program__c);
        }

        Map<String,List<SMSRecipient>> eLetterRecipientsMap = new Map<String,List<SMSRecipient>>();
        eLetterRecipientsMap = getRecipients(caseIds);//get the list of recipients
        Map<String,List<SMSRecipient>> preConfiguredRecipientsMap = new Map<String, List<SMSRecipient>>();
        preConfiguredRecipientsMap = getPreConfiguredRecipientsMap(engagementProgramIds,letterId);//external recipients

        //FLS Check
        List<String> eletterFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Allow_Send_to_Patient__c'),
                PC_Constants.getQualifiedAPIName('PC_Target_Recipients__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'),PC_Database.Operation.Reading, eletterFields);
        PC_eletter__c selectedELetter = new PC_eletter__c();
        selectedELetter= [SELECT PC_Allow_Send_to_Patient__c,PC_Target_Recipients__c FROM PC_eletter__c WHERE Id=:letterId ];


        try {
            for(String recordId : caseIds){
                if (String.isNotBlank(letterId)) {
                    engagementProgramId = casesMap.get(recordId).PC_Engagement_Program__c;
                    eLetterRecipients = eLetterRecipientsMap.get(recordId);
                    preConfiguredRecipients = preConfiguredRecipientsMap.get(engagementProgramId);
                    List<String> eLetterRoles = new List<String>();
                    if(selectedELetter.PC_Target_Recipients__c != null) {
                        eLetterRoles = selectedELetter.PC_Target_Recipients__c.split(';');
                    }
                    //setting the eletterRecipient list based on the PC_Allow_Send_to_Patient__c,PC_Target_Recipients__c values.
                    List<SMSRecipient> tempRecList= new List<SMSRecipient>();
                    for (Integer i = 0; i <eLetterRecipients.size(); i++) {
                        if (eLetterRecipients[i].role == PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE) {
                            if (selectedELetter.PC_Allow_Send_to_Patient__c) {
                                tempRecList.add(eLetterRecipients[i]);
                            }
                        } else if (!eLetterRoles.isEmpty() && eLetterRoles.contains(eLetterRecipients[i].role)) {
                            tempRecList.add(eLetterRecipients[i]);
                        }
                    }
                    //Assign tempRecList to the eLetterRecipient List
                    eLetterRecipients=tempRecList;
                    //Adding the Pre Configured SMS Recipients to the eLetterRecipient List
                    if(preConfiguredRecipients != null){
                        for(SMSRecipient rec:preConfiguredRecipients){
                            if(String.isNotBlank(rec.name) && String.isNotBlank(rec.phone)){
                                rec.Id= generateDummyId();
                                rec.recipientType = PC_Constants.PC_EXTERNAL_RECIPIENTS;
                                eLetterRecipients.add(rec);
                            }else{
                                throw new PC_eLetter2Controller.Eletter2Exception(System.Label.PC_IncorrectPreConfiguredSMSRecipients_Error);
                            }
                        }
                    }
                }
                RecipientsByCaseId recipientsById = new RecipientsByCaseId();
                recipientsById.caseId = recordId;
                recipientsById.recipients = eLetterRecipients;
                recipientsInfo.recipientDetails.add(recipientsById);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return recipientsInfo;
    }

    /*********************************************************************************
     Method Name    : getRecipients
     Description    : Retrieve the recipient data for the sending the message to.
     Parameter      : String caseId   - current case Id
    *********************************************************************************/

    public static Map<String,List<SMSRecipient>> getRecipients(List<String> caseIds) {

        //CRUD/FLS Check for case
        List<String> caseFields = new List<String>{
                'AccountId', 'Account.Name', 'Account.phone',
                'Account.HealthCloudGA__PrimaryContact__r.phone', 'Account.PC_Preferred__c'
        };
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

        //FLS check for association
        List<String> assocFields = new List<String>{
                'Id', PC_Constants.getQualifiedAPIName('PC_Associated_User_Name__c'), PC_Constants.getQualifiedAPIName('PC_Role__c'),
                PC_Constants.getQualifiedAPIName('PC_Account__c'), PC_Constants.getQualifiedAPIName('PC_Associated_User__c'),
                PC_Constants.getQualifiedAPIName('PC_AssociationStatus__c')

        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, assocFields);

        //Query to get field values from Case object and Association i.e. a child object of Case.
        Map<Id, Case> casesMap;
        if (caseIds != null && !caseIds.isEmpty()) {
            casesMap = new Map<Id, Case>([
                    SELECT AccountId, Account.Name,Account.phone, Account.HealthCloudGA__PrimaryContact__r.phone, Account.PC_Preferred__c, (SELECT Id,PC_Associated_User_Name__c, toLabel(PC_Role__c), PC_Account__c, PC_Associated_User__c FROM Associations__r WHERE PC_AssociationStatus__c = 'Active')
                    FROM case
                    where Id IN:caseIds
            ]);
        }
        Map<ID, String> accAssociation = new Map<ID, String>();
        Map<ID, String> userAssociation = new Map<ID, String>();
        Map<String,List<SMSRecipient>> recipientsMapByCaseId = new Map<String,List<SMSRecipient>>();

        for(String caseId : caseIds) {
            Case recipientDetails = new Case();
            List<SMSRecipient> recipientsDetails = new List<SMSRecipient>();
            recipientDetails = casesMap.get(caseId);
            SMSRecipient patient = new SMSRecipient();
            if (recipientDetails.Account != null) {
                patient.name = recipientDetails.Account.Name;
                patient.role = PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE;
                if (recipientDetails.Account.HealthCloudGA__PrimaryContact__r.phone != null) {
                    patient.phone = recipientDetails.Account.HealthCloudGA__PrimaryContact__r.phone;
                } else {
                    patient.phone = recipientDetails.Account.phone;
                }
                patient.recipientType = PC_Constants.PC_ACCOUNT;
                patient.Id = recipientDetails.AccountId;
                patient.communicationPreference = recipientDetails.Account.PC_Preferred__c;
                if (patient.phone == null) {
                    patient.disableSms = True;
                    patient.hasNoPhoneNumber = True;
                }
                recipientsDetails.add(patient);
                recipientsMapByCaseId.put(caseId,recipientsDetails);
            }
            for (PC_Association__c association : recipientDetails.Associations__r) {
                if (association.PC_Account__c == null && association.PC_Associated_User__c != null) {
                    userAssociation.put(association.Id, association.PC_Associated_User__c);
                } else {
                    accAssociation.put(association.Id, association.PC_Account__c);
                }
            }
        }
        //FLS check for User
        List<String> userFields = new List<String>{
                'Name', 'Phone'
        };
        PC_Database.assertAccess(PC_Constants.PC_USER, PC_Database.Operation.Reading, userFields);

        //Map to store values from user object
        Map<ID, User> usersMap = new Map<ID, User>([Select Name,Phone from User where Id IN:userAssociation.values()]);

        //FLS check for Account
        List<String> accountFields = new List<String>{
                'Name', 'Phone', PC_Constants.getQualifiedAPIName('PC_Preferred__c'), PC_Constants.getQualifiedAPIName('HealthCloudGA__PrimaryContact__r') + '.' + 'Phone'
        };
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

        //Map to store values from account object
        Map<ID, Account> accountsMap = new Map<ID, Account>([Select Name,Phone, PC_Preferred__c, HealthCloudGA__PrimaryContact__r.Phone from Account where Id IN:accAssociation.values()]);
        for(String caseId : caseIds){
            List<SMSRecipient> recipientsDetailsByCaseId = new List<SMSRecipient>();
            for (PC_Association__c association : casesMap.get(caseId).Associations__r) {
                if (userAssociation.containsKey(association.Id)) {
                    SMSRecipient recipient = new SMSRecipient();
                    recipient.name = usersMap.get(association.PC_Associated_User__c).Name;
                    recipient.Id = association.PC_Associated_User__c;
                    recipient.role = association.PC_Role__c;
                    recipient.phone = String.valueOf(usersMap.get(association.PC_Associated_User__c).phone);
                    recipient.recipientType = PC_Constants.PC_USER;
                    if (recipient.phone == null) {
                        recipient.disableSms = True;
                        recipient.hasNoPhoneNumber = True;
                    }
                    recipient.associationId = association.Id;
                    recipientsDetailsByCaseId.add(recipient);
                } else {
                    SMSRecipient recipient = new SMSRecipient();
                    recipient.name = accountsMap.get(association.PC_Account__c).Name;
                    recipient.Id = association.PC_Account__c;
                    recipient.role = association.PC_Role__c;
                    if (accountsMap.get(association.PC_Account__c).HealthCloudGA__PrimaryContact__r.Phone != null) {
                        recipient.phone = String.valueOf(accountsMap.get(association.PC_Account__c).HealthCloudGA__PrimaryContact__r.Phone);
                    } else {
                        recipient.phone = String.valueOf(accountsMap.get(association.PC_Account__c).Phone);
                    }
                    recipient.communicationPreference = accountsMap.get(association.PC_Account__c).PC_Preferred__c;
                    recipient.recipientType = PC_Constants.PC_ACCOUNT;
                    if (recipient.phone == null) {
                        recipient.disableSms = True;
                        recipient.hasNoPhoneNumber = True;
                    }
                    recipient.associationId = association.Id;
                    recipientsDetailsByCaseId.add(recipient);
                }
            }
            if(recipientsMapByCaseId.containsKey(caseId)){
                recipientsMapByCaseId.get(caseId).addAll(recipientsDetailsByCaseId);
            }else{
                recipientsMapByCaseId.put(caseId,recipientsDetailsByCaseId);
            }

        }
        return recipientsMapByCaseId;
    }

    /**
  * This method gets the PreConfiguredRecipients based on the eletterId
  * @param engagementProgramIds    Engagement Program Ids
  * @param eletterId              Eletter Record Id
  *
  * @return Map<String,List<SMSRecipient>>
  */
    private static Map<String,List<SMSRecipient>> getPreConfiguredRecipientsMap(List<String> engagementProgramIds, String eletterId) {
        List<SMSRecipient> preConfiguredRecipients = new List<SMSRecipient>();
        Map<String,List<SMSRecipient>> preConfiguredRecipientsMap = new Map<String,List<SMSRecipient>>();
        try {
            // FLS for Engagement Program ELetter
            List<String> engagementProgEletterFields = new List<String>();
            engagementProgEletterFields = new List<String>{
                    'Id', PC_Constants.getQualifiedAPIName('PC_PreConfiguredSMSRecipients__c'), PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterFields);

            List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = new List<PC_Engagement_Program_Eletter__c>([SELECT Id, PC_PreConfiguredSMSRecipients__c, PC_Engagement_Program__c, PC_eLetter__c FROM PC_Engagement_Program_Eletter__c WHERE PC_eLetter__c = :eletterId and PC_Engagement_Program__c IN: engagementProgramIds ORDER BY PC_eLetter__r.Name ASC, LastModifiedDate DESC]);
            Map<String,PC_Engagement_Program_Eletter__c> engagementProgramAndEPEletterMap = new Map<String,PC_Engagement_Program_Eletter__c>();
            for(PC_Engagement_Program_Eletter__c programELetter : engagementProgramEletters){
                if(!engagementProgramAndEPEletterMap.containsKey(programELetter.PC_Engagement_Program__c)){
                    engagementProgramAndEPEletterMap.put(programELetter.PC_Engagement_Program__c,programELetter);
                }
            }

            for(String engagementProgramId : engagementProgramIds){
                String preConfiguredRecipientsString;
                if (String.isNotBlank(eletterId) && String.isNotBlank(engagementProgramId)) {
                    if(engagementProgramAndEPEletterMap.get(engagementProgramId) != null){
                        preConfiguredRecipientsString = engagementProgramAndEPEletterMap.get(engagementProgramId).PC_PreConfiguredSMSRecipients__c;
                    }
                    if (String.isNotBlank(preConfiguredRecipientsString)) {
                        try {
                            preConfiguredRecipients = (List<SMSRecipient>) System.JSON.deserialize(preConfiguredRecipientsString, List<SMSRecipient>.class);
                            preConfiguredRecipientsMap.put(engagementProgramId,preConfiguredRecipients);
                        } catch (Exception ex) {
                            throw new PC_eLetter2Controller.Eletter2Exception(System.Label.PC_IncorrectPreConfiguredSMSRecipients_Error);
                        }
                    }
                }
            }
        }
        catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return preConfiguredRecipientsMap;
    }

    public inherited sharing class MessageRequest{
        public List<MessageRecipientDetail> messageRecipientDetails{get;set;}
        public MessageRequest(){
            messageRecipientDetails = new List<MessageRecipientDetail>();
        }
        public MessageRequest(List<MessageRecipientDetail> recipientDetails){
            messageRecipientDetails = recipientDetails;
        }
    }
    public inherited sharing class MessageRecipientDetail{
        public String recordId{get;set;}
        public String sender{get;set;}
        public SMSRecipient recipient{get;set;}
        public String eLetterId{get;set;}
        public String errorMessage{get;set;}
        public PC_Message__c messageRecord{get;set;}

        public MessageRecipientDetail(){
            sender = '';
            errorMessage = '';
        }
    }
    public static MessageDetails sendMessages(MessageRequest messageRequest) {
        List<PC_Message__c> messageList = new List<PC_Message__c> ();
        Map<String,PC_Engagement_Program_Eletter__c> eletterEngagementProgramEletterMap = new Map<String,PC_Engagement_Program_Eletter__c>();
        List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = new List<PC_Engagement_Program_Eletter__c>();
        MessageDetails messageDetailsToReturn = new MessageDetails();
        Map<String, String> recipientSpecificMessages= new Map<String,String>();
        Map<String,MessageRecipientDetail> messageRecipientDetailMap = new Map<String,MessageRecipientDetail>();
        Set<String> eLetterIds = new Set<String>();
        List<String> caseIds = new List<String>();
        try{
            for(MessageRecipientDetail eachRecipientDetail : messageRequest.messageRecipientDetails){
                messageRecipientDetailMap.put(eachRecipientDetail.recordId+eachRecipientDetail.recipient.Id,eachRecipientDetail);
                eLetterIds.add(eachRecipientDetail.eLetterId);
                caseIds.add(eachRecipientDetail.recordId);
            }
            //FLS Check
            List<String> engagementProgramEletterFields = new List<String>{'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_eLetter__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgramEletterFields);

            if(eLetterIds != null && !eLetterIds.isEmpty()) {
                //get the eletter Name from Engagement Program eletter
                engagementProgramEletters = [
                        SELECT Id, Name, PC_eLetter__c
                        FROM PC_Engagement_Program_Eletter__c
                        WHERE PC_eLetter__c IN: eLetterIds
                ];
            }
            for(PC_Engagement_Program_Eletter__c eachProgramEletter : engagementProgramEletters){
                eletterEngagementProgramEletterMap.put(eachProgramEletter.PC_eLetter__c,eachProgramEletter);
            }
            //Getting all message bodies
            getAllMessageBodies(messageRequest.messageRecipientDetails);

            //Getting the transaction Id
            String transactionId = PC_Utility.generateTransactionId(PC_Constants.PC_MESSAGE_TRANSACTION_ID_KEY);

            Map<String,List<SMSSender>> sendersMap = new Map<String, List<SMSSender>>();
            sendersMap = getSendersMap(caseIds);

            for(MessageRecipientDetail recipientDetail : messageRequest.messageRecipientDetails){
                PC_Message__c newMessage;
                if(sendersMap.get(recipientDetail.recordId) != null){
                    recipientDetail.sender = sendersMap.get(recipientDetail.recordId)[0].phone;
                    newMessage = getMessageRecord(recipientDetail.recordId,recipientDetail.sender, recipientDetail.recipient, transactionId,String.valueOf(eletterEngagementProgramEletterMap.get(recipientDetail.eLetterId).Id));
                }
                //create Messages List
                if(newMessage != null){
                    messageList.add(newMessage);
                }
            }
            PC_SMS.BatchSenderResponse messagesResponse = new PC_SMS.BatchSenderResponse();
            String serviceName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_BATCH_SMS_SERVICE_NAME,'');
            if(String.isNotBlank(serviceName)) {
                if(isBatchServiceClassValid(serviceName)){
                    messagesResponse = callBatchSmsService(serviceName,messageList);      //Calling the sms service
                }
                else {
                    PC_SMS.SMSException ex = new PC_SMS.SMSException();
                    ex.setMessage(System.Label.PC_BatchSMSIntegrationErrorMessage);
                    throw ex;
                }
            }

            //Message details to be returned for client-side processing.
            List<String> messageIds = new List<String>();
            List<PC_Message__c> messageDetails = new List<PC_Message__c>();
            messageIds = messagesResponse.messageIds;
            if(!messageIds.isEmpty()){
                List<String> msgFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_Case__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Message__c'), PC_Database.Operation.Reading, msgFields);
                messageDetails = [SELECT Id, Name, PC_Case__c, PC_Receiver__c, PC_Content__c, PC_Message_Status__c, PC_MessageStatusDetails__c FROM PC_Message__c WHERE Id IN: messageIds];
                messageDetailsToReturn.messages= messageDetails;
                messageDetailsToReturn.messageObjectName=PC_Constants.getQualifiedAPIName('PC_Message');
                messageDetailsToReturn.messageRelationshipName=PC_Constants.getQualifiedAPIName('Messages__r');
            }
            for(PC_Message__c eachMsg : messageDetails){
                if(messageRecipientDetailMap != null && messageRecipientDetailMap.get(eachMsg.PC_Case__c + eachMsg.PC_Receiver__c) != null){
                    messageRecipientDetailMap.get(eachMsg.PC_Case__c + eachMsg.PC_Receiver__c).messageRecord = eachMsg;
                }
            }
            if(messageRecipientDetailMap != null){
                messageDetailsToReturn.messageRecipientDetails = messageRecipientDetailMap.values();
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return messageDetailsToReturn;
    }
    public static List<MessageRecipientDetail> getAllMessageBodies(List<MessageRecipientDetail> messageRecipientDetails) {
        PC_eLetterPreviewController.PreviewRequest previewRequest = new PC_eLetterPreviewController.PreviewRequest();
        Messaging.SingleEmailMessage singleEmailMessage;
        String templatePlainTextBody,recipientId;
        Set<String> eLetterIds = new Set<String>();
        Set<String> accountIds = new Set<String>();
        try{
            for(MessageRecipientDetail eachRecipientDetail: messageRecipientDetails){
                //SMSRecipient recipient = (SMSRecipient) System.JSON.deserialize(eachRecipientDetail.recipient, SMSRecipient.class);
                if(eachRecipientDetail.recipient.recipientType == PC_Constants.PC_ACCOUNT){
                    accountIds.add(eachRecipientDetail.recipient.Id);
                }
                if(String.isNotBlank(eachRecipientDetail.eLetterId)){
                    eLetterIds.add(eachRecipientDetail.eLetterId);
                }
            }
            //FLS Check
            List<String> eLetterFields = new List<String>{
                    'Name',
                    PC_Constants.getQualifiedAPIName('PC_Template_Name__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);

            Map<Id,PC_eLetter__c> eLettersMap = new Map<Id,PC_eLetter__c>([
                    SELECT Id, Name, PC_Template_Name__c
                    FROM PC_eLetter__c
                    WHERE Id IN: eLetterIds
            ]);
            List<String> allTemplateNames = new List<String>();
            for(PC_eLetter__c eLetter : eLettersMap.values()){
                if(eLetter.PC_Template_Name__c != null){
                    allTemplateNames.add(eLetter.PC_Template_Name__c);
                }
            }

            /** FLS Check for EmailTemplate */
            List<String> emailTemplateFields = new List<String>{'DeveloperName', 'Body'};
            PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE,PC_Database.Operation.Reading, emailTemplateFields);
            List<EmailTemplate> emailTemplates = new List<EmailTemplate>([SELECT Id, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName IN: allTemplateNames]);
            Map<String,EmailTemplate> templatesMap = new Map<String,EmailTemplate>();
            for(EmailTemplate template : emailTemplates){
                templatesMap.put(template.DeveloperName,template);
            }
            //FLS check for Account
            List<String> accountFields = new List<String>{
                    'Id', 'HealthCloudGA__PrimaryContact__c'
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
            Map<Id,Account> accountsMap = new Map<Id,Account>([
                    Select Id, HealthCloudGA__PrimaryContact__c
                    From Account
                    where Id IN: accountIds
            ]);

            for(MessageRecipientDetail recipientDetail: messageRecipientDetails){
                String smsRecipientId = recipientDetail.recipient.Id;
                if (smsRecipientId != null) {
                    if (recipientDetail.recipient.recipientType == PC_Constants.PC_ACCOUNT) {
                        Account recipientAccount = new Account();
                        recipientAccount = accountsMap.get(smsRecipientId);
                        if(recipientAccount != null){
                            if (recipientAccount.HealthCloudGA__PrimaryContact__c != null) {
                                smsRecipientId = recipientAccount.HealthCloudGA__PrimaryContact__c;
                            }else{
                                smsRecipientId = recipientAccount.Id;
                            }
                        }else{
                            smsRecipientId = null;
                        }
                    }
                    if(recipientDetail.recipient.recipientType == PC_Constants.PC_EXTERNAL_RECIPIENTS){
                        previewRequest.whoId = null;
                    }else {
                        previewRequest.whoId = smsRecipientId;
                    }
                }
                if(recipientDetail.recordId != null){
                    previewRequest.whatId = recipientDetail.recordId;
                }
                if (recipientDetail.eLetterId != null) {
                    EmailTemplate emailTemplate = new emailTemplate();
                    PC_eLetter__c eLetter = eLettersMap.get(recipientDetail.eLetterId);
                    if (eLetter != null && eLetter.PC_Template_Name__c != null) {
                        emailTemplate = templatesMap.get(eLetter.PC_Template_Name__c);
                        previewRequest.templateId = emailTemplate.Id;
                        templatePlainTextBody = emailTemplate.Body;
                    }
                    //Get eLetter content for preview
                    if (previewRequest.templateId != null){
                        singleEmailMessage = Messaging.renderStoredEmailTemplate(previewRequest.templateId, previewRequest.whoId, previewRequest.whatId);
                    }
                    if (singleEmailMessage != null) {
                        recipientDetail.recipient.msgBody = singleEmailMessage.getPlainTextBody();
                    }
                }
            }
        }catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return messageRecipientDetails;
    }
    /**************************************************************************************************************************
   Method Name    : getMessageRecord
   Author         : Kishore Kanteti
   Description    : This method is used for creating an instance of message record, populate values and return.
   Return Type    : PC_Message__c
   Parameter      : String caseId, String sender, SMSRecipient recipient, String transactionId, String engagementProgramEletterId
   **************************************************************************************************************************/
    private static PC_Message__c getMessageRecord(String caseId, String sender,SMSRecipient recipient, String transactionId,String engagementProgramEletterId){

        PC_Message__c msg = new PC_Message__c();
        msg.PC_Case__c = caseId;
        msg.PC_Content__c = recipient.msgBody.escapeHtml4();
        msg.PC_Hide_from_Feed__c = false;
        msg.PC_Message_Date__c = datetime.now();
        msg.PC_Sender__c = UserInfo.getUserId();
        if(recipient.recipientType == PC_Constants.PC_ACCOUNT){

            msg.PC_ReceiverAccount__c = recipient.Id;
        }
        else if(recipient.recipientType == PC_Constants.PC_USER){
            msg.PC_ReceiverUser__c = recipient.Id;
        }
        else{
            msg.PC_ExternalRecipientNumber__c = recipient.phone;
            msg.PC_ExternalRecipientName__c = recipient.name;
        }
        if(String.isNotBlank(engagementProgramEletterId)){
            msg.PC_SMSEletter__c= engagementProgramEletterId;
        }
        msg.PC_Receiver__c = recipient.Id;
        msg.PC_Type__c = PC_Constants.OUTBOUND;
        msg.PC_Message_Status__c = PC_SMS.PC_SMS_DRAFT;
        msg.PC_TransactionId__c = transactionId;
        msg.PC_FromAlias__c = sender;
        msg.Name = recipient.name;

        return msg;
    }

    /*********************************************************************************
     Retrieve all the sender numbers from where the message will be sent.
     * @param- String[] caseIds
     * @return- Map<String,List<SMSSender>>
    *********************************************************************************/
    private static Map<String,List<SMSSender>> getSendersMap(List<String> caseIds) {
        List<SMSSender> senderData,engagementProgramPhoneNumber= new List<SMSSender>();
        Map<String,List<SMSSender>> engagementProgramPhoneNumbersMap = getEngagementProgramSpecificPhoneNumber(caseIds);

        Map<String,List<SMSSender>> allSMSSendersByCaseIds = new Map<String,List<SMSSender>>();

        if(!caseIds.isEmpty()){
            for(String caseId : caseIds){
                engagementProgramPhoneNumber = engagementProgramPhoneNumbersMap.get(caseId);
                //Conditions to check the value availability w.r.t both org-wide numbers and Engagement Program Specific numbers.
                if (!engagementProgramPhoneNumber.isEmpty()){
                        senderData = engagementProgramPhoneNumber;
                } else {
                    PC_SMS.SMSException ex = new PC_SMS.SMSException();
                    ex.setMessage(System.Label.PC_SenderNumberUnavailableError);
                    throw ex;
                }
                allSMSSendersByCaseIds.put(caseId,senderData);
            }
        }
        return allSMSSendersByCaseIds;
    }

    /**************************************************************************************************
     *This method helps fetch Engagement Program Specific Sender Phone Number
     * @param- String[] caseIds
     * @return- Map<String,List<SMSSender>>
     **************************************************************************************************/
    private static Map<String,List<SMSSender>> getEngagementProgramSpecificPhoneNumber(List<String> caseIds){
        Map<String,List<SMSSender>> caseIdEngagementProgramSpecificPhoneNumberList= new Map<String,List<SMSSender>>();

        Case caseEngagementProgramDetails= new Case();
        //CRUD/FLS Check for case
        List<String> caseFields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_Engagement_Program__r') + '.' +
                'PC_Program_Code__c'};
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);
        //Query to get the Program code w.r.t the Engagement Program of the Case.
        if(caseIds != null && !caseIds.isEmpty()){
            Map<Id,Case> casesMap = new Map<Id,Case>([SELECT Id, PC_Engagement_Program__r.PC_Program_Code__c FROM Case WHERE Id IN: caseIds]);
            for (String caseId : caseIds){
                List<SMSSender> engagementProgramSpecificPhoneNumberList = new List<SMSSender>();
                String valueInJSON, engagementProgramCode;
                caseEngagementProgramDetails = casesMap.get(caseId);
                engagementProgramCode = caseEngagementProgramDetails.PC_Engagement_Program__r.PC_Program_Code__c;
                valueInJSON = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PC_GLOBAL_SMS_SENDER_NUMBERS,
                        PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, ''
                );
                if (String.isNotBlank(valueInJSON)) {
                    engagementProgramSpecificPhoneNumberList = (List<SMSSender>) System.JSON.deserialize(valueInJSON, List<SMSSender>.class);
                }
                caseIdEngagementProgramSpecificPhoneNumberList.put(caseId,engagementProgramSpecificPhoneNumberList);
            }
        }
        return caseIdEngagementProgramSpecificPhoneNumberList;
    }
}