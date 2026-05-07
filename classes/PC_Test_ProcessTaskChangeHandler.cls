/**
 * Created by vkashikar on 7/16/2021.
 */

@IsTest
private class PC_Test_ProcessTaskChangeHandler {
    static User adminUser;
    @isTest static void testBehavior() {
        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        Account patient = PC_Test_Setup.createPatient('patient');
        PC_Database.ups(patient);

        Case programCase = PC_Test_Setup.createProgram(patient);
        PC_Database.ups(programCase);

        List<Task> tasks = PC_Test_Setup.createTasks(programCase, 10);
        tasks[0].Subject = '';
        String expectedTask0Subject = '';

        tasks[1].Subject = '';
        tasks[1].PC_Channel__c = null;
        tasks[1].PC_Category__c = 'Appeal';
        String expectedTask1Subject = tasks[1].PC_Category__c;

        tasks[2].Subject = '';
        tasks[2].PC_Category__c = 'Appeal';
        String expectedTask2Subject = tasks[2].PC_Category__c + ' ' + tasks[2].PC_Channel__c;

        tasks[3].Subject = '';
        tasks[3].PC_Category__c = 'Appeal';
        tasks[3].PC_Sub_Category__c = 'Follow up';
        String expectedTask3Subject = tasks[3].PC_Category__c + ' ' + tasks[3].PC_Sub_Category__c + ' ' + tasks[3].PC_Channel__c;

        tasks[4].Subject = '';
        tasks[4].PC_Category__c = 'Appeal';
        tasks[4].PC_Channel__c = null;
        tasks[4].PC_Sub_Category__c = 'Follow up';
        String expectedTask4Subject = tasks[4].PC_Category__c + ' ' + tasks[4].PC_Sub_Category__c;


        tasks[5].Status = 'Completed';

        PC_Database.ups(tasks);


        System.runAs(adminUser) {
            Test.startTest();
            List<Task> updatedTasks = [SELECT ID, Subject, PC_Program__c, PC_Close_Date__c FROM Task LIMIT 10];

            system.assert(String.isBlank(updatedTasks[0].Subject));
            system.assert(updatedTasks[1].Subject == expectedTask1Subject);
            system.assert(updatedTasks[2].Subject == expectedTask2Subject);
            system.assert(updatedTasks[3].subject == expectedTask3Subject);
            system.assert(updatedTasks[4].subject == expectedTask4Subject);
            system.assert(updatedTasks[0].PC_Program__c == programCase.Id);

            updatedTasks[0].Status = 'Completed';
            PC_Database.upd(updatedTasks[0]);

            List<Task> completedTasks = [SELECT ID, Subject, PC_Program__c, PC_Close_Date__c FROM Task WHERE Status = 'Completed' LIMIT 1];
            system.assert(completedTasks[0].PC_Close_Date__c <= System.now());

            Test.stopTest();

        }
    }
}