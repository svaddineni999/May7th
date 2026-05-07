/*********************************************************************************
Class Name      :   PC_AE2DownloadPDF
Description        : Controller for PC_AE2DownloadPDF Component
Created By        : Kanteti Kishore
Created Date     : 23-10-2019
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kanteti Kishore          23-10-2019              Initial Version
Shishir Bansal           3-12-2019               Added logic to fetch the Latest AE2 id
                                                 along with vfpage Name
Shishir Bansal           06-Dec-2019             [PC-5792] Avoid hardcoding of string variable
Haritha Reddy            21-Jan-2021             [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_AE2DownloadPDF {

    /*********************************************************
    Method Name          : getAEDownloadPDFPageName
    Description           : Getting VF PageName
    Input Params            :
    Return Type             : String
    *********************************************************************************/
   /* @AuraEnabled
    public static String getAEDownloadPDFPageName(){
        String vfPageName='';
        try{
            vfPageName=PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_VF_PAGE_NAME,PC_Constants.PC_AE2_DEFAULT_VF_PAGE_NAME);
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return vfPageName;
    }/*

    /*********************************************************
    Method Name          : getAEDownloadParams
    Description           : Getting VF PageName
    Input Params            :
    Return Type             : String
    *********************************************************************************/
   @AuraEnabled
    public static AE2Wrapper getAEDownloadParams(Id currentAE2_Id){
       String vfPageName=PC_Constants.EMPTY_STRING;
       AE2Wrapper ae2Params = new AE2Wrapper();

        try{
            vfPageName=PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_VF_PAGE_NAME,PC_Constants.PC_AE2_DEFAULT_VF_PAGE_NAME);
            ae2Params.vfPageName =    vfPageName;
            if(String.isNotBlank(String.valueOf(currentAE2_Id)) ) {
                List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c'),
                    PC_Constants.getQualifiedAPIName('PC_ParentAdverseEvent__c')
                };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, fields);
                List<PC_AdverseEvent2__c> ae2Record = [Select Id,PC_ParentAdverseEvent__c ,PC_ParentAdverseEvent__r.PC_LatestAdverseEvent__c, PC_LatestAdverseEvent__c FROM PC_AdverseEvent2__c where Id = :currentAE2_Id LIMIT 1];

                if(ae2Record !=null){
                    if(ae2Record.size()>0)

                    //Integer i = 5/0;
                    if(ae2Record[0].PC_ParentAdverseEvent__c !=null){
                        if(ae2Record[0].PC_ParentAdverseEvent__r.PC_LatestAdverseEvent__c !=null ){
                            ae2Params.latestAE2Id = ae2Record[0].PC_ParentAdverseEvent__r.PC_LatestAdverseEvent__c;
                        }
                        else {

                            String exceptionMessage =System.Label.PC_AdverseEvent2_ExceptionMessage;
                            AuraHandledException ex = new AuraHandledException(exceptionMessage);
                             PC_Utility.logAndThrowException(ex, exceptionMessage);

                        }

                    }
                    else if(  ae2Record[0].PC_LatestAdverseEvent__c !=null){
                        ae2Params.latestAE2Id =  ae2Record[0].PC_LatestAdverseEvent__c;
                    }
                    else{
                        ae2Params.latestAE2Id =currentAE2_Id;
                    }
                }

            }
            return ae2Params;
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
            //PC_Utility.createExceptionLog(ex);
        }
       return null;
    }


    /*********************************************************
    Wrapper Class Name    :  AE2Wrapper
    Description           :  This wrapper class will hold the value of vf page and Latest AE2 Id
    *********************************************************************************/
    public inherited sharing class AE2Wrapper {
        @AuraEnabled public String vfPageName { get; set; }
        @AuraEnabled public Id latestAE2Id { get; set; }


        public AE2Wrapper() {
            vfPageName = PC_Constants.EMPTY_STRING;
            latestAE2Id = null;
        }
    }
}