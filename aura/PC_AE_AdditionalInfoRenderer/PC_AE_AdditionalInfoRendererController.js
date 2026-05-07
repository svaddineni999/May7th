({
	doInit : function (component, event, helper){
	    component.set('v.errors',[]);
        helper.setNamespace(component, helper);
        helper.setFieldSetNameAndType(component, helper);
        helper.setFieldSetObject(component, event, helper);
	},
    validate : function(component, event, helper) {
        return helper.validateFieldSetForm(component, helper);
    }

})