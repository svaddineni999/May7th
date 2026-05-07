/**
 * Created by peharitha on 10/21/2019.
 */
({
    itemSelected : function(component, event, helper) {
        var target = event.target;
        var SelIndex = helper.getIndexFrmParent(target,helper,"data-selectedIndex");
        if(SelIndex){
            var serverResult = component.get("v.server_result");
            var selectedRecord = serverResult[SelIndex];
            if(selectedRecord.val){
               component.set("v.selectedRecord",selectedRecord);
               component.set("v.last_ServerResult",serverResult);
            }
            component.set("v.server_result",null);
        }
    },
    serverCall : function(component, event, helper) {
        var target = event.target;
        var searchText = target.value;
        var last_SearchText = component.get("v.last_SearchText");
        //Escape button pressed
        if (event.keyCode == 27 || !searchText.trim()) {
            helper.clearSelection(component, event, helper);
        }else if(searchText.trim() != last_SearchText ){
            //Save server call, if last text not changed
            var objectName = component.get("v.objectName");
            var field_API_text = component.get("v.field_API_text");
            var field_API_val = component.get("v.field_API_val");
            var field_API_search = component.get("v.field_API_search");
            var limit = component.get("v.limit");

            var action = component.get('c.searchDB');
            action.setStorable();

            action.setParams({
                objectName : objectName,
                fld_API_Text : field_API_text,
                fld_API_Val : field_API_val,
                lim : limit,
                fld_API_Search : field_API_search,
                searchText : searchText
            });

            action.setCallback(this,function(a){
                this.handleResponse(a,component,helper);
            });
            component.set("v.last_SearchText",searchText.trim());
            $A.enqueueAction(action);

        }else if(searchText && last_SearchText && searchText.trim() == last_SearchText.trim()){
            component.set("v.server_result",component.get("v.last_ServerResult"));
        }
    },
    handleResponse : function (res,component,helper){
        if (res.getState() === 'SUCCESS') {
            var retObj = JSON.parse(res.getReturnValue());
            if(retObj.length <= 0){
                var noResult = JSON.parse('[{"text":"No Results Found"}]');
                component.set("v.server_result",noResult);
                component.set("v.last_ServerResult",noResult);
            }else{
                component.set("v.server_result",retObj);
                component.set("v.last_ServerResult",retObj);
            }
        }else if (res.getState() === 'ERROR'){
            var errors = res.getError();
            helper.handleErrors(component, errors);
        }
    },
    getIndexFrmParent : function(target,helper,attributeToFind){
        //User can click on any child element, so traverse till intended parent found
        var SelIndex = target.getAttribute(attributeToFind);
        while(!SelIndex){
            target = target.parentNode ;
            SelIndex = helper.getIndexFrmParent(target,helper,attributeToFind);
        }
        return SelIndex;
    },
    clearSelection: function(component, event, helper){
        component.set("v.selectedRecord",null);
        component.set("v.server_result",null);
    },
    handleErrors : function(component, errors) {
        let toastParams = {
            title: "Error",
            message: 'Unknown Error', // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
})