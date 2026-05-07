/**
 * Created by havalakki on 5/28/2021.
 */
({
    doInit: function(component,event,helper){
        helper.setNamespace(component);
        debugger;
        var recordIdParam = component.get('v.namespace')+'__Id';
        var accountFieldSetParam = component.get('v.namespace')+'__accountFieldSetAPIName';
        var caseFieldSetParam = component.get('v.namespace')+'__caseFieldsetAPIName';
        var pageRefObj = component.get("v.pageReference");
        component.set("v.recordId", pageRefObj.state[recordIdParam]);
        if(pageRefObj.state[accountFieldSetParam]!=null && pageRefObj.state[accountFieldSetParam]!=''){
            component.set('v.accountFieldSetAPIName',pageRefObj.state[accountFieldSetParam]);
        }
        if(pageRefObj.state[caseFieldSetParam]!=null && pageRefObj.state[caseFieldSetParam]!=''){
            component.set('v.caseFieldsetAPIName',pageRefObj.state[caseFieldSetParam]);
        }

        if(pageRefObj!=null && pageRefObj!='' && pageRefObj!=undefined){
            var workflowNameParam = component.get('v.namespace')+'__name';
            var workflowSurveyContextParam = component.get('v.namespace')+ '__workflowSurveyContext';
            var workflowContext;
            if(pageRefObj.state[workflowNameParam]!=null && pageRefObj.state[workflowNameParam]!='' && pageRefObj.state[workflowNameParam]!=undefined){
                workflowContext = pageRefObj.state[workflowNameParam];
            }else if(pageRefObj.state[workflowSurveyContextParam]!=null && pageRefObj.state[workflowSurveyContextParam]!='' && pageRefObj.state[workflowSurveyContextParam]!=undefined){
                workflowContext = pageRefObj.state[workflowSurveyContextParam];
            }
            component.set('v.workflowSurveyContext',workflowContext);
        }

        if(component.get('v.workflowSurveyContext') == 'PC_PAP'){
            component.set('v.surveyEligibilityCheckLabel',$A.get("$Label.c.PC_PAPTitle")+' '+$A.get("$Label.c.PC_SurveyEligibilityCheck"));
            component.set('v.buttonTitle',$A.get("$Label.c.PC_PAPTitle"));
            component.set('v.surveyLabel',$A.get("$Label.c.PC_PAPTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
            component.set('v.surveyWorkflowDivTitle',$A.get("$Label.c.PC_PAPTitle")+' '+$A.get("$Label.c.PC_SurveyWorkflowTitle"))
        }else if(component.get('v.workflowSurveyContext') == 'PC_Copay'){
            component.set('v.surveyEligibilityCheckLabel',$A.get("$Label.c.PC_CopayTitle")+' '+$A.get("$Label.c.PC_SurveyEligibilityCheck"));
            component.set('v.buttonTitle',$A.get("$Label.c.PC_CopayTitle"));
            component.set('v.surveyLabel',$A.get("$Label.c.PC_CopayTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
            component.set('v.surveyWorkflowDivTitle',$A.get("$Label.c.PC_CopayTitle")+' '+$A.get("$Label.c.PC_SurveyWorkflowTitle"))
        }

        helper.clearErrors(component);
        helper.getAccountAndCaseDetails(component,event,helper);
    },
    
    openPAPEligibilityCheckScreen : function(component,event,helper){
        var action = event.getParam('action');
        if(action.name == component.get('v.accountSurveyActionName')){
            helper.navigateToCmp(component, event, helper);
        }
        else if(action.name == component.get('v.caseSurveyActionName')){
            helper.launchSurvey(component,event,helper);
        }
    }
})