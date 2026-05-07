/**
 * Created by shisbansal on 11/15/2018.
 */
({
    getELetter: function(component, event, helper){
        var action = component.get("c.geteLetterObject");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var picklistOptions = [{ class: "optionClass", label: component.get('v.picklistNone'), value: ""}];
                var result = response.getReturnValue();
                component.set("v.eletterWrapper" , result);
                if(result.eLettres.length > 0) {
                    for (var i = 0; i < result.eLettres.length; i++) {
                            picklistOptions.push({
                                class: "optionClass",
                                label: result.eLettres[i].eLetterName ,
                                value: result.eLettres[i].eLetterName
                            });
                        }
                    component.find("EletterOptions").set("v.options",picklistOptions);
                    component.set("v.recipentMapping",result.eLettres[0].targetRecepientMapping);
                    this.setEletterOptions(component, event, helper, picklistOptions);
                    if(!$A.util.isEmpty(component.get("v.taskJSON"))){
                        this.compareWithStoredValue (component, event, helper);
                    }
                    this.onEletterChange (component, event, helper);
                } else {
                    component.find("EletterOptions").set("v.errors",[{message:component.get("v.errorMsg")}]);
                    component.set("v.isValid",false);
                }
            }

            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +  errors[0].message);
                    }
                }
                else{
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },

    validateData: function(component, event, helper){
        var requiredFieldErrorMessage = component.get("v.requiredFieldErrorMessage");
        var selectedValue = component.find("EletterOptions").get("v.value");
        if(selectedValue == undefined || selectedValue == null || selectedValue == ''){
            component.find("EletterOptions").set("v.errors",[{message:requiredFieldErrorMessage}]);
            component.find("eletterName").getElement().scrollIntoView({behavior: "smooth", block: "center"});
            component.set("v.isValid", false);
        }
    },

    getFieldLabels: function (component, event, helper){
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var result = response.getReturnValue();
                component.set("v.fieldLabels", result);
            }
            else if( state === "ERROR"){
                var error = response.getError();
                if(error){
                    if(errors[0] && errors[0].message){
                        console.log("Error message: " +errors[0].message);
                    }
                }
            }
            else{
                console.log("Unkown error");
            }
        })
        $A.enqueueAction(action);
    },

    setEletterOptions: function(component, event, helper, picklistOptions){
        var eletterValue = component.get("v.taskJSON");
        if (eletterValue != undefined && eletterValue != null && eletterValue != '') {
            eletterValue = JSON.parse(eletterValue);
            var eletterOption = eletterValue.eLetterName;
            if (eletterOption !== null && eletterOption !== '') {
                if (picklistOptions.some(eletter => eletter.value === eletterOption)) {
                    component.find("EletterOptions").set("v.value", eletterOption);
                }
                else {
                    var invalidErrorMsg = component.get('v.invalidTemplateMsg');
                    component.find("EletterOptions").set("v.value", '');
                    component.find("EletterOptions").set("v.errors", [{message: invalidErrorMsg.replace('{0}', eletterOption)}]);
                    component.set("v.isValid", false);
                }
            }
        }
    },


    onEletterChange: function(component, event, helper){
        var taskValue = component.find("EletterOptions").get("v.value");
        var languageArray = [];
        var eletterWrapper = component.get("v.eletterWrapper");

        if( taskValue != undefined && taskValue != null && taskValue != ''){
            component.set("v.eletterOptionSelected", true);
            component.set("v.isValid",true);
            component.find("EletterOptions").set("v.errors", null);
            for (var i = 0; i < eletterWrapper.eLettres.length; i++) {
                if(eletterWrapper.eLettres[i].eLetterName == taskValue){
                    component.set("v.taskJSON",JSON.stringify(eletterWrapper.eLettres[i]));
                    //
                    var recipientList           = eletterWrapper.eLettres[i].targetRecepient;
                    var recipientMappingList    = component.get("v.recipentMapping");
                    var recipentMapping         = new Map();
                    for(var j=0; j < recipientMappingList.length; j++){
                        recipentMapping.set(recipientMappingList[j].value, recipientMappingList[j].label);
                    }
                    for(var k=0; k < recipientList.length; k++){
                        recipientList[k].recepient = recipentMapping.get(recipientList[k].recepient);
                    }

                    //
                    component.set("v.recipientList" , recipientList);
                    break;
                }
            }
        }
        else {
            component.set("v.isValid", false);
            component.set("v.recipientList" , []);
            component.set("v.eletterOptionSelected", false);
        }
    },

    compareWithStoredValue: function(component, event, helper){
        var savedEletter        = JSON.parse(component.get("v.taskJSON"));
        var fetchedEletter      = component.get("v.eletterWrapper").eLettres;

        var fetchedEletterRecipient = {};
        var savedEletterRecipient = {};
        for(var i=0; i < fetchedEletter.length; i++){
            if(fetchedEletter[i].eLetterID == savedEletter.eLetterID){
                fetchedEletterRecipient =  fetchedEletter[i].targetRecepient;
                savedEletterRecipient   =  savedEletter.targetRecepient;
                for(var k=0; (k < fetchedEletterRecipient.length); k++){
                    for(var j=0; (j < savedEletterRecipient.length); j++){
                        if(fetchedEletterRecipient[k].recepient == savedEletterRecipient[j].recepient && fetchedEletterRecipient[k].communicationLanguage == savedEletterRecipient[j].communicationLanguage
                            && fetchedEletterRecipient[k].selected != savedEletterRecipient[j].selected){
                                fetchedEletterRecipient[k].selected =  savedEletterRecipient[j].selected;
                        }
                    }
                }
                break;
            }
        }
    },

    setSelected: function(component, event, helper){
        var taskValue = component.find("EletterOptions").get("v.value");
        var languageArray = [];
        var eletterWrapper = component.get("v.eletterWrapper");
        if( taskValue != undefined && taskValue != null && taskValue != ''){
            for (var i = 0; i < eletterWrapper.eLettres.length; i++) {
                if(eletterWrapper.eLettres[i].eLetterName == taskValue){

                    var recipientList           = component.get("v.recipientList");
                    var recipientMappingList    = component.get("v.recipentMapping");
                    var recipentMapping         = new Map();
                    for(var j=0; j < recipientMappingList.length; j++){
                        recipentMapping.set(recipientMappingList[j].label, recipientMappingList[j].value);
                    }
                    for(var k=0; k < recipientList.length; k++){
                        recipientList[k].recepient = recipentMapping.get(recipientList[k].recepient);
                    }

                    eletterWrapper.eLettres[i].targetRecepient = component.get("v.recipientList");
                    component.set("v.taskJSON",JSON.stringify(eletterWrapper.eLettres[i]));
                    break;
                }
            }
        }
    },
})