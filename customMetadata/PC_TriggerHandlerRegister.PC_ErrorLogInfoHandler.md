<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>PC_ErrorLogInfoHandler</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_ApexClass__c</field>
        <value xsi:type="xsd:string">PC_ErrorLogInfoHandler</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Used to create error logs with all error details when error log info platform event is published. PC Trigger on Error log Info platform event will be executed only if this is active.</value>
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
        <value xsi:type="xsd:string">PC_Error_Log_Info__e</value>
    </values>
</CustomMetadata>
