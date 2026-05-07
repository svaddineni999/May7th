/**
* Class Name      : PC_Test_ActionCenterLightningController
* Created By      : Tejas Patel
* @Created Date   : Aug 29, 2017
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Tejas Patel		   29-Aug-2017			Initial Version
* Shabda Bhujad		   02-Oct-2017 			Changed the method to create manufacturer
* Tejas Patel          05-Apr-2018          Getting the Code Coverage Up, by making use of the custom metadata
* Haritha Reddy        10-Dec-2019         [PC-5791] Removed references of getCaseDetails method which is not in use
*/

@isTest
public class PC_Test_ActionCenterLightningController {
    private static User adminUser;
    public static final String ActionCenterEngagementProgram = 'PRP';
    
    @isTest static void testMethodActionCenter() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            
            //Account
            Account  patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account)PC_Database.ins(patient, false);
            // patient is created
            system.assertNotEquals(patient.Id, null);
            
            //Manufacturer
            List<Account>  manufacturers = PC_Test_Setup.createAccounts('testmanufacturer', 1, PC_Constants.MANUFACTURER_RECORD_TYPE);
            Account manufacturer = (Account)PC_Database.ins(manufacturers[0], false);
            // manufacturer is created
            system.assertNotEquals(manufacturer.Id, null);
            
            //Engagement Program
            PC_Engagement_Program__c  engagement = PC_Test_Setup.createEngagementProgram(ActionCenterEngagementProgram, manufacturer.Id);
            engagement = (PC_Engagement_Program__c)PC_Database.ins(engagement, false);
            // engagement is created
            system.assertNotEquals(engagement.Id, null);
            
            //Program
            Case programCase = PC_Test_Setup.newCase(patient.Id , PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            programCase.PC_Engagement_Program__c = engagement.Id;
            programCase = (Case)PC_Database.ins(programCase, false);
            // Program Case is created
            system.assertNotEquals(programCase.Id, null);

            
            //Test setupActionCenter
            PC_ActionCenterLightningController.ActionCenterWrapper actionCenterWrapper = PC_ActionCenterLightningController.setupActionCenter(programCase.Id);
            system.assertEquals(actionCenterWrapper.lstCommunicationsMetadata.size(), 2);
            system.assertEquals(actionCenterWrapper.lstWorkflowsMetadata.size(), 3);
            system.assertEquals(actionCenterWrapper.lstToolsMetadata.size(), 3);
            Test.StopTest();
        }
    }
    public static List<PC_Action_Center_Setting__mdt> createActionCenterSetting() {
        String orgNameSpace = (PC_Constants.OrgNamespace == '') ? null : PC_Constants.OrgNamespace;
        List<PC_Action_Center_Setting__mdt> lstAllActions = new List<PC_Action_Center_Setting__mdt> ();
        PC_Action_Center_Setting__mdt actions1 = new PC_Action_Center_Setting__mdt();
        actions1.PC_Action_Component__c                  =   'TestAllRecordTypeAllEngPrgCmp';
        actions1.PC_Action_Icon__c                       =   'TestAllRecordTypeAllEngPrgIcon';
        actions1.PC_Action_Label__c                      =   'TestAllRecordTypeAllEngPrg';
        actions1.PC_Action_Ordinal__c                    =    1;
        actions1.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_COMMUNICATIONS;
        actions1.PC_Case_Record_Type__c                  =   'ALL';
        actions1.PC_Action_Component_Attributes__c       =   'TestAllRecordTypeAllEngPrgAttr';
        actions1.PC_Engagement_Program_Code__c           =   'ALL';
        actions1.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        lstAllActions.add(actions1);

        PC_Action_Center_Setting__mdt actions2 = new PC_Action_Center_Setting__mdt();
        actions2.PC_Action_Component__c                  =   'TestAllRecordTypePRPEngPrgCmp';
        actions2.PC_Action_Icon__c                       =   'TestAllRecordTypePRPEngPrgIcon';
        actions2.PC_Action_Label__c                      =   'TestAllRecordTypePRPEngPrg';
        actions2.PC_Action_Ordinal__c                    =    2;
        actions2.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_COMMUNICATIONS;
        actions2.PC_Case_Record_Type__c                  =   'ALL';
        actions2.PC_Action_Component_Attributes__c       =   'TestAllRecordTypePRPEngPrgAttr';
        actions2.PC_Engagement_Program_Code__c           =   ActionCenterEngagementProgram;
        actions2.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        lstAllActions.add(actions2);

        PC_Action_Center_Setting__mdt actions3 = new PC_Action_Center_Setting__mdt();
        actions3.PC_Action_Component__c                  =   'TestPrgRecordTypePRPEngPrgCmp';
        actions3.PC_Action_Icon__c                       =   'TestPrgRecordTypePRPEngPrgIcon';
        actions3.PC_Action_Label__c                      =   'TestPrgRecordTypePRPEngPrg';
        actions3.PC_Action_Ordinal__c                    =    3;
        actions3.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_WORKFLOWS;
        actions3.PC_Case_Record_Type__c                  =   PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        actions3.PC_Action_Component_Attributes__c       =   'TestPrgRecordTypePRPEngPrgAttr';
        actions3.PC_Engagement_Program_Code__c           =   ActionCenterEngagementProgram;
        actions3.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        lstAllActions.add(actions3);

        PC_Action_Center_Setting__mdt actions4 = new PC_Action_Center_Setting__mdt();
        actions4.PC_Action_Component__c                  =   'TestPrgRecordTypeAllEngPrgCmp';
        actions4.PC_Action_Icon__c                       =   'TestPrgRecordTypeAllEngPrgIcon';
        actions4.PC_Action_Label__c                      =   'TestPrgRecordTypeAllEngPrg';
        actions4.PC_Action_Ordinal__c                    =    4;
        actions4.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_WORKFLOWS;
        actions4.PC_Case_Record_Type__c                  =   PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        actions4.PC_Action_Component_Attributes__c       =   'TestPrgRecordTypeAllEngPrgAttr';
        actions4.PC_Engagement_Program_Code__c           =   'ALL';
        actions4.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        lstAllActions.add(actions4);

        //Other Case Type
        PC_Action_Center_Setting__mdt actions5 = new PC_Action_Center_Setting__mdt();
        actions5.PC_Action_Component__c                  =   'TestAllRecordTypeAllEngPrgCmp';
        actions5.PC_Action_Icon__c                       =   'TestAllRecordTypeAllEngPrgIcon';
        actions5.PC_Action_Label__c                      =   'TestAllRecordTypeAllEngPrg';
        actions5.PC_Action_Ordinal__c                    =    5;
        actions5.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_WORKFLOWS;
        actions5.PC_Case_Record_Type__c                  =   PC_Constants.CASE_OTHER_RECORD_TYPE;
        actions5.PC_Action_Component_Attributes__c       =   'TestAllRecordTypeAllEngPrgAttr';
        actions5.PC_Engagement_Program_Code__c           =   'ALL';
        actions5.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        actions5.PC_Other_Case_Record_Type__c            =  'ALL';
        lstAllActions.add(actions5);

        PC_Action_Center_Setting__mdt actions6 = new PC_Action_Center_Setting__mdt();
        actions6.PC_Action_Component__c                  =   'TestAllRecordTypePRPEngPrgCmp';
        actions6.PC_Action_Icon__c                       =   'TestAllRecordTypePRPEngPrgIcon';
        actions6.PC_Action_Label__c                      =   'TestAllRecordTypePRPEngPrg';
        actions6.PC_Action_Ordinal__c                    =    6;
        actions6.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_TOOLS;
        actions6.PC_Case_Record_Type__c                  =   PC_Constants.CASE_OTHER_RECORD_TYPE;
        actions6.PC_Action_Component_Attributes__c       =   'TestAllRecordTypePRPEngPrgAttr';
        actions6.PC_Engagement_Program_Code__c           =   ActionCenterEngagementProgram;
        actions6.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        actions6.PC_Other_Case_Record_Type__c            =  'ALL';
        lstAllActions.add(actions6);

        PC_Action_Center_Setting__mdt actions7 = new PC_Action_Center_Setting__mdt();
        actions7.PC_Action_Component__c                  =   'TestPrgRecordTypePRPEngPrgCmp';
        actions7.PC_Action_Icon__c                       =   'TestPrgRecordTypePRPEngPrgIcon';
        actions7.PC_Action_Label__c                      =   'TestPrgRecordTypePRPEngPrg';
        actions7.PC_Action_Ordinal__c                    =    7;
        actions7.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_TOOLS;
        actions7.PC_Case_Record_Type__c                  =   PC_Constants.CASE_OTHER_RECORD_TYPE;
        actions7.PC_Action_Component_Attributes__c       =   'TestPrgRecordTypePRPEngPrgAttr';
        actions7.PC_Engagement_Program_Code__c           =   ActionCenterEngagementProgram;
        actions7.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        actions7.PC_Other_Case_Record_Type__c            =  PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        lstAllActions.add(actions7);

        PC_Action_Center_Setting__mdt actions8 = new PC_Action_Center_Setting__mdt();
        actions8.PC_Action_Component__c                  =   'TestPrgRecordTypeAllEngPrgCmp';
        actions8.PC_Action_Icon__c                       =   'TestPrgRecordTypeAllEngPrgIcon';
        actions8.PC_Action_Label__c                      =   'TestPrgRecordTypeAllEngPrg';
        actions8.PC_Action_Ordinal__c                    =    8;
        actions8.PC_Action_Type__c                       =   PC_Constants.ACTION_METADATA_TOOLS;
        actions8.PC_Case_Record_Type__c                  =   PC_Constants.CASE_OTHER_RECORD_TYPE;
        actions8.PC_Action_Component_Attributes__c       =   'TestPrgRecordTypeAllEngPrgAttr';
        actions8.PC_Engagement_Program_Code__c           =   'ALL';
        actions8.PC_Case_Recordtype_Namespaceprefix__c   =   orgNameSpace;
        actions8.PC_Other_Case_Record_Type__c            =  PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        lstAllActions.add(actions8);
        return lstAllActions;
    }
}