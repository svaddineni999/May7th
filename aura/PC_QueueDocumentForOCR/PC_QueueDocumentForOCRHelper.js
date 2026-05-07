/**
 * Created by sathekumar on 10/19/2021.
 */
({
    doInit : function(component,event,helper){
        this.initializeAttributes(component,event,helper);
        var action = component.get("c.getOcrTemplateOptions");
        action.setParams({
            "supportPlanId"   : component.get("v.supportPlanID")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var result = response.getReturnValue();
                if(!$A.util.isEmpty(result)){
                    var queueObject = component.get("v.queueObject");
                    if(result.isValidTriggerEventObject) {
                        component.set('v.isValidTriggerEventObject', true);
                        component.set('v.isSPBehaviorRunEverytime', result.isSPBehaviorRunEverytime);
                        component.set("v.isValid", true);
                        if($A.util.isEmpty(result.templateTypeSettingList)) {
                            component.set("v.isDisabled",true);
                            var errors =  [];
                            var error = {"message" : component.get("v.noOcrTemplateTypeOptionsError")}
                            errors.push(error);
                            CH_PC_Util.showAllErrors('',errors);
                        } else {
                            queueObject.templateTypeOptions = queueObject.templateTypeOptions.concat(this.createTemplateTypeOptions(result.templateTypeSettingList));
                            if(typeof component.get("v.taskJSON") != 'undefined'){
                                var taskJSON = JSON.parse(component.get("v.taskJSON"));
                                if(typeof taskJSON.templateTypeName != 'undefined'){
                                    var templateTypeNames = [];
                                    for(var i=0; i < queueObject.templateTypeOptions.length; i++){
                                        templateTypeNames.push(queueObject.templateTypeOptions[i].value);
                                    }
                                    if(templateTypeNames.includes(taskJSON.templateTypeName)){
                                        queueObject.selectedTemplateType = taskJSON.templateTypeName;
                                    }
                                    if(taskJSON.notifyOnCompletion){
                                        queueObject.notifyOnCompletion = taskJSON.notifyOnCompletion;
                                    }
                                }
                            }
                        }
                    } else {
                        helper.showSupportError(component,event,helper);
                    }
                }
                component.set("v.queueObject",queueObject);
                helper.setTemplateDescription(component,event,helper);
                helper.setTaskJSON(component,event,helper);
            } else if (state === "ERROR") {
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            } else {
                var unknownErrors = [];
                var error = {"message" : component.get("v.errorStatus")}
                unknownErrors.push(error);
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),unknownErrors);
            }
        });
        $A.enqueueAction(action);
    },

    showSupportError: function(component, event, helper){
        component.set('v.isValidTriggerEventObject', false);
        var supportError = component.find('supportError')
        $A.util.removeClass(supportError,'slds-hide');
        $A.util.addClass(supportError,'slds-show');
    },

    createTemplateTypeOptions : function(templateTypeList){
        return templateTypeList.map(opt => ({ value: opt.apiName, label: opt.label, description: opt.description, createResultsImmediately: opt.createResultsImmediately }));
    },

    setTemplateDescription : function(component, event, helper)
    {
        var selectedTemplateDescription = '';
        var queueObject = component.get("v.queueObject");
        var selectedTemplateTypeObj;
        if(!$A.util.isEmpty(queueObject.selectedTemplateType)) {
            selectedTemplateTypeObj = (queueObject.templateTypeOptions).find(template => template.value === queueObject.selectedTemplateType);
            selectedTemplateDescription = (typeof selectedTemplateTypeObj === 'object' ? (selectedTemplateTypeObj.createResultsImmediately ? component.get('v.createResultImmediatelyMessage') : component.get('v.createResultManuallyMessage')) : '');
        } else {
            selectedTemplateDescription = component.get('v.noneDescription');
            selectedTemplateTypeObj = {};
        }
        component.set('v.selectedTemplateTypeObj', selectedTemplateTypeObj);
        component.set("v.selectedTemplateDescription", selectedTemplateDescription);
    },

    initializeAttributes: function(component,event,helper){
        var newQueueObject = {
            'templateTypeOptions' : [{
                                         'value' : '',
                                         'label': component.get('v.picklistNone'),
                                         'description' : component.get('v.noneDescription'),
                                         'createResultsImmediately': false
                                     }],
            'selectedTemplateType' : '',
            'notifyOnCompletion' : false
        };
        component.set("v.queueObject", newQueueObject);
        component.set("v.isValidTriggerEventObject", false);
    },

    setTaskJSON : function(component,event,helper){
        var queueObject = component.get("v.queueObject");
        var finalJSON = {
            "templateTypeName" : queueObject.selectedTemplateType,
            "notifyOnCompletion" : queueObject.notifyOnCompletion
        }
        if(!$A.util.isEmpty(queueObject.selectedTemplateType)){
            component.set("v.taskJSON",JSON.stringify(finalJSON));
        }else{
            component.set("v.taskJSON",'');
        }
        console.log('taskJSON'+component.get("v.taskJSON"));
    },

    handleTemplateChange : function(component,event,helper) {
        helper.resetNotifyCheckbox(component,event,helper);
        var selectedTemplate = event.getSource().get("v.value");
        console.log('selectedTemplate--'+selectedTemplate);
        this.setTemplateDescription(component,event,helper);
        //component.set("v.queueObject",queueObject);
        helper.setTaskJSON(component,event,helper);
    },

    handleNotifyCheckboxChange: function(component,event,helper) {
        helper.setTaskJSON(component,event,helper);
    },

    resetNotifyCheckbox : function(component,event,helper) {
        var queueObject = component.get("v.queueObject");
        queueObject.notifyOnCompletion = false;
        component.set("v.queueObject", queueObject);
    },

    validateData : function(component,event,helper){
        var isValid = true;
        /*var queueObject = component.get("v.queueObject");
        if($A.util.isEmpty(queueObject.selectedTemplateType)){
            isValid = false;
        }*/
        if(! component.get('v.isValidTriggerEventObject')){
            if(!$A.util.isEmpty(component.find("supportError"))){
                component.find("supportError").getElement().scrollIntoView({behavior: "smooth",block: "center"});
            }
            isValid = false;
        }
        component.set("v.isValid", isValid);
    }
})