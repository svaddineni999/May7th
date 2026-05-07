<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Appointment Reminder via Email</label>
    <protected>false</protected>
    <values>
        <field>PC_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_AssignNotificationFieldName__c</field>
        <value xsi:type="xsd:string">PC_Patient_Program__r.PC_Care_Coordinator__c</value>
    </values>
    <values>
        <field>PC_CreateTasksOnFailure__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_Description__c</field>
        <value xsi:type="xsd:string">This Setting defines the criteria on which reminder will be sent through emails for any upcoming appointments of the patients</value>
    </values>
    <values>
        <field>PC_DueDate_FieldName__c</field>
        <value xsi:type="xsd:string">PC_Start__c</value>
    </values>
    <values>
        <field>PC_EndDateOffsetReference__c</field>
        <value xsi:type="xsd:string">Days</value>
    </values>
    <values>
        <field>PC_EndDateOffsetType__c</field>
        <value xsi:type="xsd:string">Before</value>
    </values>
    <values>
        <field>PC_EndDateOffset__c</field>
        <value xsi:type="xsd:double">0.0</value>
    </values>
    <values>
        <field>PC_MaximumRemindersToBeSent__c</field>
        <value xsi:type="xsd:double">0.0</value>
    </values>
    <values>
        <field>PC_MinimumIntervalReminders__c</field>
        <value xsi:type="xsd:double">24.0</value>
    </values>
    <values>
        <field>PC_ObjectNamespace__c</field>
        <value xsi:type="xsd:string">PatientConnect</value>
    </values>
    <values>
        <field>PC_Object_ReminderService__c</field>
        <value xsi:type="xsd:string">PC_Interaction__c</value>
    </values>
    <values>
        <field>PC_OtherChannelName__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_OtherTemplateType__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_ParentFieldName__c</field>
        <value xsi:type="xsd:string">ID</value>
    </values>
    <values>
        <field>PC_RecipientFieldName__c</field>
        <value xsi:type="xsd:string">PC_Patient_Program__r.PC_Email__c</value>
    </values>
    <values>
        <field>PC_RecipientSourceClass__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_RecipientSource__c</field>
        <value xsi:type="xsd:string">Recipient Field API Name</value>
    </values>
    <values>
        <field>PC_ReminderChannel__c</field>
        <value xsi:type="xsd:string">Email</value>
    </values>
    <values>
        <field>PC_ShowSuccessfulRemindersNotifications__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>PC_StartDateOffsetReference__c</field>
        <value xsi:type="xsd:string">Days</value>
    </values>
    <values>
        <field>PC_StartDateOffsetType__c</field>
        <value xsi:type="xsd:string">Before</value>
    </values>
    <values>
        <field>PC_StartDateOffset__c</field>
        <value xsi:type="xsd:double">3.0</value>
    </values>
    <values>
        <field>PC_TemplateName__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>PC_TemplateType__c</field>
        <value xsi:type="xsd:string">Salesforce Templates</value>
    </values>
</CustomMetadata>
