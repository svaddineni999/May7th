/**
* Created by tejas patel on 25 Jan 2018.
*/
/*********************************************************************************
Class Name      : PC_Test_ActionIconsLightningController
Description     : Test Class for PC_ActionIconsLightningController
Created By      : tejas patel
Created Date    : 25 Jan 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
Teajs Patel                 25-Jan-18                  Initial Version
Tejas Patel					31-Jan-18				   PC-2727 Display general icons on all record types
Prachi Nandgaonkar          3-Feb-18                   [PC-2727] Display general icons on all record types with 'ALL' keyword
Tejas Patel                 26-Sep-19                  [PC-5511] Updating the test class with new field added to custom metadata
*********************************************************************************/
@isTest
public class PC_Test_ActionIconsLightningController {
    private static User adminUser;
    private static PC_Document__c oDoc;
    @isTest 
    static void setupActionIcons() {
        //Create Admin Users
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser);
        
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
        PC_Database.ins(oDoc);
        
        system.runAs(adminUser) {
            Test.StartTest();
            LIST<PC_ActionIconsLightningController.ActionIconsWrapper> actionIconsWrapper = PC_ActionIconsLightningController.setupActionIcons(oDoc.Id);
            
            PC_Document__c tempDoc = [SELECT RecordType.DeveloperName,RecordType.NamespacePrefix from PC_Document__c where Id =:oDoc.Id];
            
            LIST<PC_Document_Action_Setting__mdt> actionIconMetaData = NEW LIST<PC_Document_Action_Setting__mdt>();

            LIST<PC_Document_Action_Setting__mdt> actionIconMetaData_RecordType = [SELECT PC_Active__c, PC_Component__c, PC_Icon__c, PC_Document_Record_Type__c,
                                                                                   PC_Label__c, PC_Ordinal__c, PC_ComponentAttributes__c, PC_ValidatorClass__c FROM PC_Document_Action_Setting__mdt
                                                                                   WHERE PC_Active__c =: TRUE AND
                                                                                   (PC_Document_Record_Type__c =: tempDoc.RecordType.DeveloperName OR
                                                                                	PC_Document_Record_Type__c = 'ALL' OR
                                                                                	PC_Document_Record_Type__c = 'all')
                                                                            ORDER BY PC_Ordinal__c ];

            actionIconMetaData.addAll(actionIconMetaData_RecordType);

            System.assertEquals(actionIconsWrapper.size(), actionIconMetaData.size());

            //No Custom meta data available
            PC_Document_Action_Setting__mdt a = NEW PC_Document_Action_Setting__mdt();
            a.PC_Active__c                  =   true;
            a.PC_Component__c               =   'TestCmp';
            a.PC_Icon__c                    =   'TestIcon';
            a.PC_Document_Record_Type__c    =   'TestDocRecord';
            a.PC_Label__c                   =   'TestLabel';
            a.PC_Ordinal__c                 =   1;
            a.PC_Action__c                  =   'TestAction';
            a.PC_ComponentAttributes__c     = '{"adminAccessAttributes":{"adminAccess":false,"adminProfile":"testProfile"}}';
            a.PC_ValidatorClass__c          =   'DocumentValidatorClass';

            PC_ActionIconsLightningController.getAccessibilityStatus(oDoc.Id, a.PC_ValidatorClass__c, a.PC_Component__c);

            PC_ActionIconsLightningController.ActionIconsWrapper actionIconsWrapper1 = new PC_ActionIconsLightningController.ActionIconsWrapper(a);
            System.assertEquals(a.PC_Document_Record_Type__c,actionIconsWrapper1.iconDocRecordType);
            System.assertEquals(actionIconsWrapper1.iconActionComponent,'c:'+a.PC_Component__c + '::' + a.PC_Action__c + '::' + a.PC_ComponentAttributes__c + '::' + a.PC_ValidatorClass__c);
            Test.StopTest();
        }
    }
    
}