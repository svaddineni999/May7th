/**
 * Created by ronbansal on 1/07/2023.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        component.set("v.namespace", ns);
    },
    callNewBIBVComponent : function(component, event, helper){
        var params = {
            "entityApiName": "Case",
            "recordTypeId" : component.get('v.logACaseBIBVRecordTypeId'),
            "defaultFieldValues" : {
          	}            
        }
        var parentId = "ParentId";
        var pgmId    = "PC_Program__c";
        params["defaultFieldValues"][parentId] = component.get("v.recordId");
        params["defaultFieldValues"][pgmId]    = component.get("v.recordId");
        //All other attributes will be get autopopulated as part of US-327
        
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams(params);
        createRecordEvent.fire();
    },
    showNewBIBVComponent : function(component, event, helper){
        var action= component.get("c.getMapOfRecordtype");
        action.setParams({ objectAPIName : "Case" });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.logACaseBIBVRecordTypeId",returnValue['PC_Benefits_Investigation_Benefits_Verification']);
                this.callNewBIBVComponent(component, event, helper);
            } else {
                var errors = response.getError();
                if(!$A.util.isEmpty(errors) && errors.length > 0) {
                    var message = errors[0].message;
                    component.set("v.logACaseErrors", message);
                }
            }
        });
        $A.enqueueAction(action);
    },
    clearErrors : function(component) {
        component.set("v.logACaseErrors", []);
    },
})