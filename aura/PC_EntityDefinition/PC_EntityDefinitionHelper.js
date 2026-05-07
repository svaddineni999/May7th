/**
 * Created by tusarora on 3/11/2020.
 */
({
    searchHelper : function(component, event, getInputkeyWord, isPlatformEventContext) {
        // call the apex class method
        var action = component.get("c.getEntityDefinitionList");
        action.setParams({
            'searchKeyword': getInputkeyWord,
            'isPlatformEventContext' : isPlatformEventContext
        });
        // set a callBack
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            console.log('state::::'+state);
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
                if(component.get("v.selectedRecord") != "{}" && component.get("v.defaultPill")){
                    var objectsList = component.get("v.listOfSearchRecords");
                    
                    for(var selectedObject of objectsList){
                        
                        if(selectedObject.QualifiedApiName == component.get("v.selectedRecord.QualifiedApiName")){
                     
                            component.set("v.selectedRecord",selectedObject);
                            var forclose = component.find("lookup-pill");
                            $A.util.addClass(forclose, 'slds-show');
                            $A.util.removeClass(forclose, 'slds-hide');
                             
                            var searchRes = component.find("searchRes");
                            $A.util.addClass(searchRes, 'slds-is-close');
                            $A.util.removeClass(searchRes, 'slds-is-open');
                            
                            var lookUpTarget = component.find("lookupField");
                            $A.util.addClass(lookUpTarget, 'slds-hide');
                            $A.util.removeClass(lookUpTarget, 'slds-show');
                            
                        }
                    }}
            }
            
        });
        // enqueue the Action
        $A.enqueueAction(action);
        
    },
})