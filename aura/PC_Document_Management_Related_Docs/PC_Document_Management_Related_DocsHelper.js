/**
 * Created by havalakki on 3/1/2018.
 */
({
    showHideSection : function(component,event,secId) {
    	  var acc = component.find(secId);
            	for(var cmp in acc) {
            	$A.util.toggleClass(acc[cmp], 'slds-show');
            	$A.util.toggleClass(acc[cmp], 'slds-hide');
           }
    	},

     //init method
    getInit : function(component, event, helper) {
        //get page count for parent document
        helper.parentDocumentCount(component, event, helper);
        var ParentID = component.get("v.recordId");
        var isRelatedComp = component.get("v.isRelatedComponent");
        var action = component.get("c.getChildDocs");
        action.setParams({
            "ParentID": ParentID,
             isRelatedComponent: isRelatedComp
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                var childDocInfo=JSON.parse(a.getReturnValue());
                var splitDocList=childDocInfo.childDocumentWrapperList;
                //component.set("v.noSplitDocs",a.getReturnValue());
                component.set("v.noSplitDocs",splitDocList);
                component.set("v.isResubmit", true);
                for(var i=0; i < splitDocList.length; i++ ) {
                    if(!(splitDocList[i].DocumentStatus === 'Awaiting Attachment')) {
                        component.set("v.isResubmit", false);
                        break;
                    }
                }
                if(splitDocList.length < 1) {
                    component.set("v.isSplitbuttonActive", false);
                }
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
    },

    parentDocumentCount : function(component, event, helper) {
        var ParentID = component.get("v.recordId");
        var action = component.get("c.getParentDocumentCount");
        action.setParams({
            "ParentID": ParentID
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.pageCount",a.getReturnValue());
            } else if (a.getState() ==="ERROR") {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
    },

    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    }

})