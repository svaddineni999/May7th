<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>PC_WCDServiceClassName</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Service class for WCD.
Format - {&quot;defaultclass&quot;: &quot;PC_WCDRoundRobinService&quot;,&quot;classPerRole&quot;: [{&quot;role&quot;: &quot;Treating Physician&quot;,&quot;classname&quot;: &quot;PC_WCDDefaultService&quot;}]}
defaultclass applies for all roles, classPerRole is optional &amp; applies to specific roles</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_WCDServiceClassName</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">{
	&quot;defaultclass&quot;: &quot;PC_WCDRoundRobinService&quot;
}</value>
    </values>
</CustomMetadata>
