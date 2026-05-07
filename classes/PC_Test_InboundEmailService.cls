/*********************************************************************************************************
Class Name      : PC_Test_InboundEmailService
Description     : Test class to cover PC_InboundEmailService
Created By      : Tetiana Danylyshyn
Created Date    : June 1, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn         June 1, 2016           Initial Version
Mayuresh Patil			   June 26, 2017		  PC-1670 Updated test class to reflect the changes done to the PC_InboundEmailService class
****************************************************************************************************************/
@isTest
private class PC_Test_InboundEmailService {

    /*********************************************************************************
    Method Name    : testControllerMethod
    Description    : test inbound functionality
    Parameters     : none
    Return Type    : void
    *********************************************************************************/
	@isTest static void testControllerMethod(){

		User objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test67.com', 'test67');
		objUser = (User)PC_Database.ins(objUser, false);
        system.assert(objUser.Id != null);


        System.runAs(objUser) {
        	// Create a new email, envelope object and Attachment
        	Messaging.InboundEmail email = new Messaging.InboundEmail();
        	Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

	        email.subject = 'Test Email';
	        email.fromName = 'test test';
	        email.plainTextBody = 'Hello, this a test email body. For testing purposes only. Phone:123456 Bye';
	        email.htmlBody = '<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns:m="http://schemas.microsoft.com/office/2004/12/omml" xmlns="http://www.w3.org/TR/REC-html40">'+

			'<head>'+
			'<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">'+
			'<meta name="Generator" content="Microsoft Word 15 (filtered medium)">'+
			'</style><!--[if gte mso 9]><xml>'+
			'<o:shapedefaults v:ext="edit" spidmax="1026" />'+
			'</xml><![endif]--><!--[if gte mso 9]><xml>'+
			'<o:shapelayout v:ext="edit">'+
			'<o:idmap v:ext="edit" data="1" />'+
			'</o:shapelayout></xml><![endif]-->'+
			'</head>'+
			'<body lang="EN-US" link="#0563C1" vlink="#954F72">'+
			'<div class="WordSection1">'+
			'<p class="MsoNormal">Hi Team, <o:p></o:p></p>'+
			'<p class="MsoNormal"><o:p>&nbsp;</o:p></p>'+
			'<p class="MsoNormal"><o:p>&nbsp;</o:p></p>'+
			'<p class="MsoNormal"><o:p>&nbsp;</o:p></p>'+
			'<p class="MsoNormal"><img width="371" height="297" style="width:3.8611in;height:3.0972in" id="Picture_x0020_1" src="cid:image001.png@01D53264.D0C49440"><o:p></o:p></p>'+
			'<p class="MsoNormal"><o:p>&nbsp;</o:p></p>'+
			'<p class="MsoNormal"><o:p>&nbsp;</o:p></p>'+
			'<p class="MsoNormal">Regards,<o:p></o:p></p>'+
			'<p class="MsoNormal">Shishir<o:p></o:p></p>'+
			'</div>'+
			 '<p>This message (including any attachments) contains confidential information intended for a specific individual and purpose, and is protected by law. If you are not the intended recipient, you should delete this message and any disclosure, copying, or distribution'+
			'of this message, or the taking of any action based on it, by you is strictly prohibited.</p>'+
			'<p>Deloitte refers to a Deloitte member firm, one of its related entities, or Deloitte Touche Tohmatsu Limited (&quot;DTTL&quot;). Each Deloitte member firm is a separate legal entity and a member of DTTL. DTTL does not provide services to clients. Please see www.deloitte.com/about'+
			'to learn more.</p>'+
			'<p>v.E.1</p>'+
			'</body>'+
			'</html>';

	        //create test BinaryAttachment
	        Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];
	        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
	        binaryAttachment.Filename = 'image001.png';
	        binaryAttachment.mimeTypeSubType = 'image/png';

	        String algorithmName = 'HMacSHA1';
	        Blob b = Crypto.generateMac(algorithmName, Blob.valueOf('test'), Blob.valueOf('test_key'));
	         binaryAttachment.Body = b;


			Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
			binaryAttachment.headers=new Messaging.InboundEmail.Header[1];
			hditem.name='<image001.png@01D53264.D0C49440>'; hditem.value='<image001.png@01D53264.D0C49440>';
			binaryAttachment.headers[0]=hditem;


	        binaryAttachments[0] =  binaryAttachment;
	        email.binaryAttachments = binaryAttachments;

	        //create test TextAttachment
	        Messaging.Inboundemail.TextAttachment[] textAttachments = new Messaging.Inboundemail.TextAttachment[1];
	        Messaging.Inboundemail.TextAttachment textAttachment = new Messaging.Inboundemail.TextAttachment();
	        textAttachment.Filename = 'test1.txt';
	        textAttachment.Body = 'test body';
	        textAttachments[0] =  textAttachment ;
	        email.textAttachments = textAttachments;

	        envelope.fromAddress = 'user@acme.com';

	        Test.StartTest();


                Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();




	           // PC_InboundEmailService controller = new PC_InboundEmailService();
	           // Messaging.InboundEmailResult result = controller.handleInboundEmail(email, envelope);

	            // Exception Case
	            /*Messaging.InboundEmail emailException = new Messaging.InboundEmail();
	            Messaging.InboundEnvelope envelopeException = new Messaging.InboundEnvelope();
	            Messaging.InboundEmailResult resultnew = controller.handleInboundEmail(emailException, envelopeException);
	            System.assertEquals(resultnew.success, false);*/
                Boolean isInboundFilesInserted = PC_InboundEmailService.createInboundRecord(email, envelope, true);
                System.assertEquals(isInboundFilesInserted, true);

                Boolean isInboundAttachmentsInserted = PC_InboundEmailService.createInboundRecord(email, envelope, false);
                System.assertEquals(isInboundAttachmentsInserted, true);

                PC_InboundEmailService controller = new PC_InboundEmailService();
                Messaging.InboundEmailResult negativeResult =  controller.handleInboundEmail(null, envelope);
                System.assertEquals(negativeResult.success, false);
	        Test.StopTest();
        }

    }
}