function Add-VSTeamWorkItem {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$Title,

      [Parameter(Mandatory = $false)]
      [string]$Description,

      [Parameter(Mandatory = $false)]
      [string]$IterationPath,

      [Parameter(Mandatory = $false)]
      [string]$AreaPath,

      [Parameter(Mandatory = $false)]
      [string]$AssignedTo,

      # The tags parameter can tokenised by semi-colon followed by a space to create multiple tags on a work item e.g. "Tag 1; Tag 2; Fred" creates three tags
      [Parameter(Mandatory = $false)]
      [string]$Tags,

      # Original Estimate is in hours and will appear in the original estimate field in Azure DevOps
      [Parameter(Mandatory = $false)]
      [int]$OriginalEstimate,

      # Remaining Work is in hours and will appear in the remaining work field in Azure DevOps
      [Parameter(Mandatory = $false)]
      [int]$RemainingWork,

      [Parameter(Mandatory = $false)]
      [int]$ParentId,

      [Parameter(Mandatory = $false)]
      [int]$ChildId,

      [Parameter(Mandatory = $false)]
      [int]$PredecessorId,

      [Parameter(Mandatory = $false)]
      [int]$SuccessorId,

      [Parameter(Mandatory = $false)]
      [int]$RelatedId
   )

   DynamicParam {
      $dp = _buildProjectNameDynamicParam -mandatory $true

      # If they have not set the default project you can't find the
      # validateset so skip that check. However, we still need to give
      # the option to pass a WorkItemType to use.
      if ($Global:PSDefaultParameterValues["*:projectName"]) {
         $wittypes = _getWorkItemTypes -ProjectName $Global:PSDefaultParameterValues["*:projectName"]
         $arrSet = $wittypes
      }
      else {
         Write-Verbose 'Call Set-VSTeamDefaultProject for Tab Complete of WorkItemType'
         $wittypes = $null
         $arrSet = $null
      }

      $ParameterName = 'WorkItemType'
      $rp = _buildDynamicParam -ParameterName $ParameterName -arrSet $arrSet -Mandatory $true
      $dp.Add($ParameterName, $rp)

      $dp
   }

   Process {
      # Bind the parameter to a friendly variable
      $ProjectName = $PSBoundParameters["ProjectName"]

      # The type has to start with a $
      $WorkItemType = "`$$($PSBoundParameters["WorkItemType"])"

      # Constructing the contents to be send.
      # Empty parameters will be skipped when converting to json.
      $body = @(
         @{
            op    = "add"
            path  = "/fields/System.Title"
            value = $Title
         }
         @{
            op    = "add"
            path  = "/fields/System.Description"
            value = $Description
         }
         @{
            op    = "add"
            path  = "/fields/System.IterationPath"
            value = $IterationPath
         }
         @{
            op    = "add"
            path  = "/fields/System.AreaPath"
            value = $AreaPath
         }
         @{
            op    = "add"
            path  = "/fields/System.Tags"
            value = $Tags
         }
         @{
            op    = "add"
            path  = "/fields/Microsoft.VSTS.Scheduling.OriginalEstimate"
            value = $OriginalEstimate
         }
         @{
            op    = "add"
            path  = "/fields/Microsoft.VSTS.Scheduling.RemainingWork"
            value = $RemainingWork
         }
         @{
            op    = "add"
            path  = "/fields/System.AssignedTo"
            value = $AssignedTo
         }) | Where-Object { $_.value}

         # details on "relations" can be found at the URL below
         # https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/work%20item%20relation%20types/list?view=azure-devops-rest-5.0

         if ($ChildId) {
            $childUri = _buildRequestURI -ProjectName $ProjectName -Area 'wit' -Resource 'workitems' -id $ChildId
            $body += @{
               op    = "add"
               path  = "/relations/-"
               value = @{
                  "rel" = "System.LinkTypes.Hierarchy-Forward"
                  "url" = $childUri
               }
            }
         }

         if ($ParentId) {
            $parentUri = _buildRequestURI -ProjectName $ProjectName -Area 'wit' -Resource 'workitems' -id $ParentId
            $body += @{
               op    = "add"
               path  = "/relations/-"
               value = @{
                  "rel" = "System.LinkTypes.Hierarchy-Reverse"
                  "url" = $parentURI
               }
            }
         }

         if ($PredecessorId) {
            $predecessorUri = _buildRequestURI -ProjectName $ProjectName -Area 'wit' -Resource 'workitems' -id $PredecessorId
            $body += @{
               op    = "add"
               path  = "/relations/-"
               value = @{
                  "rel" = "System.LinkTypes.Dependency-Reverse"
                  "url" = $predecessorUri
               }
            }
         }

         if ($SuccessorId) {
            $successorUri = _buildRequestURI -ProjectName $ProjectName -Area 'wit' -Resource 'workitems' -id $SuccessorId
            $body += @{
               op    = "add"
               path  = "/relations/-"
               value = @{
                  "rel" = "System.LinkTypes.Dependency-Forward"
                  "url" = $successorUri
               }
            }
         }

         if ($RelatedId) {
            $relatedUri = _buildRequestURI -ProjectName $ProjectName -Area 'wit' -Resource 'workitems' -id $RelatedId
            $body += @{
               op    = "add"
               path  = "/relations/-"
               value = @{
                  "rel" = "System.LinkTypes.Related"
                  "url" = $relatedUri
               }
            }
         }

      # It is very important that even if the user only provides
      # a single value above that the item is an array and not
      # a single object or the call will fail.
      # You must call ConvertTo-Json passing in the value and not
      # not using pipeline.
      # https://stackoverflow.com/questions/18662967/convertto-json-an-array-with-a-single-item
      $json = ConvertTo-Json @($body) -Compress

      # Call the REST API
      $resp = _callAPI -ProjectName $ProjectName -Area 'wit' -Resource 'workitems' `
         -Version $([VSTeamVersions]::Core) -id $WorkItemType -Method Post `
         -ContentType 'application/json-patch+json' -Body $json

      _applyTypesToWorkItem -item $resp

      return $resp
   }
}