({
	sendMessageC: function (component, event, helper) {
		helper.sendMessageH(component);
	},
    
    doInit: function (component, event, helper) {
	    helper.getCaseMessages(component);
	}
})