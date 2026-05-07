/**
         * Created by sahgarg on 3/15/2018.
         */
({
    doInit : function(component, event, helper) {
        console.log('===============test=======');
        
        var currentPagenumber = component.get("v.currentPagenumber");
        var recordToDisply = '30';
        helper.getAllAlertsPagination(component,helper,currentPagenumber, recordToDisply);

    },

    refreshView: function(component, event, helper) {
        var currentPagenumber = 1;
        component.set("v.currentPagenumber", currentPagenumber);
        component.set("v.lstActivity", []);
        component.set("v.totalRecords", 0);
        var recordToDisply = component.get("v.recordsPerPage");
        helper.getAllAlertsPagination(component,helper,currentPagenumber, recordToDisply);
    },
    
    handleTaskUpdated : function(component, event, helper) {
        console.log("task Event occured");
        
        // get the page Number if it's not define, take 1 as default
        var currentPagenumber = component.get("v.currentPagenumber") || 1;
        // get the select option (drop-down) values.   
        

        var pages = component.get("v.totalNumberOfPages");
        var total = component.get("v.totalRecords");
        var recordToDisply;
        
        recordToDisply= Math.ceil(total / pages)
        if(recordToDisply<=30){
            recordToDisply=30;
        }
        else{
            recordToDisply=60;
        }
        
        helper.getAllAlertsPagination(component,helper,currentPagenumber, recordToDisply);
        
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
    
    
    
    
    handleMyApplicationEvent : function(component, event, helper) {
        
        console.log("appevent handling");
        var sourceId = event.getParam("sourceId");
        
        if(sourceId=='MyAlerts' ){   
            var currentPagenumber = event.getParam("currentPagenumber");
            var recordSize=event.getParam("totalNumberOfPages");
            
            helper.getAllAlertsPagination(component,helper,currentPagenumber, recordSize);
        }       
        
        
    },
    
    markDismissAction: function(component, event, helper){
        component.set("v.dropdownOver",false);
        var mainDiv = component.find('main-div');
        $A.util.removeClass(mainDiv, 'slds-is-open');
        
        $A.util.addClass(mainDiv, 'hideDivPartial');
        helper.markDismissActivity(component);
    },
    
})