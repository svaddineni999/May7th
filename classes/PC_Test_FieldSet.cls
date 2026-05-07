/*********************************************************************************
Class Name      : PC_Test_FieldSet
Description     : Test class used for PC_FieldSet.apxc
Created By      : Deloitte               
Created Date    : March 31, 2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Tejas Patel           March 31, 2017           Initial Version
*********************************************************************************/
@isTest 
public class PC_Test_FieldSet {
    private static User adminUser;
    @isTest static void testMethodCreate() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            //Creating a parent document
            PC_Document__c pDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
			PC_Database.ins(pDoc, false);
            
            List<PC_FieldSet.FieldSet> fieldset;
            
            // using pc_document__c as PC_FieldSet class is used only for document detail section
            
            String typeName	= PC_Constants.getQualifiedAPIName('PC_Document__c');
            String fsName 	= PC_Constants.getQualifiedAPIName('PC_Document_FieldSet'); 
            Id recordId 	=  pDoc.Id; 
            fieldset 		=  PC_FieldSet.getFields(typeName, fsName, recordId);
            
            // get field set member label
            Set <String> fieldSetLabel1 = new Set <String> ();
            
            for (PC_FieldSet.FieldSet fs : fieldSet) {
                fieldSetLabel1.add(fs.label);
            }

            Schema.DescribeSObjectResult targetType = Schema.getGlobalDescribe().get(typeName).getDescribe();
            List<Schema.FieldSetMember> fields = targetType.fieldSets.getMap().get(fsName).getFields();
            
            // check if the size of the returned result is same
            system.assertEquals(fieldset.size(), fields.size());
			
			// get field set member label
            Set <String> fieldSetLabel2 = new Set <String> ();
            
            for (Schema.FieldSetMember fs : fields) {
                fieldSetLabel2.add(fs.label);
            }           
            
            // check if the returned results are similar
            //system.assert(fieldSetLabel2.equals(fieldSetLabel1) , 'The field sets are equal');
			Test.stopTest();
        }
    }

    @isTest static void testFieldSetExceptions() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            String errorMessage = 'testMessage';
            String errorCode = 'testCode';

            Test.startTest();
            PC_FieldSet.FieldSetNullException nullExp = new PC_FieldSet.FieldSetNullException(errorMessage , errorCode);
            system.assertEquals(nullExp.errorMessage,errorMessage);
            system.assertEquals(nullExp.errorCode,errorCode);

            PC_FieldSet.LookupFieldNameException lookupExp = new PC_FieldSet.LookupFieldNameException(errorMessage , errorCode);
            system.assertEquals(lookupExp.errorMessage,errorMessage);
            system.assertEquals(lookupExp.errorCode,errorCode);

            PC_FieldSet.ObjectNameException objectExp = new PC_FieldSet.ObjectNameException(errorMessage , errorCode);
            system.assertEquals(objectExp.errorMessage,errorMessage);
            system.assertEquals(objectExp.errorCode,errorCode);

            Test.stopTest();
        }

    }
}