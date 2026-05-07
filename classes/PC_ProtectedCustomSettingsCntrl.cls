/***********************************************************************************************
Modification Log:
----------------------------------------------------------------------------------------------
Developer             Date          Version         Description
----------------------------------------------------------------------------------------------
Kanteti Kishore       2020-08-21    Initial         Controller for protecting API Keys
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
************************************************************************************************/
public class PC_ProtectedCustomSettingsCntrl {
    
    @AuraEnabled public List<String> apiLabels;
    @AuraEnabled public String saveToast;
    @AuraEnabled public String errorMsg;
    @AuraEnabled public String formErrorMsg;
    @AuraEnabled public String toastTitleSuccess;
    @AuraEnabled public String toastTitleError;
    @AuraEnabled public String none;
    @AuraEnabled public String errorSelectedApi;
    @AuraEnabled public String addSimilarApiError;
    @AuraEnabled public String apiHelpText;
    @AuraEnabled public Map<String,String> apiLabDescMap;


    /*********************************************************************************
Method Name    : getApiLabels
Author         : Kanteti Kishore
Description    : This method is used for returning all api custom settings.
Return Type    : PC_ProtectedCustomSettingsCntrl 
*********************************************************************************/
    @AuraEnabled
    public static PC_ProtectedCustomSettingsCntrl getApiLabels(){
        
        PC_ProtectedCustomSettingsCntrl protectedApis = new PC_ProtectedCustomSettingsCntrl();
        try{
            protectedApis.apiLabels = new List<String>();
            protectedApis.apiLabDescMap = new Map<String,String>();
            protectedApis.saveToast = Label.PC_Save_Toast;
            protectedApis.errorMsg = Label.PC_Lighting_Error_Message;
            protectedApis.toastTitleSuccess = Label.PC_Toast_Title_Success;
            protectedApis.toastTitleError = Label.PC_Toast_Title_Error;
            protectedApis.formErrorMsg = Label.PC_ProtectedApiSettingFormError;
            protectedApis.none = Label.PC_None;
            protectedApis.apiHelpText = Label.PC_ProtectedApiSettingHelpText;
            protectedApis.errorSelectedApi = Label.PC_ErrorSelectedApi;
            protectedApis.addSimilarApiError = Label.PC_AddSimilarApiError;
            List<PC_ProtectedApiSettings__c> protectedApisList = new List<PC_ProtectedApiSettings__c>();
            protectedApisList = getProtectedApis(); 
            protectedApis.apiLabels.add(Label.PC_None);

            for(PC_ProtectedApiSettings__c apiSetting : protectedApisList){
                protectedApis.apiLabels.add(apiSetting.PC_ProtectedApiKey__c);
                protectedApis.apiLabDescMap.put(apiSetting.PC_ProtectedApiKey__c,apiSetting.PC_ProtectedApiDescription__c);
            }
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        //system.debug('Wrapper'+protectedApis);
        return protectedApis;
        
    }
    
    
    /*********************************************************************************
Method Name    : getProtectedApis
Author         : Kanteti Kishore
Description    : This method is used for returning all api custom settings.
Return Type    : List<PC_ProtectedApiSettings__c> 
*********************************************************************************/
    @AuraEnabled
    public static List<PC_ProtectedApiSettings__c> getProtectedApis(){
        List<PC_ProtectedApiSettings__c> protectedApisList = new List<PC_ProtectedApiSettings__c>();
        try{
            Map<String, PC_ProtectedApiSettings__c> allApisMap = PC_ProtectedApiSettings__c.getAll();
            for(PC_ProtectedApiSettings__c eachApiSetting : allApisMap.values()){
                if(eachApiSetting.PC_SubscriberEditable__c){
                    protectedApisList.add(eachApiSetting);
                }

            }

            if(protectedApisList.size() != 0){
                return protectedApisList;
            }
            
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return protectedApisList;
    }
    
    /*********************************************************************************
Method Name    : updateApiKey
Author         : Kanteti Kishore
Description    : This method is used for updating api custom settings with the key
Return Type    : void 
*********************************************************************************/    
    
    @AuraEnabled
    public static void updateApiKey(String selectedApi,String value){
        List<PC_ProtectedApiSettings__c> protectedApisList = new List<PC_ProtectedApiSettings__c>();
        protectedApisList = getProtectedApis();
        try{
            for(PC_ProtectedApiSettings__c protectedApi : protectedApisList){
                if(protectedApi.PC_ProtectedApiKey__c == selectedApi){
                    protectedApi.PC_ProtectedApiValue__c = String.escapeSingleQuotes(value);
                }
            }
            if(protectedApisList.size() != 0){
                PC_Database.upd(protectedApisList);
            }
            
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }
    /*********************************************************************************
Method Name    : createApiSetting
Author         : Kanteti Kishore
Description    : This method is used for create api custom settings record with the key
Return Type    : Boolean
*********************************************************************************/

    @AuraEnabled
    public static void createApiSetting(String apiSettingKey,String apiSettingValue ,String apiDescription){
        try{

            PC_ProtectedApiSettings__c protectedApi = new PC_ProtectedApiSettings__c();

                protectedApi.Name = apiSettingKey;
                protectedApi.PC_ProtectedApiKey__c = apiSettingKey;
                protectedApi.PC_ProtectedApiDescription__c = apiDescription;
                protectedApi.PC_ProtectedApiValue__c = apiSettingValue;
                protectedApi.PC_SubscriberEditable__c = true;

            List<PC_ProtectedApiSettings__c> protectedApiList = new List<PC_ProtectedApiSettings__c>();
            protectedApiList.add(protectedApi);
            PC_Database.ups(protectedApiList,true);

        }

        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

    }
}