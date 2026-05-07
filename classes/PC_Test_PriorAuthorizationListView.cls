/**
* Class Name      : PC_Test_PriorAuthorizationListView
* Created By      : Tejas Patel
* @Created Date   : Aug 24, 2017
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Tejas Patel		   24-Aug-2017			Initial Version
*/

@isTest
public class PC_Test_PriorAuthorizationListView {
    private static User adminUser;
    
    @isTest static void testMethodPA() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            PC_PriorAuthorizationListView.FieldLabels fieldlabels =  PC_PriorAuthorizationListView.getFieldLabels();
            system.assertEquals(fieldlabels.paID, System.Label.PC_PA_Number);
            
            ID paRecType =  PC_PriorAuthorizationListView.getPARecordTypeId(PC_Constants.PC_CASE);
            system.assertEquals(paRecType, PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_PA_RECORD_TYPE));
            
            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ins(patient, false);
            // patient is created
            system.assertNotEquals(patient.Id, null);
            
            Case programCase = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            programCase = (Case)PC_Database.ins(programCase, false);
            // Program Case is created
            system.assertNotEquals(programCase.Id, null);
            
            Case paCase1 = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PA_RECORD_TYPE);
            paCase1.PC_Program__c = programCase.Id;
            paCase1.PC_PA_Status__c = PC_Constants.PA_CASE_STATUS_Denied;
            paCase1 = (Case)PC_Database.ins(paCase1, false);
            // PA Case is created with Status Denied
            system.assertNotEquals(paCase1.Id, null);
            system.assertEquals(paCase1.PC_Program__c, programCase.Id);
            
            boolean activePA1 = PC_PriorAuthorizationListView.isPACaseActive(programCase.Id);
            system.assertEquals(activePA1, false);
            
            Case paCase2 = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PA_RECORD_TYPE);
            paCase2.PC_Program__c = programCase.Id;
            paCase2.PC_PA_Status__c = PC_Constants.PA_CASE_STATUS_Approved;
            paCase2 = (Case)PC_Database.ins(paCase2, false);
            // PA Case is created with Status Accepted
            system.assertNotEquals(paCase2.Id, null);
            system.assertEquals(paCase2.PC_Program__c, programCase.Id);
            
            boolean activePA2 = PC_PriorAuthorizationListView.isPACaseActive(programCase.Id);
            system.assertEquals(activePA2, true);
            
            LIST<PC_PriorAuthorizationListView.PAWrapper> painfo =  PC_PriorAuthorizationListView.getPARecords(programCase.Id);
            system.assertEquals(painfo.size(), 2);
            Test.StopTest();
        }
    }
}