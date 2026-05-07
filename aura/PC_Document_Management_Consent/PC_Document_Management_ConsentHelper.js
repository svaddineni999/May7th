({
/*    getFieldLabels : function(component){
               
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue);
                
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    
*/    
    insertNewConsent: function (component, event, helper){
        var createRecordEvent = $A.get("e.force:createRecord");
        //var windowRedirect = window.location.href;
        //console.log(windowRedirect);
        var docId = component.get("v.recordId");
        var namespacePrefix = component.get("v.namespacePrefix");
        var api = namespacePrefix + 'PC_Program_Service_Permission__c';
        console.log(api);
        var docField = namespacePrefix+'PC_Signed_Request_Form__c';
        var consentTypeField = namespacePrefix+'PC_Consent_Type__c';
        var parameters = {"entityApiName": api,
                "defaultFieldValues" : { }
                /*,"panelOnDestroyCallback": function(event) {
       				 window.location.href = windowRedirect; // Return to the page where the record was created
    			}*/
        }
        parameters["defaultFieldValues"][docField] = docId;
        parameters["defaultFieldValues"][consentTypeField] = "Written";
        createRecordEvent.setParams(parameters);
        createRecordEvent.fire(); 
    },
    
    editExistingConsent : function(component, event, helper) {
    	var editRecordEvent = $A.get("e.force:editRecord");
        var id = event.getSource().get("v.value");
    	editRecordEvent.setParams({
         	"recordId": id
    	});
    	editRecordEvent.fire();
   },
    
    fetchConsentCasesList: function (component, event, helper){
        var action =  component.get("c.getConsentCases");
        var docId = component.get("v.recordId");
        //console.log(docId);
        action.setParams({
            docIds: docId
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state =="SUCCESS"){
                var consentCasesList =response.getReturnValue();
                //console.log(consentCasesList);
                //component.set("v.consentCases", consentCasesList);
                component.set("v.consentCases", consentCasesList.consentsList);
                component.set("v.fieldLabels",consentCasesList.fieldLabels);                   
            }
            else{
                //alert("Error in fetching data");
                component.set("v.errors", response.getError());
            }
                           
        });
        $A.enqueueAction(action);
    },
    

    
    setNamespace : function(component) {
  		
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        
  		component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
        console.log(ns);
        console.log(namespacePrefix);
        
    }

})