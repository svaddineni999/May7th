/**
 * Created by havalakki on 10/18/2019.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setProperties : function(component) {
       var orgNamespace = component.get("v.orgNamespace");
       var buttonLabel = CH_PC_Util.replaceOrgNSPlaceholder(orgNamespace, component.get("v.openAEPopUpButtonLabel"));
       var buttonName;
       if(buttonLabel.startsWith("$Label.")){
           buttonName = $A.getReference(buttonLabel);
       }else{
           buttonName = buttonLabel;
       }
       component.set("v.openAEPopUpButtonName", buttonName);
    },
    initializeAttributes :function(component, event, helper){
        var recordId = component.get('v.recordId');
        var action=component.get("c.getAdverseEventConfigData");
        action.setParams({
           selectedRecordId : recordId
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            var returnValue=response.getReturnValue();
            if(state=="SUCCESS" && returnValue != null){
                var actionCenterAEAttributes = new Object();
                actionCenterAEAttributes['additionalInfoTabFieldSet'] = returnValue.fieldsetName;
                if(returnValue.hideAdditionalInfoSection){
                    actionCenterAEAttributes['hideAdditionalInfoTab'] = true;
                }
                actionCenterAEAttributes['dateFormat'] = returnValue.dateFormat;
                component.set("v.dateFormatErrorMessage",returnValue.dateFormatErrorMessage);
                component.set("v.adverseEventMenuCmpAttributes",actionCenterAEAttributes);
                component.set("v.orgNamespace",returnValue.orgNamespace);
                var parentObjectName = returnValue.parentObjectName;
                if(parentObjectName.toUpperCase() =='CASE'){
                   component.set("v.searchActive", false);
                  component.set("v.caseId" ,recordId );
                }
                else if(parentObjectName.toUpperCase() =='ACCOUNT' ){
                   component.set("v.searchActive", false);
                   component.set("v.selectedRecordId" , recordId);
                }
                helper.setAEMenuProperties(component,event,helper);
                helper.setProperties(component);
            }
        });
        $A.enqueueAction(action);
    },
    setAEMenuProperties : function(component,event,helper){
        var actionCenterAEAttributes = component.get("v.adverseEventMenuCmpAttributes");
        if(!actionCenterAEAttributes.hasOwnProperty('hideAdditionalInfoTab')){
            actionCenterAEAttributes['hideAdditionalInfoTab'] = component.get("v.hideAdditionalInfoTab");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('hideCoding')){
            actionCenterAEAttributes['hideCoding'] = component.get("v.hideCoding");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('hideMfr')){
            actionCenterAEAttributes['hideMfr'] = component.get("v.hideMfr");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('hideNotes')){
            actionCenterAEAttributes['hideNotes'] =  component.get("v.hideNotes");
        }
        if(!actionCenterAEAttributes.hasOwnProperty('usePrescriptionForSuspectProducts')){
            if(!$A.util.isEmpty(component.get("v.caseId"))){
                actionCenterAEAttributes['usePrescriptionForSuspectProducts'] =  component.get("v.usePrescriptionForSuspectProducts");
            }else{
                actionCenterAEAttributes['usePrescriptionForSuspectProducts'] = false;
            }
        }
        if(!actionCenterAEAttributes.hasOwnProperty('useRxForMI')){
            if(!$A.util.isEmpty(component.get("v.caseId"))){
                actionCenterAEAttributes['useRxForMI'] =  component.get("v.useRxForMI");
            }else{
                actionCenterAEAttributes['useRxForMI'] = false;
            }
        }
        component.set("v.adverseEventMenuCmpAttributes",actionCenterAEAttributes);
    },
})