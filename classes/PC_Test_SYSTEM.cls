/*********************************************************************************************************
Class Name      : PC_Test_SYSTEM
Description     : Test class for PC_SYSTEM
Created Date    : Mar 25, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy      Mar 25, 2021         [PC-7010] Initial Version
Vijay Kashikar     Jul 06, 2022         [PC-8908] Test methods to test getPatientConnectSettings() and getIntegrationSettings()
***************************************************************************************************************/
@isTest
public with sharing class PC_Test_SYSTEM {
    private static User adminUser;
    /**
    * This methods verifies the retrieval of TriggerHandlerRegisters
    */
    @isTest static void testGetTriggerHandlerRegisters() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList1 = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_ERROR_LOG_INFO_HANDLER,PC_Constants.PC_ERROR_LOG_INFO,null);
            System.assert(triggerHandlerRegisterList1.size()>0);
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList2 = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_CASE,null);
            System.assert(triggerHandlerRegisterList2.size()>0);
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerRegisterList3 = PC_SYSTEM.getTriggerHandlerRegisters(PC_Constants.PC_ERROR_LOG_INFO, null);
            System.assert(triggerHandlerRegisterList3.size()>0);
            Test.stopTest();
        }
    }

    @isTest static void testGetEngagementProgramSetting() {
        // Create Admin User
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'testAdminUser1@test.com', 'test1');
        PC_Database.ins(adminUser);
        User adminUser1 = [Select Id from User WHERE username = 'testAdminUser1@test.com'];
        System.runAs(adminUser1) {
            Test.StartTest();

            String settingValue1 = PC_SYSTEM.getSettingByEngagementProgram('PRP_RIB', 'Non_Existent_Setting', PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING, 'Default Value1');
            System.assertEquals(settingValue1, 'Default Value1');

            String settingValue2 = PC_SYSTEM.getSettingByEngagementProgram('PRP_RIB', 'Non_Existent_Setting', PC_Constants.SETTINGS_TYPE.INTEGRATION_SETTING, 'Default Value1');
            System.assertEquals(settingValue2, 'Default Value1');

            String settingValue3 = PC_SYSTEM.getSettingByEngagementProgram('PRP_RIB', 'Non_Existent_Setting', NULL, 'Default Value1');
            System.assertEquals(settingValue3, 'Default Value1');

            Test.stopTest();
        }
    }
    @isTest static void testLongPatientConnectSetting() {
        String longValue = PC_SYSTEM.getPatientConnectSetting('PC_AccountToApplicantMapping','');
        if(longValue.length() > 255) {
            system.assert(System.Limits.getQueryRows() == 1,
                    'Expected only one SOQL if the setting value is greater than 255 characters');
        }
        else {
            system.assert(System.Limits.getQueryRows() == 0,
                    'Expected zero SOQLs if the setting value is lesser than 255 characters');
        }
    }
    @isTest static void testShortPatientConnectSetting() {
        String shortValue = PC_SYSTEM.getPatientConnectSetting('PC_EnableWorkCaseDistribution','');
        system.assert(System.Limits.getQueryRows() == 0,
                'Expected zero SOQLs if the setting value is lesser than 255 characters');
        system.assert(shortValue.length() < 255);
    }
    @isTest static void testInvalidPatientConnectSetting() {
        String value = PC_SYSTEM.getPatientConnectSetting('PC_Invalid','invalid');
        system.assert(System.Limits.getQueryRows() == 0,
                'Expected zero SOQLs since the setting was invalid');
        system.assert(value == 'invalid');
    }
    @isTest static void testShortIntegrationSetting() {
        String shortValue = PC_SYSTEM.getIntegrationSetting('PC_TwilioAccountSid','');
        system.assert(System.Limits.getQueryRows() == 0,
                'Expected zero SOQLs if the setting value is lesser than 255 characters');
        system.assert(shortValue.length() < 255);
    }
    @isTest static void testInvalidIntegrationSetting() {
        String value = PC_SYSTEM.getPatientConnectSetting('PC_Invalid','invalid');
        system.assert(System.Limits.getQueryRows() == 0,
                'Expected zero SOQLs since the setting was invalid');
        system.assert(value == 'invalid');
    }
    @isTest static void test_PC_PersonAccountPatientNamespaceSettingName() {
        String value = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_PersonAccountPatientNamespaceSettingName,PC_Constants.PC_PersonAccountPatientNamespaceDefaultSettingValue);
        system.assert(System.Limits.getQueryRows() == 0,
                'Expected zero SOQLs if the setting value is lesser than 255 characters');
        system.assert(value == PC_Constants.PC_PersonAccountPatientNamespaceDefaultSettingValue || value.equalsIgnoreCase(PC_Constants.OrgNamespace));
    }
}