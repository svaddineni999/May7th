/**
 * Created by peharitha on 7/4/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    getDocumentDetails : function(component) {
        var action = component.get("c.getDocumentDetails");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var returnValue = a.getReturnValue();
                    component.set("v.siteBaseUrl",returnValue.siteBaseUrl);
                    component.set("v.documentDetails", returnValue);
                    component.set("v.hidePopout",returnValue.isCommunity);
                }
            }else if (state ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.ErrorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                console.log("getDocumentDetails: Failed with state: " + state);
            }
      });
      $A.enqueueAction(action);
    },
})