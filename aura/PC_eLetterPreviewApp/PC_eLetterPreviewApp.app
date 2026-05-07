<!--
 - Created by havalakki on 4/11/2019.
 -->

<aura:application description="PC_eLetterPreviewApp" extends="force:slds" implements="force:appHostable" access="global">
    <aura:attribute name="eLetterId" type="String"/>
    <aura:attribute name="recordId" type="String"/>
    <aura:attribute name="dynamicPreviewCmpName" type="String"/>
    <aura:attribute name="eLetterPreviewTitle" type="String"/>
    <aura:attribute name="dynamicPreviewComponent" type="Aura.Component[]"/>
    <aura:handler name="init" value="{!this}" action="{!c.doInit}" />
    <div style="padding-left:10px">
        {!v.dynamicPreviewComponent}
    </div>
</aura:application>