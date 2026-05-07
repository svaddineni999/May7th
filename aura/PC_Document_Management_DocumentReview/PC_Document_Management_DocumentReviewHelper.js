/**
 * Created by sathekumar on 10/07/2021.
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

    setAttributeValues: function(component, event, helper){
        var actionAttribute = component.get("v.actionAttribute");
        if(!$A.util.isEmpty(actionAttribute)){
            var cmpAttribute = JSON.parse(actionAttribute);
            var templateCategories = cmpAttribute.docReviewAttributes['templateCategories'];
            var createDocumentLinkLog = cmpAttribute.docReviewAttributes['createDocumentLinkLog'];
            if(!$A.util.isEmpty(templateCategories)){
                component.set("v.templateCategories", templateCategories);
            }
            if(!$A.util.isEmpty(createDocumentLinkLog)){
                component.set("v.createDocumentLinkLog", createDocumentLinkLog);
            }
        }
    },

    /*
    * It Launches OCR component in the new tab/ console sub-tab
    */
    launchOCR : function(component, event, helper){
        var workspaceAPI = component.find("documentOCRWorkspace");
        var templateCategories = component.get('v.templateCategories');
        var createDocumentLinkLog = component.get('v.createDocumentLinkLog');

        var recordId = component.get('v.recordId');
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.ocrComponentName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var qualifiedTemplateCategoriesName = CH_PC_Util.getQualifiedQueryParam(component,'templateCategories',namespace);
        var qualifiedCreateDocumentLinkLogName = CH_PC_Util.getQualifiedQueryParam(component,'createDocumentLinkLog',namespace);

        var tabParamsObject = new Object();
        tabParamsObject.uid = 'OCR-'+recordId;
        tabParamsObject[qualifiedIdName] = recordId;
        tabParamsObject[qualifiedTemplateCategoriesName] = templateCategories;
        tabParamsObject[qualifiedCreateDocumentLinkLogName] = createDocumentLinkLog;

        var templateCategoriesString = JSON.stringify(templateCategories);
        var urlParams = '?'+qualifiedIdName+'='+recordId+'&'+qualifiedTemplateCategoriesName+'='+templateCategoriesString+'&'+qualifiedCreateDocumentLinkLogName+'='+createDocumentLinkLog;

        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                // this block of code helps to open the component in new console tab if it is console app
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,null,tabParamsObject,
                        component.get("v.ocrTabLabel"),component.get("v.ocrTabIcon"),true,urlParams);
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