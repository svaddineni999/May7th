/*********************************************************************************
Class Name      : PC_Test_Consent_DataModel
Description     : Test the Consent Data Model
Created By      : TEJAS PATEL
Created Date    : 15-May-2017

Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
TEJAS PATEL		         15-May-2017	              Initial Version
TEJAS PATEL				 05-June-2017				  Modified the Assert Statements
Vijay Kashikar           07-Marc-2019                 [PC-4556] Changed reference from PC_Program_Service_Permission__c.PC_Program__c to PC_Program_Service_Permission__c.PC_ProgramCase__c
*********************************************************************************/
@isTest
public class PC_Test_Consent_DataModel {
    private static User adminUser;
	public static final String SERVICE_NAME = 'TestService';
    public static final String REQUEST_FORM_NAME = 'TestService';
    private static final Integer SERVICE_NUMBER = 3;
    
    
    /*********************************************************************************
    Method Name    : createRequestForm
    Author         : Tejas Patel
    Description    : This method creates PC_Request_Form__c records
    Return Type    : List<PC_Request_Form>
    Parameter      : Service Name and Number of Records
    *********************************************************************************/
    public static List<PC_Request_Form__c> createRequestForm(String requestFormName, Integer pNoRecs, PC_Engagement_Program__c engagmentProgram){
        List<PC_Request_Form__c> newRequestForm = new List<PC_Request_Form__c>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Request_Form__c requestForm 			= new PC_Request_Form__c();
            requestForm.Name						= requestFormName + '_' + i;
            requestForm.PC_Release_Date__c			= (DATE) date.today();
            requestForm.PC_Retirement_Date__c		= (DATE) date.today() + 10;
            requestForm.PC_Engagement_Program__c	= engagmentProgram.Id;
            newRequestForm.add(requestForm);
        }
        return newRequestForm;
    }
    
    /*********************************************************************************
    Method Name    : createRequestFormService
    Author         : Tejas Patel
    Description    : This method creates PC_Request_Form_Service__c records
    Return Type    : List<PC_Request_Form_Service__c>
    Parameter      : Service Name and Number of Records
    *********************************************************************************/
    public static List<PC_Request_Form_Service__c> createRequestFormService(List<PC_Request_Form__c> requestForm, Integer pNoRecs, List<PC_Service__c> services){
        List<PC_Request_Form_Service__c> newRequestFormService = new List<PC_Request_Form_Service__c>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Request_Form_Service__c requestFormService 			= new PC_Request_Form_Service__c();
            requestFormService.PC_Request_Form__c	= requestForm[i].Id;
            requestFormService.PC_Service__c		= services[i].Id;
            newRequestFormService.add(requestFormService);
        }
        return newRequestFormService;
    }
    
    /*********************************************************************************
    Method Name    : createEngagementProgramService
    Author         : Tejas Patel
    Description    : This method creates PC_Engagement_Program_Service__c records
    Return Type    : List<PC_Engagement_Program_Service__c>
    Parameter      : Service Name and Number of Records
    *********************************************************************************/
    public static List<PC_Engagement_Program_Service__c> createEngagementProgramService(PC_Engagement_Program__c engagement, Integer pNoRecs, List<PC_Service__c> services){
        List<PC_Engagement_Program_Service__c> newEngagementProgramService = new List<PC_Engagement_Program_Service__c>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Engagement_Program_Service__c engagementProgramService 			= new PC_Engagement_Program_Service__c();
            engagementProgramService.PC_Engagement_Program__c	= engagement.Id;
            engagementProgramService.PC_Service__c		= services[i].Id;
            newEngagementProgramService.add(engagementProgramService);
        }
        return newEngagementProgramService;
    }
    
    /*********************************************************************************
    Method Name    : createProgramServicePermissions
    Author         : Tejas Patel
    Description    : This method creates PC_Program_Service_Permission__c records
    Return Type    : List<PC_Program_Service_Permission__c>
    Parameter      : Service Name and Number of Records
    *********************************************************************************/
    public static List<PC_Program_Service_Permission__c> createProgramServicePermissions(List<PC_Service__c> services, Integer pNoRecs, Case programCase, PC_Document__c signedDocument){
        List<PC_Program_Service_Permission__c> newProgramServicePermissions = new List<PC_Program_Service_Permission__c>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Program_Service_Permission__c programServicePermission = new PC_Program_Service_Permission__c();
            programServicePermission.PC_Start_Date__c  = (Date) date.today();
            programServicePermission.PC_Service__c	   = services[i].Id;
            programServicePermission.PC_ProgramCase__c	   = programCase.Id;
            programServicePermission.PC_Signed_Request_Form__c = signedDocument.Id;
            newProgramServicePermissions.add(programServicePermission);
        }
        return newProgramServicePermissions;
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
	Method Name    : testConsentModel
	Author         : Tejas Patel
	Description    : This method is used for testing the Consent Model
	Return Type    : void 
	Parameter      : 
   *********************************************************************************/
    @isTest 
    static void testConsentModel() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);
        system.runAs(adminUser) {
            Test.StartTest();
            //Bulk Creation of Services
            List<PC_Service__c> services                    = createServices(SERVICE_NAME, SERVICE_NUMBER);
            PC_Database.ins(services,false);
            // check if Services are created for bulk testing
            system.assertEquals(services.size(), SERVICE_NUMBER);
            
            
            // create manufacturer account
        	Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        	PC_Database.ins(manufacturerAcc, false);
            
            // create patient account
        	Account patientAcc = PC_Test_Setup.createTestAccount(PC_Constants.PATIENT_RECORD_TYPE);
        	PC_Database.ins(patientAcc, false);
            
            // create program case
        	Case programCase = PC_Test_Setup.newCase(patientAcc.Id , PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        	PC_Database.ins(programCase, false);
            
            // create document
        	PC_Document__c onlineDocument = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
        	PC_Database.ins(onlineDocument, false);
            
            PC_Engagement_Program__c engagmentProgram = PC_Test_Setup.createEngagementProgram ('TstCMD', manufacturerAcc.Id);
            PC_Database.ins(engagmentProgram, false);
            
            List<PC_Request_Form__c> requestForm = createRequestForm('TestRequestForm' , SERVICE_NUMBER, engagmentProgram);
            PC_Database.ins(requestForm, false);
            // check if RequestForms are created for bulk testing
            system.assertEquals(requestForm.size(), SERVICE_NUMBER);
            
            List<PC_Request_Form_Service__c> requestFormService = createRequestFormService(requestForm, SERVICE_NUMBER, services);
            PC_Database.ins(requestFormService, false);
            // check if RequestFormServices are created for bulk testing
            system.assertEquals(requestFormService.size(), SERVICE_NUMBER);
            
            List<PC_Engagement_Program_Service__c> engagementProgramService = createEngagementProgramService(engagmentProgram, SERVICE_NUMBER, services);
            PC_Database.ins(engagementProgramService, false);
            // check if RequestFormServices are created for bulk testing
            system.assertEquals(engagementProgramService.size(), SERVICE_NUMBER);
            
            //Bulk Creation of Program Service Permission
            List<PC_Program_Service_Permission__c> programServicePermissions   = createProgramServicePermissions(services, SERVICE_NUMBER, programCase, onlineDocument);
            PC_Database.ins(programServicePermissions,false);
            // check if Program Service Permission are created for bulk testing
            system.assertEquals(programServicePermissions.size(), SERVICE_NUMBER);
            
            List<PC_Program_Service_Permission__c> testProgramServicePermission = [SELECT Id, PC_ProgramCase__c, PC_ProgramCase__r.PC_Engagement_Program__c,
                PC_Service__c, PC_Program_Service_Permission_Name__c, 
                PC_Signed_Request_Form__c FROM PC_Program_Service_Permission__c 
                where PC_ProgramCase__c in (SELECT Id from Case where Account.ID = :patientAcc.Id)];
            
            for (PC_Program_Service_Permission__c a : testProgramServicePermission){
                system.assertEquals(a.PC_ProgramCase__c, programCase.Id);
                system.assertEquals(a.PC_Signed_Request_Form__c, onlineDocument.Id);
            }
            
            List<PC_Request_Form_Service__c> testRequestFormService = [SELECT ID, PC_Request_Form__c, PC_Request_Form__r.Name 
                                                                                    FROM PC_Request_Form_Service__c 
                WHERE PC_Service__c IN 
                (SELECT PC_Service__c FROM PC_Program_Service_Permission__c 
                 WHERE PC_Signed_Request_Form__c= :onlineDocument.Id)];
            
            system.assertEquals(testRequestFormService.size(), SERVICE_NUMBER);
            
            Test.StopTest();
        }
    }       
}