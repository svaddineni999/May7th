@isTest
public class PC_Test_Constants {
    @isTest public static void testTheConstants() {
        Test.StartTest();
        //PC_Constants pcc = new PC_Constants();	//Not Used
        System.assert(PC_Constants.TIME_ZONE == 'America/New_York', 'Timezone Failed');
        //Test Namespace
        String ns = PC_Constants.OrgNamespace;
        System.assert(ns != null);
        String objApiName = PC_Constants.getQualifiedAPIName('testName');
        System.assert(objApiName != null);
        Test.StopTest();
    }
}