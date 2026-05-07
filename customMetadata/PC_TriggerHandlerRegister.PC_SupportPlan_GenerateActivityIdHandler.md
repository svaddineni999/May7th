<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>PC_SupportPlan_GenerateActivityIdHandler</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_ApexClass__c</field>
        <value xsi:type="xsd:string">PC_SupportPlan_GenerateActivityIdHandler</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Handler to generate a unique Internal Activity Number for each Support Plan Activity on AfterInsert. This must be active to execute a Support plan.</value>
    </values>
    <values>
        <field>PC_OrderOfExecution__c</field>
        <value xsi:type="xsd:double">1.0</value>
    </values>
    <values>
        <field>PC_OtherObject__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_sObject__c</field>
        <value xsi:type="xsd:string">PC_SupportPlanActivity__c</value>
    </values>
</CustomMetadata>
