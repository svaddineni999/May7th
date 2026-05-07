/*********************************************************************************
Class Name      : NVS_eLetter_Recipient
Description     : Class working as Wrapper for eLetter related classes/pages
Created By      : Alex Miller
Created Date    : Clozrail Release
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Alex Miller                Cloazaril Release      Initial Version
Jayadev Rath               17-Jun-14              Added new property 'sendToMe' to support sending the eLetter to the current User
Ajinkya Deshmukh           27-Jun-17              with sharing keyword added
Tejas Patel                21-Jul-17              [PC-1964 Translation issue] Add recipientTypeLabel for display
Tejas Patel                13-Mar-19              [PC-4570] new boolean attribute bContactEmail added
Satheesh Kumar             22-Jul-20              [PC-6540] renamed bContactEmail attribute to hasContactEmail
Satheesh Kumar             14-Dec-20              [PC-6960] Added 2 new boolean attribute hasContactFax and isValidEmail
Hitha Avalakki             07-Nov-21              [PC-8029] Added code to store consent records(PC_Program_Service_Permission__c) records configured for services specific to eletter recipient roles
*********************************************************************************/
public with sharing class PC_eLetter_Recipient {
    @AuraEnabled public PC_eLetter.RecipientWrapper recipient {get;set;}
    @AuraEnabled public String recipientType {get;set;}
    @AuraEnabled public String recipientTypeLabel {get;set;}
    @AuraEnabled public String communicationLanguage {get;set;}
    @AuraEnabled public String communicationPreference {get;set;}
    @AuraEnabled public Boolean sendFax {get; set;}
    @AuraEnabled public Boolean sendEmail {get; set;}
    @AuraEnabled public Boolean sendToMe {get;set;}
	@AuraEnabled public Boolean bDisableEmail {get;set;}
	@AuraEnabled public Boolean bDisableFax {get;set;}
	@AuraEnabled public Boolean bDisableSendToMe {get;set;}
    @AuraEnabled public Boolean hasContactEmail {get;set;}
    @AuraEnabled public Boolean hasContactFax {get;set;}
    @AuraEnabled public Boolean isValidEmail {get;set;}
    @AuraEnabled public String recipientFax{get;set;}
    @AuraEnabled public String recipientEmail{get;set;}
    @AuraEnabled public String recipientName{get;set;}
    @AuraEnabled public String recipientRecordType{get;set;}
    @AuraEnabled public String recipientRole{get;set;}
    @AuraEnabled public String recipientRoleLabel{get;set;}
    @AuraEnabled public Map<Id, List<ProgramServicePermissionWrapper>> serviceDetails;
    @AuraEnabled public List<ProgramServicePermissionWrapper> programServicePermissionRecordsList;

    public PC_eLetter_Recipient(PC_eLetter.RecipientWrapper recipient, String recipientType, String recipientTypeLabel, String recipientRecordType, Set<String> availableLanguages , STRING role, STRING contactEmail, String contactFax){
        this.recipient = recipient;
        this.recipientRecordType = recipientRecordType;
        this.recipientFax = recipient.fax;
        this.recipientEmail = recipient.email;
        this.recipientName = recipient.name;
        // Type of Participant (Physician or Pharmacy or...etc)
        this.recipientType = recipientType;
        this.recipientTypeLabel = recipientTypeLabel;
        this.recipientRole  = role;
        this.isValidEmail = PC_Constants.TRUE_BOOLEAN;

        // Communication Language is defaulted to recipent's communiction language or the language set at eLetter record level.
        this.communicationLanguage = availableLanguages.contains(recipient.communicationLanguage) ? recipient.communicationLanguage : PC_Constants.EMPTY_STRING;

        // Fax will be selected by default (if a fax number exist for the participant)
        this.sendFax = !String.isBlank(recipient.fax);
        // Email sending is uncheked by default (Enabled for Gilenya)
        this.sendEmail = false; //!String.isBlank(recipient.NVS_Prime_Contact_Email__c);

        // sendToMe is false by default, Will be enabled if the eLetter is set as editable/Send to User is enabled for the eLetter
        this.sendToMe = false;

        if(recipient.type == PC_eLetter.RecipientType.ACCOUNT.name()){
            this.recipientEmail = String.isNotBlank(contactEmail) ? contactEmail :PC_Constants.EMPTY_STRING;
            this.recipientFax = String.isNotBlank(contactFax) ? contactFax :PC_Constants.EMPTY_STRING;
            this.hasContactEmail = String.isNotBlank(contactEmail);
            this.hasContactFax = String.isNotBlank(contactFax);
        } else{
            this.recipientEmail = recipient.email;
            this.recipientFax = recipient.fax;
            this.hasContactEmail = String.isNotBlank(recipient.email);
            this.hasContactFax = String.isNotBlank(recipient.fax);
        }
    }

    public PC_eLetter_Recipient(PC_eLetter.RecipientWrapper recipient, String recipientType, String recipientTypeLabel, String recipientRecordType, Set<String> availableLanguages , STRING role, STRING contactEmail, String contactFax, String communicationPreference, String roleLabel){
        this(recipient, recipientType, recipientTypeLabel, recipientRecordType, availableLanguages, role, contactEmail, contactFax);
        this.communicationPreference = communicationPreference;
        this.recipientRoleLabel = roleLabel;
    }

    public inherited sharing class ProgramServicePermissionWrapper{
        @AuraEnabled public String serviceName{get;set;}
        @AuraEnabled public Id programServicePermissionId{get;set;}
        @AuraEnabled public String informationIconLabel{get;set;}
        @AuraEnabled public Boolean isConsentAvailable{get;set;}
        @AuraEnabled public Boolean consentDoesNotExist{get;set;}
        @AuraEnabled public Date startDate{get;set;}
        @AuraEnabled public Date endDate{get;set;}

      public ProgramServicePermissionWrapper(){
         this.serviceName =' ';
         this.informationIconLabel = '';
         this.isConsentAvailable = false;
      }
    }
}