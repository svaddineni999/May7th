({
    
    getPatientConsentList: function(component, event, helper){
        helper.setNamespace(component);
        helper.fetchPatientConsentList(component, event, helper);
        //helper.getFieldLabels(component, event, helper);
    },
    
    goToSelectedLink : function(component, event, helper) {
        var objectId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
        /*console.log("Object ID: "+objectId); 
         var subTabURL = '/lightning/r/' + objectId + '/view';
        console.log("Sub tab url: "+subTabURL);
         var workspaceAPI = component.find("workspace");
        console.log("workspace api: : "+workspaceAPI);
         workspaceAPI.getFocusedTabInfo().then(function(response) {
             var parentTabId;
             var focusedTabId = response.tabId;
             console.log("focused tab id : "+focusedTabId);
             if(response.parentTabId == null){
                 parentTabId= response.tabId;
             }else{
                 parentTabId= response.parentTabId;
             }
             console.log("Parent tab ID: "+parentTabId);
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
        console.log(component.get("v.namespace"));
        console.log(component.get("v.namespacePrefix"));
        helper.insertNewConsent(component, event, helper);
        	
    },
    
    editConsent : function(component, event, helper){
        helper.editExistingConsent(component, event, helper);
        	
    },
    
    				
                                    
 
})