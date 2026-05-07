({
    doInit : function(component, event, helper) {
      helper.setNamespace(component)  ;
    },
    
    openWizard : function(component, event, helper){
    	var docId =	component.get("v.recordId");
        if(docId == "NULL"){
            helper.launchWizard (component, event, helper);
        } else {
            helper.launchPopUp (component, event, helper);
        }
    },
    
    hideModalBox : function(component, event, helper) {
        helper.hideModal(component, event, helper);
    },
    
    goToCase : function(component, event, helper) {
    	helper.goToCase(component, event, helper);        
    }
})