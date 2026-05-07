public with sharing class ACLS_Fax_IntegrationWrapper {

    /*********************************************************************************
    Class Name     : Fax_GetToken_Response
    Description    : Used to deserialize the get access token response into wrapper.
    Variables      : access_token,expires_in,token_type,scope,secret_id,app_id,jti
    *********************************************************************************/
    public class Fax_GetTokenResponse
    {
        public String access_token;
        public String expires_in;
        public String token_type;
        public String scope;
        public String secret_id;
        public String app_id;
        public String jti;
    }

    /*********************************************************************************
    Class Name     : FaxOutboundSuccessResponse
    Description    : Used to deserialize the success Fax response into wrapper.
    Variables      : SuccessResponse
    *********************************************************************************/
	public class FaxOutboundSuccessResponse {
		public String fax_id;
		public String destination_fax_number;
	}

    /*********************************************************************************
    Class Name     : FaxOutboundFailureResponse
    Description    : Used to deserialize the failure Fax response into wrapper.
    Variables      : transaction_id,errors
    *********************************************************************************/
	public class FaxOutboundFailureResponse {
		public String transaction_id;
		public List<ErrorResponse> errors;
	}

    /***********************************************************************************************************************************************************************************************************************************************
    Class Name     : FaxGetStatusResponse
    Description    : Used to deserialize the Get Fax status response into wrapper.
    Variables      : fax_id,size,duration,pages,image_downloaded,fax_status,completed_timestamp,direction,originating_fax_number,destination_fax_number,originating_fax_tsid,destination_fax_csid,routing_data,transmission_data,client_tracking_data
    *************************************************************************************************************************************************************************************************************************************************/
	public class FaxGetStatusResponse {
		public String fax_id;
		public Integer size;
		public Integer duration;
		public Integer pages;
		public Boolean image_downloaded;
		public String fax_status;
		public String completed_timestamp;
		public String direction;
		public String originating_fax_number;
		public String destination_fax_number;
		public String originating_fax_tsid;
		public String destination_fax_csid;
		public Routing_data routing_data;
		public Transmission_data transmission_data;
		public Client_data client_tracking_data;
	}

    /***********************************************************************************************
    Class Name     : Client_data
    Description    : Prepares the wrapper data for Client Info
    Variables      : billing_code,client_code,client_id,client_matter,client_name,client_reference_id
    *************************************************************************************************/
	public class Client_data {
		public String billing_code;
		public String client_code;
		public String client_id;
		public String client_matter;
		public String client_name;
		public String client_reference_id;

	}

    /***********************************************************************************************
    Class Name     : Documents
    Description    : Prepares the wrapper data for Fax Attachments
    Variables      : document_content,document_type
    *************************************************************************************************/
	public class Documents {
		public String document_content;
		public String document_type;

		public Documents(String document_content, String document_type){
			this.document_content= document_content;
			this.document_type = document_type;
		}
	}

    /****************************************************************************************************************
    Class Name     : Fax_options
    Description    : Prepares the wrapper data for fax cover page
    Variables      : image_resolution,include_cover_page,custom_CallerID,header_options,custom_CSID,cover_page_options
    ******************************************************************************************************************/
	public class Fax_options {
		public String image_resolution;
		public String include_cover_page;
		public String custom_CallerID;
		public Header_options header_options;
		public String custom_CSID;
		public Cover_page_options cover_page_options;

		public Fax_options(String image_resolution, String include_cover_page, String custom_CallerID, Header_options header_options, String custom_CSID, Cover_page_options cover_page_options){
			this.image_resolution = image_resolution;
			this.include_cover_page = include_cover_page;
			this.custom_CallerID = custom_CallerID;
			this.header_options = header_options;
			this.custom_CSID = custom_CSID;
			this.cover_page_options = cover_page_options;
		}
	}

    /****************************************************************************************************************
    Class Name     : Header_options
    Description    : Prepares the wrapper data for fax page lines
    Variables      : line_1
    ******************************************************************************************************************/
	public class Header_options {
		public List<String> line_1;

		public Header_options(List<String> line_1){
			this.line_1 = line_1;
		}
	}

	/****************************************************************************************************************
    Class Name     : Cover_page_options
    Description    : Prepares the wrapper data for fax cover page 
    Variables      : from_name,subject,message,retry_options
    ******************************************************************************************************************/
	public class Cover_page_options {
		public String from_name;
		public String subject;
		public String message;
		public Retry_options retry_options;

		public Cover_page_options(String from_name, String subject, String message, Retry_options retry_options){
			this.from_name = from_name;
			this.subject = subject;
			this.message = message;
			this.retry_options = retry_options;
		}
	}

    /****************************************************************************************************************
    Class Name     : Retry_options
    Description    : Prepares the wrapper data for fax retry information
    Variables      : non_billable,billable,human_answer
    ******************************************************************************************************************/
	public class Retry_options {
		public Integer non_billable;
		public Integer billable;
		public Integer human_answer;

		public Retry_options(Integer non_billable, Integer billable, Integer human_answer){
			this.non_billable = non_billable;
			this.billable = billable;
			this.human_answer = human_answer;
		}
	}  

    /****************************************************************************************************************
    Class Name     : Transmission_data
    Description    : Used to deserialize the fax transmission response into wrapper.
    Variables      : transmission_status,billable_retries,error_code,error_message
    ******************************************************************************************************************/
	public class Transmission_data {
		public String transmission_status;
		public Integer billable_retries;
		public String error_code;
		public String error_message;
	}

    /****************************************************************************************************************
    Class Name     : Routing_data
    Description    : Used to deserialize the fax routing response into wrapper.
    Variables      : to_name,to_company,subject,from_name,cover_page_tags
    ******************************************************************************************************************/
	public class Routing_data {
		public String to_name;
		public String to_company;
		public String subject;
		public String from_name;
		public String cover_page_tags;
	}

    /****************************************************************************************************************
    Class Name     : ErrorResponse
    Description    : Used to deserialize the fax failure response into wrapper.
    Variables      : error_code,developer_message,user_message,more_info
    ******************************************************************************************************************/
	public class ErrorResponse{
		public String error_code;
		public String developer_message;
		public String user_message;
		public String more_info;
	}
}