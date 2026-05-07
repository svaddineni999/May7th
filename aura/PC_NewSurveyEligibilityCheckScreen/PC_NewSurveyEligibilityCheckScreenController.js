/**
 * Created by havalakki on 6/3/2021.
 */
({
    doInit: function(component,event,helper){
        helper.setNamespace(component);
        var pageRefObj = component.get("v.pageReference");

        if(pageRefObj !=null && pageRefObj !='' && pageRefObj!=undefined){

            if(component.get('v.recordId')==undefined || component.get('v.recordId')==''){
                var recordIdParam = component.get('v.namespace')+'__Id';
                component.set("v.recordId", pageRefObj.state[recordIdParam]);
            }

            var workflowNameParam = component.get('v.namespace')+'__workflowSurveyContext';
            var workflowContext = pageRefObj.state[workflowNameParam];
            component.set('v.workflowSurveyContext',workflowContext);

        }

        if(component.get('v.workflowSurveyContext') == 'PC_PAP'){
            component.set('v.surveyLabel',$A.get("$Label.c.PC_PAPTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
        }else if(component.get('v.workflowSurveyContext') == 'PC_Copay'){
            component.set('v.surveyLabel',$A.get("$Label.c.PC_CopayTitle")+' '+$A.get("$Label.c.PC_SurveyLabel"));
        }

        if(!$A.util.isUndefinedOrNull(component.get("v.namespace")) && !$A.util.isEmpty(component.get("v.namespace") &&
            component.get("v.namespace")!='c')){
            component.set("v.qualifiedEngagementProgramFieldAPIName",component.get("v.namespace")+'__'+component.get('v.engagementProgramFieldName'));
        }
        else{
            component.set("v.qualifiedEngagementProgramFieldAPIName",component.get('v.engagementProgramFieldName'));
        }
        
        helper.clearErrors(component);
        helper.getAccountCaseDetails(component,event,helper);
    },

     openSurveyInvitationPage:function(component,event,helper){
           var engagementProgramFieldValue = component.find('engagementProgAuraId').get('v.value');
           var accountIdValue = component.find('accountAuraId').get('v.value');

           var engProgramFieldValueisEmpty =false;
           var accountFieldValueisEmpty =false;
           var engProgIdDiv;

           if(engagementProgramFieldValue ==undefined || engagementProgramFieldValue ==null|| engagementProgramFieldValue==''){
                engProgIdDiv = component.find("invalidEngProgId");
                $A.util.removeClass(engProgIdDiv, "slds-hide");
                engProgramFieldValueisEmpty =true;
           }

           if(accountIdValue ==undefined || accountIdValue ==null|| accountIdValue ==''){
                var invalidAccountIdDiv = component.find("invalidAccountId");
                $A.util.removeClass(invalidAccountIdDiv, "slds-hide");
                accountFieldValueisEmpty=true;
           }

           if(!engProgramFieldValueisEmpty && !accountFieldValueisEmpty){
               engProgIdDiv = component.find("invalidEngProgId");
               $A.util.addClass(engProgIdDiv, "slds-hide");
               var accountIdDiv = component.find("invalidAccountId");
               $A.util.addClass(accountIdDiv, "slds-hide");

               helper.navigateToSurveyInvitationPage(component,event,helper);
           }
     },

     validateFieldValues :function(component,event,helper){
        var engagementProgramFieldValue = component.find('engagementProgAuraId').get('v.value');
        var accountIdValue = component.find('accountAuraId').get('v.value');

        if(engagementProgramFieldValue!=undefined && engagementProgramFieldValue !=null && engagementProgramFieldValue!=''){
           var engProgIdDiv = component.find("invalidEngProgId");
           $A.util.addClass(engProgIdDiv, "slds-hide");
       }
       if(accountIdValue!=undefined && accountIdValue !=null && accountIdValue!=''){
          var accountIdDiv = component.find("invalidAccountId");
          $A.util.addClass(accountIdDiv, "slds-hide");
       }
     }
})