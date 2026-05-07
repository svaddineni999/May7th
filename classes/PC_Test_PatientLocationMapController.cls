/*******************************************************************************************
Class Name      : PC_Test_PatientLocationMapController 
Description     : Test methods PC_PatientLocationMapController
Created By      : Deloitte
Created Date    : May 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan              May 30, 2016             Initial Version
Tejas Patel				 Sep 8, 2017			  [PC-2016] Modification for Refarral flow and creation of Test Data
Prachi Nandgaonkar       Sept 15, 2017            [PC-2217]Updated retrieveNearbySP() with updated Distribution Network object name
Vijay Kashikar           Aug 20, 2019             [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/
@isTest
private class PC_Test_PatientLocationMapController {
    
    @isTest static void testMapLocation() {
        Test.StartTest();
        //Create Patient
        Account pat = PC_Test_Setup.newAccount(null, 'TESTPATIENT','PatientName','LastName',  PC_Constants.PATIENT_RECORD_TYPE);
        pat.BillingLatitude = 50;
        pat.BillingLongitude = 120;
        pat = (Account)PC_Database.ins(pat, false);
        system.assertNotEquals(pat.Id, null);

        //Create Pharmacy
        Account pharmacy = PC_Test_Setup.newAccount(null, 'TEST','Name 1','Last',  'PC_Pharmacy');
        pharmacy.BillingLatitude = 42;
        pharmacy.BillingLongitude = 120;
        pharmacy.Type = 'Pharmacy';
        pharmacy.PC_Sub_Type__c= 'Specialty Pharmacy';
        pharmacy = (Account)PC_Database.ins(pharmacy, false);
        system.assertNotEquals(pharmacy.Id, null);
        //system.debug('Display : '+ pharmacy.pcfall17__PC_Display_on_Map__c);

        //Create Manufacturer
        Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
        manufacturer = (Account)PC_Database.ins(manufacturer, false);
        system.assertNotEquals(manufacturer.Id, null);

        //Create Engagement Program
        PC_Engagement_Program__c  engagement = PC_Test_Setup.createEngagementProgram('programA', manufacturer.Id);
        engagement = (PC_Engagement_Program__c)PC_Database.ins(engagement, false);
        system.assertNotEquals(engagement.Id, null);

        //Create Product
        Product2  product = PC_Test_Setup.newProduct('Product1', 'P1', manufacturer.Id);
        product = (Product2)PC_Database.ins(product, false);
        system.assertNotEquals(product.Id, null);

        //New Distribution Network
        PC_Distributor__c  dn = PC_Test_Setup.newDistributionNetwork(product.Id, pharmacy.Id);
        dn = (PC_Distributor__c)PC_Database.ins(dn, false);
        system.assertNotEquals(dn.Id, null);

        //Engagement Program Product
        PC_Engagement_Program_Product__c engProductJunction = new PC_Engagement_Program_Product__c();
        engProductJunction.PC_Engagement_Program__c = engagement.Id;
        engProductJunction.PC_Product__c = product.Id;
        engProductJunction = (PC_Engagement_Program_Product__c)PC_Database.ins(engProductJunction, false);
        system.assertNotEquals(engProductJunction.Id, null);

        //Program Case
        Case programCase = PC_Test_Setup.newCase(pat.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        programCase.PC_Engagement_Program__c = engagement.Id;
        programCase.PC_Program_Product__c = engProductJunction.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
        system.assertNotEquals(programCase.Id, null);

        PC_Database.ins(new PC_System_Settings__c(PC_Google_Map_Location_Radius__c = 50, PC_Google_Map_Radius_Is_KM__c = true), false);

        ApexPages.StandardController sscController = new ApexPages.StandardController(programCase);
        PC_PatientLocationMapController controller = new PC_PatientLocationMapController(sscController);
        system.assertNotEquals(null, controller.patient);
        PC_PatientLocationMapController.clinicType = 'Hospital Pharmacy';
        //getClinicImagesL()
        List<PC_LightningMap> getClinicImagesLOptions = PC_PatientLocationMapController.getClinicImagesL(pat, 50, true, programCase.Id, 'Hospital Pharmacy');
        //system.assertEquals(getClinicImagesLOptions[0].name, 'Specialty Pharmacy');

        //getMapClinics()
        List<PC_LightningMap> getMapClinicsOptions1 = PC_PatientLocationMapController.getMapClinics(pat , true);
        List<PC_LightningMap> getMapClinicsOptions2 = PC_PatientLocationMapController.getMapClinics(pat , false);
        //system.assertEquals(getMapClinicsOptions1[0].name, 'ALL');
        //system.assertEquals(getMapClinicsOptions2[0].name, 'ALL');

        //getPatientInfo()
        Account patient = PC_PatientLocationMapController.getPatientInfo(pat, programCase.Id);
        system.assertEquals(patient.BillingLatitude, 50);
        system.assertEquals(patient.BillingLongitude, 120);

        //getNearbyClinics()
        List<Account> getNearbyClinics1 = PC_PatientLocationMapController.getNearbyClinics(pat, 'Specialty Pharmacy', true ,programCase.Id ,50);
        List<Account> getNearbyClinics2 = PC_PatientLocationMapController.getNearbyClinics(pat, 'Specialty Pharmacy', false ,programCase.Id ,50);

        //getNearbyAccounts()
        PC_PatientLocationMapController.getNearbyAccounts(pat.Id, pat.BillingLatitude, pat.BillingLongitude, 'All');

        //isDistanceInKM()
        PC_PatientLocationMapController.isDistanceInKM();

        Test.StopTest();
     }

    @isTest static void testFieldLabels() {
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@testpc.com','UserName');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            PC_PatientLocationMapController.getFieldLabels();
            Test.StopTest();
        }
    }
}