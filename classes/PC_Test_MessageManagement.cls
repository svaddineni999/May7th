/*********************************************************************************
Class Name      : PC_Test_MessageManagement 
Description     : This test class for Message Management
Created By      : Deloitte
Created Date    : May 21, 2016
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Vasile Paraschiv               May 21, 2016              Initial Version
Ajinkya Deshmukh               Apr-12-2016               Updated test methods
Tejas Patel                    Apr-13-2017               Updated test methods, with assert statements
*********************************************************************************/
@isTest
public with sharing class PC_Test_MessageManagement { 
 
//@TODO: test the constructor somehow? crash the select to enter the catch branch?

    @isTest private static void testSendMessage() {
        Test.startTest();
        Account  patient = PC_Test_Setup.createPatient('testpatient');
        patient = (Account)PC_Database.ins(patient, false);
        //create case
        Case currentCase = PC_Test_Setup.newCase(patient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        
        currentCase.PC_Care_Coordinator__c = UserInfo.getUserId();   
        currentCase = (Case)PC_Database.ins(currentCase, false);
        Boolean result = PC_MessageManagementController.sendMessage('some test msg', (String) currentCase.Id);
        List<PC_Message__c> accountMessages = PC_MessageManagementController.getAccountMessages(currentCase.Id);
        Test.stopTest();
        System.AssertEquals(result, true);
        System.AssertEquals(accountMessages[0].PC_Case__c, currentCase.Id);
        System.AssertEquals(accountMessages[0].PC_Content__c, 'some test msg');
    }
    
    @isTest private static void testGetCaseMessages() {
        Test.startTest();
        Account  patient = PC_Test_Setup.createPatient('testpatient');
        patient = (Account)PC_Database.ins(patient, false);
        //create case
        Case currentCase = PC_Test_Setup.newCase(patient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        currentCase.PC_Care_Coordinator__c = UserInfo.getUserId();   
        currentCase = (Case)PC_Database.ins(currentCase, false);
        PC_MessageManagementController.sendMessage('some test msg', (String) currentCase.Id);	// Required to create the message
        List<PC_Message__c> caseMessages = PC_MessageManagementController.getCaseMessages((String)currentCase.Id);
        Test.stopTest();
        System.AssertNotEquals(caseMessages[0].Id, null);
        System.AssertEquals(caseMessages[0].PC_Content__c, 'some test msg');
        System.AssertEquals(caseMessages[0].PC_Source_Type__c, 'SMS');
        System.AssertEquals(caseMessages[0].PC_Type__c, 'Outbound');
    }
    @isTest private static void testGetAccountMessages() {
        Test.startTest();
        Account  patient = PC_Test_Setup.createPatient('testpatient');
        patient = (Account)PC_Database.ins(patient, false);
        //create case
        Case currentCase = PC_Test_Setup.newCase(patient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        currentCase.PC_Care_Coordinator__c = UserInfo.getUserId();
        currentCase = (Case)PC_Database.ins(currentCase, false);
        PC_MessageManagementController.sendMessage('some test msg2', (String) currentCase.Id);
        List<PC_Message__c> accountMessages = PC_MessageManagementController.getAccountMessages((String)currentCase.Id);
        Test.stopTest();
        System.AssertNotEquals(accountMessages[0].Id, null);
        System.AssertEquals(accountMessages[0].PC_Case__c, currentCase.Id);
        System.AssertEquals(accountMessages[0].PC_Content__c, 'some test msg2');
        System.AssertEquals(accountMessages[0].PC_Source_Type__c, 'SMS');
        System.AssertEquals(accountMessages[0].PC_Type__c, 'Outbound');
    }
    
    @isTest private static void testGetUserMessages() {
        Test.startTest();
        Account  patient = PC_Test_Setup.createPatient('testpatient');
        patient = (Account)PC_Database.ins(patient, false);
        //create case
        Case currentCase = PC_Test_Setup.newCase( patient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
        currentCase.PC_Care_Coordinator__c = UserInfo.getUserId();  
        currentCase = (Case)PC_Database.ins(currentCase, false);
        PC_MessageManagementController.sendMessage('some test msg3', (String) currentCase.Id);
        List<PC_Message__c> userMessages = PC_MessageManagementController.getUserMessages();
        Test.stopTest();
        System.AssertNotEquals(userMessages[0].Id, null);
        System.AssertEquals(userMessages[0].PC_Case__c, currentCase.Id);
        System.AssertEquals(userMessages[0].PC_Content__c, 'some test msg3');
        System.AssertEquals(userMessages[0].PC_Source_Type__c, 'SMS');
        System.AssertEquals(userMessages[0].PC_Type__c, 'Outbound');
    }
}