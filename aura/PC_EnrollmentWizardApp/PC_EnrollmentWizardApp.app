<!--
Lightning App        : PC_EnrollmentWizardApp
Description          : Displays Enrollment wizard pages that are configured
Modification Log:
Haritha Reddy        15-Sep-2020    [PC-6790] Added a new attribute isCustomApp to help determine from where enrollment wizard is launched
-->
<aura:application access="global" extends="force:slds" implements="force:appHostable">
    <aura:attribute name="Id" type="String"/>
    <c:PC_EnrollmentWizard >
         <aura:set attribute="enrollmentCaseId" value="{!v.Id}" />
        <aura:set attribute="isCustomApp" value="true" />
    </c:PC_EnrollmentWizard>
</aura:application>