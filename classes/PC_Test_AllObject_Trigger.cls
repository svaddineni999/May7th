/*********************************************************************************
Class Name      : PC_Test_AllObject_Trigger
Description     : A test class for all Object Triggers
Created By      : Deloitte
Created Date    : Jan 23, 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tejas Patel                 Jan 23, 2018            Initial Version		
Prachi Nandgaonkar          Jan 24, 2018            [PC-2649] Test class to test trigger framework for all patient connect triggers
                                                    which don't even have trigger handlers yet.
*********************************************************************************/
@isTest
public class PC_Test_AllObject_Trigger {
    private static User adminUser;
    private static final String MANUFACTURER_NAME = 'EngPrg87';
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static PC_Document__c oDoc;
    private static Case reqEnrollCase;
    private static PC_Applicant__c onlineApplicant1;
    private static PC_Document_Log__c docLog;

    @isTest
    static void updateAccountNameTest() {
        //Create Admin Users
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);

        //Create Bulk Patinet Accounts
        List<Account> accounts = PC_Test_Setup.createAccounts('Patient', 2, PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(accounts);

        //Create Case
        Case patient1Case = PC_Test_Setup.createCase(adminUser, accounts[0]);
        PC_Database.ins(patient1Case);

        //Create Manufacturer
        Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
        manufacturer = (Account)PC_Database.ins(manufacturer, false);

        //Create Product
        Product2  product = PC_Test_Setup.newProduct('Product1', 'P1', manufacturer.Id);
        product = (Product2)PC_Database.ins(product, false);

        //Create Pharmacy
        Account pharmacy = PC_Test_Setup.newAccount(null, 'TEST','Name 1','Last',  'PC_Pharmacy');
        pharmacy.BillingLatitude = 42;
        pharmacy.BillingLongitude = 120;
        pharmacy.Type = 'Pharmacy';
        pharmacy.PC_Sub_Type__c= 'Specialty Pharmacy';
        pharmacy = (Account)PC_Database.ins(pharmacy, false);

        //Create document1
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, MANUFACTURER_NAME + 'D');
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);

        //Engg Program
        PC_Engagement_Program__c engPrgA= PC_Test_Setup.createEngagementProgram(MANUFACTURER_NAME, manufacturer.Id);
        PC_Database.ins(engPrgA, false);

        //Create Applicant
        onlineApplicant1 = PC_Test_Setup.createApplicant('Patel');
        PC_Database.ins(onlineApplicant1, false);

        //Create the Enrollment Case with Applicant
        reqEnrollCase = new Case(
                Status 	= 'Open',
                Origin = 'Web',
                RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE),
                Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME,
                PC_Engagement_Program__c = engPrgA.Id,
                OwnerId					 = adminUser.Id,
                PC_ActiveApplicant__c	 = onlineApplicant1.Id
        );
        PC_Database.ins(reqEnrollCase, false);

        // create eltter
        PC_eLetter__c eletter = new PC_eLetter__c (
                Name = 'Test 1',
                PC_Target_Recipients__c = 'HCO; Treating Physician',
                PC_Communication_Language__c = 'English',
                PC_Send_to_User__c= false,
                PC_Source_Object__c = 'Case',
                PC_Template_Name__c = 'Email_Template_Name'
        );
        PC_Database.ins(eletter);

        system.runAs(adminUser) {
            Test.StartTest();
            PC_AdverseEvent__c ade = new PC_AdverseEvent__c();
            ade.PC_Patient__c = accounts[0].Id;
            PC_Database.ins(ade,false);

            PC_AdverseEvent2__c ade2 = new PC_AdverseEvent2__c();
            ade2.PC_Patient__c = accounts[1].Id;
            PC_Database.ins(ade2,false);

            PC_Alert__c alert = new PC_Alert__c();
            alert.PC_Program__c = patient1Case.Id;
            PC_Database.ins(alert,false);

            PC_Dispense__c dispense = new PC_Dispense__c();
            PC_Database.ins(dispense);

            PC_Distributor__c  dn = PC_Test_Setup.newDistributionNetwork(product.Id, pharmacy.Id);
            PC_Database.ins(dn, false);

            PC_Document_Log__c docLog = new PC_Document_Log__c();
            docLog.PC_Document__c = oDoc.Id;
            docLog.PC_Program__c = patient1Case.Id;
            PC_Database.ins(docLog, false);

            PC_Engagement_Program__c engP = new PC_Engagement_Program__c();

            PC_Engagement_Program_Product__c engPP = new PC_Engagement_Program_Product__c();
            //Engagement Program Product
            PC_Engagement_Program_Product__c engProductJunction = new PC_Engagement_Program_Product__c();
            engProductJunction.PC_Engagement_Program__c = engPrgA.Id;
            engProductJunction.PC_Product__c = product.Id;
            engProductJunction = (PC_Engagement_Program_Product__c)PC_Database.ins(engProductJunction, false);

            PC_Engagement_Program_Service__c engS = new PC_Engagement_Program_Service__c();

            PC_Engagement_Program_Eletter__c engE = new PC_Engagement_Program_Eletter__c();
            engE.PC_eLetter__c = eletter.Id;
            engE.PC_Engagement_Program__c = engPrgA.Id;
            PC_Database.ins(engE, false);

            PC_Error_Log__c err = new PC_Error_Log__c();

            //Create interaction
            PC_Interaction__c interaction = PC_Test_Setup.newInteraction(patient1Case.Id);
        	PC_Database.ins(interaction,false);
            
            
            //Create measurement
            PC_Measurement__c  measurement = PC_Test_Setup.createMeasurement(accounts[0].Id,patient1Case.Id, 8.0);
            PC_Database.ins(measurement,false);
            
            //Create message
            PC_Message__c  msg = PC_Test_Setup.createMessage(patient1Case);
            PC_Database.ins(msg,false);
            
            //Create prescription
            PC_Prescription__c  prescription = new PC_Prescription__c();
            PC_Database.ins(prescription,false);
            
            //Create program coverage
            PC_Program_Coverage__c prgCov = PC_Test_Setup.createProgramCoverage(patient1Case.Id);
            PC_Database.ins(prgCov,false);
            
            //Create request form
            PC_Request_Form__c reqForm= new PC_Request_Form__c(
            name = 'TestRequestForm'
            );
            PC_Database.ins(reqForm,false);
            
            //Create service
            PC_Service__c service = new PC_Service__c();
            PC_Database.ins(service,false);
            
                
            //Create request form service
            PC_Request_Form_Service__c reqFormService = new PC_Request_Form_Service__c(
            PC_Request_Form__c = reqForm.Id,
            PC_Service__c = service.Id
            );
            PC_Database.ins(reqFormService,false);
            
           
            //Create support model
            PC_Support_Model__c sm = PC_Test_Setup.createSupportModel(adminUser, 'TestSM');
            PC_Database.ins(sm,false);
         
                        
            Test.StopTest();
        }
    }

}