[CmdletBinding()]
Param()

# cSpell:ignore steamcmd_servers winmm.zip

Begin {
  Write-Host -Object "`$env:pwsh_DEBUG = $($env:pwsh_DEBUG) & $($env:pwsh_DEBUG.GetType()) & $($env:pwsh_DEBUG -eq $True)";
  If ($env:pwsh_DEBUG -eq $True) {
    $DebugPreference = "Continue"
  }
  Write-Host -Object "`$env:pwsh_VERBOSE = $($env:pwsh_VERBOSE) & $($env:pwsh_VERBOSE.GetType()) & $($env:pwsh_VERBOSE -eq $True)";
  If ($env:pwsh_VERBOSE -eq $True) {
    $VerbosePreference = "Continue"
  }

  Function Write-Log {
    [CmdletBinding(DefaultParameterSetName = "Message")]
    Param(
      # Specifies a message to write to console with.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ParameterSetName = "Message",
                 ValueFromPipeline = $True,
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "A message to write to console with.")]
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ParameterSetName = "Exception",
                 ValueFromPipeline = $True,
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "A message to write to console with.")]
      [Alias("Object")]
      [ValidateNotNullOrEmpty()]
      [System.String[]]
      $Message,
      # Specifies a logging level to log at.
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Message",
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "A logging level to log at. Defaults `"Info`"")]
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Exception",
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "A logging level to log at. Defaults `"Info`"")]
      [Alias("Level")]
      [ValidateSet("Verbose","Trace","Debug","Info","Information","Warn","Warning","Error","Exception","Fatal")]
      [System.String]
      $LogLevel = "Info",
      # Specifies an instance of an exception.
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Exception",
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "An instance of an exception.")]
      [Alias("Error")]
      [System.Exception]
      $Exception = $Null
    )

    [System.String]$LogDate = [System.DateTime]::Now.ToString("[yyyy-MM--dd HH:mm:ss.fff K]")

    If ($LogLevel -eq "Verbose" -and $VerbosePreference -ne "SilentlyContinue") {
      Write-Host -ForegroundColor Yellow     -NoNewLine -Object "$($LogDate) [VRB] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
    } ElseIf ($LogLevel -eq "Trace" -and $VerbosePreference -ne "SilentlyContinue") {
      Write-Host -ForegroundColor DarkGray   -NoNewLine -Object "$($LogDate) [TRA] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
    } ElseIf ($LogLevel -eq "Debug" -and $DebugPreference -ne "SilentlyContinue") {
      Write-Host -ForegroundColor Gray       -NoNewLine -Object "$($LogDate) [DBG] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
    } ElseIf ($LogLevel -eq "Info") {
      Write-Host -ForegroundColor Blue       -NoNewLine -Object "$($LogDate) [INF] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
    } ElseIf ($LogLevel -eq "Warn" -or $LogLevel -eq "Warning") {
      Write-Host -ForegroundColor DarkYellow -NoNewLine -Object "$($LogDate) [WRN] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
    } ElseIf ($LogLevel -eq "Error" -or $LogLevel -eq "Exception") {
      Write-Host -ForegroundColor Red        -NoNewLine -Object "$($LogDate) [ERR] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
      If ($Null -ne $Exception) {
        Write-Host -ForegroundColor DarkRed             -Object "$($Exception.Message)"                    | Out-Host;
        Write-Host -ForegroundColor DarkRed             -Object "$($Exception.StackTrace)"                 | Out-Host;
      }
    } ElseIf ($LogLevel -eq "Fatal") {
      Write-Host -ForegroundColor DarkRed    -NoNewLine -Object "$($LogDate) [FTL] "                       | Out-Host;
      Write-Host -ForegroundColor White                 -Object "$([System.String]::Join("`n", $Message))" | Out-Host;
      If ($Null -ne $Exception) {
        Write-Host -ForegroundColor DarkRed             -Object "$($Exception.Message)"                    | Out-Host;
        Write-Host -ForegroundColor DarkRed             -Object "$($Exception.StackTrace)"                 | Out-Host;
      }
    }
  }

  $DocumentationDir = (Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "documentation");
  $InFilePath = (Join-Path -Path $DocumentationDir -ChildPath "README.md");
  $CurrentDir = (Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "current");
  $OutFilePath = (Join-Path -Path $CurrentDir -ChildPath "game_eggs" -AdditionalChildPath @("steamcmd_servers", "palworld", "binaries", "winmm.zip"));
  [Collections.Generic.Dictionary[System.String, System.DateTime]]$Data = @{};
  $Data["Documentation"] = $Null;
  $Data["Current"] = $Null;
}
Process {
  #Catch {
  #  Write-Host -ForegroundColor Red -Message "Failed to run PowerShell task. Exiting...`n$($_.Exception.Message)`n$($_.Exception.StackTrace)" | Out-Host;
  #  Write-Error -Message $_.Exception.Message -Exception $_.Exception | Out-Host;
  #  Exit 1;
  #}
  Function Get-GitLogDate {
    [CmdletBinding(DefaultParameterSetName = "Path")]
    Param(
      # Specifies a path to a file in a git repository.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 ParameterSetName = "Path",
                 ValueFromPipeline = $True,
                 ValueFromPipelineByPropertyName = $True,
                 HelpMessage = "A path to a file in a git repository.")]
      [Alias("PSPath")]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $Path,
      # Specifies a format for git log.
      [Parameter(Mandatory = $False,
                 ParameterSetName = "Path",
                 HelpMessage = "A format for git log. Defaults to `"format:%ct`"")]
      [ValidateNotNullOrEmpty()]
      [System.String]
      $Format = "format:%ct"
    )
    [System.String]$OutputDate = (git log -1 --pretty="$($Format)" "$($Path)");

    If ([System.String]::IsNullOrEmpty($OutputDate) -or $OutputDate -eq "") {
      Throw "The command ``git log -1 --pretty=`"format:%ct`" `"$($Path)`` did not return a valid date.`n`$OutputDate = `"$OutputDate`"";
    }

    [System.Int64]$OutputLong = 0;

    Try {
      $OutputLong = [System.Int64]::Parse($OutputDate)
    } Catch {
      Write-Log -Level Error -Message "Failed to parse `"$($OutputDate)`" into a [System.Int64]." -Exception $_.Exception.Message;
      Throw
    }

    Return [System.DateTimeOffset]::FromUnixTimeSeconds($OutputLong);
  }

  Push-Location -Path $DocumentationDir;
  $Data.Documentation = (Get-GitLogDate -Path $InFilePath)
  Pop-Location;

  Push-Location -Path $CurrentDir;
  $Data.Current = (Get-GitLogDate -Path $OutFilePath)
  Pop-Location;

  Write-Log -Level Debug -Message "Documentation=$($Data.Documentation) | Current=$($Data.Current) | Boolean=$($Data.Documentation -lt $Data.Current)";

  If ($Data.Documentation -lt $Data.Current) {
    Function Select-UrlString {
      [CmdletBinding()]
      Param(
        # Specifies a path of one url.
        [Parameter(Mandatory = $True,
                   Position = 0,
                   ParameterSetName="Path",
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   HelpMessage="Path of one file with a url.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
      )

      $Content = (Get-Content -Path $Path -Raw);
      $ContentMatches = ($Content | Select-String -Pattern "\[([^\]]+)\]\((https:\/\/[^\)]+)\)" -AllMatches);
      $Groups = $ContentMatches.Matches.Groups;

      $Property_Alt = @{
        Name="Alt";
        Expression={
          $Item = $_;
          $ItemGroups = ($Item | Where-Object {
            Return (($_ | Get-Member).Name -contains "Groups");
          });

          Return @($ItemGroups.Groups[1].Value);
        }
      };

      $Property_Uri = @{
        Name="Uri";
        Expression={
          $Item = $_;
          $ItemGroups = ($Item | Where-Object {
            Return (($_ | Get-Member).Name -contains "Groups");
          });

          Return @($ItemGroups.Groups[2].Value);
        }
      };

      $Uri = ($Groups | Select-Object @($Property_Alt, $Property_Uri) | Where-Object {
        If ($Null -eq $_ -or $Null -eq $_.Uri) {
          Return $False
        };

        Return $_.Uri.EndsWith("winmm.zip")
      });

      Return $Uri
    }

    $SelectedString = (Select-UrlString -Path $InFilePath);

    If ($Null -ne $SelectedString) {
      $DownloadLink = $SelectString.Url;
    } Else {
      Throw "Failed to get Uri to download winmm.zip"
    }

    Try {
      $Web = (Invoke-WebRequest -Uri "$($DownloadLink)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -ErrorAction SilentlyContinue);

      If ($Web.StatusCode -eq 200) {
        If (-not (Test-Path -Path $OutFilePath -PathType Leaf)) {
          New-Item -ItemType File -Path $OutFilePath;
        }

        Set-Content $OutFilePath -Value $Web.Content -AsByteStream;
      } Else {
        Throw "Failed to Invoke-WebRequest, got status code $($Web.StatusCode)";
      }
    } Catch {
      Write-Log -Level Error -Message "Failed to download file from `"$($DownloadLink)`"." -Exception $_.Exception;
      Throw;
    }

  } else {
    Write-Output "DoUpdate=0" >> $Env:GITHUB_OUTPUT
    Exit 0;
  }
}
End {
  Write-Output "DoUpdate=1" >> $Env:GITHUB_OUTPUT
  Write-Log -Level Info -Message "Completed successfully."
  Exit 0;
}
