/*******************************************************************************************
Class Name      : PC_Test_Setup 
Description     : This class is used for storing all common methods which will be used by the Test Methods
Created By      : Deloitte
Created Date    : May 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Alina Balan               May 30, 2016             Initial Version
Prachi Nandgaonkar,
Shabda Bhujad             Oct 27, 2016             Removed method createMedication() for Managed Package code cleanup PC-155
Prachi Nandgaonkar,
Shabda Bhujad             Oct 27, 2016             Removed method all methods related to Holiday functionality for Managed Package code cleanup PC-155
Annoted by @@HOL
Prachi Nandgaonkar,
Shabda Bhujad             Nov 2, 2016              Removed method all methods related to Threshold for Managed Package code cleanup PC-155
Annoted by @@RemoveThreshold
Prachi Nandgaonkar,
Shabda Bhujad             Nov 3, 2016              Removed reference for Phone field on address for Managed Package code cleanup PC-155 Annoted by @@RemoveAddressPhone
Shabda Bhujad             Nov 14, 2016             Removed assignment of BRAND
Shabda Bhujad			  Feb 15, 2016			   Added the new mandatory field 'PC_Program_Code__c' to createEngagementProgram() method with a static value- PC_Program_Code__c = '23424211'
Prachi Nandgaonkar        March 3, 2017            Updated String CALL_CENTER_AGENT_PROFILE to use System Admin profile PC-1240
Ajinkya Deshmukh		  Apr 25, 2017			   [PC-1365] Updated method createDocument()
Shabda Bhujad			  May 15, 2017 			   [PC-1584] Added the method createEnrlCase() for creating case for applicant
Tejas Patel				  May 26, 2017			   New methods added createServices and createProgramServicePermissions
Ajinkya Deshmukh		  June 12, 2017			   Class made With Sharing
Shabda Bhujad			  July 10,2017			   [PC-1886] Removed unnecessary assignments from method createAccounts with 'Record Type' as parameter
Prachi Nandgaonkar        Aug 9, 2017              [PC-1730] Created a method for Pharmacy referral creation
Tejas Patel				  Sep 8, 2017			   [PC-2016] New Test Methods added newProduct, newDistributionNetwork
Prachi Nandgaonkar        Sept 15, 2017            [PC-2217]Updated newDistributionNetwork() with updated object name
Tejas Patel				  Nov 16, 2017			   [PC-2065] Use new profiles created for testing
Tejas Patel				  Mar 21, 2018			   Updated Signature for createSupportPlanActivity
Shishir Bansal            May 26, 2019             [PC-2616] crated new method for suspect prescriptions with adverseEventId as a param
Kanteti Kishore           July 24,2019             created person account test data createPA
Kanteti Kishore           July 25,2019             created person account test data createPAPatient
Tushar Arora              July 31,2019             Modified Test method createPA for personAccount Support
Vijay Kashikar            Feb 17,2020              [PC-5999] Updated assignHealthCloudPermissionSet to assign Member Services permission set license
Haritha Reddy             Apr 27,2020              [PC-6227] Added new Method to create Support Plan Activity of type Create Record & Publish Platform Event
Kanteti Kishore           May 5,2020              [PC-5940] Added new Method to create Engagement Program Eletter Record - createEngagementProgramEletter()
Haritha Reddy			  Feb 17,2021             PC-7423 Modified code to set Start date to GMT value of today's date in createProgramServicePermissions()
Hitha Avalakki            Feb 26,2021             [PC-7442]: 1) Created new method to create Program cases: createProgramCases() method.
                                                             2) Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
                                                             3) Created new Exception class TestProgramException.
                                                             4) Edited method createCases() to throw an exception to notify user to use createProgramCases() for creation of Program cases
Hitha Avalakki            Mar 04, 2021            [PC-7442] Replaced getProgramCaseRecordTypeId() with getDefaultProgramCaseRecordTypeId()
Haritha Reddy             Mar 05, 2021            [PC-7497] Added new constant to store FRM Profile name
Kanteti Kishore           Mar 12, 2021            [PC-7485] Added methods createTasks,createEvents,createEmailMessages,createEmailMessageRelations,assignFRMUserPermissionSet
Kanteti Kishore           Jun 21, 2021            [PC-7485] Added methods createReminderQueues
Vijay Kashikar            Jun 26, 2021            [PC-7841] Updated createHealthPlans to add expiration date, effective date & status
Kishore Kanteti           Oct 15, 2021            [PC-8183] Added method createReminderLog to create reminder log records when needed in test classes.
Haritha Reddy             Oct 20, 2021            [PC-8237] Updated createPublishPlatformEventSPA to add a row for testing isBoundValue value assignment.
Hitha Avalakki            Oct 20, 2021            [PC-8139] Added code to create task related user task fields' string required for Support plan execution
Hitha Avalakki            Nov 10, 2021            [PC-8319] Added logic to cover consent model changes for eletter
****************************************************************************************************************/

public with sharing class PC_Test_Setup {
    public static final String PHYSICIAN_RECORD_TYPE = 'PC_Physician';
    public static final String ACCOUNT_OBJ = 'Account';
    public static final String CASE_OBJ = 'Case';
    public static final String ACCOUNT_NAME = 'Account Name';
    public static final String CALL_CENTER_AGENT_PROFILE = 'PC_TestUser';
    public static final String SYS_ADMIN_PROFILE = 'PC_TestUser';
    public static final string RESTRICTED_PROFILE = 'PC_TestReadOnly';
    public static final string FRM_PROFILE = 'PC FRM User';
    //public static final String BRAND = 'Diomed';
    public static final String PATIENT_NAME = 'test patient name';
    public static final String MEASUREMENT_TYPE = 'Sleep';
    public static final String SUPPORTPLAN_NAME = 'TestSupPlan';

    
    /*********************************************************************************
Method Name    : create Account
Author         : Roxana Ivan
Description    : This method is used for creating an account object
Return Type    : Account 
Parameter      : String parent Id, String account Name
*********************************************************************************/
    
    public static Account newAccount(Id pParentId, String pAcName, String firstName, String lastName, String recordType){
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, recordType);
        return new Account(Name = pAcName,
                           AccountNumber = 'ABC1234',
                           ParentId = pParentId,
                           Industry = 'Retail',
                           BillingCity = 'New York',
                           BillingStreet = '123 First Avenue',
                           BillingPostalCode = '12324',
                           NumberOfEmployees = 500,
                           PC_First_Name__c = firstName,
                           PC_Last_Name__c = lastName,
                           RecordTypeId = recordTypeId);
    }
    /*********************************************************************************
    Method Name    : createPA
    Author         : Kishore Kanteti
    Description    : This method is used for creating an person account object
    Return Type    : Account
    Parameter      : String strPAName, String recordType
    *********************************************************************************/

    public static Account createPA( String strPAName,String recordType){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PC_Constants.PC_PATIENT_PERSONACCOUNT_RECORDTYPE_API).getRecordTypeId();

        Account acc = new Account();

        if(PC_SYSTEM.isPersonAccountEnabled()){
            System.debug('enter condition PA');
            acc.put('RecordTypeId',recordTypeId);
            acc.put('lastName',strPAName);
            acc.put('firstName','Test');
        } else {
            System.debug('enter condition not PA');
            acc.put('PC_First_Name__c',strPAName);
            acc.put('PC_Last_Name__c',strPAName);
            acc.put('Name',strPAName);
        }

        acc.put('AccountNumber','ABC1234');
        acc.put('Industry','Retail');
        acc.put('BillingCity','New York');
        acc.put('BillingStreet','123 First Avenue');
        acc.put('BillingPostalCode','12324');
        acc.put('NumberOfEmployees',500);
        return acc;
    }

    /*********************************************************************************
    Method Name    : createPAPatient
    Author         : Kishore Kanteti
    Description    : This method is used for creating an person account Patient object
    Return Type    : Account
    Parameter      : String strPAName, String recordType
    *********************************************************************************/

    public static Account createPAPatient(String strPAName,String recordType){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PC_Constants.PC_PATIENT_PERSONACCOUNT_RECORDTYPE_API).getRecordTypeId();
        Account acc = new Account();
        acc.PC_First_Name__c = strPAName;
        acc.PC_Last_Name__c = strPAName;
        if(!PC_SYSTEM.isPersonAccountEnabled()){
            acc.put('Name','Test'+strPAName);
        } else {
            acc.RecordTypeId = recordTypeId;
        }
        return acc;

    }


    /*********************************************************************************
Method Name    : create Account
Author         : Roxana Ivan
Description    : This method is used for creating an account object
Return Type    : Account 
Parameter      : String parent Id, String account Name
*********************************************************************************/
    
    public static Account newAccount(Id pParentId, String pAcName){
        return new Account(Name = pAcName,
                           AccountNumber = 'ABC1234',
                           ParentId = pParentId,
                           Industry = 'Retail',
                           BillingCity = 'New York',
                           BillingStreet = '123 First Avenue',
                           BillingPostalCode = '12324',
                           NumberOfEmployees = 500);
    }
    
    /*********************************************************************************
Method Name    : create Account
Author         : Roxana Ivan
Description    : This method is used for creating an account object
Return Type    : Account 
Parameter      : String account Name
*********************************************************************************/
    public static Account newAccount(String pAcName){
        return newAccount(null, pAcName);
    }
    
    /*********************************************************************************
Method Name    : create Accounts
Author         : Roxana Ivan
Description    : This method is used for creating multiple accounts object
Return Type    : Account 
Parameter      : String account root name, Integer number of records
*********************************************************************************/
    public static List<Account> newAccounts(String pRootName, Integer pNoRecs){
        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, PHYSICIAN_RECORD_TYPE);
        List<Account> newAccounts = new List<Account>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            Account Account = new Account();
            account.Name = 'Physician Name '+i;
            account.PC_Specialist_Type__c = 'Cardiologist';
            account.Type = 'Specialist';
            account.PC_Sub_Type__c = 'Other';
            account.recordTypeId = accountRecordTypeId;
            newAccounts.add(account);
        }
        return newAccounts;
    }
    
    
    public static Account createTestAccount(String recordType) {
        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, recordType);
        system.debug('@@@ ' +recordType + ' = ' +accountRecordTypeId);
        Account account = new Account(Name = ACCOUNT_NAME, RecordTypeId = accountRecordTypeId);
        return account;
    }
    
    /*********************************************************************************
Method Name    : create Case
Author         : Roxana Ivan
Description    : This method is used for creating a case object
Return Type    : Case 
Parameter      : String accountId, String recordy type
*********************************************************************************/
    public static Case newCase(Id accountId, String recordType) {
        return newCase(null, accountId, recordType);
    }
    
    /*********************************************************************************
Method Name    : create Case
Author         : Roxana Ivan
Description    : This method is used for creating a case object
Return Type    : Case 
Parameter      : String parent Id, String accountId, String recordy type
*********************************************************************************/
    public static Case newCase(Id parentId, Id accountId, String recordType) {
        Id biCaseRecordTypeId;

        if(!String.isBlank(recordType) && recordType.equals(PC_Constants.CASE_PROGRAM_RECORD_TYPE)){
            biCaseRecordTypeId= PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
        }
        else{
            biCaseRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, recordType);
        }
        Case testCase = new Case (
            RecordTypeId = biCaseRecordTypeId,
            ParentId = parentId,
            AccountId = accountId,
            Status= 'New'
        );
        return testCase;
    }
    
    /*********************************************************************************
Method Name    : createUser
Author         : Alina Balan
Description    : This method is used for creating a user object
Return Type    : User
Parameter      : String sProfileName, String sUserName, String sAlias
*********************************************************************************/
    public static User createUser(String sProfileName, String sUserName, String sAlias) {
        // Get the profile details
        Profile p = [SELECT Id FROM Profile WHERE Name = :sProfileName];
        User objUser = new User(Alias = sAlias, email = sUserName,emailencodingkey = 'UTF-8', lastname = 'Testing', languagelocalekey = 'en_US', 
                                localesidkey = 'en_US',country = 'United States', profileid = p.Id,
                                timezonesidkey = 'America/Los_Angeles', username = sUserName);

        return objUser;
    }

    public static void assignHealthCloudPermissionSet(String userId) {
        String healthCloudPermissionSet = PC_Constants.HealthCloudPermissionSetLicenseName;
        String healthCloudMemberServicesPermissionSet = PC_Constants.HealthCloudMemberServicesPermissionSetLicenseName;
        List<PermissionSet> permissionSets = [SELECT ID From PermissionSet WHERE Name IN (:healthCloudPermissionSet, :healthCloudMemberServicesPermissionSet)];
        upsert new PermissionSetAssignment(AssigneeId = userId,  PermissionSetId = permissionSets[0].Id);
        upsert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSets[1].Id);



    }
/*
    @MethodName        : assignFRMUserPermissionSet
    @Author             : Kishore Kanteti
    @Description        : This method is used for assigning permissions set to FRM User
    @ReturnType         : void
    @Param              : String
    */
    public static void assignFRMUserPermissionSet(String userId) {
        String frmUserPermissionSet = PC_Constants.PC_FRMUSER_PERMISSIONSET;
        List<PermissionSet> permissionSets = [SELECT ID From PermissionSet WHERE Name =: frmUserPermissionSet];
        insert new PermissionSetAssignment(AssigneeId = userId,  PermissionSetId = permissionSets[0].Id);
    }

    /*
Method Name    : createUsers
Author         : Ajinkya Deshmukh
Description    : This method is used for creating a users
Return Type    : User
Parameter      : String sProfileName, String sUserName, String sAlias
*/
    public static List<User> createUsers(String sProfileName, String sUserName, String sAlias, Integer noRecords) {
        List<User> allUsers = new List<User>();
        for(integer i = 0; i < noRecords; i ++){
            allUsers.add(createUser(sProfileName, i + sUserName, i + sAlias));
        }
        return allUsers;
    }   
    /*********************************************************************************
Method Name    : createDocument
Author         : Alina Balan
Description    : This method is used for creating a document object
Return Type    : PC_Document__c
Parameter      : String sRecordType, String sStatus
*********************************************************************************/
    public static PC_Document__c createDocument(String sRecordType, String sStatus) {
        PC_Document__c doc = createDocument(sRecordType, sStatus, 'programA74');
        return doc;
    }

    /*********************************************************************************
Method Name    : createDocument
Author         : Ajinkya Deshmukh
Description    : This method is used for creating a document object
Return Type    : PC_Document__c
Parameter      : String sRecordType, String sStatus
*********************************************************************************/
    public static PC_Document__c createDocument(String sRecordType, String sStatus, String programName) {
        Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc, false);
        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram (programName, manufacturerAcc.Id);
        PC_Database.ins(engagementProgram, false);
        PC_Document__c objDocument = new PC_Document__c();
        objDocument.RecordTypeId=PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, sRecordType);
        objDocument.PC_Document_Status__c = sStatus;
        objDocument.PC_Page_Count__c = 5;
        objDocument.PC_Engagement_Program__c = engagementProgram.Id;
        return objDocument;
    }
    
    /*********************************************************************************
Method Name    : createAttachment
Author         : Alina Balan
Description    : This method is used for creating a attachment object
Return Type    : Attachment
Parameter      : Id docId
*********************************************************************************/
    public static Attachment createAttachment(Id docId) {
        Attachment objAtt = new Attachment();
        String name = 'abc';
        objAtt.body = Blob.valueof(name);
        objAtt.name = 'DemoName.pdf';
        objAtt.ParentId = docId;
        return objAtt;
    }
    
    /*********************************************************************************
Method Name    : createGroup
Author         : Alina Balan
Description    : This method is used for creating a group object
Return Type    : Group
Parameter      : 
*********************************************************************************/
    public static Group createGroup() {
        Group oTestGroup = new Group(Name='test group', Type='Queue', DeveloperName='TestGroup');
        return oTestGroup;
    }
    
    /*********************************************************************************
Method Name    : createQueue
Author         : Alina Balan
Description    : This method is used for creating a queue object
Return Type    : QueuesObject
Parameter      : Group oTestGroup
*********************************************************************************/
    public static QueuesObject createQueue(Group oTestGroup) {
        QueuesObject testQueue = new QueueSObject(QueueID = oTestGroup.Id, SobjectType = PC_Constants.DOCUMENT_OBJECT);
        return testQueue;
    }

    /*********************************************************************************
    Method Name    : createQueue
    Author         : Tejas Patel
    Description    : This method is used for creating a queue object
    Return Type    : QueuesObject
    Parameter      : Group oTestGroup, String SobjectTypeName
*********************************************************************************/
    public static QueuesObject createQueue(Group oTestGroup, String SobjectTypeName) {
        QueuesObject testQueue = new QueueSObject(QueueID = oTestGroup.Id, SobjectType = SobjectTypeName);
        return testQueue;
    }

    /*********************************************************************************
Method Name    : createCase
Author         : Alina Balan
Description    : This method is used for creating a case(program) object
Return Type    : Case
Parameter      : User oUser, Account oPatient
*********************************************************************************/
    public static Case createCase(User oUser, Account oPatient){
        return new Case(Status = 'New', ownerId= oUser.Id, Account = oPatient, AccountId = oPatient.Id, RecordTypeId = PC_SYSTEM.getDefaultProgramCaseRecordTypeId());
    }

    /*********************************************************************************
Method Name    : createPatient
Author         : Alina Balan
Description    : This method is used for creating an account(patient) object
Return Type    : Account
Parameter      : 
*********************************************************************************/
    public static Account createPatient(String sName) {
        Account oAccount = new Account();
        oAccount.Name = sName;
        oAccount.PC_First_Name__c = sName;
        oAccount.PC_Last_Name__c = sName;
        oAccount.RecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
        return oAccount;
    }

    /*********************************************************************************
Method Name    : createAccount
Author         : Hitha Avalakki
Description    : This method is used for creating an account if any record type
Return Type    : Account
Parameter      :
*********************************************************************************/
    public static Account createAccount(String sName,Id recordTypeId) {
        Account oAccount = new Account();
        oAccount.Name = sName;
        oAccount.PC_First_Name__c = sName;
        oAccount.PC_Last_Name__c = sName;
        oAccount.RecordTypeId = recordTypeId;
        return oAccount;
    }


/*********************************************************************************
Method Name    : createAccountIndetifier
Author         : Shishir Bansal
Description    : This method is used for creating an account identifier
Return Type    : Account Identifer
Parameter      :
*********************************************************************************/
    public static PC_Account_Identifier__c createAccountIdentifier(Id accountId, String type, String assigner) {
        PC_Account_Identifier__c accIdentifier = new PC_Account_Identifier__c();
        accIdentifier.PC_Account__c = accountId;
        accIdentifier.PC_Type__c = type;
        accIdentifier.PC_Value__c = '19';
        accIdentifier.PC_Assigner__c = assigner;
        return accIdentifier;
    }

    /*********************************************************************************
Method Name    : createEWPPatient
Author         : Tejas Patel
Description    : This method is used for creating an account(patient) object for EWP Page
Return Type    : Account
Parameter      :
*********************************************************************************/
    public static Account createEWPPatient(String sName, String sDOB, String sSalutation, String sRecordType) {
        Account oAccount 				= new Account();
        oAccount.PC_Salutation__c 		= sSalutation;
        oAccount.Name 					= sName;
        oAccount.PC_First_Name__c 		= sName;
        oAccount.PC_Last_Name__c 		= sName;
        oAccount.PC_Date_of_Birth__c	= Date.valueof(String.valueof(sDOB));
        oAccount.RecordTypeId = PC_SYSTEM.recordTypeId('Account', sRecordType);
        return oAccount;
    }

    /*********************************************************************************
Method Name    : createSupportModel
Author         : Vasile Paraschiv
Description    : This method is used for creating a support model object
Return Type    : PC_Support_Model__c
Parameter      : String
*********************************************************************************/ 
    public static PC_Support_Model__c createSupportModel(User owner, String name) {
        PC_Support_Model__c sm = new PC_Support_Model__c(Name = name);
        return sm;
    }
    
    /*********************************************************************************
Method Name    : createEngagementProgram
Author         : Ajinkya Deshmukh
Description    : This method is used for creating a support model object
Return Type    : PC_Engagement_Program__c
Parameter      :
*********************************************************************************/
    public static PC_Engagement_Program__c createEngagementProgram(String programName, Id manufacturerAccId) {
        PC_Engagement_Program__c ep = new PC_Engagement_Program__c (Name = programName, PC_Manufacturer__c = manufacturerAccId, PC_Program_Code__c = programName);
        return ep;
    }

    /*********************************************************************************
Method Name    : createTemplateActivity
Author         : Vasile Paraschiv
Description    : This method is used for creating a support model object
Return Type    : PC_Support_Model__c
Parameter      : String
*********************************************************************************/
    public static Task createTemplateActivity(User owner, String subject, PC_Support_Model__c supportModel) {
        Task newTask = new Task(OwnerId= owner.Id, Subject = subject, WhatId = supportModel.Id);
        return newTask;
    }
    
    /*********************************************************************************
Method Name    : create Candidate Patient record
Author         : Tetiana danylyshyn
Description    : This method is used for creating a Candidate Patient record
Return Type    : PC_Applicant__c
Parameter      : String parent Id, String accountId, String recordy type
*********************************************************************************/
    public static PC_Applicant__c createApplicant(String lastName) {
        PC_Applicant__c newApplicant = new PC_Applicant__c( PC_Last_Name__c = lastName, 
                                                           PC_First_Name__c = 'Test First Name',
                                                           PC_Source__c = true);
        return newApplicant;
    }
    
    /*********************************************************************************
Method Name    : createApplicant
Author         : Tejas Patel
Description    : This method is used for creating a Candidate Patient record and assiging a engagement prgram
Return Type    : PC_Applicant__c
Parameter      : String parent Id, String accountId, String recordy type
*********************************************************************************/
    public static PC_Applicant__c createApplicant(String lastName, Id enrollmentId) {
        Id appRecordType = PC_SYSTEM.recordTypeId(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),'PC_Internal');
        PC_Applicant__c newApplicant = new PC_Applicant__c( PC_Last_Name__c = lastName,
                                                           PC_First_Name__c = 'Test First Name',
                                                           PC_Enrollment_Case__c = enrollmentId,
                                                           RecordTypeId = appRecordType,
                                                           PC_Source__c = true,
                                                           PC_HP_Payer_Name__c = '',
                                                           PC_Physician_Name__c = lastName + 'Test First Name');
        //Retrieve the engagement program for the enrollment case and assign it to applicant
        case enrollCase = [Select PC_Engagement_Program__c from Case WHERE Id=:enrollmentId
                           LIMIT 1];
        newApplicant.PC_Engagement_Program__c =enrollCase.PC_Engagement_Program__c;

        return newApplicant;
    }

    /*********************************************************************************
Method Name    : createEnrollment
Author         : Tejas Patel
Description    : This method is used for creating a Candidate Patient record and assiging a engagement prgram
Return Type    : PC_Applicant__c
Parameter      : String parent Id, String accountId, String recordy type
*********************************************************************************/
    public static Case createEnrollment(Id engagementId) {
        Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, 'PC_Enrollment');
        Case newEnrollment = new Case( PC_Engagement_Program__c = engagementId,
                                      RecordTypeId = caseRecordType,
                                      Status = 'Open',
                                      Origin = 'Email');
        return newEnrollment;
    }

    /*********************************************************************************
Method Name    : newAdverseEvent
Author         : Tetiana Danylyshyn
Description    : This method is used for creating a test PC_AdverseEvent__c object
Return Type    : PC_AdverseEvent__c 
Parameter      : String accountId
*********************************************************************************/
    public static PC_AdverseEvent__c newAdverseEvent(Id accountId) {
        PC_AdverseEvent__c ae = new PC_AdverseEvent__c(PC_Patient__c = accountId);
        return ae;
    }


    /*********************************************************************************
Method Name    : newAdverseEvent
Author         : Tetiana Danylyshyn
Description    : This method is used for creating a test PC_AdverseEvent__c object
Return Type    : PC_AdverseEvent__c
Parameter      : String accountId
*********************************************************************************/
    public static PC_AdverseEvent2__c newAdverseEvent2(Id accountId) {
        PC_AdverseEvent2__c ae = new PC_AdverseEvent2__c(PC_Patient__c = accountId);
        return ae;
    }

    /*********************************************************************************
Method Name    : newInteraction
Author         : Tetiana Danylyshyn
Description    : This method is used for creating a test PC_Interaction__c object
Return Type    : PC_Interaction__c 
Parameter      : String caseId
*********************************************************************************/
    public static PC_Interaction__c newInteraction(Id caseId) {
        PC_Interaction__c i = new PC_Interaction__c(PC_Patient_Program__c = caseId);
        return i;
    }
    
    /*********************************************************************************
Method Name    : createAddress
Author         : Alina BAlan
Description    : This method is used for creating a test PC_Address__c object
Return Type    : PC_Address__c 
Parameter      : String accId
*********************************************************************************/
    public static PC_Address__c createAddress(Id accId) {
        PC_Address__c address = new PC_Address__c();
        address.PC_Account__c = accId;
        address.PC_Address_1__c = 'test address line 1';
        address.PC_Address_2__c = 'test address line 2';
        address.PC_City__c = 'test City';
        //address.PC_State__c = 'test State';
        address.PC_Zip_Code__c = '123321';
        //@@RemoveAddressPhone: address.PC_Phone__c = '0727555957';
        address.PC_Primary_Address__c = true;
        return address;
    }
    
    /*********************************************************************************
Method Name    : createMeasurement
Author         : Alina Balan
Description    : This method is used for creating a test PC_Measurement__c object
Return Type    : PC_Measurement__c 
Parameter      : patientId
*********************************************************************************/
    public static PC_Measurement__c createMeasurement(Id patientId, Id programId, Decimal measurement) {
        PC_Measurement__c oMeasurement = new PC_Measurement__c();
        //oMeasurement.PC_Patient__c = patientId;
        oMeasurement.PC_Program__c = programId;
        oMeasurement.PC_Measurement__c = measurement;
        oMeasurement.PC_Type__c = MEASUREMENT_TYPE;
        return oMeasurement;
    }
    
    /*********************************************************************************
Method Name    : createDocumentLog
Author         : Alina Balan
Description    : This method is used for creating a test PC_Document_Log__c object
Return Type    : PC_Document_Log__c
Parameter      : Id documentId, Id associationRecordId, String associationType, String associationName
*********************************************************************************/
    public static PC_Document_Log__c createDocumentLog(Id documentId, Id programCoverage, String associationType, String associationName) {
        PC_Document_Log__c docObj = new PC_Document_Log__c();
        docObj.PC_Document__c = documentId;
        //docObj.PC_Association_Record_ID__c = associationRecordId;
        docObj.PC_Coverage__c = programCoverage;
        docObj.PC_Association_Type__c = associationType;
        docObj.PC_Association_Record_Name__c = associationName;
        return docObj;            
    }
    
    
    /*********************************************************************************
Method Name    : createProgramCoverage
Author         : Alina Balan
Description    : This method is used for creating a test PC_Document_Log__c object
Return Type    : PC_Document_Log__c
Parameter      : Id programId
*********************************************************************************/
    public static PC_Program_Coverage__c createProgramCoverage(Id programId) {
        PC_Program_Coverage__c programCoverage = new PC_Program_Coverage__c();
        programCoverage.PC_Program__c = programId;
        return programCoverage;            
    }
    
    /*********************************************************************************
Method Name    : create Multiple Patient Accounts
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<Account> 
Parameter      : String account name, No of records, Record Type Name
*********************************************************************************/
    public static List<Account> createAccounts(String pRootName, Integer pNoRecs, String recordType){
        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, recordType);
        List<Account> newAccounts = new List<Account>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            Account Account = new Account();
            account.Name = 'Account Name '+i;
            account.PC_First_Name__c = pRootName +' ' + 'First Name '+i;
            account.PC_Last_Name__c = pRootName +' ' + 'Last Name '+i;
            account.Fax  = '56777'+ i;
            account.AnnualRevenue = 45600;
            account.recordTypeId = accountRecordTypeId;
            newAccounts.add(account);
        }
        return newAccounts;
    }
    
    /*********************************************************************************
Method Name    : create Multiple Health Plans
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<Account> 
Parameter      : String account name, No of records, Record Type Name
*********************************************************************************/
    public static List<PC_Health_Plan__c> createHealthPlans(List<Account> patientAccounts, Integer noRecords){
        
        List<PC_Health_Plan__c> newHealthPlans = new List<PC_Health_Plan__c>(); 
        for(integer i = 0; i < noRecords; i ++){
            PC_Health_Plan__c eachHealthPlan = new PC_Health_Plan__c();
            eachHealthPlan.Patient__c = patientAccounts[0].Id;
            eachHealthPlan.PC_Cardholder_Relationship_to_Patient__c =  PC_Constants.SELF;
            eachHealthPlan.PC_Expiration_Date__c = System.now().date().addYears(1);
            eachHealthPlan.PC_Effective_Date__c = System.now().date().addYears(-1);
            eachHealthPlan.PC_Plan_Status__c = PC_Constants.ACTIVE;
            newHealthPlans.add(eachHealthPlan);
        }
        return newHealthPlans;
    }
    
    /*********************************************************************************
Method Name    : create Multiple Patient Addresses
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<PC_Address__c>
Parameter      : List <Account> , No of records
*********************************************************************************/
    public static List<PC_Address__c> createAddresses(List<Account> accounts, Integer noRecords, boolean isPrimaryAddress){
        
        List<PC_Address__c> newAddresses = new List<PC_Address__c>(); 
        for(integer i = 0; i < noRecords; i ++){
            PC_Address__c address = new PC_Address__c();
            address.PC_Account__c = accounts[i].Id;
            address.PC_Address_1__c = 'test address line 1';
            address.PC_Address_2__c = 'test address line 2';
            address.PC_City__c = 'test City';
            //address.PC_State__c = 'test State';
            address.PC_Zip_Code__c = '123321';
            address.PC_Primary_Address__c = isPrimaryAddress;
            newAddresses.add(address);
        }
        return newAddresses;
    }

    /*********************************************************************************
Method Name    : create Multiple Patient Addresses
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<PC_Address__c>
Parameter      : List <Account> , No of records
*********************************************************************************/
    public static PC_Association__c createAssociations(Id programCaseId, Id physicianAccId, Id ccOrRiUserId, String associationRole){
        return new PC_Association__c(
            PC_Program__c = programCaseId,
            PC_Role__c = associationRole,
            PC_Account__c = physicianAccId == null ? null : physicianAccId,
            PC_Associated_User__c = ccOrRiUserId == null ? null : ccOrRiUserId
        );
    }
    
    /*********************************************************************************
Method Name    : create Multiple Patient Addresses
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<PC_Address__c>
Parameter      : List <Account> , No of records
*********************************************************************************/
    public static PC_Association__c createAssociation(Account account, Case caseObj, String roleName, Date endDate, User objUser) {
        PC_Association__c association = new PC_Association__c (PC_Program__c = caseObj.Id, PC_Role__c = roleName, PC_EndDate__c = endDate, PC_AssociationStatus__c=PC_Constants.ACTIVE);
        if (account != null) {
            association.PC_Account__c = account.Id;
        }
        if (objUser != null) {
            association.PC_Associated_User__c = objUser.Id;
        }
        return (PC_Association__c)PC_Database.ins(association, false);
    }
    
    /*********************************************************************************
Method Name    : create Messages for SMS
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : PC_Message__c 
Parameter      : Case
*********************************************************************************/
    public static PC_Message__c createMessage(Case programCase) {
        PC_Message__c message = new PC_Message__c();
        message.Name = 'test message';
        message.PC_Case__c = programCase.Id;
        message.PC_Message_Date__c = datetime.now();
        message.PC_Content__c = 'This is a Test Class';
        return message;
    }
    
    /*********************************************************************************
Method Name    : create Multiple Cases
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<Case>
Parameter      : List <Account> , No of records, String recordType
*********************************************************************************/
    public static List<Case> createCases(List<Account> patientAccounts, Integer noRecords, String recordType) {
        if(recordType.equals(PC_Constants.CASE_PROGRAM_RECORD_TYPE)){
           throw new TestProgramException('Please use PC_Test_Setup.createProgramCases(List<Account> patientAccounts, Integer noRecords) method to create program cases for testing');
        }
        Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, recordType);
        List<Case> newCases = new List<Case>();
        for(integer i = 0; i < noRecords; i ++){
            Case eachCase = new Case();
            eachCase.AccountId = patientAccounts[i].Id;
            eachCase.RecordTypeId = caseRecordType;
            eachCase.Status= 'New';
            newCases.add(eachCase);
        }
        return newCases;
    }

    /*********************************************************************************
Method Name    : create Enrollment Cases
Author         : Shabda Bhujad
Description    : This method is used for creating case for applicant object
*********************************************************************************/
    public static List<Case> createEnrlCase(Id applicantId, Integer noRecords, String recordType) {
        Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, recordType);
        List<Case> newCases = new List<Case>();
        for(integer i = 0; i < noRecords; i ++){
            Case enrlCase = new Case();
            enrlCase.PC_ActiveApplicant__c = applicantId;
            enrlCase.RecordTypeId = caseRecordType;
            newCases.add(enrlCase);
        }
        return newCases;
    }


    /*********************************************************************************
Method Name    : create Enrollment Cases
Author         : Shabda Bhujad
Description    : This method is used for create Enrollment case for Account under engagement program
*********************************************************************************/
    public static List<Case> createEnrlCase(Id accountId, Integer noRecords, String recordType, String EngagementProgramId) {
        Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, recordType);
        List<Case> newCases = new List<Case>();
        for(integer i = 0; i < noRecords; i ++){
            Case enrlCase = new Case();
            enrlCase.AccountId = accountId;
            enrlCase.RecordTypeId = caseRecordType;
            enrlCase.PC_Engagement_Program__c = EngagementProgramId;
            newCases.add(enrlCase);
        }
        return newCases;
    }

    /*********************************************************************************
    Method Name    : create Multiple Reminder Queues
    Author         : Kishore Kanteti
    Description    : This method is used for creating multiple reminder queues records
    Return Type    : List<PC_ReminderQueue__c>
    Parameter      : Setting Name , No of records
    *********************************************************************************/
    public static List<PC_ReminderQueue__c> createReminderQueues(String referenceRecordId,String settingName, Integer noOfRecords) {
        List<PC_ReminderQueue__c> allReminderQueues = new List<PC_ReminderQueue__c>();
        for(integer i = 0; i < noOfRecords; i ++){
            PC_ReminderQueue__c eachQueue = new PC_ReminderQueue__c();
            eachQueue.PC_RecordID__c = referenceRecordId;
            eachQueue.PC_ParentReferenceRecordID__c = referenceRecordId;
            eachQueue.PC_Active__c = true;
            eachQueue.PC_DueDate__c = Date.today().addDays(1);
            eachQueue.PC_ReminderSetting__c = settingName;
            eachQueue.PC_Recipient__c = 'usertest@gmail.com';
            eachQueue.PC_ReminderChannel__c = 'Email';
            eachQueue.PC_RemindersToBeSent__c = 10;
            allReminderQueues.add(eachQueue);
        }
        return allReminderQueues;
    }
    /*********************************************************************************
    Method Name    : createReminderLog
    Author         : Kishore Kanteti
    Description    : This method is used for creating reminder log records
    Return Type    : List<PC_ReminderLog__c>
    Parameter      : Setting Name , No of records
    *********************************************************************************/
    public static PC_ReminderLog__c createReminderLog(String queueId) {
        PC_ReminderLog__c reminderLog = new PC_ReminderLog__c();
        reminderLog.PC_ReminderQueue__c = queueId;
        reminderLog.PC_ReminderContent__c = 'This is a test class.';
        reminderLog.PC_Status__c = 'Unprocessed';
        return reminderLog;
    }

    /*********************************************************************************
Method Name    : create Multiple Tasks
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : List<Case> 
Parameter      : List <Case> , No of records
*********************************************************************************/
    public static List<Task> createTasks(Case patientCase, Integer noRecords) {
        List<Task> allTasks = new List<Task>(); 
        for(integer i = 0; i < noRecords; i ++){
            Task eachTask = new Task();
            eachTask.WhatId = patientCase.Id;
            eachTask.Subject = 'Test Child Task';
            eachTask.PC_Channel__c = 'Call';
            eachTask.Status = 'Not Started';
            allTasks.add(eachTask);
        }
        return allTasks;
    }

    /*********************************************************************************
Method Name    : createTasks
Author         : Kishore Kanteti
Description    : This method is used for creating multiple task object records
Return Type    : List<Task>
Parameter      : whatId , No of records
*********************************************************************************/
    public static List<Task> createTasks(Id whatId, Integer noRecords) {
        List<Task> allTasks = new List<Task>();
        for(integer i = 0; i < noRecords; i ++) {
            Task eachTask = new Task();
            if (whatId != null) {
                eachTask.WhatId = whatId;
            }
            eachTask.Subject = 'Test Child Task';
            eachTask.PC_Channel__c = 'Call';
            eachTask.Status = 'Not Started';
            allTasks.add(eachTask);
        }
        return allTasks;
    }

/*********************************************************************************
Method Name    : createEvents
Author         : Kishore Kanteti
Description    : This method is used for creating multiple event object records
Return Type    : List<Event>
Parameter      : whatId , No of records
*********************************************************************************/
    public static List<Event> createEvents(Integer numberOfEvents, Id whatId, Id whoId) {
        List<Event> lstEvents = new List<Event>();
        for(Integer i=0; i<numberOfEvents; i++){
            Event newEvent = new Event(
                    Subject = 'Test Event ' + i,
                    EventSubType = 'Event',
                    StartDateTime = System.now(),
                    EndDateTime = System.now().addHours(1),
                    ActivityDate = Date.today(),
                    Description = 'Test Description ' + i
            );
            if(whatId != null){
                newEvent.WhatId = whatId;
            }
            if(whoId != null){
                newEvent.WhoId = whoId;
            }

            lstEvents.add(newEvent);
        }
        return lstEvents;
    }

/*********************************************************************************
Method Name    : createEmailMessages
Author         : Kishore Kanteti
Description    : This method is used for creating multiple email message object records
Return Type    : List<EmailMessage>
Parameter      : whatId , No of records
*********************************************************************************/
    public static List<EmailMessage> createEmailMessages(Integer numberOfEmails, Id whatId) {
        List<EmailMessage> lstEmails = new List<EmailMessage>();
        for(Integer i=0; i <numberOfEmails; i++){
            EmailMessage newEmail = new EmailMessage(
                    RelatedToId = whatId,
                    MessageDate = Date.today(),
                    Subject = 'Test Email ' + i,
                    TextBody = 'Test Description ' + i,
                    FromName = 'Test Name',
                    FromAddress = 'test123abc@test.com',
                    ToAddress = 'test432@test.com'
            );

            lstEmails.add(newEmail);
        }
        return lstEmails;
    }
/*********************************************************************************
Method Name    : createEmailMessageRelations
Author         : Kishore Kanteti
Description    : This method is used for creating multiple email message object records
Return Type    : List<EmailMessageRelation>
Parameter      : whoId , No of records
*********************************************************************************/
    public static List<EmailMessageRelation> createEmailMessageRelations(List<EmailMessage> emailMessages, Id whoId, String relationType) {
        List<EmailMessageRelation> lstRelations = new List<EmailMessageRelation>();
        for(EmailMessage emailObj : emailMessages) {
            EmailMessageRelation relationObj = new EmailMessageRelation(
                    EmailMessageId = emailObj.Id,
                    RelationType = relationType,
                    RelationId = whoId,
                    RelationAddress = emailObj.FromAddress
            );
            lstRelations.add(relationObj);
        }
        return lstRelations;
    }
    /*********************************************************************************
Method Name    : create Health Plan
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : PC_Health_Plan__c 
Parameter      : Account Id
*********************************************************************************/
    public static PC_Health_Plan__c createTestHealthPlan(Id patientId) {
        PC_Health_Plan__c hp = new PC_Health_Plan__c(Patient__c = patientId);
        return hp;
    }
    
    /*********************************************************************************
Method Name    : create Program Coverage
Author         : Ajinkya
Description    : This method is used for creating multiple accounts object
Return Type    : PC_Program_Coverage__c 
Parameter      : Case Id, PC_Health_Plan__c Id
*********************************************************************************/
    public static PC_Program_Coverage__c createTestProgramCoverage(Id programId, Id healthPlanId) {
        PC_Program_Coverage__c pc = new PC_Program_Coverage__c (PC_Program__c = programId, 
                                                                PC_Health_Plan__c = healthPlanId);
        return pc;
    }
    
    /*********************************************************************************
    Method Name    : create Program
    Author         : Ajinkya
    Description    : This method is used for creating multiple accounts object
    Return Type    : Case
    Parameter      : Account
    *********************************************************************************/
    public static Case createProgram(Account account) {
        Id programRecordTypeId = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
        Case caseObj = new Case(AccountId = account.Id, recordTypeId = programRecordTypeId);
        return (Case)PC_Database.ins(caseObj, false);
    }
    
    /*********************************************************************************
Method Name    : getFieldFullName
Author         : Ajinkya
Description    : This method is used for returning for object+field api name
Return Type    : String
Parameter      :
*********************************************************************************/
    public static String getFieldFullName(String objectName, String fieldName){
        return checkForCustomApi(objectName) + '.' + checkForCustomApi(fieldName);
    }
    
    /*********************************************************************************
Method Name    : checkForCustomApi
Author         : Ajinkya
Description    : This method returns api name of field
Return Type    : String
Parameter      :
*********************************************************************************/
    public static String checkForCustomApi(String apiName){
        if(apiName.endsWithIgnoreCase('__c'))
            return PC_Constants.getQualifiedAPIName(apiName);
        else
            return apiName;
    }
    
    /*********************************************************************************
Method Name    : createObjectPermissions
Author         : Ajinkya
Description    : This method returns api name of field
Return Type    : ObjectPermissions
Parameter      :
*********************************************************************************/
    public static ObjectPermissions createObjectPermissions(string objectName, Id permissionSetId, boolean oCreate, 
                                                            boolean oRead, boolean oUpdate, boolean oDelete){
                                                                ObjectPermissions myObjectPermission = new ObjectPermissions(SobjectType = checkForCustomApi(objectName),
                                                                                                                             ParentId = permissionSetId,
                                                                                                                             PermissionsCreate = oCreate,
                                                                                                                             PermissionsRead = oRead,
                                                                                                                             PermissionsEdit = oUpdate,
                                                                                                                             PermissionsDelete = oDelete                                                                     
                                                                                                                            );
                                                                return (ObjectPermissions)PC_Database.ins(myObjectPermission, false);
                                                            }
    
    /*********************************************************************************
Method Name    : createPermissionSet
Author         : Ajinkya
Description    : This method creates permissin set
Return Type    : PermissionSet
Parameter      : null
*********************************************************************************/
    public static PermissionSet createPermissionSet(){
        PermissionSet eachPermissionSet = new PermissionSet(Name='CRUDFLSPERMISSION', Label='CRUDFLSPERMISSION');
        return (PermissionSet)PC_Database.ins(eachPermissionSet, false);
    }

    /*********************************************************************************
Method Name    : createFieldPermissions
Author         : Ajinkya
Description    : This method creates field permission
Return Type    : FieldPermissions
Parameter      : null
*********************************************************************************/
    public static FieldPermissions createFieldPermissions(string objectName, string fieldName, Id permissionSetId, 
                                                          boolean oRead, boolean oUpdate) {
                                                              FieldPermissions myFieldPermissionSet = new FieldPermissions(SobjectType = checkForCustomApi(objectName),
                                                                                                                           Field = getFieldFullName(objectName, fieldName),
                                                                                                                           ParentId = permissionSetId,
                                                                                                                           PermissionsRead = oRead,
                                                                                                                           PermissionsEdit = oUpdate
                                                                                                                          ); //set field permissions
                                                              return (FieldPermissions)PC_Database.ins(myFieldPermissionSet, false);
                                                          }
    
    /*********************************************************************************
Method Name    : createSampleAccounts
Author         : Ajinkya
Description    : This method creates accounts for checking fls assert messages
Return Type    : List<Account>
Parameter      : null
*********************************************************************************/
    public static List<Account> createSampleAccounts(String pRootName, Integer pNoRecs, String recordType){
        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, recordType);
        List<Account> newAccounts = new List<Account>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            Account Account = new Account();
            account.Name = 'Account Name '+i;
            account.Fax  = '56777'+ i;
            account.recordTypeId = accountRecordTypeId;
            newAccounts.add(account);
        }
        return newAccounts;
    }

    /*********************************************************************************
Method Name    : createSampleAccounts
Author         : Ajinkya
Description    : This method creates accounts for checking fls assert messages
Return Type    : List<Account>
Parameter      : null
*********************************************************************************/
    public static Account createSampleAccount(String pRootName, String recordType){
        Id accountRecordTypeId = PC_System.recordTypeId(ACCOUNT_OBJ, recordType);
        Account newAccount = new Account();
        newAccount.Name = 'Account Name '+pRootName;
        newAccount.Fax  = '56777';
        newAccount.recordTypeId = accountRecordTypeId;
        return newAccount;
    }

    /*********************************************************************************
Method Name    : createCaseTeamRole
Author         : Ajinkya
Description    : This method creates accounts for checking fls assert messages
Return Type    : List<CaseTeamRole>
Parameter      : Integer , List<String>
*********************************************************************************/
    public static List<CaseTeamRole> createCaseTeamRole(Integer pNoRecs, List<String>roles) {
        List <CaseTeamRole> caseTeamRoles = new List<CaseTeamRole>();
        for(integer i = 0; i < pNoRecs; i ++){
            CaseTeamRole cTeamRole = new CaseTeamRole();
            cTeamRole.Name = roles[i];
            cTeamRole.AccessLevel = 'Read';
            cTeamRole.PreferencesVisibleInCSP = false;
            caseTeamRoles.add(cTeamRole);
        }
        return caseTeamRoles;
    }

    /*********************************************************************************
Method Name    : createServices
Author         : Tejas Patel
Description    : This method creates PC_Service__c records
Return Type    : List<PC_Service__c>
Parameter      : Service Name and Number of Records
*********************************************************************************/
    public static List<PC_Service__c> createServices(String serviceName, Integer pNoRecs){
        List<PC_Service__c> newServices = new List<PC_Service__c>();
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Service__c services = new PC_Service__c();
            services.Name = serviceName +'_'+i;
            services.PC_Default_Expiration_Days__c  = i;
            newServices.add(services);
        }
        return newServices;
    }

    /*********************************************************************************
Method Name    : createProgramServicePermissions
Author         : Tejas Patel
Description    : This method creates PC_Program_Service_Permission__c records
Return Type    : List<PC_Program_Service_Permission__c>
Parameter      : Service Name and Number of Records
*********************************************************************************/
    public static List<PC_Program_Service_Permission__c> createProgramServicePermissions(List<PC_Service__c> services, Integer pNoRecs){
        List<PC_Program_Service_Permission__c> newProgramServicePermissions = new List<PC_Program_Service_Permission__c>();
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Program_Service_Permission__c programServicePermission = new PC_Program_Service_Permission__c();
            programServicePermission.PC_Start_Date__c  = Datetime.now().dateGMT();
            programServicePermission.PC_Service__c	   = services[i].Id;
            newProgramServicePermissions.add(programServicePermission);
        }
        return newProgramServicePermissions;
    }
    
    //[PC-1730]
    /*********************************************************************************
Method Name    : Create multiple Pharmacy Referral records
Author         : Prachi Nandgaonkar
Description    : This method is used for creating multiple Pharmacy Referral records
Return Type    : List<PC_Pharmacy__Referral__c>
Parameter      : List <Case> , No of records
*********************************************************************************/
    public static List<PC_Pharmacy_Referral__c> createReferrals(List<Case> programCase, Integer noRecords) {
        List<PC_Pharmacy_Referral__c> newReferrals = new List<PC_Pharmacy_Referral__c>(); 
        for(integer i = 0; i < noRecords; i ++){
            PC_Pharmacy_Referral__c eachRef = new PC_Pharmacy_Referral__c();
            eachRef.PC_Program__c = programCase[i].Id;
            eachRef.PC_Referral_Status__c = 'Started';
            newReferrals.add(eachRef);
        }
        return newReferrals;
    }

    /*********************************************************************************
Method Name    : create Product
Author         : Tejas Patel
Description    : This method is used for creating an product object
Return Type    : Product2
Parameter      : String pName, String pCode, Id Manufacturer
*********************************************************************************/

    public static Product2 newProduct(String pName, String pCode, Id Manufacturer){
        return new Product2 (Name = pName,
                             IsActive = true,
                             ProductCode = pCode,
                             PC_Manufacturer__c = Manufacturer
                            );
    }

/*********************************************************************************
Method Name    : create prescription
Author         :Shishir Bansal
Description    : This method is used for creating prescription object
Return Type    : Prescription
Parameter      : Product2 id  is passed as a parameter
*********************************************************************************/
    public static PC_Prescription__c newPrescription(Id Product2){
        return new PC_Prescription__c(

                PC_Frequency__c = '123',
                PC_Days_Supply__c = 22,
                PC_Requested_Quantity__c = 20,
                PC_Rx_Refills__c =11,
                PC_Product__c = Product2,
                PC_hasActivePA__c = false

        );
    }



    /*********************************************************************************
Method Name    : create suspect Prescriptions
Author         : Shishir Bansal
Description    : This method is used for creating List of Suspect Prescriptions
Return Type    : List<PC_Suspect_Prescription__c>
Parameter      : String adverse Event Id
*********************************************************************************/
    public static List<PC_Suspect_Prescription__c> createSuspectPrescriptions(Id adverseEvent, Integer recordsCount) {

        List<PC_Suspect_Prescription__c> suspectPrescriptions = new List<PC_Suspect_Prescription__c>();
        PC_Suspect_Prescription__c testSuspectPrescription;



        for(Integer i = 0 ; i<recordsCount; i++){
             testSuspectPrescription= new PC_Suspect_Prescription__c (

                    PC_Adverse_Event__c = adverseEvent,
                    PC_Concomitant_Medical_Products__c = 'Medicare-'+''+ i,
                    PC_Indication_for_Product_Use__c = 'A-rated-' + ''+i,
                    PC_Dose__c = String.valueOf(100* i)


            );

            suspectPrescriptions.add(testSuspectPrescription);

        }
        return suspectPrescriptions;
    }

    /*********************************************************************************
Method Name    : create suspect Prescriptions
Author         : Shishir Bansal
Description    : This method is used for creating List of Suspect Prescriptions
Return Type    : List<PC_Suspect_Prescription__c>
Parameter      : String adverse Event Id
*********************************************************************************/
    public static List<PC_Suspect_Prescription__c> createSuspectPrescriptions2(Id adverseEvent, Integer recordsCount) {

        List<PC_Suspect_Prescription__c> suspectPrescriptions = new List<PC_Suspect_Prescription__c>();
        PC_Suspect_Prescription__c testSuspectPrescription;



        for(Integer i = 0 ; i<recordsCount; i++){
             testSuspectPrescription= new PC_Suspect_Prescription__c (

                    PC_Adverse_Event2__c = adverseEvent,
                    PC_Concomitant_Medical_Products__c = 'Medicare-'+''+ i,
                    PC_Indication_for_Product_Use__c = 'A-rated-' + ''+i,
                    PC_Dose__c = String.valueOf(100* i)


            );

            suspectPrescriptions.add(testSuspectPrescription);

        }
        return suspectPrescriptions;
    }

    /*********************************************************************************
Method Name    : create Distribution Network
Author         : Tejas Patel
Description    : This method is used for creating an Distribution Network object
Return Type    : PC_Distributor__c
Parameter      : String dnName, Id Product, Id Pharmacy
*********************************************************************************/

    public static PC_Distributor__c newDistributionNetwork(Id Product, Id Pharmacy){
        return new PC_Distributor__c (
            PC_Pharmacy__c = Pharmacy,
            PC_Product__c = Product
        );
    }
    /*********************************************************************************
Method Name    : createAdverseEvents
Author         : Rohit Kapoor
Description    : This method is used for creating a test PC_AdverseEvent__c record
Return Type    : PC_AdverseEvent__c 
Parameter      : String accId
*********************************************************************************/
    public static PC_AdverseEvent__c createAdverseEvents(Id accId) {
        return new PC_AdverseEvent__c(
            PC_Patient__c = accId
        );
    }

    /*********************************************************************************
Method Name    : createDocWithStatusAndRecordType
Author         : Hitha Avalakki
Description    : This method is used for creating a test PC_Document__c record
Return Type    : PC_Document__c
Parameter      : String recordType,String status
*********************************************************************************/
    public static PC_Document__c createDocWithStatusAndRecordType(String recordType,String status) {
        PC_Document__c parentDoc=new PC_Document__c();
        parentDoc.RecordTypeId=PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, recordType);
        parentDoc.PC_Document_Status__c=status;

        return parentDoc;
    }

    /*********************************************************************************
Method Name    : createSupportPlan
Author         : Sahil Garg
Description    : This method is used for creating a support plan object
Return Type    : PC_SupportPlan__c

*********************************************************************************/
    public static PC_SupportPlan__c createSupportPlan() {

        PC_SupportPlan__c objSupPlan = new PC_SupportPlan__c();
        objSupPlan.Name	= SUPPORTPLAN_NAME;
        objSupPlan.PC_IsActive__c = false;
        return objSupPlan;
    }

    /*********************************************************************************
Method Name    : createSupportPlanActivity
Author         : Sahil Garg
Description    : This method is used for creating a support plan object
Return Type    : PC_SupportPlanActivity__c

*********************************************************************************/
    public static PC_SupportPlanActivity__c createSupportPlanActivity(String activityName) {

        PC_SupportPlanActivity__c objSupPlanActivity = new PC_SupportPlanActivity__c();
        objSupPlanActivity.Name=activityName;
		objSupPlanActivity.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        objSupPlanActivity.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK;
        objSupPlanActivity.PC_InternalActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK;
        objSupPlanActivity.PC_Subject__c='Test '+activityName;
        objSupPlanActivity.PC_Channel__c='Call';
        objSupPlanActivity.PC_Priority__c='Normal';
        objSupPlanActivity.PC_AutomationTaskJSON__c = '';
        objSupPlanActivity.PC_UserTask_Fields__c='{"requiredFieldSet":[{"value":"Normal","type":"PICKLIST","label":"Priority","isDeleteAllowed":"false","apiName":"Priority"},' +
                '{"value":"Call","type":"PICKLIST","label":"Channel","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Channel__c')+'"},' +
                '{"value":"Test ","type":"STRING","label":"Subject","isDeleteAllowed":"false","apiName":"Subject"},' +
                '{"value":"Care Coordinator","type":"PICKLIST","label":"Assign to Role","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c')+
                '"},{"value":"2020-04-23T08:30:00.000Z","type":"DATETIME","label":"Close Date","isDeleteAllowed":"true","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Close_Date__c')+'"}]}';
        
        return objSupPlanActivity;
    }
    /*********************************************************************************
    Method Name    : createSupportPlanActivityToCreateRecord
    Author         : Haritha Reddy
    Description    : This method is used for creating a Support Plan Activity of Type 'Create Record'
    Return Type    : PC_SupportPlanActivity__c

    *********************************************************************************/
    public static PC_SupportPlanActivity__c createSupportPlanActivityToCreateRecord(String activityName) {

        PC_SupportPlanActivity__c objSupPlanActivity = new PC_SupportPlanActivity__c();
        objSupPlanActivity.Name=activityName;
        objSupPlanActivity.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_CREATE_RECORD;
        objSupPlanActivity.PC_InternalActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK;
        objSupPlanActivity.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        objSupPlanActivity.PC_AutomationTaskJSON__c = '{"fieldMapping":[{"label":"Record Type Name","apiName":"RecordType","isDeleteAllowed":false,"type":"Picklist",'+
                '"value":"'+PC_Constants.getQualifiedAPIName('PC_Benefits_Investigation_Benefits_Verification')+'","isBoundValue":false},{"label":"Status","apiName":"Status","isDeleteAllowed":false,"type":"Picklist",'+
                '"value":"New","isBoundValue":false},{"label":"Case Origin","apiName":"Origin","isDeleteAllowed":false,"type":"Picklist","value":"Email","isBoundValue":false},'+
                '{"label":"Account ID","apiName":"AccountId","isDeleteAllowed":false,"type":"Reference","value":"AccountId","isBoundValue":true}],'+
                '"objectDetails":{"qualifiedApiName":"Case"},"outcomeTaskDetails":{"create":true}}';
        return objSupPlanActivity;
    }

    /*********************************************************************************
    Method Name    : createSupportPlanActivityToUpdateRecord
    Author         : Haritha Reddy
    Description    : This method is used for creating a Support Plan Activity of Type 'Update Record'
    Return Type    : PC_SupportPlanActivity__c
    *********************************************************************************/
    public static PC_SupportPlanActivity__c createUpdateRecordSupportPlanActivity(String activityName) {

        PC_SupportPlanActivity__c objSupPlanActivity = new PC_SupportPlanActivity__c();
        objSupPlanActivity.Name=activityName;
        objSupPlanActivity.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_UPDATE_RECORD;
        objSupPlanActivity.PC_InternalActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK;
        objSupPlanActivity.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        objSupPlanActivity.PC_AutomationTaskJSON__c = '{"type":"updateTriggerRecord","orderBy":[],"continueWhenNoUpdates":"TRUE",'+
                '"objectDetails":{"qualifiedApiName":"Case","relativeQualifiedApiPath":""},"LstConditionsPerObject":[],'+
                '"fieldMapping":[{"label":"Status","apiName":"Status","isDeleteAllowed":false,"type":"Picklist","value":"In Treatment","isBoundValue":false}],'+
                '"outcomeTaskDetails":{"create":true}}';
        return objSupPlanActivity;
    }
    /*********************************************************************************
    Method Name    : createPublishPlatformEventSPA
    Author         : Haritha Reddy
    Description    : This method is used for creating a Support Plan Activity of Type 'Publish Platform Event'
    Return Type    : PC_SupportPlanActivity__c
    *********************************************************************************/
    public static PC_SupportPlanActivity__c createPublishPlatformEventSPA(String activityName) {
        PC_SupportPlanActivity__c objSupPlanActivity = new PC_SupportPlanActivity__c();
        objSupPlanActivity.Name=activityName;
        objSupPlanActivity.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_PUBLISH_PLATFORM_EVENT;
        objSupPlanActivity.PC_InternalActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK;
        objSupPlanActivity.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        objSupPlanActivity.PC_AutomationTaskJSON__c = '{"fieldMapping":[{"label":"Error Date/Time","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Error_DateTime__c')+
                '","isDeleteAllowed":false,"type":"Datetime","value":"--PC_Now--","isBoundValue":false},{"label":"Running User","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Running_User__c')+
                '","isDeleteAllowed":false,"type":"String","value":"LastModifiedById","isBoundValue":true},{"label":"Error Message","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Error_Message__c')+
                '","isDeleteAllowed":false,"type":"Textarea","value":"Test Message","isBoundValue":false},{"label": "Additional Information","apiName": "'+PC_Constants.getQualifiedAPIName('PC_Additional_Information__c')+
                '","isDeleteAllowed":false,"type": "Textarea","value": "CreatedDate","isBoundValue": true}],"objectDetails":{"qualifiedApiName":"'+PC_Constants.getQualifiedAPIName('PC_Error_Log_Info__e')+
                '"},"outcomeTaskDetails":{"create":true}}';
        return objSupPlanActivity;
    }

    /*********************************************************************************
Method Name    : createSupportPlanGroup
Author         : Tejas Patel
Description    : This method is used for creating a support plan Group
Return Type    : PC_SupportPlanActivity__c

*********************************************************************************/
    public static PC_SupportPlanActivity__c createSupportPlanGroup(String activityName) {

        PC_SupportPlanActivity__c objSupPlanGroup = new PC_SupportPlanActivity__c();
        objSupPlanGroup.Name=activityName;
        objSupPlanGroup.PC_InternalActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE;
        objSupPlanGroup.PC_GroupActivityExecution__c =   PC_Constants.PC_IN_SEQUENCE;

        return objSupPlanGroup;
    }

    /*********************************************************************************
Method Name    : createSupportPlanGroupActivity
Author         : Tejas Patel
Description    : This method is used for creating a support plan Group Activity
Return Type    : PC_SupportPlanActivity__c

*********************************************************************************/
    public static PC_SupportPlanActivity__c createSupportPlanGroupActivity(String activityName) {

        PC_SupportPlanActivity__c objSupPlanGroupActivity = new PC_SupportPlanActivity__c();
        objSupPlanGroupActivity.Name=activityName;
        objSupPlanGroupActivity.PC_ConditionBehavior__c = PC_Constants.SUPPORTPLAN_CONDBEHAVIOR_STATUS_NONE;
        objSupPlanGroupActivity.PC_ActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK;
        objSupPlanGroupActivity.PC_InternalActivityType__c = PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE_TASK;
        objSupPlanGroupActivity.PC_Subject__c='Group Act '+activityName;
        objSupPlanGroupActivity.PC_Channel__c='Call';
        objSupPlanGroupActivity.PC_Priority__c='Normal';
        objSupPlanGroupActivity.PC_UserTask_Fields__c='{"requiredFieldSet":[{"value":"Normal","type":"PICKLIST","label":"Priority","isDeleteAllowed":"false","apiName":"Priority"},' +
                '{"value":"Call","type":"PICKLIST","label":"Channel","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Channel__c')+'"},' +
                '{"value":"Test ","type":"STRING","label":"Subject","isDeleteAllowed":"false","apiName":"Subject"},' +
                '{"value":"Care Coordinator","type":"PICKLIST","label":"Assign to Role","isDeleteAllowed":"false","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Assign_to_Role__c')+
                '"},{"value":"2020-04-23T08:30:00.000Z","type":"DATETIME","label":"Close Date","isDeleteAllowed":"true","apiName":"'+PC_Constants.getQualifiedAPIName('PC_Close_Date__c')+'"}]}';

        return objSupPlanGroupActivity;
    }


    public static PC_SupportPlanActivity__c createSupportPlanActivity(String actName, String actType, Id actSupID) {

        PC_SupportPlanActivity__c objSupPlanActivity = new PC_SupportPlanActivity__c();
        objSupPlanActivity.Name 				= actName;
        if(actType == 'Activity Sequence'){
            objSupPlanActivity.PC_InternalActivityType__c	= 'Sequence';
        }else {
            objSupPlanActivity.PC_ActivityType__c	= actType;
            objSupPlanActivity.PC_InternalActivityType__c	= actType;
        }
        objSupPlanActivity.PC_SupportPlan__c	= actSupID;
        return objSupPlanActivity;
    }

    public static PC_SupportPlanRuntime__c createSupPlanRuntime(PC_SupportPlan__c supPlan, Case caseOne) {

        PC_SupportPlanRuntime__c objSupPlanRuntime = new PC_SupportPlanRuntime__c();
        objSupPlanRuntime.Name='TestSupPlanRuntime';
        objSupPlanRuntime.PC_SupportPlan__c=supPlan.Id;
        objSupPlanRuntime.PC_SupportPlanCase__c=caseOne.Id;

        return objSupPlanRuntime;
    }

    public static PC_EngagementProgram_SupportPlan__c createEnggmtPgmSupPlan() {

        PC_EngagementProgram_SupportPlan__c objEnggmntSupPlan = new PC_EngagementProgram_SupportPlan__c();
        //objEnggmntSupPlan.Name='TestEnggmntPgmSupPlan';
        //objEnggmntSupPlan.PC_EngagementProgram__c=enggtPgm.Id;


        return objEnggmntSupPlan;
    }

    public static Contact createContact(Id accountId) {
        Contact contact=new Contact();
        contact.AccountId=accountId;
        contact.LastName='LNContact';
        return contact;
    }

    public static EmailTemplate createEmailTemplate(String templateName){
        EmailTemplate emailTemplate = new EmailTemplate();
        emailTemplate.developerName = templateName;
        emailTemplate.FolderId = UserInfo.getUserId();
        emailTemplate.TemplateType = 'Text';
        emailTemplate.Name = 'Email Template Name';
        emailTemplate.Body = 'This is an Email Body';
        emailTemplate.IsActive = TRUE;

        return emailTemplate;
    }

    public static PC_eLetter__c createEletter(){
        PC_eLetter__c eletter = new PC_eLetter__c();
        eletter.Name = 'Test 1';
        eletter.PC_Target_Recipients__c = 'HCO; Treating Physician';
        eletter.PC_Communication_Language__c = 'English';
        eletter.PC_Send_to_User__c = false;
        eletter.PC_Source_Object__c = 'Case';
        eletter.PC_Template_Name__c = 'Email_Template_Name';

        return eletter;
    }

    public static contentDocument createFile(String relatedRecordId){
        ContentVersion contentVer = new ContentVersion();
        contentVer.Title = 'SampleFile.pdf';
        contentVer.PathOnClient = 'SampleFile.pdf';
        contentVer.versiondata =  Blob.valueOf('Sample Data');
        PC_Database.ins(contentVer, false);

        ContentDocument contentDoc = new ContentDocument();
        if(contentVer != null) {
            String contentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVer.id].ContentDocumentId;
            contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Id =: contentDocumentId];
            if(string.isNotBlank(relatedRecordId)) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = relatedRecordId;
                cdl.ShareType = 'V';
                PC_Database.ins(cdl);
            }
        }
        return contentDoc;
    }
    /*********************************************************************************
Method Name    : createEngagementProgramEletter
Author         : Kanteti Kishore
Description    : This method is used for creating a Engagement Program eLetter object
Return Type    : PC_Engagement_Program_Eletter__c

*********************************************************************************/
    public static PC_Engagement_Program_Eletter__c createEngagementProgramEletter(Id engPrgId ,Id eLetterId,String emails) {

        PC_Engagement_Program_Eletter__c objEngagementProgramEletter = new PC_Engagement_Program_Eletter__c();
        objEngagementProgramEletter.PC_Engagement_Program__c = engPrgId;
        objEngagementProgramEletter.PC_eLetter__c = eLetterId;
        objEngagementProgramEletter.PC_PreConfiguredEmailRecipients__c = emails;
        return objEngagementProgramEletter;
    }

    /*********************************************************************************
    Method Name    : create Multiple Cases
    Author         : Ajinkya
    Description    : This method is used for creating multiple accounts object
    Return Type    : List<Case>
    Parameter      : List <Account> , No of records, String recordType
    *********************************************************************************/
    public static List<Case> createProgramCases(List<Account> patientAccounts, Integer noRecords) {
        Id caseRecordType = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
        List<Case> newCases = new List<Case>();
        for(integer i = 0; i < noRecords; i ++){
            Case eachCase = new Case();
            eachCase.AccountId = patientAccounts[i].Id;
            eachCase.RecordTypeId = caseRecordType;
            eachCase.Status= 'New';
            newCases.add(eachCase);
        }
        return newCases;
    }

    public class TestProgramException extends Exception {}

    /*********************************************************************************
    Method Name    : createUserTaskFieldsString
    Author         : Hitha Avalakki
    Description    : This method is used for creating user task field string for test classes for Support Plans
    Return Type    : Map<String,PC_AutomationTaskHelper.FieldMap> userTaskFieldsLabelMap
    Parameter      : String
    *********************************************************************************/
    public static String createUserTaskFieldsString(Map<String,PC_AutomationTaskHelper.FieldMap> userTaskFieldsLabelMap){

        String finalString='{"requiredFieldSet":[';
        List<String> userFieldApiNamesList = new List<String>(userTaskFieldsLabelMap.keySet());
        String fieldJSONString='';

        for(Integer i=0; i<userFieldApiNamesList.size();i++){

            fieldJSONString = '{';

            PC_AutomationTaskHelper.FieldMap fieldMap = userTaskFieldsLabelMap.get(userFieldApiNamesList[i]);

            if(fieldMap!=null){
                fieldJSONString = fieldJSONString +'"label"'+':'+'"'+ fieldMap.label+'"'+',';
                fieldJSONString = fieldJSONString +'"apiName"'+':'+'"'+ fieldMap.apiName+'"'+',';
                fieldJSONString = fieldJSONString +'"isDeleteAllowed"'+':'+ fieldMap.isDeleteAllowed+',';
                fieldJSONString = fieldJSONString +'"type"'+':'+'"'+ fieldMap.type+'"'+',';
                fieldJSONString = fieldJSONString +'"value"'+':'+'"'+ fieldMap.value+'"'+',';
                if(fieldMap.FormulaValue!=null && !String.isBlank(fieldMap.FormulaValue.referenceFieldApiName)){
                    String formulaValueAsString = '{';
                    formulaValueAsString = formulaValueAsString + '"referenceFieldApiName"' + ':' + '"' + fieldMap.FormulaValue.referenceFieldApiName + '"' + ',';
                    formulaValueAsString = formulaValueAsString + '"referenceFieldType"' + ':' + '"' + fieldMap.FormulaValue.referenceFieldType + '"' + ',';
                    formulaValueAsString = formulaValueAsString + '"operation"' + ':' + '"' + fieldMap.FormulaValue.operation + '"' + ',';
                    formulaValueAsString = formulaValueAsString + '"offsetType"' + ':' + '"' + fieldMap.FormulaValue.offsetType + '"' + ',';
                    formulaValueAsString = formulaValueAsString + '"offsetValue"' + ':' + '"' + fieldMap.FormulaValue.offsetValue + '"';
                    formulaValueAsString = formulaValueAsString + '}';

                    fieldJSONString = fieldJSONString + '"formulaValue"' + ':' + formulaValueAsString +',';
                }
                else{

                    fieldJSONString = fieldJSONString + '"formulaValue"' + ':' + '{}' + ',';
                }

                fieldJSONString = fieldJSONString +'"isBoundValue"'+':'+ fieldMap.isBoundValue;
            }

            fieldJSONString = fieldJSONString +'}';

            if(i!=userFieldApiNamesList.size()-1){
                fieldJSONString = fieldJSONString + ',';
            }

            finalString = finalString + fieldJSONString ;
        }

        finalString = finalString  + ']}';

        return finalString;
    }
    /*********************************************************************************
    Method Name    : createServiceRecordForPatientRole
    Author         : Hitha Avalakki
    Description    : This method is used for creating service records
    Return Type    : PC_Service__c
    Parameter      : None
    *********************************************************************************/
    public static PC_Service__c createServiceRecordForPatientRole() {
        PC_Service__c serviceRecord = new PC_Service__c();
        serviceRecord.PC_Patient_Permission_Required__c = true;
        return serviceRecord;
    }

    /*********************************************************************************
    Method Name    : createEngagementProgramServiceRecord
    Author         : Hitha Avalakki
    Description    : This method is used for creating engagement program service records
    Return Type    : PC_Engagement_Program_Service__c
    Parameter      : Id serviceRecordId,Id eletterId,Id engagementProgramId
    *********************************************************************************/
    public static PC_Engagement_Program_Service__c createEngagementProgramServiceRecord(Id serviceRecordId,Id eletterId,Id engagementProgramId) {
        PC_Engagement_Program_Service__c engagement_program_service = new PC_Engagement_Program_Service__c();
        engagement_program_service.PC_Service__c = serviceRecordId;
        engagement_program_service.PC_Start_Date__c = Date.today().addDays(-10);
        engagement_program_service.PC_End_Date__c = Date.today().addDays(20);
        engagement_program_service.PC_Notification_Template__c = eletterId;
        engagement_program_service.PC_Engagement_Program__c = engagementProgramId;

        return engagement_program_service;
    }

    /*********************************************************************************
    Method Name    : createProgramServicePermissionRecord
    Author         : Hitha Avalakki
    Description    : This method is used for creating program service permission records
    Return Type    : PC_Program_Service_Permission__c
    Parameter      : Id programCaseId,Id serviceRecordId,Boolean isPatientRole,Id associationRecordId
    *********************************************************************************/
    public static PC_Program_Service_Permission__c createProgramServicePermissionRecord(Id programCaseId,Id serviceRecordId,Boolean isPatientRole,Id associationRecordId) {
        PC_Program_Service_Permission__c programServicePermissionRecord =  new PC_Program_Service_Permission__c();
        programServicePermissionRecord.PC_ProgramCase__c = programCaseId;
        programServicePermissionRecord.PC_Start_Date__c = Date.today().addDays(-20);
        programServicePermissionRecord.PC_End_Date__c = Date.today().addDays(20);
        programServicePermissionRecord.PC_Service__c = serviceRecordId;
        if(isPatientRole){
            programServicePermissionRecord.PC_Patient_Response__c = PC_Constants.PERMISSION_PATIENT_RESPONSE;
        }
        else{
            programServicePermissionRecord.PC_CareTeamMember__c = associationRecordId;
            programServicePermissionRecord.PC_CareTeamMemberResponse__c = PC_Constants.CARE_TEAM_MEMBER_RESPONSE;
        }

        return programServicePermissionRecord;
    }

    /*********************************************************************************
    Method Name    : createEngagementProgramMetadata
    Author         : Tejas Patel
    Description    : This method is used for creating Engagement Program custom metadata
    Return Type    : PC_EngagementProgram__mdt
    Parameter      : String engagementProgramCode
    *********************************************************************************/
    public static PC_EngagementProgram__mdt createEngagementProgramMetadata(String engagementProgramCode) {
        PC_EngagementProgram__mdt ep    = new PC_EngagementProgram__mdt();
        ep.MasterLabel                  = engagementProgramCode;
        ep.DeveloperName                = engagementProgramCode.deleteWhitespace();
        ep.PC_EngagementProgramCode__c  = engagementProgramCode;
        ep.PC_IsActive__c               = true;
        return ep;
    }

    /*********************************************************************************
    Method Name    : createPatientConnectSetting
    Author         : Tejas Patel
    Description    : This method is used for creating Patient Connect custom metadata
    Return Type    : PC_Patient_Connect_Setting__mdt
    Parameter      : String SettingName, String SettingValue, Boolean isOverridable
    *********************************************************************************/
    public static PC_Patient_Connect_Setting__mdt createPatientConnectSetting(String SettingName, String SettingValue, Boolean isOverridable) {
        PC_Patient_Connect_Setting__mdt pcSetting   = new PC_Patient_Connect_Setting__mdt();
        pcSetting.MasterLabel                   = SettingName;
        pcSetting.DeveloperName                 = SettingName.deleteWhitespace();
        pcSetting.PC_SettingName__c             = SettingName;
        pcSetting.PC_SettingValue__c            = SettingValue;
        pcSetting.PC_IsOverridable__c           = isOverridable;
        pcSetting.PC_Active__c                = true;
        return pcSetting;
    }

    /*********************************************************************************
    Method Name    : createEngagementProgramSetting
    Author         : Tejas Patel
    Description    : This method is used for creating EngagementProgramSetting records
    Return Type    : PC_EngagementProgramSetting__mdt
    Parameter      : String settingType, String settingValue, PC_Patient_Connect_Setting__mdt pcSetting, PC_EngagementProgram__mdt ep
    *********************************************************************************/
    public static PC_EngagementProgramSetting__mdt createEngagementProgramSetting(String settingType, String settingValue, PC_Patient_Connect_Setting__mdt pcSetting, PC_EngagementProgram__mdt ep) {
        PC_EngagementProgramSetting__mdt settings = new PC_EngagementProgramSetting__mdt();
        settings.PC_EngagementProgram__r        = ep;
        settings.PC_IsActive__c                 = true;
        settings.PC_PatientConnectSetting__r    = pcSetting;
        settings.PC_SettingType__c              = settingType;
        settings.PC_SettingValue__c             = settingValue;

        return  settings;
    }

    /*********************************************************************************
    Method Name    : createPatientConnectSettings
    Author         : Tejas Patel
    Description    : This method is used for creating PatientConnect setting records
    Return Type    : PC_EngagementProgramSetting__mdt
    Parameter      : Id programCaseId,Id serviceRecordId,Boolean isPatientRole,Id associationRecordId
    *********************************************************************************/
    public static List<PC_EngagementProgramSetting__mdt> createUnassignedTaskTriage(String settingName, String SETTING_TYPE_PATIENT_CONNECT) {
        List<PC_EngagementProgramSetting__mdt> returnList = new List<PC_EngagementProgramSetting__mdt>();

        PC_EngagementProgram__mdt ep1 = PC_Test_Setup.createEngagementProgramMetadata('EP1');
        PC_EngagementProgram__mdt ep2 = PC_Test_Setup.createEngagementProgramMetadata('EP2');
        PC_EngagementProgram__mdt ep3 = PC_Test_Setup.createEngagementProgramMetadata('EP3');
        PC_EngagementProgram__mdt ep4 = PC_Test_Setup.createEngagementProgramMetadata('EP4');

        String settingValue = PC_Constants.EMPTY_STRING;
        PC_Patient_Connect_Setting__mdt pc = PC_Test_Setup.createPatientConnectSetting(settingName, settingValue , true);

        String ep1settingValue = '{"type" : "LoggedInUser"}';
        PC_EngagementProgramSetting__mdt pcsetting1 = PC_Test_Setup.createEngagementProgramSetting(SETTING_TYPE_PATIENT_CONNECT, ep1settingValue, pc, ep1);

        String ep2settingValue = '{"type" : "CaseOwner"}';
        PC_EngagementProgramSetting__mdt pcsetting2 = PC_Test_Setup.createEngagementProgramSetting(SETTING_TYPE_PATIENT_CONNECT, ep2settingValue, pc, ep2);

        String ep3settingValue = '{"type" : "Queue", "value" : "TestGroup"}';
        PC_EngagementProgramSetting__mdt pcsetting3 = PC_Test_Setup.createEngagementProgramSetting(SETTING_TYPE_PATIENT_CONNECT, ep3settingValue, pc, ep3);

        String ep4settingValue = '{"type" : "User", "value" : "taskdefaultuser@test.com"}';
        PC_EngagementProgramSetting__mdt pcsetting4 = PC_Test_Setup.createEngagementProgramSetting(SETTING_TYPE_PATIENT_CONNECT, ep4settingValue, pc, ep4);
        returnList.add(pcsetting1);returnList.add(pcsetting2);returnList.add(pcsetting3);returnList.add(pcsetting4);

        return returnList;
    }
}