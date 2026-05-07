/**
     * Created by sahgarg on 3/15/2018.
     */
({
    doInit : function(component, event, helper) {
        var currentPagenumber = component.get("v.currentPagenumber");

        var recordToDisply = '30';
        helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
        
    },
    refreshView: function(component, event, helper) {
        debugger;
        var temp;
        component.set("v.lstActivity", temp);
        component.set("v.currentPagenumber", 1);
        component.set("v.groupByParam", "None");
        component.set("v.filterByParam", "soryByDueDate");
        component.find("groupBy").set("v.value", "None");
        component.find("filterBy").set("v.value", "soryByDueDate");
        component.find("groupBy").set("v.selected", "None");
        component.find("filterBy").set("v.selected", "soryByDueDate");
        component.set("v.groupByNone", "True");

        var recordToDisply = component.get("v.recordsPerPage");
        var currentPagenumber = 1;
        helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
    },
    
    handleTaskUpdated : function(component, event, helper) {
        console.log("task Event occured");
        
        var currentPagenumber = component.get("v.currentPagenumber");
        var totalNumberOfPages = component.get("v.totalNumberOfPages");
        var totalRecords = component.get("v.totalRecords");
        var sortType=component.get("v.chosenFilter");
        var recordToDisply;
        if(component.get("v.recordSize")!=null){
            recordToDisply=component.get("v.recordSize");
        }else{
            /* PC-7400: We would require attribute 'recordsPerPage' in order to display records as per the pagination value*/
            if(component.get('v.recordsPerPage')!=null && component.get('v.recordsPerPage')!=''){
                recordToDisply = component.get('v.recordsPerPage');
            }
            else{
                recordToDisply= Math.ceil(totalRecords / totalNumberOfPages)
                if(recordToDisply<=30){
                    recordToDisply=30;
                }
                else{
                    recordToDisply=60;
                }
            }
        }
        
          if(sortType == 'filterTodaysItems') {
                helper.getTodayDueActivities(component, event, helper, currentPagenumber,recordToDisply);

             } else if(sortType == 'filterTomorrowItems') {

                 helper.getTomorrowDueActivities(component, event, helper, currentPagenumber, recordToDisply);

             }else if(sortType == 'filterOverdueItems') {
                 helper.getOverDueActivities(component, event, helper, currentPagenumber, recordToDisply);

             }else if(sortType == 'soryByPriority') {

                 helper.getHighPriorityTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
             }else if(sortType == null || sortType == 'soryByDueDate') {
				if($A.util.isEmpty(component.get("v.groupByParam")) || component.get("v.groupByParam") == "None"){
                 	helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
                }else{
                    helper.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 0);
                }
              }
        
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

        showHighPriority :function(component, event, helper){
        
        var currentPagenumber = component.get("v.currentPagenumber");
        var totalNumberOfPages = component.get("v.totalNumberOfPages");
        var totalRecords = component.get("v.totalRecords");
        var recordToDisply;
        if(component.get("v.recordSize")!=null){
            recordToDisply=component.get("v.recordSize");
        }else{
            /* PC-7400: We would require attribute 'recordsPerPage' in order to display records as per the pagination value*/
            if(component.get('v.recordsPerPage')!=null && component.get('v.recordsPerPage')!=''){
                recordToDisply = component.get('v.recordsPerPage');
            }
            else{
                recordToDisply= Math.ceil(totalRecords / totalNumberOfPages)
                if(recordToDisply<=30){
                    recordToDisply=30;
                }
                else{
                    recordToDisply=60;
                }
            }
        }
        if($A.util.isEmpty(component.get("v.groupByParam")) || component.get("v.groupByParam") == "None"){
            helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
        }else{
            helper.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 0);
        }
        
        component.set("v.dropdownOver",false);
        var mainDiv = component.find('main-div');
        $A.util.removeClass(mainDiv, 'slds-is-open');
    },
    sort : function(component, event, helper) {
        var currentPagenumber = component.get("v.currentPagenumber");
        var totalNumberOfPages = component.get("v.totalNumberOfPages");
        var totalRecords = component.get("v.totalRecords");
        var recordToDisply;
        /* PC-7400: We would require attribute 'recordsPerPage' in order to display records as per the pagination value*/
        if(component.get('v.recordsPerPage')!=null && component.get('v.recordsPerPage')!=''){
            recordToDisply = component.get('v.recordsPerPage');
        }
        else{
            recordToDisply= Math.ceil(totalRecords / totalNumberOfPages);
            if(recordToDisply<=30 || isNaN(recordToDisply)){
                recordToDisply=30;
            }
            else{
                recordToDisply=60;
            }
        }
        var sortType = component.get("v.filterByParam");
        component.set("v.chosenFilter",sortType );
        //helper.setSelectedMenuItem(event.currentTarget);
        if(sortType == 'filterTodaysItems') {
            helper.getTodayDueActivities(component, event, helper, 1, recordToDisply);
        }
        else if(sortType == 'filterTomorrowItems') {
            helper.getTomorrowDueActivities(component, event, helper, 1, recordToDisply);
            
        }
            else if(sortType == 'filterOverdueItems') {
                helper.getOverDueActivities(component, event, helper, 1, recordToDisply);
                
            }
                else if(sortType == 'soryByPriority') {
                    helper.getHighPriorityTasksPagination(component, event, helper, 1, recordToDisply);
                    
                }
                    else if(sortType == 'soryByDueDate') {
                        var groupByOptionSelected = component.get("v.groupByParam");
                        if(groupByOptionSelected === 'Physician' || groupByOptionSelected === 'Patient'){
                            component.set("v.groupByNone", false);
                            helper.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 0);
                        }else{
                            component.set("v.groupByNone", true);
                            helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
                        }

                    }

    },
    
    handleMyApplicationEvent : function(component, event, helper) {
        
        var groupByOptionSelected = component.get("v.groupByParam");
        var sortType=component.get("v.chosenFilter");
        var sourceId = event.getParam("sourceId");
        if(sourceId=='MyTasks'){
            var currentPagenumber = event.getParam("currentPagenumber");
            var recordToDisply=event.getParam("totalNumberOfPages");

            /* PC-7400: We would require attribute 'recordsPerPage' in order to display records as per the pagination value*/
            component.set('v.recordsPerPage',recordToDisply);
            
            if(sortType == 'filterTodaysItems') {
                helper.getTodayDueActivities(component, event, helper, currentPagenumber,recordToDisply);
            }
            else if(sortType == 'filterTomorrowItems') {
                
                helper.getTomorrowDueActivities(component, event, helper, currentPagenumber, recordToDisply);
                
            }
                else if(sortType == 'filterOverdueItems') {
                    helper.getOverDueActivities(component, event, helper, currentPagenumber, recordToDisply);
                    
                }
                    else if(sortType == 'soryByPriority') {
                        
                        helper.getHighPriorityTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
                    }
                        else if(sortType == null || sortType == 'soryByDueDate') {
                            
        					if($A.util.isEmpty(component.get("v.groupByParam")) || groupByOptionSelected === 'None'){
                            	helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
                            }else{
                                helper.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 0);
                            }
                        }
                        component.set("v.dropdownOver",false);
            
        }
        
    },
    applyGroupBy : function(component, event, helper){
        component.set("v.chosenFilter",'soryByDueDate' );

        var currentPagenumber = '1';
        var totalNumberOfPages = component.get("v.totalNumberOfPages");
        var totalRecords = component.get("v.totalRecords");
        var recordToDisply;

        /* PC-7400: We would require attribute 'recordsPerPage' in order to display records as per the pagination value*/
        if(component.get('v.recordsPerPage')!=null && component.get('v.recordsPerPage')!=''){
           recordToDisply = component.get('v.recordsPerPage');
        }
        else{
            recordToDisply= Math.ceil(totalRecords / totalNumberOfPages);
            if(recordToDisply<=30){
                recordToDisply=30;
            }
            else{
                recordToDisply=60;
            }
        }
        if($A.util.isEmpty(component.get("v.groupByParam")) || component.get("v.groupByParam") == "None"){
             component.set("v.groupByNone", true);
             helper.getAllTasksPagination(component, event, helper, currentPagenumber, recordToDisply);
        }else{
         	helper.getAllGroupedByTasks(component, event, helper, currentPagenumber, recordToDisply, 0);
        }
        helper.updateFilterBySelection(component, event, helper, event);

    },
    navigateToAccountRecord: function(component, event, helper) {
        //AccountId

            var rid = event.target.id;

            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": rid,
                "slideDevName": "related"
            });
            navEvt.fire();

   }

    
})