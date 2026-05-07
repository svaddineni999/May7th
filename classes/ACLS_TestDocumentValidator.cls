/**
* Summary:      This is the test class for Enrollment Icon Validation on the Basis of Document Tag Enrollment Form
* Author:       Deloitte
* Company:      Ashfield 
* Created:      Jan 19, 2023
* <Date>            <Authors Name>            <Brief Description of Change>
* Jan 19, 2023        Deloitte              		Initial Version
**/
@isTest(seeAllData=false)
private class ACLS_TestDocumentValidator {
    
    @testsetup
    private static void setup(){
        User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        insert usr;
        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_Licensed_Case_Manager_Permissions');
        lstPsAssignment.add(psAssignment);
        insert lstPsAssignment;
        System.runAs(usr){
            //Creating documents data
            List<PC_Document__c> testPC_Documentc=ACLS_TestDataFactory.createTestDocument(1);
            testPC_Documentc[0].PC_Document_Category__c = 'Enrollment Form';
            insert testPC_Documentc;
            
        }
    }
    
    @isTest 
    private static void test_isVisible() {
        PC_ActionValidator.Params validationParams= new PC_ActionValidator.Params();
        List<PC_Document__c> retgetDocDetail = new List<PC_Document__c>();
        retgetDocDetail= [SELECT Name, id,RecordTypeId,PC_Document_Category__c FROM PC_Document__c WHERE PC_Document_Category__c ='Enrollment Form'];
        validationParams.recordId = retgetDocDetail[0].id; 
        User usr = [select id from User where UserName = 'test@testAhsfield1.com'][0];
        system.assertEquals(retgetDocDetail[0].PC_Document_Category__c,'Enrollment Form');
        System.runAs(usr){
            Test.startTest();
            Boolean retisVisible = ACLS_DocumentValidator.isVisible(validationParams);  
            Test.stopTest();
        }
    }
    
    @isTest 
    private static void test_isAccessible() {
        PC_ActionValidator.Params validationParams = new PC_ActionValidator.Params();
        List<PC_Document__c> retgetDocDetail = new List<PC_Document__c>();
        retgetDocDetail= [SELECT Name, id,RecordTypeId,PC_Document_Category__c FROM PC_Document__c WHERE PC_Document_Category__c ='Enrollment Form'];
        validationParams.recordId = retgetDocDetail[0].id;
        User usr = [select id from User where UserName = 'test@testAhsfield1.com'][0];
        system.assertEquals(retgetDocDetail[0].PC_Document_Category__c,'Enrollment Form');
        System.runAs(usr){
            Test.startTest();
            PC_ActionValidator.AccessibilityResponse retisAccessible = ACLS_DocumentValidator.isAccessible(validationParams);
            Test.stopTest();
        }
    }
    
    @isTest 
    private static void test_getDocDetails() {
       
        String docId;
        User usr = [select id from User where UserName = 'test@testAhsfield1.com'][0];
        System.runAs(usr){
            Test.startTest();
             List<PC_Document__c> testPC_Documentc=ACLS_TestDataFactory.createTestDocument(1);
            testPC_Documentc[0].PC_Document_Category__c = 'Enrollment Form';
            insert testPC_Documentc;
            PC_Document__c retgetDocDetails = [SELECT Name, RecordType.DeveloperName, RecordType.NamespacePrefix,PC_Document_Category__c FROM 
                                               PC_Document__c WHERE PC_Document_Category__c ='Enrollment Form' LIMIT 1];
            
            system.assertEquals(testPC_Documentc[0].PC_Document_Category__c,'Enrollment Form');
           
            Test.stopTest();
        }
    }
    
}