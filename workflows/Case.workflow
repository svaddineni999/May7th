<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ChangePriorityToHigh</fullName>
        <field>Priority</field>
        <literalValue>High</literalValue>
        <name>Changes the case priority to high.</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>PC_UpdateSubject</fullName>
        <field>Subject</field>
        <formula>null</formula>
        <name>PC_UpdateSubject</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>PC_UpdateCaseSubject</fullName>
        <actions>
            <name>PC_UpdateSubject</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Patient Connect- This workflow rule is to update the subject on case</description>
        <formula>false</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
