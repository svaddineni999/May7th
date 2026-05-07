({
/*    getFieldLabels : function(component){
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue);
            } else {
                //console.log("Failed with state: " + state);
                component.set("v.errors", response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
*/
    editExistingConsent : function(component, event, helper) {
    	var editRecordEvent = $A.get("e.force:editRecord");
        var id = event.getSource().get("v.value");
    	editRecordEvent.setParams({
         	"recordId": id
    	});
    	editRecordEvent.fire();
   },
    
    insertNewConsent: function (component, event, helper){
        var createRecordEvent = $A.get("e.force:createRecord");
        var caseId = component.get("v.recordId");
        var namespacePrefix = component.get("v.namespacePrefix");
        var api = namespacePrefix +'PC_Program_Service_Permission__c';
        var caseField = namespacePrefix +'PC_ProgramCase__c';
        var parameters = {
                "entityApiName": api,
                "defaultFieldValues" : {
                }
        }
          
        parameters["defaultFieldValues"][caseField] = caseId;
        createRecordEvent.setParams(parameters);
		createRecordEvent.fire(); 
    },
    
    fetchPatientConsentList: function (component, event, helper){
        component.set("v.isLoading", true);
        var action =  component.get("c.getPatientConsents");
        var caseId = component.get("v.recordId");
        console.log(caseId);
        action.setParams({
            caseId: caseId
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var consentPatientList =response.getReturnValue();
                console.log(consentPatientList);
                //component.set("v.consentPatientList", consentPatientList);
                component.set("v.consentPatientList", consentPatientList.consentsList);
                component.set("v.fieldLabels",consentPatientList.fieldLabels);                
            }
            else{
                //alert("Error in fetching data");
                component.set("v.errors", response.getError());
            }
            component.set("v.isLoading", false);
                           
        });
        $A.enqueueAction(action);
    },


    setNamespace : function(component) {
  		
        var component_to_string = component.toString();
        console.log(component_to_string);
        var markupTagLoc = component_to_string.indexOf('markup://');
        console.log(markupTagLoc);
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        console.log(endOfNamespaceLoc);
        
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        console.log(ns);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        console.log(namespacePrefix);
  		component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
        
    }

})