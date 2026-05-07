/*****************************************************************************************
Class Name    	: PC_AWS
Description     : AWS Abstract Class which helps to generate authentication information for AWS API request.
Created By      : Deloitte
Created Date    : May 03, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 03, 2021           Initial Version
*********************************************************************************************/
// Credits to brianmfear (https://gist.github.com/brianmfear/92cf05807ac4becbd21f)

public abstract class PC_AWS {
    //	Post initialization logic (after constructor, before call)
    protected abstract void init();

    //	Things we need to know about the service. Set these values in init()
    protected String host, region, service, resource, accessKey, payloadSha256;
    protected Url endpoint;
    protected HttpMethod method;
    protected Blob payload;

    //	Not used externally, so we hide these values
    Blob signingKey;
    String signature;
    String canonicalRequest;
    DateTime requestTime;
    Map<String, String> queryParams, headerParams;

    public enum HttpMethod { XGET, XPUT, XHEAD, XOPTIONS, XDELETE, XPOST }

    //	Call this constructor with super() in subclasses
    public PC_AWS() {
        requestTime = DateTime.now();
        queryParams = new Map<String, String>();
        headerParams = new Map<String, String>();
    }

    //	Actually perform the request, and throw exception if response code is not valid
    public HttpResponse sendRequest(HttpRequest request) {
        HttpResponse response = new Http().send(request);
        return response;
    }

    public HttpRequest generateHttpRequest() {
        String stringToSign;
        String finalEndpoint;
        String queryString;
        String canonicalHeaders;

        HttpRequest request = new HttpRequest();
        init();

        payloadSha256 = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', payload));
        if (host == null) {
            host = endpoint.getHost();
        }
        setHeader('Host', host);
        setHeader('X-Amz-Content-Sha256', payloadSha256);
        setHeader('X-Amz-Date', requestTime.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\''));

        List<String> headerKeys = new List<String>(headerParams.keySet());
        headerKeys.sort();

        //Create the signature
        queryString = createCanonicalQueryString();
        canonicalHeaders = createCanonicalHeaders();
        canonicalRequest = createCanonicalRequest(queryString, canonicalHeaders, headerKeys);
        stringToSign = createStringToSign(canonicalRequest);
        createSignature(stringToSign);

        request.setMethod(method.name().removeStart('X'));

        for (String key : headerParams.keySet()) {
            request.setHeader(key, headerParams.get(key));
        }
        request.setHeader('Authorization', String.format('AWS4-HMAC-SHA256 Credential={0},SignedHeaders={1},Signature={2}',
                new String[]{ String.join(new String[]{ accessKey, requestTime.formatGMT('YYYYMMdd'), region, service, 'aws4_request'}, '/'), String.join(headerKeys, ';'), signature }
        ));
        request.setBodyAsBlob(payload);

        finalEndpoint = new Url(endpoint, resource).toExternalForm();
        if (queryString != '') {
            finalEndpoint += '?' + queryString;
        }
        request.setEndpoint(finalEndpoint);
        return request;
    }

    protected void createSigningKey(String secretKey) {
        Blob dateKey = HMAC(Blob.valueOf(requestTime.formatGMT('yyyyMMdd')), Blob.valueOf('AWS4' + secretKey));
        Blob dateRegionKey = HMAC(Blob.valueOf(region), dateKey);
        Blob dateRegionServiceKey = HMAC(Blob.valueOf(service), dateRegionKey);
        signingKey = HMAC(Blob.valueOf('aws4_request'), dateRegionServiceKey);
    }

    //	Create a canonical query string (used during signing)
    String createCanonicalQueryString() {
        List<String> results = new List<String>();
        List<String> keys = new List<String>(queryParams.keySet());
        keys.sort();
        for (String key : keys) {
            results.add(key + '=' + queryParams.get(key));
        }
        return String.join(results, '&');
    }

    //	Create the canonical headers (used for signing)
    String createCanonicalHeaders() {
        List<String> results = new List<String>();
        List<String> keys = new List<String>(headerParams.keySet());
        keys.sort();
        for (String key : keys) {
            results.add(key + ':' + headerParams.get(key));
        }
        return String.join(results, '\n') + '\n';
    }

    // Create the entire canonical request
    String createCanonicalRequest(String queryString, String canonicalHeaders, String[] headerKeys) {
        String result = String.join(
                new List<String>{
                        method.name().removeStart('X'),         //	METHOD
                        new Url(endPoint, resource).getPath(),  //	RESOURCE
                        queryString,                            //	CANONICAL QUERY STRING
                        canonicalHeaders,                       //	CANONICAL HEADERS
                        String.join(headerKeys, ';'),           //	SIGNED HEADERS
                        payloadSha256                           //	SHA256 PAYLOAD
                },
                '\n');
        return result;
    }

    /**	Create the entire string to sign */
    String createStringToSign(String canonicalRequest) {
        String result = String.join(
                new List<String>{
                        'AWS4-HMAC-SHA256', requestTime.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\''),
                        String.join(new List<String>{requestTime.formatGMT('yyyyMMdd'), region, service, 'aws4_request'}, '/'),
                        EncodingUtil.convertToHex(Crypto.generateDigest('sha256', Blob.valueof(canonicalRequest)))
                }, '\n');
        return result;
    }

    /** Create Signature */
    private void createSignature(String stringToSign) {
        signature = EncodingUtil.convertToHex(HMAC(blob.valueof(stringToSign), signingKey));
    }

    /** HMAC represents HMAC-SHA256 function that returns output in binary format*/
    private Blob HMAC(Blob msg, Blob key) {
        return Crypto.generateMac('HMACSHA256', msg, key);
    }

    //	We have to replace ~ and " " correctly, or we'll break AWS on those two characters
    protected string uriEncode(String value) {
        return value == null ? null : EncodingUtil.urlEncode(value, 'utf-8').replaceAll('%7E', '~').replaceAll('\\+', '%20');
    }

    protected void setHeader(String key, String value) {
        headerParams.put(key.toLowerCase(), value);
    }

    protected void setQueryParam(String key, String value) {
        queryParams.put(key.capitalize(), UriEncode(value));
    }
}