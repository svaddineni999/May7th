<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Maximum Support Plan Recursions allowed</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Max no. of times a Support Plan is allowed to execute recursively. If the value is blank, 10 is considered as limit &amp; execution will be stopped after the 10th recursion. However, ensure to define conditions so as to avoid recursion.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_MaxSPRecursiveExecutionsAllowed</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">10</value>
    </values>
</CustomMetadata>
