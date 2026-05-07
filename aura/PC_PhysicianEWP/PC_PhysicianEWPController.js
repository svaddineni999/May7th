({
    doInit : function(component, event, helper) {
        helper.getHeaders(component, event, helper);
        if(component.get("v.enrollmentCase.isOnlineApplicant")) {
            var enrollmentCaseId = component.get("v.enrollmentCase.enrollmentId");
            helper.handleOnlineForm(component, enrollmentCaseId, helper);
        }
        
        if(component.get("v.selectedResult") != null) {
            var selectedResult = component.get("v.selectedResult");
            var searchResults = component.get("v.searchResults");
            searchResults.push(selectedResult);
            component.set("v.searchResults",searchResults);
        }
        else {
            helper.searchRecord(component, event, helper);
        }
         setTimeout(function(){
                            component.find("searchInputText").focus();
                }, 100);
    },

    preventSubmitAction : function(component, event, helper) {
        event.preventDefault();
        return false;
    },
    clearSelection : function(component, event, helper) {
        var x;
        var y;
        component.set("v.searchResults",x);
        component.set("v.selectedResult",y);
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
    onSelect : function(component, event, helper) {
        var index = event.getSource().get("v.text");
        var searchResult = component.get("v.searchResults");
        searchResult[index]['isSelected'] = "true";
        component.set("v.selectedResult",searchResult[index]);
    }    
})