/*********************************************************************************************************
Handler Name    : ACLS_TestDataFactory
Description     : This class is used for storing all common methods which will be used by the Test Methods 
Created By      : Deloitte
Created Date    : Jan 10, 2023
****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
Jan 10, 2023	Vartika Goyal				US-120				Added createUser
																assignUserPermissionSet	
																ServiceTestDataMethod
																Program_Service_PermissioncTestDataMethod
*****************************************************************************************************************/
public with sharing class ACLS_TestDataFactory {
    /*************************************************************************************************
     *  @method name         :  createProgramCase
     *  @method description  :  This method is used to create Test Program Case
     *  @method param        :  Integer Count, Id AccountId
     *  @method return type  :  List<Case>
     **************************************************************************************************/
    public static List<Case> createProgramCase(Integer count, Id accountId){
        List<Case> lstCase = new List<Case>();
        for (Integer i = 0; i < count; i++){
            Case objCase = new Case();
            objCase.AccountId = accountId;
            objCase.Status = 'New';
            objCase.RecordTypeId = ACLS_Utility.getRecordtypeIdByDeveloperName('Case', 'PC_Program');
            lstCase.add(objCase);
        }
        return lstCase;
    }

    /*************************************************************************************************
     *  @method name         :  createEngagmentProgram
     *  @method description  :  This method is used to create Test EngagementProgram
     *  @method param        :  Integer Count
     *  @method return type  :  List<PC_Engagement_Program__c>
     **************************************************************************************************/
    public static List<PC_Engagement_Program__c> createEngagmentProgram(Integer count){
        List<PC_Engagement_Program__c> PC_Engagement_ProgramcList = new List<PC_Engagement_Program__c>();
        for (Integer i = 0; i < count; i++){
            PC_Engagement_Program__c PC_Engagement_ProgramcVar = new PC_Engagement_Program__c();
            PC_Engagement_ProgramcVar.PC_Active__c = true;
            PC_Engagement_ProgramcVar.PC_Description__c = 'ABCD';
            PC_Engagement_ProgramcVar.PC_Program_Start_Date__c = system.today();
            PC_Engagement_ProgramcVar.Name = 'ABCD';
            PC_Engagement_ProgramcList.add(PC_Engagement_ProgramcVar);
        }
        return PC_Engagement_ProgramcList;
    }

    /*************************************************************************************************
     *  @method name         :  createAccount
     *  @method description  :  This method is used to create Test Account
     *  @method param        :  Integer Count
     *  @method return type  :  List<Account>
     **************************************************************************************************/
    public static List<Account> createAccount(Integer count){
        List<Account> lstAccount = new List<Account>();
        for (Integer i = 0; i < count; i++){
            Account objAccount = new Account();
            objAccount.Name = 'Test Account ' + i;
            lstAccount.add(objAccount);
        }
        return lstAccount;
    }

	 /*********************************************************************************
	Method Name    : createAccounts
	Author         : Ronak
	Description    : This method is used for creating accounts
	Return Type    : List<Account> 
	Parameter      : String account name, No of records, Record Type Name
	*********************************************************************************/
	  public static List<Account> createAccounts(String pRootName, Integer pNoRecs, String recordType){
		Id accountRecordTypeId = PC_System.recordTypeId('Account', recordType);
		List<Account> newAccounts = new List<Account>(); 
		for(integer i = 0; i < pNoRecs; i ++){
			Account Account = new Account();
			account.Name = 'Account Name '+i;
			account.PC_First_Name__c = pRootName +' ' + 'First Name '+i;
			account.PC_Last_Name__c = pRootName +' ' + 'Last Name '+i;
			account.recordTypeId = accountRecordTypeId;
			newAccounts.add(account);
		}
		return newAccounts;
	}
	 /*************************************************************************************************
     *  @method name         :  createMessage
     *  @method description  :  This method is used to create Test Message
     *  @method param        :  Integer Count
     *  @method return type  :  List<PC_Message__c>
     **************************************************************************************************/
    public static List<PC_Message__c> createMessage(Integer count){
        List<PC_Message__c> lstMessage = new List<PC_Message__c>();
        for (Integer i = 0; i < count; i++){
            PC_Message__c objMessage = new PC_Message__c();
            objMessage.Name = 'Test Message ' + i;
			objMessage.PC_Type__c = 'Outbound';
			objMessage.PC_Message_Status__c = 'Queued';
			
            lstMessage.add(objMessage);
        }
        return lstMessage;
    }

    public static User createUser(String sProfileName, String sUserName, String sAlias) {
        // Get the profile details
		Profile p = new Profile();
        if(Schema.sObjectType.Profile.isAccessible()){
			p = [SELECT Id FROM Profile WHERE Name = :sProfileName];
		}
		
        User objUser = new User(Alias = sAlias, email = sUserName,emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US', 
                                localesidkey = 'en_US',country = 'United States', profileid = p.Id,
                                timezonesidkey = 'America/Los_Angeles', username = sUserName);

        return objUser;
    }

    /*************************************************************************************************
    @MethodName        : assignUserPermissionSet
    @Author             : Deloitte
    @Description        : This method is used for assigning permissions set to a User
    @ReturnType         : void
    @Param              : String
    **************************************************************************************************/
    public static void assignUserPermissionSet(String userId, String PermissionSetToAssign) {
		List<PermissionSet> permissionSets = new List<PermissionSet>();
		if(Schema.sObjectType.PermissionSet.isAccessible() && Schema.sObjectType.PermissionSet.isCreateable()){
			permissionSets = [SELECT ID From PermissionSet WHERE Name =: PermissionSetToAssign];
			insert new PermissionSetAssignment(AssigneeId = userId,  PermissionSetId = permissionSets[0].Id);
		}
    }

    /*************************************************************************************************
     *  @method name         :  crateTestDocument
     *  @method description  :  This method is used to create test Document
     *  @method param        :  Integer Count
     *  @method return type  :  List<PC_Document__c>
     **************************************************************************************************/
     public static List<PC_Document__c> createTestDocument(Integer count)  
     {
         List<PC_Document__c> lstDocuments = new List<PC_Document__c>();
         for(Integer i = 0; i< count;i++)
         {
             PC_Document__c objDocument = new PC_Document__c();
            objDocument.RecordTypeId = ACLS_Utility.getRecordtypeIdByDeveloperName('PC_Document__c', 'PC_Email_Inbound');
             objDocument.PC_Document_Status__c = 'Spam';
             objDocument.PC_Document_Category__c = 'Enrollment Form';
             lstDocuments.add(objDocument);
         }
         return lstDocuments;
     }
    
     /*************************************************************************************************
     *  @method name         :  createELetterRecord
     *  @method description  :  This method is used to create eLetter Record
     *  @method param        :  Integer count
     *  @method return type  :  List<PC_eLetter__c>
     **************************************************************************************************/
   public static List<PC_eLetter__c> createTesteLetter(Integer count)  
     {
         List<PC_eLetter__c> lsteLetter = new List<PC_eLetter__c>();
         for(Integer i = 0; i< count;i++)
         {
             PC_eLetter__c eLetterRecord = new PC_eLetter__c();
            eLetterRecord.Name = 'Fax : Welcome To Program';
             eLetterRecord.PC_AllowExternalRecipients__c = true;
             eLetterRecord.PC_Allow_Send_to_Patient__c = true;
             eLetterRecord.PC_Category__c = 'Fax';
             eLetterRecord.PC_Communication_Language__c = 'English';
             eLetterRecord.PC_Description__c = 'Sample eletter sent to patient during their enrollment	';
             eLetterRecord.PC_Hide_From_eLetter_Page__c = false;
             eLetterRecord.PC_Source_Object__c = 'Case';
             eLetterRecord.PC_Target_Recipients__c = 'HCO';
             eLetterRecord.PC_Object_Record_Types__c = 'Program';
             eLetterRecord.ACLS_Subject__c = 'Welcome to the Program';
             eLetterRecord.ACLS_Number_of_Pages__c='4';
             lsteLetter.add(eLetterRecord);
         }
         return lsteLetter;
     }
         

    /*************************************************************************************************
     *  @method name         :  PC_AdverseEvent2cTestDataMethod
     *  @method description  :  This method is used to create Adverse Event Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_AdverseEvent2__c> createPC_AdverseEvent2TestRecord(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_AdverseEvent2__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_AdverseEvent2__c> PC_AdverseEvent2cList = new List<PC_AdverseEvent2__c>();
		for(Integer i=0;i<count;i++) {
		PC_AdverseEvent2__c PC_AdverseEvent2cVar = new PC_AdverseEvent2__c();
		PC_AdverseEvent2cVar.PC_Death_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Reporter__c = 'ABCD'+(Integer)Math.floor(Math.Random()*100);
		PC_AdverseEvent2cVar.PC_Event_LLT__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Other_Relevent_History__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_ReporterFax__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_BLA__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Date_of_Birth__c = system.today();
		PC_AdverseEvent2cVar.PC_PreferredResponseWindow__c = '8:00AM - Noon';
		PC_AdverseEvent2cVar.PC_Hospitalization_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Manufacturer_Address__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_InquiryDescription__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Report_Type_Other_Text__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Product_Name__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Laboratory_Data__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_AE_Received_by_Manufacturer_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Event_Reappeared_after_Reintroduction__c = 'Yes';
		PC_AdverseEvent2cVar.PC_ActionTaken__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Notes__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Medication__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Outcome__c = 'Recovered';
		PC_AdverseEvent2cVar.PC_Adverse_Event_Reporter__c = 'Nurse';
		PC_AdverseEvent2cVar.PC_Prescription__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Ini_Reporter_Also_Sent_Report_to_FDA__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Report_Type__c = '5-day';
		PC_AdverseEvent2cVar.PC_Manufacturer_Comp_Outsourcing_Fac__c = true;
		PC_AdverseEvent2cVar.PC_HealthCareProfessional__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Weight__c = null;
		PC_AdverseEvent2cVar.PC_PatientFirstname__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Description__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_ANDA__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_CauseOfDeath__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_ReporterAddress__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Dose__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reference_No__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_Country__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_First_Name__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Age_Unit__c = 'Year(s)';
		PC_AdverseEvent2cVar.PC_Report_Source_Other_Text__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Frequency__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Drug_NDC__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Meddra_ID__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_Email__c = 'test@test.com';
		PC_AdverseEvent2cVar.PC_Manufacturer_Name__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Event_Outcome__c = 'Death';
		PC_AdverseEvent2cVar.PC_Event_PT__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Pre_1938_Flag__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Event_HLT__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Gender__c = 'Female';
		PC_AdverseEvent2cVar.ACLS_Engagement_Program_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Combination_Product_Report__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Route_of_Administration__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_Phone__c = '1234567890';
		PC_AdverseEvent2cVar.PC_Causality__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Follow_Up_Number__c = '1234567890';
		PC_AdverseEvent2cVar.PC_PMA_510k__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_VersionNumber__c = null;
		PC_AdverseEvent2cVar.PC_Product_Compounded__c = 'Yes';
		PC_AdverseEvent2cVar.PC_IND__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Event_SOC__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Age__c = null;
		PC_AdverseEvent2cVar.PC_NDA__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_Last_Name__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_State__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Manufacturer_Report_Number__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_PermissiontoContactReporter__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Therapy_Start_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Weight_Unit__c = 'lb';
		PC_AdverseEvent2cVar.PC_EventType__c = 'Product Complaint';
		PC_AdverseEvent2cVar.PC_Stop_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Event_Onset_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Event_PT_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Product_Manufacturer__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Event_HLT_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_PatientLastname__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Patient_Identifier__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Ethnicity__c = 'Hispanic/Latino';
		PC_AdverseEvent2cVar.PC_Expiration_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_Event_HLGT__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Report_to_FDA__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Product_OTC__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Event_Verbatim__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Report_Source__c = 'Company Representative';
		PC_AdverseEvent2cVar.PC_Reporter_City__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Date_of_the_Report__c = system.today();
		PC_AdverseEvent2cVar.PC_Manufacturer_Phone__c = '1234567890';
		PC_AdverseEvent2cVar.PC_OtherMedicalHistory__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Event_LLT_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Product_Strength__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_If_IND_Give_Protocol__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Deactivation_Reason__c = 'Error in completing report';
		PC_AdverseEvent2cVar.PC_Product_Lot__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Indication_for_Product_Use__c = true;
		PC_AdverseEvent2cVar.PC_Therapy_End_Date__c = system.today();
		PC_AdverseEvent2cVar.PC_PreferredResponseChannel__c = 'Email';
		PC_AdverseEvent2cVar.PC_Adverse_Event_Terms__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Manufacturer_Email__c = 'test@test.com';
		PC_AdverseEvent2cVar.PC_Abated_After_Use_Stopped_or_Reduced__c = 'Yes';
		PC_AdverseEvent2cVar.PC_Event_SOC_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Reporter_Zip_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Deactivate__c = true;
		PC_AdverseEvent2cVar.PC_Event_HLGT_Code__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Race__c = 'Asian';
		PC_AdverseEvent2cVar.PC_SubmissionStatus__c = 'Submitted';
		PC_AdverseEvent2cVar.PC_Indication_for_use__c = 'ABCD';
		PC_AdverseEvent2cVar.PC_Meddra_Version__c = null;
		PC_AdverseEvent2cList.add(PC_AdverseEvent2cVar);
		}
		return PC_AdverseEvent2cList;
		}

   /*************************************************************************************************
     *  @method name         :  PC_ApplicantcTestDataMethod
     *  @method description  :  This method is used to create Applicant Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    
    public static List<PC_Applicant__c> createPC_ApplicantTestRecord(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Applicant__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Applicant__c> PC_ApplicantcList = new List<PC_Applicant__c>();
		for(Integer i=0;i<count;i++) {
		PC_Applicant__c PC_ApplicantcVar = new PC_Applicant__c();
		PC_ApplicantcVar.PC_Country1__c = 'Canada';
		PC_ApplicantcVar.PC_HCO2_Name__c = 'ABCD'+(Integer)Math.floor(Math.Random()*100);
		PC_ApplicantcVar.PC_HCO2_Street_Address1__c = 'Street 334';
		PC_ApplicantcVar.PC_HP2_Rx_Bin__c = 'Test qwerty';
		PC_ApplicantcVar.PC_HP_Plan_Status__c = 'Active';
		PC_ApplicantcVar.PC_Caregiver_Salutation__c = 'Mr.';
		PC_ApplicantcVar.PC_IsReviewed__c = true;
		PC_ApplicantcVar.PC_HP1_Rx_PCN__c = 'Test';
		PC_ApplicantcVar.PC_HCO_Type__c = 'Clinic';
		PC_ApplicantcVar.PC_HCO2_City__c = 'NY';
		PC_ApplicantcVar.PC_Address1_1__c = 'Street 556';
		PC_ApplicantcVar.PC_HP_Effective_Date__c = system.today();
		PC_ApplicantcVar.PC_HP2_ID_Policy_No__c = '50871222';
		PC_ApplicantcVar.PC_HP1_Plan_Status__c = 'Active';
		PC_ApplicantcVar.PC_HCO1_Phone__c = '0987654321';
		PC_ApplicantcVar.PC_Date_of_Birth__c = system.today();
		PC_ApplicantcVar.PC_HCO_Zipcode__c = '12231';
		PC_ApplicantcVar.PC_HP2_Rx_PCN__c = 'TEst PCN';
		PC_ApplicantcVar.PC_Training__c = true;
		PC_ApplicantcVar.PC_HP_Rx_PCN__c = 'field';
		PC_ApplicantcVar.PC_Caregiver_First_Name__c = 'Smith';
		PC_ApplicantcVar.PC_HCO2_State__c = 'NY';
		PC_ApplicantcVar.PC_HP1_Payer_Name__c = 'John';
		PC_ApplicantcVar.PC_Zip_Code__c = '5521';
		PC_ApplicantcVar.PC_HCO1_Fax__c = '98734';
		PC_ApplicantcVar.PC_HP2_Cardholder_s_Date_of_Birth__c = system.today();
		PC_ApplicantcVar.PC_HP2_Expiration_Date__c = system.today();
		PC_ApplicantcVar.PC_HP1_Expiration_Date__c = system.today();
		PC_ApplicantcVar.PC_Physician_Zipcode__c = '12122';
		PC_ApplicantcVar.PC_HCO_Street_Address1__c = 'Street 678';
		PC_ApplicantcVar.PC_HCO1_State__c = 'NY';
		PC_ApplicantcVar.PC_Medication__c = 'TestMed';
		PC_ApplicantcVar.PC_Last_Name__c = 'Watt';
		PC_ApplicantcVar.PC_HP_Cardholder_ID_Policy_No__c = 'ABCD';
		PC_ApplicantcVar.PC_Physician_Email__c = 'test@test.com';
		PC_ApplicantcVar.PC_Insurance_Name__c = 'Healthcare';
		PC_ApplicantcVar.PC_HP2_Payer_Name__c = 'Smith';
		PC_ApplicantcVar.PC_HP1_ID_Policy_No__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO1_Zipcode__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_Payer_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_Plan_Claim_Card_No__c = 'ABCD';
		PC_ApplicantcVar.PC_HP2_Rx_Grp__c = 'ABCD';
		PC_ApplicantcVar.PC_Dosage_Form__c = 'Tablet';
		PC_ApplicantcVar.PC_HP2_Cardholder_ID_Policy_No__c = 'ABCD';
		//PC_ApplicantcVar.RecordTypeId = recordTypeId;
		PC_ApplicantcVar.PC_Dosage_Strength_Units__c = 'mg';
		PC_ApplicantcVar.PC_Address1_Description__c = 'Home';
		PC_ApplicantcVar.PC_HP1_Plan_Type__c = 'Primary';
		PC_ApplicantcVar.PC_Address1_2__c = 'ABCD';
		PC_ApplicantcVar.PC_Dosage_Date__c = system.today();
		PC_ApplicantcVar.PC_Country__c = 'Canada';
		PC_ApplicantcVar.PC_BIN_No__c = 'ABCD';
		PC_ApplicantcVar.PC_Frequency__c = '1x';
		PC_ApplicantcVar.PC_Physician_Fax__c = 'ABCD';
		PC_ApplicantcVar.PC_HP1_Rx_Bin__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO2_Type__c = 'Clinic';
		PC_ApplicantcVar.PC_HP1_Cardholder_s_Date_of_Birth__c = system.today();
		PC_ApplicantcVar.PC_Gender__c = 'Male';
		PC_ApplicantcVar.PC_HP1_Record_Type__c = 'Private Health Plan';
		PC_ApplicantcVar.ACLS_Engagement_Program_Code__c = 'ABCD';
		PC_ApplicantcVar.PC_Insurance_Investigation__c = true;
		PC_ApplicantcVar.PC_HP2_Cardholder_Employer__c = 'ABCD';
		PC_ApplicantcVar.PC_Preferred_Channel__c = 'Phone';
		PC_ApplicantcVar.PC_HP2_Group_No__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_Plan_Type__c = 'Primary';
		PC_ApplicantcVar.PC_HCO_City__c = 'ABCD';
		PC_ApplicantcVar.PC_Initials__c = 'AB';
		PC_ApplicantcVar.PC_HP2_Cardholder_Rel_to_Patient__c = 'Self';
		PC_ApplicantcVar.PC_Coverage_Type__c = 'Alternate Funding';
		PC_ApplicantcVar.PC_Caregiver_Relationship_to_Patient__c = 'Self';
		PC_ApplicantcVar.PC_HCO2_Zipcode__c = 'ABCD';
		PC_ApplicantcVar.PC_HP2_Effective_Date__c = system.today();
		PC_ApplicantcVar.PC_Physician_Street_Address2__c = 'ABCD';
		PC_ApplicantcVar.PC_Physician_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_Physician_City__c = 'ABCD';
		PC_ApplicantcVar.PC_HP1_Cardholder_Employer__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_Rx_Grp__c = 'ABCD';
		PC_ApplicantcVar.PC_Zip_Code1__c = 'ABCD';
		PC_ApplicantcVar.PC_HP1_Cardholder_Rel_to_Patient__c = 'Self';
		PC_ApplicantcVar.PC_HP2_Plan_Type__c = 'Primary';
		PC_ApplicantcVar.PC_Address_1__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_Expiration_Date__c = system.today();
		PC_ApplicantcVar.PC_Dosage_Strength__c = null;
		PC_ApplicantcVar.PC_HP_Cardholder_Employer__c = 'ABCD';
		PC_ApplicantcVar.PC_City1__c = 'ABCD';
		PC_ApplicantcVar.PC_Primary_Address__c = true;
		PC_ApplicantcVar.PC_Caregiver_Last_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_Salutation__c = 'Mr.';
		PC_ApplicantcVar.PC_City__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO1_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_Primary_Address1__c = true;
		PC_ApplicantcVar.PC_State__c = 'ABCD';
		PC_ApplicantcVar.PC_First_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_HP1_Effective_Date__c = system.today();
		PC_ApplicantcVar.PC_Address_2__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO_Phone__c = '1234567890';
		PC_ApplicantcVar.PC_Patient_Email__c = 'test@test.com';
		PC_ApplicantcVar.PC_Address_Description__c = 'Home';
		PC_ApplicantcVar.PC_Source__c = true;
		PC_ApplicantcVar.PC_Every__c = 'Day';
		PC_ApplicantcVar.PC_HP1_Cardholder_ID_Policy_No__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO1_City__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO1_Type__c = 'Clinic';
		PC_ApplicantcVar.PC_HP_Cardholder_Rel_to_Patient__c = 'Self';
		PC_ApplicantcVar.PC_HP_Group_No__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO2_Phone__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_Cardholder_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_HCO_Fax__c = 'ABCD';
		PC_ApplicantcVar.PC_Physician_State__c = 'ABCD';
		PC_ApplicantcVar.PC_HP2_Plan_Status__c = 'Active';
		PC_ApplicantcVar.PC_Adherence_Support__c = true;
		PC_ApplicantcVar.PC_HCO_State__c = 'ABCD';
		PC_ApplicantcVar.PC_Phone__c = '1234567890';
		PC_ApplicantcVar.PC_HP_Rx_Bin__c = 'ABCD';
		PC_ApplicantcVar.PC_IsCreatedUsingOCR__c = true;
		PC_ApplicantcVar.PC_HCO2_Fax__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_Record_Type__c = 'Private Health Plan';
		PC_ApplicantcVar.PC_Renewal_Date__c = system.today();
		PC_ApplicantcVar.PC_HP_Cardholder_s_Date_of_Birth__c = system.today();
		PC_ApplicantcVar.PC_Physician_Phone__c = '1234567890';
		PC_ApplicantcVar.PC_Communication__c = 'English';
		PC_ApplicantcVar.PC_HCO1_Street_Address1__c = 'ABCD';
		PC_ApplicantcVar.PC_HP1_Rx_Grp__c = 'ABCD';
		PC_ApplicantcVar.PC_Physician_Street_Address1__c = 'ABCD';
		PC_ApplicantcVar.PC_HP_ID_Policy_No__c = 'ABCD';
		PC_ApplicantcVar.PC_HP2_Cardholder_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_State1__c = 'ABCD';
		PC_ApplicantcVar.PC_HP2_Record_Type__c = 'Private Health Plan';
		PC_ApplicantcVar.PC_HP1_Cardholder_Name__c = 'ABCD';
		PC_ApplicantcVar.PC_Other_Language__c = 'ABCD';
		PC_ApplicantcVar.PC_HP1_Group_No__c = 'ABCD';
		PC_ApplicantcList.add(PC_ApplicantcVar);
		}
		return PC_ApplicantcList;
		}
/*************************************************************************************************
     *  @method name         :  PC_DocumentcTestDataMethod
     *  @method description  :  This method is used to Document Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_Document__c> PC_DocumentcTestDataMethod(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Document__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Document__c> PC_DocumentcList = new List<PC_Document__c>();
		for(Integer i=0;i<count;i++) {
		PC_Document__c PC_DocumentcVar = new PC_Document__c();
		PC_DocumentcVar.PC_Error__c = 'ABCD';
		PC_DocumentcVar.PC_Correlation_Id__c = 'ABCD'+(Integer)Math.floor(Math.Random()*100);
		PC_DocumentcVar.PC_Fax_Handle__c = '3680976';
		PC_DocumentcVar.PC_From_Name__c = 'Ashfield';
		PC_DocumentcVar.PC_Outbound_Fax_Handle__c = '12346';
		PC_DocumentcVar.PC_To_Email_Address__c = 'test@test.com';
		PC_DocumentcVar.PC_From_Email_Address__c = 'test@test.com';
		PC_DocumentcVar.PC_Fax_Sent_Date_Time__c = system.now();
		PC_DocumentcVar.PC_To_Fax_Number__c = '18126102356';
		PC_DocumentcVar.PC_SMS_Timestamp__c = 'Test';
		PC_DocumentcVar.PC_From_Fax_Number__c = '723716';
		PC_DocumentcVar.PC_Description__c = 'Data created';
		PC_DocumentcVar.PC_To_Fax_Name__c = 'Deloitte';
		PC_DocumentcVar.PC_isPIIIdentified__c = true;
		PC_DocumentcVar.PC_To_Email_Address_Inbound__c = 'abc@abc.com';
		PC_DocumentcVar.PC_Sorted_Parent_Pg_Num__c = '46';
		//PC_DocumentcVar.RecordTypeId = recordTypeId;
		PC_DocumentcVar.PC_Document_Name__c = 'Test Document';
		PC_DocumentcVar.PC_Page_Count__c = null;
		PC_DocumentcVar.PC_Marked_Spam_On__c = system.today();
		PC_DocumentcVar.PC_Fax_Unique_Id__c = '9a3e5059-9af8-45a5-806e-f8e695009d73';
		PC_DocumentcVar.PC_Inbound_Fax__c = true;
		PC_DocumentcVar.PC_IsSplit__c = true;
		PC_DocumentcVar.PC_EngagementProgramCode__c = 'None';
		PC_DocumentcVar.PC_Mark_for_Delete__c = true;
		PC_DocumentcVar.PC_Document_Status__c = 'New';
		PC_DocumentcVar.PC_Attachment_Id__c = '998';
		PC_DocumentcVar.PC_SMS_Body__c = 'generating the documents';
		PC_DocumentcVar.PC_Document_Category__c = 'Enrollment Form';
		PC_DocumentcVar.PC_ParentPgRange__c = '5';
		PC_DocumentcVar.PC_Inbound_Fax_Date_Time__c = system.now();
		PC_DocumentcVar.PC_Failure_Count__c = null;
		PC_DocumentcVar.PC_Archived_On__c = system.now();
		PC_DocumentcVar.PC_SMS_Phone_Number__c = '0987654321';
		PC_DocumentcList.add(PC_DocumentcVar);
		}
		return PC_DocumentcList;
		} 
     /*************************************************************************************************
     *  @method name         :  PC_OrdercTestDataMethod
     *  @method description  :  This method is used to create Order Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_Order__c> PC_OrdercTestDataMethod(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Order__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Order__c> PC_OrdercList = new List<PC_Order__c>();
		for(Integer i=0;i<count;i++) {
		PC_Order__c PC_OrdercVar = new PC_Order__c();
		PC_OrdercVar.PC_OrderAddress2__c = 'Ashfield';
		PC_OrdercVar.PC_OrderAddress3__c = '495 Grove Street';
		PC_OrdercVar.PC_OrderAddressZipCode__c = '10014';
		PC_OrdercVar.PC_ActualDeliveryDate__c = system.now();
		PC_OrdercVar.PC_OrderAddress1__c = 'New York';
		PC_OrdercVar.PC_EstimatedDeliveryDate__c = system.now();
		PC_OrdercVar.PC_ReceivedBy__c = 'Deloitte';
		PC_OrdercVar.PC_ShipmentTrackingNumber__c = 'ABCD';
		PC_OrdercVar.PC_OrderAddressState__c = 'TestNY';
		PC_OrdercVar.PC_OrderAddressCity__c = 'New York';
		PC_OrdercVar.PC_ShippingDate__c = system.now();
		PC_OrdercVar.PC_SubmittedDate__c = system.now();
		PC_OrdercVar.PC_OrderStatus__c = 'Draft';
		PC_OrdercVar.ACLS_Engagement_Program_Code__c = 'QWERT'+(Integer)Math.floor(Math.Random()*100);
		PC_OrdercVar.PC_ShipTo2__c = 'Patient';
		PC_OrdercVar.PC_DeliveryDayRun__c = 'Same Day Delivery';
		PC_OrdercVar.PC_OrderInstructions__c = 'Do not use plastic bags for packaging';
		PC_OrdercVar.PC_OrderType__c = 'Bridge Program';
		PC_OrdercVar.PC_PreferredDeliveryDate__c = system.now();
		PC_OrdercVar.PC_PreferredDeliveryWindow__c = 'Anytime';
		PC_OrdercList.add(PC_OrdercVar);
		}
		return PC_OrdercList;
		} 
    /*************************************************************************************************
     *  @method name         :  PC_Pharmacy_ReferralcTestDataMethod
     *  @method description  :  This method is used to create Pharmacy Referral Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_Pharmacy_Referral__c> PC_Pharmacy_ReferralcTestDataMethod(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Pharmacy_Referral__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Pharmacy_Referral__c> PC_Pharmacy_ReferralcList = new List<PC_Pharmacy_Referral__c>();
		for(Integer i=0;i<count;i++) {
		PC_Pharmacy_Referral__c PC_Pharmacy_ReferralcVar = new PC_Pharmacy_Referral__c();
		PC_Pharmacy_ReferralcVar.PC_Reason_Code__c = 'TEST'+(Integer)Math.floor(Math.Random()*100);
		PC_Pharmacy_ReferralcVar.PC_End_Date__c = system.today();
		PC_Pharmacy_ReferralcVar.PC_Source__c = 'Ashfield';
		PC_Pharmacy_ReferralcVar.ACLS_Engagement_Program_Code__c = 'ASHF';
		PC_Pharmacy_ReferralcVar.PC_Start_Date__c = system.today();
		PC_Pharmacy_ReferralcVar.PC_Referral_Status__c = 'Started';
		PC_Pharmacy_ReferralcList.add(PC_Pharmacy_ReferralcVar);
		}
		return PC_Pharmacy_ReferralcList;
		} 
    /*************************************************************************************************
     *  @method name         :  PC_PrescriptioncTestDataMethod
     *  @method description  :  This method is used to create Prescription Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_Prescription__c> PC_PrescriptioncTestDataMethod(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Prescription__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Prescription__c> PC_PrescriptioncList = new List<PC_Prescription__c>();
		for(Integer i=0;i<count;i++) {
		PC_Prescription__c PC_PrescriptioncVar = new PC_Prescription__c();
		PC_PrescriptioncVar.PC_Requested_Quantity__c = null;
		PC_PrescriptioncVar.PC_Rx_Status__c = true;
		PC_PrescriptioncVar.PC_Frequency__c = 'ABCD'+(Integer)Math.floor(Math.Random()*100);
		PC_PrescriptioncVar.PC_Rx_End_Date__c = system.today();
		PC_PrescriptioncVar.PC_hasActivePA__c = true;
		PC_PrescriptioncVar.PC_PrimaryDiagnosis__c = 'M81.0';
		PC_PrescriptioncVar.PC_Rx_Start_Date__c = system.today();
		PC_PrescriptioncVar.PC_Days_Supply__c = null;
		PC_PrescriptioncVar.ACLS_Engagement_Program_Code__c = 'VSHF';
		PC_PrescriptioncVar.PC_Rx_Refills__c = null;
		PC_PrescriptioncVar.PC_PlaceOfService__c = '22';
		PC_PrescriptioncVar.PC_Dosage__c = 'one';
		PC_PrescriptioncVar.PC_SecondaryDiagnosis__c = 'M82.0';
		PC_PrescriptioncList.add(PC_PrescriptioncVar);
		}
		return PC_PrescriptioncList;
		} 
    /*************************************************************************************************
     *  @method name         :  ServiceTestDataMethod
     *  @method description  :  This method is used to create Service Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    public static List<PC_Service__c> ServiceTestDataMethod(Integer count, String serviceName){ 
		//Id recordTypeId = Schema.SObjectType.PC_Prescription__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Service__c> PC_ServicecList = new List<PC_Service__c>();
		for(Integer i=0;i<count;i++) {
		PC_Service__c PC_ServiceVar = new PC_Service__c();
		PC_ServiceVar.Name = serviceName;
		
		PC_ServicecList.add(PC_ServiceVar);
		}
		return PC_ServicecList;
		}
    /*************************************************************************************************
     *  @method name         :  Program_Service_PermissioncTestDataMethod
     *  @method description  :  This method is used to Program Service Permission Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_Program_Service_Permission__c> Program_Service_PermissioncTestDataMethod(Integer count, List<PC_Service__c> services){ 
		//Id recordTypeId = Schema.SObjectType.PC_Program_Service_Permission__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Program_Service_Permission__c> PC_Program_Service_PermissioncList = new List<PC_Program_Service_Permission__c>();
		for(Integer i=0;i<count;i++) {
		PC_Program_Service_Permission__c PC_Program_Service_PermissioncVar = new PC_Program_Service_Permission__c();
		PC_Program_Service_PermissioncVar.PC_Consent_Type__c = 'Verbal';
		PC_Program_Service_PermissioncVar.PC_CareTeamMemberResponse__c = 'Granted';
		PC_Program_Service_PermissioncVar.PC_End_Date__c = system.today()+8;
		PC_Program_Service_PermissioncVar.PC_Patient_Response_Date__c = system.today();
		PC_Program_Service_PermissioncVar.ACLS_Engagement_Program_Code__c = 'ABCD'+(Integer)Math.floor(Math.Random()*100);
		PC_Program_Service_PermissioncVar.ACLS_HCP_Permission_Required__c = true;
		PC_Program_Service_PermissioncVar.ACLS_PT_Legal_GUA_Permission_Required__c = true;
		PC_Program_Service_PermissioncVar.PC_HCP_Response_Date__c = system.today();
		PC_Program_Service_PermissioncVar.PC_Patient_Response__c = 'Signed';
		PC_Program_Service_PermissioncVar.PC_HCP_Response__c = 'Signed';
		PC_Program_Service_PermissioncVar.PC_Start_Date__c = system.today()+1;
		PC_Program_Service_PermissioncVar.PC_CareTeamMemberResponseDate__c = system.today();
        PC_Program_Service_PermissioncVar.PC_Service__c = services[i].Id;
		PC_Program_Service_PermissioncList.add(PC_Program_Service_PermissioncVar);
		}
		return PC_Program_Service_PermissioncList;
		}
    /*************************************************************************************************
     *  @method name         :  PC_InteractioncTestDataMethod
     *  @method description  :  This method is used to Program Service Permission Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    public static List<PC_Interaction__c> PC_InteractioncTestDataMethod(Integer count){ 
    List<PC_Interaction__c> PC_InteractionList = new List<PC_Interaction__c>();
		for(Integer i=0;i<count;i++) {
		PC_Interaction__c PC_intrctVar = new PC_Interaction__c();
		PC_intrctVar.PC_Type__c='Injection Training';
        PC_intrctVar.PC_Notes__c='Xyz';
		
		PC_InteractionList.add(PC_intrctVar);
		}
		return PC_InteractionList;
   
    }
    /*************************************************************************************************
     *  @method name         :  PC_ServiceTestDataMethod
     *  @method description  :  This method is used to create Service Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    public static List<PC_Service__c> PC_ServiceTestDataMethod(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Prescription__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Service__c> PC_ServicecList = new List<PC_Service__c>();
		for(Integer i=0;i<count;i++) {
		PC_Service__c PC_ServiceVar = new PC_Service__c();
		//PC_ServiceVar.Name = serviceName;
		PC_ServiceVar.Name='HIPAA Authorization';
		PC_ServicecList.add(PC_ServiceVar);
		}
		return PC_ServicecList;
		}
    /*************************************************************************************************
     *  @method name         :  PC_Program_Service_PermissioncTestDataMethod
     *  @method description  :  This method is used to Program Service Permission Test Data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
 	public static List<PC_Program_Service_Permission__c> PC_Program_Service_PermissioncTestDataMethod(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Program_Service_Permission__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Program_Service_Permission__c> PC_Program_Service_PermissioncList = new List<PC_Program_Service_Permission__c>();
		for(Integer i=0;i<count;i++) {
		PC_Program_Service_Permission__c PC_Program_Service_PermissioncVar = new PC_Program_Service_Permission__c();
		PC_Program_Service_PermissioncVar.PC_Consent_Type__c = 'Verbal';
		PC_Program_Service_PermissioncVar.PC_CareTeamMemberResponse__c = 'Granted';
		PC_Program_Service_PermissioncVar.PC_End_Date__c = system.today()+8;
		//PC_Program_Service_PermissioncVar.PC_Patient_Response_Date__c = system.today();
		PC_Program_Service_PermissioncVar.ACLS_Engagement_Program_Code__c = 'ABCD'+(Integer)Math.floor(Math.Random()*100);
		PC_Program_Service_PermissioncVar.ACLS_HCP_Permission_Required__c = true;
		PC_Program_Service_PermissioncVar.ACLS_PT_Legal_GUA_Permission_Required__c = false;
		PC_Program_Service_PermissioncVar.PC_HCP_Response_Date__c = system.today();
		//PC_Program_Service_PermissioncVar.PC_Patient_Response__c = 'Signed';
		PC_Program_Service_PermissioncVar.PC_HCP_Response__c = 'Signed';
		PC_Program_Service_PermissioncVar.PC_Start_Date__c = system.today()+1;
		PC_Program_Service_PermissioncVar.PC_CareTeamMemberResponseDate__c = system.today();
        
		PC_Program_Service_PermissioncList.add(PC_Program_Service_PermissioncVar);
		}
		return PC_Program_Service_PermissioncList;
		}

	/*************************************************************************************************
	 *  @method name         :  ACLS_Missing_InformationcTestDataMethod
	 *  @method description  :  This method is used for Missing Information Test Data
	 *  @method param        :  Integer Count, String sObjectName
	 *  @method return type  :  List<sObject>
	 **************************************************************************************************/
	public static List<sObject> ACLS_Missing_InformationcTestDataMethod(Integer count, String sObjectName, String recordTypeName){ 
		List<ACLS_Missing_Information__c> ACLS_Missing_InformationcList = new List<ACLS_Missing_Information__c>();
		for(Integer i=0;i<count;i++) {
		ACLS_Missing_Information__c ACLS_Missing_InformationcVar = new ACLS_Missing_Information__c();
		ACLS_Missing_InformationcVar.ACLS_Object_Name__c = sObjectName;
		// ACLS_Missing_InformationcVar.ACLS_Source_Record_Id__c = 'ABCD';
		ACLS_Missing_InformationcVar.ACLS_Status__c = 'Active';
		ACLS_Missing_InformationcVar.ACLS_Object_Record_Type_Name__c = recordTypeName;
		ACLS_Missing_InformationcVar.ACLS_Object_Record_Id__c = 'ABCD';
		//ACLS_Missing_InformationcVar.ACLS_Missing_Information_Fields__c = 'ABCD';
		ACLS_Missing_InformationcList.add(ACLS_Missing_InformationcVar);
		}
		return ACLS_Missing_InformationcList;
	} 
    /*************************************************************************************************
     *  @method name         :  testFaxData
     *  @method description  :  This method is used to create Fax data
     *  @method param        :  Integer Count, String recordType
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    
    public static List<EFX__efax__c> faxTestDataMethod(Integer count){ 
		//Id faxRecordTypeId = Schema.SObjectType.EFX__efax__c.getRecordTypeInfosByName().get('Sent Fax').getRecordTypeId();
        Id faxRecordTypeId = Schema.SObjectType.EFX__efax__c.getRecordTypeInfosByDeveloperName().get('Sent_Fax').getRecordTypeId();
        System.debug('faxRecordTypeId'+faxRecordTypeId);
		List<EFX__efax__c> faxList = new List<EFX__efax__c>();
		for(Integer i=0;i<count;i++) {
		EFX__efax__c objFax = new EFX__efax__c();
		objFax.EFX__eFax_Id__c = '9a3e5059-9af8-45a5-806e-f8e695009d73';
		objFax.EFX__From__c = '723716';
		objFax.EFX__To__c = '18126102356';
		objFax.EFX__Status__c = 'NEW';
        objFax.recordTypeId = faxRecordTypeId;
		faxList.add(objFax);
		}
		return faxList;
		} 
    
    /*************************************************************************************************
     *  @method name         :  testContentDocument
     *  @method description  :  This method is used to create Content document 
     *  @method param        :  Integer Count
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
     public static List<ContentVersion> testContentDocument(Integer count){ 
       		List<ContentVersion> cv = new List<ContentVersion>();
         for(Integer i=0;i<count;i++)
         {
             ContentVersion obj = new ContentVersion();
            obj.Title = 'Test Document';
            obj.PathOnClient = 'TestDocument.pdf';
            obj.VersionData = Blob.valueOf('Test Content');
            cv.add(obj);
         }
         return cv;
     }
    /*************************************************************************************************
     *  @method name         :  testContentDocumentLink
     *  @method description  :  This method is used to create Content document link
     *  @method param        :  Integer Count
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    public static List<ContentDocumentLink> testContentDocumentLink(Integer count){ 
		//Id faxRecordTypeId = Schema.SObjectType.EFX__efax__c.getRecordTypeInfosByName().get('Received_Fax').getRecordTypeId();
		List<ContentDocumentLink> cdLink = new List<ContentDocumentLink>();
		for(Integer i=0;i<count;i++) {
		ContentDocumentLink objCDL = new ContentDocumentLink();
		objCDL.ShareType = 'I';
		objCDL.Visibility = 'AllUsers';
		cdLink.add(objCDL);
		}
		return cdLink;
		} 
    
    /*************************************************************************************************
     *  @method name         :  createEngagmentProgram
     *  @method description  :  This method is used to create Test EngagementProgram
     *  @method param        :  Integer Count
     *  @method return type  :  List<ACLS_KeyValue__mdt>
     **************************************************************************************************/
    public static List<ACLS_KeyValue__mdt> createKeyValue(Integer count){
        List<ACLS_KeyValue__mdt> lstKeyValue = new List<ACLS_KeyValue__mdt>();
        for (Integer i = 0; i < count; i++){
            ACLS_KeyValue__mdt keyValue = new ACLS_KeyValue__mdt();
            keyValue.ACLS_Key__c = 'ACLS_SMS_SendSMSBatch';
            keyValue.ACLS_Value__c = '40';
            keyValue.ACLS_Type__c = 'Batch Size';
            lstKeyValue.add(keyValue);
        }
        return lstKeyValue;
    }
 /*************************************************************************************************
     *  @method name         :  testRemoteServiceLog
     *  @method description  :  This method is used to create Remote service log
     *  @method param        :  Integer Count
     *  @method return type  :  List<sObject>
     **************************************************************************************************/
    public static List<sObject> testRemoteServiceLog(Integer count){ 
		//Id recordTypeId = Schema.SObjectType.PC_Remote_Service_Log__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
		List<PC_Remote_Service_Log__c> PC_Remote_Service_LogcList = new List<PC_Remote_Service_Log__c>();
		for(Integer i=0;i<count;i++) {
		PC_Remote_Service_Log__c PC_Remote_Service_LogcVar = new PC_Remote_Service_Log__c();
		PC_Remote_Service_LogcVar.PC_Additional_Information__c = 'ABCD';
		PC_Remote_Service_LogcVar.PC_Callback_URL__c = 'ABCD';
		PC_Remote_Service_LogcVar.PC_Service_Name__c = 'CMM';
		PC_Remote_Service_LogcVar.PC_StatusCode__c = 'ABCD';
		PC_Remote_Service_LogcVar.PC_Callback_URL2__c = 'ABCD';
		PC_Remote_Service_LogcVar.PC_Service_Type__c = 'Inbound';
		PC_Remote_Service_LogcVar.PC_Callback_Request__c = 'ABCD';
		PC_Remote_Service_LogcVar.PC_Callback_Response__c = 'ABCD';
		PC_Remote_Service_LogcList.add(PC_Remote_Service_LogcVar);
		}
		return PC_Remote_Service_LogcList;
		}
    
     //Create Document parent data
    
    public static PC_Document__c createParentDoc()
    {
        PC_Document__c pDoc = new PC_Document__c();
        pDoc.PC_Document_Status__c = ACLS_Constants.COMPLETE_STATUS;
		if(Schema.sObjectType.PC_Document__c.isCreateable()) {
			insert pDoc;
			}
        return pDoc;
    }
    
    //Create Child Documents
    
    public static List<PC_Document__c> createChildDocuments(PC_Document__c parentDoc)
    {
        List<PC_Document__c> childDocs = new List<PC_Document__c>();
        for(Integer i = 0; i < 3; i++)
        {
            PC_Document__c cDoc  = new PC_Document__c();
            cDoc.PC_Document_Status__c = ACLS_Constants.REVIEW_NEEDED;
            cDoc.PC_Parent_Document__c = parentDoc.Id;
            childDocs.add(cDoc);
        }
       // insert childDocs;
        return childDocs;
            
        
    }
}