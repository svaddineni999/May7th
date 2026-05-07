/**
 * Created by vkashikar on 5/20/2021.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setMode : function(component, event, helper) {
        debugger;
        var url = window.location.href;
        //"https://coredev-dev-ed.lightning.force.com/flexipageEditor/surface.app?appLayout=lg&formfactorName=DESKTOP&aura.mode=PROD"

        // SF loads the edit components in the URI flexipageEditor/surface.app. We will use this to determine,
        // if we are in edit mode or not.
        if(!$A.util.isEmpty(url) && url.indexOf('/flexipageEditor/surface.app') > 0) {
            component.set("v.isEditMode", true);
        }
    },
    navigateToRecord : function (component, event, helper) {
        var workspaceAPI = component.find("workspaceAPI");
        var recordId = component.get("v.selectedRecordId");
        CH_PC_Util.openRecordInNewTab(workspaceAPI, recordId);
    }
})