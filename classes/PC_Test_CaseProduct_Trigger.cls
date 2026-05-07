/*********************************************************************************
Class Name      : PC_Test_CaseProduct_Trigger
Description     : This test class for Case Product trigger
Created By      : Chetna Mohapatra
Created Date    : April 18, 2022
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Chetna Mohapatra       April 18, 2022           Initial Version
*************************************************************************************/
@isTest
  public with sharing class PC_Test_CaseProduct_Trigger {
    private static User adminUser;

    @isTest
    static void createCaseProductTest() {
      //Create admin user
      adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'myuser@testing.com', 'myuser');
      PC_Database.ins(adminUser);

      //Create Account
      Id accRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PC_BUSINESSACCOUNT_PATIENT_RECORD_TYPE);
      Account patient = PC_Test_Setup.createAccount('MyPatient',accRecordTypeId);
      patient = (Account) PC_Database.ins(patient, false);
      system.assertNotEquals(patient.Id, null);

      //Create Case
      Case programCase = PC_Test_Setup.createCase(adminUser, patient);
      PC_Database.ins(programCase,false);

      //Create Manufacturer
      Account  manufacturer = PC_Test_Setup.createEWPPatient('MyManufacturer', '1990-08-30', 'Mr.' , 'Manufacturer');
      manufacturer = (Account)PC_Database.ins(manufacturer, false);

      //Create Product
      Product2  product = PC_Test_Setup.newProduct('MyProduct', 'P4', manufacturer.Id);
      product = (Product2)PC_Database.ins(product, false);

      system.runAs(adminUser) {
        Test.StartTest();
        //Create Case Product
        createCaseProduct(programCase.Id, product.Id);
        Test.StopTest();
      }
    }
    public static void createCaseProduct(Id caseId, Id productId) {
      PC_CaseProduct__c caseProduct= new PC_CaseProduct__c();
      caseProduct.PC_Case__c= caseId;
      caseProduct.PC_Product__c= productId;
      caseProduct = (PC_CaseProduct__c) PC_Database.ins(caseProduct, false);
    }

  }