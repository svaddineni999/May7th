/**
                 * Created by sahgarg on 3/15/2018.
                 */
({
    showAllRecords : function(component) {
        var retValue = false;
        // try catch has been put because the component.find("showAllTasksToggle") may throw exception when hidden on the screen
        try {
            retValue = component.find("showAllTasksToggle").get("v.checked");
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
    getAllTasksPagination: function(component, event, helper, currentPagenumber, recordToDisply ) {
        debugger;
        var action = component.get("c.getAllTasksPagination");
        //var showAllRecords = component.get("v.showAllRecords");
        //var defaultView = component.get("v.defaultView");
        action.setParams({
            "pageNumber": currentPagenumber,
            "recordToDisply": recordToDisply,
            "fromDate":null,
            "toDate":null,
            "showAllTasks": helper.showAllRecords(component)
        });


        component.set("v.showSpinner", true);
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                var result = a.getReturnValue();
                
                component.set("v.currentPagenumber", result.page);
                component.set("v.totalRecords", result.total);
                component.set("v.totalNumberOfPages", Math.ceil(result.total / recordToDisply));
                
                var sortedList = this.sortResults(result.activityWrapper, 'index_dueDatePlusPriority', true);
                component.set("v.lstActivity",sortedList);
                
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
    
    getHighPriorityTasksPagination: function(component, event, helper, currentPagenumber, recordToDisply ) {
        var groupByOptionSelected = component.get("v.groupByParam");
        if($A.util.isEmpty(component.get("v.groupByParam")) || groupByOptionSelected === 'None'){
            var action = component.get("c.getHighPriorityTasksPagination");
            action.setParams({
                "pageNumber": currentPagenumber,
                "recordToDisply": recordToDisply,
                "fromDate":null,
                "toDate":null,
                "showAllTasks": helper.showAllRecords(component)
            });

            component.set("v.showSpinner", true);
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS"){
                    var result = a.getReturnValue();

                    component.set("v.currentPagenumber", result.page);
                    component.set("v.totalRecords", result.total);


                    var sortedList = this.sortResults(result.activityWrapper, 'index_dueDatePlusPriority', true);
                    component.set("v.lstActivity",sortedList);
                     var pages =Math.ceil(result.total / recordToDisply);
                                     if(component.get("v.lstActivity").length!=0){
                                                        component.set("v.totalNumberOfPages", pages);
                                                   }
                                                   else{
                                                       component.set("v.totalNumberOfPages", pages+1);
                                                   }
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
        }else{
            this.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 7);
        }
    },
    
    markCompleteActivity : function (component) {
        var objTask  = component.get("v.objTask");
        var action = component.get("c.closeTask");
        action.setParams({
            "taskID" : objTask.taskID
        });
        component.set("v.showSpinner", true);
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                
                var mainDiv = component.find('main-div-element');
                $A.util.addClass(mainDiv, 'slds-transition-hide');
                
                
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
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
    
    markHighPriorityActivity : function (component) {
        var objTask  = component.get("v.objTask");
        var action = component.get("c.updatePriority");
        action.setParams({
            "taskID" : objTask.taskID
        });
        component.set("v.showSpinner", true);
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                var ret = a.getReturnValue();
                if(ret.svgIconName == 'fax') {
                    ret.svgIconName = 'task';
                }
                component.set("v.objTask", ret);
                
                //Fire update event
                var taskUpdatedEvent = component.getEvent("taskUpdated");
                taskUpdatedEvent.fire();
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
    
    
    getOverDueActivities: function(component, event, helper, currentPagenumber, recordToDisply ) {
        var groupByOptionSelected = component.get("v.groupByParam");
        if($A.util.isEmpty(component.get("v.groupByParam")) || groupByOptionSelected === 'None'){
            var action = component.get("c.getOverDueActivities");
            action.setParams({

                "pageNumber": currentPagenumber,
                "recordToDisply": recordToDisply,
                "fromDate":null,
                "toDate":null,
                "showAllTasks": helper.showAllRecords(component)
            });
            component.set("v.showSpinner", true);
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {

                    var result = a.getReturnValue();

                    component.set("v.currentPagenumber", result.page);
                    component.set("v.totalRecords", result.total);


                    component.set("v.lstActivity",this.sortResults(result.activityWrapper, 'index_dueDatePlusPriority', true));
                     var pages =Math.ceil(result.total / recordToDisply);
                                     if(component.get("v.lstActivity").length!=0){
                                                        component.set("v.totalNumberOfPages", pages);
                                                   }
                                                   else{
                                                       component.set("v.totalNumberOfPages", pages+1);
                                                   }

                } else {
                    var errors = a.getError();
                    errors.unshift(component.get("v.errorText"));
                    console.log(JSON.stringify(errors));
                    CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(action);
        }else{
            this.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 1);
        }
    },
    getTodayDueActivities: function(component, event, helper, currentPagenumber, recordToDisply) {
        var groupByOptionSelected = component.get("v.groupByParam");
        if($A.util.isEmpty(component.get("v.groupByParam")) || groupByOptionSelected === 'None'){
            var action = component.get("c.getActivitiesDueToday");
            action.setParams({
                "pageNumber": currentPagenumber,
                "recordToDisply": recordToDisply,
                "fromDate":null,
                "toDate":null,
                "showAllTasks": helper.showAllRecords(component)
            });
            component.set("v.showSpinner", true);
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS"){

                    var result = a.getReturnValue();
                    var pages =Math.ceil(result.total / recordToDisply);

                    component.set("v.currentPagenumber", result.page);
                    component.set("v.totalRecords", result.total);

                    component.set("v.lstActivity",this.sortResults(result.activityWrapper, 'index_dueDatePlusPriority', true));
                    if(component.get("v.lstActivity").length!=0){
                         component.set("v.totalNumberOfPages", pages);
                    }
                    else{
                        component.set("v.totalNumberOfPages", pages+1);
                    }

                } else {
                    var errors = a.getError();
                    errors.unshift(component.get("v.errorText"));
                    console.log(JSON.stringify(errors));
                    CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(action);
        }else{
            this.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 3);
            }
    },
    getTomorrowDueActivities: function(component, event, helper, currentPagenumber, recordToDisply) {
        var groupByOptionSelected = component.get("v.groupByParam");
        if($A.util.isEmpty(component.get("v.groupByParam")) || groupByOptionSelected === 'None'){
            var action = component.get("c.getActivitiesDueTomorrow");
            action.setParams({
                "pageNumber": currentPagenumber,
                "recordToDisply": recordToDisply,
                "fromDate":null,
                "toDate":null,
                "showAllTasks": helper.showAllRecords(component)
            });
            component.set("v.showSpinner", true);
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {

                    var result = a.getReturnValue();
                    component.set("v.lstActivity",this.sortResults(result.activityWrapper, 'index_dueDatePlusPriority', true));
                    component.set("v.currentPagenumber", result.page);
                    component.set("v.totalRecords", result.total);
                     var pages =Math.ceil(result.total / recordToDisply);
                     if(component.get("v.lstActivity").length!=0){
                                        component.set("v.totalNumberOfPages", pages);
                                   }
                                   else{
                                       component.set("v.totalNumberOfPages", pages+1);
                                   }
                } else {
                    var errors = a.getError();
                    errors.unshift(component.get("v.errorText"));
                    console.log(JSON.stringify(errors));
                    CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),errors);
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(action);
        }else{
            this.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 4);
        }
    },
    
    sortResults: function (getItems, prop, asc) {
        var sortedItems = getItems.sort(function(a, b) {
            console.log(a + ' , ' + b);
            if(a[prop] < b[prop]) return -1;
            if(a[prop] > b[prop]) return 1;
            return 0;
        });
        return sortedItems;
    },
    
    setSelectedMenuItem : function(selectedNode) {
        
        $(".filterOptions li").removeClass("selected");
        selectedNode.parentElement.classList.add("selected");
    },
    getAllGroupedByTasks: function(component, event, helper, currentPage, recordToDisplay,  filterByIndex) {
        debugger;
        var action = component.get("c.getAllGroupedByTasks");
        action.setParams({
            "groupByParameter": component.get("v.groupByParam"),
            "pageNumber": currentPage,
            "recordToDisplay": recordToDisplay,
            "filterByIndex": filterByIndex,
            "showAllTasks": helper.showAllRecords(component)
        });
        component.set("v.showSpinner", true);
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                var result = a.getReturnValue();

                component.set("v.currentPagenumber", result.page);
                component.set("v.totalRecords", result.total);
                component.set("v.totalNumberOfPages", Math.ceil(result.total / recordToDisplay));
                component.set("v.groupByNone", false);
                var sortedList = this.sortGroupByResults(component, event, helper, result.activityMapWrapper, 'index_dueDatePlusPriority', true);
                component.set("v.mapActivities",sortedList);
                var activities = [];
				var fetchedActivities = result.activityMapWrapper;
                var nameMap = result.namesAndIds;
                var namesList = [];
                for(var k in nameMap){
                    namesList.push({value:nameMap[k], key:k});
                }
                component.set("v.mapNames",namesList);
                for(var key in fetchedActivities){
                    var name = nameMap[key];
                    activities.push({value:fetchedActivities[key], key:key, keyLabel:name, count:fetchedActivities[key].length});
                }

                component.set("v.groupedActivitiesList",activities);
                console.log("v.mapActivities");
                console.log(component.get("v.mapActivities"));
                console.log(JSON.stringify(component.get("v.mapActivities")));
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
    sortGroupByResults: function (component, event, helper, getItems, prop, asc) {
        var taskOwners = [];
        for (var key in getItems) {
            taskOwners.push(key);
        getItems[key] = getItems[key].sort(function(a, b) {
            console.log(a + ' , ' + b);
            if(a[prop] < b[prop]) return -1;
            if(a[prop] > b[prop]) return 1;
            return 0;
        });
        }
        component.set("v.groupedActivitiesList",taskOwners);
        return getItems;
    },
     updateFilterBySelection : function (component, event, helper){
		var action = component.get("c.getFilterByValues");
        var filterBy = component.find("filterBy");

         var opts=[];
         action.setCallback(this, function(a) {
             var response=a.getReturnValue();
             if (response != undefined) {
                 for(var key in response){
                     opts.push({class: "optionClass", label: response[key], value:key});
                 }
             }
             filterBy.set("v.options", opts);

         });
         $A.enqueueAction(action);

    }
})