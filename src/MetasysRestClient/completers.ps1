function Get-MetasysCachedItemReferences {
    param ( $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters )

    $cache = GetCacheObject -MetasysHost ([MetasysEnvVars]::getSiteHost())

    $quotesNeeded = $false
    foreach ($reference in $cache.Keys) {
        if ($reference.Contains(" ")) {
            $quotesNeeded = $true
            break
        }
    }

    foreach ($reference in $cache.Keys) {
        if ($reference -like "*$wordToComplete*") {
            if ($quotesNeeded) {
                $reference = "`"$reference`""
            }
            [System.Management.Automation.CompletionResult]::new($reference, $reference, [System.Management.Automation.CompletionResultType]::ParameterValue, $reference)
        }
    }
}

function Get-MetasysCachedObjectIds {
    param ( $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters )

    $cache = GetCacheObject -MetasysHost ([MetasysEnvVars]::getSiteHost())

    foreach ($reference in $cache.Keys) {
        $id = $cache[$reference]
        if ($id -like "$wordToComplete*") {
            [System.Management.Automation.CompletionResult]::new($id, "$id, $reference", [System.Management.Automation.CompletionResultType]::ParameterValue, $id)
        }
    }
}

Register-ArgumentCompleter -CommandName "Invoke-MetasysReadAttribute" -ParameterName "ItemReference" -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-MetasysCachedItemReferences $commandName $parameterName $wordToComplete $commandAst $fakeBoundParameters
}

Register-ArgumentCompleter -CommandName "Invoke-MetasysReadAttribute" -ParameterName "ObjectId" -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-MetasysCachedObjectIds $commandName $parameterName $wordToComplete $commandAst $fakeBoundParameters
}

Export-ModuleMember -Function "Get-MetasysCachedItemReferences", "Get-MetasysCachedObjectIds"
