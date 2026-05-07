({
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.getDocRecordTypeId(component, event, helper);
        
        helper.getPickListValues(component, event, helper);
    },
    
    //updates document status to current status
    updateStatus: function(component, event, helper) {
        helper.updateStatus(component, event, helper);
    },
    
    hideModalBox : function(component, event, helper) {
        helper.hideModal(component, event, helper);
    }
})