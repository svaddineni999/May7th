/**
 * Created by havalakki on 6/11/2021.
 */
({
    setNamespace : function(component) {
            var ns = CH_PC_Util.getNamespace(component);
            var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
            component.set("v.namespace", ns);
            component.set("v.namespacePrefix", nsPrefix);
        },

    launchSurvey : function(component,event,helper) {
     var action= component.get("c.generateSurveyLink");
    action.setParams({
        "recordIdValue" : component.get('v.recordId'),
        "engagementProgramId" : component.get('v.engagementProgramId'),
        "surveyContext" : component.get('v.workflowSurveyContext')
    });
     action.setCallback(this, function(response) {

         if (response.getState() == "SUCCESS") {
             var returnValue = response.getReturnValue();

             if(returnValue){
                component.set('v.surveyLink',returnValue);
             }

         } else {
             var errors = [];
             errors.push(component.get('v.surveyInvitationError'));
             component.set("v.errors", errors);
         }
        });
    $A.enqueueAction(action);
    },
    clearErrors : function(component) {
            var errors = [];
            component.set("v.errors", errors);
    },

    getRecordIdAndEngagementProgValues:function(component,event,helper) {
        debugger;
        var sPageURL = decodeURIComponent(window.location.search.substring(1));
        var accountRecordIdParam = component.get('v.namespace')+'__accountId';
        var caseRecordIdParam = component.get('v.namespace')+'__caseId';
        var engagementProgramIdParam = component.get('v.namespace')+'__'+component.get('v.engagementProgramUrlFieldName');
        var workflowSurveyContextAttrName = component.get('v.namespace')+'__workflowSurveyContext';
        var sURLVariables = sPageURL.split('&');
        var sParameterName;
        var i;
        var j;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');

            for(j = 0;j<sParameterName.length;j++){

                if ((sParameterName[j] == accountRecordIdParam)||(sParameterName[j] == caseRecordIdParam)) {
                    component.set("v.recordId", sParameterName[j+1]);
                }
                else if(sParameterName[j] == engagementProgramIdParam){
                    component.set("v.engagementProgramId", sParameterName[j+1]);
                }
                else if(sParameterName[j] == workflowSurveyContextAttrName){
                    component.set("v.workflowSurveyContext", sParameterName[j+1]);
                }
            }
        }
    }
})