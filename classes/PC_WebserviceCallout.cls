/******************************************************************************
 Modification Log:
 -------------------------------------------------------------------------------
 Developer           	Date           	Description
 -------------------------------------------------------------------------------
 Ajinkya Deshmukh     	1/17/2017       Initial Version
 Ajinkya Deshmukh		6/23/2017		with sharing keyword added
 Mike Klumpenaar		2/25/2019		PC-4474 Updated comments and cleanup
*******************************************************************************/

/**
 *  Generic method for webservice callouts.
 *
 *  @author Ajinkya Deshmukh
 *  @date 1/17/2017
 */
public with sharing class PC_WebserviceCallout {
	/**
	 * Perform an HTTP callout to the given endpoint
	 *
	 * @param httpMethod			The HTTP method to use
	 * @param endpoint				The endpoint URL
	 * @param body					The body to send
	 * @param authorizationHeader	An optional base 64 encoded authorization header
	 *
	 * @return The HTTP response from the remote service.
	 */
	public static HttpResponse callout(String httpMethod, String endpoint, String body, String username, String password){
		//Instantiate an httpRequest and set the required attributes
		HttpRequest req = new HttpRequest();
		req.setMethod(httpMethod);
		req.setEndpoint(endpoint);		
		//Optional attributes
		req.setHeader('Content-Type', 'application/json');		
		// only if Authorization is needed 
		if (String.isNotBlank(username) && String.isNotBlank(password)) {
			String authorizationHeader = authorizationHeader(username, password);
			req.setHeader('Authorization', authorizationHeader);
		}

        // only if body is set
        if (String.isNotBlank(body)) {
			req.setBody(body);
		}
		//You can adjust the timeout duration (in milliseconds) to deal with slow servers or large payloads
		req.setTimeout(120000);

        return new Http().send(req);
	}

	/**
	 * Creates the base 64 encoded authorization header value
     */
	private static String authorizationHeader(String username, String password){
		Blob headerValue = Blob.valueOf(userName + ':' + password);
		String authorization = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
		return authorization;
	}
}