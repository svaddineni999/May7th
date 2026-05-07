<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>PC_ClearBillingAddrsOnAccountAfterDelete</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_ApexClass__c</field>
        <value xsi:type="xsd:string">PC_ClearBillingAddrsOnAccountAfterDelete</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Clears the Billing Address when Address records are deleted and the associated account is left with zero address records.</value>
    </values>
    <values>
        <field>PC_OrderOfExecution__c</field>
        <value xsi:type="xsd:double">4.0</value>
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
