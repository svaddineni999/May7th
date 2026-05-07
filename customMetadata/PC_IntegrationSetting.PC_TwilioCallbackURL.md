<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Twilio Callback URL</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">API URL for Twilio Callback.The URL structure should be as follows,
&lt; site domain address&gt;/services/apexrest/&lt;OrgNamespace&gt;/&lt;RestService URLMapping&gt;/?name=&lt;token parameter&gt;
Use Twilio Token Parameter to configure the &lt;token parameter&gt; for this URL.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_TwilioCallbackURL</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:nil="true"/>
    </values>
</CustomMetadata>
