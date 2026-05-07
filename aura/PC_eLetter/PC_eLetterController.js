({
	doInit: function (component, event, helper) {
		//var cc = component.getConcreteComponent();
        //var ns = cc.getDef().getDescriptor().getNamespace();
        //component.set("v.recipients", a.getReturnValue());
        helper.initLetters(component);
	},
	onChangeSelectedLetter: function (component, event, helper) {
       component.set("v.message",'');
       var toggleText = component.find("msgResult");
       $A.util.removeClass(toggleText, 'msgDisplayTrue');
       $A.util.addClass(toggleText, 'msgDisplayFalse');
        var eLetterValue=component.find("inputSelectLetter").get("v.value");

        if(eLetterValue!=undefined && eLetterValue!=component.get("v.noneValue")){
            helper.loadRecipients(component);
        }else{
             component.set("v.recipients",[]);
             component.set('v.selectedELetterVal',eLetterValue);
        }
	},
	onSend: function (component, event, helper) {
		var eLetterValue=component.find("inputSelectLetter").get("v.value");
		if(eLetterValue!=undefined && eLetterValue!=component.get("v.noneValue")){
		    helper.sendDocuments(component);
		}
		else{
		   component.set("v.message",component.get("v.noeLetterSelectedError"));
           var toggleText = component.find("msgResult");
           $A.util.removeClass(toggleText, 'msgDisplayFalse');
           $A.util.addClass(toggleText, 'msgDisplayTrue');
        }
	},
	validateEletterId: function(component,event,helper){
        if(event.getParam("isEletterInvalid")){
           component.set("v.message",component.get("v.noeLetterSelectedError"));
           var toggleText = component.find("msgResult");
           $A.util.removeClass(toggleText, 'msgDisplayFalse');
           $A.util.addClass(toggleText, 'msgDisplayTrue');
        }
    }
})