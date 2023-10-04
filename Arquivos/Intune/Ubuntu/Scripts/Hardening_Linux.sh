#!/bin/bash
#

SCRIPT_PATH=${PWD}

echo "Scripts path files = ${SCRIPT_PATH}" > security_file.log

${SCRIPT_PATH}/ConfigureSecureBoot.sh >> security_file.log
${SCRIPT_PATH}/ConfigureService.sh >> security_file.log
${SCRIPT_PATH}/ConfigureTimeBasedJobSchedules.sh >> security_file.log
${SCRIPT_PATH}/ConfigureUncommonNetworkProtocols.sh >> security_file.log
${SCRIPT_PATH}/EnsureCronDaemonEnabledAndRunning.sh >> security_file.log
${SCRIPT_PATH}/EnsureFsDisabled.sh >> security_file.log
${SCRIPT_PATH}/EnsurePartitionConfigured.sh >> security_file.log
${SCRIPT_PATH}/EnsurePermissionsOnAllLogfilesConfigured.sh >> security_file.log
${SCRIPT_PATH}/EnsureUsbStorageDisabled.sh >> security_file.log
${SCRIPT_PATH}/ubuntu-post-installation.sh >> security_file.log
