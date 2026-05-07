/**
 * Created by havalakki on 10/18/2019.
 */
({

    initializeAttributes : function(component, event, helper) {
        var action = component.get("c.getOrgNamespace");
        action.setCallback(this,function(response) {
            var state=response.getState();
            if(state=='SUCCESS'){
                var returnValue=response.getReturnValue();
                component.set('v.orgNamespace', returnValue);
                helper.setProperties(component);
            }else{
                console.log("SearchActionGoToRecord: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    setProperties : function(component) {
       var orgNamespace = component.get("v.orgNamespace");
       var buttonLabel = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.goToRecordButtonLabel"));
       var buttonName;
       if(buttonLabel.startsWith("$Label.")){
           buttonName = $A.getReference(buttonLabel);
       }else{
           buttonName = buttonLabel;
       }
       component.set("v.goToRecordButtonName", buttonName);
    },

    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    }
})