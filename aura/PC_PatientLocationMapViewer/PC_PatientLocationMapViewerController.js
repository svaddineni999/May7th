({
    doInit: function(component, event, helper) {
        if(component.get("v.isAfterScriptsLoadedCalled") == false &&
          typeof L !== 'undefined') 
        {
            helper.getFieldLabels(component);
            helper.setNamespace(component);
            helper.getPatient(component);
            helper.getDistanceUnit(component);            
        }
	},
    afterScriptsLoaded: function(component, event, helper) {
        if(component.get("v.isAfterScriptsLoadedCalled") == false) {
            component.set("v.isAfterScriptsLoadedCalled", true);
            helper.getFieldLabels(component);
            helper.setNamespace(component);
            helper.getPatient(component);
            helper.getDistanceUnit(component);            
        }
	},
    loadMap : function(component, event, helper) {
		var patient = component.get("v.patient");
        console.log('component.get("v.patientHasAddress") ' + component.get("v.patientHasAddress"));
		if(patient != null && component.get("v.patientHasAddress") == true) {
            helper.getDistanceUnit(component);
			helper.getAvailableClinics(component);
			helper.drawMap(component);
		}
    },
    reloadMap : function(component, event, helper) {
		var patient = component.get("v.patient");	
		if(patient != null && component.get("v.patientHasAddress") == true) {
            helper.getDistanceUnit(component);
			helper.getAvailableClinicImages(component);
			helper.drawMap(component);
		}
    }
})