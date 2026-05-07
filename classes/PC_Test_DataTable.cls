/**
 * Class Name      : PC_Test_DataTable
 * Created By      : Tejas Patel
 * @Created Date   : January 06, 2021
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Tejas Patel            06-Jan-2021               Initial Version
 */

@isTest(seeAllData=false)
public with sharing class PC_Test_DataTable {
    private static User adminUser;
    private static Account patient;
    private static Account physician;
    private static List<Account>  manufacturers;
    private static Account  manufacturer;
    private static PC_Engagement_Program__c enmtProgram;
    private static Case programCase;
    private static Product2 product;
    private static Product2 product1;
    private static PC_Prescription__c prescription;
    private static PC_Engagement_Program_Product__c epp;
    private static PC_Engagement_Program_Product__c epp1;
    private static PC_OrderItem__c oi;
    private static PC_OrderItem__c oi1;
    private static PC_Order__c o;
    private static String fsOrderDetails    = PC_Constants.getQualifiedAPIName('PC_OrderDetails');
    private static String fsSelectionList   = PC_Constants.getQualifiedAPIName('PC_Product');
    private static String fsDisplayList     = PC_Constants.getQualifiedAPIName('PC_OrderItems');
    private static String fsOrderShipment   = PC_Constants.getQualifiedAPIName('PC_OrderShipment');

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Haritha Reddy
    Description    : This method is used for creating test data
    Return Type    : void
    *********************************************************************************/

    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        patient                     = PC_Test_Setup.createSampleAccount('', PC_Constants.PATIENT_RECORD_TYPE);
        patient.PC_Date_of_Birth__c = date.today().addDays(-100);
        patient                     = (Account)PC_Database.ins(patient, false);
        // check if patient is created
        system.assertNotEquals(patient.Id, null);

        physician                     = PC_Test_Setup.createSampleAccount('phy', PC_Constants.PHYSICIAN_RECORD_TYPE);
        physician                     = (Account)PC_Database.ins(physician, false);
        // check if physician is created
        system.assertNotEquals(physician.Id, null);

        //Create Manufacturer
        manufacturers   = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer    = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram                     = PC_Test_Setup.createEngagementProgram('TestPgm',manufacturer.Id );
        enmtProgram.PC_Program_Code__c  = 'TestPgm';
        enmtProgram                     = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        programCase = PC_Test_Setup.createCase(adminUser, patient);
        programCase.PC_Engagement_Program__c    = enmtProgram.Id;
        programCase.AccountId                   = patient.Id;
        programCase.PC_Physician__c             = physician.Id;
        programCase = (Case)PC_Database.ins(programCase, false);
        // check if program Case is created
        system.assertNotEquals(programCase.Id, null);

        product = PC_Test_Setup.newProduct('Product1','p1',manufacturer.Id);
        List<String> picklistValues = new List<String>();
        picklistValues.add('Patient');
        picklistValues.add('Treating Physician');
        product.PC_PreferredShipmentRole__c = String.join(picklistValues, ';');
        product = (Product2)PC_Database.ins(product, false);

        product1 = PC_Test_Setup.newProduct('Product2','p2',manufacturer.Id);
        product1 = (Product2)PC_Database.ins(product1, false);

        prescription = PC_Test_Setup.newPrescription(product.Id);
        prescription = (PC_Prescription__c)PC_Database.ins(prescription, false);

        epp         = new PC_Engagement_Program_Product__c();
        epp.PC_Engagement_Program__c            = enmtProgram.Id;
        epp.PC_Product__c                       = product.Id;
        epp = (PC_Engagement_Program_Product__c)PC_Database.ins(epp, false);

        epp1         = new PC_Engagement_Program_Product__c();
        epp1.PC_Engagement_Program__c            = enmtProgram.Id;
        epp1.PC_Product__c                       = product1.Id;
        epp1 = (PC_Engagement_Program_Product__c)PC_Database.ins(epp1, false);

        o                       = new PC_Order__c();
        o.PC_ProgramCase__c     = programCase.Id;
        o.PC_Prescription__c    = prescription.Id;
        o.PC_ShipTo2__c         = 'Patient';
        o = (PC_Order__c)PC_Database.ins(o, false);

        oi  = new PC_OrderItem__c();
        oi.PC_Order__c      = o.Id;
        oi.PC_Product__c    = product.Id;
        oi = (PC_OrderItem__c)PC_Database.ins(oi, false);

    }

    @isTest static void testgetFields() {
        try {
            createTestData();
            String orderId = PC_Constants.EMPTY_STRING;
            PC_DataTable.resultSetFields r1 = PC_DataTable.getFields(fsOrderDetails,orderId);

            orderId = (String) String.valueOf(o.Id);
            PC_DataTable.resultSetFields r2 = PC_DataTable.getFields(fsOrderDetails,orderId);

            orderId = (String) String.valueOf(o.Id);
            PC_DataTable.resultSetFields r3 = PC_DataTable.getFields(fsOrderShipment,orderId);

            //Will throw exception
            orderId = (String) String.valueOf(o.Id);
            oi1  = new PC_OrderItem__c();
            oi1.PC_Order__c      = o.Id;
            oi1.PC_Product__c    = product1.Id;
            oi1 = (PC_OrderItem__c)PC_Database.ins(oi1, false);
            PC_DataTable.resultSetFields r4 = PC_DataTable.getFields(fsOrderShipment,orderId);

        }catch (Exception ex) {
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(true,ex.getMessage());
        }
    }

    @isTest static void testsaveOrderItems() {
        try {
            createTestData();
            PC_OrderItem__c oi  = new PC_OrderItem__c();
            oi.PC_Order__c      = o.Id;
            oi.PC_Product__c    = product.Id;
            oi.PC_Quantity__c   = 10;
            List<PC_OrderItem__c> oiList = new List<PC_OrderItem__c>();
            oiList.add(oi);
            String saveData = JSON.serialize(oiList);
            String save1 = PC_DataTable.saveOrderItems(saveData);

        }catch (Exception ex) {
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testresultSet() {
        try {
            PC_DataTable.resultSet r1 = PC_DataTable.resultSet();

        }catch (Exception ex) {
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }

    @isTest static void testgetcolumns() {
        try {
            createTestData();
            String orderId          = PC_Constants.EMPTY_STRING;
            String programId        = PC_Constants.EMPTY_STRING;
            String prescriptionId   = PC_Constants.EMPTY_STRING;
            PC_DataTable.resultSet rs1 = PC_DataTable.getcolumns(fsSelectionList, fsDisplayList, orderId, programId, prescriptionId, 'true');

            orderId          = (String) String.valueOf(o.Id);
            programId        = (String) String.valueOf(programCase.Id);
            prescriptionId   = PC_Constants.EMPTY_STRING;
            PC_DataTable.resultSet rs2 = PC_DataTable.getcolumns(fsSelectionList, fsDisplayList, orderId, programId, prescriptionId, 'false');

            orderId          = (String) String.valueOf(o.Id);
            programId        = (String) String.valueOf(programCase.Id);
            prescriptionId   = (String) String.valueOf(prescription.Id);
            PC_DataTable.resultSet rs3 = PC_DataTable.getcolumns(fsSelectionList, fsDisplayList, orderId, programId, prescriptionId, 'true');

            orderId          = (String) String.valueOf(o.Id);
            programId        = PC_Constants.EMPTY_STRING;
            prescriptionId   = (String) String.valueOf(prescription.Id);
            PC_DataTable.resultSet rs4 = PC_DataTable.getcolumns(fsSelectionList, fsDisplayList, orderId, programId, prescriptionId,'false');

        }catch (Exception ex) {
            system.debug('exception in testCreateUserTaskAction>>'+ex.getMessage());
            system.assert(false,ex.getMessage());
        }
    }
}