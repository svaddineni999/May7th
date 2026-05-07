/*********************************************************************************
Class Name      : PC_Test_DocumentManagementReceiveConsent
Description     : Test Program Service Permission list view in Document Viewer
Created By      : Sheela Sathyanarayana
Created Date    : 18-Aug-2018

Modification Log:
----------------------------------------------------------------------------------
Developer                        Date                      Description
-----------------------------------------------------------------------------------           
Sheela Sathyanarayana		     18-Aug-2018	           Initial Version
Vijay Kashikar                   07-Marc-2019              [PC-4556] Changed reference from PC_Program_Service_Permission__c.PC_Program__c to PC_Program_Service_Permission__c.PC_ProgramCase__c
*********************************************************************************/
@isTest
public class PC_Test_DocumentManagementReceiveConsent {

    private static User adminUser;
	public static final String SERVICE_NAME = 'Service1';
    public static final String REQUEST_FORM_NAME = 'Form1';
    private static final Integer SERVICE_NUMBER = 1;

    public static List<PC_Program_Service_Permission__c> createProgramServicePermissions(List<PC_Service__c> services, Integer pNoRecs, Case programCase, String ConsentType, PC_Document__c signedDocument){
        List<PC_Program_Service_Permission__c> newProgramServicePermissions = new List<PC_Program_Service_Permission__c>(); 
        for(integer i = 0; i < pNoRecs; i ++){
            PC_Program_Service_Permission__c programServicePermission = new PC_Program_Service_Permission__c();
            programServicePermission.PC_Start_Date__c  = (Date) date.today();
            programServicePermission.PC_Service__c	   = services[i].Id;
            programServicePermission.PC_ProgramCase__c	   = programCase.Id;
            programServicePermission.PC_Signed_Request_Form__c = signedDocument.Id;
            programServicePermission.PC_Consent_Type__c = ConsentType;
            newProgramServicePermissions.add(programServicePermission);
        }
        return newProgramServicePermissions;
    }
    
    @isTest static void testMethodList() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            
            //To test field labels
            PC_DocumentManagementReceiveConsent.FieldLabels fieldlabels =  PC_DocumentManagementReceiveConsent.getFieldLabels();
            system.assertEquals(fieldlabels.service, PC_Program_Service_Permission__c.PC_Service__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.patientResponse, PC_Program_Service_Permission__c.PC_Patient_Response__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.patientResponseDate, PC_Program_Service_Permission__c.PC_Patient_Response_Date__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.hcpResponse, PC_Program_Service_Permission__c.PC_HCP_Response__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.hcpResponseDate,PC_Program_Service_Permission__c.PC_HCP_Response_Date__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.startDate, PC_Program_Service_Permission__c.PC_Start_Date__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.endDate, PC_Program_Service_Permission__c.PC_End_Date__c.getDescribe().getLabel());
            system.assertEquals(fieldlabels.caseId, PC_Program_Service_Permission__c.PC_ProgramCase__c.getDescribe().getLabel());
            
            //Creating Patient Account
            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ins(patient, false);
            system.assertNotEquals(patient.Id, null);
            system.debug('$$ Patient Id = '+patient.Id);

            //Creating Program Case for the account
            Case programCase = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            programCase = (Case)PC_Database.ins(programCase, false);
            system.assertNotEquals(programCase.Id, null);
            system.debug('$$ Program Case Id = '+programCase.Id);  
            
            //Creating Manufacturer Account
        	Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        	PC_Database.ins(manufacturerAcc, false);
            system.assertNotEquals(manufacturerAcc.Id, null);
            system.debug('$$ Manufaturer Id = ' + manufacturerAcc.Id);

            //Creating document
        	PC_Document__c onlineDocument = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
        	PC_Database.ins(onlineDocument, false);
            system.assertNotEquals(onlineDocument.Id, null);
            system.debug('$$ onlineDocument Id = ' + onlineDocument.Id);
            
            //Creating Engagement Program
            PC_Engagement_Program__c engagmentProgram = PC_Test_Setup.createEngagementProgram ('TstCMD', manufacturerAcc.Id);
            PC_Database.ins(engagmentProgram, false);
            
            //Creating Service and Check
            List<PC_Service__c> services = PC_Test_Setup.createServices(SERVICE_NAME, SERVICE_NUMBER);
            PC_Database.ins(services,false);
            system.assertEquals(services.size(), SERVICE_NUMBER);
            system.debug('$$ services = ' + services);
            
            //Creating Program Service Permission
            List<PC_Program_Service_Permission__c> programServicePermissions   
                = createProgramServicePermissions(services, SERVICE_NUMBER,  programCase,'Written', onlineDocument);
            PC_Database.ins(programServicePermissions,false);
            system.assertEquals(programServicePermissions.size(), SERVICE_NUMBER);
            system.debug('$$ programServicePermissions = ' + programServicePermissions);
            
            List<PC_Program_Service_Permission__c> testProgramServicePermission 
                = [SELECT Id, PC_ProgramCase__c, PC_ProgramCase__r.PC_Engagement_Program__c,PC_Service__c, PC_Program_Service_Permission_Name__c,
                PC_Signed_Request_Form__c, PC_Consent_Type__c FROM PC_Program_Service_Permission__c 
                where PC_Signed_Request_Form__c = :onlineDocument.Id
                ];
            system.debug('$$ testProgramServicePermission = ' + testProgramServicePermission);
            
           
            LIST<id> accID= new list<string>{onlineDocument.Id};
            PC_DocumentManagementReceiveConsent.InitData consents =  PC_DocumentManagementReceiveConsent.getConsentCases(accId);
            system.debug('$$ consents = ' + consents);
            system.assertEquals(consents.consentsList.size(), testProgramServicePermission.size());
                        

            Test.StopTest();
        } 
    }
}