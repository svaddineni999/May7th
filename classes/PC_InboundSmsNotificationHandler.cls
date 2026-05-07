/**********************************************************************************************************************************************
Class Name      : PC_InboundSmsNotificationHandler
Description     : Trigger on Message object that creates notification when Inbound message gets created.
Created By      : Chetna Mohapatra
Created Date    : Oct 15, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Chetna Mohapatra          Oct 15, 2021           Initial Version
Satheesh Kumar            Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
************************************************************************************************************************************************/
    public inherited sharing class PC_InboundSmsNotificationHandler extends PC_TriggerHandler {
        override public void afterInsert() {
            try {
                notifyForInboundSms((List<PC_Message__c>) newList);
            }catch(Exception ex){
                PC_Utility.logAndThrowException(ex);
            }
        }
        /************************************************************************************
       Method Name    : notifyForInboundSms
       Author         : Chetna Mohapatra
       Description    : This method is to create the custom notification
       Return Type    : void
       Parameter      : List of new message records- messages
       ***************************************************************************************/
        private void notifyForInboundSms(List<PC_Message__c> messages) {
            Set<Id> senderAccountIdSet = new Set<Id>();
            Set<Id> caseIdSet= new Set<Id>();
            for (PC_Message__c msg : messages) {
                if (msg.PC_Type__c == PC_Constants.INBOUND && msg.PC_Case__c != null && msg.PC_SenderAccount__c != null) {
                    senderAccountIdSet.add(msg.PC_SenderAccount__c);
                    caseIdSet.add(msg.PC_Case__c);
                }
            }
            //FLS is NOT needed in Triggers, as they always run in System Mode.
            /*// FLS Check
            List<String> accountFields = new List<String>{'Id', 'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields); */
            //Query and store the sender account details in a Map
            Map<Id, Account> accountMap= new Map<Id, Account>([SELECT Id,Name FROM Account WHERE ID IN: senderAccountIdSet]);

            /*// FLS Check
            List<String> caseFields = new List<String>{'Id', 'OwnerId', PC_Constants.getQualifiedAPIName('PC_Care_Coordinator__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);*/
            //Query and store the sender account details in a Map
            Map<Id, Case> caseMap= new Map<Id, Case>([SELECT Id,OwnerId, PC_Care_Coordinator__c FROM Case WHERE ID IN: caseIdSet]);

            Account senderAccount= new Account();
            Case senderCase= new Case();
            String ownerId, caseId, senderName,subject= PC_Constants.EMPTY_STRING;
            String notificationBody,notificationTargetId, notificationTitle = PC_Constants.EMPTY_STRING;
            List<CustomNotificationType> notificationTypeList = new List<CustomNotificationType>();
            // Get the List of Id for our custom notification type
            notificationTypeList = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = :PC_Constants.PC_INBOUND_SMS_NOTIFICATION_DEVELOPER_NAME];
            if (notificationTypeList!=null && !notificationTypeList.isEmpty()) {
                for (PC_Message__c msg : messages) {
                    if (msg.PC_Type__c == PC_Constants.INBOUND && msg.PC_Case__c != null && msg.PC_SenderAccount__c != null) {
                        if (accountMap.containsKey(msg.PC_SenderAccount__c)) {
                            senderAccount = accountMap.get(msg.PC_SenderAccount__c);
                            if (senderAccount.Name != null) {
                                senderName = senderAccount.Name;
                                notificationTitle=String.format(System.Label.PC_InboundMessageTitle, new List<String>{ senderName });
                            }
                        }
                        if (caseMap.containsKey(msg.PC_Case__c)) {
                            senderCase = caseMap.get(msg.PC_Case__c);
                            if(senderCase.PC_Care_Coordinator__c !=null){
                                ownerId= senderCase.PC_Care_Coordinator__c;
                            }
                            else if ( senderCase.PC_Care_Coordinator__c == null && senderCase.OwnerId != null) {
                                ownerId = senderCase.OwnerId;
                            }
                        }
                        notificationBody = System.Label.PC_InboundMessageNotificationBody;
                        notificationTargetId= msg.Id;
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        // Set the contents for the notification
                        notification.setTitle(notificationTitle);
                        notification.setBody(notificationBody);

                        // Set the notification type and target
                        notification.setNotificationTypeId(notificationTypeList[0].Id);
                        notification.setTargetId(notificationTargetId);
                        Set<String> recipientsIds = new Set<String>();
                        //Assigning the case owner as the recipient.
                        recipientsIds.add(ownerId);
                        // Actually send the notification
                        try {
                            notification.send(recipientsIds);
                        } catch (Exception e) {
                            System.debug('Problem sending notification: ' + e.getMessage());
                            PC_Utility.createExceptionLog(e);
                        }

                    }
                }
            }

        }
    }