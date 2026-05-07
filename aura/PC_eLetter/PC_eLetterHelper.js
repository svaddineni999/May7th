({
    initLetters: function(component) {
        console.log(component.get("v.recordId"));
        var action = component.get("c.getLetters");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(a) {
			var state = a.getState();
			if (state === 'SUCCESS'){
				var inputsel = component.find("inputSelectLetter");
				var lstAvailableeLetters = a.getReturnValue();
				var opts=[];
				for(var i=0;i< lstAvailableeLetters.length;i++){
					var currentVal =lstAvailableeLetters[i];
					opts.push({"class": "optionClass", label: currentVal.name, value: currentVal.value});
				}
				inputsel.set("v.options", opts);
				if(lstAvailableeLetters.length==1){
				   component.set("v.message", component.get("v.msgNoEngagementProgram"));
				   var toggleText = component.find("msgResult");
				   $A.util.removeClass(toggleText, 'msgDisplayFalse');
                   $A.util.addClass(toggleText, 'msgDisplayTrue');
                }
			} else if (state === "ERROR") {
				var errors = a.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.message", errors[0].message);
                } else {
                    component.set("v.message", 'Unknown error');
                }
			}
            if($A.util.isEmpty(component.get("v.message"))){
            	var msgResult = component.find("msgResult");
				$A.util.removeClass(msgResult, 'msgDisplayTrue');
                $A.util.addClass(msgResult, 'msgDisplayFalse');
            }
		});
        $A.enqueueAction(action); 
    },
	loadRecipients: function(component) {
        var action = component.get("c.getRecipients");
        component.set('v.selectedELetterVal',component.find("inputSelectLetter").get("v.value"));
        action.setParams({
			"recordId": component.get("v.recordId"),
			"letterId": component.find("inputSelectLetter").get("v.value")
		});
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                var recipientList = a.getReturnValue();
                var noContactNameList = [];
				component.set("v.recipients", a.getReturnValue());
				if($A.util.isEmpty(a.getReturnValue())) {
					component.set("v.message", component.get("v.msgNoRecipient"));
				}else{
				    for(var i=0; i<recipientList.length; i++){
				        if(recipientList[i].hasContactEmail == false){
				            noContactNameList.push(recipientList[i].recipient.name);
                        }
                    }
                    if(noContactNameList.length > 0){
                        component.set("v.message", component.get("v.msgNoPrimaryContact")+noContactNameList.join(" and "));
                    }
                }
            } else if (state === "ERROR") {
                         var errors = a.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.message", errors[0].message);
                } else {
                    component.set("v.message", 'Unknown error');
                }
            }
            var toggleText = component.find("msgResult");
            if($A.util.isEmpty(component.get("v.message"))){
                $A.util.removeClass(toggleText, 'msgDisplayTrue');
                $A.util.addClass(toggleText, 'msgDisplayFalse');
            } else {
                $A.util.removeClass(toggleText, 'msgDisplayFalse');
                $A.util.addClass(toggleText, 'msgDisplayTrue');
            }
			
		});
        $A.enqueueAction(action); 
    },
	sendDocuments: function(component) { 	
        var action = component.get("c.sendOutboundDocuments");
        action.setParams({
			//"recipientsString": $A.util.json.encode(component.get("v.recipients")),
			//$A.util.json.encode does not work in locker service and hence is replaced with JSON.stringify
			"recipientsString": JSON.stringify(component.get("v.recipients")),
			"letterId": component.find("inputSelectLetter").get("v.value"),
			"objectId": component.get("v.recordId")
		});
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
				component.set("v.message", a.getReturnValue());
            } else if (state === "ERROR") {
				var errors = a.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.message", errors[0].message);
                } else {
                    component.set("v.message", 'Unknown error');
                }
			}
			var toggleText = component.find("msgResult");
            if($A.util.isEmpty(component.get("v.message"))){
                $A.util.removeClass(toggleText, 'msgDisplayTrue');
                $A.util.addClass(toggleText, 'msgDisplayFalse');
            } else {
                $A.util.removeClass(toggleText, 'msgDisplayFalse');
                $A.util.addClass(toggleText, 'msgDisplayTrue');
            }
		});
        $A.enqueueAction(action); 
    },
	displayError: function(a) { 	
		var errors = a.getError();
        if (errors && errors[0] && errors[0].message) {
			component.set("v.message", errors[0].message);
		} else {
			component.set("v.message", 'Unknown error');
		}
	}
})