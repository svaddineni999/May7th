/**
 * Created by sathekumar on 11/19/2020.
 */
({
    /*
    * This method helps to set the namespace
    */
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    /*
    * gets and sets the attributes values from actionAttribute JSON
    */
    setAttributeValues: function(component, event, helper){
        var actionAttribute = component.get("v.actionAttribute");
        if(!$A.util.isEmpty(actionAttribute)){
            var cmpAttribute = JSON.parse(actionAttribute);
            var eletterContext = cmpAttribute.eLetterAttributes['eletterContext'];
            var showPreviewScreen = cmpAttribute.eLetterAttributes['showPreviewScreen'];
            var showSendSecureOption = cmpAttribute.eLetterAttributes['showSendSecureOption'];
            var showAttachments = cmpAttribute.eLetterAttributes['showAttachments'];
            var moreEmailRecipients = cmpAttribute.eLetterAttributes['moreEmailRecipients'];
            if(!$A.util.isEmpty(eletterContext)){
                component.set("v.eletterContext", eletterContext);
            }
            if(!$A.util.isEmpty(showPreviewScreen)){
                component.set("v.showPreviewScreen", showPreviewScreen);
            }
            if(!$A.util.isEmpty(showAttachments)){
                component.set("v.showAttachments", showAttachments);
            }
            if(!$A.util.isEmpty(showSendSecureOption)){
                component.set("v.showSendSecureOption", showSendSecureOption);
            }
            if(!$A.util.isEmpty(moreEmailRecipients)){
                component.set("v.moreEmailRecipients", moreEmailRecipients);
            }
        }
    },

    /*
    * It Launches eletter component in the new tab/ console sub-tab
    */
    launchEletter : function(component, event, helper){
        var workspaceAPI = component.find("documentEletterReplyWorkspace");
        var showAttachments = component.get('v.showAttachments');
        var showPreviewScreen = component.get('v.showPreviewScreen');
        var showSendSecureOption = component.get('v.showSendSecureOption');
        var eletterContext = component.get('v.eletterContext');
        var moreEmailRecipients = component.get('v.moreEmailRecipients');

        var recordId = component.get('v.recordId');
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.eletterComponentName");
        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.eletterPageName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var qualifiedShowAttachmentsName = CH_PC_Util.getQualifiedQueryParam(component,'showAttachments',namespace);
        var qualifiedShowPreviewScreenName = CH_PC_Util.getQualifiedQueryParam(component,'showPreviewScreen',namespace);
        var qualifiedShowSendSecureOptionName = CH_PC_Util.getQualifiedQueryParam(component,'showSendSecureOption',namespace);
        var qualifiedEletterContextName = CH_PC_Util.getQualifiedQueryParam(component,'eletterContext',namespace);
        var qualifiedMoreEmailRecipientsName = CH_PC_Util.getQualifiedQueryParam(component,'moreEmailRecipients',namespace);

        var tabParamsObject = new Object();
        tabParamsObject.uid = 'EL-'+recordId;
        tabParamsObject[qualifiedIdName] = recordId;
        tabParamsObject[qualifiedShowAttachmentsName] = showAttachments;
        tabParamsObject[qualifiedShowPreviewScreenName] = showPreviewScreen;
        tabParamsObject[qualifiedShowSendSecureOptionName] = showSendSecureOption;
        tabParamsObject[qualifiedEletterContextName] = eletterContext;
        tabParamsObject[qualifiedMoreEmailRecipientsName] = moreEmailRecipients;

        var urlParams = '?'+qualifiedIdName+'='+recordId+'&'+qualifiedShowAttachmentsName+'='+showAttachments+'&'+qualifiedShowPreviewScreenName+'='+showPreviewScreen+'&'+qualifiedShowSendSecureOptionName+'='+showSendSecureOption+'&'+qualifiedEletterContextName+'='+eletterContext+'&'+qualifiedMoreEmailRecipientsName+'='+moreEmailRecipients;

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