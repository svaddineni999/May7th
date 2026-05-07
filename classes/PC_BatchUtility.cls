/*********************************************************************************
Class Name      : PC_BatchUtility
Description     : Utility class for patient connect batch jobs
Created By      : Kanteti Kishore
Created Date    : 22-June-2021
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kanteti Kishore          22-June-2021              [PC-7699] Initial Version
*********************************************************************************/
public with sharing class PC_BatchUtility {
    //Batch Sizes Setting Name
    public static final String BATCH_SIZE_SETTING_NAME = 'PC_BatchJobProperties';
    public static final String REMINDER_QUEUES_BATCH_NAME = 'PC_ProcessQueuesInBatch';
    public static final String REMINDER_CHANNEL_HANDLER_SETTING = 'PC_ReminderChannelHandlerMapping';
    public static final String OFFSET_BEFORE = 'Before';
    public static final String OFFSET_AFTER = 'After';
    public static final String OFFSET_REFERENCE_DAYS = 'Days';

    public static BatchJobProperties getBatchJobSetting(String batchJobName){
        String batchJobPropertiesJSON = PC_SYSTEM.getPatientConnectSetting(BATCH_SIZE_SETTING_NAME, '');
        if(String.isNotBlank(batchJobPropertiesJSON)){
            List<BatchJobProperties> batchJobAndSizeMappingList = new List<BatchJobProperties>();
            batchJobAndSizeMappingList = (List<BatchJobProperties>) JSON.deserialize(batchJobPropertiesJSON, List<BatchJobProperties>.class);
            for(BatchJobProperties eachBatchJobProperty : batchJobAndSizeMappingList){
                if(eachBatchJobProperty.jobName == batchJobName){
                    return eachBatchJobProperty;
                }
            }
        }
        return null;
    }
    public static String getFolderId(String batchJobName){
        String folderId = '';
        Boolean notifyAllAdmins = false;
        try{
            String batchJobPropertiesJSON = PC_SYSTEM.getPatientConnectSetting(BATCH_SIZE_SETTING_NAME, '');
            if(String.isNotBlank(batchJobPropertiesJSON)){
                List<BatchJobProperties> batchJobAndSizeMappingList = new List<BatchJobProperties>();
                batchJobAndSizeMappingList = (List<BatchJobProperties>) JSON.deserialize(batchJobPropertiesJSON, List<BatchJobProperties>.class);

                String namespacePrefix;
                String developerName;
                for(BatchJobProperties eachBatchJobAndSize : batchJobAndSizeMappingList){
                    if(batchJobName.equalsIgnoreCase(eachBatchJobAndSize.jobName)){
                        if(eachBatchJobAndSize.notifyAllAdmins){
                            notifyAllAdmins = eachBatchJobAndSize.notifyAllAdmins;
                        }
                        if(String.isNotBlank(eachBatchJobAndSize.folderPath)){
                            String folderName = PC_Utility.replacePatientConnectNamespace(eachBatchJobAndSize.folderPath);
                            if(folderName.contains('__')){
                                namespacePrefix = folderName.split('__')[0];
                                developerName = folderName.split('__')[1];
                            }else{
                                developerName = folderName;
                            }
                        }else{
                            folderId = UserInfo.getUserId();
                        }
                        break;
                    }
                }
                Folder batchLogFolder = new Folder();
                if(String.isNotBlank(developerName) && String.isNotBlank(namespacePrefix)){
                    batchLogFolder = [SELECT Id, Name, DeveloperName FROM Folder WHERE DeveloperName = :developerName AND NamespacePrefix = :namespacePrefix LIMIT 1];
                    folderId = batchLogFolder.Id;
                }else if(String.isNotBlank(developerName) && String.isBlank(namespacePrefix)){
                    batchLogFolder = [SELECT Id, Name, DeveloperName FROM Folder WHERE DeveloperName = :developerName LIMIT 1];
                    folderId = batchLogFolder.Id;
                }else{
                    folderId = UserInfo.getUserId();
                }
            }
        }catch(Exception ex){
            PC_Utility.publishErrorLog(ex, ex.getMessage() + '\n OR \n Issue in Patient Connect Setting '+PC_BatchUtility.BATCH_SIZE_SETTING_NAME+' make sure the JSON is correct and also the folderPath. \n Logs are stored in Personal Documents Folder.');
            notifyAdministratorsOrUser(notifyAllAdmins,ex.getMessage() + '\n OR \n Issue in Patient Connect Setting '+PC_BatchUtility.BATCH_SIZE_SETTING_NAME+' make sure the JSON is correct and also the folderPath. \n Logs are stored in Personal Documents Folder.');
            return UserInfo.getUserId();
        }
        if(String.isBlank(folderId)){
            return UserInfo.getUserId();
        }else{
            return folderId;
        }
    }
    public inherited sharing class BatchJobProperties{
        public String jobName{get;set;}
        public Integer size{get;set;}
        public String folderPath{get;set;}
        public Boolean notifyAllAdmins{get;set;}

        public BatchJobProperties(){}
    }

    public inherited sharing class PC_BatchUtilityException extends Exception{}

    public static Datetime getDatetime(Datetime dueDate, Integer offset, String offsetType, String offsetReference){
        Datetime calculatedDate;
        if(offsetType == OFFSET_AFTER){
            if(offsetReference == OFFSET_REFERENCE_DAYS){
                calculatedDate = dueDate.addDays(offset);
            }else{
                calculatedDate = dueDate.addHours(offset);
            }
        }else{
            if(offsetReference == OFFSET_REFERENCE_DAYS){
                calculatedDate = dueDate.addDays(-offset);
            }else{
                calculatedDate = dueDate.addHours(-offset);
            }
        }
        if(calculatedDate != null){
            return calculatedDate;
        }else{
            return dueDate;
        }
    }

    /**
 * @description Notifies Administrator/User by sending an email.
 * @param Boolean notifyAllAdmins, String Content
 */
    public static void notifyAdministratorsOrUser(Boolean notifyAllAdmins,String content){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        if(notifyAllAdmins){
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name =: PC_Constants.PROFILE_SALESFORCE_SYS_ADMIN LIMIT 1];
            List<User> adminUsers = new List<User>([SELECT Id,Email FROM User
            WHERE ProfileId =: adminProfile.Id AND Email != NULL AND IsActive = TRUE]);
            for(User eachAdmin : adminUsers){
                toAddresses.add(eachAdmin.Email);
            }
        }else{
            toAddresses.add(UserInfo.getUserEmail());
        }
        email.setToAddresses(toAddresses);
        email.setSubject('Batch Run Notification');
        email.setPlainTextBody(content);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}