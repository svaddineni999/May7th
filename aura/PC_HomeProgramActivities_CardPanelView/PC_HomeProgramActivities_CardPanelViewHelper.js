/**
 * Created by vkashikar on 9/11/2017.
 */
({

	getThisWeekDueActivities: function(component,helper) {
            var action = component.get("c.getThisWeekActivities");
            action.setParams({
                "fromDate":null,
                "toDate":null
            });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS"){
                    component.set("v.lstActivity", a.getReturnValue());
                    helper.sortByDueDate(component, helper);
                    helper.setActivities(component, helper);
                    console.log("v.lstActivity");
                    console.log(component.get("v.lstActivity"));
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.errorText");
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errText);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        },
	getStarredActivities: function(component) {
        var action = component.get("c.getStarredActivities");
        action.setParams({
            "fromDate":null,
            "toDate":null
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                component.set("v.lstStarredActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    getOverDueActivities: function(component) {
        var action = component.get("c.getOverDueActivities");
        action.setParams({
            "fromDate":null,
            "toDate":null
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.lstOverDueActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    getTodayDueActivities: function(component) {
        var action = component.get("c.getActivitiesDueToday");
        action.setParams({
            "fromDate":null,
            "toDate":null
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                component.set("v.lstTodayDueActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    getTomorrowDueActivities: function(component) {
        var action = component.get("c.getActivitiesDueTomorrow");
        action.setParams({
            "fromDate":null,
            "toDate":null
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.lstTomorrowDueActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.errorText");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log(errText);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    sortByDueDate: function(component, helper){
          var getItems = component.get("v.lstActivity");
          console.log("Sorting 1...")
          console.log(JSON.stringify(getItems));

          var getItems_sorted = helper.sortResults(getItems, 'index_dueDatePlusPriority', true);
           component.set("v.lstThisWeekActivity", getItems_sorted);
           console.log(JSON.stringify(getItems_sorted));
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
    setActivities: function (component, helper) {
        debugger;
        var allActivities = component.get("v.lstActivity");
        var todaysActivities = [];
        var tomorrowActivities = [];
        var overDueActivities = [];
        var thisWeekActivities = [];
        var allAlerts = [];
        var allTasks = [];
        for(var i =0; i<allActivities.length ; i++) {
            if(allActivities[i].isDueToday) {
                todaysActivities.push(allActivities[i]);
            }
            else if(allActivities[i].isDueTomorrow) {
                tomorrowActivities.push(allActivities[i]);
            }
            else if(allActivities[i].isOverdue) {
                overDueActivities.push(allActivities[i]);
            }

            if(allActivities[i].isAlert) {
                allAlerts.push(allActivities[i]);
            }
            else {
                allTasks.push(allActivities[i]);
            }
            thisWeekActivities.push(allActivities[i]);
        }
        component.set("v.lstTodayDueActivity", todaysActivities);
        component.set("v.lstTomorrowDueActivity", tomorrowActivities);
        component.set("v.lstOverDueActivity", overDueActivities);
        component.set("v.lstThisWeekActivity", thisWeekActivities);
        component.set("v.lstAlerts", allAlerts);
        component.set("v.lstTasks", allTasks);

    },
    setSelectedMenuItem : function(selectedNode) {
        debugger;
        $(".filterOptions li").removeClass("selected");
        selectedNode.parentElement.classList.add("selected");
    }
})