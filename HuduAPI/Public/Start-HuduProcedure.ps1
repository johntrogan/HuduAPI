function Start-HuduProcedure {
    <#
    .SYNOPSIS
    Start a run from an existing company procedure.

    .DESCRIPTION
    Creates a new run by calling POST /api/v1/procedures/{id}/kickoff.

    Only company procedures can be kicked off.
    Global templates must first be copied to a company procedure.
    If the target is already a run, kickoff is not performed.

    .PARAMETER ProcedureId
    ID of the procedure to kick off.

    .PARAMETER AssetId
    Optional asset ID to associate with the new run.

    .PARAMETER Name
    Optional name for the new run.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Id')]
        [int]$ProcedureId,

        [int]$AssetId,

        [string]$Name
    )

    $procedureContext = Get-HuduProcedureContext -ProcedureId $ProcedureId
    if (-not $procedureContext) {
        throw "Could not determine procedure context for procedure ID $ProcedureId."
    }

    if ($procedureContext.IsRun) {
        Write-Warning "Procedure ID $ProcedureId is already a run. Kick off is not applicable."
        return $null
    }


    if ($procedureContext.CanKickoff -ne $true) {
        Write-Warning "Procedure ID $ProcedureId cannot be kicked off. Ensure it is a company procedure and not already a run."
        return $null
    }

    if (
        $procedureContext.IsGlobal -or
        $procedureContext.ProcessType -eq 'global' -or
        [string]::IsNullOrWhiteSpace([string]$procedureContext.CompanyId)
    ) {
        Write-Warning "Procedure ID $ProcedureId is a global template. It must be copied to a company procedure before it can be kicked off."
        return $null
    }    

    $params = @{}
    if ($PSBoundParameters.ContainsKey('AssetId')) { $params.asset_id = $AssetId }
    if ($PSBoundParameters.ContainsKey('Name'))    { $params.name = $Name }

    try {
        
        $r = Invoke-HuduRequest -Method POST -Resource "/api/v1/procedures/$ProcedureId/kickoff" -Params $params
        return ($r.procedure ?? $r)
    }
    catch {
        Write-Warning "Failed to kick off procedure ID $ProcedureId- $($_.Exception.Message)"
        return $null
    }
}