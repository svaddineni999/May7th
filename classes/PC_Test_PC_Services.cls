/*********************************************************************************
  Class Name      : PC_Test_PC_Services
  Description     : This test class for PC_Services
  Created By      : Deloitte
  Created Date    : August 01, 2016
  Modification Log:
  ----------------------------------------------------------------------------------
  Developer                   Date                   Description
  -----------------------------------------------------------------------------------
  Roxana Ivan             August 01, 2016            Initial Version
  Tejas Patel			  April  12, 2017			 Adding TeststartTest() and TeststopTest() methods; Removal of debug statements; Adding Assert Statements
  Shabda Bhujad			  July 14, 2017		   		 [PC-1897] Added the check the test outcomes only if the trigger handler is active.
  Mike Klumpenaar         2017-08-10                 [PC-2007] Removed tests for methods removed from PC_Services
 *********************************************************************************/
@isTest
public class PC_Test_PC_Services {
    public static Boolean isTriggerActive = True;
    
    @isTest static void testDescribe() {
        Test.startTest();
        Schema.DescribeSobjectResult objDescr = PC_Services.describe('Account');
        Test.stopTest();
        System.assertNotEquals(objDescr, null); 
    }

    @isTest static void testGetNamespace() {
        Test.startTest();
        String namespace = PC_Services.getNamespace('Account');
        String namespace1 = PC_Services.getNamespace('');
        String namespace2 = PC_Services.getNamespace(Schema.Account.getSObjectType());
        Schema.sObjectType pObjType = null;
        String namespace3 = PC_Services.getNamespace(pObjType);
        Test.stopTest();
        
        System.assertNotEquals(namespace, null);
        System.assertEquals(namespace1, 'NS_DDPC');
        System.assertNotEquals(namespace2, null);
        System.assertEquals(namespace3, PC_Services.NS_DEFAULT);
    }
    
    @isTest static void testupdateableFieldsString() {
        Test.startTest();
        String updateableFields = PC_Services.updateableFieldsString('Account');
        Test.stopTest();
        system.assertNotEquals(updateableFields, null);
    }
    
    @isTest static void testisMultiPickListField() {
        Test.startTest();
        boolean isMultiSelect = PC_Services.isMultiPickListField(Account.Type);
        Test.stopTest();
        system.assertEquals(isMultiSelect, false);
    }

    @isTest static void testAccessibleFields() {
        Test.startTest();
        Map<String, Schema.SObjectField> fields = PC_Services.accessibleFields('Account');
        Map<String, Schema.SObjectField> fields2 = PC_Services.accessibleFields(Schema.Account.getSObjectType());
        Test.stopTest();
        
        System.assertNotEquals(fields, null);
        System.assertNotEquals(fields2, null);
    }

    @isTest static void testUpdateableFields() {
        Test.startTest();
        Map<String, Schema.SObjectField> fields = PC_Services.updateableFields('Account');
        Map<String, Schema.SObjectField> fields2 = PC_Services.updateableFields(Schema.Account.getSObjectType());
        Test.stopTest();
        
        System.assertNotEquals(fields, null);
        System.assertNotEquals(fields2, null); 
    }

    @isTest static void testIsDouble() {
        Test.startTest();
        Boolean isDouble = PC_Services.isDouble(Account.Name);
        Test.stopTest();
        System.assertNotEquals(isDouble, true);  
    }

    @isTest static void testIsInteger() {
        Test.startTest();
        Boolean isInteger = PC_Services.isInteger(Account.Name);
        Test.stopTest();
        System.assertNotEquals(isInteger, true);     
    }
    @isTest static void testIsDate() {
        Test.startTest();
        Boolean isDate = PC_Services.isDate(Account.Name);
        Test.stopTest();
        System.assertNotEquals(isDate, true);  
    }
    @isTest static void testIsDateTime() {
        Test.startTest();
        Boolean isDateTime = PC_Services.isDateTime(Account.Name);
        Test.stopTest();
        System.assertNotEquals(isDateTime, true);
          
    }

    @isTest static void testIsBoolean() {
        Test.startTest();
        Boolean isBoolean = PC_Services.isBoolean(Account.Name);
        Test.stopTest();
        System.assertNotEquals(isBoolean, true);
          
    }

    @isTest static void testFields() {
        Test.startTest();
        Map<String, Schema.SObjectField> fields = PC_Services.fields('Account');
        Test.stopTest();
        System.assertNotEquals(fields.size(), 0);
    }

    @isTest static void testIsPickListField() {
        Test.startTest();
        Boolean isPicklist = PC_Services.isPickListField(Account.Type);
        Test.stopTest();
        System.assertEquals(isPicklist, true);
    }

    @isTest static void testIsLookupField() {
        Test.startTest();
        Boolean isLookupField = PC_Services.isLookupField(Account.Type);
        Test.stopTest();
        System.assertEquals(isLookupField, false);
    }

    @isTest static void testIsAccessible() {
        Test.startTest();
        Boolean isAccessible = PC_Services.isAccessible('Account', 'Type');
        Test.stopTest();
        System.assertEquals(isAccessible, true);
    }

    @isTest static void testIsUpdateable() {
        Test.startTest();
        Boolean isUpdateable = PC_Services.isUpdateable('Account', 'Type');
        Test.stopTest();
        System.assertEquals(isUpdateable, true);
           
    }

    @isTest static void testObjectIsAccessible() {
        Test.startTest();
        Boolean isAccessible = PC_Services.isAccessible('Account');
        Test.stopTest();
        System.assertEquals(isAccessible, true);
         
    }

    @isTest static void testObjectIsUpdateable() {
        Test.startTest();
        Boolean isUpdateable = PC_Services.isUpdateable('Account');
        Test.stopTest();
        System.assertEquals(isUpdateable, true);
         
    }

    @isTest static void testObjectIsCreateable() {
        Test.startTest();
        Boolean isCreateable = PC_Services.isCreateable('Account');
        Test.stopTest();
        System.assertEquals(isCreateable, true);
          
    }

    @isTest static void testObjectIsDeletable() {
        Test.startTest();
        Boolean isDeletable = PC_Services.isDeletable('Account');
        Test.stopTest();
        System.assertEquals(isDeletable, true);
           
    }

    @isTest static void testObjectIsCustom() {
        Test.startTest();
        Boolean isCustom = PC_Services.isCustom('Account');
        Test.stopTest();
        System.assertEquals(isCustom, false);
          
    }

    @isTest static void testFieldsToString() {
        Test.startTest();
        SObjectType accountType = Schema.getGlobalDescribe().get('Account');
        List<String> fields = PC_Services.fieldsToString(accountType.getDescribe().fields.getMap().values());
        Test.stopTest();
        System.assertNotEquals(fields.size(), 0);
          
    }

    @isTest static void testShareObjName() {
        Test.startTest();
        String shareObj = PC_Services.shareObjName('Account');
        Test.stopTest();
        System.assertNotEquals(shareObj, null);
           
    }

    @isTest static void testsObjectType() {
        Test.startTest();
        Account patient = PC_Test_Setup.createPatient('testpatient');
        PC_Database.ins(patient);
        patient = [SELECT Id from Account LIMIT 1];
        Schema.SObjectType objType = PC_Services.sObjectType(patient.Id);
        Test.stopTest(); 
        System.assertEquals(objType, Schema.getGlobalDescribe().get('Account'));  
    }

    @isTest static void testIsObjectId() {
        Test.startTest();
        Account patient = PC_Test_Setup.createPatient('testpatient');
        PC_Database.ins(patient);
        patient = [SELECT Id from Account LIMIT 1];
        Boolean isAccount = PC_Services.isObjectId(patient.Id, PC_Services.sObjectType(patient.Id));
        Test.stopTest();  
        System.assertEquals(isAccount, true);     
    }

    @isTest static void testListViews() {
        Test.startTest();
        System.SelectOption[] views = PC_Services.listViews('Account');
        Test.stopTest(); 
        System.assertNotEquals(views.size(), 0);
           
    }
    @isTest static void testViewIdFromName() {
        Test.startTest();
        System.SelectOption[] views = PC_Services.listViews('Account');
        ID viewId = PC_Services.viewIdFromName('Account', views[0].getLabel());
        Test.stopTest(); 
        System.assertNotEquals(viewId, null);
           
    }
    
    @isTest static void testCopyFields() {
        Test.startTest();
        Account patientAccount = PC_Test_Setup.createPatient('testpatient');
        PC_Database.ins(patientAccount);
        if(isTriggerActive) {
            patientAccount = [SELECT Id FROM Account LIMIT 1];
            List<Contact> patientContacts = [SELECT Id FROM Contact WHERE AccountId =: patientAccount.Id];
            if(patientContacts != null && patientContacts.size() > 0) {
                SObject myObject = PC_Services.copyFields(patientAccount, patientContacts[0], true);
                System.assertNotEquals(myObject.Id, NULL);// Tejas-Patel; 13-Apr-2017
            }
        }
        Test.stopTest();
    }

    @isTest static void testKeyToken15ToIds() {
        Test.startTest();
        Account patient = PC_Test_Setup.createPatient('testpatient');
        PC_Database.ups(patient);
        patient = [SELECT Id from Account LIMIT 1];
        List<Id> ids = PC_Services.keyToken15ToIds(String.valueOf(patient.Id));
        Test.stopTest();  
        System.assertNotEquals(ids.size(), 0); 
    }

    @isTest static void testListKeyToken15ToIds() {
        Test.startTest();
        Account patient = PC_Test_Setup.createPatient('testpatient');
        PC_Database.ins(patient);  
        patient = [SELECT Id from Account LIMIT 1];
        List<Id> ids = PC_Services.key15ToId(New List<String> { String.valueOf(patient.Id) });
        Id aId = PC_Services.key15ToId((String)patient.Id);
        Test.stopTest(); 
        System.assertNotEquals(ids.size(), 0);       
    }


    @isTest static void testKey15ToIds() {
        Test.startTest(); 
        Account patient = PC_Test_Setup.createPatient('testpatient');
        PC_Database.ins(patient); 
        patient = [SELECT Id from Account LIMIT 1];
        List<Id> ids = PC_Services.key15ToId(New List<String> { String.valueOf(patient.Id) });
        Test.stopTest();
        System.assertNotEquals(ids.size(), 0);
    }
}