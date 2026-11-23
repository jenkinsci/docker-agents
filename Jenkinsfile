final String cronExpr = env.BRANCH_IS_PRIMARY ? '@daily' : ''

properties([
    buildDiscarder(logRotator(numToKeepStr: '10')),
    disableConcurrentBuilds(abortPrevious: true),
    pipelineTriggers([cron(cronExpr)]),
])

def agentSelector(String imageType, retryCounter) {
    def platform
    switch (imageType) {
        // All Windows images
        case ~/(nanoserver|windowsservercore).*/:
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

// Defaul values
def tagWithOneDashExist = false
def remotingVersion = '3396.ve02b_5cde31b_2'
def buildNumber = env.BUILD_NUMBER
// Values on tag containing the remoting version and build number
if (env.TAG_NAME) {
    def tagItems = env.TAG_NAME.split('-')
    if (tagItems.length == 2) {
        tagWithOneDashExist = true
        remotingVersion = tagItems[0]
        buildNumber = tagItems[1]
    }
}

// Linux: bake group(s) or target(s), see 'make list' or 'make listgroup-linux' output
// Note: splitting Alpine and Debian targets to avoid 429 rate limit errors from Docker Hub
// Windows: flavor and version to build
def allImagesTypeAndTheirVariants = [
    'agent_alpine_jdk21':         ['linux', 'alpine', 'jdk21'],
    'agent_alpine_jdk25':         ['linux', 'alpine', 'jdk25'],
    'inbound-agent_alpine_jdk21': ['linux', 'alpine', 'jdk21'],
    'inbound-agent_alpine_jdk25': ['linux', 'alpine', 'jdk25'],
    'agent_debian_jdk21':         ['linux', 'debian', 'jdk21'],
    'agent_debian_jdk25':         ['linux', 'debian', 'jdk25'],
    'inbound-agent_debian_jdk21': ['linux', 'debian', 'jdk21'],
    'inbound-agent_debian_jdk25': ['linux', 'debian', 'jdk25'],
    'rhel_ubi9':                  ['linux', 'rhel', 'jdk21', 'jdk25'],
    'nanoserver-ltsc2022':        ['windows', 'nanoserver', 'jdk21', 'jdk25'],
    'nanoserver-ltsc2025':        ['windows', 'nanoserver', 'jdk21', 'jdk25'],
    'windowsservercore-ltsc2022': ['windows', 'jdk21', 'jdk25'],
    'windowsservercore-ltsc2025': ['windows', 'jdk21', 'jdk25'],
]

// Specify java release(s) to build for Windows images
def allWindowsJavaReleases = [21, 25]

def imageTypesToBuild = allImagesTypeAndTheirVariants.keySet().toList()
def windowsJavaReleases = allWindowsJavaReleases.collect()
if (env.CHANGE_ID) {
    def requestedVariants = []
    pullRequest.labels.each { label -> 
        if (label.startsWith('variant-')) {
            requestedVariants << label.replace('variant-', '')
        }
    }
    if (requestedVariants) {
        echo "Building only selected variant(s): ${requestedVariants}"

        imageTypesToBuild = allImagesTypeAndTheirVariants.findAll { image, variants ->
            variants.any { it in requestedVariants }
        }.keySet().toList()

        // Special case for JDK variants and Windows Java releases
        if (requestedVariants.any { it ==~ /jdk\d+/ }) {
            windowsJavaReleases = []
            requestedVariants.findAll { it.contains('jdk') }.each {
                windowsJavaReleases += it.replace('jdk', '')
            }
            echo "Building only Windows Java release(s): ${windowsJavaReleases}"
        }
        echo "Images to build: ${imageTypesToBuild}"
    }
}

def parallelStages = [failFast: false]
imageTypesToBuild.each { imageType ->
    parallelStages[imageType] = {
        withEnv([
            "ON_TAG=${tagWithOneDashExist}",
            "REMOTING_VERSION=${remotingVersion}",
            "BUILD_NUMBER=${buildNumber}",
            "IMAGE_TYPE=${imageType}",
            "REGISTRY_ORG=${infra.isTrustedCiController() ? 'jenkins' : 'jenkins4eval'}"
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
                        if (!infra.isTrustedCiController()) {
                            // Build current arch for Linux images
                            stage('Build current arch') {
                                if (isUnix()) {
                                    sh 'make "build-${IMAGE_TYPE}"'
                                } else {
                                    // No multiarch Windows images
                                    windowsJavaReleases.each { javaRelease ->
                                        withEnv(["JAVA_RELEASE_OVERRIDE=${javaRelease}"]) {
                                            powershell './make.ps1 build -ImageType ${env:IMAGE_TYPE}'
                                        }
                                    }
                                }
                            }

                            stage('Test') {
                                if (isUnix()) {
                                    sh 'make "test-${IMAGE_TYPE}"'
                                } else {
                                    windowsJavaReleases.each { javaRelease ->
                                        withEnv(["JAVA_RELEASE_OVERRIDE=${javaRelease}"]) {
                                            powershell './make.ps1 test -ImageType ${env:IMAGE_TYPE} -TestsDebug verbose'
                                        }
                                    }
                                }
                                junit 'target/**/junit-results*.xml'
                            }
                            archiveArtifacts artifacts: 'target/build-result-metadata_*.json', allowEmptyArchive: true
                        }

                        // If the tests are passing for Linux AMD64 or if we're on trusted.ci.jenkins.io
                        // then we build all the CPU architectures
                        stage('Build multiarch') {
                            if (isUnix()) {
                                sh 'make "multiarchbuild-${IMAGE_TYPE}"'
                            } else {
                                // No multiarch images for Windows, (re)building them here on both controllers
                                windowsJavaReleases.each { javaRelease ->
                                    withEnv(["JAVA_RELEASE_OVERRIDE=${javaRelease}"]) {
                                        powershell './make.ps1 build -ImageType ${env:IMAGE_TYPE}'
                                    }
                                }
                            }
                            archiveArtifacts artifacts: 'target/build-result-metadata_*.json', allowEmptyArchive: true
                        }

                        // trusted.ci.jenkins.io builds (e.g. publication to DockerHub)
                        if (infra.isTrustedCiController()) {
                            stage('Deploy to DockerHub') {
                                if (!tagWithOneDashExist) {
                                    error("The deployment to Docker Hub failed because the tag doesn't contain any '-'.")
                                }
                                // This function is defined in the jenkins-infra/pipeline-library
                                infra.withDockerCredentials {
                                    if (isUnix()) {
                                        if (imageType != 'linux') {
                                            sh 'make "publish-${IMAGE_TYPE}"'
                                        } else {
                                            // Batch Linux images publication by distribution to avoid 429 rate limit errors from Docker Hub
                                            sh 'make listgroup-linux | xargs -I {} make "publish-{}"'
                                        }
                                    } else {
                                        windowsJavaReleases.each { javaRelease ->
                                            withEnv(["JAVA_RELEASE_OVERRIDE=${javaRelease}"]) {
                                                powershell './make.ps1 publish -ImageType ${env:IMAGE_TYPE}'
                                            }
                                        }
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

// Execute parallel stages
parallel parallelStages
// // vim: ft=groovy
