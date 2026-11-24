Import-Module -DisableNameChecking -Force $PSScriptRoot/test_helpers.psm1

$global:IMAGE_NAME = Get-EnvOrDefault 'IMAGE_NAME' '' # Ex: jenkins/inbound-agent:ltsc2022
$global:VERSION = Get-EnvOrDefault 'VERSION' ''

Write-Host "= TESTS: Preparing $global:IMAGE_NAME with Remoting $global:VERSION"

$imageItems = $global:IMAGE_NAME.Split(':')
$GLOBAL:IMAGE_TAG = $imageItems[1]

$items = $global:IMAGE_TAG.Split('-')
# Remove the 'jdk' prefix (3 first characters)
$global:JAVARELEASE = $items[0].Remove(0,3)
$global:WINDOWSFLAVOR = $items[1]
$global:WINDOWSVERSIONTAG = $items[2]

$random = Get-Random
$global:CONTAINERNAME = 'pester-jenkins-inbound-agent_{0}_{1}' -f $global:IMAGE_TAG, $random
Write-Host "= TESTS: container name $global:CONTAINERNAME"

$global:CONTAINERSHELL = 'powershell.exe'
if ($global:WINDOWSFLAVOR -eq 'nanoserver') {
    $global:CONTAINERSHELL = 'pwsh.exe'
}

# # Uncomment to help debugging when working on this script
# Write-Host "= DEBUG: global vars"
# Get-Variable -Scope Global | ForEach-Object { Write-Host "$($_.Name) = $($_.Value)" }
# Write-Host "= DEBUG: env vars"
# Get-ChildItem Env: | ForEach-Object { Write-Host "$($_.Name) = $($_.Value)" }

Cleanup($global:CONTAINERNAME)
Cleanup('ncat-helper')
CleanupNetwork('jnlp-network')

Describe "[$global:IMAGE_NAME] build image" {
    It 'builds image' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' "build --build-arg `"VERSION=${global:VERSION}`" --build-arg `"JAVA_RELEASE=${global:JAVARELEASE}`" --build-arg `"WINDOWS_VERSION_TAG=${global:WINDOWSVERSIONTAG}`" --tag=${global:IMAGE_TAG} --file ./windows/${global:WINDOWSFLAVOR}/Dockerfile ."
        $exitCode | Should -Be 0
    }
}

Describe "[$global:IMAGE_NAME] debug" {
    It 'diagnoses nested PowerShell initialization' {
        $debugScript = @'
Write-Output "=== Parent PowerShell ==="
Write-Output "PSVersion: $($PSVersionTable.PSVersion)"
Write-Output "PSHOME: [$PSHOME]"
Write-Output "PSModulePath: [$env:PSModulePath]"
Write-Output "USERPROFILE: [$env:USERPROFILE]"
Write-Output "HOME: [$env:HOME]"

Write-Output "`n=== PowerShell-related environment variables ==="
Get-ChildItem Env: |
    Where-Object Name -Match '^(PS|HOME|USERPROFILE)' |
    Sort-Object Name |
    Format-Table -AutoSize |
    Out-String |
    Write-Output

Write-Output "`n=== Registry environment values ==="
$registryPaths = @(
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    'HKCU:\Environment'
)

foreach ($path in $registryPaths) {
    Write-Output "--- $path ---"
    if (Test-Path $path) {
        Get-ItemProperty -Path $path |
            Format-List * |
            Out-String |
            Write-Output
    }
    else {
        Write-Output "Registry path does not exist"
    }
}

Write-Output "`n=== PSHOME Modules directory ==="
Write-Output "Exists: $(Test-Path "$PSHOME\Modules")"
Get-ChildItem "$PSHOME\Modules" -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name |
    Write-Output

Write-Output "`n=== Child PowerShell: inherited PSModulePath ==="
& pwsh.exe -NoLogo -NoProfile -Command "Write-Output 'CHILD_DEFAULT_STARTED'; exit 0"
Write-Output "Child default exit code: $LASTEXITCODE"

Write-Output "`n=== Child PowerShell: explicit PSModulePath ==="
$env:PSModulePath = "$PSHOME\Modules"
Write-Output "Overridden PSModulePath: [$env:PSModulePath]"

& pwsh.exe -NoLogo -NoProfile -Command "Write-Output 'CHILD_OVERRIDE_STARTED'; exit 0"
Write-Output "Child override exit code: $LASTEXITCODE"

Write-Output "`n=== Parent staying alive ==="
Start-Sleep -Seconds 300
'@

        # Use -EncodedCommand to avoid multiple layers of Windows/Docker/PowerShell quoting.
        $encodedScript = [Convert]::ToBase64String(
            [System.Text.Encoding]::Unicode.GetBytes($debugScript)
        )

        $exitCode, $stdout, $stderr = Run-Program 'docker' "run --detach --tty --entrypoint $global:CONTAINERSHELL --name $global:CONTAINERNAME $global:IMAGE_NAME -NoLogo -NoProfile -EncodedCommand $encodedScript"

        $exitCode | Should -Be 0

        Start-Sleep -Seconds 3

        Write-Host "`n=== Container state ==="
        docker inspect --format '{{.State.Status}} (exit code: {{.State.ExitCode}})' $global:CONTAINERNAME | Out-Host

        Write-Host "`n=== Container logs ==="
        docker logs $global:CONTAINERNAME | Out-Host

        Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
    }
}

Describe "[$global:IMAGE_NAME] check default user account" {
    BeforeAll {
        docker run --detach --tty --name "$global:CONTAINERNAME" "$global:IMAGE_NAME" -Cmd "$global:CONTAINERSHELL"
        $LASTEXITCODE | Should -Be 0
        Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
    }

    It 'has a password that never expires' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"if ((net user jenkins | Select-String -Pattern 'Password expires') -match 'Never') { exit 0 } else { net user jenkins ; exit -1 }`""
        $exitCode | Should -Be 0
    }

    It 'has password policy of "not required"' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"if ((net user jenkins | Select-String -Pattern 'Password required') -match 'No') { exit 0 } else { net user jenkins ; exit -1 }`""
        $exitCode | Should -Be 0
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
    }
}

Describe "[$global:IMAGE_NAME] image has jenkins-agent.ps1 in the correct location" {
    BeforeAll {
        docker run --detach --tty --name "$global:CONTAINERNAME" "$global:IMAGE_NAME" -Cmd "$global:CONTAINERSHELL"
        $LASTEXITCODE | Should -Be 0
        Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
    }

    It 'has jenkins-agent.ps1 in C:/ProgramData/Jenkins' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"if (Test-Path 'C:/ProgramData/Jenkins/jenkins-agent.ps1') { exit 0 } else { exit 1 }`""
        $exitCode | Should -Be 0
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
    }
}

Describe "[$global:IMAGE_NAME] image starts jenkins-agent.ps1 correctly (slow test)" {
    It 'connects to the ncat-helper container' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' 'network create --driver nat jnlp-network'
        Start-NcatContainer -windowsVersionTag $global:WINDOWSVERSIONTAG -networkName 'jnlp-network'

        $exitCode, $stdout, $stderr = Run-Program 'docker' "inspect --format `"{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}`" ncat-helper"
        $exitCode | Should -Be 0
        $ncat_ip = $stdout.Trim()

        $secret = "aaa"
        $name = "bbb"
        $exitCode, $stdout, $stderr = Run-Program 'docker' "run --detach --tty --network=jnlp-network --name $global:CONTAINERNAME $global:IMAGE_NAME -Url http://${ncat_ip}:5000 $secret $name"
        $exitCode | Should -Be 0
        Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue

        $exitCode, $stdout, $stderr = Run-Program 'docker' 'wait ncat-helper'
        $exitCode, $stdout, $stderr = Run-Program 'docker' 'logs ncat-helper'
        $exitCode | Should -Be 0
        $stdout | Should -Match "GET /tcpSlaveAgentListener/ HTTP/1.1"
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
        Cleanup('ncat-helper')
        CleanupNetwork('jnlp-network')
    }
}

Describe "[$global:IMAGE_NAME] custom build args" {
    BeforeAll {
        Push-Location -StackName 'agent' -Path "$PSScriptRoot/.."
        # Old version used to test overriding the build arguments.
        # This old version must have the same tag suffixes as the current windows images (`-jdk25-nanoserver` etc.), and the same Windows version
        $TEST_VERSION = '3206.vb_15dcf73f6a_9'
        $customImageName = "custom-${global:IMAGE_NAME}"
    }

    It 'builds image with arguments' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' "build --build-arg `"VERSION=${TEST_VERSION}`" --build-arg `"JAVA_RELEASE=${global:JAVARELEASE}`" --build-arg `"WINDOWS_VERSION_TAG=${global:WINDOWSVERSIONTAG}`" --build-arg WINDOWS_FLAVOR=${global:WINDOWSFLAVOR} --build-arg CONTAINER_SHELL=${global:CONTAINERSHELL} --tag=${customImageName} --file=./windows/${global:WINDOWSFLAVOR}/Dockerfile ."
        $exitCode | Should -Be 0

        $exitCode, $stdout, $stderr = Run-Program 'docker' "run --detach --tty --name $global:CONTAINERNAME $customImageName -Cmd $global:CONTAINERSHELL"
        $exitCode | Should -Be 0
        Is-ContainerRunning "$global:CONTAINERNAME" | Should -BeTrue
    }

    It 'has the correct agent.jar version' {
        $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -c `"java -jar C:/ProgramData/Jenkins/agent.jar -version`""
        $exitCode | Should -Be 0
        $stdout | Should -Match $TEST_VERSION
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
        Pop-Location -StackName 'agent'
    }
}

Describe "[$global:IMAGE_NAME] passing JVM options (slow test)" {
    It "shows the java version ${global:JAVARELEASE} with --show-version" {
        $exitCode, $stdout, $stderr = Run-Program 'docker' 'network create --driver nat jnlp-network'
        Start-NcatContainer -windowsVersionTag $global:WINDOWSVERSIONTAG -networkName 'jnlp-network'

        $exitCode, $stdout, $stderr = Run-Program 'docker' "inspect --format `"{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}`" ncat-helper"
        $exitCode | Should -Be 0
        $ncat_ip = $stdout.Trim()

        $secret = 'aaa'
        $name = 'bbb'
        $exitCode, $stdout, $stderr = Run-Program 'docker' "run --detach --tty --network=jnlp-network --name $global:CONTAINERNAME $global:IMAGE_NAME -Url http://${ncat_ip}:5000 -JenkinsJavaOpts `"--show-version`" $secret $name"
        $exitCode | Should -Be 0
        Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
        Start-Sleep -Seconds 20
        $exitCode, $stdout, $stderr = Run-Program 'docker' "logs $global:CONTAINERNAME"
        $exitCode | Should -Be 0
        $stdout | Should -Match "OpenJDK Runtime Environment Temurin-${global:JAVARELEASE}"
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
        Cleanup('ncat-helper')
        CleanupNetwork('jnlp-network')
    }
}
