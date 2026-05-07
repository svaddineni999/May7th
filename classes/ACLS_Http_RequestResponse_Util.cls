/*********************************************************************************************************
Class Name      : ACLS_Http_RequestResponse_Util
Description     : This class provides the service to send request using HTTP send() and give back the response. 
Created By      : Vartika Goyal
Created Date    : Mar 21st 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
Vartika Goyal               Mar 21st 2023           Initial Version
-------------------------------------------------------------------------------------------------------------- */   
public with sharing class ACLS_Http_RequestResponse_Util {
    /*********************************************************************************
    Method Name    : handleHTTPCallouts
    Description    : Method to send request using HTTP send() and give back the response. 
    Return Type    : HttpResponse
    *********************************************************************************/
    public static HttpResponse handleHTTPCallouts(String restMethod, Map<String, String> mapHeader, String endPoint, String body, Integer timeout, String certificate) {
        HttpRequest req = new HttpRequest(); 
        Http http = new Http();
        HTTPResponse res;

        req.setMethod(restMethod);

        if(timeOut!=null){
            req.setTimeout(timeOut);
            
        }
        if(endPoint!=null){
            req.setEndpoint(endPoint);
        	
        }
        if(body!=null){
            req.setBody(body);
        	
        }
        if(Certificate!=null){
            req.setClientCertificateName(certificate);
        	
        }
        if(mapHeader!=null){
            
        for(String key : mapHeader.keySet()){
            
            req.setHeader(key,mapHeader.get(key));
            
            
        } 
        }   
                
        return http.send(req); 
        
    }
}