/**
 * Created by peharitha on 9/30/2019.
 */
({
    doInit : function (component, event, helper) {
        helper.setNamespace(component);
        helper.initializeAttributes(component, event, helper);
    },

    openSearchPage : function (component, event, helper) {
        var namespace = component.get("v.namespace");
        var workspaceAPI = component.find("workspaceId");
        var navService = component.find("navService");
        var pageAPIName = component.get("v.searchPage");
        var identifier = component.get("v.identifier");
        var identifierParam = CH_PC_Util.getQualifiedQueryParam(component,'identifier',namespace);

        var tabParamsObject = new Object();
        tabParamsObject[identifierParam] = identifier;

        CH_PC_Util.openLightningPageInNewTab(navService,workspaceAPI,pageAPIName,tabParamsObject,true,'');
    },
})