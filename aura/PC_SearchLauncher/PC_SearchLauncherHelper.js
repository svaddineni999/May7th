/**
 * Created by peharitha on 9/30/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    initializeAttributes : function(component, event, helper) {
        var action = component.get("c.getOrgNamespace");
        action.setCallback(this,function(response) {
            var state=response.getState();
            if(state=='SUCCESS'){
                var returnValue=response.getReturnValue();
                component.set('v.orgNamespace', returnValue);
                helper.setProperties(component, event, helper);
            }else{
                console.log("SearchLauncher: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    setProperties : function(component, event, helper) {
        var orgNamespace = component.get("v.orgNamespace");
        //Set Button Label
        var buttonName;
        var buttonLabel = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.searchLauncherButtonLabel"));
        if(buttonLabel.startsWith("$Label.")){
            buttonName = $A.getReference(buttonLabel);
        }else{
            buttonName = buttonLabel;
        }
        component.set("v.searchLauncherButtonName", buttonName);
        //Set search Page Name
        var searchPage = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.searchPageName"));
        component.set("v.searchPage", searchPage);
    },
})