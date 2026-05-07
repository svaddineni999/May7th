/**************************************************************************************
Apex Class Name     : PC_Test_WorkCaseRedistribution
Description         : This class is used for testing Work Case Redistribution
CreatedBy           : Satheesh Kumar
Created Date        : 12 May 2022
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Satheesh Kumar            12 May 2022             Initial version
*************************************************************************************/
@isTest(seeAllData=false)
public with sharing class PC_Test_WorkCaseRedistribution {
    //Record Number
    private static Integer manufacturerNumber = 1;

    //Data variables
    private static String zipCode1 = '5001';
    private static String zipCode2 = '5002';

    private static Account patient;
    private static PC_Address__c patientAddress;

    private static Account physician;
    private static PC_Address__c physicianAddress;

    //Patient
    private static String patientName = 'TestPatient';
    private static String patientEmail = 'sathkum@testpatient.com';

    //Physician
    private static String physicianName = 'TestPhy';
    private static String physicianEmail = 'sathkum@testphy.com';

    //Manufacturer
    private static Account manufacturer;
    private static String pRootName = 'testmanufacturer';

    private static PC_Engagement_Program__c enmtProgram1;
    private static PC_Engagement_Program__c enmtProgram2;
    private static PC_Engagement_Program__c enmtProgram3;

    private static ID patientId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
    private static ID physicianId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PHYSICIAN_RECORD_TYPE);

    private static Datetime effectiveFrom = System.now().addDays(-1);
    private static DateTime effectiveTo = System.now().addDays(10);

    private static Datetime startDateTime = System.now().addDays(-1);
    private static DateTime endDateTime = System.now().addDays(2);

    //User
    private static String sUserName = 'user@wcdredis.com';
    private static String sUserName2 = 'user2@wcdredis.com';
    private static String sAlias = 'tuser1';
    private static String sAlias2 = 'tuser2';


    //Engagement Program
    private static String programName1 = 'TestPgm';
    private static String programName2 = 'TestPgm2';
    private static String programName3 = 'TestPgm3';

    //Work Case Distribution
    private static PC_WorkCaseDistributionConfig__c wcdConfig;
    private static List<PC_WorkCaseDistributionConfig__c> wcdConfigList = new List<PC_WorkCaseDistributionConfig__c>();

    private static List<PC_Region__c> regions = new List<PC_Region__c>();
    private static List<PC_RegionZipCode__c> regionZipCodes = new List<PC_RegionZipCode__c>();
    private static List<PC_ProgramRegionUserMapping__c> programRegionUserMappings = new List<PC_ProgramRegionUserMapping__c>();
    private static List<PC_ProgramRegionUserHistory__c> programRegionUserHistories = new List<PC_ProgramRegionUserHistory__c>();
    private static PC_Region__c region;
    private static PC_RegionZipCode__c regionZipCode;
    private static PC_ProgramRegionUserMapping__c programRegionUserMapping;
    private static PC_ProgramRegionUserHistory__c programRegionUserHistory;

    private static User careCoordinator1;
    private static User careCoordinator2;
    private static User reimbursementSpecialist1;
    private static User reimbursementSpecialist2;
    private static User frmUser1;
    private static User frmUser2;

    private static User objUser;
    private static User objUser2;


    @testSetup static void setupData() {
        //Create Patient
        patient                         = PC_Test_Setup.createPatient(patientName);
        patient.PC_Email__c             = patientEmail;
        patient.PC_Date_of_Birth__c     = Date.today();
        patient.PC_Gender__c            = 'Male';
        patient                         = (Account) PC_Database.ins(patient, false);

        //Create Address
        patientAddress                  = PC_Test_Setup.createAddress(patient.Id);
        patientAddress.PC_Zip_Code__c   = '';
        patientAddress                  = (PC_Address__c) PC_Database.ins(patientAddress, false);

        //Create Physician
        physician                       = PC_Test_Setup.createAccount(physicianName, physicianId);
        physician.PC_Email__c           = physicianEmail;
        physician.PC_Date_of_Birth__c   = Date.today();
        physician.PC_Gender__c          = 'Male';
        physician.PC_Specialist_Type__c = 'Cardiologist';
        physician.Type                  = 'Specialist';
        physician.PC_Sub_Type__c        = 'Other';
        physician                       = (Account) PC_Database.ins(physician, false);

        //Create Address
        physicianAddress                  = PC_Test_Setup.createAddress(physician.Id);
        physicianAddress.PC_Zip_Code__c   = '';
        physicianAddress                  = (PC_Address__c) PC_Database.ins(physicianAddress, false);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts(pRootName, manufacturerNumber, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram1= PC_Test_Setup.createEngagementProgram(programName1,manufacturer.Id );
        enmtProgram1.PC_Program_Code__c = programName1;
        enmtProgram1 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram1, false);

        //enmtProgram2
        enmtProgram2= PC_Test_Setup.createEngagementProgram(programName2,manufacturer.Id );
        enmtProgram2.PC_Program_Code__c = programName2;
        enmtProgram2 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram2, false);

        //enmtProgram3
        enmtProgram3= PC_Test_Setup.createEngagementProgram(programName3,manufacturer.Id );
        enmtProgram3.PC_Program_Code__c = programName3;
        enmtProgram3 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram3, false);


        //Create Care Coordinator
        careCoordinator1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinator1@test.com', 'care1');
        careCoordinator1 = (User) PC_Database.ins(careCoordinator1);

        careCoordinator2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinator2@test.com', 'care2');
        careCoordinator2 = (User) PC_Database.ins(careCoordinator2);

        //Create Reimbursement Specialist
        reimbursementSpecialist1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'reimbursementspecialist1@test.com', 'rs1');
        reimbursementSpecialist1 = (User) PC_Database.ins(reimbursementSpecialist1);

        reimbursementSpecialist2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'reimbursementspecialist2@test.com', 'rs2');
        reimbursementSpecialist2 = (User) PC_Database.ins(reimbursementSpecialist2);

        //Create FRM User
        frmUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'frm1@test.com', 'frm1');
        frmUser1 = (User) PC_Database.ins(frmUser1);

        frmUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'frm2@test.com', 'frm2');
        frmUser2 = (User) PC_Database.ins(frmUser2);


        //Create Region record
        /**
         *
         *  Region Name     Zip Code
         *  East5001	    5001
         *  West5002	    5002
         */
        region =   new PC_Region__c();
        region.Name                     = 'East';
        region.PC_Manufacturer__c       = manufacturer.Id;
        region.PC_EffectiveFromTime__c  = effectiveFrom;
        region.PC_EffectiveToTime__c    = effectiveTo;
        region.PC_Active__c             = true;

        regions.add(region);

        region =   new PC_Region__c();
        region.Name                     = 'West';
        region.PC_Manufacturer__c       = manufacturer.Id;
        region.PC_EffectiveFromTime__c  = effectiveFrom;
        region.PC_EffectiveToTime__c    = effectiveTo;
        region.PC_Active__c             = true;

        regions.add(region);
        regions = (List<PC_Region__c>)PC_Database.ins(regions, false);

        //Create RegionZipCode record
        /**
         *
         *  Region Zip Code Name        Region      Zip Code
         *  East5001	                East        5001
         *  West5002	                West        5002
         */
        List<PC_Region__c> fetchedregion   =  [Select Id, Name from PC_Region__c where PC_Manufacturer__c = :manufacturer.Id];
        system.assertEquals(fetchedregion.size(), 2);

        regionZipCode   =   new PC_RegionZipCode__c();
        regionZipCode.Name          = fetchedregion[0].Name + zipCode1;
        regionZipCode.PC_ZipCode__c = zipCode1;
        regionZipCode.PC_Region__c  = fetchedregion[0].Id;
        regionZipCodes.add(regionZipCode);

        regionZipCode   =   new PC_RegionZipCode__c();
        regionZipCode.Name          = fetchedregion[1].Name + zipCode2;
        regionZipCode.PC_ZipCode__c = zipCode2;
        regionZipCode.PC_Region__c  = fetchedregion[1].Id;
        regionZipCodes.add(regionZipCode);

        regionZipCodes = (List<PC_RegionZipCode__c>)PC_Database.ins(regionZipCodes, false);

        //Create Program Region User Mapping
        //Patient Flow
        /**
         *
         *  East5001	PC_ROLE_REIMBURSEMENT_SPECIALIST		TestPgm			RS1
         *  East5001	PC_ROLE_CARE_COORDINATOR				TestPgm			CC1

         *  West5002	PC_ROLE_REIMBURSEMENT_SPECIALIST		TestPgm			RS2
         *  West5002	PC_ROLE_CARE_COORDINATOR				TestPgm         CC2
         *
         */
        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist1.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram1.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator1.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram1.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram1.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram1.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        //Physician Flow
        /**
         *
         *  East5001	PC_ROLE_REIMBURSEMENT_SPECIALIST		TestPgm2		RS1
         *  East5001	PC_ROLE_CARE_COORDINATOR				TestPgm2		CC1
         *
         *  West5002	PC_ROLE_REIMBURSEMENT_SPECIALIST		TestPgm2		RS2
         *  West5002	PC_ROLE_CARE_COORDINATOR				TestPgm2		CC2
         */
        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist1.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram2.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator1.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram2.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram2.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram2.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);


        // Care Coordinator Role
        /**
         *
         *  East5001	PC_ROLE_FRM								TestPgm3		FRM1
         *  East5001	PC_ROLE_REIMBURSEMENT_SPECIALIST		TestPgm3		RS1
         *
         *  West5002	PC_ROLE_FRM								TestPgm3		FRM2
         *  West5002	PC_ROLE_REIMBURSEMENT_SPECIALIST		TestPgm3		RS2
         *
         */
        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist1.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram3.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = frmUser1.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram3.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram3.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = frmUser2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram3.Id;
        programRegionUserMapping.PC_StartDateTime__c       = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c         = endDateTime;
        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMappings = (List<PC_ProgramRegionUserMapping__c>)PC_Database.ins(programRegionUserMappings, false);


        //Create WCD record
        /**
         *  Engagement Pgm      Assignemnt Type             Assignment Role         Assign Lookup Field
         *  ----------------  ---------------------   -------------------------   -------------------------------
         *  TestPgm				Patient												PC_Primary_Zip_Code__c
         *  TestPgm2			Association					Treating Physician		Account.PC_Primary_Zip_Code__c
         *  TestPgm3			Association					Care Coordinator		User.PostalCode
         */
        wcdConfig  =   new PC_WorkCaseDistributionConfig__c();
        wcdConfig.PC_EngagementProgram__c      = enmtProgram1.Id;
        wcdConfig.PC_AssignmentType__c         = 'Patient';
        wcdConfig.PC_AssignmentLookupField__c  = PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c');
        wcdConfigList.add(wcdConfig);

        wcdConfig  =   new PC_WorkCaseDistributionConfig__c();
        wcdConfig.PC_EngagementProgram__c      = enmtProgram2.Id;
        wcdConfig.PC_AssignmentType__c         = 'Association';
        wcdConfig.PC_AssociationRole__c        = 'Treating Physician';
        wcdConfig.PC_AssignmentLookupField__c  = 'Account.'+PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c');
        wcdConfigList.add(wcdConfig);

        wcdConfig  =   new PC_WorkCaseDistributionConfig__c();
        wcdConfig.PC_EngagementProgram__c      = enmtProgram3.Id;
        wcdConfig.PC_AssignmentType__c         = 'Association';
        wcdConfig.PC_AssociationRole__c        = 'Care Coordinator';
        wcdConfig.PC_AssignmentLookupField__c  = 'User.PostalCode';
        wcdConfigList.add(wcdConfig);
        PC_Database.ins(wcdConfigList, false);
    }


    //WCD is active for Patient
    @isTest static void triggerWCDByPatient() {
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient = [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            enmtProgram1 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName1 LIMIT 1];
            Case caseOne = PC_Test_Setup.createCase(objUser, patient);
            caseOne.PC_Engagement_Program__c = enmtProgram1.Id;

            Test.startTest();
            //Create Case
            caseOne = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);

            // Check trigger handler register is active or not
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerList = new List<PC_TriggerHandlerRegister__mdt>();
            triggerHandlerList = [
                    SELECT PC_ApexClass__c,PC_Active__c
                    FROM PC_TriggerHandlerRegister__mdt
                    WHERE PC_ApexClass__c = 'PC_WorkCaseRedistributionForAddrHandler' AND PC_Active__c = true
            ];

            if(triggerHandlerList.size() > 0) {
                // Update Patient Zip - Trigger WCD Redistribution workflow
                List<PC_Address__c> addressList = [Select PC_Zip_Code__c from PC_Address__c where PC_Account__c = :patient.Id and PC_Primary_Address__c = :PC_Constants.TRUE_BOOLEAN];
                if (addressList.size() > 0) {
                    addressList[0].PC_Zip_Code__c = zipCode1;
                    PC_Database.upd(addressList[0], false);

                    caseOne = [SELECT PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];
                    careCoordinator1 = [SELECT Id, email FROM User WHERE email = 'carecoordinator1@test.com'];
                    reimbursementSpecialist1 = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist1@test.com'];

                    system.assertEquals(caseOne.PC_Care_Coordinator__c, careCoordinator1.Id);
                    system.assertEquals(caseOne.PC_Reimbursment_Specialist__c, reimbursementSpecialist1.Id);
                }
            }
            Test.stopTest();
        }
    }

    //WCD is active for Physician
    @isTest static void triggerWCDByPhysician() {
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient = [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            physician = [SELECT ID FROM Account WHERE RecordTypeId = :physicianId LIMIT 1];
            enmtProgram2 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName2 LIMIT 1];
            Case caseOne = PC_Test_Setup.createCase(objUser, patient);
            caseOne.PC_Engagement_Program__c = enmtProgram2.Id;
            caseOne.PC_Physician__c = physician.Id;

            Test.startTest();
            //Create Case
            caseOne = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);

            // Check trigger handler register is active or not
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerList = new List<PC_TriggerHandlerRegister__mdt>();
            triggerHandlerList = [
                    SELECT PC_ApexClass__c,PC_Active__c
                    FROM PC_TriggerHandlerRegister__mdt
                    WHERE PC_ApexClass__c = 'PC_WorkCaseRedistributionForAddrHandler' AND PC_Active__c = true
            ];

            if(triggerHandlerList.size() > 0) {
                // Update Patient Zip - Trigger WCD Redistribution workflow
                List<PC_Address__c> addressList = [Select PC_Zip_Code__c from PC_Address__c where PC_Account__c = :physician.Id and PC_Primary_Address__c = :PC_Constants.TRUE_BOOLEAN];
                if (addressList.size() > 0) {
                    addressList[0].PC_Zip_Code__c = zipCode1;
                    PC_Database.upd(addressList[0], false);

                    caseOne = [SELECT PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];
                    careCoordinator1 = [SELECT Id, email FROM User WHERE email = 'carecoordinator1@test.com'];
                    reimbursementSpecialist1 = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist1@test.com'];

                    system.assertEquals(caseOne.PC_Care_Coordinator__c, careCoordinator1.Id);
                    system.assertEquals(caseOne.PC_Reimbursment_Specialist__c, reimbursementSpecialist1.Id);
                }
            }
            Test.stopTest();
        }
    }


    //WCD is active for User (Care Coordinator)
    @isTest static void triggerWCDByUser() {
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            //Create User for Case Care Coordinator
            objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName2, sAlias2);
            objUser2 = (User) PC_Database.ins(objUser2);
            patient = [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            enmtProgram3 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName3 LIMIT 1];
            Case caseOne = PC_Test_Setup.createCase(objUser, patient);
            caseOne.PC_Engagement_Program__c = enmtProgram3.Id;
            caseOne.PC_Care_Coordinator__c = objUser2.Id;

            Test.startTest();
            //Create Case
            caseOne = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);

            // Check trigger handler register is active or not
            List<PC_TriggerHandlerRegister__mdt> triggerHandlerList = new List<PC_TriggerHandlerRegister__mdt>();
            triggerHandlerList = [
                    SELECT PC_ApexClass__c,PC_Active__c
                    FROM PC_TriggerHandlerRegister__mdt
                    WHERE PC_ApexClass__c = 'PC_WorkCaseRedistributionForUserHandler' AND PC_Active__c = true
            ];

            if(triggerHandlerList.size() > 0) {
                // Update Patient Zip - Trigger WCD Redistribution workflow
                objUser2.PostalCode = zipCode1;
                PC_Database.upd(objUser2, false);

                caseOne = [SELECT PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];
                reimbursementSpecialist1 = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist1@test.com'];
                system.assertEquals(caseOne.PC_Reimbursment_Specialist__c, reimbursementSpecialist1.Id);

                frmUser1 = [SELECT Id, email FROM User WHERE email = 'frm1@test.com'];
                List<PC_Association__c> frmAssociations = [SELECT Id, PC_Program__c, PC_Associated_User__c, PC_Role__c FROM PC_Association__c WHERE PC_Program__c = :caseOne.Id AND PC_AssociationStatus__c = :PC_Constants.ACTIVE AND PC_Role__c = :PC_Constants.ROLE_FIELD_REIMBURSEMENT_MANAGER ORDER BY CreatedDate DESC];
                if (frmAssociations.size() > 0) {
                    system.assertEquals(frmAssociations[0].Id, frmUser1.Id);
                }
            }
            Test.stopTest();
        }
    }
}