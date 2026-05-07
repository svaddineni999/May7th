<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Reminder Channel and Handler Mapping</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">This setting contains the mapping of channel and handler class that processes queue records.If channel is Other in Reminder Setting, provide Other Channel Name of Reminder Setting in channel value of JSON.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_ReminderChannelHandlerMapping</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">[{&quot;channel&quot;:&quot;Email&quot;,&quot;handler&quot;:&quot;PC_SendRemindersViaEmail&quot;},{&quot;channel&quot;:&quot;SMS&quot;,&quot;handler&quot;:&quot;PC_SendRemindersViaSMS&quot;}]</value>
    </values>
</CustomMetadata>
