/**
 * Created by peharitha on 4/2/2019.
 */
({
    doInit: function(component, event, helper){
        helper.fetchProgramCoverageList(component, event, helper);
    },
    navigateToRecord : function(component , event, helper){
        var recId = event.currentTarget.id;
        var workspaceAPI = component.find("workspace");
        CH_PC_Util.openRecordInNewTab(workspaceAPI,recId);
    },
})