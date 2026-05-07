/*********************************************************************************
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Vijay Kashikar              16-Jan-19                  Initial Version
Vijay Kashikar              04-Mar-19                  [PC-4426] Handled migration from 7.0 to 7.1
Vijay Kashikar              13-Mar-19                  [PC-4603] Handled context - 'Push Upgrades'
Vijay Kashikar              24-Apr-19                  [PC-4755] Send email only if upgrading the package from versions
                                                        below 7.0 and if it has any accounts to be migrated.
Vijay Kashikar              08-Jul-19                  [PC-5008] Made changes so that package installation doesn't fail if
                                                        an exception occurs during post install execution. Exception gets
                                                        logged in Document object.
Kanteti Kishore             26-Aug-2019                [PC-5351] Method insertGeocodeProtectedCustomSettings() is added to the class
                                                       so that geocode api data is created in protected custom settings.
*********************************************************************************/
/**
 * Post Install Script that runs after every package installation/upgrade.
 */
global class PC_PostInstall implements InstallHandler{

    public static final String TXT_KEY = 'txt';
    /**
     * Executes after the package is installed.
     * @param context holds install context information.
     */
    global void onInstall(InstallContext context) {
        try {
            if (context.previousVersion() != null && context.previousVersion().compareTo(new Version(7, 0)) < 0) {
                PC_PostDeployment postDeployment = new PC_PostDeployment();
                if (postDeployment.v7.noOfPhysicianAccsToBeMigrated > 0 || postDeployment.v7.noOfPatientAccsToBeMigrated > 0) {

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setSubject('Patient Connect : Post Installation Steps');

                    String welcomeMessage = 'Thank you for installing Patient Connect.';

                    String hcMessage = '\nPatient Connect is now aligned with the Individual Model of Health Cloud and this necessitates a migration step.';

                    String message = '\n\n' + postDeployment.v7.patientMigrationMessage;

                    message += '\n\n' + postDeployment.v7.physicianMigrationMessage;

                    String orgUrl = URL.getSalesforceBaseUrl().toExternalForm();
                    String deploymentPageURL = orgUrl + '/apex/' +
                            PC_Constants.getQualifiedAPIName('PC_PostDeployment');

                    message += '\n\n' + ' Please visit ' + deploymentPageURL + ' for more details.';
                    system.debug(message);

                    String[] toAddresses = new String[]{
                    };
                    String userName = '';

                    if (context.isPush()) {
                        userName = 'via Push Upgrade';
                        try {
                            List<User> sysAdminUsers = [
                                    SELECT Id, Username, Email, Profile.Name
                                    FROM User
                                    WHERE Profile.UserLicense.Name = :PC_Constants.USER_LICENSE_SALESFORCE and
                                    Profile.Name = :PC_Constants.PROFILE_SALESFORCE_SYS_ADMIN and IsActive = TRUE
                            ];
                            for (User sysAdminUser : sysAdminUsers) {
                                system.debug(sysAdminUser.Email);
                                toAddresses.add(sysAdminUser.Email);
                            }
                        } catch (Exception ex) {
                            system.debug('No system admins found');
                            system.debug(ex.getMessage());
                        }
                    } else {
                        User u = [Select Id, Email, Username from User where Id = :context.installerID()];
                        String toAddress = u.Email;
                        toAddresses.add(toAddress);
                        userName = u.Username;
                    }

                    if (toAddresses != null && !toAddresses.isEmpty()) {
                        String orgId = context.organizationId();
                        String orgMessage = '\nOrganization Id: ' + orgId;

                        String userMessage = '\nUser: ' + userName;

                        String thankYouMessage = '\n\nTeam Patient Connect';

                        email.setPlainTextBody(welcomeMessage + hcMessage + message + orgMessage + userMessage + thankYouMessage);

                        email.setToAddresses(toAddresses);
                        system.debug('About to send email');
                        Messaging.sendEmail(new Messaging.Email[]{
                                email
                        });
                    } else {
                        system.debug('No recipients found to send the email');
                    }
                }
            }
        }
        catch(Exception ex) {
            logException(ex);
        }
    }
    public static void logException(Exception ex) {
        String postInstallLogContent = 'Exception occurred while running post install script. ';
        postInstallLogContent += '\n' + 'Exception Message: ' + ex.getMessage();
        postInstallLogContent += '\n' + 'Exception Stack Trace: ' + ex.getStackTraceString();
        postInstallLogContent += '\n' + 'Exception Line #: ' + ex.getLineNumber();
        postInstallLogContent += '\n' + 'Exception Type: ' + ex.getTypeName();
        system.debug(postInstallLogContent);

        Document postInstallLog = new Document();
        postInstallLog.Name = 'PC_PostInstall-' + PC_Constants.EMPTY_STRING + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        postInstallLog.Type = TXT_KEY;
        postInstallLog.folderid = UserInfo.getUserId();
        postInstallLog.Body = Blob.valueOf(postInstallLogContent);

        upsert postInstallLog;
        system.debug(postInstallLog.Id);
    }
}