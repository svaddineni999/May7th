({
    getHeaders : function(component, event, helper) {
        component.set("v.showSpinner",true);
        var action = component.get("c.getFields");
        action.setParams({
            
        });
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set('v.HCOTableHeaders', returnValue);
            } else {
                console.log("searchRecord: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        
        
    },
    
    setsearchFilterOptions : function(component, event, helper) {
        component.set("v.showSpinner",true);
        var action = component.get("c.getHCOTypes");
        action.setParams({
                  'namedCredentialName' : component.get('v.namedCredentialName'),
        });
       	action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set('v.searchFilterOptions', returnValue);
            } else {
                var toastEvent  = $A.get("e.force:showToast");
                var errorMessage = response.getError()[0].message;
                toastEvent.setParams({
                    "title": component.get('v.toastErrorTitle'),
                    "message": errorMessage,
                    "type": "error",
                    "mode": "sticky"
                });
                toastEvent.fire();
                console.log("getHCOTypes: Failed with state: " + state + errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    searchRecord : function(component, event, helper) {
        var searchString = component.get("v.searchString");
        var searchFilter = component.find("searchFilterOptions").get("v.value");
        console.log("Selected filter value " + searchFilter);
        searchFilter = searchFilter == component.get("v._searchFilterOptionAll") ? "" : searchFilter;
        if(searchString != "" && searchString.length >= 2) {
            component.set("v.showSpinner",true);
            var action = component.get("c.searchRecords");
            action.setParams({
                'searchString' : searchString,
                'searchFilter' : searchFilter
            });
            action.setCallback(this, function(response) {
                component.set("v.showSpinner",false);
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    
                    var returnValue = response.getReturnValue();
                    component.set('v.searchResults', returnValue);
                    if(returnValue.length > 0) {
                        $A.util.addClass(component.find('searchResultMsg'),'searchResultMsgBlockHidden');
                    }
                    else {
                        $A.util.removeClass(component.find('searchResultMsg'),'searchResultMsgBlockHidden')
                    }
                    
                } else {
                    console.log("searchRecord: Failed with state: " + state);
                }
                
                helper.renderSelectedHCOInSearchBlock(component, event, helper);
            });
            $A.enqueueAction(action);
        }
    },
    searchRecordsByIds : function(component, event, helper, ids) {
        component.set("v.showSpinner",true);
        var action = component.get("c.searchRecordsByIds");
        action.setParams({
            'accountIds' : ids
        });
        action.setCallback(this, function(response) {
            component.set("v.showSpinner",false);
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set('v.selectedResults', returnValue);  
                var item;
                for (var i = 0; i < returnValue.length; i++) {
                    item = returnValue[i];
                    if(component.get("v.selectedHCOIds").indexOf(item.Id) == -1) {
                        component.get("v.selectedHCOIds").push(item.Id)
                    }
                }
            } else {
                console.log("searchRecordsByIds: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    renderSelectedHCOInSearchBlock : function(component, event, helper) {
        var selectedHCOIds = component.get("v.selectedHCOIds");
        var searchResults = component.get('v.searchResults');
        
        for(var i=0; i<searchResults.length; i++) {
            if(selectedHCOIds.indexOf(searchResults[i].Id) == -1) {
                // not found case
                searchResults[i].isSelected = "false";
            }
            else {
                // found case
                searchResults[i].isSelected = "true";
            }
        }
        component.set('v.searchResults',searchResults);
    },
    
       
    handleOnlineForm : function(component, enrollmentCaseId, helper) {
        component.set("v.showSpinner",true);
		var action = component.get("c.getApplicantHCO");
        action.setParams({
                "enrollmentCaseId"	: enrollmentCaseId,
                "activeApplicantId"	: component.get("v.enrollmentCase.applicantId") //[PC-1379] Handles multiple applicants on enrollment case
        });
        
        action.setCallback(this, function(a) {
            component.set("v.showSpinner",false);
            if(a.getState() ==="SUCCESS") {
                var returnValue = a.getReturnValue();
                component.set("v.onlineApplicantHCO",returnValue);
                var onlineAppHCO = component.get("v.onlineApplicantHCO");
				var showRefTable;
                if($A.util.isUndefinedOrNull(onlineAppHCO) || onlineAppHCO =='') {
                    console.log("HCO on online form not found");
                    showRefTable = false; 
                }else{
                    showRefTable = true;
                }
                component.set("v.showRefTable", showRefTable);
               //Initialize search string with applicant's HCO name
                if(showRefTable) {
                    var initSearchString = returnValue[0].name;
                    //If HCO name found, set the search string with HCO name
                    if(initSearchString != null && initSearchString != undefined){
                        component.set("v.searchString",initSearchString);
                     	helper.searchRecord(component, event, helper);
                    }
                }
                
                    
            } else if (a.getState() ==="ERROR") {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
                var errText = component.get("v.ErrorText");
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

    setConfiguration : function(component) {
        var config = component.get("v.config");
        if(!$A.util.isEmpty(config)) {
            var parsedConfig = JSON.parse(config);
            console.log("Config as in custom metadata...");
            console.log(parsedConfig);
            var namedCredentialName = parsedConfig["namedCredentialName"];
            component.set("v.namedCredentialName",namedCredentialName);
        }
    },
})