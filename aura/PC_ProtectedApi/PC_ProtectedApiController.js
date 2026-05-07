({
    doInit : function(component, event, helper) {
        var action = component.get('c.getApiLabels');
        
        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS' && response.getReturnValue().length != 0) {
                
                component.set("v.apiOptions",response.getReturnValue().apiLabels);
                component.set("v.apiLabelDescription",response.getReturnValue().apiLabDescMap);
                component.set("v.saveToast",response.getReturnValue().saveToast);
                component.set("v.errorMsg",response.getReturnValue().errorMsg);
                component.set("v.formErrorMsg",response.getReturnValue().formErrorMsg);
                component.set("v.toastTitleSuccess",response.getReturnValue().toastTitleSuccess);
                component.set("v.toastTitleError",response.getReturnValue().toastTitleError);
                component.set("v.noSelectedApi",response.getReturnValue().none);
                component.set("v.apiSelectedValue",response.getReturnValue().none);
                component.set("v.apiSettingHelpText",response.getReturnValue().apiHelpText);
                component.set("v.errorSelectedApi",response.getReturnValue().errorSelectedApi);
                component.set("v.addSimilarApiError",response.getReturnValue().addSimilarApiError);
            }
            
        });
        $A.enqueueAction(action);
    },
    submit : function(component, event, helper) {
        var apiSelected = component.get("v.apiSelectedValue");
        var apiInput = component.get("v.apiKeyInput");

        if( apiSelected != component.get("v.noSelectedApi")){
            var action = component.get('c.updateApiKey');
            if(apiInput == 'undefined'){
                apiInput = '';
            }
            action.setParams({
                "selectedApi" : apiSelected,
                "value" : apiInput     
            });
            action.setCallback(this, function(response) {
                if(response.getState() === 'SUCCESS' ) {
                    var saveToastMessage = component.get("v.saveToast");
                    helper.showSuccessToast(component,saveToastMessage,apiInput);
                    component.set("v.apiKeyInput",'');
                    component.set("v.inputCheck",true);
                    var reInit = component.get("c.doInit");
                    $A.enqueueAction(reInit); 
                    
                }
                else{
                    console.log(response.getReturnValue());
                    var message = component.get("v.errorMsg");
                    helper.showErrorToast(component,message);
                }
            });
            $A.enqueueAction(action);
        }
        else{
            var errorSelectedApi = component.get("v.errorSelectedApi");

            helper.showErrorToast(component,errorSelectedApi);
        }
    },
    onChange : function(component, event, helper) {
        if(component.get("v.apiSelectedValue") != component.get("v.noSelectedApi")){
            component.set("v.inputCheck",false);
            helper.setDesc(component, event);
        }
        else{
            component.set("v.inputCheck",true);
            component.set("v.apiKeyInput",'');
            component.set("v.apiPicklistDesc",'');
        }
    },
    addApiKey : function(component, event, helper) {
        var apiSettingKey = component.get("v.apiSettingKey");
        var apiDescription = component.get("v.apiSettingDescription");
        var apiSettingValue = component.get("v.apiSettingValue")

        if(typeof apiSettingKey !== "undefined" && typeof apiSettingValue !== "undefined"){
            var apiLabels = component.get("v.apiOptions");

            var createApi = true;
            for(let i=0;i<apiLabels.length;i++){
                if(apiLabels[i] == apiSettingKey){
                    var message = component.get("v.addSimilarApiError");
                    helper.showErrorToast(component,message);
                    createApi = false;
                }
            }
                if(createApi){
                    var action = component.get('c.createApiSetting');
                    action.setParams({
                        "apiSettingKey" : apiSettingKey,
                        "apiDescription" : apiDescription,
                        "apiSettingValue" : apiSettingValue
                    });
                    action.setCallback(this, function(response) {
                        if(response.getState() === 'SUCCESS' ) {

                                var saveToast = component.get("v.saveToast");
                                helper.showSuccessToast(component,saveToast,apiSettingKey);
                                component.set("v.apiSettingKey",'');
                            	component.set("v.apiSettingValue",'');
                            	component.set("v.apiSettingDescription",'');
                                var reInit = component.get("c.doInit");
                    			$A.enqueueAction(reInit);
                            }
                            else{
                                var errorMsg = component.get("v.errorMsg");
                                helper.showErrorToast(component,errorMsg);
                            }
                        });
                    $A.enqueueAction(action);
                }
            }
        else{
            var formErrorMsg = component.get("v.formErrorMsg");
            helper.showErrorToast(component,formErrorMsg);
        }


    },

})