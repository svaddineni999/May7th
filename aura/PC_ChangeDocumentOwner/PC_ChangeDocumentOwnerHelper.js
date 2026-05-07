({
    doSearch : function(cmp) {
        var searchString = cmp.get("v.searchString");
        var inputElement = cmp.find('lookup');
        var lookupList = cmp.find("lookuplist");
        var lookupListItems = cmp.find("lookuplist-items");
        inputElement.set('v.errors', null);
        lookupListItems.set('v.body', new Array());
        if (typeof searchString === 'undefined' || searchString.length < 2){
            $A.util.addClass(lookupList, 'slds-hide hideBorder');
            return;
        }
        // Show the lookuplist
        $A.util.removeClass(lookupList, 'hideBorder');
        $A.util.removeClass(lookupList, 'slds-hide');
        
        $A.util.removeClass(lookupListItems, 'slds-hide');
        // Create an Apex action
        var action = cmp.get("c.lookup");
        // Mark the action as abortable, this is to prevent multiple events from the keyup executing
        action.setAbortable();
        action.setParams({ "searchString" : searchString});                     
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS"){
                // Get the search matches
                var matches = response.getReturnValue();
                
                // If we have no matches, return
                if (matches.length == 0) {
                    $A.util.addClass(lookupList, 'slds-hide hideBorder');
                    return;
                }
                // Render the results
                lookupListItems.set('v.body', new Array());
                this.renderLookupComponents(cmp, lookupListItems, matches);
            }
            else if (cmp.isValid() && state === "ERROR"){
                var errors = response.getError();
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
    
    renderLookupComponents : function(cmp, lookupListItems, matches) {
        // Array of components to create
        var newComponents = new Array();
        for (var i=0; i<matches.length; i++) {
            var text = matches[i].SObjectLabel;
            if (text.length > 25) {
				text = text.substr(0,22) + "...";             
            }
            // li element
            newComponents.push(["aura:html", {
                "tag" : "li",
                "HTMLAttributes" : {
                    "class" : ""
                }
            }]);
            // a element
            newComponents.push(["aura:html", {
                "tag" : "a",
                "HTMLAttributes" : { 
                    "id" : cmp.getGlobalId() + '_id_' + matches[i].SObjectId, 
                    "role" : "option", 
                    "class" : "matchedItem",
                    "onclick" : cmp.getReference("c.select") 
                }
            }]);
            newComponents.push(["ui:outputText", {
                "value" : text
            }]);
        }
        // Create the components
        $A.createComponents(newComponents, function(components, status) {
            if (status === "SUCCESS"){
                // Get the List Component Body
                var lookupListItemsBody = lookupListItems.get('v.body');
                var li;
                var a;
                var outputText;
                var liBody;
                var aBody;
                for (var i=0; i<components.length; i+=3) {
                    // Identify the releated components
                    li = components[i];
                    a = components[i+1];
                    outputText = components[i+2];
                    // Add the <a> to the <li>
                    liBody = li.get('v.body');
                    liBody.push(a);
                    li.set('v.body', liBody);
                    // Add the <outputText> to the <a>
                    aBody = a.get('v.body');
                    aBody.push(outputText);
                    a.set('v.body', aBody);
                    // Add the <li> to the container
                    lookupListItemsBody.push(li);
                }
                // Update the list body
                lookupListItems.set('v.body', lookupListItemsBody);
           }
        });
    },

    handleSelection : function(cmp, event) {
        debugger;
        var objectId = this.resolveId(event.currentTarget.id);
        var objectLabel = event.currentTarget.text;
        
        cmp.set("v.userId", objectId);
        cmp.set("v.userName", objectLabel);
 
        // Update the Searchstring with the Label
        cmp.set("v.searchString", objectLabel);
 
        // Hide the Lookup List
        var lookupList = cmp.find("lookuplist");
        $A.util.addClass(lookupList, 'slds-hide hideBorder');
        
        var lookupListItems = cmp.find("lookuplist-items");
        $A.util.addClass(lookupListItems, 'slds-hide');
 
        // Hide the lookup
        var lookup = cmp.find('lookup');
        $A.util.addClass(lookup, 'slds-hide');
 
        // Show the Lookup pill
        var lookupPill = cmp.find("lookup-pill");
        $A.util.removeClass(lookupPill, 'slds-hide');
 
        // Lookup Div has selection
        var lookupDiv = cmp.find('lookup-div');
        $A.util.addClass(lookupDiv, 'slds-has-selection');
    },
    //Clear the Selection
    clearSelection : function(cmp) {
        cmp.set("v.userId", "");
        cmp.set("v.userName", "");
        
        // Clear the Searchstring
        cmp.set("v.searchString", '');
 
        // Hide the Lookup pill
        var lookupPill = cmp.find("lookup-pill");
        $A.util.addClass(lookupPill, 'slds-hide');
 
        // Show the lookup
        var lookup = cmp.find('lookup');
        $A.util.removeClass(lookup, 'slds-hide');
 
        // Lookup Div has no selection
        var lookupDiv = cmp.find('lookup-div');
        $A.util.removeClass(lookupDiv, 'slds-has-selection');
    },
    //Resolve the Object Id from the Element Id by splitting the id at the _
    resolveId : function(elmId) {
        var i = elmId.lastIndexOf('_');
        return elmId.substr(i+1);
    },

})