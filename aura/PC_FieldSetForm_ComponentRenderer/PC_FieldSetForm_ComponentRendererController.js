({
	init : function(component, event, helper) {
		var form = component.get("v.lightningFormMap");
        var c = form[component.get("v.index")];
        //console.log("Rendering " + c.toString())
        component.set("v.lightningFormCmp", c);
        component.set("v.body", c);
        //console.log("Rendered " + c.toString());
	}
})