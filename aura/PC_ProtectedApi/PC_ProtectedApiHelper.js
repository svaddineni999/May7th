({
	showSuccessToast : function(component,message,apiInput) {
		var del=100; 

                    var title = component.get("v.toastTitleSuccess");
                    
                    setTimeout(function() {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: title,
                            message: apiInput + ' - ' + message,
                            type: "success"
                        });
                        toastEvent.fire();
                    }, del);
	},
    showErrorToast: function(component,message) {
    				var del=100; 
                    setTimeout(function() {
                        var toastEvent = $A.get("e.force:showToast");
                        var titleError = component.get("v.toastTitleError");
                        
                        toastEvent.setParams({
                            title:titleError ,
                            message: message,
                            type: "error"
                        });
                        toastEvent.fire();
                    }, del);
    },
    setDesc: function(component,event) {

        var apiSelected = component.get("v.apiSelectedValue");
        var apiDesc = component.get("v.apiLabelDescription")[apiSelected];
        component.set("v.apiPicklistDesc",apiDesc);
    }
})