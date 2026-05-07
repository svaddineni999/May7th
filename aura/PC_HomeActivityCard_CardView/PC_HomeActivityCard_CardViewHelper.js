/**
 * Created by vkashikar on 9/11/2017.
 */
({
    markCompleteActivity : function (component, helper) {
        var objTask  = component.get("v.objTask");
        var action = component.get("c.closeTask");
        action.setParams({
            "taskID" : objTask.taskID
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                //component.set("v.objTask", a.getReturnValue());
                var mainDiv = component.find('main-div-element');
                $A.util.addClass(mainDiv, 'slds-transition-hide');
                
                //console.log(objTask);
                //Fire update event
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
                helper.showSuccessMessage(component, component.get("v.objTask").taskID, component.get("v.objTask").subject);
            } else {
                var errors = a.getError();
                errors.unshift(component.get("v.errorText"));
                console.log(JSON.stringify(errors));
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
            }
            
        });
        $A.enqueueAction(action);
    },
    markHighPriorityActivity : function (component, helper) {
        var objTask  = component.get("v.objTask");
        var action = component.get("c.updatePriority");
        action.setParams({
            "taskID" : objTask.taskID
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                var ret = a.getReturnValue();
                if(ret.svgIconName == 'fax') {
                    ret.svgIconName = 'task';
                }
                component.set("v.objTask", ret);
                //var mainDiv = component.find('main-div');
                //$A.util.addClass(mainDiv, 'transition-hide');
                //console.log(objTask);
                //Fire update event
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
                    helper.showSuccessMessage(component, component.get("v.objTask").taskID, component.get("v.objTask").subject);

            } else {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                errors.unshift(component.get("v.errorText"));
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
            }
            
        });
        $A.enqueueAction(action);
    },
    markDismissActivity : function (component, helper) {
        
        debugger;
        var objTask  = component.get("v.objTask");
        console.log('===>>>>>>OBJTASK>>>>>>>>>>===='+objTask);
        console.log('=====TaskId====='+objTask.taskID);
        
        var action = component.get("c.overrideAlert");
        action.setParams({
            "objAlertId" : objTask.taskID
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                debugger;
                var mainDiv = component.find('main-div');
                $A.util.addClass(mainDiv, 'transition-hide');
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
                if(!$A.util.isUndefinedOrNull(component.get("v.objTask").subject)){
                   helper.showSuccessMessage(component, component.get("v.objTask").taskID, component.get("v.objTask").subject);
                } else{
                   helper.showSuccessMessage(component, component.get("v.objTask").taskID, component.get("v.objTask").alertName);
                }
            } else {
                var errors = a.getError();
                errors.unshift(component.get("v.errorText"));
                console.log(JSON.stringify(errors));
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
            }
            
        });
        $A.enqueueAction(action);
    },
     showSuccessMessage : function(component, recordId, recordLabel) {
         var toastEvent = $A.get("e.force:showToast");
         toastEvent.setParams({
             "title": component.get("v.toastSuccessTitle"),
             "message": component.get("v.successMessage"),
             "type" : 'success',
             "mode" : "dismissible",
             "messageTemplate": component.get("v.successMessage"),
             "messageTemplateData": [{
                 url: '/'+ recordId,
                 label: recordLabel
             }]
         });
         toastEvent.fire();
     }
})