function Get-HeaderValue {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Headers,
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$DefaultValue
    )

    # Convert headers to case-insensitive for lookup
    $headerDict = @{}
    $Headers.GetEnumerator() | ForEach-Object {
        $headerDict[$_.Key.ToLower()] = $_.Value
    }

    # Look up using lowercase name
    $lookupName = $Name.ToLower()
    if ($headerDict.ContainsKey($lookupName)) {
        return $headerDict[$lookupName]
    }
    return "$DefaultValue"
}