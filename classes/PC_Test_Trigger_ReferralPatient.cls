/*********************************************************************************************************
Class Name      : PC_Test_Trigger_ReferralPatient
Description     : Tests PC_Trigger_ReferralRecordType.
Created By      : Kanteti Kishore
Created Date    : August 07, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                     Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore        August 07, 2019               Initial version
****************************************************************************************************************/
@isTest
public class PC_Test_Trigger_ReferralPatient{


/*********************************************************************************
    Method Name    : testRefEvtPatient
    Author         : Kishore Kanteti
    Description    : This method populates patient name for person account associated before person account record is created.
    Return Type    : void
    Parameter      :
*********************************************************************************/
    @isTest public static void testRefEvtPatient() {
        Account testAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        /* Account testAcc = new Account();
         testAcc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(PC_Constants.PATIENT_RECORD_TYPE).getRecordTypeId();
         testAcc.Name = 'ACCOUNT_NAME';*/
        PC_Database.ins(testAcc);

        Test.startTest();
        PC_Pharmacy_Referral__c phRef = new PC_Pharmacy_Referral__c(PC_Patient__c = testAcc.Id);
        PC_Database.ins(phRef);
        phRef.PC_Start_Date__c = System.today();
        PC_Database.upd(phRef);
        Test.stopTest();
    }

}