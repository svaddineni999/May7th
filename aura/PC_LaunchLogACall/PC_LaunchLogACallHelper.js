/**
 * Created by tusarora on 7/22/2020.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        component.set("v.namespace", ns);
    },
    getLogACallRecordTypeInfo : function(component, event, helper){
        var action= component.get("c.getLogACallRecordTypeInfo");
        action.setCallback(this, function(response) {
            console.log('response.getState()::::'+response.getState());
            if (response.getState() == "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.logACallRecordTypeId",returnValue);
            } else {
                console.log("Failed with state: " + state);
                var errors = response.getError();
                if(!$A.util.isEmpty(errors) && errors.length > 0) {
                    var message = errors[0].message;
                    component.set("v.logACallErrors", message);
                }
            }
        });
        $A.enqueueAction(action);
    },
    callLogACallComponent : function(component, event, helper){
        var today = new Date().toISOString();
        var params = {
            "entityApiName": "Task",
            "recordTypeId" : component.get('v.logACallRecordTypeId'),
            "defaultFieldValues" : {
                                    'Subject' : 'Call',
                                    'Type': 'Call',
                                    'Status': 'Completed',
                                    'ActivityDate': today
                                    //Need to get local date/time and set due date to today
            }
        }

        var prgId = "WhatId"; //component.get("v.namespacePrefix") + "PC_Program__c" ;
        params["defaultFieldValues"][prgId] = component.get("v.relatedToId");
        var channel = component.get("v.namespace") + "__" + "PC_Channel__c";
        params["defaultFieldValues"][channel] = 'Call';
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams(params);
        createRecordEvent.fire();
    },
    clearErrors : function(component) {
        component.set("v.logACallErrors", []);
    },
})