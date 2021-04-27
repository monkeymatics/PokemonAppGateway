# Call from repository root e.g:
#   C:\Git\<project-folder>
#
# Example usage:
# . "./Deployment-Funcs.ps1"; Build
# . "./Deployment-Funcs.ps1"; Deploy -Environment jd-stack
function Build {
  yarn run build
}

function Deploy([string]$Environment, [switch]$Rebuild) {

  $vars = loadVarsForEnvironment "$($Environment.ToLower())"

  if($vars){
	  
	if ($Rebuild) {
	Build
	}

	$stackName = $vars.StackNamePrefix + $vars.StackName

	$AWSProfile = $vars.ProfileName
	if (!$AWSProfile) {    $AWSProfile = 'default' }

	$BuildVersion = Get-Date -UFormat "%y%j%H%M%S"

	# Start deployment by updating the CFTs and Swagger definitions to S3
	uploadArtifacts $vars $BuildVersion $AWSProfile

	$deployCmd = "aws cloudformation deploy --profile $AWSProfile --stack-name $stackName --template-file cloud-formation/main.yaml --no-fail-on-empty-changeset --capabilities CAPABILITY_IAM"

	$deployCmd += " --parameter-overrides"

	foreach ($key in $vars.Keys) {
	$deployCmd += " $($key)=$($vars[$key])"
	}

	# This is used to force update if the template hasn't changed
	$deployCmd += " BuildVersion=$BuildVersion"

	Write-Host $deployCmd

	Invoke-Expression $deployCmd

	deployApi $AWSProfile $vars
  }else{
    Write-Host "Deployment was unsuccessful because environment variable was not found" 
  }
}

function loadVarsForEnvironment([string]$Environment) {
  $varFile = "stack-profiles/$Environment.json"
  loadJsonFile $varFile
}

function deployApi([string]$profile, $vars)
{
  Write-Host "aws apigateway get-rest-apis --profile $profile"
  $jsonObj = aws apigateway get-rest-apis --profile $profile |ConvertFrom-Json
  
  $api = $jsonObj.items | Where-Object { $_.name -eq "$($vars.StackNamePrefix)$($vars.StackName)" }
  
  $apiId = $api.id
  $stageName = $vars.StageName
  
  Write-Host "aws apigateway create-deployment --rest-api-id $apiId --stage-name $stageName --profile $profile"
  aws apigateway create-deployment --rest-api-id $apiId --stage-name $stageName --profile $profile
}

# Load a jsonfile as a Hashtable
function loadJsonFile([string]$FilePath) {
  $obj = Get-Content -Raw -Path $FilePath | ConvertFrom-Json
  objectToHashtable $obj
}

# Convert a CustomPsObject to a Hashtable
function objectToHashtable($Object) {
  $table = @{}

  $Object.psobject.properties | ForEach-Object { $table[$_.Name] = $_.Value }

  $table
}

function uploadArtifacts($Vars, [string]$BuildVersion, [string]$AWSProfile) {
  aws s3 cp "build-artifacts" "s3://$($Vars['ArtifactsS3Bucket'])/$($Vars['ArtifactsS3Prefix'])/$BuildVersion/build-artifacts" --recursive --exclude "*" --include "*.yaml" --profile $AWSProfile
}
