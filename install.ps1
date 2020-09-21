param(
    [string]
    $jreURI,
    [string]
    $jreName
)

# init log setting
$logLoc = "$env:SystemDrive\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\"
if (! (Test-Path($logLoc)))
{
    New-Item -path $logLoc -type directory -Force
}
$logPath = "$logLoc\tracelog.log"
"Start to excute jre.ps1. `n" | Out-File $logPath

function Now-Value()
{
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Throw-Error([string] $msg)
{
	try
	{
		throw $msg
	}
	catch
	{
		$stack = $_.ScriptStackTrace
		Trace-Log "DMDTTP is failed: $msg`nStack:`n$stack"
	}

	throw $msg
}

function Trace-Log([string] $msg)
{
    $now = Now-Value
    try
    {
        "${now} $msg`n" | Out-File $logPath -Append
    }
    catch
    {
        #ignore any exception during trace
    }

}

function Download-File([string] $url, [string] $path)
{
    try
    {
        $ErrorActionPreference = "Stop";
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $path)
        Trace-Log "Download file successfully. Location: $path"
    }
    catch
    {
        Trace-Log "Fail to download file"
        Trace-Log $_.Exception.ToString()
        throw
    }
}

function Install-JRE([string] $jrePath, [string] $jreName)
{
	if ([string]::IsNullOrEmpty($jrePath) -Or [string]::IsNullOrEmpty($jreName))
    {
		Throw-Error "JRE path or name not specified"
    }

	if (!(Test-Path -Path $jrePath))
	{
		Throw-Error "Invalid JRE path: $jrePath"
	}

	Trace-Log "Start JRE installation"

    Expand-Archive -Force -Path $jrePath -DestinationPath .

    [System.Environment]::SetEnvironmentVariable('PATH', "$env:Path;$PWD\$jreName\bin", [System.EnvironmentVariableTarget]::Machine)
    [System.Environment]::SetEnvironmentVariable('JAVA_HOME', "$PWD\$jreName\bin", [System.EnvironmentVariableTarget]::Machine)

    $env:Path += "$PWD\$jreName\bin"

    echo $env:JAVA_HOME
    echo $env:Path

    java -version

	Start-Sleep -Seconds 10

	Trace-Log "Installation of JRE is successful"
}


Trace-Log "Log file: $logLoc"
Trace-Log "Java Runtime Environment from: $jreURI"
$jrePath= "$PWD\jre.zip"
Trace-Log "Java Runtime Environment location: $jrePath"

Download-File $jreURI $jrePath
Install-JRE $jrePath $jreName
