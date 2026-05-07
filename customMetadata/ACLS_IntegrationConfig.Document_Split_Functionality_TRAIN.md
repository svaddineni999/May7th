<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Document Split Functionality</label>
    <protected>false</protected>
    <values>
        <field>ACLS_APIKey__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>ACLS_BaseURL__c</field>
        <value xsi:type="xsd:string">https://ashfield4--train.sandbox.my.salesforce.com</value>
    </values>
    <values>
        <field>ACLS_Endpoint__c</field>
        <value xsi:type="xsd:string">/services/data/v56.0/connect/document-automation/contentDocuments/{ContentDocumentId}/linkedObjects/{LinkedEntityId}</value>
    </values>
    <values>
        <field>ACLS_Environment__c</field>
        <value xsi:type="xsd:string">TRAIN</value>
    </values>
    <values>
        <field>ACLS_Headers__c</field>
        <value xsi:type="xsd:string">{
&quot;Authorization&quot;:&quot;Bearer &quot;,
&quot;Content-Type&quot;:&quot;application/json&quot;
}</value>
    </values>
    <values>
        <field>ACLS_IntegrationName__c</field>
        <value xsi:type="xsd:string">HC Split</value>
    </values>
    <values>
        <field>ACLS_Integration_Procedure_Name__c</field>
        <value xsi:type="xsd:string">ACLS_IP_Document_Split</value>
    </values>
    <values>
        <field>ACLS_Timeout__c</field>
        <value xsi:type="xsd:double">120000.0</value>
    </values>
</CustomMetadata>
