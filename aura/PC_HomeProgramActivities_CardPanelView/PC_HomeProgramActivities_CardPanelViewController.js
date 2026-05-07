/**
 * Created by vkashikar on 9/11/2017.
 */
({
    doInit : function(component, event, helper) {
        console.log('===============test=======');
        helper.getThisWeekDueActivities(component,helper);
        //helper.getFormContent(component, candidatePatientId);
    },

    handleTaskUpdated : function(component, event, helper) {
        console.log("task Event occured");
        helper.getThisWeekDueActivities(component,helper);
        //helper.getStarredActivities(component);
        //helper.getOverDueActivities(component);
        //helper.getTodayDueActivities(component);
        //helper.getTomorrowDueActivities(component);
    },

   handleMoreOption: function(component, event, helper) {
       var mainDiv = component.find('main-div');
       $A.util.addClass(mainDiv, 'slds-is-open');
     },

     handleMoreOptionLeave: function(component, event, helper) {
       component.set("v.dropdownOver",false);
       var mainDiv = component.find('main-div');
       $A.util.removeClass(mainDiv, 'slds-is-open');
     },

     handleMoreOptionEnter: function(component, event, helper) {
       component.set("v.dropdownOver",true);
     },

     handleMoreOptionOut: function(component, event, helper) {
       window.setTimeout(
         $A.getCallback(function() {
           if (component.isValid()) {
             //if dropdown over, user has hovered over the dropdown, so don't close.
             if (component.get("v.dropdownOver")) {
               return;
             }
             var mainDiv = component.find('main-div');
             $A.util.removeClass(mainDiv, 'slds-is-open');
           }
         }), 200
       );
     },

     showDueDateList: function(component, event, helper){
          console.log('==========Show Due Date List');
          console.log("field = " + component.get("{!v.lstThisWeekActivity}"));
          //helper.sortByDueDate(component);
           helper.sortByDueDate(component, helper);
            // Check Sorting Results
            /*
                for (var key in getItems) {
                var item = getItems[key];
                 console.log('=====11111===='+item.priority);
                for (var key2 in item) {
                    console.log('=====key2===='+key2);
                    console.log('==========value2======='+item[key2]);
                }
              }
            */
         component.set("v.dropdownOver",false);
         var mainDiv = component.find('main-div');
         $A.util.removeClass(mainDiv, 'slds-is-open');
     },

     showHighPriority :function(component, event, helper){
        console.log('==========Show High Priority List');
        console.log("field = " + component.get("{!v.lstThisWeekActivity}"));
                  var getItems = component.get("{!v.lstThisWeekActivity}");
                    /*
        			for (var e1 in getItems) {
                        console.log('===DueDates old==='+getItems[e1].priority);
                    }
        			*/
        			sortResults('index_priorityPlusDueDate', true);
                     function sortResults(prop, asc) {
                        var sortedItems = getItems.sort(function(a, b) {
                            if(a[prop] < b[prop]) return -1;
                            if(a[prop] > b[prop]) return 1;
                             return 0;
                        });
                        getItems = sortedItems;
                    }

                component.set("v.lstThisWeekActivity", getItems);

                // Check Sorting Results
        		/*
                    for (var key in getItems) {
                    var item = getItems[key];
                     console.log('=====11111===='+item.priority);
                    for (var key2 in item) {
                        console.log('=====key2===='+key2);
                        console.log('==========value2======='+item[key2]);
                    }
                  }
        		*/

                 component.set("v.dropdownOver",false);
                 var mainDiv = component.find('main-div');
                 $A.util.removeClass(mainDiv, 'slds-is-open');
     },
     sort : function(component, event, helper) {
         debugger;
         var sortType = event.currentTarget.getAttribute("data-sortType");
         helper.setSelectedMenuItem(event.currentTarget);
         var items;
         if(sortType == 'filterTodaysItems') {
             items = component.get("v.lstTodayDueActivity");
             items = helper.sortResults(items, 'index_priorityPlusDueDate', true); //make sense to show high priority items
         }
         else if(sortType == 'filterTomorrowItems') {
             items = component.get("v.lstTomorrowDueActivity");
             items = helper.sortResults(items, 'index_priorityPlusDueDate', true);
         }
         else if(sortType == 'filterOverdueItems') {
             items = component.get("v.lstOverDueActivity");
             items = helper.sortResults(items, 'index_dueDatePlusPriority', true);
         }
         else if(sortType == 'soryByPriority') {
             items = component.get("v.lstThisWeekActivity");
             items = helper.sortResults(items, 'index_priorityPlusDueDate', true);
         }
         else if(sortType == 'soryByDueDate') {
             items = component.get("v.lstThisWeekActivity");
             items = helper.sortResults(items, 'index_dueDatePlusPriority', true);
         }
         else if(sortType == 'filterAlerts') {
            items = component.get("v.lstAlerts");
            items = helper.sortResults(items, 'index_dueDatePlusPriority', true);
         }
         else if(sortType == 'filterTasks') {
            items = component.get("v.lstTasks");
            items = helper.sortResults(items, 'index_dueDatePlusPriority', true);
         }
         else {
             var toastEvent=$A.get("e.force:showToast");
                toastEvent.setParams({
                    "title":    'Warning',
                    "message":  'Something went wrong, Please contact System Administrator',
                    "type":     'warning'
                    });
                toastEvent.fire();
         }
         component.set("v.lstActivity", items);
         component.set("v.dropdownOver",false);
         var mainDiv = component.find('main-div');
         $A.util.removeClass(mainDiv, 'slds-is-open');
     }

})