/**
 * Created by vkashikar on 7/10/2020.
 */

@IsTest
private class PC_Test_LaunchTaskActionComponent {
    @isTest static void testBehavior() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Account> accounts = PC_Test_Setup.createAccounts('Patient', 1, PC_Constants.PATIENT_RECORD_TYPE);
            List<Account> manufacturers = PC_Test_Setup.createAccounts('Manufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(accounts);
            PC_Database.ins(manufacturers);

            Case c = PC_Test_Setup.createProgram(accounts[0]);

            PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram('PRP', manufacturers[0].Id);
            PC_Database.ins(engagementProgram);

            c.PC_Engagement_Program__c = engagementProgram.Id;
            PC_Database.upd(c);

            Task t = new Task();
            t.PC_Channel__c = 'Call';
            t.Priority = 'Normal';
            t.Status = 'In Progress';
            t.PC_Assigned_To__c = adminUser.Id;
            PC_Database.ins(t);
            PC_LaunchTaskActionComponent.TaskActionDetails ret = PC_LaunchTaskActionComponent.getActionComponent(t.Id);
            system.assert(ret == null);

            Task t2 = new Task();
            t2.PC_ActionComponent__c = 'PatientConnect__PC_eLetter2';
            t2.PC_Channel__c = 'Call';
            t2.Priority = 'Normal';
            t2.Status = 'In Progress';
            t2.PC_Assigned_To__c = adminUser.Id;
            t2.WhatId = c.Id;
            PC_Database.ins(t2);
            PC_LaunchTaskActionComponent.TaskActionDetails ret2 = PC_LaunchTaskActionComponent.getActionComponent(t2.Id);
            system.assert(ret2 != null);

            try {
                PC_LaunchTaskActionComponent.TaskActionDetails ret3 = PC_LaunchTaskActionComponent.getActionComponent('invalidId');
            }
            catch (Exception ex) {
                system.assert(true);
            }

        }
    }
}