/*********************************************************************************
Class Name      : PC_eLetterAuraController
Description     : Methods for eLetter lightning component
Created By      : Roxana Ivan
Created Date    : 22-June-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   	Description
-----------------------------------------------------------------------------------            
Roxana Ivan               	22-June-16              Initial Version
Shabda Bhujad				Dec 08, 2016			Added FLS check to getLetters,getRecepients,sendOutboundDocuments methods
Mayuresh Patil				Jul 26, 2017			Updated CRUD/FLS Checks
Tejas Patel					Nov 22, 2017			[PC-2515]Initializing the String varibles faxRecipientString and emailRecipientString on seperate lines
Mike Klumpenaar				2017-12-13				[PC-2601] Add support for Interaction object
Tejas Patel                 2019-03-08              [PC-4570] updated the sendOutboundDocuments to send eLetters and message in same loop.
Hitha Avalakki				Mar 12, 2019			[PC-4487] Added code to fetch eLetters on the basis of Engagement Program on the
													corresponding program case record.
Hitha Avalakki            	Feb 23, 2021            [PC-7442] Replaced the use of RecordTypeId with 'Type' field of Case object to decide if its a program case record
Hitha Avalakki         		Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Hitha Avalakki              Apr 07,2021             [PC-7537] Removed the condition of CASE_PROGRAM_TYPE in query in order to fetch eletters configured as per engagement program for any type of Case record
*********************************************************************************/
public with sharing class PC_eLetterAuraController {
	private static final String EMPTY_STRING = '';

    /*********************************************************************************
    Method Name    : getLetters
    Description    : Retrieves available eLetters by object type
    Return Type    : List<PC_LightningMap>
    *********************************************************************************/
	@AuraEnabled
	public static List<PC_LightningMap> getLetters(Id recordId) {
		List<PC_LightningMap> lstAvailableeLetters = new List<PC_LightningMap>();
		lstAvailableeLetters.add(new PC_LightningMap(Label.PC_Select_an_eLetter, PC_Constants.PICKLIST_NONE_VAL));
		Case caseObject=new Case();
		List<PC_eLetter__c> eLetters = null;
		/*
		* CRUD/FLS Check for the object of the recordId passed to the method
		*/
        String objType = String.valueOf(recordId.getSobjectType());
		List<String> fields = new List<String>{'Id'};
		PC_Database.assertAccess(objType, PC_Database.Operation.Reading, fields);
		String recordTypeName = EMPTY_STRING;
		SObject selectedObj=null;
		try {
			if (objType == PC_Constants.PC_INTERACTION) {
				objType = Label.PC_Interaction;
				PC_Interaction__c interactionObject=new PC_Interaction__c();

				/**** PC-4487: Fetch eLetters on the basis of engagement program present on program case record : START****/
				selectedObj = Database.query('SELECT Id, PC_Patient_Program__c FROM ' + String.valueOf(recordId.getSobjectType()) + ' WHERE Id = :recordId');
				interactionObject=(PC_Interaction__c)selectedObj;
				eletters=getElettersAsPerEngagementProg(interactionObject.PC_Patient_Program__c,objType,recordTypeName);

				/**** PC-4487: Fetch eLetters on the basis of engagement program present on program case record : END****/

			} else {
				selectedObj = Database.query('SELECT Id, RecordType.Name FROM ' + String.valueOf(recordId.getSobjectType()) + ' WHERE Id = :recordId');

				/*[PC-7537]: Removed the condition of CASE_PROGRAM_TYPE in order to fetch eletters configured as per engagement program for any type of Case record*/
				if (objType == PC_Constants.PC_CASE) {
					Case caseObj = (Case) selectedObj;
					recordTypeName = caseObj.RecordType.Name;

					if(recordTypeName!=null){

						/**** PC-4487: Fetch eLetters on the basis of engagement program present on program case record : START****/
						eletters=getElettersAsPerEngagementProg(recordId,objType,recordTypeName);
						/**** PC-4487: Fetch eLetters on the basis of engagement program present on program case record : END****/
					}
				} else if (objType == PC_Constants.PC_PROGRAM_COVERAGE) {
					PC_Program_Coverage__c coverage = (PC_Program_Coverage__c) selectedObj;
					recordTypeName = coverage.RecordType.Name;
					objType = Label.PC_ProgramCoverage;
					PC_Program_Coverage__c progCoverageObject =new PC_Program_Coverage__c();

					/**** PC-4487: Fetch eLetters on the basis of engagement program present on program case record : START****/
					selectedObj = Database.query('SELECT Id, PC_Program__c FROM ' + String.valueOf(recordId.getSobjectType()) + ' WHERE Id = :recordId');
					progCoverageObject=(PC_Program_Coverage__c)selectedObj;
					eletters=getElettersAsPerEngagementProg(progCoverageObject.PC_Program__c,objType,recordTypeName);

					/**** PC-4487: Fetch eLetters on the basis of engagement program present on program case record : END****/

				}
			}

			for (PC_eLetter__c el : eLetters) {
				lstAvailableeLetters.add(new PC_LightningMap(el.Name, el.Id));
			}

		} catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);           
        }

		return lstAvailableeLetters;

	}
    /*********************************************************************************
    Method Name    : getRecepients
    Description    : Retrieves eLetters recipients based on selected letter
    Return Type    : List<PC_eLetter_Recipient>
    *********************************************************************************/
	@AuraEnabled
	public static List<PC_eLetter_Recipient> getRecipients(String letterId, Id recordId) {
     	String objType = String.valueOf(recordId.getSobjectType());
		List<PC_eLetter_Recipient> recipients = new List<PC_eLetter_Recipient> ();
        Id caseId  = recordId;
		
		try {
			if (String.valueof(letterId) != Label.PC_None) {
				PC_eLetter__c eLetter = PC_eLetterService.getELetter(letterId);
				List<String> fields;

	            if (objType == PC_Constants.PC_PROGRAM_COVERAGE) {
	                fields = new List<String> {PC_Constants.getQualifiedAPIName('PC_Program__c')};
		            PC_Database.assertAccess(PC_Constants.PC_PROGRAM_COVERAGE, PC_Database.Operation.Reading, fields);
		            PC_Program_Coverage__c coverage = [SELECT Id, PC_Program__c FROM PC_Program_Coverage__c WHERE Id = :recordId];
	                caseId = coverage.PC_Program__c;
	            } else if (objType == PC_Constants.PC_INTERACTION) {
					fields = new List<String> {PC_Constants.getQualifiedAPIName('PC_Patient_Program__c')};
					PC_Database.assertAccess(PC_Constants.PC_INTERACTION, PC_Database.Operation.Reading, fields);
					PC_Interaction__c interaction = [SELECT Id, PC_Patient_Program__c FROM PC_Interaction__c WHERE Id = :recordId];
					caseId = interaction.PC_Patient_Program__c;
				}
            	
				fields = new List<String> {'CaseNumber'};
		        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
		        fields = new List<String> {'Name'};
		        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
				PC_Database.assertAccess(PC_Constants.RECORD_TYPE_PARAM,PC_Database.Operation.Reading, fields);

		        Case objCase = [SELECT Id, CaseNumber, RecordType.Name, Account.Name FROM Case WHERE Id = :caseId];

				// Get available languages from the eLetter Template and dynamically display the participant language:
				List<SelectOption> lstCommunicationLanguage = new List<SelectOption> ();
				for (String lang : eLetter.PC_Communication_Language__c.split(';')) {
					lstCommunicationLanguage.add(new SelectOption(lang, lang));
				}

				recipients = PC_eLetterService.getParticipants(objCase.Id, eLetter);
				if (recipients == null) {
					// If no participants found, don't proceed.
					return null;
				}
	            
				// After getting all the Recipients, for special eLetter templates (with Allow_Editing=true or Send_To_User=True) set the sendToMe flag to True and uncheck other flags
				if (eLetter.PC_Send_to_User__c) {
					for (PC_eLetter_Recipient rec : recipients) {
						rec.sendToMe = true;
						rec.sendFax = false;
						rec.sendEmail = false;
						// Enable SendToMe column
						rec.bDisableSendToMe = false;
						// Disble the SendFax & SendEmail checkboxes on eLetter Page:
						rec.bDisableEmail = true;
						rec.bDisableFax = true;
					}
				}
				else {
					// Disble the SendToMe checkboxes on eLetter Page for the eLetters where 'Send to User' is not selected.
					for (PC_eLetter_Recipient rec : recipients)
					{
						rec.sendToMe = false;
						// Disable SendToMe column
						rec.bDisableSendToMe = true;
						// Enable SendFax and SendEmail Column
						rec.bDisableEmail = false;
						rec.bDisableFax = false;
						if(rec.hasContactEmail == false){
							rec.bDisableEmail = true;
							rec.bDisableFax = true;
						}
					}
				}			
	        }
		} catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
		}
		System.debug('@@'+recipients);
		return recipients;
	}
    /**
     * Send eLetter to select recipients.
     *
     * @param recipientsString  JSON string containing PC_eLetter_Recipient list
     * @param letterId			Record Id of the eLetter object
     * @param objectId			Record Id of object the letter is being sent from - looks like it is always Program Case
     */
	@AuraEnabled
	public static string sendOutboundDocuments(String recipientsString, String letterId, Id objectId) {
		String returnMessage = EMPTY_STRING;
		try {
			List<PC_eLetter_Recipient> recipients = (List<PC_eLetter_Recipient>) System.JSON.deserialize(recipientsString, List<PC_eLetter_Recipient>.class);
			// If no recipients are available then inform the user:
			if (recipients == null || recipients.size() == 0 || String.valueOf(letterId) == Label.PC_None) {
				return System.Label.PC_No_Recipients_Available;
			}
			
			// Prepare a list of accounts with preferences selected on page:
			List<PC_eLetter.RecipientWrapper> faxRecipients = new List<PC_eLetter.RecipientWrapper>();
			List<PC_eLetter.RecipientWrapper> emailRecipients = new List<PC_eLetter.RecipientWrapper>();
			List<PC_eLetter.RecipientWrapper> sendToUserRecipients = new List<PC_eLetter.RecipientWrapper>();

			//Store the recipient names for displaying info message to the user (boolean sendEmail/sendFax is not considered now)
			String faxRecipientString = EMPTY_STRING;
            String emailRecipientString = EMPTY_STRING;
			// Collect the list of selected recipients with their language selection at Page level.
			PC_eLetter.RecipientWrapper overriddenRecipient = new PC_eLetter.RecipientWrapper();
			for (PC_eLetter_Recipient recipient : recipients) {
				overriddenRecipient = recipient.recipient;
				overriddenRecipient.communicationLanguage = recipient.communicationLanguage;
				if (recipient.sendFax && String.isNotEmpty(recipient.recipientFax)) {
					// This list will be explicitly passed to PC_eLetterService to override the preferred method of communication selection at participant level.
					faxRecipients.add(overriddenRecipient); // Later another list is prepared for EMAIL
					faxRecipientString += overriddenRecipient.name + '; ';
				}
				if (recipient.sendEmail && String.isNotEmpty(recipient.recipientEmail)) {
					// This list will be explicitly passed to PC_eLetterService.SendEmail() Method to override the preferred method of communication selection at participant level.
					emailRecipients.add(overriddenRecipient);
					emailRecipientString += overriddenRecipient.name + '; ';
				}
				if (recipient.sendToMe) {
					// This list will be explicitly passed to PC_eLetterService.SendLetterToUser() to override the preferred method of communication/Language selection at participant level.
					User ownerRecipient;
					String objectType	=	objectId.getSobjectType().getDescribe().getName();
					String query = 'Select Id, OwnerId From '+ objectType;
					query += ' Where Id = \'' + objectId + '\' Limit 1';
					try{
						List<Sobject> s	=	PC_Database.queryWithAccess(query , false);
						Id ownerId = (Id)s[0].get('OwnerId');
						if(s[0]!=null){
							ownerRecipient = [Select Id, toLabel(LanguageLocaleKey), Fax, Email, LastName, FirstName From User
							Where Id = :ownerId];
						}

					}
					catch(exception ex){
						PC_Utility.logAndThrowException(ex);
					}
					if(ownerRecipient !=null){
						sendToUserRecipients.add(new PC_eLetter.RecipientWrapper(ownerRecipient));
					}
				}
			}

			// If the recipient list is empty then throw error message else info message
			if (faxRecipients.isEmpty() && emailRecipients.isEmpty() && sendToUserRecipients.isEmpty()) {
				returnMessage = System.Label.PC_No_Record_Selected;
			} else {
				PC_eLetter__c eLetter = PC_eLetterService.getELetter(letterId);
				if (!emailRecipients.isEmpty()) {
					PC_eLetterService.sendLetter(objectId, eLetter, PC_Constants.EMAIL, emailRecipients, false);
					emailRecipientString = emailRecipientString.left(emailRecipientString.length() - 2); // Remove the last '; ' from the list of email recipients:
					returnMessage = System.Label.PC_Generating_eLetter_for + emailRecipientString;
				}
				if (!faxRecipients.isEmpty()) {
					PC_eLetterService.sendLetter(objectId, eLetter, PC_Constants.FAX, faxRecipients, false);
					faxRecipientString = faxRecipientString.left(faxRecipientString.length() - 2); // Remove the last '; ' from the list of fax recipients:
					returnMessage = System.Label.PC_Generating_Fax_for + faxRecipientString;
				}
				if (!sendToUserRecipients.isEmpty()) {
					PC_eLetterService.sendLetter(objectId, eLetter, PC_Constants.EMAIL, sendToUserRecipients, true);
					returnMessage = System.Label.PC_eLetters_Sent_to_User;
				}
			}

		} catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
		}

		return returnMessage;
	}

	/*********************************************************************************
    Method Name    : getElettersAsPerEngagementProg
    Description    : Retrieves eLetters on the basis of engagement program of Program case
    Return Type    : List<PC_eLetter__c>
    User Story	   : PC-4487
    Author		   : Hitha Avalakki
    *********************************************************************************/
	public static List<PC_eLetter__c> getElettersAsPerEngagementProg(Id caseRecordId, String objType, String recordTypeName) {
		List<PC_eLetter__c> eLetters = new List<PC_eLetter__c>();

		Case caseObject=new Case();

		try {

			/* [PC-7537]: Removed the condition of caseType in query in order to allow to fetch eletters configured as per engagement program for any type of Case record */
			List<String> fields=new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
			String caseQuery='SELECT Id, PC_Engagement_Program__c FROM Case WHERE Id =\''+String.valueOf(caseRecordId)+'\'';
			List<SObject> caseObjList = PC_Database.queryWithAccess(caseQuery,fields);
			if(caseObjList!=null && !caseObjList.isEmpty()){
				caseObject = (Case) caseObjList.get(0);
			}

			if (caseObject != null && caseObject.PC_Engagement_Program__c != null) {

				List<String> eLetterFields = new List<String>();
				eLetterFields = new List<String>{
						'Id', 'Name',
						PC_Constants.getQualifiedAPIName('PC_Hide_From_eLetter_Page__c'),
						PC_Constants.getQualifiedAPIName('PC_Source_Object__c'),
						PC_Constants.getQualifiedAPIName('PC_Object_Record_Types__c')
				};
				PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);

				List<Id> eLetterIdsList = new List<Id>();
				List<String> engagementProgEletterrFields = new List<String>();
				engagementProgEletterrFields = new List<String>{
						'Id', 'Name',
						PC_Constants.getQualifiedAPIName('PC_eLetter__c'),
						PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
				};
				PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Eletter__c'), PC_Database.Operation.Reading, engagementProgEletterrFields);

				List<PC_Engagement_Program_Eletter__c> engagementProgramEletters = [
						SELECT Id, PC_eLetter__c
						FROM PC_Engagement_Program_Eletter__c
						WHERE PC_Engagement_Program__c = :caseObject.PC_Engagement_Program__c
				];

				for (PC_Engagement_Program_Eletter__c engagementProgramEletter : engagementProgramEletters) {
					eLetterIdsList.add(engagementProgramEletter.PC_eLetter__c);
				}

				if (!String.isBlank(recordTypeName)) {

					eLetters = [SELECT Id, Name
								FROM PC_eLetter__c
								WHERE PC_Hide_From_eLetter_Page__c != true AND
								Id IN:eLetterIdsList AND
								PC_Source_Object__c = :objType AND
								PC_Object_Record_Types__c INCLUDES (:recordTypeName)
					];
				} else {
					eLetters = [SELECT Id, Name
								FROM PC_eLetter__c
								WHERE PC_Hide_From_eLetter_Page__c != true AND
								PC_Source_Object__c = :objType AND
								Id IN:eLetterIdsList
					];
				}
			}
		}
		catch (Exception ex){
			PC_Utility.createExceptionLog(ex);
		}
		return eLetters;
	}
}