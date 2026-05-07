<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Batch Job Properties</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Batch properties for batch classes of Patient Connect Package. Valid format -[{&quot;jobName&quot;:&quot;PC_ProcessQueuesInBatch&quot;,&quot;size&quot;:50,&quot;folderPath&quot;:&quot;&quot;,&quot;notifyAllAdmins&quot;:true}]. If folderPath is blank Personal documents folder will be used for storing logs.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_BatchJobProperties</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">[{&quot;jobName&quot;:&quot;PC_ProcessQueuesInBatch&quot;,&quot;size&quot;:50,&quot;folderPath&quot;:&quot;PatientConnect__PC_BatchLogs&quot;,&quot;notifyAllAdmins&quot;:false},{&quot;jobName&quot;:&quot;PC_PurgeBatch&quot;,&quot;size&quot;:50,&quot;folderPath&quot;:&quot;&quot;,&quot;notifyAllAdmins&quot;:false}]</value>
    </values>
</CustomMetadata>
