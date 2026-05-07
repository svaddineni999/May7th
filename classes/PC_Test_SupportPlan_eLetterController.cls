/**
 * Created by shisbansal on 11/20/2018.
 */

@IsTest
private class PC_Test_SupportPlan_eLetterController {

    @isTest static void testMethod1() {

            Test.startTest();
            PC_SupportPlan_eLetterController.eLetterObject eLetterObject =   PC_SupportPlan_eLetterController.geteLetterObject();
            PC_SupportPlan_eLetterController.FieldLabels fieldLabelsObj = PC_SupportPlan_eLetterController.getFieldLabels();
            //Hitha Avalakki: [PC-5757] : Added a LIMIT to query
            List<PC_eLetter__c> eLetterList = [Select Id,name, PC_Source_Object__c from PC_eLetter__c LIMIT 3];
            system.assert(eLetterList.size() == 3);
            Test.stopTest();
    }

    @testSetup static void setup() {

        List<PC_eLetter__c> testEletters = new List<PC_eLetter__c>();
        for(Integer i=0;i<2;i++) {
            testEletters.add(new PC_eLetter__c(Name = 'TestEletter'+i, PC_Source_Object__c ='Case',PC_Communication_Language__c = 'English;French',PC_Target_Recipients__c ='HCO;Treating Physician', PC_Template_Name__c = 'PC_Referral_Notification',PC_Allow_Send_to_Patient__c = true,PC_Send_to_User__c = true, PC_Object_Record_Types__c='Program' ));
        }
        PC_eLetter__c eLetter = new PC_eLetter__c(Name = 'TestEletter2', PC_Source_Object__c ='Case',PC_Communication_Language__c = 'English;French',PC_Target_Recipients__c ='HCO;Treating Physician', PC_Template_Name__c = 'PC_Referral_Notification', PC_Send_to_User__c = false, PC_Object_Record_Types__c='Program', PC_Allow_Send_to_Patient__c = true);
        testEletters.add(eLetter);
        Database.insert(testEletters,false);
    }
}