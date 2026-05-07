/*********************************************************************************************************
Class Name      : PC_Services 
Description     :  
Created By      : Deloitte
Created Date    : 
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
Vasile Paraschiv   0001         27.05.2016             Moved Schema.DisplayType.Combobox from boolean types to string types
Ajinkya Deshmukh				20.06.2017			   FLS Check Added and changed to With Sharing (Code Merge)
Mike Klkumpenaar                2017-08-10             [PC-2007] Removed picklistFieldMap methods that are no longer used
****************************************************************************************************************/
public with sharing class PC_Services {

    private static final List < Schema.DisplayType > STRING_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.base64, Schema.DisplayType.Email, Schema.DisplayType.MultiPicklist, Schema.DisplayType.Phone, Schema.DisplayType.Picklist, Schema.DisplayType.String, Schema.DisplayType.TextArea, Schema.DisplayType.URL, Schema.DisplayType.Combobox
    };
    private static final List < Schema.DisplayType > INTEGER_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.Integer
    };
    private static final List < Schema.DisplayType > ID_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.ID, Schema.DisplayType.Reference
    };
    private static final List < Schema.DisplayType > DOUBLE_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.Currency, Schema.DisplayType.Double, Schema.DisplayType.Percent
    };
    private static final List < Schema.DisplayType > DATETIME_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.DateTime
    };
    private static final List < Schema.DisplayType > DATE_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.Date
    };
    private static final List < Schema.DisplayType > BOOLEAN_TYPES = new List < Schema.DisplayType > {
        Schema.DisplayType.Boolean
    };
    private static Map < String, Schema.DescribeSobjectResult > sCashedDescribes = new Map < String, Schema.DescribeSobjectResult > ();
    private static Map < String, Map < String, Schema.SObjectField >> sCashedFields = new Map < String, Map < String, Schema.SObjectField >> ();

    public static final String NS_DEFAULT = 'NS_DDPC';
    private static String sNameSpace = NS_DEFAULT;

    // Given an sObjectType, return its namespace prefix, if present
    // Remember: standard sObjects have no namespace prefix.
    private static String getNamespace(Schema.DescribeSobjectResult pObjDescr) {

        // Give back the cached value, if present
        if (!sNameSpace.equals(NS_DEFAULT) || pObjDescr == null)
            return sNameSpace;

        String reqName = pObjDescr.getName();

        Map < String, Schema.SObjectType > gd = Schema.getGlobalDescribe();
        // Loop until we find something in the form of a namespace: namespaceprefix__objname__c
        for (SObjectType sObfjType: gd.values()) {
            String name = sObfjType.getDescribe().getName();

            if (name != null && name.equalsIgnoreCase(reqName)) {
                List < String > nameParts = name.split('__');
                if (nameParts.size() == 3) {
                    sNameSpace = nameParts[0];
                    break;
                }
            }
        } // end loop

        return sNameSpace;
    }

    public static String getNamespace(Schema.sObjectType pObjType) {
        if (pObjType == null)
            return NS_DEFAULT;

        return getNamespace(pObjType.getDescribe());
    }

    public static String getNamespace(String pObjectName) {
        if (pObjectName == null || String.isBlank(pObjectName))
            return NS_DEFAULT;

        return getNamespace(describe(pObjectName));
    }

    public static Schema.DescribeSobjectResult describe(String pObjName) {

        Schema.DescribeSobjectResult result = (sCashedDescribes.containsKey(pObjName)) ?
            sCashedDescribes.get(pObjName) :
            (Schema.getGlobalDescribe().get(pObjName) != null) ?
            Schema.getGlobalDescribe().get(pObjName).getDescribe() :
            null;

        if (result != null)
            sCashedDescribes.put(pObjName, result);

        return result;
    }

    public static Map < String, Schema.SObjectField > fields(String pObjName) {
        return fields(Schema.getGlobalDescribe().get(pObjName));
    }

    public static Map < String, Schema.SObjectField > fields(Schema.SObjectType pObjType) {
        if (sCashedFields.containsKey(pObjType.getDescribe().getName()))
            return sCashedFields.get(pObjType.getDescribe().getName());

        Map < String, Schema.SObjectField > fields = pObjType.getDescribe().fields.getMap();
        sCashedFields.put(pObjType.getDescribe().getName(), fields);
        return fields;
    }

    public static Map < String, Schema.SObjectField > accessibleFields(Schema.sObjectType pObjType) {
        Map < String, Schema.SObjectField > result = new Map < String, Schema.SObjectField > ();
        Map < String, Schema.SObjectField > fields = fields(pObjType);
        for (String fieldName: fields.keySet()) {
            if (fields.get(fieldName).getDescribe().isAccessible())
                result.put(fieldName, fields.get(fieldName));
        }
        return result;
    }

    public static Map < String, Schema.SObjectField > accessibleFields(String pObjName) {
        return accessibleFields(Schema.getGlobalDescribe().get(pObjName));
    }

    public static Map < String, Schema.SObjectField > updateableFields(Schema.sObjectType pObjType) {
        Map < String, Schema.SObjectField > result = new Map < String, Schema.SObjectField > ();
        Map < String, Schema.SObjectField > fields = fields(pObjType);
        for (String fieldName: fields.keySet()) {
            if (fields.get(fieldName).getDescribe().isUpdateable())
                result.put(fieldName, fields.get(fieldName));
        }
        return result;
    }

    public static Map < String, Schema.SObjectField > updateableFields(String pObjName) {
        return updateableFields(Schema.getGlobalDescribe().get(pObjName));
    }
    public static String updateableFieldsString(String pObjName) {
        Schema.sObjectType pObjType = Schema.getGlobalDescribe().get(pObjName);
        Map < String, Schema.SObjectField > fields = updateableFields(pObjType);


        return String.join(new List < String > (fields.keySet()), ',');
    }

    // Given an SObjectField, return true if is a picklist field
    public static Boolean isPickListField(SObjectField field) {
        if (field != null)
            return field.getDescribe().getType() == Schema.DisplayType.Picklist;
        else
            return false;
    }

    // Given an SObjectField, return true if is a multipicklist field
    public static Boolean isMultiPickListField(SObjectField field) {
            return field.getDescribe().getType() == Schema.DisplayType.Multipicklist;
    }

    // Given an SObjectField, return true if is a Lookup field
    public static boolean isLookupField(SObjectField field) {
            return field.getDescribe().getType() == Schema.Displaytype.Reference;
    }

    public static boolean isAccessible(String pObjName, String pFieldName) {
        String fieldName = pFieldName.toLowerCase();
        return accessibleFields(pObjName).containsKey(fieldName);
    }

    public static boolean isUpdateable(String pObjName, String pFieldName) {
        String fieldName = pFieldName.toLowerCase();
        return updateableFields(pObjName).containsKey(fieldName);
    }

    public static boolean isAccessible(String pObjName) {
        return describe(pObjName).IsAccessible();
    }

    public static boolean isCreateable(String pObjName) {
        return describe(pObjName).isCreateable();
    }

    public static boolean isUpdateable(String pObjName) {
        return describe(pObjName).isUpdateable();
    }

    public static boolean isDeletable(String pObjName) {
        return describe(pObjName).isDeletable();
    }

    public static boolean isCustom(String pObjName) {
        return describe(pObjName).IsCustom();
    }

    public Static List < String > fieldsToString(List < SObjectField > pSObjectFields) {
        List < String > result = new List < String > ();
        for (SObjectField field: pSObjectFields) {
            result.add(field.getDescribe().getName());
        }
        return result;
    }

    public static string shareObjName(String pObjectName) {
        Schema.DescribeSobjectResult objDesc = describe(pObjectName);
        return objDesc.IsCustom() ? objDesc.getName().replace('__c', '__Share') : objDesc.getName() + 'Share';
    }

    public static Schema.SObjectType sObjectType(ID pId) {
        Schema.SObjectType result = null;
        for (SObjectType sObfjType: Schema.getGlobalDescribe().values()) {
            String keyPrefix = sObfjType.getDescribe().getKeyPrefix();
            if (keyPrefix != null && String.valueOf(pId).startsWith(keyPrefix))
                return (result = sObfjType);
        }
        system.assert(result != null, 'Cannot find Object Type for ID:' + pId);
        return result;
    }

    public static boolean isObjectId(ID pId, SObjectType pObjType) {
        return sObjectType(pId) == pObjType;
    }

    public static SObject copyFields(SObject pSource, SObject pDestination, boolean pForceNulls) {
        Map < String, Schema.SObjectField > sourceFields = fields(pSource.getSObjectType());
        Map < String, Schema.SObjectField > destinationFields = fields(pDestination.getSObjectType());
        // Keep only matching fields, based on the name, and field that were retreived in the source record.
        Set < String > copyFields = new Set < String > ();
        for (String fieldName: destinationFields.keySet()) {
            try {
                if (sourceFields.containsKey(fieldName)) {
                    pSource.get(fieldName);
                    copyFields.add(fieldName);
                }
            } catch (System.SObjectException e) { /* Do Nothing; skip field if it was not retrieved */ }
        }

        for (String fieldName: copyFields) {
            Schema.SObjectField sourceField = sourceFields.get(fieldName);
            Schema.SObjectField destinationField = destinationFields.get(fieldName);
            // AZ: do not change these conditions. Very sensitive code.
            boolean isCopyPermitted = !destinationField.getDescribe().isAutoNumber() && !destinationField.getDescribe().isCalculated() && sourceField.getDescribe().getType() == destinationField.getDescribe().getType() && sourceField.getDescribe().isAccessible() && destinationField.getDescribe().isAccessible() && destinationField.getDescribe().isUpdateable() && (pDestination.ID == null && destinationField.getDescribe().isCreateable() || pDestination.ID != null && destinationField.getDescribe().isUpdateable()) && (pForceNulls || pSource.get(fieldName) != null);

            if (isCopyPermitted) {
                if (isID(destinationField)) {
                    pDestination.put(destinationField, (Id) pSource.get(sourceField));
                } else if (isString(destinationField)) {
                    pDestination.put(destinationField, (String) pSource.get(sourceField));
                } else if (isInteger(destinationField)) {
                    pDestination.put(destinationField, (Integer) pSource.get(sourceField));
                } else if (isDouble(destinationField)) {
                    pDestination.put(destinationField, (Double) pSource.get(sourceField));
                } else if (isDate(destinationField)) {
                    pDestination.put(destinationField, (Date) pSource.get(sourceField));
                } else if (isDateTime(destinationField)) {
                    pDestination.put(destinationField, (DateTime) pSource.get(sourceField));
                } else if (isBoolean(destinationField)) {
                    pDestination.put(destinationField, (Boolean) pSource.get(sourceField));
                } else {
                    pDestination.put(destinationField, pSource.get(sourceField));
                }
            }
        }
        return pDestination;
    }

    public static System.SelectOption[] listViews(String pObjectName) {
        pObjectName = pObjectName.endsWithIgnoreCase('__c') ? PC_Constants.getQualifiedAPIName(pObjectName) : pObjectName;
    	List<String> fields = new List<String>{'Name'};
    	PC_Database.assertAccess(pObjectName ,PC_Database.Operation.Reading, fields);
        String query = 'SELECT Id, Name FROM ' + pObjectName + ' LIMIT 5 ';
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(Database.getQueryLocator(query));

        return con.getListViewOptions();
    }

    public static ID viewIdFromName(String pObjName, String pViewName) {
        Id listId = null;
        for (SelectOption opt: PC_Services.listViews(pObjName)) {
            if (opt.getLabel() == pViewName) {
                listId = opt.getValue();
                break;
            }
        }

        system.assert(listId != null, 'View was not found for Object:' + pObjName + ' View name:' + pViewName);
        return listId;
    }

    public static List < Id > keyToken15ToIds(String pKeys) {
        List < Id > result = (pKeys == null) ? new List < Id > () : key15ToId(pKeys.split(','));
        return result;
    }

    public static List < Id > key15ToId(List < String > pKeys) {
        List < Id > result = new List < Id > ();
        Id idValue;
        for (String key: pKeys) {
            idValue = key;
            result.add(idValue);
        }
        return result;
    }

    public static Id key15ToId(String pKey) {
        Id value = pKey;
        return value;
    }
    public static boolean isString(SObjectField pField) {
        return contains(STRING_TYPES, pField.getDescribe().getType());
    }

    public static boolean isInteger(SObjectField pField) {
        return contains(INTEGER_TYPES, pField.getDescribe().getType());
    }

    public static boolean isID(SObjectField pField) {
        return contains(ID_TYPES, pField.getDescribe().getType());
    }

    public static boolean isDouble(SObjectField pField) {
        return contains(DOUBLE_TYPES, pField.getDescribe().getType());
    }

    public static boolean isDate(SObjectField pField) {
        return contains(DATE_TYPES, pField.getDescribe().getType());
    }

    public static boolean isDateTime(SObjectField pField) {
        return contains(DATETIME_TYPES, pField.getDescribe().getType());
    }

    public static boolean isBoolean(SObjectField pField) {
        return contains(BOOLEAN_TYPES, pField.getDescribe().getType());
    }

    private static Boolean contains(List < Schema.DisplayType > pListActingAsSet, Schema.DisplayType pTypeToCheck) {
        if (pListActingAsSet != null && pListActingAsSet.size() > 0) {
            for (Schema.DisplayType aType: pListActingAsSet) {
                if (aType == pTypeToCheck)
                    return true;
            }
        }
        return false;
    }
}