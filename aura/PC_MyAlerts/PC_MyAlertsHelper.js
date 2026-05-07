/**
         * Created by sahgarg on 3/15/2018.
         */
({
    showAllRecords : function(component) {
        var retValue = false;
        // try catch has been put because the component.find("showAllTasksToggle") may throw exception when hidden on the screen
        try {
            retValue = component.find("showAllAlertsToggle").get("v.checked");
        }
        catch(err) {
            var defaultView = component.get("v.defaultView");
            if(defaultView == 'MY RECORDS') {
                retValue = false;
            }
            else {
                retValue = true;
            }
        }
        return retValue;
    },

    getAllAlertsPagination: function(component,helper,currentPagenumber, recordToDisply ) {
        debugger;
        //entering alerts
        var action = component.get("c.getAllAlertsPagination");
        action.setParams({
            "pageNumber": currentPagenumber,
            "recordToDisply": recordToDisply,
            "showAllAlerts": helper.showAllRecords(component)
            // "fromDate":null,
            //   "toDate":null
        });
        component.set("v.showSpinner", true);
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                var result = a.getReturnValue();
                component.set("v.lstActivity", result.activityWrapper);
                component.set("v.currentPagenumber", result.page);
                component.set("v.totalRecords", result.total);
                component.set("v.totalNumberOfPages", Math.ceil(result.total / recordToDisply));
                
                console.log("v.lstActivity");
                console.log(component.get("v.lstActivity"));
            } else {
                var errors = a.getError();
                errors.unshift(component.get("v.errorText"));
                console.log(JSON.stringify(errors));
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    
    
    setSelectedMenuItem : function(selectedNode) {
        debugger;
        $(".filterOptions li").removeClass("selected");
        selectedNode.parentElement.classList.add("selected");
    },
    
    markDismissActivity : function (component) {
        
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
                var mainDiv = component.find('main-div');
                $A.util.addClass(mainDiv, 'transition-hide');
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
            } else {
                var errors = a.getError();
                errors.unshift(component.get("v.errorText"));
                console.log(JSON.stringify(errors));
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
            }
            
        });
        $A.enqueueAction(action);
    }
    
    
    
    
    
    
})