({
	doInit : function(component, event, helper) {
        var services = component.get("v.services");
        
        if (services === null) {
            services = [
                    {'Name': 'Benefits Investigation', 'Selected': false},
                    {'Name': 'Prior Authorization', 'Selected': false}
            ];
            
            component.set("v.services", services);
        }
	},
    validate : function(component, event, helper) {
		console.log("program services validation");

		var valid = component.get("v.facilityName") != "invalid";

		if (!valid) {
		    component.set("v.pageErrorHeader", "This is a custom error header.");
		    component.set("v.pageErrors", ["First error", "Second error"]);
        }

        component.set("v.isValid", valid);
	}
})