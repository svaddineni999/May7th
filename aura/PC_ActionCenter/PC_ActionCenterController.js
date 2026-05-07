/**
 * Created by mapatil on 8/2/2017.
 * Modified Tejas Patel Sep 14 2017 If else conditions for Event
 * Modified Tejas Patel Sep 21 2017 If else conditions for record type for TASK
 * Modified Mayuresh Patil Oct 18 2017 Added channel to Log a Call
 */
({
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.setupActionCenter(component, event , helper);
    },

    handelActionPanel: function(component, event, helper){
        component.set("v.actionPanel", event.getParam("actionPanel"));
    },

    actionPanel : function(component, event, helper) {
        component.set("v.actionPanel",false);
        component.set("v.body", []);
    },

    callActionComponent : function (component, event,helper) {
        var actionComponentName = event.currentTarget.value;
        if(actionComponentName.length === 0){
            return;
        }
        component.set("v.actionPanel",true);
        var str = event.currentTarget.value;
        var recordTypeDevName;
        var taskRecordType = component.get("v.taskRecordTypes");
        var recordTypeId = "";
        var LHS;
        var RHS;
        if(str.includes(':')){
            LHS = str.substring(0,str.indexOf(':'));
            RHS = str.substring(str.indexOf(':')+1);
            if (LHS.toLowerCase() == 'task' || LHS.toLowerCase() == 'call'){
                actionComponentName =   LHS;
                recordTypeDevName   =   RHS;
                for (var i=0; i < taskRecordType.length ; i++){
                    if(recordTypeDevName == taskRecordType[i].DeveloperName){
                        recordTypeId = taskRecordType[i].Id
                    }
                }
            }else{
                actionComponentName =  str;
            }
        }else if (str.toLowerCase() == 'event'){
            actionComponentName =   str;
        }else{
            //Show Toast
            var title   = component.get("v.warning");
            var type    = "error";
            var message = component.get("v.warningMsg");
            helper.showToast(title, type, message);
            component.set("v.actionPanel",false);
            return;
        }
        component.set("v.actionComponentLabel",event.currentTarget.name);
        var params;
        var prgId = "WhatId";
        var createRecordEvent = $A.get("e.force:createRecord");
        if(actionComponentName == 'Event'){
            component.set("v.actionPanel",false);
            params = {
                "entityApiName": actionComponentName,
                "defaultFieldValues" : {}
            }
            params["defaultFieldValues"][prgId] = component.get("v.recordId");
            createRecordEvent.setParams(params);
            createRecordEvent.fire();
        } else if (actionComponentName == 'Task') {
            component.set("v.actionPanel",false);
            params = {
                "entityApiName": actionComponentName,
                "recordTypeId" : recordTypeId,
                "defaultFieldValues" : {}
            }
            //component.get("v.namespacePrefix") + "PC_Program__c" ;
            params["defaultFieldValues"][prgId] = component.get("v.recordId");
            createRecordEvent.setParams(params);
            createRecordEvent.fire();
        } else if (actionComponentName == 'Call'){
            component.set("v.actionPanel",false);
            var today = new Date().toISOString();
            params = {
            "entityApiName": "Task",
            "recordTypeId" : recordTypeId,
            "defaultFieldValues" : {
                'Type': 'Call',
                'Status': 'Completed',
                'ActivityDate': today
                //Need to get local date/time and set due date to today
                }
            }
            //component.get("v.namespacePrefix") + "PC_Program__c" ;
            params["defaultFieldValues"][prgId] = component.get("v.recordId");
            var channel = component.get("v.namespacePrefix") + "PC_Channel__c";
            params["defaultFieldValues"][channel] = 'Call';
            createRecordEvent.setParams(params);
            createRecordEvent.fire();
        } else {
            var componentName = actionComponentName;
            var actionComponentAttributes = event.currentTarget.getAttribute("data-componentAttributes");
            if($A.util.isEmpty(actionComponentAttributes)) {
                actionComponentAttributes = "{}";
            }
            var recordId = component.get("v.recordId");
            var patientId = component.get("v.caseDetails[0].AccountId");
            //var defaultAttributes = '{"recordId" : ' + recordId + ', "patientId": ' + patientId + '"}';
            //var defaultAttributesObj = JSON.parse(defaultAttributes);
            var defaultAttributesObj = {"recordId":"", "patientId":""};
            defaultAttributesObj['recordId'] = recordId;
            defaultAttributesObj['patientId'] = patientId;

            var actionComponentAttributesObj, allAttributesObj;
            try {
                actionComponentAttributesObj = JSON.parse(actionComponentAttributes);
                allAttributesObj = Object.assign({},defaultAttributesObj,actionComponentAttributesObj);
                var allAttibutes = JSON.stringify(allAttributesObj);
                console.log('All Attributes...');
                console.log(allAttibutes);
            } catch (err) {
                //Show Toast
                var toastTitle   = component.get('v.actionComponentAttributesError');
                var toastType    = "error";
                var toastMessage = err.name + ": " + err.message;
                helper.showToast(toastTitle, toastType, toastMessage);
                component.set("v.actionPanel",false);
                return;
            }

            $A.createComponent(
                componentName,
                allAttributesObj,
                function(newComponent) {
                    component.set("v.body", newComponent);
                }
            );
        }
    }
})