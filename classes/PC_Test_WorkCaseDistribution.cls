/**************************************************************************************
Apex Class Name     : PC_Test_WorkCaseDistribution
Description         : This class is used for testing Work Case Distribution;
CreatedBy           : Tejas Patel
Created Date        : 26 Jun 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Tejas Patel                26 Jun 2019            Initial version
Hitha Avalakki             27 Nov,2019            [PC-5757] Added a LIMIT to query in UserCase3() method
*************************************************************************************/
@isTest(seeAllData=false)
public with sharing class PC_Test_WorkCaseDistribution {
    //Record Number
    private static Integer manufacturerNumber = 1;

    //Data variables
    private static String zipCode1 = '02621';
    private static String zipCode2 = '02623';
    private static String zipCode3 = '02624';
    private static String zipCode4 = '02625';

    private static Account patient;
    private static PC_Address__c patientAddress;

    private static Account physician;
    private static PC_Address__c physicianAddress;

    private static Account manufacturer;
    private static PC_Engagement_Program__c enmtProgram;
    private static PC_Engagement_Program__c enmtProgram2;
    private static PC_Engagement_Program__c enmtProgram3;
    private static PC_Engagement_Program__c enmtProgram4;
    private static User objUser;
    private static User objUser2;
    private static Case caseOne;
    private static Case caseTwo;
    private static ID patientId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
    private static ID physicianId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PHYSICIAN_RECORD_TYPE);

    private static Datetime effectiveFrom = System.now().addDays(-1);
    private static DateTime effectiveTo = System.now().addDays(10);

    private static Datetime startDateTime = System.now().addDays(-1);
    private static DateTime endDateTime = System.now().addDays(2);

    //User
    private static String sUserName = 'user@t1234.com';
    private static String sUserName2 = 'user@t12345.com';
    private static String sAlias = 'test1';
    private static String sAlias2 = 'test2';

    //Patient
    private static String sName = 'Test';
    private static String sEmail = 'tejapatel@test.com';

    //Manufacturer
    private static String pRootName = 'testmanufacturer';

    //Manufacturer
    private static String programName = 'TestPgm';
    private static String programName2 = 'TestPgm2';
    private static String programName3 = 'EPTest'; //TestPgm3
    private static String programName4 = 'TestPgm4';

    //Work Case Distribution
    private static PC_WorkCaseDistributionConfig__c wcdConfig;
    private static PC_WorkCaseDistributionConfig__c wcdConfig2;
    private static List<PC_Region__c> regions = new List<PC_Region__c>();
    private static PC_Region__c region;
    private static List<PC_RegionZipCode__c> regionZipCodes = new List<PC_RegionZipCode__c>();
    private static PC_RegionZipCode__c regionZipCode;
    private static List<PC_ProgramRegionUserMapping__c> programRegionUserMappings = new List<PC_ProgramRegionUserMapping__c>();
    private static List<PC_ProgramRegionUserHistory__c> programRegionUserHistories = new List<PC_ProgramRegionUserHistory__c>();
    private static PC_ProgramRegionUserMapping__c programRegionUserMapping;
    private static PC_ProgramRegionUserHistory__c programRegionUserHistory;

    private static User careCoordinator;
    private static User careCoordinator2;
    private static User careCoordinator3;
    private static User careCoordinator4;
    private static User reimbursementSpecialist;


    @testSetup static void setupData() {
        //Create Patient
        patient                         = PC_Test_Setup.createPatient(sName);
        patient.PC_Email__c             = sEmail;
        patient.PC_Date_of_Birth__c     = Date.today();
        patient.PC_Gender__c            = 'Male';
        patient                         = (Account) PC_Database.ins(patient, false);

        //Create Address
        patientAddress                  = PC_Test_Setup.createAddress(patient.Id);
        patientAddress.PC_Zip_Code__c   = zipCode1;
        patientAddress                  = (PC_Address__c) PC_Database.ins(patientAddress, false);

        //Create Physician
        physician                       = PC_Test_Setup.createAccount(sName, physicianId);
        physician.PC_Email__c           = sEmail;
        physician.PC_Date_of_Birth__c   = Date.today();
        physician.PC_Gender__c          = 'Male';
        physician.PC_Specialist_Type__c = 'Cardiologist';
        physician.Type                  = 'Specialist';
        physician.PC_Sub_Type__c        = 'Other';
        physician                       = (Account) PC_Database.ins(physician, false);

        //Create Address
        physicianAddress                  = PC_Test_Setup.createAddress(physician.Id);
        physicianAddress.PC_Zip_Code__c   = zipCode2;
        physicianAddress                  = (PC_Address__c) PC_Database.ins(physicianAddress, false);

        //Create Manufacturer
        List<Account>  manufacturers = PC_Test_Setup.createAccounts(pRootName, manufacturerNumber, PC_Constants.MANUFACTURER_RECORD_TYPE);
        manufacturer = (Account)PC_Database.ins(manufacturers[0], false);

        //Create Engagement Program
        enmtProgram= PC_Test_Setup.createEngagementProgram(programName,manufacturer.Id );
        enmtProgram.PC_Program_Code__c = programName;
        enmtProgram = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram, false);

        //enmtProgram2
        enmtProgram2= PC_Test_Setup.createEngagementProgram(programName2,manufacturer.Id );
        enmtProgram2.PC_Program_Code__c = programName2;
        enmtProgram2 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram2, false);

        //enmtProgram3
        enmtProgram3= PC_Test_Setup.createEngagementProgram(programName3,manufacturer.Id );
        enmtProgram3.PC_Program_Code__c = programName3;
        enmtProgram3 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram3, false);

        //enmtProgram4
        enmtProgram4= PC_Test_Setup.createEngagementProgram(programName4,manufacturer.Id );
        enmtProgram4.PC_Program_Code__c = programName4;
        enmtProgram4 = (PC_Engagement_Program__c) PC_Database.ins(enmtProgram4, false);

        //Create Care Coordinator
        careCoordinator = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinator@test.com', 'care1');
        careCoordinator = (User) PC_Database.ins(careCoordinator);

        careCoordinator2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinator2@test.com', 'care2');
        careCoordinator2 = (User) PC_Database.ins(careCoordinator2);

        careCoordinator3 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinator3@test.com', 'care3');
        careCoordinator3 = (User) PC_Database.ins(careCoordinator3);

        careCoordinator4 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'carecoordinator4@test.com', 'care4');
        careCoordinator4 = (User) PC_Database.ins(careCoordinator4);

        //Create Reimbursement Specialist
        reimbursementSpecialist = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'reimbursementspecialist@test.com', 'rem1');
        reimbursementSpecialist = (User) PC_Database.ins(reimbursementSpecialist);

        //Create Region record
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

        region =   new PC_Region__c();
        region.Name                 = 'North';
        region.PC_Manufacturer__c   = manufacturer.Id;
        region.PC_EffectiveFromTime__c  = effectiveFrom;
        region.PC_EffectiveToTime__c    = effectiveTo;
        region.PC_Active__c         = true;

        regions.add(region);

        region =   new PC_Region__c();
        region.Name                 = 'South';
        region.PC_Manufacturer__c   = manufacturer.Id;
        region.PC_EffectiveFromTime__c  = effectiveFrom;
        region.PC_EffectiveToTime__c    = effectiveTo;
        region.PC_Active__c         = true;

        regions.add(region);


        regions = (List<PC_Region__c>)PC_Database.ins(regions, false);

        //Create RegionZipCode record
        List<PC_Region__c> fetchedregion   =  [Select Id, Name from PC_Region__c where PC_Manufacturer__c = :manufacturer.Id];
        system.assertEquals(fetchedregion.size(), 4);
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

        regionZipCode   =   new PC_RegionZipCode__c();
        regionZipCode.Name          = fetchedregion[2].Name + zipCode3;
        regionZipCode.PC_ZipCode__c = zipCode3;
        regionZipCode.PC_Region__c  = fetchedregion[2].Id;
        regionZipCodes.add(regionZipCode);

        //zipCode4
        regionZipCode   =   new PC_RegionZipCode__c();
        regionZipCode.Name          = fetchedregion[3].Name + zipCode4;
        regionZipCode.PC_ZipCode__c = zipCode4;
        regionZipCode.PC_Region__c  = fetchedregion[3].Id;
        regionZipCodes.add(regionZipCode);
        regionZipCodes = (List<PC_RegionZipCode__c>)PC_Database.ins(regionZipCodes, false);

        //Create Program Region User Mapping
        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram.Id;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram.Id;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        //Create Program Region User Mapping
        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_REIMBURSEMENT_SPECIALIST;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram.Id;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[1].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = reimbursementSpecialist.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram.Id;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator2.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram2.Id;
        programRegionUserMapping.PC_Ordinal__c = 1;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator3.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram2.Id;
        programRegionUserMapping.PC_Ordinal__c = 2;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[3].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator4.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram.Id;
        programRegionUserMapping.PC_Ordinal__c = 1;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[3].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator4.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram.Id;
        programRegionUserMapping.PC_Ordinal__c = 1;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        //new record
        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator3.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram3.Id;
        programRegionUserMapping.PC_Ordinal__c = 1;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator4.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram3.Id;
        programRegionUserMapping.PC_Ordinal__c = 2;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator3.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram4.Id;
        programRegionUserMapping.PC_Ordinal__c = 1;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        programRegionUserMapping    =   new PC_ProgramRegionUserMapping__c();
        programRegionUserMapping.PC_Region__c              = fetchedregion[0].Id;
        programRegionUserMapping.PC_CareTeamRole__c        = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserMapping.PC_CareTeamMember__c      = careCoordinator4.Id;
        programRegionUserMapping.PC_EngagementProgram__c   = enmtProgram4.Id;
        programRegionUserMapping.PC_Ordinal__c = 2;
        programRegionUserMapping.PC_StartDateTime__c           = startDateTime;
        programRegionUserMapping.PC_EndDateTime__c             = endDateTime;

        programRegionUserMappings.add(programRegionUserMapping);

        //add history records
        programRegionUserHistory = new PC_ProgramRegionUserHistory__c();
        programRegionUserHistory.PC_CareTeamUser__c = careCoordinator3.Id;
        programRegionUserHistory.PC_EngagementProgram__c = enmtProgram3.Id;
        programRegionUserHistory.PC_Region__c = fetchedregion[0].Id;
        programRegionUserHistory.PC_CareTeamRole__c = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserHistories.add(programRegionUserHistory);

        programRegionUserHistory = new PC_ProgramRegionUserHistory__c();
        programRegionUserHistory.PC_CareTeamUser__c = careCoordinator3.Id;
        programRegionUserHistory.PC_EngagementProgram__c = enmtProgram4.Id;
        programRegionUserHistory.PC_Region__c = fetchedregion[0].Id;
        programRegionUserHistory.PC_CareTeamRole__c = PC_Constants.PC_ROLE_CARE_COORDINATOR;
        programRegionUserHistories.add(programRegionUserHistory);

        programRegionUserHistories = (List<PC_ProgramRegionUserHistory__c>)PC_Database.ins(programRegionUserHistories, false);

        programRegionUserMappings = (List<PC_ProgramRegionUserMapping__c>)PC_Database.ins(programRegionUserMappings, false);
    }

    //WCD is active for Program Case
    @isTest static void triggerWCDByProgramCase(){
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient     =   [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            enmtProgram =   [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];
            caseOne                             = PC_Test_Setup.createCase(objUser,patient);
            caseOne.PC_Engagement_Program__c    =   enmtProgram.Id;

            Test.startTest();
            //Create WCD record
            wcdConfig   =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c      = enmtProgram.Id;
            wcdConfig.PC_AssignmentType__c         = 'Program Case';
            wcdConfig.PC_AssignmentLookupField__c  = PC_Constants.getQualifiedAPIName('PC_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig, false);

            //Create Case: This will trigger WCD workflow
            caseOne = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);

            caseOne = [SELECT PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];

            careCoordinator = [SELECT Id, email FROM User WHERE email = 'carecoordinator@test.com'];
            reimbursementSpecialist = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist@test.com'];

            system.assertEquals(caseOne.PC_Care_Coordinator__c, careCoordinator.Id);
            system.assertEquals(caseOne.PC_Reimbursment_Specialist__c, reimbursementSpecialist.Id);
            Test.stopTest();

        }
    }

    //WCD is active for Patient
    @isTest static void triggerWCDByPatient(){
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient     =   [SELECT ID FROM Account WHERE RecordTypeId = :patientId  LIMIT 1];
            enmtProgram =   [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];
            caseOne                             = PC_Test_Setup.createCase(objUser,patient);
            caseOne.PC_Engagement_Program__c    =   enmtProgram.Id;

            Test.startTest();

            //Create WCD record
            wcdConfig   =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c      = enmtProgram.Id;
            wcdConfig.PC_AssignmentType__c         = 'Patient';
            wcdConfig.PC_AssignmentLookupField__c  = PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig, false);

            //Create Case: This will trigger WCD workflow
            caseOne = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);
            caseOne = [SELECT PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];

            careCoordinator = [SELECT Id, email FROM User WHERE email = 'carecoordinator@test.com'];
            reimbursementSpecialist = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist@test.com'];

            system.assertEquals(caseOne.PC_Care_Coordinator__c, careCoordinator.Id);
            system.assertEquals(caseOne.PC_Reimbursment_Specialist__c, reimbursementSpecialist.Id);
            Test.stopTest();
        }
    }

    //WCD is active for Association
    @isTest static void triggerWCDByPhysician(){
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient     =   [SELECT ID FROM Account WHERE RecordTypeId = :patientId  LIMIT 1];
            enmtProgram =   [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];
            caseOne                             = PC_Test_Setup.createCase(objUser,patient);
            caseOne.PC_Engagement_Program__c    =   enmtProgram.Id;

            Test.startTest();
            //Create WCD record
            wcdConfig   =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c      = enmtProgram.Id;
            wcdConfig.PC_AssignmentType__c         = 'Association';
            wcdConfig.PC_AssociationRole__c        = 'Treating Physician';
            wcdConfig.PC_AssignmentLookupField__c  = 'Account.'+PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig, false);

            //Create Association: This will trigger WCD workflow
            caseOne     = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);
            physician   =   [SELECT ID FROM Account WHERE RecordTypeId = :physicianId  LIMIT 1];
            system.assertNotEquals(physician.Id, null);
            PC_Association__c physicianAssociation = PC_Test_Setup.createAssociations(caseOne.Id, physician.Id, null, 'Treating Physician');
            physicianAssociation = (PC_Association__c)PC_Database.ins(physicianAssociation, false);
            system.assertNotEquals(physicianAssociation.Id, null);


            careCoordinator = [SELECT Id, email FROM User WHERE email = 'carecoordinator@test.com'];
            reimbursementSpecialist = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist@test.com'];

            List<PC_Association__c> allAssociations = [SELECT Id, PC_Account__r.Name, PC_Associated_User__r.Name, PC_Program__c FROM PC_Association__c LIMIT 3];

            caseOne = [SELECT Id, PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];

            system.assertEquals(caseOne.Id, allAssociations[0].PC_Program__c);
            system.assertEquals(caseOne.Id, allAssociations[1].PC_Program__c);
            system.assertEquals(caseOne.Id, allAssociations[2].PC_Program__c);
            Test.stopTest();
        }
    }

    //Bulk insertion of program cases
    @isTest static void triggerWCDByBulkProgramCases() {
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient = [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            enmtProgram2 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName2 LIMIT 1];

            Test.startTest();
            //Create WCD record
            wcdConfig = new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c = enmtProgram2.Id;
            wcdConfig.PC_AssignmentType__c = 'Program Case';
            wcdConfig.PC_AssignmentLookupField__c = PC_Constants.getQualifiedAPIName('PC_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c) PC_Database.ins(wcdConfig, false);

            //Create Case: This will trigger WCD workflow
            List<Case> newCases = new List<Case>();
            Id caseRecordType = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
            for(integer i = 0; i < 200; i ++){
                Case eachCase = new Case();
                eachCase.ownerId = objUser.Id;
                eachCase.AccountId = patient.Id;
                eachCase.RecordTypeId = caseRecordType;
                eachCase.Status= 'New';
                eachCase.PC_Engagement_Program__c = enmtProgram2.Id;
                newCases.add(eachCase);
            }

            newCases = (List<Case>) PC_Database.ins(newCases, false);
            List<Id> caseIds = new List<Id>();
            for(Case cs:newCases){
                caseIds.add(cs.Id);
            }

            List<PC_Association__c> allAssociations = [SELECT Id, PC_Account__r.Name, PC_Associated_User__r.Name, PC_Program__c FROM PC_Association__c WHERE PC_Program__c IN: caseIds];
            system.assertEquals(200,allAssociations.size()); //one association for a case
            Test.stopTest();
        }
    }

    //Bulk insertion of program cases with different engagement programs
    @isTest static void bulkProgramCasesWithDifferentEngagementPrograms() {
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient     =   [SELECT ID FROM Account WHERE RecordTypeId = :patientId  LIMIT 1];
            enmtProgram =   [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];
            enmtProgram2 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName2 LIMIT 1];

            Test.startTest();
            //Create WCD record
            wcdConfig = new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c = enmtProgram.Id;
            wcdConfig.PC_AssignmentType__c = 'Program Case';
            wcdConfig.PC_AssignmentLookupField__c = PC_Constants.getQualifiedAPIName('PC_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c) PC_Database.ins(wcdConfig, false);

            wcdConfig2 = new PC_WorkCaseDistributionConfig__c();
            wcdConfig2.PC_EngagementProgram__c = enmtProgram2.Id;
            wcdConfig2.PC_AssignmentType__c = 'Program Case';
            wcdConfig2.PC_AssignmentLookupField__c = PC_Constants.getQualifiedAPIName('PC_Zip_Code__c');
            wcdConfig2 = (PC_WorkCaseDistributionConfig__c) PC_Database.ins(wcdConfig2, false);

            //Create Case: This will trigger WCD workflow
            List<Case> newCases = new List<Case>();
            Id caseRecordType = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
            for(integer i = 0; i < 100; i ++){
                Case eachCase = new Case();
                eachCase.ownerId = objUser.Id;
                eachCase.AccountId = patient.Id;
                eachCase.RecordTypeId = caseRecordType;
                eachCase.Status= 'New';
                eachCase.PC_Engagement_Program__c = enmtProgram.Id;
                newCases.add(eachCase);
            }
            for(integer i = 0; i < 100; i ++){
                Case eachCase = new Case();
                eachCase.ownerId = objUser.Id;
                eachCase.AccountId = patient.Id;
                eachCase.RecordTypeId = caseRecordType;
                eachCase.Status= 'New';
                eachCase.PC_Engagement_Program__c = enmtProgram2.Id;
                newCases.add(eachCase);
            }
            newCases = (List<Case>) PC_Database.ins(newCases, false);
            List<Id> caseIds = new List<Id>();
            for(Case cs:newCases){
                caseIds.add(cs.Id);
            }
            Test.stopTest();

            List<PC_Association__c> allAssociations = [SELECT Id, PC_Account__r.Name, PC_Associated_User__r.Name, PC_Program__c FROM PC_Association__c WHERE PC_Program__c IN: caseIds];
            system.assertEquals(300,allAssociations.size());//2 associations for a case with enmtProgram and a association for a case with enmtProgram2

        }
    }

    //Bulk insertion of cases where each case triggers WCD twice
    // Commenting this test method since this scenario is not valid
    /* @isTest static void programCasesCallingWCDTwiceInEachCase() {
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName2, sAlias2);
        objUser2.CompanyName = '02625';
        objUser2 = (User) PC_Database.ins(objUser2);
        system.runAs(objUser) {
            Test.startTest();
            patient     =   [SELECT ID FROM Account WHERE RecordTypeId = :patientId  LIMIT 1];
            enmtProgram =   [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];

            //Create WCD record
            wcdConfig   =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c      = enmtProgram.Id;
            wcdConfig.PC_AssignmentType__c         = 'Association';
            wcdConfig.PC_AssociationRole__c        = 'Care Coordinator';
            wcdConfig.PC_AssignmentLookupField__c  = 'User.CompanyName';
            wcdConfig = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig, false);

            wcdConfig2 =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig2.PC_EngagementProgram__c      = enmtProgram.Id;
            wcdConfig2.PC_AssignmentType__c         = 'Program Case';
            wcdConfig2.PC_AssignmentLookupField__c  = 'PC_Zip_Code__c';
            wcdConfig2 = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig2, false);

            List<Case> newCases = new List<Case>();
            Id caseRecordType = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
            for(integer i = 0; i < 50; i ++){
                Case eachCase = new Case();
                eachCase.ownerId = objUser.Id;
                eachCase.RecordTypeId = caseRecordType;
                eachCase.Status = 'New';
                eachCase.PC_Engagement_Program__c = enmtProgram.Id;
                eachCase.AccountId = patient.Id;
                eachCase.PC_Care_Coordinator__c = objUser2.Id;
                newCases.add(eachCase);
            }
            newCases = (List<Case>) PC_Database.ins(newCases, false);
            List<Id> caseIds = new List<Id>();
            for(Case cs:newCases){
                caseIds.add(cs.Id);
            }

            List<PC_Association__c> allAssociations = [SELECT Id, PC_Account__r.Name, PC_Associated_User__r.Name, PC_Program__c FROM PC_Association__c WHERE PC_Program__c IN: caseIds AND PC_AssociationStatus__c = 'Active'];
            system.assertEquals(100,allAssociations.size());//active associations will be from program cases only

            Test.stopTest();
        }
    } */

    //this method will verify the history records
    @isTest static void checkProgramRegionHistory(){
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient     = [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            enmtProgram3 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName3 LIMIT 1];
            enmtProgram4 = [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName4 LIMIT 1];
            caseOne                             = PC_Test_Setup.createCase(objUser,patient);
            caseOne.PC_Engagement_Program__c    =   enmtProgram3.Id;

            caseTwo = PC_Test_Setup.createCase(objUser,patient);
            caseTwo.PC_Engagement_Program__c = enmtProgram4.Id;

            Test.startTest();
            //Create WCD record
            wcdConfig   =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c      = enmtProgram3.Id;
            wcdConfig.PC_AssignmentType__c         = 'Patient';
            wcdConfig.PC_AssignmentLookupField__c  = PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig, false);

            wcdConfig2 =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig2.PC_EngagementProgram__c      = enmtProgram4.Id;
            wcdConfig2.PC_AssignmentType__c         = 'Patient';
            wcdConfig2.PC_AssignmentLookupField__c  = PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c');
            wcdConfig2 = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig2, false);

            List<Case> newCases = new List<Case>();
            newCases.add(caseOne);
            newCases.add(caseTwo);
            newCases = (List<Case>) PC_Database.ins(newCases, false);
            List<Id> caseIds = new List<Id>();
            for(Case cs:newCases){
                caseIds.add(cs.Id);
            }
            List<Case> caseList = [SELECT PC_Care_Coordinator__c,PC_Engagement_Program__c FROM  Case WHERE Id IN :caseIds];

            List<PC_ProgramRegionUserHistory__c> historyRecords = [SELECT Id,Name,PC_EngagementProgram__c,PC_Region__c,PC_CareTeamUser__c FROM PC_ProgramRegionUserHistory__c WHERE PC_Case__c = :caseList[0].Id];
            system.assertEquals(2,historyRecords.size());//This should have histories from both program region user mapping records with enmtProgram3 as it has default service class

            List<PC_ProgramRegionUserHistory__c> historyRecords2 = [SELECT Id,Name,PC_EngagementProgram__c,PC_Region__c,PC_CareTeamUser__c FROM PC_ProgramRegionUserHistory__c WHERE PC_Case__c = :caseList[1].Id];
            system.assertEquals(1,historyRecords2.size());//This should have only one from both program region user mapping records with enmtProgram4 as it has round robin service class
        }
    }

    //WCD is active for Program Case
    @isTest static void triggerDeactivateWCDByCreateWCDAssociation(){
        //Create test user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, sUserName, sAlias);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser) {
            patient     =   [SELECT ID FROM Account WHERE RecordTypeId = :patientId LIMIT 1];
            enmtProgram =   [SELECT ID FROM PC_Engagement_Program__c WHERE PC_Program_Code__c = :programName LIMIT 1];
            caseOne                             = PC_Test_Setup.createCase(objUser,patient);
            caseOne.PC_Engagement_Program__c    =   enmtProgram.Id;

            Test.startTest();
            //Create WCD record
            wcdConfig   =   new PC_WorkCaseDistributionConfig__c();
            wcdConfig.PC_EngagementProgram__c      = enmtProgram.Id;
            wcdConfig.PC_AssignmentType__c         = 'Program Case';
            wcdConfig.PC_AssignmentLookupField__c  = PC_Constants.getQualifiedAPIName('PC_Zip_Code__c');
            wcdConfig = (PC_WorkCaseDistributionConfig__c)PC_Database.ins(wcdConfig, false);

            //Create Case: This will trigger WCD workflow
            caseOne = (Case) PC_Database.ins(caseOne, false);
            system.assertNotEquals(caseOne.Id, null);

            caseOne = [SELECT PC_Care_Coordinator__c, PC_Reimbursment_Specialist__c FROM Case WHERE Id = :caseOne.Id];

            careCoordinator = [SELECT Id, email FROM User WHERE email = 'carecoordinator@test.com'];
            reimbursementSpecialist = [SELECT Id, email FROM User WHERE email = 'reimbursementspecialist@test.com'];

            system.assertEquals(caseOne.PC_Care_Coordinator__c, careCoordinator.Id);
            system.assertEquals(caseOne.PC_Reimbursment_Specialist__c, reimbursementSpecialist.Id);


            careCoordinator = [SELECT Id, email FROM User WHERE email = 'carecoordinator2@test.com'];
            PC_WorkCaseDistributionForAssocHandler.isProcessed = true;
            PC_Association__c newAssociationRec = new PC_Association__c();
            newAssociationRec.PC_Associated_User__c = careCoordinator.Id;
            newAssociationRec.PC_AssociationStatus__c = PC_Constants.ACTIVE;
            newAssociationRec.PC_IsCreatedViaWCD__c = PC_Constants.TRUE_BOOLEAN;
            newAssociationRec.PC_Program__c = caseOne.Id;
            PC_Database.ins(newAssociationRec, false);

            //Check the active association records
            List<PC_Association__c> activeAssociations = [
                    SELECT Id, PC_Program__c
                    FROM PC_Association__c
                    WHERE PC_Program__c =:caseOne.Id AND PC_AssociationStatus__c = :PC_Constants.ACTIVE
                    AND PC_IsCreatedViaWCD__c = :PC_Constants.TRUE_BOOLEAN
            ];
            system.assertEquals(activeAssociations.size(), 1);
            Test.stopTest();
        }
    }
}