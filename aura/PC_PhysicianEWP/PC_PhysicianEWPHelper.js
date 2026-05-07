({
    searchRecord : function(component, event, helper) {
        var searchString = component.get("v.searchString");
        if(searchString != "" && searchString.length >= 2) {
            console.log("Physician Search String = " + searchString);
            component.set("v.showSpinner",true);
            var action = component.get("c.searchRecords");
            action.setParams({
                'searchString' : searchString
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
            });
            $A.enqueueAction(action);
        }
       
    },
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
                component.set('v.physicianTableHeaders', returnValue);
            } else {
                console.log("searchRecord: Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        
        
    },
    
    handleOnlineForm : function(component, enrollmentCaseId, helper) {
        component.set("v.showSpinner",true);
       	var action = component.get("c.getApplicantPhysician"); //
        action.setParams({
                "enrollmentCaseId"	: enrollmentCaseId,
                "activeApplicantId"	: component.get("v.enrollmentCase.applicantId") //[PC-1379] Handles multiple applicants on enrollment case
        });
        
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.showSpinner",false);
                var returnValue = a.getReturnValue();
                component.set("v.onlineApplicantPhysician",returnValue[0]);
                var onlineAppPhysician = component.get("v.onlineApplicantPhysician");
              	var showRefTable;
                if($A.util.isUndefinedOrNull(onlineAppPhysician) || onlineAppPhysician =='') {
                    console.log("Physician on online form not found");
                    showRefTable = false; 
                }else{
                    showRefTable = true;
                }
                component.set("v.showRefTable", showRefTable);
                
                //Initialize search string with applicant's Physician name
                if(showRefTable) {
                    var initSearchString = returnValue[0].name;
                    //Physician name found, set the search string with Physician name
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
    
    
})