<aura:application extends="force:slds" implements="force:appHostable">
    <aura:attribute name="Id" type="String" />
    <aura:attribute name="isAppWindow" type="Boolean" />
    <!--<aura:handler name="init" value="{!this}" action="{!c.getParameters}"/>-->
	<c:PC_Document_Management >
        <aura:set attribute="recordId" value="{!v.Id}" />
        <aura:set attribute="isAppWindow" value="{!v.isAppWindow}"/>
    </c:PC_Document_Management>
</aura:application>