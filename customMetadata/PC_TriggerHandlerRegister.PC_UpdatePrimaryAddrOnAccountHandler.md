<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>PC_UpdatePrimaryAddrOnAccountHandler</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_ApexClass__c</field>
        <value xsi:type="xsd:string">PC_UpdatePrimaryAddrOnAccountHandler</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Updates the primary addresses on accounts for both single address record entry and bulk  address upload. It also takes care of the scenario to set the address field on Account record to null when the same address record is marked as non-primary manually.</value>
    </values>
    <values>
        <field>PC_OrderOfExecution__c</field>
        <value xsi:type="xsd:double">2.0</value>
    </values>
    <values>
        <field>PC_OtherObject__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_sObject__c</field>
        <value xsi:type="xsd:string">PC_Address__c</value>
    </values>
</CustomMetadata>
