<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Purge Batch Setting</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Setting to define the scope &amp; other settings for PC_PurgeBatchScheduler. &apos;context&apos; defines the query used and &apos;offset&apos; defines the offset w.r.t today to filter records based on time. You may set offset, other properties &amp;amp; the right context as needed.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_PurgeBatchSetting</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">{&quot;scope&quot;:[{&quot;context&quot;:&quot;SPAL_RO&quot;,&quot;offset&quot;:365},{&quot;context&quot;:&quot;SPAL_NRO&quot;,&quot;offset&quot;:365},{&quot;context&quot;:&quot;ERR&quot;,&quot;offset&quot;:365},{&quot;context&quot;: &quot;MSG_TWL&quot;,&quot;offset&quot;:365},{&quot;context&quot;:&quot;RSL&quot;,&quot;offset&quot;:365},{&quot;context&quot;:&quot;RQ&quot;,&quot;offset&quot;:365}],&quot;emptyRecycleBin&quot;:true}</value>
    </values>
</CustomMetadata>
