/**
 * Created by vkashikar on 6/18/2018.
 */
({
    /**
     * The default validate implementation. This should be overridden by all pages.
     *
     * The validate method is responsible for ensuring all page input is valid and ready for
     * enrollment processing. The method should set the isValid attribute appropriately and
     * should also set the pageErrors attribute, when isValid is set to false to inform the use
     * on how to correct the issues.
     */
    validate : function(component, event, helper) {
        console.log("Calling default validate function in page controller, don't forget to validate user input!");
    }
})