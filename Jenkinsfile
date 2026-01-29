final String cronExpr = env.BRANCH_IS_PRIMARY ? '@daily' : ''

properties([
    buildDiscarder(logRotator(numToKeepStr: '10')),
    disableConcurrentBuilds(abortPrevious: true),
    pipelineTriggers([cron(cronExpr)]),
])

def agentSelector(String imageType, retryCounter) {
    def platform
    switch (imageType) {
        // nanoserver-1809, nanoserver-ltsc2019 and windowservercore-ltsc2019
        case ~/.*(1809|2019)/:
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
def parallelStages = [failFast: false]
[
    'linux',
    'nanoserver-1809',
    'nanoserver-ltsc2019',
    'nanoserver-ltsc2022',
    'windowsservercore-1809',
    'windowsservercore-ltsc2019',
    'windowsservercore-ltsc2022'
].each { imageType ->
    parallelStages[imageType] = {
        withEnv(["IMAGE_TYPE=${imageType}", "REGISTRY_ORG=${infra.isTrusted() ? 'jenkins' : 'jenkins4eval'}"]) {
            int retryCounter = 0
            retry(count: 2, conditions: [agent(), nonresumable()]) {
                // Use local variable to manage concurrency and increment BEFORE spinning up any agent
                final String resolvedAgentLabel = agentSelector(imageType, retryCounter)
                retryCounter++
                node(resolvedAgentLabel) {
                    timeout(time: 60, unit: 'MINUTES') {
                        checkout scm
                        if (imageType == "linux") {
                            stage('Prepare Docker') {
                                sh 'make docker-init'
                            }
                        }
                        // This function is defined in the jenkins-infra/pipeline-library
                        if (infra.isTrusted()) {
                            // trusted.ci.jenkins.io builds (e.g. publication to DockerHub)
                            stage('Deploy to DockerHub') {
                                String[] tagItems = env.TAG_NAME.split('-')
                                if(tagItems.length == 2) {
                                    withEnv([
                                        "ON_TAG=true",
                                        "REMOTING_VERSION=${tagItems[0]}",
                                        "BUILD_NUMBER=${tagItems[1]}",
                                    ]) {
                                        // This function is defined in the jenkins-infra/pipeline-library
                                        infra.withDockerCredentials {
                                            if (isUnix()) {
                                                sh 'make publish'
                                            } else {
                                                powershell '& ./build.ps1 build'
                                                powershell '& ./build.ps1 publish'
                                            }
                                        }
                                    }
                                } else {
                                    error("The deployment to Docker Hub failed because the tag doesn't contain any '-'.")
                                }
                            }
                        } else {
                            // ci.jenkins.io builds (e.g. no publication)
                            stage('Build') {
                                if (isUnix()) {
                                    sh './build.sh'
                                } else {
                                    powershell '& ./build.ps1 build'
                                    archiveArtifacts artifacts: 'build-windows_*.yaml', allowEmptyArchive: true
                                }
                            }
                            stage('Test') {
                                if (isUnix()) {
                                    sh './build.sh test'
                                } else {
                                    powershell '& ./build.ps1 test'
                                }
                                junit(allowEmptyResults: true, keepLongStdio: true, testResults: 'target/**/junit-results*.xml')
                            }
                            // If the tests are passing for Linux AMD64, then we can build all the CPU architectures
                            if (isUnix()) {
                                stage('Multi-Arch Build') {

                                    sh 'make every-build'
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
