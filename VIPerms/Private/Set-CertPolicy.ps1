function SkipTLSLegacy {
    try {
        [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls"
        [Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    } catch {
        $Err = $_
        if ($Err.Exception.Message.StartsWith("Cannot find type [TrustAllCertsPolicy]")) {
            Add-Type -TypeDefinition  @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
            [Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        } else {
            throw $Err
        }
    }
}

function SkipTLSCoreEdition {
    # Invoke-restmethod provide Skip certcheck param in PowerShell Core
    $Script:PSDefaultParameterValues = @{
        "invoke-restmethod:SkipCertificateCheck" = $true
        "invoke-webrequest:SkipCertificateCheck" = $true
    }    
}

function Set-CertPolicy {
    <#
    .SYNOPSIS
    Ignore SSL verification.
    
    .DESCRIPTION
    Using a custom .NET type, override SSL verification policies.

    #>

    param (
        [Switch] $SkipCertificateCheck,
        [Switch] $ResetToDefault
    )

    try {
        if ($SkipCertificateCheck) {
            if ($PSVersionTable.PSEdition -eq 'Core') {
                SkipTLSCoreEdition
            } else {
                SkipTLSLegacy 
            }
        }
    } catch {
        $Err = $_
        throw $Err
    }
}