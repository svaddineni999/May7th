/*********************************************************************************
Class Name      : PC_ELetter2Helper
Description     : eLetter2 helper class
Created By      : Satheesh Kumar
Created Date    : 08-Dec-20
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Satheesh Kumar            08-Dec-20               Initial Version
Satheesh Kumar            14-Dec-20               [PC-6960] Checked isValidEmail method for all pre-configured emails
Hitha Avalakki            23-Feb-21               [PC-7442] Replaced the use of RecordTypeId with 'Type' field of Case object to decide if its a program case record
Hitha Avalakki            19-Mar-21               [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Satheesh Kumar            22-Mar-21               [PC-7127] Handle invalid PreConfiguredEmailRecipients string
Hitha Avalakki            07-Apr-21               [PC-7537] Removed the condition for CASE_PROGRAM_TYPE to fetch preconfigured eletter receipients for all case types records
*********************************************************************************/

public with sharing class PC_ELetter2Helper {
    /**
    * This method gets the PreConfiguredRecipients based on the eletterId
    * @param engagementProgramId    Engagement Program Id
    * @param eletterId              Eletter Record Id
    *
    * @return List<PreConfiguredRecipient>
    */
    public static List<PreConfiguredRecipient> getPreConfiguredRecipients(String engagementProgramId, String eletterId) {
        List<PreConfiguredRecipient> preConfiguredRecipients = new List<PreConfiguredRecipient>();
        String preConfiguredRecipientsString;
        try {
            // FLS for Engagement Program ELetter
            List<String> engagementProgEletterFields = new List<String>();
            engagementProgEletterFields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_PreConfiguredEmailRecipients__c'), PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterFields);

            if (String.isNotBlank(eletterId) && String.isNotBlank(engagementProgramId)) {
                preConfiguredRecipientsString = [SELECT Id, PC_PreConfiguredEmailRecipients__c, PC_Engagement_Program__c, PC_eLetter__c FROM PC_Engagement_Program_Eletter__c WHERE PC_eLetter__c = :eletterId and PC_Engagement_Program__c = :engagementProgramId ORDER BY PC_eLetter__r.Name ASC, LastModifiedDate DESC LIMIT 1] ?. PC_PreConfiguredEmailRecipients__c;
                if (String.isNotBlank(preConfiguredRecipientsString)) {
                    Boolean isCommaSeparatedEmail = PC_Utility.isCommaSeparatedEmail(preConfiguredRecipientsString);
                    if (isCommaSeparatedEmail) {
                        List<String> mailIds = (preConfiguredRecipientsString).trim().split('\\s*,\\s*');
                        for (String mailId : mailIds) {
                            preConfiguredRecipients.add(new preConfiguredRecipient(mailId));
                        }
                    } else {
                        try {
                            preConfiguredRecipients = (List<PreConfiguredRecipient>) System.JSON.deserialize(preConfiguredRecipientsString, List<PreConfiguredRecipient>.class);
                        } catch (Exception ex) {
                            throw new PC_eLetter2Controller.Eletter2Exception(System.Label.PC_InvalidPreConfiguredEmailRecipients_Error);
                        }
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return preConfiguredRecipients;
    }

    /**
    * This method checks the input string and returns the email id in comma separated string
    * @param recordId   Record Id
    * @param eletterId  Eletter Record Id
    *
    * @return List<PC_eLetter_Recipient>
    */
    public static List<PC_eLetter_Recipient> getConfiguredRecipientsAsEletterRecipients(String recordId, String eletterId) {
        List<PC_eLetter_Recipient> eLetterRecipients = new List<PC_eLetter_Recipient>();
        String caseId = PC_eLetter2Controller.getCaseId(recordId);

        //FLS check for case
        List<String> caseFields = new List<String>{'Id', 'RecordTypeId', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

        /*PC-7537: Removed the condition for CASE_PROGRAM_TYPE to fetch eletter receipients for all case types records*/
        String engagementProgramId = [SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id =:caseId LIMIT 1] ?.PC_Engagement_Program__c ;
        List<PreConfiguredRecipient> preConfiguredRecipients = getPreConfiguredRecipients(engagementProgramId, eletterId);
        for (PreConfiguredRecipient configRecipient : preConfiguredRecipients) {
            String recipientEmail = (PC_Utility.isValidEmail(configRecipient.email)) ? configRecipient.email : PC_Constants.EMPTY_STRING;
            PC_eLetter.RecipientWrapper recipientWrapper = new PC_eLetter.RecipientWrapper();
            recipientWrapper.Id = null;
            recipientWrapper.communicationLanguage = '';
            recipientWrapper.type = PC_eLetter.RecipientType.PRE_CONFIGURED_EMAIL.name();
            recipientWrapper.fax = configRecipient.fax;
            recipientWrapper.email = configRecipient.email;
            recipientWrapper.name = String.isNotBlank(configRecipient.name) ? configRecipient.name : '';

            PC_eLetter_Recipient newRecipient = new PC_eLetter_Recipient(recipientWrapper, null, configRecipient.role, null, new Set<String>(), configRecipient.role, configRecipient.email, configRecipient.fax);
            newRecipient.recipientRoleLabel = configRecipient.role;
            newRecipient.bDisableEmail = String.isBlank(recipientEmail);
            newRecipient.bDisableFax = String.isBlank(configRecipient.fax);
            newRecipient.hasContactEmail = String.isNotBlank(recipientEmail);
            newRecipient.recipientEmail = configRecipient.email;
            newRecipient.isValidEmail = PC_Utility.isValidEmail(configRecipient.email);
            eLetterRecipients.add(newRecipient);
        }
        return eLetterRecipients;
    }

    public class PreConfiguredRecipient {
        public String name;
        public String email;
        public String fax;
        public String role;

        public PreConfiguredRecipient() {
            name = PC_Constants.EMPTY_STRING;
            email = PC_Constants.EMPTY_STRING;
            fax = PC_Constants.EMPTY_STRING;
            role = PC_Constants.EMPTY_STRING;
        }

        public PreConfiguredRecipient(String emailId) {
            name = PC_Constants.EMPTY_STRING;
            email = emailId;
            fax = PC_Constants.EMPTY_STRING;
            role = PC_Constants.EMPTY_STRING;
        }
    }
}