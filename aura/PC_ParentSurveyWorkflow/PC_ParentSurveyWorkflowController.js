/**
 * Created by havalakki on 6/4/2021.
 */
({
     doInit: function(component,event,helper){
        helper.setNamespace(component);
        debugger;
        if(component.get("v.pageReference") != null && (component.get('v.recordId')==null || component.get('v.recordId')==undefined || component.get('v.recordId')=='')){
            var recordIdParam = component.get('v.namespace')+'__Id';
            var pageRefObj = component.get("v.pageReference");
            component.set("v.recordId", pageRefObj.state[recordIdParam]);
        }
        if(pageRefObj!=null && pageRefObj!='' && pageRefObj!=undefined){
            var workflowNameParam = component.get('v.namespace')+'__workflowSurveyContext';
            var workflowContext = pageRefObj.state[workflowNameParam];
            component.set('v.workflowSurveyContext',workflowContext);
        }

        if(component.get('v.workflowSurveyContext') == 'PC_PAP'){
            component.set('v.surveyLabel',$A.get("$Label.c.PC_PAPTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
        }else if(component.get('v.workflowSurveyContext') == 'PC_Copay'){
            component.set('v.surveyLabel',$A.get("$Label.c.PC_CopayTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
        }

        helper.clearErrors(component);
        helper.getAccountCaseDetails(component,event,helper);
        }

})