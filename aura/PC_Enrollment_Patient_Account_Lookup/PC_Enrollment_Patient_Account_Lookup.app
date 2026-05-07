<!--
Lightning App        : PC_Enrollment_Patient_Account_Lookup
Description          : Displays Pre Enrollment page
Modification Log:
Haritha Reddy        11-Nov-2020    [PC-6795] Added a new attribute isCustomApp to help determine from where enrollment wizard is launched
-->
<aura:application access="global" extends="force:slds" implements="force:appHostable">
    <aura:attribute name="Id" type="String"/>
    <!--PC_Launch_PreEnrollment-->
    <c:PC_Enrollment_Patient_Lookup docId="{!v.Id}" isCustomApp="true"/>
</aura:application>