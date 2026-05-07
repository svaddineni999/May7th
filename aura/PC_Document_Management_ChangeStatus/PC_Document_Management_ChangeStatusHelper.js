({
    /* Modification log:
     * Sheela Sathyanarayana    8/8/2018     [PC-3076] Changed the showToast function definition based on the values being passed, type & title was interchanged
	*/
    updateStatus : function(component, event, helper) {
       
        var action = component.get("c.updateDocumentStatus");
        action.setParams({
            docId : component.get("v.recordId"),
            status : component.find("InputSelectDynamic").get("v.value")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {                      
                    var returnValue = a.getReturnValue();
                    var newStatus = returnValue.docStatus;
                    var successMsg = component.get("v.successMsg");
                    var successDocStatus = component.get("v.successDocStatus");
                    component.set("v.oldStatus", newStatus);
                    helper.hideModal(component, event, helper);
                    helper.showToast(successDocStatus,'Success',successMsg);
                 	$A.get('e.force:refreshView').fire();
                }
            } else if (state ==="ERROR") {
                var errorMsg;
                var errors = a.getError();

                CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
            }
        });
        $A.enqueueAction(action);
      },
    
    hideModal : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        event.preventDefault();
        return false;
    },
    
    hidePopupHelper: function(component, componentId, className){ 
        var modal = component.find(componentId); 
        $A.util.addClass(modal, className+'hide'); 
        $A.util.removeClass(modal, className+'open'); 
    },
    
    showToast : function(title,type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type
        });
        toastEvent.fire();
    },
    
    setNamespace : function(component) {
        var component_to_string = component.toString();        
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);        
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    
    getPickListValues : function(component, event, helper) {
        var action = component.get("c.getRecTypeBasedPicklistValues");
        
        var opts=[];
        
        action.setParams({
           //"sobjectType" : 'PC_Document__c',
           "sobjectType" : component.get('v.namespacePrefix') + component.get("v.typeName"),
            "docId" : component.get("v.recordId"),
            //"pickListFieldAPIName" : 'PC_Document_Status__c'
            "pickListFieldAPIName" : component.get('v.namespacePrefix') + component.get("v.fieldName")
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                var returnValue = a.getReturnValue();
                var value;
                var strLabel;
                for(var i in returnValue) {
                    value = returnValue[i].strValue;
                    strLabel = returnValue[i].strLabel;
                    if($A.util.isEmpty(value)) {
                        value = 'none'; // This is not hardcoding as it is assigned to value and not name
                        opts.push({"class": "optionClass", label: returnValue[i].strLabel, value: value});
                    }else if(strLabel == component.get("v.oldStatus")){
                        opts.push({"class": "optionClass", label: returnValue[i].strLabel, value: value, selected: "true"});
                    }else{
                        opts.push({"class": "optionClass", label: returnValue[i].strLabel, value: value});
                    }
                }
                console.log(opts);
                component.find("InputSelectDynamic").set("v.options", opts);
            }
            else {
                var errors = a.getError();
                var errText = component.get("v.ErrorText");
                var errorDocStatus = component.get("v.errorDocStatus");
                                console.log(JSON.stringify(errors));
                                helper.showToast(errorDocStatus, 'Error', errText);

            }            
        });
        $A.enqueueAction(action);
    },
    
    getDocRecordTypeId : function(component, event, helper) {   
         
        var action = component.get("c.getDocRecord");        
        action.setParams({
            docId : component.get("v.recordId"),
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {	
                    var returnValue = a.getReturnValue();   
                    component.set("v.oldStatus", returnValue.document.docStatus);
                    component.set("v.recordTypeId", returnValue.document.recordTypeId);
                }
            } else {
                var errors = a.getError();
                 var errText = component.get("v.ErrorText");

                var errorDocStatus = component.get("v.errorDocStatus");
                                console.log(JSON.stringify(errors));
                                helper.showToast(errorDocStatus, 'Error', errText);
            }
        });
        $A.enqueueAction(action); 
    }
})