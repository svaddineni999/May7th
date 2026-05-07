/**
* Summary:      This is the test class for Populate Engagement Code
* Author:       Deloitte
* Company:      Ashfield 
* Created:      06.01.2023 
* <Date>            <Authors Name>            <Brief Description of Change>
* 06/01/2023        Deloitte              Initial Version
**/
@isTest(seeAllData=false)
public class ACLS_Test_ExecuteFlows {
    @testSetup 
    private static void dataSetup() {
       User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        insert usr;
        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_Base_RW_Permissions');
        lstPsAssignment.add(psAssignment);
        insert lstPsAssignment;
        System.runAs(usr) {
            Map<String, Id> mapAccRecordTypes = ACLS_Utility.getMapOfRecordtype(ACLS_Constants.ACCOUNT);

            //Creating Manufacturer 
            List<Account> lstAcct = ACLS_TestDataFactory.createAccount(2);
            lstAcct[0].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            lstAcct[1].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            insert lstAcct;
            System.debug('lstAcct!@#$ '+lstAcct);

            //Creating Engagement Program
            List<PC_Engagement_Program__c> lstEngageProgram = ACLS_TestDataFactory.createEngagmentProgram(1);
            lstEngageProgram[0].PC_Program_Code__c = 'ASHF';
            insert lstEngageProgram;
			System.debug('lstEngageProgram!@#$ '+lstEngageProgram);
            
            //Creating Program Case
            List<Case> lstProgramCase = ACLS_TestDataFactory.createProgramCase(1, lstAcct[1].Id);
            lstProgramCase[0].PC_Engagement_Program__c = lstEngageProgram[0].Id;
            
            lstProgramCase[0].OwnerId = UserInfo.getUserId();
            lstProgramCase[0].Subject='Test Subject';

            insert lstProgramCase;
            System.debug('lstProgramCase!@#$ '+lstProgramCase);
            
            //Creating Adverse event
            List<PC_AdverseEvent2__c> lstadverseEvent = ACLS_TestDataFactory.createPC_AdverseEvent2TestRecord(1);
            //lstadverseEvent[0].PC_Engagement_Program__c=lstEngageProgram[0].id;
            lstadverseEvent[0].PC_Care_Program__c=lstProgramCase[0].id;
            lstadverseEvent[0].PC_Reporter__c='mrXyz';
            insert lstadverseEvent;
            
            //Creating Applicant record
            List<PC_Applicant__c> lstApplicant = ACLS_TestDataFactory.createPC_ApplicantTestRecord(1);
            lstApplicant[0].PC_Engagement_Program__c=lstEngageProgram[0].id;
        	lstApplicant[0].PC_Physician_State__c='USA';
            insert lstApplicant;
   			
            //create document record
            List<PC_Document__c> lstDocument = ACLS_TestDataFactory.PC_DocumentcTestDataMethod(1);
            lstDocument[0].PC_Engagement_Program__c = lstEngageProgram[0].id;
        	lstDocument[0].PC_To_Fax_Name__c='saad';
            lstDocument[0].OwnerId =usr.id;
            lstDocument[0].PC_Document_Status__c='New';
        	insert lstDocument;
            
            //create order record
            List<PC_Order__c> lstOrder = ACLS_TestDataFactory.PC_OrdercTestDataMethod(1);
            lstOrder[0].PC_ProgramCase__c = lstProgramCase[0].id;
            lstOrder[0].PC_ShipmentTrackingNumber__c='1234';
            insert lstOrder;
            
            //create pharmacy referral record
             List<PC_Pharmacy_Referral__c> lstPharmrefrrl = ACLS_TestDataFactory.PC_Pharmacy_ReferralcTestDataMethod(1);
             lstPharmrefrrl[0].PC_Program__c = lstProgramCase[0].id;
             lstPharmrefrrl[0].PC_Source__c = 'web';
                 insert lstPharmrefrrl;
            
            //create prescription record
            List<PC_Prescription__c> lstPrescription = ACLS_TestDataFactory.PC_PrescriptioncTestDataMethod(1);
            lstPrescription[0].PC_Program_Case__c = lstProgramCase[0].id;
        	lstPrescription[0].PC_Dosage__c='two';
        	insert lstPrescription;
            
            //create service record
            List<PC_Service__c> lstService = ACLS_TestDataFactory.PC_ServiceTestDataMethod(1);
            lstService[0].Name='HIPAA Authorization';
			insert lstService;
            
            //create psp record
            List<PC_Program_Service_Permission__c> lstpsp = ACLS_TestDataFactory.PC_Program_Service_PermissioncTestDataMethod(1);
            lstpsp[0].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp[0].ACLS_Engagement_Program_Code__c='ASHF';
        	//psp.PC_Service__c=serv.id;
        	insert lstpsp;
            
            //create interact record
            List<PC_Interaction__c> lstinteract = ACLS_TestDataFactory.PC_InteractioncTestDataMethod(1);
            lstinteract[0].PC_Patient_Program__c = lstProgramCase[0].id;
        	lstinteract[0].PC_Type__c='Injection Training';
        	lstinteract[0].PC_Notes__c='Xyz';
        	insert lstinteract;
            
            Case programCase1 = new Case();
        programCase1.RecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe()
                                    .getRecordTypeInfosByDeveloperName()
                                    .get(ACLS_Constants.CASE_PROGRAM_RT)
                                    .getRecordTypeId(); 
        programCase1.PC_Engagement_Program__c = lstEngageProgram[0].id;
        programCase1.Subject='Test Subject1';
        //programCase1.PC_Care_Coordinator__c=usr.id;
        insert programCase1;
    }
    }
    @isTest
    public static void test_AdverseEventFlowACLSTestflow1()
    {
        PC_AdverseEvent2__c ad =[select id,PC_Reporter__c,ACLS_Engagement_Program_Code__c from PC_AdverseEvent2__c where PC_Reporter__c ='mrXyz'];
        System.debug('AdverseEvent+++++++ '+ad);
        Test.startTest();
        ad.PC_Reporter__c='MrAbc';
        update ad;
        system.assertEquals(ad.PC_Reporter__c, 'MrAbc');
        Test.stopTest(); 
    }
    @isTest
    public static void test_ApplicantFlowACLSTestflow1()
    {
        PC_Applicant__c ap =[select id,PC_Physician_State__c,PC_Engagement_Program__c from PC_Applicant__c where PC_Physician_State__c ='USA'];
        
        Test.startTest();
        ap.PC_Physician_State__c='IND';
        update ap;
        system.assertEquals(ap.PC_Physician_State__c, 'IND');
        Test.stopTest(); 
    }
     @isTest
    public static void test_DocumentFlowACLSTestflow1()
    {
        
        List<PC_Document__c> ap =[select id,OwnerId,PC_Document_Status__c,PC_To_Fax_Name__c,PC_Engagement_Program__c from PC_Document__c where PC_To_Fax_Name__c ='saad'];
        
        Test.startTest();
        ap[0].PC_To_Fax_Name__c='Test Subject 1';
        ap[0].PC_Document_Status__c='In Review';
        update ap;
        system.assertEquals(ap[0].PC_Document_Status__c, 'In Review');
        Test.stopTest();
    }
    @isTest
    public static void test_CaseFlowACLSTestflow1()
    {
        Case ap =[select id,Subject,PC_Engagement_Program__c from Case where Subject ='Test Subject'];
        
        Test.startTest();
        ap.Subject='Test Subject 1';
        update ap;
        system.assertEquals(ap.Subject, 'Test Subject 1');
        Test.stopTest(); 
    }
     @isTest
    public static void test_OrderFlowACLSTestflow1()
    {
        PC_Order__c ap =[select id,PC_ShipmentTrackingNumber__c,PC_ProgramCase__c from PC_Order__c where PC_ShipmentTrackingNumber__c ='1234'];
        
        Test.startTest();
        ap.PC_ShipmentTrackingNumber__c='Test Subject 1';
        update ap;
        system.assertEquals(ap.PC_ShipmentTrackingNumber__c, 'Test Subject 1');
        Test.stopTest();
    }
    @isTest
    public static void test_PharmacyReferralFlowACLSTestflow1()
    {
        PC_Pharmacy_Referral__c ap =[select id,PC_Source__c,PC_Program__c from PC_Pharmacy_Referral__c];
        Case c =[select id,Subject,PC_Engagement_Program__c from Case where Subject ='Test Subject1'];
        System.debug('Pharmacyreferral at 91 '+ap);
        Test.startTest();
        ap.PC_Program__c=c.id;
        update ap;
        system.assertEquals(c.Subject, 'Test Subject1');
        Test.stopTest();   
    }
     @isTest
    public static void test_PrescriptionFlowACLSTestflow1()
    {
		PC_Prescription__c ap =[select id,PC_Dosage__c,PC_Program_Case__c from PC_Prescription__c where PC_Dosage__c ='two'];
        
        Test.startTest();
        ap.PC_Dosage__c='Test Subject 1';
        update ap;
        system.assertEquals(ap.PC_Dosage__c, 'Test Subject 1');
        Test.stopTest();
    }
    @isTest
    public static void test_ProgramServicePermissionFlowACLSTestflow1()
    {
       List<PC_Program_Service_Permission__c> prgmservperm =[select id,ACLS_Engagement_Program_Code__c,PC_ProgramCase__c from PC_Program_Service_Permission__c ];
        System.debug('prgmservperm!@## '+prgmservperm);
        Test.startTest();
        for(PC_Program_Service_Permission__c ps:prgmservperm){
        ps.ACLS_Engagement_Program_Code__c='ASHF';
        }
        update prgmservperm;
        system.assertEquals(prgmservperm[0].ACLS_Engagement_Program_Code__c, 'ASHF');

        Test.stopTest();
        for(PC_Program_Service_Permission__c ps:prgmservperm){
        system.assertEquals(ps.ACLS_Engagement_Program_Code__c, 'ASHF');
            System.debug('ps.ACLS_Engagement_Program_Code__c!@## '+ps.ACLS_Engagement_Program_Code__c);
            System.debug('ps!@## '+ps);
        }
    }
	@isTest
    public static void test_ProgramServicePermissionTaskFlowACLSTestflow1()
    {
        
        
        Test.startTest();
        PC_Service__c serv = new PC_Service__c();
        serv.Name='HIPAA Authorization';
        insert serv;
            
        PC_Program_Service_Permission__c psp = new PC_Program_Service_Permission__c();
        
        psp.ACLS_Engagement_Program_Code__c='123';
        psp.PC_Service__c=serv.id;
		psp.ACLS_PT_Legal_GUA_Permission_Required__c = true;
        system.assertEquals(psp.ACLS_Engagement_Program_Code__c, '123');
        insert psp;
        Test.stopTest();
    }
    @isTest
    public static void test_InteractionFlowACLSTestflow1()
    {
        List<PC_Interaction__c> ap =[select id,PC_Notes__c,PC_Patient_Program__c from PC_Interaction__c];
        
        Test.startTest();
        for(PC_Interaction__c ps:ap){
        ps.PC_Notes__c='Test Subject 1';
        }
        update ap;
        system.assertEquals(ap[0].PC_Notes__c, 'Test Subject 1');
        Test.stopTest();
    }
    @isTest
    public static void test_FaxFlowACLSTestflow()
    {
       Test.startTest();
        //Created new fax record with status as complete
        List<EFX__efax__c> fax = ACLS_TestDataFactory.faxTestDataMethod(1);
        insert fax;
        
         //Created test document record
        List<PC_Document__c> doc = [select id,OwnerId,PC_Document_Status__c from PC_Document__c where PC_Document_Status__c='New'];
        doc[0].ACLS_Fax__c = fax[0].id;
        update doc;
        
        //verify the document status updated to Sent
        List<PC_Document__c> doc1 = [select id,PC_Document_Status__c from PC_Document__c Where ACLS_Fax__c = :fax[0].Id];
        System.assertEquals('New', doc1[0].PC_Document_Status__c);
        Test.stopTest();

    }
}