<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>PC_GeocodeAPIEndPointURL</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Used to populate BillingLatitude and BillingLongitude on Billing Address on creation of Patient Person Account. It holds Google Geocode Endpoint URL. Placeholders {0} and {1} dynamically get replaced with Address and Google Api Key respectively.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_GeocodeAPIEndPointURL</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">https://maps.googleapis.com/maps/api/geocode/json?address={0}&amp;sensor=false&amp;key={1}</value>
    </values>
</CustomMetadata>
