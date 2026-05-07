/*********************************************************************************
  Class Name      : PC_eLetterAuraController
  Description     : Methods for eLetter service
  Created By      : Roxana Ivan
  Created Date    : 16-June-16
  Modification Log:
  ---------------------------------------------------------------------------------- 
  Developer                   Date                   Description
  -----------------------------------------------------------------------------------            
  Roxana Ivan               16-June-16              Initial Version
  Shabda Bhujad				Dec 08, 2016			Added FLS check to loadEletter,getParticipants methods
  Ajinkya Deshmukh			June 20, 2017			FLS Check Added (Code Merge)
  Tejas Patel               July-21-2017            [PC-1964 Transalation isssue]
  Mayuresh Patil            Jul 26, 2017            Update CRUD/FLS Check
  Shabda Bhujad 			Nov 16, 2017			PC-2513 Fax number on Account is not shown in the eletter component
  Mike Klumpenaar           2017-12-13              [PC-2601] Add support for Interaction object
  Tejas Patel               2019-03-13              [PC-4570] error handeling when no primary contact associated.
  Hitha Avalakki            10-April-19             [PC-2064] Added method to pull classic email template details of selected eLetter
  Mayuresh Patil
  Shabda Bhujad				2019-05-09				[PC-4837] Fix for eLetter error for 'User' based role in Association
  Tushar Arora              Jun 26, 2019            [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
  Tushar Arora              july 5, 2019            [PC-5087 Email Sending to Patient Person Account Using E-letter Action Center Button]
  Tushar Arora              Aug 14,2019             [PC-5277] Fix for Physician email not getting fetched on e-letter 
  Shishir Bansal            11-Dec-2019             [PC-5792] Avoid hardcoding of string variable
  Kanteti Kishore           May 5,2020              [PC-5940] Modified loadTargetInformation and create documents to support Adverse Event Objects and In case of no patient.
  Satheesh Kumar            Jul 13,2020             [PC-6352] Overloaded sendLetter method for eletter2(attachment support)
  Satheesh Kumar            Jul 31,2020             [PC-6622] Added getEngagementProgramId() method for populating engagement Program field in PC Document record
  Satheesh Kumar            Nov 18,2020             [PC-6730] Modified getParticipants method and added new sender3 instance to send eletter with enhanced requestParams
  Satheesh Kumar            Dec 14,2020             [PC-6960] Added fax field to the query to get contact fax number.
  Satheesh Kumar            Dec 17,2020             [PC-7159] Fix for invalid email address issue when accounts having multiple contacts.
  Haritha Reddy             Jan 21,2021             [PC-7102] Added FLS Check
  Satheesh Kumar            Mar 16,2021             [PC-7525] Moved getParticipants query to without sharing class to make it working for community user
  Hitha Avalakki            Mar 19,2021             [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
  Satheesh Kumar            Mar 31,2021             [PC-6836] Updated the query to retrieve Communication Preference from account object.
  Hitha Avalakki            Apr 07,2021             [PC-7537] Modified the existing method: getParticipants() in order to split the logic into more manageable code.
                                                     New methods:getRecipientsFromCasesAssociations(),getRecipientsFromAccount() added to fetch the eletter recipients from Association records and Account of case records.
  Satheesh Kumar            Jun 15,2021             [PC-7827] Populating to and from address in Outbound PC_Document
  Hitha Avalakki            Aug 19,2022             [PC-9138] Added code to fetch the contact for Person Accounts from PersonContact records. Also fetch contacts from HealthCloudGA__PrimaryContact record for business account records.
  *********************************************************************************/
public with sharing class PC_eLetterService {
    static Id OUTBOUND_FAX_RECORD_TYPE = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, 'PC_Fax_Outbound');
    static Id OUTBOUND_EMAIL_RECORD_TYPE = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, 'PC_Email_Outbound');

    private Set<Id> patientAccountIds = new Set<Id>();
    private Map<Id, Id> patientToObjectId = new Map<Id, Id>();

    public static PC_eLetter__c getELetter(Id eLetterId) {
        List<String> fields = new List<String> {
                'Name',
                PC_Constants.getQualifiedAPIName('PC_Target_Recipients__c'),
                PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'),
                PC_Constants.getQualifiedAPIName('PC_Template_Name__c'),
                PC_Constants.getQualifiedAPIName('PC_Allow_Send_to_Patient__c'),
                PC_Constants.getQualifiedAPIName('PC_Send_to_User__c'),
                PC_Constants.getQualifiedAPIName('PC_Category__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, fields);

        PC_eLetter__c eLetter = [
                SELECT Id, Name, PC_Target_Recipients__c, PC_Communication_Language__c, PC_Template_Name__c, PC_Allow_Send_to_Patient__c, PC_Send_to_User__c, PC_Category__c
                FROM PC_eLetter__c
                WHERE Id = :eLetterId
        ];

        return eLetter;
    }

    /*********************************************************************************
      Method Name    : getParticipants
      Description    : Based on the eLetterName get the relevant Participants for patient(s) for a single patient
      Return Type    : void 
      Parameter      : 1. caseId : Id of the Patient
      2. eLetter: eLetter record details
     *********************************************************************************/
    public static List<PC_eLetter_Recipient> getParticipants(Id caseId, PC_eLetter__c eLetter) {
        List<PC_eLetter_Recipient> recipients = getParticipants(new Set<Id> { caseId }, eLetter);
        if (recipients == null || recipients.size() == 0) {
            return null;
        }

        return recipients;
    }

    /*********************************************************************************
      Method Name    : getRelatedParticipants
      Description    : Based on the eLetterName get the relevant Participants for patient(s)
      Return Type    : void
      Parameter      : 1. caseIds : Number of Patients for whom the related recipients are required
      2. eLetter: eLetter record details
      3. loadedParticipants : Has some value only when invoked from eLetter page where recipients and their language are dyanmically selected at page level. So it won't be applicable for all related recipients
     *********************************************************************************/
    public Map<Id, List<PC_eLetter.RecipientWrapper>> getRelatedRecipients(List<PC_eLetter.RecipientWrapper> recipients) {
        // Fetch the eLetter details: The types of Participants to which the eLetters can be sent

        Map<Id, List<PC_eLetter.RecipientWrapper>> patientToRecipients = new Map<Id, List<PC_eLetter.RecipientWrapper>> ();
        //if loadedParticipants is not null ; i.e the list has been overwritten, and can be added directly for the Patient (single patient from eLetter page)
        if (recipients != null && patientAccountIds.size()>0){
            for (Id patient : patientAccountIds) {
                patientToRecipients.put(patient, recipients);
            }
        }

        return patientToRecipients;
    }

    /*********************************************************************************
      Method Name    : createDocuments
      Description    : Create document for a given set of Participants and return the formatted map
      Return Type    : void
      Parameter      : 1. patientToAccounts : Map holding the particiapnts related to a single Patient
      2. patientToRecordId:  Map holding the Patient Id and the record Id for which the document will be created
      3. eLetter: eLetter record details
     *********************************************************************************/
    public List<PC_eLetter.DocumentWrapper> createDocuments(Id objectId, String documentId, Map<Id, List<PC_eLetter.RecipientWrapper>> patientToRecipients, PC_eLetter__c eLetter, Id recordTypeId,List<PC_eLetter.RecipientWrapper> recipients, PC_eLetter2Controller.SendLetterRequest requestParams) {
        // Create the document records for all the relevant recipients:
        List<PC_Document__c> documents = new List<PC_Document__c>();
        List<PC_eLetter.DocumentWrapper> wrappers = new List<PC_eLetter.DocumentWrapper>();
        // Get Engagement Program Id for PC Document
        String engagementProgramId = getEngagementProgramId(objectId);
        String documentRecordTypeName = PC_SYSTEM.recordTypeDeveloperNameById(PC_Constants.DOCUMENT_OBJECT , recordTypeId);
        // From Address
        PC_eLetter2Controller.FromAddress fromAddress = new PC_eLetter2Controller.FromAddress();
        if(requestParams != null && String.isNotBlank(requestParams?.fromAddress?.fromId)){
            fromAddress = requestParams.fromAddress;
        } else {
            String currentUserType = UserInfo.getUserType();
            String PC_AutomatedTaskEmail = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL, '');
            if (currentUserType == PC_Constants.PC_AUTOMATED_PROCESS_USERTYPE && String.isNotBlank(PC_AutomatedTaskEmail)) {
                for (OrgWideEmailAddress o : [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :PC_AutomatedTaskEmail LIMIT 1]) {
                    fromAddress.fromId = o.Id;
                    fromAddress.address = o.Address;
                    fromAddress.name = o.DisplayName;
                }
            } else {
                fromAddress.fromId = UserInfo.getUserId();
                fromAddress.address = UserInfo.getUserEmail();
                fromAddress.name = UserInfo.getName();
            }
        }

        if(!patientToRecipients.keySet().isEmpty()){
            for (Id patientAccountId : patientToRecipients.keySet()) {
                for (PC_eLetter.RecipientWrapper recipient : patientToRecipients.get(patientAccountId)) {
                    PC_Document__c doc = new PC_Document__c(
                            RecordTypeId = recordTypeId,
                            PC_Document_Status__c = PC_Constants.PC_NEW,
                            PC_From_Name__c = fromAddress.name,
                            PC_Engagement_Program__c = (String.isNotBlank(engagementProgramId) ? engagementProgramId : null),
                            PC_Parent_Document__c = (String.isNotBlank(documentId) ? documentId : null)
                    );
                    if ((PC_Constants.DOCUMENT_FAX_OUTBOUND_RECORD_TYPE).equalsIgnoreCase(documentRecordTypeName)) {
                        doc.PC_To_Fax_Number__c = recipient.fax;
                        doc.PC_To_Fax_Name__c = recipient.name;
                    } else if ((PC_Constants.DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE).equalsIgnoreCase(documentRecordTypeName)){
                        doc.PC_From_Email_Address__c = fromAddress.address;
                        doc.PC_To_Email_Address__c = recipient.email;
                    }
                    documents.add(doc);
                    wrappers.add(new PC_eLetter.DocumentWrapper(objectId, patientAccountId, recipient, doc));
                }
            }
        }else{
            for(PC_eLetter.RecipientWrapper recipient : recipients){
                PC_Document__c doc = new PC_Document__c(
                        RecordTypeId = recordTypeId,
                        PC_Document_Status__c = PC_Constants.PC_NEW,
                        PC_From_Name__c = fromAddress.name,
                        PC_Engagement_Program__c = (String.isNotBlank(engagementProgramId) ? engagementProgramId : null),
                        PC_Parent_Document__c = (String.isNotBlank(documentId) ? documentId : null)
                );
                if ((PC_Constants.DOCUMENT_FAX_OUTBOUND_RECORD_TYPE).equalsIgnoreCase(documentRecordTypeName)) {
                    doc.PC_To_Fax_Number__c = recipient.fax;
                    doc.PC_To_Fax_Name__c = recipient.name;
                } else if ((PC_Constants.DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE).equalsIgnoreCase(documentRecordTypeName)){
                    doc.PC_From_Email_Address__c = fromAddress.address;
                    doc.PC_To_Email_Address__c = recipient.email;
                }
                documents.add(doc);
                wrappers.add(new PC_eLetter.DocumentWrapper(objectId,null, recipient, doc));
            }
        }
        try {
            PC_Database.ins(documents);

            // TODO: verify if we want to keep task generation or defer to solution implementation
            // Create tasks for all documents inserted above
            /*List<Task> tasks = new List<Task>();

            for (PC_eLetter.DocumentWrapper dw : wrappers) {
                tasks.add(PC_ActivityService.eLetterTask(objectId, dw.doc.id, eLetter.Name));
            }

            PC_Database.ins(tasks);*/
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return wrappers;
    }

    /**
     * Method to be used at eLetterManagement page, where recipient's language can differ based on the selection
     * at page level and the communication method can be fax/email
     *
     * @param objectId      Id for which the eLetter has to be sent - Program Case Id
     * @param eLetter       eLetter record
     * @param communicationMethod   Fax or Email
     * @param recipients    Has some value only when invoked from eLetter page where recipients and their language
     *                      are dyanmically selected at page level. So it won't be applicable for all related recipients.
     * @param sendToUser    True, if the eLetter should be send to the current user.
     */
    public static void sendLetter(Id objectId, PC_eLetter__c eLetter, String communicationMethod, List<PC_eLetter.RecipientWrapper> recipients, Boolean sendToUser) {
        PC_eLetterService service = new PC_eLetterService();

        if (communicationMethod != null && communicationMethod.toLowerCase() == PC_Constants.FAX) {
            service.sendLetter(objectId, eLetter, recipients, OUTBOUND_FAX_RECORD_TYPE, sendToUser, null);
        } else {
            service.sendLetter(objectId, eLetter, recipients, OUTBOUND_EMAIL_RECORD_TYPE, sendToUser, null);
        }
    }

    /**
     * Method to be used at eLetterManagement page, where recipient's language can differ based on the selection
     * at page level and the communication method can be fax/email
     *
     * @param objectId      Id for which the eLetter has to be sent - Program Case Id
     * @param eLetter       eLetter record
     * @param communicationMethod   Fax or Email
     * @param recipients    Has some value only when invoked from eLetter page where recipients and their language
     *                      are dyanmically selected at page level. So it won't be applicable for all related recipients.
     * @param sendToUser    True, if the eLetter should be send to the current user.
     * @param request       eLetter request.
     */
    public static void sendLetter(Id objectId, PC_eLetter__c eLetter, String communicationMethod, List<PC_eLetter.RecipientWrapper> recipients, Boolean sendToUser, PC_eLetter2Controller.SendLetterRequest request) {
        PC_eLetterService service = new PC_eLetterService();
        // [PC-6352] - To Provide secure email with attachments in outbound email, added 3 new parameters isEmailSecure, subject, attachmentIds
        if (communicationMethod != null && communicationMethod.toLowerCase() == PC_Constants.FAX) {
            request.communicationMethod = PC_Constants.FAX;
            service.sendLetter(objectId, eLetter, recipients, OUTBOUND_FAX_RECORD_TYPE, sendToUser, request);
        } else {
            request.communicationMethod = PC_Constants.EMAIL;
            service.sendLetter(objectId, eLetter, recipients, OUTBOUND_EMAIL_RECORD_TYPE, sendToUser, request);
        }
    }

    private void sendLetter(Id objectId, PC_eLetter__c eLetter, List<PC_eLetter.RecipientWrapper> recipients, Id docRecordTypeId, Boolean sendToCurrentUser, PC_eLetter2Controller.SendLetterRequest requestParams) {
        Boolean isEmailSecure;
        String subject, documentId;
        List<String> attachmentIds = new List<String>();
        if(requestParams != null){
            documentId = requestParams.documentId;
            isEmailSecure = requestParams.isSecureEmail;
            subject = requestParams.subject;
            attachmentIds = requestParams.attachmentIds;
        }
        loadTargetInformation(objectId);
        Map<Id, List<PC_eLetter.RecipientWrapper>> patientToRecipients = getRelatedRecipients(recipients);

        // Create document records for the patients' recipients & get the respective document ids (for attaching the merged templates to these documents)
        List<PC_eLetter.DocumentWrapper> documents = new List<PC_eLetter.DocumentWrapper>();
        documents = createDocuments(objectId, documentId, patientToRecipients, eLetter, docRecordTypeId, recipients, requestParams);
        PC_eLetter.EmailContent emailContent = new PC_eLetter.EmailContent(subject, attachmentIds);

        try {
            String eLetterSender = PC_System_Settings__c.getInstance().PC_eLetter_Sender_Class__c;
            if (String.isBlank(eLetterSender)) {
                throw new PC_eLetter.SenderException('No sender class registered in PC_SystemSettings custom setting');
            }
            Type t = Type.forName(eLetterSender);

            if (t != null) {
                Object o = t.newInstance();

                if (o instanceof PC_eLetter.Sender) {
                    PC_eLetter.Sender sender = (PC_eLetter.Sender) o;
                    sender.sendLetter(objectId, documents, eLetter, sendToCurrentUser);
                } else if (o instanceof PC_eLetter.Sender2) {
                    PC_eLetter.Sender2 sender2 = (PC_eLetter.Sender2) o;
                    sender2.sendLetter(objectId, documents, eLetter, sendToCurrentUser, isEmailSecure, emailContent);
                } else if (o instanceof PC_eLetter.Sender3) {
                    PC_eLetter.Sender3 sender3 = (PC_eLetter.Sender3) o;
                    if(requestParams == null){
                        requestParams = new PC_eLetter2Controller.SendLetterRequest();
                        requestParams.sendToCurrentUser = sendToCurrentUser;
                        requestParams.recordId = objectId;
                        requestParams.eletterId = eLetter.Id;
                    }
                    PC_eLetter.SenderRequest request = createEletterSenderRequest(documents, requestParams);
                    PC_eLetter.SenderResponse response = sender3.sendLetter(request);
                    if(!response.isSuccess) {
                        throw new PC_eLetter.SenderException('Problem in Sending Eletter. Please contact your administrator');
                    }
                } else {
                    throw new PC_eLetter.SenderException('Registered eLetter.Sender, ' +  eLetterSender + ' does not implement required interface.');
                }
            } else {
                throw new PC_eLetter.SenderException('Registered eLetter.Sender , ' + eLetterSender + ' class not found. Check PC_System_Settings.');
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /**
     * Method to collect the patient ids from the recipients
     *
     * @param objectId Id for which the eLetter has to be sent
     */
    private void loadTargetInformation(Id objectId) {
        SObjectType sObjectType = objectId.getSobjectType();

        if (sObjectType == Case.sObjectType) {
            Case programCase = [SELECT Id, AccountId FROM Case WHERE Id = :objectId];
            patientAccountIds.add(programCase.AccountId);
            patientToObjectId.put(programCase.AccountId, programCase.Id);
        } else if (sObjectType == PC_Program_Coverage__c.sObjectType) {
            PC_Program_Coverage__c coverage = [SELECT Id, PC_Program__c, PC_Program__r.AccountId FROM PC_Program_Coverage__c WHERE Id = :objectId];
            patientAccountIds.add(coverage.PC_Program__r.AccountId);
            patientToObjectId.put(coverage.PC_Program__r.AccountId, coverage.Id);
        } else if (sObjectType == PC_Interaction__c.sObjectType) {
            PC_Interaction__c interaction = [SELECT Id, PC_Patient_Program__c, PC_Patient_Program__r.AccountId FROM PC_Interaction__c WHERE Id = :objectId];
            patientAccountIds.add(interaction.PC_Patient_Program__r.AccountId);
            patientToObjectId.put(interaction.PC_Patient_Program__r.AccountId, interaction.Id);
        }else if(sObjectType == PC_AdverseEvent__c.sObjectType){

            List<String> aeFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Patient__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, aeFields);

            PC_AdverseEvent__c adverseEvent = [SELECT Id,PC_Patient__c FROM PC_AdverseEvent__c WHERE Id = :objectId];
            patientAccountIds.add(adverseEvent.PC_Patient__c);
            patientToObjectId.put(adverseEvent.PC_Patient__c, adverseEvent.Id);
        }else if(sObjectType == PC_AdverseEvent2__c.sObjectType){

            List<String> ae2Fields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Patient__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, ae2Fields);

            PC_AdverseEvent2__c adverseEvent2 = [SELECT Id,PC_Patient__c FROM PC_AdverseEvent2__c WHERE Id = :objectId];
            if(adverseEvent2.PC_Patient__c != null) {
                patientAccountIds.add(adverseEvent2.PC_Patient__c);
                patientToObjectId.put(adverseEvent2.PC_Patient__c, adverseEvent2.Id);
            }
        }
    }

    /*********************************************************************************
      Method Name    : geteLetterPreview
      Description    : Method to pull classic email template details of selected eLetter
      Return Type    : PC_eLetter.PreviewResponse
      Parameter      : PC_eLetter.PreviewRequest previewRequest
    *********************************************************************************/
    public static Messaging.SingleEmailMessage geteLetterPreview(PC_eLetterPreviewController.PreviewRequest previewRequest) {
        Messaging.SingleEmailMessage email;
        try {
            email= PC_emailTemplate_eLetterPreview.getEletterPreview(previewRequest);

        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return email;
    }

    /*********************************************************************************
      Method Name    : getEngagementProgramId
      Description    : Method to get Engagement Program Id for case, Program Coverage and Interaction
      Return Type    : String
      Parameter      : Id - recordId
    *********************************************************************************/
    public static String getEngagementProgramId(Id recordId){
        String engagementProgramId;
        String recordIdObjectType = String.valueOf(Id.valueOf(recordId).getSobjectType());
        if (recordIdObjectType == PC_Constants.PC_CASE) {
            // FLS Check
            List<String> caseFields = new List<String>{ 'Id', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c') };
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

            Case caseObj = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id = :recordId];
            engagementProgramId = ((caseObj != null && caseObj.PC_Engagement_Program__c != null) ? caseObj.PC_Engagement_Program__c : null);
        } else if (recordIdObjectType == PC_Constants.PC_INTERACTION) {
            // FLS Check
            List<String> interactionFields = new List<String>{ 'Id', PC_Constants.getQualifiedAPIName('PC_Patient_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_Patient_Program__r')+ '.' +PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_INTERACTION, PC_Database.Operation.Reading, interactionFields);

            PC_Interaction__c interactionObject = [SELECT Id, PC_Patient_Program__c, PC_Patient_Program__r.PC_Engagement_Program__c FROM PC_Interaction__c WHERE Id = :recordId];
            engagementProgramId = ((interactionObject != null && interactionObject.PC_Patient_Program__r.PC_Engagement_Program__c != null) ? interactionObject.PC_Patient_Program__r.PC_Engagement_Program__c : null);
        } else if (recordIdObjectType == PC_Constants.PC_PROGRAM_COVERAGE) {
            // FLS Check
            List<String> programCoverageFields = new List<String>{ 'Id', PC_Constants.getQualifiedAPIName('PC_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_Program__r')+ '.' +PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_PROGRAM_COVERAGE, PC_Database.Operation.Reading, programCoverageFields);

            PC_Program_Coverage__c progCoverageObject = [SELECT Id, PC_Program__c, PC_Program__r.PC_Engagement_Program__c FROM PC_Program_Coverage__c WHERE Id = :recordId];
            engagementProgramId = ((progCoverageObject != null && progCoverageObject.PC_Program__r.PC_Engagement_Program__c != null) ? progCoverageObject.PC_Program__r.PC_Engagement_Program__c : null);
        }
        return engagementProgramId;
    }


    /**
     * Method is used to create SenderRequest object for eletter
     *
     * @param documentWrapper       documentWrapper
     * @param eLetterRequest   SendLetterRequest obj holds all the request parameter of an eletter
     */
    public PC_eLetter.SenderRequest createEletterSenderRequest(List<PC_eLetter.DocumentWrapper> documentWrapper, PC_eLetter2Controller.SendLetterRequest eLetterRequest){
        PC_eLetter.SenderRequest request = new PC_eLetter.SenderRequest();

        PC_eLetter.FromAddress fromAddress = new PC_eLetter.FromAddress();
        PC_eLetter.OutgoingEmail outgoingEmail = new PC_eLetter.OutgoingEmail();
        PC_eLetter.CommunicationInfo communicationInfo = new PC_eLetter.CommunicationInfo();
        PC_eLetter.Settings settings = new PC_eLetter.Settings();
        List<PC_eLetter.DocumentRecipient> documentRecipientList = new List<PC_eLetter.DocumentRecipient>();
        List<PC_eLetter.RecipientWrapper> recipients = new List<PC_eLetter.RecipientWrapper>();
        Set<Id> accIds = new Set<Id>();

        // get all recipient Id of type Account
        for(PC_eLetter.DocumentWrapper docWrapper : documentWrapper) {
            if (docWrapper.recipient2.type == PC_eLetter.RecipientType.ACCOUNT.name()) {
                accIds.add(docWrapper.recipient2.Id);
            }
        }

        List<String> accountFields = new List<String> {'Id','HealthCloudGA__PrimaryContact__r.Email',
                'HealthCloudGA__PrimaryContact__r.Fax', 'HealthCloudGA__PrimaryContact__r.Name',
                'HealthCloudGA__PrimaryContact__r.HealthCloudGA__PrimaryLanguage__c', 'HealthCloudGA__PrimaryContact__c'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

        // Fetch primary contact of accounts
        List<Account> recipientAccounts= new List<Account>();

        Map<Id, Contact> accountContactMap = new Map<Id, Contact>();
        if (PC_SYSTEM.isPersonAccountEnabled()) {
            String accountStrQuery='';

            accountStrQuery = 'SELECT Id,IsPersonAccount, PersonContactId,' +
                                'HealthCloudGA__PrimaryContact__r.Email, HealthCloudGA__PrimaryContact__r.Fax, HealthCloudGA__PrimaryContact__r.Name, ' +
                                'HealthCloudGA__PrimaryContact__r.HealthCloudGA__PrimaryLanguage__c ' +
                                'FROM Account ' +
                                'WHERE Id IN :accIds';

            List<Account> listOfAccounts = Database.query(accountStrQuery);

            if(listOfAccounts!=null && !listOfAccounts.isEmpty()) {

                List<Id> contactIdList = new List<Id>();
                List<Contact> listOfContacts = new List<Contact>();
                String contactStrQuery = '';
                Map<Id, Contact> mapOfContacts = new Map<Id, Contact>();

                for (Account accountRecord : listOfAccounts) {
                    if (accountRecord.get('IsPersonAccount') == true && accountRecord.get('PersonContactId') != null) {
                        contactIdList.add((Id) accountRecord.get('PersonContactId'));
                    }
                }

                contactStrQuery = 'SELECT Id,Name,Email,AccountId,Fax,HealthCloudGA__PrimaryLanguage__c FROM Contact WHERE Id in :contactIdList';

                listOfContacts = Database.query(contactStrQuery);

                if (listOfContacts!=null && !listOfContacts.isEmpty()) {

                    for (Contact contact : listOfContacts) {
                        mapOfContacts.put(contact.Id, contact);
                    }
                }

                for (Account acc : listOfAccounts) {
                    if(acc.get('IsPersonAccount')==true && acc.get('PersonContactId')!=null) {
                        accountContactMap.put(acc.Id, mapOfContacts.get((Id)acc.get('PersonContactId')));
                    }else{
                        accountContactMap.put(acc.Id, acc.HealthCloudGA__PrimaryContact__r);
                    }
                }
            }
        }
        else{
            recipientAccounts = [
                    SELECT Id, HealthCloudGA__PrimaryContact__r.Email, HealthCloudGA__PrimaryContact__r.Fax, HealthCloudGA__PrimaryContact__r.Name, HealthCloudGA__PrimaryContact__r.HealthCloudGA__PrimaryLanguage__c
                    FROM Account
                    WHERE Id in :accIds and HealthCloudGA__PrimaryContact__c != null
            ];

            for (Account acc : recipientAccounts) {
                accountContactMap.put(acc.Id, acc.HealthCloudGA__PrimaryContact__r);
            }
        }

        // Creating new List of DocumentRecipient and RecipientWrapper list
        for(PC_eLetter.DocumentWrapper docWrapper : documentWrapper){
            PC_eLetter.DocumentRecipient docRecipient = new PC_eLetter.DocumentRecipient();
            docRecipient.document = docWrapper.doc;
            if (docWrapper.recipient2.type == PC_eLetter.RecipientType.ACCOUNT.name()) {

                if(accountContactMap!=null && !accountContactMap.isEmpty() &&
                        accountContactMap.containsKey(docWrapper.recipient2.Id) &&
                        accountContactMap.get(docWrapper.recipient2.Id)!=null){
                    docRecipient.recipient = new PC_eLetter.RecipientWrapper(accountContactMap.get(docWrapper.recipient2.Id));
                    recipients.add(docRecipient.recipient);
                }
            } else if (docWrapper.recipient2.type == PC_eLetter.RecipientType.USER.name()) {
                docRecipient.recipient = docWrapper.recipient2;
                recipients.add(docWrapper.recipient2);
            } else if (docWrapper.recipient2.type == PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name()) {
                docRecipient.recipient = docWrapper.recipient2;
                recipients.add(docWrapper.recipient2);
            }
            system.debug('documentRecipients----'+docRecipient.recipient);
            documentRecipientList.add(docRecipient);
        }

        populateValidFromAddress(eLetterRequest);
        fromAddress.name = eLetterRequest.FromAddress.name;
        fromAddress.address = eLetterRequest.FromAddress.address;
        fromAddress.fromId = eLetterRequest.FromAddress.fromId;

        outgoingEmail.fromAddress = fromAddress;
        outgoingEmail.recipients = recipients;
        outgoingEmail.subject = eLetterRequest.subject;
        outgoingEmail.textBody = eLetterRequest.textBody;
        outgoingEmail.htmlBody = eLetterRequest.htmlBody;
        outgoingEmail.replyTo = getEmailServiceAddressId();
        outgoingEmail.attachmentIds = eLetterRequest.attachmentIds;

        communicationInfo.communicationMethod = (eLetterRequest.communicationMethod == PC_Constants.EMAIL ? PC_eLetter.CommunicationMethod.EMAIL : PC_eLetter.CommunicationMethod.FAX);

        request.outgoingEmail = outgoingEmail;
        request.relatedToId = eLetterRequest.recordId;
        request.eLetterId = (String.isNotBlank(eLetterRequest.eletterId))?eLetterRequest.eletterId:null;
        request.isSecureEmail = eLetterRequest.isSecureEmail;
        request.communicationInfo = communicationInfo;
        request.documentRecipientList = documentRecipientList;

        settings.insertThreadIdInSubject = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ELETTER_INSERT_THREAD_ID_IN_SUBJECT, PC_Constants.EMPTY_STRING);
        settings.automatedTaskEmail =  PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL, PC_Constants.EMPTY_STRING);
        settings.useSalesforceFiles =  PC_SYSTEM.useSalesforceFiles();
        settings.useDocumentPreviewInStrictMode =  PC_SYSTEM.useDocumentPreviewInStrictMode();
        request.settings = settings;

        return request;
    }

    /**
    * Returns Email Service Address Id
    * @return String    returns the Email Service Address ID
    */
    public String getEmailServiceAddressId() {
        String emailServiceAddressId = PC_Constants.EMPTY_STRING;
        String emailServiceName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_INBOUND_EMAIL_SERVICE_NAME, PC_Constants.EMPTY_STRING);
        String emailAddressName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_INBOUND_EMAIL_ADDRESS_NAME, PC_Constants.EMPTY_STRING);
        if (String.isNotBlank(emailServiceName) && String.isNotBlank(emailAddressName)) {
            for (EmailServicesAddress emailServicesAddress : [SELECT Id, Function.FunctionName, LocalPart, DeveloperName, EmailDomainName FROM EmailServicesAddress WHERE Function.FunctionName = :emailServiceName and DeveloperName = :emailAddressName]) {
                emailServiceAddressId = emailServicesAddress.LocalPart + '@' + emailServicesAddress.EmailDomainName;
            }
            if (String.isBlank(emailServiceAddressId)) {
                throw new AuraHandledException(System.Label.PC_EmailServiceAddress_Error);
            }
        }
        return emailServiceAddressId;
    }

    /***
    * Class Name      : RunWithElevatedPrivileges
    * Description     : Helps to run some methods with elevated privileges
    **/
    public without sharing class RunWithElevatedPrivileges {
        public List<PC_Association__c> getProgramCaseAssociations(Set<Id> programIds, PC_eLetter__c eLetter){
            List<PC_Association__c> patientParticipants = new List<PC_Association__c>();
            List<String> targetRecipientRoles  = new List<String>();
            String associationStatus = PC_Constants.ACTIVE;
            try {
                if(String.isNotBlank(eLetter.PC_Target_Recipients__c)){
                    targetRecipientRoles.addAll(eLetter.PC_Target_Recipients__c.split(';'));
                }
                List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Account__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Role__c'), PC_Constants.getQualifiedAPIName('PC_Associated_User__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);
                fields = new List<String>{'Name', 'Type', 'RecordTypeId', 'Fax', PC_Constants.getQualifiedAPIName('PC_Preferred__c'), PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'), PC_Constants.getQualifiedAPIName('PC_Email__c'), 'HealthCloudGA__PrimaryContact__c'};
                PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
                List<String> userFields = new List<String>{'Email', 'Fax', 'FirstName', 'LastName'};
                PC_Database.assertAccess(PC_Constants.PC_USER, PC_Database.Operation.Reading, userFields);
                List<String> contactFields = new List<String>{'Email', 'Fax'};
                PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);

                String query = PC_Constants.EMPTY_STRING;
                // Fetch all the Participants related to the patient (ACTIVE ones only) and Physician location details (as for a physician the location is explicitly selected)
                if (String.isNotBlank(eLetter.Name)) {
                    if (PC_SYSTEM.isPersonAccountEnabled()) {
                        query = 'SELECT Id, PC_Account__c,PC_Account__r.PersonEmail, PC_Account__r.PC_Preferred__c, PC_Account__r.PC_Communication_Language__c, PC_Account__r.Type, PC_Account__r.Name, PC_Account__r.RecordTypeId,PC_Account__r.PC_Email__c,PC_Account__r.Fax, PC_Program__c, PC_Role__c, toLabel(PC_Role__c) RoleLabel, PC_Account__r.HealthCloudGA__PrimaryContact__r.Email, PC_Account__r.HealthCloudGA__PrimaryContact__r.Fax, toLabel(PC_Associated_User__r.LanguageLocaleKey),PC_Associated_User__c, PC_Associated_User__r.Email, PC_Associated_User__r.Fax, PC_Associated_User__r.FirstName, PC_Associated_User__r.LastName FROM PC_Association__c WHERE PC_Program__c in :programIds AND PC_Role__c IN : targetRecipientRoles AND PC_AssociationStatus__c =: associationStatus ';
                    } else {
                        query = 'SELECT Id, PC_Account__c, PC_Account__r.PC_Preferred__c, PC_Account__r.PC_Communication_Language__c, PC_Account__r.Type, PC_Account__r.Name, PC_Account__r.RecordTypeId, PC_Account__r.PC_Email__c,PC_Account__r.Fax, PC_Program__c, PC_Role__c, toLabel(PC_Role__c) RoleLabel, PC_Account__r.HealthCloudGA__PrimaryContact__r.Email, PC_Account__r.HealthCloudGA__PrimaryContact__r.Fax,toLabel(PC_Associated_User__r.LanguageLocaleKey), PC_Associated_User__c, PC_Associated_User__r.Email, PC_Associated_User__r.Fax, PC_Associated_User__r.FirstName, PC_Associated_User__r.LastName FROM PC_Association__c WHERE PC_Program__c in :programIds AND PC_Role__c IN : targetRecipientRoles  AND PC_AssociationStatus__c =: associationStatus' ;
                    }
                } else {
                    if (PC_SYSTEM.isPersonAccountEnabled()) {
                        query = 'SELECT Id, PC_Account__c,PC_Account__r.PersonEmail, PC_Account__r.PC_Preferred__c, PC_Account__r.PC_Communication_Language__c, PC_Account__r.Type, PC_Account__r.Name, PC_Account__r.RecordTypeId,PC_Account__r.PC_Email__c,PC_Account__r.Fax, PC_Program__c, PC_Role__c, toLabel(PC_Role__c) RoleLabel, PC_Account__r.HealthCloudGA__PrimaryContact__r.Email, PC_Account__r.HealthCloudGA__PrimaryContact__r.Fax, toLabel(PC_Associated_User__r.LanguageLocaleKey),PC_Associated_User__c, PC_Associated_User__r.Email, PC_Associated_User__r.Fax, PC_Associated_User__r.FirstName, PC_Associated_User__r.LastName FROM PC_Association__c WHERE PC_Program__c in :programIds AND PC_AssociationStatus__c =: associationStatus ';
                    } else {
                        query = 'SELECT Id, PC_Account__c, PC_Account__r.PC_Preferred__c, PC_Account__r.PC_Communication_Language__c, PC_Account__r.Type, PC_Account__r.Name, PC_Account__r.RecordTypeId, PC_Account__r.PC_Email__c,PC_Account__r.Fax, PC_Program__c, PC_Role__c, toLabel(PC_Role__c) RoleLabel, PC_Account__r.HealthCloudGA__PrimaryContact__r.Email, PC_Account__r.HealthCloudGA__PrimaryContact__r.Fax,toLabel(PC_Associated_User__r.LanguageLocaleKey), PC_Associated_User__c, PC_Associated_User__r.Email, PC_Associated_User__r.Fax, PC_Associated_User__r.FirstName, PC_Associated_User__r.LastName FROM PC_Association__c WHERE PC_Program__c in :programIds AND PC_AssociationStatus__c =: associationStatus' ;
                    }
                }

                System.debug('getProgramCaseAssociations: '+query);
                patientParticipants = database.query(query);
                return patientParticipants;
            } catch (Exception ex) {
                PC_Utility.logAndThrowException(ex);
                return null;
            }
        }
    }

    /*********************************************************************************
      Method Name    : getParticipants
      Description    : Based on the eLetterName get the relevant Participants for patient(s)
      Return Type    : List<PC_eLetter_Recipient>
      Parameter      : 1. caseIds : Number of Patients for whom the related recipients are required
                       2. eLetter: eLetter record details
     *********************************************************************************/
    public static List<PC_eLetter_Recipient> getParticipants(Set<Id> caseIds, PC_eLetter__c eLetter) {
        /* PC-7537: Please note we are using 'mapOfCasesRecipients' in order to make sure we have unique list of recipients from related case records.
           This is necessary when a service case record and its related program case record both have the same Reimbursement Specialist/Physician/Care Coordinator*/

        Map<Id, Map<String,PC_eLetter_Recipient>> mapOfCasesRecipients = new Map<Id, Map<String, PC_eLetter_Recipient>>();
        Set<Id> programIds = new Set<Id>();
        Map<String, PC_eLetter_Recipient> finalMapOfRecipients =  new Map<String, PC_eLetter_Recipient>();

        try{
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('Type')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            /* Prepare list of all case record ids and its related program case record ids(if present) */
            for (Case objCase :[SELECT Id, PC_Program__c, Type FROM Case WHERE Id IN :caseIds]) {
                programIds.add(objCase.Id);
                if(objCase.PC_Program__c!=null){
                    programIds.add(objCase.PC_Program__c);
                }
            }

         /* Get recipients from association records of cases*/
        mapOfCasesRecipients = getRecipientsFromCasesAssociations(eLetter, programIds);

         /* Get recipients from account of cases*/
       mapOfCasesRecipients.putAll(getRecipientsFromAccount(eLetter,programIds,mapOfCasesRecipients));

        /* Prepare a final map of Recipients' Ids as keys and Recipients' records as values*/
        for(Id caseRecordId: mapOfCasesRecipients.keySet()){
            finalMapOfRecipients.putAll(mapOfCasesRecipients.get(caseRecordId));
        }

        /* Return final list of recipients*/
        return finalMapOfRecipients.values();
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }

    /*********************************************************************************
      Method Name    : getRecipientsFromCasesAssociations
      Description    : Get recipients from case records' association records
      Return Type    : Map<Id, Map<Id,PC_eLetter_Recipient>>
      Parameter      : 1.eLetter: eLetter record details
                       2.caseIds : case records' ids list
     *********************************************************************************/
    public static Map<Id, Map<String,PC_eLetter_Recipient>> getRecipientsFromCasesAssociations(PC_eLetter__c eLetter, Set<Id> caseIdsList){
        /* PC-7537: Please note we are using 'recipientsMap' in order to make sure we have unique list of recipients from related case records.
               This is necessary when a service case record and its related program case record both have the same Reimbursement Specialist/Physician/Care Coordinator*/

        Map<Id, Map<String,PC_eLetter_Recipient>> recipientsMap = new Map<Id, Map<String,PC_eLetter_Recipient>>();
        PC_eLetterService.RunWithElevatedPrivileges elevatedPrivileges = new PC_eLetterService.RunWithElevatedPrivileges();
        Set<String> languages = new Set<String> ();
        if(String.isNotBlank(eLetter.PC_Communication_Language__c)){
            languages.addAll(eLetter.PC_Communication_Language__c.split(';'));
        }

        /* Get association record details of case records*/
        List<PC_Association__c> patientParticipants= elevatedPrivileges.getProgramCaseAssociations(caseIdsList,eLetter);
        List<PC_PicklistFieldManager.PicklistEntryWrapper> recipientTypePicklist = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
        recipientTypePicklist   = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.Type);

        List<PC_PicklistFieldManager.PicklistEntryWrapper> recipientRolePicklist = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
        recipientRolePicklist   = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Association__c.PC_Role__c);
        String TypeLabel = PC_Constants.EMPTY_STRING;
        String recipientRecordType;
        PC_eLetter_Recipient recipient;
        PC_eLetter.RecipientWrapper recipientWrapper;

        /* Create eLetter recipient records for all the users and/or accounts associated with the Association records */
        for (PC_Association__c pp : patientParticipants) {
            if(pp.PC_Account__c != null) {
                Account recipientAccount = new Account(
                        Id = pp.PC_Account__c,
                        PC_Communication_Language__c = pp.PC_Account__r.PC_Communication_Language__c,
                        Fax = pp.PC_Account__r.Fax,
                        PC_Email__c = pp.PC_Account__r.PC_Email__c,
                        //PC_Email__c = pp.PC_Account__r.HealthCloudGA__PrimaryContact__r.Email,
                        Name = pp.PC_Account__r.Name);

                recipientWrapper = new PC_eLetter.RecipientWrapper(recipientAccount);
                recipientRecordType = PC_SYSTEM.recordTypeDeveloperNameById(PC_Constants.PC_ACCOUNT , pp.PC_Account__r.RecordTypeId);
                TypeLabel = PC_Constants.EMPTY_STRING;
                for (PC_PicklistFieldManager.PicklistEntryWrapper pew : recipientTypePicklist) {
                    if (pew.value == pp.PC_Account__r.Type) {
                        TypeLabel = pew.label;
                    }
                }
                recipient = new PC_eLetter_Recipient(recipientWrapper, pp.PC_Account__r.Type, TypeLabel, recipientRecordType, languages, pp.PC_Role__c, pp.PC_Account__r.HealthCloudGA__PrimaryContact__r.Email, pp.PC_Account__r.HealthCloudGA__PrimaryContact__r.Fax,pp.PC_Account__r.PC_Preferred__c, String.valueOf(pp.get('RoleLabel')));

            }else if(pp.PC_Associated_User__c != null) {
                User recipientUser = new User(
                        Id                  = pp.PC_Associated_User__c,
                        LanguageLocaleKey   = pp.PC_Associated_User__r.LanguageLocaleKey,
                        Fax                 = pp.PC_Associated_User__r.Fax,
                        Email               = pp.PC_Associated_User__r.Email,
                        FirstName           = pp.PC_Associated_User__r.FirstName,
                        LastName            = pp.PC_Associated_User__r.LastName);

                recipientWrapper = new PC_eLetter.RecipientWrapper(recipientUser);
                recipientRecordType = PC_Constants.EMPTY_STRING;
                TypeLabel = PC_Constants.EMPTY_STRING;
                for (PC_PicklistFieldManager.PicklistEntryWrapper pew : recipientRolePicklist) {
                    if (pew.value == pp.PC_Role__c) {
                        TypeLabel = pew.label;
                    }
                }
                recipient = new PC_eLetter_Recipient(recipientWrapper, pp.PC_Role__c, TypeLabel, recipientRecordType, languages, pp.PC_Role__c, pp.PC_Associated_User__r.Email, pp.PC_Associated_User__r.Fax, PC_Constants.EMPTY_STRING, String.valueOf(pp.get('RoleLabel')));
            }

            if (!recipientsMap.containsKey(pp.PC_Program__c)) {
                recipientsMap.put(pp.PC_Program__c, new Map<String,PC_eLetter_Recipient>());
            }

            recipientsMap.get(pp.PC_Program__c).put(recipient.recipient.Id + recipient.recipientRole,recipient);
        }

        return recipientsMap;
    }

    /*********************************************************************************
      Method Name    : getRecipientsFromAccount
      Description    : Get recipients from case records' account record
      Return Type    : Map<Id, Map<Id,PC_eLetter_Recipient>>
      Parameter      : 1.eLetter: eLetter record details
                       2.caseIds : case records' ids list
                       3.Map of case record id and corresponding eletter recipient records
     *********************************************************************************/
    public static Map<Id, Map<String,PC_eLetter_Recipient>> getRecipientsFromAccount(PC_eLetter__c eLetter, Set<Id> programIds, Map<Id, Map<String,PC_eLetter_Recipient>> recipients){

        /* PC-7537: Please note we are using 'recipients' in order to make sure we have unique list of recipients from related case records.
               This is necessary when a service case record and its related program case record both have the same Reimbursement Specialist/Physician/Care Coordinator*/
        List<String> fields =  new List<String>();
        Set<String> languages = new Set<String> ();
        String recipientRecordType;
        PC_eLetter.RecipientWrapper recipientWrapper;
        String TypeLabel = PC_Constants.EMPTY_STRING;
        List<PC_PicklistFieldManager.PicklistEntryWrapper> recipientTypePicklist = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
        recipientTypePicklist   = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.Type);
        PC_eLetter_Recipient recipient;

        if(String.isNotBlank(eLetter.PC_Communication_Language__c)){
            languages.addAll(eLetter.PC_Communication_Language__c.split(';'));
        }

        /* Check if the 'Allow Send to Patient' is enabled on eLetter OR the Name of selected eletter is blank*/
        if (eLetter.PC_Allow_Send_to_Patient__c || String.isBlank(eLetter.Name)) {
            fields = new List<String>{'Type', 'RecordTypeId','Fax',PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'), PC_Constants.getQualifiedAPIName('PC_Email__c'), 'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            //CRUD/FLS already checked for Case in the above code
            String caseQuery = PC_Constants.EMPTY_STRING;
            if(PC_SYSTEM.isPersonAccountEnabled()){
                caseQuery = 'SELECT Id, AccountId, Account.PC_Communication_Language__c, Account.Type, Account.RecordTypeId,'+
                        'Account.Fax, Account.PC_Email__c, Account.Name, Account.PersonEmail,Account.HealthCloudGA__PrimaryContact__r.Email,Account.HealthCloudGA__PrimaryContact__r.Fax,Account.PC_Preferred__c FROM Case WHERE Id IN :programIds AND AccountId != null';
            }
            else{
                caseQuery = 'SELECT Id, AccountId, Account.PC_Communication_Language__c, Account.Type, Account.RecordTypeId,'+
                        'Account.Fax, Account.PC_Email__c, Account.Name,Account.HealthCloudGA__PrimaryContact__r.Email,Account.HealthCloudGA__PrimaryContact__r.Fax,Account.PC_Preferred__c FROM Case WHERE Id IN :programIds AND AccountId != null';
            }

            List<Case> csList = new List<Case>();

            /* Fetch Account related details of case records*/
            csList = database.query(caseQuery);
            for (Case objCase :csList) {
                Account recipientAccount = new Account(
                        Id = objCase.AccountId,
                        PC_Communication_Language__c = objCase.Account.PC_Communication_Language__c,
                        Fax = objCase.Account.Fax,
                        PC_Email__c = objCase.Account.PC_Email__c,
                        Name = objCase.Account.Name);
                if(PC_SYSTEM.isPersonAccountEnabled() && objCase.Account.recordTypeId == PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PATIENT_RECORD_TYPE)){
                    recipientAccount.PC_Email__c = String.valueOf(objCase.Account.get(PC_Constants.PC_PA_PERSON_EMAIL));
                }

                recipientRecordType = PC_SYSTEM.recordTypeDeveloperNameById(PC_Constants.PC_ACCOUNT , objCase.Account.RecordTypeId);
                recipientWrapper = new PC_eLetter.RecipientWrapper(recipientAccount);
                TypeLabel = PC_Constants.EMPTY_STRING;

                for(PC_PicklistFieldManager.PicklistEntryWrapper pew : recipientTypePicklist){
                    if(pew.value == objCase.Account.Type){
                        TypeLabel = pew.label;
                    }
                }
                if (PC_SYSTEM.isPersonAccountEnabled() && objCase.Account.recordTypeId == PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PATIENT_RECORD_TYPE)) {
                    recipient = new PC_eLetter_Recipient(recipientWrapper, objCase.Account.Type, TypeLabel, recipientRecordType, languages, PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE, String.valueOf(objCase.Account.get(PC_Constants.PC_PA_PERSON_EMAIL)), objCase.Account.Fax, objCase.Account.PC_Preferred__c, PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE);
                }
                else {
                    recipient = new PC_eLetter_Recipient(recipientWrapper, objCase.Account.Type, TypeLabel, recipientRecordType, languages, PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE, objCase.Account.HealthCloudGA__PrimaryContact__r.Email, objCase.Account.HealthCloudGA__PrimaryContact__r.Fax, objCase.Account.PC_Preferred__c, PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE);
                }

                if (!recipients.containsKey(objCase.Id)) {
                    recipients.put(objCase.Id, new Map<String,PC_eLetter_Recipient>());
                }

                recipients.get(objCase.Id).put(recipient.recipient.Id + recipient.recipientRole,recipient);
            }
        }

        return recipients;
    }

    private void populateValidFromAddress(PC_eLetter2Controller.SendLetterRequest eLetterRequest){
        if (String.isBlank(eLetterRequest?.fromAddress?.fromId)) {
            String currentUserType = UserInfo.getUserType();
            String PC_AutomatedTaskEmail = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AUTOMATED_TASK_EMAIL, '');
            if (currentUserType == PC_Constants.PC_AUTOMATED_PROCESS_USERTYPE && String.isNotBlank(PC_AutomatedTaskEmail)) {
                for (OrgWideEmailAddress o : [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :PC_AutomatedTaskEmail LIMIT 1]) {
                    eLetterRequest.fromAddress.fromId = o.Id;
                    eLetterRequest.fromAddress.address = o.Address;
                    eLetterRequest.fromAddress.name = o.DisplayName;
                }
            } else {
                eLetterRequest.fromAddress.fromId = UserInfo.getUserId();
                eLetterRequest.fromAddress.address = UserInfo.getUserEmail();
                eLetterRequest.fromAddress.name = UserInfo.getName();
            }
        }
    }
}