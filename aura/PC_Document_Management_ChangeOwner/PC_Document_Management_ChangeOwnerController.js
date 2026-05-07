({
    
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.getDocName(component, event);
        helper.showGroupButton(component, event,helper);
    },
    
    //Search an SObject for a match
    search : function(cmp, event, helper) {        
        helper.doSearch(cmp);
    },
    
    //Select an SObject from a list
    select: function(cmp, event, helper) {
         cmp.set("v.isValidUserNotFound",false);
        helper.handleSelection(cmp, event);
    },
    
    //Clear the currently selected SObject
    clear: function(cmp, event, helper) {
        cmp.set("v.isValidUserNotFound",true);
        helper.clearSelection(cmp);    
    }    ,
    
    //Reassign the document to the selected user
    reassignDoc: function(component, event, helper) {
        
        helper.reassignDoc(component, event); 
        helper.hideModal(component, event, helper);
        
    },
    
    hideModalBox : function(component, event, helper) {
        helper.hideModal(component, event, helper);
    },

    handleClick : function(component, event, helper) {
        debugger;
        var selectedButton = event.getSource();
        var selectedButtonName = selectedButton.get("v.name");

        if(selectedButtonName == "userBtn") {
            helper.toggleButtons(component, event, helper, "userBtn");
        }
        else {
            helper.toggleButtons(component, event, helper, "queueBtn");
        }
    }
})