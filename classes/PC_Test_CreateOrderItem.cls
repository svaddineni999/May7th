/**************************************************************************************
Apex Class Name     : PC_Test_CreateOrderItem
Description         : This class is used for testing PC_CreateOrderItem;
CreatedBy           : Tejas Patel
Created Date        : 09 July 2020
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Tejas Patel                 09 July 2020           Initial version
*************************************************************************************/
@isTest
public class PC_Test_CreateOrderItem {

    private static User adminUser;
    public static Boolean isTriggerActive = PC_TriggerHandlerHelper.getTriggerState('PC_Order__c', 'PC_CreateOrderItem');
    public static PC_Prescription__c newPrescription;
    public static Product2 product;

    static void createTestData() {
        Account manufacturer = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account) PC_Database.ins( manufacturer);

        product = PC_Test_Setup.newProduct('TestProduct', 'P1', manufacturer.Id);
        product.PC_NDC__c = '24542131';
        product.PC_Strength__c = '50';
        product = (Product2) PC_Database.ins( product);

        newPrescription = PC_Test_Setup.newPrescription(product.Id);
        newPrescription = (PC_Prescription__c) PC_Database.ins( newPrescription);
    }

    /*********************************************************************************
    Method Name    : testInsertWithProduct
    Author         : Tejas Patel
    Description    : This method is used for testing createOrderItem on PC_CreateOrderItem
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest
    static void testInsertWithProduct() {
        if (isTriggerActive) {
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);

            createTestData();

            PC_Order__c orderObj = new PC_Order__c();
            orderObj.PC_Prescription__c = newPrescription.Id;

            List<PC_OrderItem__c> orderItem ;

            Test.StartTest();
            system.runAs(adminUser) {
                orderObj = (PC_Order__c) PC_Database.ins(orderObj);
                orderItem = [SELECT ID, PC_Product__c, PC_Order__c, PC_NDC__c, PC_Strength__c, PC_DaysSupply__c, PC_Quantity__c FROM PC_OrderItem__c];
            }
            system.assertEquals(orderObj.PC_Prescription__c, newPrescription.Id);
            system.assertEquals(orderItem.size(), 1);
            system.assertEquals(orderItem[0].PC_Product__c, product.Id);
            system.assertEquals(orderItem[0].PC_Order__c, orderObj.Id);
            system.assertEquals(orderItem[0].PC_NDC__c, product.PC_NDC__c);
            system.assertEquals(orderItem[0].PC_Strength__c, product.PC_Strength__c);
            system.assertEquals(orderItem[0].PC_DaysSupply__c, newPrescription.PC_Days_Supply__c);
            system.assertEquals(orderItem[0].PC_Quantity__c, newPrescription.PC_Requested_Quantity__c);
            Test.StopTest();
        }
    }
}