public with sharing class ACLS_SMS_IntegrationWrapper {
    
    /*********************************************************************************
    Class Name     : SMS_OptIn_Request
    Description    : Prepares the data to make the optin callout
    Return Type    : 
    Varaibles      : CampaignName,State,PhoneNumber,MessageText
    *********************************************************************************/
    public class SMS_OptIn_Request
    {

        public String campaignName;
        public String State;
        public String clientHandle;
        // String MessageText;

        

        public SMS_OptIn_Request(String campaignName,String State, String clientHandle)
        {

            this.campaignName= campaignName;
            this.State = State;
            this.clientHandle = clientHandle;
            // this.MessageText = MessageText;
        }

    }

    /*********************************************************************************
    Class Name     : SendSMS_Request
    Description    : Prepares the data to make the getToken callout
    Return Type    : 
    Varaibles      : CampaignName,State,PhoneNumber,MessageText
    *********************************************************************************/
    public class SendSMS_Request
    {

        public String campaignName;
        public String message;
        public String name;
        public List<Recipients> recipients;
        public SendSMS_Request(String campaignName,String message, String name, List<Recipients> recipients)
        {

            this.campaignName= campaignName;
            this.message = message;
            this.name = name;
            this.recipients = recipients;            
        }
    
    }
    
    public class Recipients {
        public String toPhoneNumber;

        public Recipients(String toPhoneNumber){
            this.toPhoneNumber = toPhoneNumber;
        }
    }

    /*********************************************************************************
    Class Name     : SMS_GetToken_Response
    Description    : Prepares the data to get the get token
    Return Type    : 
    Varaibles      : access_token,expires_in,token_type
    *********************************************************************************/
    public class SMS_GetToken_Response
    {

        public String access_token;
        public String expires_in;
        public String token_type;

    }

    /*********************************************************************************
    Class Name     : SMS_SendSMS_Response
    Description    : Prepares the data to get the send MSS response
    Return Type    : 
    Varaibles      : sendSmsTaskId,uri
    *********************************************************************************/
    public class SMS_SendSMS_Response
    {

        public String sendSmsTaskId;
        public String uri;

    }


    /*********************************************************************************
    Class Name     : SMS_GetMessageList_Response
    Description    : Prepares the data to make the list_sms_tasks callout
    *********************************************************************************/

    public class SMS_GetMessageList_Response {
        public String createdOn;
        public String createdBy;
        public String lastModifiedOn;
        public String lastModifiedBy;
        public String campaignName;
        public Object dispositionName;
        public String message;
        public Object scheduledTime;
        public Attributes attributes;
        public String name;
        public String sendSmsTaskId;
        public String status;
        public List<TaskProgress> taskProgress;
    }

	public class Attributes {
	}

	public class TaskProgress {
		public Integer count;
		public String status;
	}
    
}