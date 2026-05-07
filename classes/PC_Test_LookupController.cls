/*********************************************************************************
Class Name         :   PC_Test_LookupController
Description        :   Test Class for PC_LookupController
Created By         :   Haritha Reddy
Created Date       :   22-Nov-2019
Modification Log   :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          22-Nov-2019             [PC-5656] Initial Version
*********************************************************************************/
@isTest
public class PC_Test_LookupController {
    private static User adminUser;

    /*********************************************************************************
    Method Name    : createTestData
    Author         : Haritha Reddy
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/

    private static void createTestData() {

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        //Create Manufacturer
        Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
        manufacturer = (Account)PC_Database.ins(manufacturer, false);

        //Create Product
        Product2  product = PC_Test_Setup.newProduct('Product1', 'P1', manufacturer.Id);
        product = (Product2)PC_Database.ins(product, false);

    }

    @isTest
    static void testSearchDB() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_LookupController.searchDB(PC_Constants.PC_PRODUCT2, 'Name','Id',4,'Name','Product1');
        }
        Test.StopTest();
    }
}