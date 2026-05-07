/**
 * Created by sathekumar on 8/3/2020.
 */
({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    
    launchEletter : function(component, event, helper){
        var workspaceAPI = component.find("eletterLauncherWorkspace");
        var showAttachments = component.get('v.showAttachmentSection');
        var showPreviewScreen = component.get('v.showPreviewScreen');
        var showSendSecureOption = component.get('v.showSendSecureOption');
        var closeTabAfterSend = component.get('v.closeTabAfterSend');
        var enableEmailWorkflow = component.get('v.emailWorkflow');
        var enableFaxWorkflow = component.get('v.faxWorkflow');
        var eletterContext = component.get('v.eletterContext');
        var moreEmailRecipients = component.get('v.moreEmailRecipients');
        var hideConsent = component.get('v.hideConsent');

        var recordId = component.get('v.recordId');
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.eletterComponentName");
        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.eletterPageName");
        
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var qualifiedShowAttachmentsName = CH_PC_Util.getQualifiedQueryParam(component,'showAttachments',namespace);
        var qualifiedShowPreviewScreenName = CH_PC_Util.getQualifiedQueryParam(component,'showPreviewScreen',namespace);
        var qualifiedShowSendSecureOptionName = CH_PC_Util.getQualifiedQueryParam(component,'showSendSecureOption',namespace);
        var qualifiedOpenInNewTabName = CH_PC_Util.getQualifiedQueryParam(component,'openInNewTab',namespace);
        var qualifiedCloseTabAfterSendName = CH_PC_Util.getQualifiedQueryParam(component,'closeTabAfterSend',namespace);
        var qualifiedEnableEmailWorkflowName = CH_PC_Util.getQualifiedQueryParam(component,'emailWorkflow',namespace);
        var qualifiedEnableFaxWorkflowName = CH_PC_Util.getQualifiedQueryParam(component,'faxWorkflow',namespace);
        var qualifiedEletterContextName = CH_PC_Util.getQualifiedQueryParam(component,'eletterContext',namespace);
        var qualifiedMoreEmailRecipientsName = CH_PC_Util.getQualifiedQueryParam(component,'moreEmailRecipients',namespace);
        var qualifiedHideConsentName = CH_PC_Util.getQualifiedQueryParam(component,'hideConsent',namespace);

        var tabParamsObject = new Object();
        tabParamsObject.uid = 'BEL-'+recordId;
        tabParamsObject[qualifiedIdName] = recordId;
        tabParamsObject[qualifiedShowAttachmentsName] = showAttachments;
        tabParamsObject[qualifiedShowPreviewScreenName] = showPreviewScreen;
        tabParamsObject[qualifiedShowSendSecureOptionName] = showSendSecureOption;
        tabParamsObject[qualifiedOpenInNewTabName] = false;
        tabParamsObject[qualifiedCloseTabAfterSendName] = closeTabAfterSend;
        tabParamsObject[qualifiedEnableEmailWorkflowName] = enableEmailWorkflow;
        tabParamsObject[qualifiedEnableFaxWorkflowName] = enableFaxWorkflow;
        tabParamsObject[qualifiedEletterContextName] = eletterContext;
        tabParamsObject[qualifiedMoreEmailRecipientsName] = moreEmailRecipients;
        tabParamsObject[qualifiedHideConsentName] = hideConsent;

        var urlParams = '?'+qualifiedIdName+'='+recordId+'&'+qualifiedShowAttachmentsName+'='+showAttachments+'&'+qualifiedShowPreviewScreenName+'='+showPreviewScreen+'&'+qualifiedShowSendSecureOptionName+'='+showSendSecureOption+'&'+qualifiedOpenInNewTabName+'=false&'+qualifiedCloseTabAfterSendName+'='+closeTabAfterSend+'&'+qualifiedEnableEmailWorkflowName+'='+enableEmailWorkflow+'&'+qualifiedEnableFaxWorkflowName+'='+enableFaxWorkflow+'&'+qualifiedEletterContextName+'='+eletterContext+'&'+qualifiedMoreEmailRecipientsName+'='+moreEmailRecipients+'&'+qualifiedHideConsentName+'='+hideConsent;
        
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                // this block of code helps to open the component in new console tab if it is console app
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,
                                                          component.get("v.eletterTabLabel"),component.get("v.eletterTabIcon"),true,urlParams);
            } else {
                // this block of code helps to open the component in new tab if it is lightning app
                var url = '/lightning/cmp/' + componentAPIName + urlParams;
                window.open(url,"_blank");
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})