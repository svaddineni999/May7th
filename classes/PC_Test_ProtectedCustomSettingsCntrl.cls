/*********************************************************************************************************
Class Name      : PC_Test_ProtectedCustomSettingsCntrl
Description     : Test class for PC_Test_ProtectedCustomSettingsCntrl
Created By      : Deloitte
Created Date    :
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Deloitte                                               Initial Version
Shishir Bansal                  Dec 05,2019            [PC-5787] Added null check before DML operation
****************************************************************************************************************/

@isTest(seeAllData=False)
public class PC_Test_ProtectedCustomSettingsCntrl {

    @isTest static void testApiKey(){
        PC_ProtectedApiSettings__c protApi = new PC_ProtectedApiSettings__c();
        protApi.Name = PC_Constants.PC_GEOCODE_API_NAME;
        protApi.PC_ProtectedApiKey__c =PC_Constants.PC_GEOCODE_API_NAME;
        protApi.PC_SubscriberEditable__c = true;
        if(protApi !=null) {
            insert protApi;
        }
        PC_ProtectedCustomSettingsCntrl.getApiLabels();
        PC_ProtectedCustomSettingsCntrl.updateApiKey(PC_Constants.PC_GEOCODE_API_NAME,PC_Constants.PC_GEOCODE_API_NAME);
        PC_ProtectedCustomSettingsCntrl.createApiSetting(PC_Constants.PC_ACCOUNT,PC_Constants.PC_ACCOUNT,PC_Constants.PC_GEOCODE_API_NAME);
    } 
}