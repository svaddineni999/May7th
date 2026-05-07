/**************************************************************************************
Apex Class Name     : PC_Test_SubjectLine
Description         : This class is used to test Subject Line updation for enrollment case;
CreatedBy           : Tejas Patel
Created Date        : 27 Jun 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Tejas Patel                27 Jun 2019            Initial version
*************************************************************************************/

@isTest
public class PC_Test_SubjectLine {
    //Data variables
    private static Account patient;
    private static PC_Applicant__c applicant;
    private static Account manufacturer;
    private static PC_Engagement_Program__c enmtProgram;
    private static User objUser;
    private static Case enrollmentCase;

    //User
    private static String sUserName = 'user@t1234.com';
    private static String sAlias = 'test1';

    //Patient
    private static String sName = 'Test';
    private static String sEmail = 'tejapatel@test.com';

    //Manufacturer
    private static String pRootName = 'testmanufacturer';

    //Manufacturer
    private static String programName = 'TestPgm';

    @testSetup static void setupData() {
        //Create Patient
        patient                         = PC_Test_Setup.createPatient(sName);
        patient.PC_Email__c             = sEmail;
        patient.PC_Date_of_Birth__c     = Date.today();
        patient.PC_Gender__c            = 'Male';
        patient                         = (Account) PC_Database.ins(patient, false);

        //Create Active Applicant
        applicant                       = PC_Test_Setup.createApplicant(sName);
        applicant.PC_Date_of_Birth__c   = Date.today();
        applicant.PC_Gender__c          = 'Male';
        applicant                       = (PC_Applicant__c) PC_Database.ins(applicant, false);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts(pRootName, 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram(programName,manufacturer.Id );
        enmtProgram.PC_Program_Code__c = programName;
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

    }

    @isTest static void EnrollmentCaseCreation(){
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            Id caseRecordType = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
            enrollmentCase              = new Case();
            enrollmentCase.RecordTypeId = caseRecordType;
            Test.startTest();
            enrollmentCase = (Case) PC_Database.ins(enrollmentCase, false);
            system.assertNotEquals(enrollmentCase.Id, null);
            enrollmentCase = [SELECT ID, Subject,AccountId,PC_ActiveApplicant__c,PC_Engagement_Program__c , Type FROM Case WHERE Id = :enrollmentCase.Id];
            system.assertEquals(enrollmentCase.Subject, enrollmentCase.Type);
            system.assertEquals(enrollmentCase.AccountId, null);
            system.assertEquals(enrollmentCase.PC_ActiveApplicant__c, null);
            system.assertEquals(enrollmentCase.PC_Engagement_Program__c, null);

            //Update the case with engagement program.
            enmtProgram = [SELECT Id, Name FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];
            enrollmentCase.PC_Engagement_Program__c = enmtProgram.Id;
            enrollmentCase.PC_Engagement_Program__r = enmtProgram;

            enrollmentCase = (Case) PC_Database.upd(enrollmentCase, false);

            enrollmentCase = [SELECT ID, Subject,AccountId,PC_ActiveApplicant__c,PC_Engagement_Program__r.Name , Type FROM Case WHERE Id = :enrollmentCase.Id];

            system.assertEquals(enrollmentCase.Subject, enrollmentCase.PC_Engagement_Program__r.Name +' - '+ enrollmentCase.Type);

            //Update with Applicant
            applicant = [SELECT Id, PC_First_Name__c, PC_Last_Name__c FROM PC_Applicant__c LIMIT 1];
            enrollmentCase.PC_ActiveApplicant__c = applicant.Id;
            enrollmentCase.PC_ActiveApplicant__r = applicant;

            enrollmentCase = (Case) PC_Database.upd(enrollmentCase, false);

            enrollmentCase = [SELECT ID, Subject,PC_ActiveApplicant__r.PC_First_Name__c,PC_ActiveApplicant__r.PC_Last_Name__c,PC_Engagement_Program__r.Name , Type FROM Case WHERE Id = :enrollmentCase.Id];

            system.assertEquals(enrollmentCase.Subject, enrollmentCase.PC_ActiveApplicant__r.PC_Last_Name__c + ', ' + enrollmentCase.PC_ActiveApplicant__r.PC_First_Name__c +' - '+ enrollmentCase.PC_Engagement_Program__r.Name +' - '+ enrollmentCase.Type);

            //Update with Account
            patient = [SELECT Id, PC_First_Name__c, PC_Last_Name__c FROM Account LIMIT 1];
            enrollmentCase.AccountId = patient.Id;
            enrollmentCase.Account = patient;

            enrollmentCase = (Case) PC_Database.upd(enrollmentCase, false);

            enrollmentCase = [SELECT ID, Subject,Account.PC_First_Name__c,Account.PC_Last_Name__c,PC_Engagement_Program__r.Name , Type FROM Case WHERE Id = :enrollmentCase.Id];

            system.assertEquals(enrollmentCase.Subject, enrollmentCase.Account.PC_Last_Name__c + ', ' + enrollmentCase.Account.PC_First_Name__c +' - '+ enrollmentCase.PC_Engagement_Program__r.Name +' - '+ enrollmentCase.Type);

            Test.stopTest();
        }
    }
}