function Get-FileContent {
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileBytes,
        [Parameter(Mandatory)]
        [string]$FileName
    )

    Write-Information "Processing file: $fileName"
    Write-Information "File content length: $($fileBytes.Length) bytes"
    Write-Information "Starting content extraction pipeline..."

    try {
        $documentResult = Get-DocumentContent -FileContent $fileBytes -FileName $fileName

        # Check if the filename needs to be updated with the detected extension
        $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $originalExt = [System.IO.Path]::GetExtension($fileName).ToLower()
        $detectedExt = $documentResult.DetectedExtension

        # If the original filename is document.bin or has no extension or .octet-stream extension,
        # update it with the detected extension
        if ($fileName -eq 'document.bin' -or [string]::IsNullOrWhiteSpace($originalExt) -or
            $originalExt -eq '.bin' -or $originalExt -eq '.octet-stream') {
            $updatedFileName = "$fileNameWithoutExt$detectedExt"
            Write-Information "Updated filename from '$fileName' to '$updatedFileName' based on detected type"
            $fileName = $updatedFileName
        }

        Write-Information "Successfully processed file: $fileName"
        return @{
            fileName = $fileName
            content  = $documentResult.Content
        }
    } catch {
        Write-Error "Failed to process file '$fileName': $_"
        throw
    }
}