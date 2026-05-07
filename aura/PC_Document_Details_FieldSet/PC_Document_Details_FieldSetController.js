({
	init : function(component, event, helper) {
		var form = component.get("v.fieldset");
        var c = form[component.get("v.index")];
        var label = c.label;
        var value = c.value;
        component.set("v.label", label);
        component.set("v.value", value);
	}
})