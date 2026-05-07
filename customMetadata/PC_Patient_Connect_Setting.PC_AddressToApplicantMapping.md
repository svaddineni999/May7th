<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Address To Applicant Mapping</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">Holds mapping of custom Address Field to Applicant Fields. For Ex - 
{
	&quot;ns__PC_Address_1__c&quot; : [&quot;ns__PC_Address_1__c&quot;,&quot;ns__PC_Address1_1__c&quot;]
}
Leave blank if no custom fields need to be mapped. Ref to implementation guide for more details.</value>
    </values>
    <values>
        <field>PC_IsOverridable__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>PC_SettingName__c</field>
        <value xsi:type="xsd:string">PC_AddressToApplicantMapping</value>
    </values>
    <values>
        <field>PC_SettingValue__c</field>
        <value xsi:type="xsd:string">{
&quot;ACLS_Zip_Code_Extension__c&quot;:[&quot;ACLS_Zip_Code_Extension__c&quot;,&quot;ACLS_Zip_Code_Extension1__c&quot;],
&quot;ACLS_Verification_Status__c&quot;:[&quot;ACLS_Verification_Status__c&quot;,&quot;ACLS_Verification_Status1__c&quot;]}</value>
    </values>
</CustomMetadata>
