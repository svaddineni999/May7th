/**************************************************************************************
Apex Class Name     : PC_AdverseEventMenuLauncher
Description         : This class is used for PC_AdverseEventMenuLauncher lightning component;
CreatedBy           : Deloitte
Created Date        : 24 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        	24 October 2019           [PC-5616] Initial version
Haritha Reddy           Dec 13, 2019              [PC-5791] Added error handling for getAdverseEventConfigData Method
Shishir Bansal         18-Dec-2019               Ability to launch AE creation action from a custom button
Vijay Kashikar         21-Jan-21                 [PC-7102] Added sharing clause
*************************************************************************************/

public with sharing class PC_AdverseEventMenuLauncher {

    /********************************************************************************
   Method Name          : getAdverseEventConfigData
   Description          : fetch adverse event configured data.
   Input Params         :
   Return Type          : AdverseEventConfig
   *********************************************************************************/
    @AuraEnabled
    public static AdverseEventConfig getAdverseEventConfigData(Id selectedRecordId) {

        AdverseEventConfig adverseEventConfig = new AdverseEventConfig();

        try {
            adverseEventConfig.fieldsetName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE2_ADDITIONAL_INFO_FIELDSET, PC_Constants.EMPTY_STRING);
            if(string.isNotBlank(adverseEventConfig.fieldsetName)){
                adverseEventConfig.hideAdditionalInfoSection = PC_Constants.FALSE_BOOLEAN;
            }
            if(String.isNotBlank(String.valueOf(selectedRecordId)) && (selectedRecordId !=null) ){

                String objectName = selectedRecordId.getSObjectType().getDescribe().getName();
                if(objectName.equalsIgnoreCase(PC_Constants.PC_CASE)){
                adverseEventConfig.parentObjectName  = PC_Constants.PC_CASE;//'C';
                /* to do fetch values from custom metadata

                    Case selectedCase = getSelectedCase(selectedRecordId);
                    system.debug('selectedCase-->'+selectedCase); */
                }
                 else if(objectName.equalsIgnoreCase(PC_Constants.PC_ACCOUNT)){
                     adverseEventConfig.parentObjectName = PC_Constants.PC_ACCOUNT;
                 }
            }
            adverseEventConfig.dateFormat = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_DOWNLOAD_DATEFORMAT_NAME,null);
            try {
                Datetime todayDateTime = Datetime.now();
                String successDateFormatting = todayDateTime.format(adverseEventConfig.dateFormat);
            }catch(Exception ex){
                adverseEventConfig.dateFormatErrorMessage = ex.getMessage();
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return adverseEventConfig;
    }




    /********************************************************************************
  Class Name           : AdverseEventConfig
  Description          : holds Adverse Event Configuration data
  *********************************************************************************/
    public inherited sharing class AdverseEventConfig {
        @AuraEnabled public String dateFormat { get; set; }
        @AuraEnabled public String dateFormatErrorMessage { get; set; }
        @AuraEnabled public String fieldsetName { get; set; }
        @AuraEnabled public String orgNamespace { get; set; }
        @AuraEnabled public String parentObjectName { get; set; }
        @AuraEnabled public Boolean hideAdditionalInfoSection { get; set; }
       // @AuraEnabled public String actionComponentAttributes {get; set;}

        public AdverseEventConfig() {
            dateFormat = PC_Constants.EMPTY_STRING;
            fieldsetName = PC_Constants.EMPTY_STRING;
            orgNamespace = PC_Utility.getOrgNamespace();
            parentObjectName = PC_Constants.EMPTY_STRING;
            hideAdditionalInfoSection = PC_Constants.TRUE_BOOLEAN;
           // actionComponentAttributes = PC_Constants.EMPTY_STRING;
        }
    }
}