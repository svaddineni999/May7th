/**
 * Created by ronbansal on 1/07/2023.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        component.set("v.namespace", ns);
    },
    callNewAppealComponent : function(component, event, helper){
        var params = {
            "entityApiName": "Case",
            "recordTypeId" : component.get('v.logACaseAppealRecordTypeId'),
            "defaultFieldValues" : {
          	}            
        }
        var parentId = "ParentId";
        params["defaultFieldValues"][parentId] = component.get("v.recordId");
        //All other attributes will be get autopopulated as part of US-327
        
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams(params);
        createRecordEvent.fire();
    },
    showNewAppealComponent : function(component, event, helper){
        var action= component.get("c.getMapOfRecordtype");
        action.setParams({ objectAPIName : "Case" });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.logACaseAppealRecordTypeId",returnValue['PC_Appeal']);
                this.callNewAppealComponent(component, event, helper);
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