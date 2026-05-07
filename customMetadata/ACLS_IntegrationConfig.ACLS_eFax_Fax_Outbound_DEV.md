<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>eFax Fax Outbound</label>
    <protected>false</protected>
    <values>
        <field>ACLS_APIKey__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>ACLS_BaseURL__c</field>
        <value xsi:type="xsd:string">https://api.securedocex.com</value>
    </values>
    <values>
        <field>ACLS_Endpoint__c</field>
        <value xsi:type="xsd:string">/faxes</value>
    </values>
    <values>
        <field>ACLS_Environment__c</field>
        <value xsi:type="xsd:string">DEV</value>
    </values>
    <values>
        <field>ACLS_Headers__c</field>
        <value xsi:type="xsd:string">{
&quot;Authorization&quot;:&quot;Bearer &quot;,
&quot;Content-Type&quot;:&quot;application/json&quot;,
&quot;user-id&quot;:&quot;23e7f6bd-0385-4e17-ae3d-7680c3e4fe45&quot;
}</value>
    </values>
    <values>
        <field>ACLS_IntegrationName__c</field>
        <value xsi:type="xsd:string">eFax Fax SendFax</value>
    </values>
    <values>
        <field>ACLS_Integration_Procedure_Name__c</field>
        <value xsi:type="xsd:string">ACLS_IP_Fax_SendFax</value>
    </values>
    <values>
        <field>ACLS_Timeout__c</field>
        <value xsi:type="xsd:double">120000.0</value>
    </values>
</CustomMetadata>
