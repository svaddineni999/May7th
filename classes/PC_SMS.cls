/***************************************************************************************************************
Class Name      : PC_SMS
Description     : This class is used for integration with external Sms Service.
Created By      : Chetna Mohapatra
Created Date    : 01-Dec-2020
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Hitha Avalakki         Feb 02, 2018           Initial Version
Vijay Kashikar         21-Jan-21              [PC-7102] Added sharing clause
****************************************************************************************************************/
    /**
     * This class is used for integration with external Sms Service.
     */
    global with sharing class PC_SMS {
        /**
         * This interface should be implemented by all sms service class to be able to integrate with our Messaging feature
         */
        global interface Sender {
            /**
             * The method to process the send request
             *
             * @param request
             */
            void send(SenderRequest request);
        }
        /**
         * The wrapper class containing the request parameters
         */
        global inherited sharing class SenderRequest {
           /**
            * The list of Message Ids pertaining to each Message Record.
            */
           global List<Id> messageIds;

           global SenderRequest() {
                messageIds = new List<Id>();
            }
        }

        /**
         * This interface should be implemented by all batch sms service class to be able to integrate with our Messaging feature
         * synchronously as future methods are not allowed in batch class
         */
        global interface BatchSender {
            /**
             * The method to process the send request
             *
             * @param request
             */
            BatchSenderResponse send(BatchSenderRequest request);
        }
        /**
         * The wrapper class containing the request parameters
         */
        global inherited sharing class BatchSenderRequest {
            /**
            * The list of Messages pertaining to each Message Record without Id.
            */
            global List<PC_Message__c> messageDetails;

            global BatchSenderRequest() {
                messageDetails = new List<PC_Message__c>();
            }
        }
        /**
         * The wrapper class containing the request parameters
         */
        global class BatchSenderResponse{
            /**
            * The list of Message Ids pertaining to each Message Record.
            */
            global List<String> messageIds;

            global BatchSenderResponse() {
                messageIds = new List<String>();
            }
        }

        /**
       * A custom Exception class for SMS
       */
        global inherited sharing class SMSException extends Exception {}
        /**
         * Constants for Message Status Values.
         */
        public static final String PC_SMS_DRAFT= 'Draft';
        public static final String PC_SMS_QUEUED= 'Queued';
        public static final String PC_SMS_ACCEPTED= 'Accepted';
        public static final String PC_SMS_SENDING= 'Sending';
        public static final String PC_SMS_SENT= 'Sent';
        public static final String PC_SMS_FAILED= 'Failed';
        public static final String PC_SMS_DELIVERED= 'Delivered';
        public static final String PC_SMS_UNDELIVERED= 'Undelivered';
        public static final String PC_SMS_RECEIVING= 'Receiving';
        public static final String PC_SMS_RECEIVED= 'Received';


    }