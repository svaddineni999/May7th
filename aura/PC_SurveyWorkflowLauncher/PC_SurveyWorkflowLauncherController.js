/**
 * Created by havalakki on 6/11/2021.
 */
({
    doInit: function(component,event,helper){
        helper.setNamespace(component);
        component.set('v.workflowButtonLabelValue',CH_PC_Util.getCustomLabelValue(component.get('v.workflowButtonLabel')));

        if(component.get('v.workflowSurveyContext') == 'PC_PAP'){
            component.set('v.surveyEligibilityCheckLabel',$A.get("$Label.c.PC_PAPTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
        }else if(component.get('v.workflowSurveyContext') == 'PC_Copay'){
            component.set('v.surveyEligibilityCheckLabel',$A.get("$Label.c.PC_CopayTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
        }
    },

    openSurveyInvitationPage:function(component,event,helper){
          debugger;
          helper.checkIfRecordIdAccountOrCase(component,event,helper);
    },

    enableSurveyWorkflowButton: function(component,event,helper){

        if((event.getParam('selectedRecordId')!=null &&
        event.getParam('selectedRecordId')!='' &&
        event.getParam('selectedRecordId')!=undefined) &&
            component.get('v.searchObjectAPIName')=='Account'){
                component.set('v.recordId',event.getParam('selectedRecordId'));
            }else{
                component.set('v.recordId',null);
            }
    },
    handleSearchParams : function(component, event, helper) {
        debugger;
        if(event.getParam('searchObjectAPIName')!=null &&
                event.getParam('searchObjectAPIName')!='' &&
                event.getParam('searchObjectAPIName')!=undefined){
        component.set('v.searchObjectAPIName',event.getParam('searchObjectAPIName'));
        component.set('v.recordId',null);
       }
    }

})