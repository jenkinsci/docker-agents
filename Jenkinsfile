final String cronExpr = env.BRANCH_IS_PRIMARY ? '@daily' : ''

properties([
    buildDiscarder(logRotator(numToKeepStr: '10')),
    disableConcurrentBuilds(abortPrevious: true),
    pipelineTriggers([cron(cronExpr)]),
])

def agentSelector(String imageType, retryCounter) {
    def platform
    switch (imageType) {
        // nanoserver-ltsc2019 and windowservercore-ltsc2019
        case ~/.*2019/:
            platform = 'windows-2019'
            break

        // nanoserver-ltsc2022 and windowservercore-ltsc2022
        case ~/.*2022/:
            platform = 'windows-2022'
            break

        // nanoserver-ltsc2025 and windowservercore-ltsc2025
        case ~/.*2025/:
            platform = 'windows-2025'
            break

        // Linux
        default:
            // Need Docker and a LOT of memory for faster builds (due to multi archs)
            platform = 'docker-highmem'
            break
    }

    // Defined in https://github.com/jenkins-infra/pipeline-library/blob/master/vars/infra.groovy
    return infra.getBuildAgentLabel([
        useContainerAgent: false,
        platform: platform,
        spotRetryCounter: retryCounter
    ])
}

// Specify parallel stages
// Linux: bake group(s) or target(s)
// Windows: flavor and version to build
def parallelStages = [failFast: false]
[
    'linux',
    'nanoserver-ltsc2019',
    'nanoserver-ltsc2022',
    'windowsservercore-ltsc2019',
    'windowsservercore-ltsc2022'
].each { imageType ->
    parallelStages[imageType] = {
        // Only bake targets can be specified with build-%, test-% and publish-% make targets
        def makeTargetSuffix= (imageType.startsWith('agent_') || imageType.startsWith('inbound-agent_')) ? "-${imageType}" : ''
        withEnv([
            "IMAGE_TYPE=${imageType}",
            "REGISTRY_ORG=${infra.isTrusted() ? 'jenkins' : 'jenkins4eval'}",
            "MAKE_TARGET_SUFFIX=${makeTargetSuffix}"
        ]) {
            int retryCounter = 0
            retry(count: 2, conditions: [agent(), nonresumable()]) {
                // Use local variable to manage concurrency and increment BEFORE spinning up any agent
                final String resolvedAgentLabel = agentSelector(imageType, retryCounter)
                retryCounter++
                node(resolvedAgentLabel) {
                    timeout(time: 60, unit: 'MINUTES') {
                        checkout scm
                        stage("Prepare Docker on ${resolvedAgentLabel}") {
                            if (isUnix()) {
                                sh 'make docker-init'
                            } else {
                                powershell './make.ps1 docker-init'
                                archiveArtifacts artifacts: 'build-windows_*.yaml', allowEmptyArchive: true
                            }
                        }

                        if (isUnix()) {
                            stage('Checks') {
                                sh 'make hadolint'
                                sh 'make shellcheck'
                            }
                        }

                        // No single arch build or test on trusted.ci.jenkins.io
                        if (!infra.isTrusted()) {
                            // Build current arch for Linux images
                            stage('Build current arch') {
                                if (isUnix()) {
                                    sh 'make "build${MAKE_TARGET_SUFFIX}"'
                                } else {
                                    // No multiarch Windows images
                                    powershell './make.ps1 build'
                                }
                            }

                            stage('Test') {
                                if (isUnix()) {
                                    sh 'make "test${MAKE_TARGET_SUFFIX}"'
                                } else {
                                    powershell './make.ps1 test'
                                }
                                junit(allowEmptyResults: true, keepLongStdio: true, testResults: 'target/**/junit-results*.xml')
                            }
                            archiveArtifacts artifacts: 'target/build-result-metadata_*.json', allowEmptyArchive: true
                        }

                        // If the tests are passing for Linux AMD64 or if we're on trusted.ci.jenkins.io
                        // then we build all the CPU architectures
                        stage('Build multiarch') {
                            if (isUnix()) {
                                sh 'make "multiarchbuild${MAKE_TARGET_SUFFIX}"'
                            } else {
                                // No multiarch images for Windows, (re)building them here on both controllers
                                powershell './make.ps1 build'
                            }
                            archiveArtifacts artifacts: 'target/build-result-metadata_*.json', allowEmptyArchive: true
                        }

                        // trusted.ci.jenkins.io builds (e.g. publication to DockerHub)
                        if (infra.isTrusted()) {
                            stage('Deploy to DockerHub') {
                                String[] tagItems = env.TAG_NAME.split('-')
                                if(tagItems.length != 2) {
                                    error("The deployment to Docker Hub failed because the tag doesn't contain any '-'.")
                                }
                                withEnv([
                                    "ON_TAG=true",
                                    "REMOTING_VERSION=${tagItems[0]}",
                                    "BUILD_NUMBER=${tagItems[1]}",
                                ]) {
                                    // This function is defined in the jenkins-infra/pipeline-library
                                    infra.withDockerCredentials {
                                        if (isUnix()) {
                                            sh 'make "publish${MAKE_TARGET_SUFFIX}"'
                                        } else {
                                            powershell './make.ps1 publish'
                                        }
                                    }
                                    archiveArtifacts artifacts: 'target/build-result-metadata_*.json', allowEmptyArchive: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Execute parallel stages
parallel parallelStages
// // vim: ft=groovy
