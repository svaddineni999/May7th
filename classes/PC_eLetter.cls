/******************************************************************************
  Modification Log:
  -----------------------------------------------------------------------------
  Developer             Date        Description
  -----------------------------------------------------------------------------
  Mike Klumpenaar       2018-01-03  Updated documentation for ApexDoc=
  Tushar Arora          2019-07-26  [PC-5181]: Added Patient PersonEmail condition in RecipientWrapper
  Kishore Kanteti       May 5,2020  [PC-5940] Added new value in RecipientType enum and a new method in document wrapper
  Satheesh Kumar        09-07-2020  [PC-6352] Created new interface Sender2 for outbound attachments and secure email
  Satheesh Kumar        16-11-2020  [PC-6978] Created new interface Sender3 for supporting outbound fax and email
Haritha Reddy          21-Jan-2021  [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 ******************************************************************************/

/**
 * The PC_eLetter class provides support for custom eLetter implementations.
 * A custom eLetter implementation, must create a class that implements the <code>Sender</code>
 * interface and register it in the <code>PC_System Settings__c</code> custom setting under the
 * <code>PC_eLetter_Sender_Class__c</code> field.
 * <p>
 * Currently, an eLetter sender must provide an implementation for all eLetter channels (fax and email).
 *
 * @author mklumpenaar
 * @date 3/8/2017.
 */
global inherited sharing class PC_eLetter {
    /**
     * A <code>Sender</code> is responsible for preparing the specified eLetter and delivering
     * it to a list of recipients. Each recipient is associated with a document that indicates
     * the channel that the eLetter should be delivered. The rendered eLetter should also be
     * attached to the document record.
     */
    global interface Sender {
        /**
         * Provides the implementation to send the eLetter through the specified channel. Implementors should
         * throw a <code>SendException</code> if they are unable to send the eLetter.
         *
         * @param objectId              Id of the object that the eLetter is being send from
         * @param documentRecipients    The selected recipients for the eLetter
         * @param eLetter               The eLetter template
         * @param sendToCurrentUser     Flag to specify if eLetter should only be sent to current user.
         */
        void sendLetter(Id objectId, List<DocumentWrapper> documentRecipients,
                PC_eLetter__c eLetter, Boolean sendToCurrentUser);
    }

    /**
     * A <code>Sender2</code> is responsible for preparing the specified eLetter and delivering
     * it to a list of recipients. Each recipient is associated with a document that indicates
     * the channel that the eLetter should be delivered. The rendered eLetter should also be
     * attached to the document record.
     */
    global interface Sender2 {
        /**
         * Provides the implementation to send the eLetter through the specified channel. Implementors should
         * throw a <code>SendException</code> if they are unable to send the eLetter.
         *
         * @param objectId              Id of the object that the eLetter is being send from
         * @param documentRecipients    The selected recipients for the eLetter
         * @param eLetter               The eLetter template
         * @param sendToCurrentUser     Flag to specify if eLetter should only be sent to current user.
         * @param isEmailSecure         Flag to specify whether is email is secure or not.
         * @param emailContent          Wrapper of email content like subject, attachmentIds
         */
        void sendLetter(Id objectId, List<DocumentWrapper> documentRecipients,
                PC_eLetter__c eLetter, Boolean sendToCurrentUser, Boolean isEmailSecure, EmailContent emailContent);
    }

    /**
     * A <code>Sender3</code> is responsible for preparing the specified eLetter and delivering
     * it to a list of recipients. Each recipient is associated with a document that indicates
     * the channel that the eLetter should be delivered.
     */
    global interface Sender3{
        /**
         * Provides the implementation to send the eLetter through the specified channel. Implementors should
         * returns the status of the eLetter using SenderResponse object.
         *
         * @param senderRequest    A Wrapper object which has all information required to send eLetter like emailContent, Recipients, attachments etc.
         * @return  SenderResponse (Status of the send eLetter Operation)
         */
        SenderResponse sendLetter(SenderRequest senderRequest);
    }

    /**
     * Enumeration to indicated the type of recipient <code>RecipientType</code>
     */
    global enum RecipientType { ACCOUNT, USER, CONTACT, PRE_CONFIGURED_EMAIL }

    /**
     * <code>DocumentWrapper</code> is a wrapper object for associating an eLetter recipient
     * with the outbound document that the rendered eLetter will be attached to.
     */
    global inherited sharing class DocumentWrapper {
        /**
         * DEPRECATED. Id of the record from where the eLetter is being triggered
         */
        global Id parentRecordId; //DEPRECATED.
        /**
         * Id of the patient that the eLetter is being send for
         */
        global Id patientAccountId;

        /**
         * Account of the eLetter recipient
         */
        global Account recipient;

        /**
         * Wrapper of the eLetter recipient Account and User
         */
        global RecipientWrapper recipient2;

        /**
         * Document that the eLetter will be attached to
         */
        global PC_Document__c doc;

        /**
         * Creates a new DocumentWrapper
         *
         * @param patientAccountId  Id of the patient that the eLetter is being send for
         * @param recipient         Account of the eLetter recipient
         * @param doc               Document that the eLetter will be attached to
         */
        global DocumentWrapper(Id patientAccountId, Account recipient, PC_Document__c doc) {
            this.patientAccountId = patientAccountId;
            this.recipient = recipient;
            this.doc = doc;
        }

        /**
         * Creates a new DocumentWrapper
         *
         * @param patientAccountId  Id of the patient that the eLetter is being send for
         * @param recipient         PC_eLetter_Recipient.recipientObject of the eLetter recipient
         * @param doc               Document that the eLetter will be attached to
         */
        global DocumentWrapper(Id patientAccountId, RecipientWrapper recipient, PC_Document__c doc) {
            this.patientAccountId = patientAccountId;
            this.recipient2 = recipient;
            this.doc = doc;
        }

        /**
         * Creates a new DocumentWrapper
         * @param parentRecordId    Id of the record where email got triggered
         * @param patientAccountId  Id of the patient that the eLetter is being send for
         * @param recipient         PC_eLetter_Recipient.recipientObject of the eLetter recipient
         * @param doc               Document that the eLetter will be attached to

         */
        global DocumentWrapper(Id parentRecordId, Id patientAccountId, RecipientWrapper recipient, PC_Document__c doc) {
            this.parentRecordId = parentRecordId;
            this.patientAccountId = patientAccountId;
            this.recipient2 = recipient;
            this.doc = doc;
        }
    }
    /**
     * RecipientWrapper is the wrapper object for holding all information of Recipient of eLetter
     */
    global inherited sharing class RecipientWrapper {
        /**
         * Id of the recipient
         */
        @AuraEnabled global ID Id { get; set; }
        /**
         * Communication Language of the recipient
         */
        @AuraEnabled global STRING communicationLanguage { get; set; }
        /**
         * Type of the recipient
         */
        @AuraEnabled global String type { get; set; }
        /**
         * Fax of the recipient
         */
        @AuraEnabled global STRING fax { get; set; }
        /**
         * Email of the recipient
         */
        @AuraEnabled global STRING email { get; set; }
        /**
         * Display Name of the recipient
         */
        @AuraEnabled global STRING name { get; set; }

        global RecipientWrapper() {}

        /**
         * Creates a new recipientWrapper
         *
         * @param Id                    Id of the account that the eLetter is being sent to
         * @param communicationLanguage Preferred communication language of the recipient
         * @param type                  Type of the recipient auto-set using RecipientType
         * @param fax                   Fax number of the recipient
         * @param email                 Email id of the recipient
         * @param name                  Display name of the recipient
         */
        global RecipientWrapper(Account a) {
            Id                      = a.Id;
            communicationLanguage   = a.PC_Communication_Language__c;
            type                    = RecipientType.ACCOUNT.name();
            fax                     = a.Fax;
            email                   = a.PC_Email__c;
            name                    = a.Name;
        }

        /**
         * Creates a new recipientWrapper
         *
         * @param Id                    Id of the user that the eLetter is being sent to
         * @param communicationLanguage Preferred communication language of the recipient
         * @param type                  Type of the recipient auto-set using RecipientType
         * @param fax                   Fax number of the recipient
         * @param email                 Email id of the recipient
         * @param name                  Display name of the recipient
         */
        global RecipientWrapper(User a) {
            Id                      = a.Id;
            communicationLanguage   = a.LanguageLocaleKey;
            type                    = RecipientType.USER.name();
            fax                     = a.Fax;
            email                   = a.Email;
            name                    = (a.LastName != null && a.FirstName != null) ? a.FirstName + ', ' + a.LastName
                    : (a.LastName == null && a.FirstName != null) ? a.FirstName : (a.LastName != null && a.FirstName == null) ? a.LastName : '';
        }

        /**
         * Creates a new recipientWrapper
         *
         * @param Id                    Id of the contact that the eLetter is being sent to
         * @param communicationLanguage Preferred communication language of the recipient
         * @param type                  Type of the recipient auto-set using RecipientType
         * @param fax                   Fax number of the recipient
         * @param email                 Email id of the recipient
         * @param name                  Display name of the recipient
         */
        global RecipientWrapper(Contact a) {
            Id                      = a.Id;
            communicationLanguage   = a.HealthCloudGA__PrimaryLanguage__c;
            type                    = RecipientType.CONTACT.name();
            fax                     = a.Fax;
            email                   = a.Email;
            name                    = a.Name;
        }
    }

    /**
     * Exception to indicated that the <code>Sender</code> was unable to send an eLetter.
     */
    global inherited sharing class SenderException extends Exception {}

    /**
     * EmailContent is a wrapper for all email related properties like subject and email attachments
     */
    global inherited sharing class EmailContent {
        global String subject;
        global List<String> attachmentIds;

        global EmailContent(String subject, List<String> attachmentIds) {
            this.subject = subject;
            this.attachmentIds = attachmentIds;
        }
    }


    /**
     * SenderRequest is the wrapper object for holding all information about outgoing eletter request
     */
    global inherited sharing class SenderRequest {
        /**
        * Wrapper object containing information related to outbound email request
        */
        global OutgoingEmail outgoingEmail;
        /**
        * Id of the object that the eLetter is being sent from. (ex. CaseIds)
        */
        global String relatedToId;
        /**
        * Id of the eLetter
        */
        global String eLetterId;
        /**
        * Boolean Property which helps to decide whether the email is to be secure or not.
        */
        global Boolean isSecureEmail;
        /**
        * The selected recipients for the eLetter with PC Document
        */
        global List<DocumentRecipient> documentRecipientList;
        /**
        * Wrapper for eletter Communication (like CommunicationMethod)
        */
        global CommunicationInfo communicationInfo;
        /**
        * Patient connect settings for eletter
        */
        global Settings settings;

        global SenderRequest() {
            outgoingEmail = new OutgoingEmail();
            relatedToId = PC_Constants.EMPTY_STRING;
            eLetterId = PC_Constants.EMPTY_STRING;
            isSecureEmail = PC_Constants.FALSE_BOOLEAN;
            communicationInfo = new CommunicationInfo();
            documentRecipientList = new List<DocumentRecipient>();
            settings = new Settings();
        }
    }

    /**
     * Contains the email Information of outbound eletter request.
     */
    global inherited sharing class OutgoingEmail {
        /**
        * From Address of the eLetter
        */
        global FromAddress fromAddress;
        /**
        * List of selected recipients for the eLetter
        */
        global List<RecipientWrapper> recipients;
        /**
        * Subject of the eletter
        */
        global String subject;
        /**
        * TextBody of the eLetter
        */
        global String textBody;
        /**
        * HtmlBody of the eLetter
        */
        global String htmlBody;
        /**
        * Reply-To address for the eletter
        */
        global String replyTo;
        /**
        * A list of selected attachments Ids
        */
        global List<String> attachmentIds;

        global OutgoingEmail() {
            fromAddress = new FromAddress();
            recipients = new List<RecipientWrapper>();
            subject = PC_Constants.EMPTY_STRING;
            textBody = PC_Constants.EMPTY_STRING;
            htmlBody = PC_Constants.EMPTY_STRING;
            replyTo = PC_Constants.EMPTY_STRING;
            attachmentIds = new List<String>();
        }
    }

    /**
     * FromAddress wrapper for outbound eletter request.
     */
    global inherited sharing class FromAddress {
        /**
        * Name of the from Address
        */
        global String name;
        /**
        * Email Address of the from Address
        */
        global String address;
        /**
        * Id of the from Address (UserId or OrgWideEmailAddress Id)
        */
        global String fromId;
        global FromAddress(){
            name = PC_Constants.EMPTY_STRING;
            address = PC_Constants.EMPTY_STRING;
            fromId = PC_Constants.EMPTY_STRING;
        }
    }

    /**
     * Enumaration to indicated the communication method eletter
     */
    global enum CommunicationMethod {EMAIL, FAX}

    /**
     * Contains the communication Information of a send eletter request.
     */
    global inherited sharing class CommunicationInfo {
        /**
         * Communication method of the eletter request (Fax or Email)
         */
        global CommunicationMethod communicationMethod;
        global CommunicationInfo(){
            communicationMethod = PC_eLetter.CommunicationMethod.EMAIL;
        }
    }

    /**
     * Wrapper for all required patient connect settings for eletter
     */
    global inherited sharing class Settings {
        /**
        * value of PC_EletterInsertThreadIdInSubject patient connect setting
        */
        global String insertThreadIdInSubject;
        /**
        * holds the value of useSalesforceFiles patient connect setting
        */
        global Boolean useSalesforceFiles;
        /**
        * holds the value of useDocumentPreviewInStrictMode patient connect setting
        */
        global Boolean useDocumentPreviewInStrictMode;
        /**
        * value of PC_AutomatedTaskEmail patient connect setting
        */
        global String automatedTaskEmail;
        global Settings() {
            insertThreadIdInSubject = PC_Constants.EMPTY_STRING;
            useSalesforceFiles = PC_Constants.FALSE_BOOLEAN;
            useDocumentPreviewInStrictMode = PC_Constants.FALSE_BOOLEAN;
            automatedTaskEmail = PC_Constants.EMPTY_STRING;
        }
    }


    /**
    * DocumentRecipient is a wrapper object for associating an eLetter recipient
    * with the outbound document that the rendered eLetter will be attached to.
    */
    global inherited sharing class DocumentRecipient {
        /**
         * Document that the eLetter will be attached to
         */
        global PC_Document__c document;
        /**
        * Wrapper of the eLetter recipient Account, Contact and User
        */
        global RecipientWrapper recipient;
        global DocumentRecipient() {
            document = new PC_Document__c();
            recipient = new RecipientWrapper();
        }
    }

    /**
     * Contains the results of send eletter response.
     */
    global inherited sharing class SenderResponse {
        /**
         * Status of a send eletter request.
         */
        global Boolean isSuccess;
        /**
         * Error message of a failed eletter request.
         */
        global String errorMessage;
        global SenderResponse() {
            isSuccess = PC_Constants.FALSE_BOOLEAN;
            errorMessage = PC_Constants.EMPTY_STRING;
        }
    }
}