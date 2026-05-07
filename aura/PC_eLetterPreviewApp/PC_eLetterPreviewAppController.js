/**
 * Created by havalakki on 4/15/2019.
 */
({
    doInit: function(component,event,helper){

        document.title=component.get("v.eLetterPreviewTitle");

        var componentName= component.get("v.dynamicPreviewCmpName");
                $A.createComponent(componentName,
                {
                    "eLetterId" : component.get("v.eLetterId"),
                    "recordId"  : component.get("v.recordId")
                },
                function(newComponent, status, errorMessage){
                    if(status=='SUCCESS'){
                        var dynamicPreviewComponentBody=component.get('v.dynamicPreviewComponent');
                        dynamicPreviewComponentBody.push(newComponent);
                        component.set('v.dynamicPreviewComponent',dynamicPreviewComponentBody);
                    }
                });
    }
})