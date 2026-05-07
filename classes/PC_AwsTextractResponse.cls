/*****************************************************************************************
Class Name    	: PC_AwsTextractResponse
Description     : AWS Textract Response Wrapper Class.
Created By      : Deloitte
Created Date    : May 10, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 10, 2021           Initial Version
*********************************************************************************************/

public with sharing class PC_AwsTextractResponse {
    public String AnalyzeDocumentModelVersion;
    public DocumentMetadata DocumentMetadata;
    public String JobStatus;
    public String HttpStatusCode;
    public String StatusMessage;
    public String NextToken;
    public List<PC_AwsTextractParser.Block> Blocks;

    public inherited sharing class DocumentMetadata {
        public Integer Pages;
    }

    public static List<PC_AwsTextractResponse> parse(String json) {
        return (List<PC_AwsTextractResponse>) System.JSON.deserialize(json, List<PC_AwsTextractResponse>.class);
    }
}