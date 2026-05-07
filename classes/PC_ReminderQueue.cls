/**
 * Interface to fetch recipients for sending reminders.
 * Reminder Queue will be created for each recipient.
 * Reminder setting is required in Request to get the eLetter recipients.
 */

global class PC_ReminderQueue{
    /**
    * Global enum to define the recipients channel so that address is used correctly
    */
    global enum RecipientChannel{EMAIL, SMS, OTHER}

    /**
    * Interface to be implemented to get the recipients for records on
    * which reminder queues have to be created.
    */
    global interface RecipientFinder{
        RecipientsResponse getRecipients(RecipientsRequest recipientsRequest);
    }

    /**
    * Recipients request must contain the record details and reminder setting metadata.
    */
    global inherited sharing class RecipientsRequest{
        global List<RecordDetail> recordDetails{get;set;}
        global PC_ReminderSetting__mdt setting{get;set;}
    }

    /**
    * Recipients response will contain the record detail and recipients.
    */
    global inherited sharing class RecipientsResponse{
        global List<RecordRecipientDetail> recordRecipientDetails{get;set;}
        global RecipientsResponse(){}
    }

    /**
    * Record detail will be used to get recipients related to the record id.
    */
    global inherited sharing class RecordDetail{
        global String recordId{get;set;}
    }

    /**
    * Record Recipient detail will be used to create queues for the given record id.
    */
    global inherited sharing class RecordRecipientDetail{
        global String recordId{get;set;}
        global List<RecipientDetail> recipientDetails{get;set;}
    }

    /**
    * Recipient detail will be used while sending the reminder.
    */
    global inherited sharing class RecipientDetail{

        //Stores the Id of the recipient
        global String id{get; set;}

        //Stores the name of the Recipient
        global String name{get; set;}

        //Stores the channel in which the Recipient info is used
        global RecipientChannel channel{get; set;}

        //Stores the phone number/email address of the recipient.
        global String address{get; set;}

        //Stores the type of the recipient i.e. user or account
        global String type{get;set;}

        //Stores the Association record Id
        global String associationId{get; set;}

        //Stores additional information if any
        global String additionalInfo{get; set;}
        global RecipientDetail() {
            this.name = PC_Constants.EMPTY_STRING;
            this.address = PC_Constants.EMPTY_STRING;
            this.channel = RecipientChannel.EMAIL;
            this.id = PC_Constants.EMPTY_STRING;
            this.type = PC_Constants.EMPTY_STRING;
            this.associationId = PC_Constants.EMPTY_STRING;
            this.additionalInfo = PC_Constants.EMPTY_STRING;
        }
    }
}