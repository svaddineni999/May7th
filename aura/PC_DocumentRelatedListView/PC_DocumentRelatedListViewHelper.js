/**
 * Created by peharitha on 7/2/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setFileURL : function(component) {
        var namespace = component.get("v.namespace");
        var previewComponentName = component.get("v.previewComponentName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'fileId',namespace);
        var url = '/lightning/cmp/'+namespace+'__'+previewComponentName+'?'+qualifiedIdName+'=';
        component.set("v.fileURL",url);
    },
    showHideSection : function(component,event,secId) {
        var acc = component.find(secId);
        for(var cmp in acc) {
        $A.util.toggleClass(acc[cmp], 'slds-show');
        $A.util.toggleClass(acc[cmp], 'slds-hide');
        }
    },
    navigateToDocument : function(component,event,helper){
        var recordId = event.currentTarget.getAttribute("data-id");
        var urlEvent = $A.get("e.force:navigateToURL");
        if(component.get("v.isCommunity")){
            urlEvent.setParams({
                "url": '/pc-document'+recordId,
                "isredirect" :false
            });
        }else{
            urlEvent.setParams({
                "url": recordId,
                "isredirect" :false
            });
        }
        urlEvent.fire();
    },
    navigateToFile : function(component,event,helper){
        var fileId = event.currentTarget.getAttribute("data-id");
        var urlEvent = $A.get("e.force:navigateToURL");
        if(!component.get("v.isCommunity")){
            urlEvent.setParams({
                "url": fileId,
                "isredirect" :false
            });
        }
        urlEvent.fire();
    },
     //init method
    getInit : function(component, event, helper) {
        var ParentID = component.get("v.docId");
        var isRelatedComp = component.get("v.isRelatedComponent");
        var action = component.get("c.getChildDocs");
        action.setParams({
            "ParentID": ParentID,
             isRelatedComponent: isRelatedComp
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                var allDocsWrapper = JSON.parse(a.getReturnValue());
                var childDocWrapper = allDocsWrapper.childDocumentsList;
                component.set("v.childDocs",childDocWrapper);
                component.set("v.isCommunity",allDocsWrapper.isCommunity);
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
    },

})