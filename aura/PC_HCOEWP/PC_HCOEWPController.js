({
    doInit : function(component, event, helper) {
        helper.getHeaders(component, event, helper);
        helper.setConfiguration(component);
        helper.setsearchFilterOptions(component, event, helper);
        
        //Check if it is online form
        if(component.get("v.enrollmentCase.isOnlineApplicant")) {
            var enrollmentCaseId = component.get("v.enrollmentCase.enrollmentId");
            helper.handleOnlineForm(component, enrollmentCaseId, helper);
        }
        
        if(component.get("v.selectedHCOIds") != null && component.get("v.selectedHCOIds").length > 0) {
            helper.searchRecordsByIds(component, event, helper, component.get("v.selectedHCOIds"));            
        }
        else {
            helper.searchRecord(component, event, helper);
        }
         setTimeout(function(){
                            component.find("searchHCOId").focus();
                }, 100);

    },
    preventSubmitAction : function(component, event, helper) {
        event.preventDefault();
        return false;
    },
    searchRecord : function(component, event, helper) {
        component.set("v.pageErrors",[]);
        var searchString = component.get("v.searchString");
        if(searchString != "" && searchString.trim().length >= 2) {
            helper.searchRecord(component, event, helper);
        }
        else {
            var pageErrors = component.get("v.pageErrors");
            pageErrors.push(component.get("v.searchStringErrorMessage"));
            component.set("v.pageErrors",pageErrors);
        }

    },
    onAdd : function(component, event, helper)  {
        debugger;
        var currentNode = event.currentTarget;
        
        var index = currentNode.getAttribute("data-text");
        var id = currentNode.getAttribute("data-name");
        
        var searchResults = component.get("v.searchResults");
        
        if ( (component.get("v.selectedHCOIds")).indexOf(id) == -1  ) {
            component.get("v.selectedHCOIds").push(id);
            
            searchResults[index]['isSelected'] = "true";
            var updatedSelectedResult = component.get("v.selectedResults");
            updatedSelectedResult.push(searchResults[index]);
            component.set("v.selectedResults", updatedSelectedResult);
        }
        else {
            searchResults[index]['isSelected'] = "true";
        }
        
        component.set("v.searchResults",searchResults);
    },
    selectRecords : function(component, event, helper) {
        
    },    
    onRemove : function(component, event, helper) {
        debugger;
        var currentNode = event.currentTarget;
        var id = currentNode.getAttribute("data-name");
        var selectedHCOIds = component.get("v.selectedHCOIds");
        
        if ( selectedHCOIds.indexOf(id) != -1  ) {
            
            selectedHCOIds.splice(selectedHCOIds.indexOf(id),1);
            component.set("v.selectedHCOIds", selectedHCOIds)	;
            var updatedSelectedResults = component.get("v.selectedResults");
            for(var i=0; i< updatedSelectedResults.length; i++) {
                if(updatedSelectedResults[i].Id == id) {
                    updatedSelectedResults.splice(i,1);
                    break;
                }
            }
            
            var updatedSearchResults = component.get("v.searchResults");
            for(var j=0; j< updatedSearchResults.length; j++) {
                if(updatedSearchResults[j].Id == id) {
                    updatedSearchResults[j]['isSelected'] = "false";
                    break;
                }
            }
            
            component.set("v.selectedResults", updatedSelectedResults);
            component.set("v.searchResults", updatedSearchResults);
        }
        
    },
    showRecordDetails : function(component, event, helper) {
        /*var currentNode = event.currentTarget;
        var index = currentNode.getAttribute("data-text");
        var id = currentNode.getAttribute("data-name");*/
    },
    searchOnlineRecord : function(component, event, helper) {
        var currentNode = event.currentTarget;
        var searchText = currentNode.dataset.text;
        component.set("v.searchString",searchText);
        helper.searchRecord(component, event, helper);
    }
})