/*********************************************************************************
Class Name          : PC_Test_SearchFormController
Description         : Test Class for PC_SearchFormController Class
Created By          : Haritha Reddy
Created Date        : 16-Nov-2019
Modification Log    :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          16-Nov-2019              Initial Version
*********************************************************************************/
@isTest
public class PC_Test_SearchFormController {

    private static User adminUser;
    private static String fieldSetName;

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
        fieldSetName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_PRE_ENROLLMENT_SEARCH,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardSearch'));

    }

    @isTest
    static void testGetInitData() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_SearchFormController.getInitData(PC_Constants.PC_ACCOUNT,fieldSetName);
        }
        Test.StopTest();
    }

}