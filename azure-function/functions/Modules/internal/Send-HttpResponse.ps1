using namespace System.Net

function Send-BadRequest {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = $Message | ConvertTo-Json -Depth 5
        }
    )
}

function Send-Unauthorized {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Unauthorized
            Body       = $Message | ConvertTo-Json -Depth 5
        }
    )
}

function Send-MethodNotAllowed {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::MethodNotAllowed
            Body       = $Message | ConvertTo-Json -Depth 5
        }
    )
}

function Send-InternalServerError {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body       = $Message | ConvertTo-Json -Depth 5
        }
    )
}

function Send-OkResponse {
    param(
        [Parameter(Mandatory)]
        [object]$Body
    )

    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $Body | ConvertTo-Json -Depth 5
        }
    )
}