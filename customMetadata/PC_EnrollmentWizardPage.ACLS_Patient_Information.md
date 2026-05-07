<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Patient Information</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_ComponentName__c</field>
        <value xsi:type="xsd:string">ACLS_AddressValidation_PatientInfoEW</value>
    </values>
    <values>
        <field>PC_Config2__c</field>
        <value xsi:type="xsd:string">{&quot;patientInfo&quot;:{&quot;fieldSetNames&quot;: [&quot;PC_Patient_Information&quot;,
&quot;PC_Communication_Preference&quot;,&quot;ACLS_Caregiver_Information&quot;]}
,&quot;addressInfo&quot;:
{&quot;displayFieldSetName&quot;:&quot;ACLS_Address_Information&quot;,
&quot;fieldSetNames&quot;:[&quot;ACLS_Address_Information_PopUp&quot;]}
}</value>
    </values>
    <values>
        <field>PC_Config__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_EnrollmentWizardPageLabel__c</field>
        <value xsi:type="xsd:string">Patient Information</value>
    </values>
    <values>
        <field>PC_Ordinal__c</field>
        <value xsi:type="xsd:double">1.0</value>
    </values>
    <values>
        <field>PC_Processor__c</field>
        <value xsi:type="xsd:string">PC_PatientInfo2WithAddressEWPProcessor</value>
    </values>
    <values>
        <field>PC_ProgramCode__c</field>
        <value xsi:type="xsd:string">ASHF</value>
    </values>
</CustomMetadata>
