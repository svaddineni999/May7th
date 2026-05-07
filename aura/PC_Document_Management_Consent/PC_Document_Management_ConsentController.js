({
	closeWindow : function(component, event, helper){
        component.set("v.isModalMapActive", false);
    },

    getConsentCasesList: function(component, event, helper){
        helper.setNamespace(component);
        helper.fetchConsentCasesList(component, event, helper);
        //helper.getFieldLabels(component, event, helper);
        component.set("v.isModalMapActive",true);
        
    },
    
    goToSelectedLink : function(component, event, helper) {
         var objectId = event.currentTarget.id;
         window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
         /*var subTabURL = '/lightning/r/' + objectId + '/view';
         var workspaceAPI = component.find("workspace");
         workspaceAPI.getFocusedTabInfo().then(function(response) {
             var parentTabId;
             var focusedTabId = response.tabId;
             if(response.parentTabId == null){
                 parentTabId= response.tabId;
             }else{
                 parentTabId= response.parentTabId;
             }
             
             //console.log(response);
             //console.log("Tab ID is "+focusedTabId);
    		 workspaceAPI.openSubtab({
                	parentTabId: parentTabId,
                	url:subTabURL ,
                	focus: true
            		});                 
             
		 })*/
   },
    
    getAllServicesAndForms: function(component, event, helper){
        helper.fetchAllServicesAndForms(component, event, helper);
    },
    
    createConsent: function(component, event, helper){
        component.set("v.isModalMapActive", false);
        helper.insertNewConsent(component, event, helper);
        
        	
    },
    editConsent : function(component, event, helper){
        helper.editExistingConsent(component, event, helper);
        console.log(component.get("v.namespacePrefix"));
        console.log(component.get("v.namespace"));	
    }
   
})