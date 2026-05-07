/**************************************************************************************
Apex Class Name     : PC_Test_EntityDefinitionUtility
Description         : This class is used for testing PC_EntityDefinitionUtility;
CreatedBy           : Deloitte
Created Date        : 19 Mar 2020  
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kishore Kanteti          19 Mar 2020            Initial version
*****************************************************************************************/
@isTest
public class PC_Test_EntityDefinitionUtility{
    @isTest static void testGetEntityDefinitionList(){
      List<PC_EntityDefinitionUtility.EntityDefinitionDetailWrapper> definitionList = PC_EntityDefinitionUtility.getEntityDefinitionList(PC_Constants.PC_ACCOUNT,false);
      if (!definitionList.isEmpty()) {
          System.assert(true);
      } else {
          System.assert(false);
      }
  }
}