/*********************************************************************************************************
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Unknown             		   May 17, 2016           Initial Version
Shabda Bhujad,                 Nov 30, 2016			  Added method chkAccess, assertAccess, queryWithAccess, checkOperation, findFields
Prachi Nandgaonkar	                                  Modified ins, upd, ups, del and added multiple overridable methods
Shabda Bhujad				   Dec 05, 2016			  Changed Set to List added a 3 new signatures to the ins method to include glag for FLS
Prachi Nandgaonkar             Dec 12, 2015           Modified checkOperation() to avoid "null pointer" exception
Tejas Patel					   Apr 12, 2017			  Addition of new function call for upd, with sObject and boolean checkFls variable.
Prachi Nandgaonkar             July 25, 2017          [PC-1967] Added custom exception NoDatabaseAccessException inner class
Shabda Bhujad                  Jan 11, 2018           PC-2671 Added logic to skip FLS for Salesforce to Salesforce Connection User
Mike Klumpenaar                Mar 3, 2019            [PC-4475] Make class and subset of methods global and convert to apex doc.
Tushar Arora                   feb 25,2020            [PC-6019]Updating the Salesforce Api Version to 48.0 of PC_Database Class.
Vijay Kashikar                 21-Jan-21              [PC-7102] Added sharing clause
Tushar Arora                   04-Mar-21              [PC-7166] Added Logic in queryWithAccess method where the access check is not being done by the utility methods.
****************************************************************************************************************/

/**
 * PC_Database is a global utility class to support database CRUD actions that support CRUD and FLS access checking.
 *
 * @date 2016-05-17
 *
 */
global inherited sharing class PC_Database {

    //Added to streamline the operations 
    global enum Operation {
        Creating, Reading, Updating, Deleting
    }

    /**
     * Performs FLS and CRUD access checks for a list of objects. Currently only used by
     * PC_Test_Database.
     *
     * @param sObjects      The list of objects to perform the access checks on
     * @param operation     The CRUD operation to check access for
     * @param fieldNames    The list of fields to check if this is a Read or Write operation
     */
    public static void assertAccess(List<sObject> sObjects, Operation operation, List<String> fieldNames) {
        checkOperation(sObjects, operation, fieldNames);
    }
    /**
     * Performs FLS and CRUD access checks for the calling user on the given
     * object for a specific operation and list of fields.
     *
     * @param objectName    The name of the object type to perform the access checks on.
     * @param operation     The CRUD operation to check access for
     * @param fieldNames    The list of fields to check if this is a Read or Write operation
     */
    global static void assertAccess(String objectName, Operation operation, List<String> fieldNames) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        sObject obj = gd.get(objectName).newSObject();
        List<sObject> pObjs = new List<sObject>();
        pObjs.add(obj);
        checkOperation(pObjs, operation, fieldNames);
    }

    /**
     * Performs a SOQL query and also confirms that the user has Read access to
     * all of the provided fields. All of the fields need to be defined on the selected
     * object. This method cannot be used to check access on fields in related objects
     * selected in the query.
     *
     * @param SOQL          The query to run
     * @param fieldNames    The fields to check Read access on
     *
     * @return  The objects from the query. A PC_Database.NoDatabaseAccessException is thrown
     *          if the user does not have Read access on the object or any of the fields.
     */
    global static List<sObject> queryWithAccess(String SOQL, List<String> fieldNames) {
        List<sObject> dbRecords = Database.query(SOQL);

        if (dbRecords.size() > 0) {
            checkOperation(dbRecords, Operation.Reading, fieldNames);
        }

        return dbRecords;
    }

    /**
     * Performs a SOQL query and conditionally confirms that the user has Read access to
     * all of the provided fields. All of the fields need to be defined on the selected
     * object. This method cannot be used to check access on fields in related objects
     * selected in the query.
     *
     * @param SOQL          The query to run
     * @param fieldNames    The fields to check Read access on
     * @param checkAccess   Determines if Read access is enforced or not
     *
     * @return  The objects from the query. A PC_Database.NoDatabaseAccessException is thrown
     *          if the user does not have Read access on the object or any of the fields.
     */
    private static List<sObject> queryWithAccess(String SOQL, List<String> fieldNames, Boolean checkAccess) {
        if (checkAccess) {
            return queryWithAccess(SOQL, fieldNames);
        } else {
            return Database.query(SOQL);
        }
    }

    /**
     * Performs a SOQL query and conditionally confirms that the user has Read access to
     * the object being selected.
     *
     * @param SOQL          The query to run
     * @param checkAccess   Determines if Read access is enforced or not
     *
     * @return  The objects from the query. A PC_Database.NoDatabaseAccessException is thrown
     *          if the user does not have Read access on the object.
     */
    global static List<sObject> queryWithAccess(String SOQL, Boolean checkAccess) {
        List<sObject> dbRecords = new List<sObject>();
        if (String.isNotBlank(SOQL)) {
            dbRecords = Database.query(SOQL);
        }
        if (checkAccess) {
            if (dbRecords.size() > 0) {
                checkOperation(dbRecords, Operation.Reading);
            }
        }
        return dbRecords;
    }

    /*--------------------------- INSERT METHODS ------------------------------------*/

    /**
     * Performs a bulk insert of a list of objects and conditionally ensures that the current user
     * has Insert permission and Write access on all populated fields.
     *
     * @param pObjs     The list of objects to insert
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Write access is enforced or not
     *
     * @return The list of objects that was provided.
     */
    private static List<sObject> ins(List<sObject> pObjs, List<sObjectField> pFields, boolean checkFls) {
        if (pObjs != NULL && !pObjs.isEmpty()) {
            if (checkFls) {
                checkOperation(pObjs, Operation.Creating);
            }

            insert pObjs;
        }

        return pObjs;
    }

    /**
     * Performs a bulk insert of a list of objects and conditionally ensures that the current user
     * has Insert permission and Write access on the given fields.
     * The insert is performed with best effort semantics and will not fail
     * if an individual record fails to insert.
     *
     * @param pObjs     The list of objects to insert
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Write access is enforced or not
     *
     * @return The list of results for each object which can be used to determine if any of the inserts failed.
     */
    private static List<Database.SaveResult> insWithBestEffort(List<sObject> pObjs, List<sObjectField> pFields, boolean checkFls){
        if (checkFls) {
            system.assertNotEquals(null,pObjs);
            if(pObjs.size() == 0){
                return null;
            }
            checkOperation(pObjs, Operation.Creating);
        }
        //insert pObjs;
        List<Database.SaveResult> saveResults = Database.insert(pObjs, false);
        return saveResults;
    }

    /**
     * Performs a bulk insert of a list of objects and ensures that the current user
     * has Insert permission and Write access on the populated fields
     *
     * @param pObjs     The list of objects to insert
     * @param pFields   List of fields that is ignored
     *
     * @return The list of objects that was provided.
     */
    private static List<sObject> ins(List<sObject> pObjs, List<sObjectField> pFields) {
        return ins(pObjs, pFields, true);
    }

    /**
     * Performs a bulk insert of a list of objects and ensures that the current user
     * has Insert permission and Write access on the populated fields.
     *
     * @param pObjs     The list of objects to insert
     *
     * @return The list of objects that was provided.
     */
    global static List<sObject> ins(List<sObject> pObjs) {
        return ins(pObjs, new List<sObjectField>(), true);
    }

    /**
     * Performs a bulk insert of a list of objects and ensures that the current user
     * has Insert permission and Write access on the populated fields.
     * The insert is performed with best effort semantics and will not fail
     * if an individual record fails to insert.
     *
     * @param pObjs     The list of objects to insert
     *
     * @return The list of results for each object which can be used to determine if any of the inserts failed.
     */
    global static List<Database.SaveResult> insWithBestEffort(List<sObject> pObjs){
        return insWithBestEffort (pObjs, new List<sObjectField>(), true);
    }

    /**
     * Performs a bulk insert of a list of objects and conditionally ensures that the current user
     * has Insert permission and Write access on the populated fields.
     *
     * @param pObjs     The list of objects to insert
     * @param checkFls  Determines if Write access is enforced or not
     *
     * @return The list of objects that was provided.
     */
    global static List<sObject> ins(List<sObject> pObjs, boolean checkFls) {
        return ins(pObjs, new List<sObjectField>(), checkFls);
    }

    /**
     * Inserts an object and conditionally ensures that the current user
     * has Insert permission and Write access on the populated fields.
     *
     * @param pObj      The object to insert
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Write access is enforced or not
     *
     * @return The object that was provided.
     */
    private static sObject ins(sObject pObj, List<sObjectField> pFields, boolean checkFls) {
        system.assertNotEquals(null, pObj);
        List<sObject> objs = new List<sObject>();
        objs.add(pObj);
        return ins(objs, pFields, checkFls)[0];
    }

    /**
     * Inserts an object and ensures that the current user
     * has Insert permission and Write access on the populated fields.
     *
     * @param pObj      The object to insert
     * @param pFields   List of fields that is ignored
     *
     * @return The object that was provided.
     */
    private static sObject ins(sObject pObj, List<sObjectField> pFields) {
        system.assertNotEquals(null, pObj);
        List<sObject> objs = new List<sObject>();
        objs.add(pObj);
        return ins(objs, pFields, true)[0];
    }

    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Inserts an object and ensures that the current user
     * has Insert permission and Write access on the populated fields.
     *
     * @param pObj      The object to insert
     *
     * @return The object that was provided.
     */
    global static sObject ins(sObject pObj) {
        return ins(pObj, new List<sObjectField>());
    }

    /**
     * Inserts an object and conditionally ensures that the current user
     * has Insert permission and Write access on the populated fields.
     *
     * @param pObj      The object to insert
     * @param checkFls  Determines if Write access is enforced or not
     *
     * @return The object that was provided.
     */
    global static sObject ins(sObject pObj, boolean checkFls) {
        return ins(pObj, new List<sObjectField>(), checkFls);
    }

    /*--------------------------- UPDATE METHODS ------------------------------------*/

    /**
     * Updates a list of objects and conditionally ensures that the current user
     * has Update permission and has Write access on the populated fields.
     *
     * @param pObjs     The list of objects to update
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Update/Write access is enforced or not
     *
     * @return  The list of objects that was provided.
     */
    private static List<sObject> upd(List<sObject> pObjs, List<sObjectField> pFields, boolean checkFls) {
        if (pObjs != NULL && !pObjs.isEmpty()) {
            if (checkFls) {
                checkOperation(pObjs, Operation.Updating);
            }

            update pObjs;
        }

        return pObjs;
    }

    /**
     * Updates a list of objects and conditionally ensures that the current user
     * has Update permission and has Write access on the populated fields.
     * The update is performed with best effort semantics and will not fail
     * if an individual record fails to insert.
     *
     * @param pObjs     The list of objects to update
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Update/Write access is enforced or not
     *
     * @return  The list of results for each object which can be used to determine if any of the updates failed.
     */
    private static List<Database.SaveResult> updWithBestEffort(List<sObject> pObjs, List<sObjectField> pFields, boolean checkFls){
        if (checkFls) {
            system.assertNotEquals(null,pObjs);
            if(pObjs.size() == 0){
                return null;
            }
            checkOperation(pObjs, Operation.Updating);
        }
        List<Database.SaveResult> saveResults = Database.update(pObjs, false);
        return saveResults;
    }

    /**
    * Updates a list of objects and ensures that the current user
    * has Update permission and has Write access on the populated fields.
    *
    * @param pObjs     The list of objects to update
    *
    * @return  The list of objects that was provided.
     */
    global static List<sObject> upd(List<sObject> pObjs) {
        return upd(pObjs, new List<sObjectField>(), true);
    }

    /**
     * Updates a list of objects and conditionally ensures that the current user
     * has Update permission and has Write access on the populated fields.
     *
     * @param pObjs     The list of objects to update
     * @param checkFls  Determines if Update/Write access is enforced or not
     *
     * @return  The list of objects that was provided.
     */
    global static List<sObject> upd(List<sObject> pObjs, boolean checkFls) {
        return upd(pObjs, new List<sObjectField>(), checkFls);
    }

    /**
     * Updates a list of objects and ensures that the current user
     * has Update permission and has Write access on the populated fields.
     * The update is performed with best effort semantics and will not fail
     * if an individual record fails to insert.
     *
     * @param pObjs     The list of objects to update
     *
     * @return  The list of results for each object which can be used to determine if any of the updates failed.
     */
    global static List<Database.SaveResult> updWithBestEffort(List<sObject> pObjs){
        return updWithBestEffort(pObjs, new List<sObjectField>(), true);
    }

    //Tejas-Patel 12-Apr-2017; Function call with sObject Fields and FLS Check
    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Updates an object and conditionally ensures that the current user
     * has Update permission and has Write access on the populated fields.
     *
     * @param pObj      The object to update
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Update/Write access is enforced or not
     *
     * @return  The object that was provided.
     */
    private static sObject upd(sObject pObj, List<sObjectField> pFields, boolean checkFls) {
        system.assertNotEquals(null, pObj);
        return upd(new List<sObject>{pObj}, pFields, checkFls)[0];
    }

    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Updates an object and ensures that the current user
     * has Update permission and has Write access on the populated fields.
     *
     * @param pObj      The object to update
     *
     * @return  The object that was provided.
     */
    global static sObject upd(sObject pObj) {
        return upd(pObj, new List<sObjectField>(), true);
    }

    //Tejas-Patel 12-Apr-2017; Function call with sObject and FLS check
    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Updates an object and conditionally ensures that the current user
     * has Update permission and has Write access on the populated fields.
     *
     * @param pObj      The object to update
     * @param checkFls  Determines if Update/Write access is enforced or not
     *
     * @return  The object that was provided.
     */
    global static sObject upd(sObject pObj, boolean checkFls) {
        return upd(pObj, new List<sObjectField>(), checkFls);
    }

    /*--------------------------- UPSERT METHODS ------------------------------------*/

    /**
     * Upserts a list of objects and conditionally ensures that the current user
     * has Insert/Update permission and has Write access on the populated fields.
     *
     * @param pObjs     The list of objects to upsert
     * @param pFields   List of fields that is ignored
     * @param checkFls  Determines if Insert/Update/Write access is enforced or not
     *
     * @return  The list of objects that was provided.
     */
    public static List<sObject> ups(List<sObject> pObjs, List<sObjectField> pFields, boolean checkFls) {
        List<SObject> toIns = new List<SObject>();
        List<SObject> toUpd = new List<SObject>();
        for (sObject obj: pObjs) {
            if (obj.id == null) {
                toIns.add(obj);
            } else {
                toUpd.add(obj);
            }
        }
        // Security scan FALSE-POSITIVE: the scan show bulkifying issue, however there no individual inserts here.
        // Inserts and updates are done separately so only 2 DML statements are executed.
        ins(toIns, pFields, checkFls);
        upd(toUpd, pFields, checkFls);

        pObjs.clear();
        pObjs.addAll(toIns);
        pObjs.addAll(toUpd);

        return pObjs;
    }

    /**
     * Upserts a list of objects and ensures that the current user
     * has Insert/Update permission and has Write access on the populated fields.
     *
     * @param pObjs     The list of objects to upsert
     *
     * @return  The list of objects that was provided.
     */
    global static List<sObject> ups(List<sObject> pObjs) {
        return ups(pObjs, new List<sObjectField>(), true);
    }

    /**
     * Upserts a list of objects and conditionally ensures that the current user
     * has Insert/Update permission and has Write access on the populated fields.
     *
     * @param pObjs     The list of objects to upsert
     * @param checkFls  Determines if Insert/Update/Write access is enforced or not
     *
     * @return  The list of objects that was provided.
     */
    global static List<sObject> ups(List<sObject> pObjs, boolean checkFls) {
        return ups(pObjs, new List<sObjectField>(), checkFls);
    }

    /**
     * Upserts a list of objects and ensures that the current user
     * has Insert/Update permission and has Write access on the populated fields.
     *
     * @param pObjs     The list of objects to upsert
     * @param pFields   List of fields that is ignored
     *
     * @return  The list of objects that was provided.
     */
    private static List<sObject> ups(List<sObject> pObjs, List<sObjectField> pFields) {
        return ups(pObjs, pFields, true);
    }

    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Upserts an object and ensures that the current user
     * has Insert/Update permission and has Write access on the populated fields.
     *
     * @param pObj      The object to upsert
     * @param pFields   List of fields that is ignored
     *
     * @return  The object that was provided.
     */
    private static sObject ups(sObject pObj, List<sObjectField> pFields) {
        system.assertNotEquals(null, pObj);
        return ups(new List<sObject>{pObj}, pFields, true)[0];
    }

    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Upserts an object and ensures that the current user
     * has Insert/Update permission and has Write access on the populated fields.
     *
     * @param pObj      The object to upsert
     *
     * @return  The object that was provided.
     */
    global static sObject ups(sObject pObj) {
        return ups(pObj, new List<sObjectField>());
    }

    /*--------------------------- DELETE METHODS ------------------------------------*/

    /**
     * Deletes a list of objects and conditionally ensures that the current user has
     * Delete permission.
     *
     * @param pObjs     The list of objects to delete
     * @param checkFls  Determines if Delete access is enforced or not
     *
     * @return The list of objects that was provided.
     */
    global static List<sObject> del(List<sObject> pObjs, boolean checkFls) {
        if (pObjs != NULL && !pObjs.isEmpty()) {
            if (checkFls) {
                checkOperation(pObjs, Operation.Deleting);
            }

            delete pObjs;
        }

        return pObjs;
    }

    // Security scan FALSE-POSITIVE: the db method is called with one object and returns one object. 
    // The bulkifying alert is not relevant here as it is not being called in a loop.
    /**
     * Deletes an objects ensures that the current user has Delete permission.
     *
     * @param pObj      The object to delete
     *
     * @return The object that was provided.
     */
    global static sObject del(sObject pObj) {
        del(new List<sObject>{pObj}, true);
        return pObj;
    }

    /*--------------------------- CHECK ACCESS METHODS ------------------------------------*/

    /**
     * Checks if the current user has access to perform a CRUD operation on a given list of
     * objects. The fields that are populated on the objects are also checked to make sure
     * the user has Read/Write permission on the operation. Throws a <code>NoDatabaseAccessException</code>
     * if the user does not have the necessary permission.
     *
     * @param pObjs The list of objects to check access for the operation
     * @param op    The CRUD operation
     */
    private static void checkOperation(List<sObject> pObjs, Operation op) {
        List<String> fieldNames = findFields(pObjs);
        checkOperation(pObjs, op, fieldNames);
    }

    /**
     * Checks if the current user has access to perform a CRUD operation on a given list of
     * objects. The fields that are populated on the objects are also checked to make sure
     * the user has Read/Write permission on the operation. Throws a <code>NoDatabaseAccessException</code>
     * if the user does not have the necessary permission.
     *
     * @param pObjs         The list of objects to check access for the operation
     * @param op            The CRUD operation
     * @param fieldNames    The list of fields to check access on
     */
    private static void checkOperation(List<sObject> pObjs, Operation op, List<String> fieldNames) {
        if(!(UserInfo.getFirstName()==PC_Constants.CONNECTIONUSER_FName
                && UserInfo.getLastName()== PC_Constants.CONNECTIONUSER_LName
                && UserInfo.getUserType()==PC_Constants.CONNECTIONUSER_Type )) {
            Schema.DescribeSObjectResult objDesc = pObjs[0].getSObjectType().getDescribe();

            //CRUD on object
            if ((op == Operation.Creating && !objDesc.isCreateable())
                    || (op == Operation.Updating && !objDesc.isUpdateable())
                    || (op == Operation.Reading && !objDesc.isAccessible())
                    || (op == Operation.Deleting && !objDesc.isDeletable())) {
                //Exception e = new System.NoAccessException();
                Exception e = new PC_Database.NoDatabaseAccessException(objDesc.getName(), op); //PC-1967
                e.setMessage('No access on ' + objDesc.getName() + ' for ' + op);
                throw e;
            }

            //CRUD on fields if the object passes the check above
            Map<String, Schema.SObjectField> fieldNameMetaMap = objDesc.fields.getMap();
            List<String> noAccessFields = new List<String>();
            sObjectField field;
            Schema.DescribeFieldResult fieldDesc;
            system.debug('fieldNames== ' + fieldNames);
            if (fieldNames.size() > 0) {
                for (String fieldName : fieldNames) {

                    field = fieldNameMetaMap.get(fieldName);
                    if (field == null) {
                        continue;
                    }
                    fieldDesc = field.getDescribe();

                    // ignore system fields that can't have permissions
                    if (fieldDesc.isPermissionable()) {
                        if ((op == Operation.Creating && !fieldDesc.isCreateable())
                                || (op == Operation.Updating && !fieldDesc.isUpdateable())) {
                            noAccessFields.add(fieldName);
                        } else if ((op == Operation.Reading && !fieldDesc.isAccessible())) {
                            noAccessFields.add(fieldName);
                        }
                    } else {
                        System.debug('Bypass Check: FLS on [' + objDesc.getName() + '.' + fieldName + '] for [' + op + '] since it\'s not isPermissionable()');
                    }
                }
            }

            if (noAccessFields.size() > 0) {
                //Exception e = new System.NoAccessException();
                Exception e = new PC_Database.NoDatabaseAccessException(objDesc.getName(), noAccessFields, op); //PC-1967
                e.setMessage('No Access on ' + objDesc.getName() + ' for fields ' + noAccessFields + ' for ' + op);
                throw e;
            }
        }
    }

    /**
     * Returns a the complete list of fields that are populated in a list of objects
     *
     * @param pObjs The list of objects
     */
    private static List<String> findFields(List<sObject> pObjs) {
        List<String> fieldNames = new List<String>();
        Map<String, Object> fieldNameValueMap;
        for (sObject pObj : pObjs) {
            fieldNameValueMap = pObj.getPopulatedFieldsAsMap();
            fieldNames.addAll(fieldNameValueMap.keyset());
        }
        return fieldNames;
    }


    public static boolean chkAccess(String objName, Operation op, List<String> fieldNames) {
        if(!(UserInfo.getFirstName()==PC_Constants.CONNECTIONUSER_FName
                && UserInfo.getLastName()== PC_Constants.CONNECTIONUSER_LName
                && UserInfo.getUserType()==PC_Constants.CONNECTIONUSER_Type )) {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = gd.get(objName);
            Schema.DescribeSObjectResult objDesc = sobjType.getDescribe();
            //CRUD on object
            if ((op == Operation.Creating && !objDesc.isCreateable())
                    || (op == Operation.Updating && !objDesc.isUpdateable())) {
                return false;
            } else if (op == Operation.Reading && !objDesc.isAccessible()) {
                return false;
            } else if (op == Operation.Deleting && !objDesc.isDeletable()) {
                return false;
            }
            //CRUD on fields if the object passes the check above
            Map<String, Schema.SObjectField> fieldNameMetaMap = objDesc.fields.getMap();
            sObjectField field;
            Schema.DescribeFieldResult fieldDesc;
            if (fieldNames.size() > 0) {
                for (String fieldName : fieldNames) {
                    field = fieldNameMetaMap.get(fieldName);
                    fieldDesc = field.getDescribe();
                    // ignore system fields that can't have permissions
                    if (fieldDesc.isPermissionable()) {
                        if ((op == Operation.Creating && !fieldDesc.isCreateable())
                                || (op == Operation.Updating && !fieldDesc.isUpdateable())) {
                            return false;
                        } else if ((op == Operation.Reading && !fieldDesc.isAccessible())) {
                            return false;
                        }
                    }
                }
            }
        }
        return true;
    }
    
    //[PC-1967] Custom exception for PC_Database to replace System.NoAccessException
    /**
     * Exception used to capture the object and list of fields that a user is missing
     * permission on.
     */
    global inherited sharing class NoDatabaseAccessException extends Exception{
        /**
         * The object type name.
         */
        global string objectName;

        /**
         * The list of fields that the user does not have sufficient permission on
         */
        global List<string> noAccessFields;

        /**
         * The CRUD operation to be performed
         */
        global Operation operation;
        
                
       public NoDatabaseAccessException(string objName, List<string> fields, Operation op){
            this.objectName = objName;
            this.noAccessFields = fields;
            this.operation = op;
        }
        
        public NoDatabaseAccessException(string objName, Operation op){
            this.objectName = objName;
            this.operation = op;
        }
    }
}