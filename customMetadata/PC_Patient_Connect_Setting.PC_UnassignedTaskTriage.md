<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Unassigned Task Triage</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Provide one of the following values for use in trigger handler to assign Tasks if the designated role is blank
{&quot;type&quot; : &quot;User&quot;, &quot;value&quot; : &quot;UserName&quot;}
{&quot;type&quot; : &quot;Queue&quot;, &quot;value&quot; : &quot;QueueDeveloperName&quot;}
{&quot;type&quot; : &quot;CaseOwner&quot;}
{&quot;type&quot; : &quot;LoggedInUser&quot;}</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_UnassignedTaskTriage</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:nil="true"/>
    </values>
</CustomMetadata>
