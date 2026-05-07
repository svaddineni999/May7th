/**
 * Created by kkanteti on 4/29/2021.
 */
({
    doInit : function(component,event,helper){
        var newQueueObject = {
            'channelOptions' : [],
            'selectedChannel' : '',
            'allChannelSettings' : new Map(),
            'selectedSetting' : '',
            'relatedChannelSettings' : '',
            'showNoSettingOptionsError': false,
            'criteriaOptions' : [],
            'selectedCriteria': ''
        };
        component.set("v.queueObject",newQueueObject);
        var action = component.get("c.getReminderOptions");
        action.setParams({
            "supportPlanId"   : component.get("v.supportPlanID")
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if('SUCCESS'== state){
                var result = response.getReturnValue();
                if(!$A.util.isEmpty(result)){
                    var queueObject = component.get("v.queueObject");
                    if($A.util.isEmpty(result.channelSettingsMap)){
                        component.set("v.isDisabled",true);
                        var errors =  [];
                        var error = {"message" : component.get("v.noSettingOptionsError")}
                        errors.push(error);
                        CH_PC_Util.showAllErrors('',errors);
                    }else{
                        queueObject.channelOptions = result.channelOptions;
                        queueObject.allChannelSettings = result.channelSettingsMap;
                        queueObject.criteriaOptions = result.criteriaOptions;
                        if(typeof component.get("v.taskJSON") != 'undefined'){
                            var taskJSON = JSON.parse(component.get("v.taskJSON"));
                            if(typeof taskJSON.reminderChannel == 'undefined'){
                                queueObject.selectedChannel = result.channelOptions[0];
                                queueObject.selectedCriteria = result.criteriaOptions[0].value;
                                helper.setRelatedChannelSettings(component,event,helper,queueObject.selectedChannel);
                            }else{
                                queueObject.selectedChannel = taskJSON.reminderChannel;
                                queueObject.selectedCriteria = taskJSON.handleExistingQueueCriteria;
                                queueObject.relatedChannelSettings = queueObject.allChannelSettings[queueObject.selectedChannel]
                                var channelSettingsList = [];
                                for(var i=0; i < queueObject.relatedChannelSettings.length; i++){
                                    channelSettingsList.push(queueObject.relatedChannelSettings[i].apiName);
                                }
                                if(channelSettingsList.includes(taskJSON.reminderSettingName)){
                                    queueObject.selectedSetting = taskJSON.reminderSettingName;
                                }else{
                                    queueObject.selectedSetting = queueObject.relatedChannelSettings[0].apiName;
                                }
                            }
                        }else{
                            queueObject.selectedChannel = result.channelOptions[0];
                            queueObject.selectedCriteria = result.criteriaOptions[0].value;
                            helper.setRelatedChannelSettings(component,event,helper,queueObject.selectedChannel);
                        }
                    }
                    component.set("v.queueObject",queueObject);
                    helper.setTaskJSON(component,event,helper,queueObject);
                }
            }else if (state === "ERROR") {
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else{
                var unknownErrors = [];
                var error = {"message" : component.get("v.errorStatus")}
                unknownErrors.push(error);
                CH_PC_Util.showAllErrors(component.get("v.toastErrorTitle"),unknownErrors);
            }
        });
        $A.enqueueAction(action);
    },
    onChannelChange: function(component,event,helper){
        var selectedChannel = event.getSource().get("v.value");
        helper.setRelatedChannelSettings(component,event,helper,selectedChannel);
    },
    onCriteriaChange: function(component,event,helper){
        var selectedCriteria = event.getSource().get("v.value");
        var queueObject = component.get("v.queueObject");
        queueObject.selectedCriteria = selectedCriteria;
        component.set("v.queueObject",queueObject);
        helper.setTaskJSON(component,event,helper,queueObject);
    },
    onReminderSettingChange: function(component,event,helper){
        var selectedSetting = event.getSource().get("v.value");
        var queueObject = component.get("v.queueObject");
        queueObject.selectedSetting = selectedSetting;
        component.set("v.queueObject",queueObject);
        helper.setTaskJSON(component,event,helper,queueObject);
    },
    setRelatedChannelSettings : function(component,event,helper,selectedChannel){
        var queueObject = component.get("v.queueObject");
        var relatedChannelSettings = [];
        var allChannelSettingsMap = queueObject.allChannelSettings;
        if(selectedChannel != '' && allChannelSettingsMap.hasOwnProperty(selectedChannel)){
            relatedChannelSettings = allChannelSettingsMap[selectedChannel];
        }
        if($A.util.isEmpty(relatedChannelSettings)){
            queueObject.showNoSettingOptionsError = true;
            queueObject.selectedSetting = '';
            queueObject.relatedChannelSettings = [];
        }else{
            queueObject.relatedChannelSettings = relatedChannelSettings;
            queueObject.selectedSetting = relatedChannelSettings[0].apiName;
            queueObject.showNoSettingOptionsError = false;
        }
        component.set("v.queueObject",queueObject);
        helper.setTaskJSON(component,event,helper,queueObject);
    },
    setTaskJSON : function(component,event,helper,queueObject){
        var finalJSON = {
            "reminderChannel" : queueObject.selectedChannel,
            "reminderSettingName" : queueObject.selectedSetting,
            "handleExistingQueueCriteria" : queueObject.selectedCriteria,
            "sendToAllRecipients" : true
        }
        if(queueObject.selectedChannel != '' && queueObject.selectedSetting != ''){
            component.set("v.taskJSON",JSON.stringify(finalJSON));
        }else{
            component.set("v.taskJSON",'');
        }
        helper.setSettingDescription(component,event,helper,queueObject);
    },
    setSettingDescription : function(component,event,helper,queueObject){
        var relatedChannelSettings = queueObject.relatedChannelSettings;
        for(var j=0; j<relatedChannelSettings.length; j++){
            if(relatedChannelSettings[j].apiName == queueObject.selectedSetting){
                component.set("v.settingDescription",relatedChannelSettings[j].description);
            }
        }
    },
    validateData : function(component,event,helper){
        var isValid = true;
        var queueObject = component.get("v.queueObject");
        if(queueObject.selectedSetting == '' || queueObject.selectedChannel == ''){
            isValid = false;
        }
        component.set("v.isValid",isValid);
    }
})