$InformationPreference = "Continue"

$IsCloudLabs = Test-Path C:\LabFiles\AzureCreds.ps1;

$Load30Billion = 0
$LoadSqlPool = 0

if($IsCloudLabs){
        if(Get-Module -Name solliance-synapse-automation){
                Remove-Module solliance-synapse-automation
        }
        Import-Module "..\solliance-synapse-automation"

        . C:\LabFiles\AzureCreds.ps1

        $userName = $AzureUserName                # READ FROM FILE
        $password = $AzurePassword                # READ FROM FILE
        $clientId = $TokenGeneratorClientId       # READ FROM FILE
        #$global:sqlPassword = $AzureSQLPassword          # READ FROM FILE

        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
        
        Connect-AzAccount -Credential $cred | Out-Null

        $resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*-L400*" }).ResourceGroupName

        if ($resourceGroupName.Count -gt 1)
        {
                $resourceGroupName = $resourceGroupName[0];
        }

        $ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
        $global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
        $global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
        $global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"
        $global:ropcBodyPowerBI = "$($ropcBodyCore)&scope=https://analysis.windows.net/powerbi/api/.default"

        $artifactsPath = "..\..\"
        $notebooksPath = "..\notebooks"
        $templatesPath = "..\templates"
        $datasetsPath = "..\datasets"
        $dataflowsPath = "..\dataflows"
        $pipelinesPath = "..\pipelines"
        $sqlScriptsPath = "..\sql"
} else {
        if(Get-Module -Name solliance-synapse-automation){
                Remove-Module solliance-synapse-automation
        }
        Import-Module "..\solliance-synapse-automation"

        #Different approach to run automation in Cloud Shell
        $subs = Get-AzSubscription | Select-Object -ExpandProperty Name
        if($subs.GetType().IsArray -and $subs.length -gt 1){
                $subOptions = [System.Collections.ArrayList]::new()
                for($subIdx=0; $subIdx -lt $subs.length; $subIdx++){
                        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
                        $subOptions.Add($opt)
                }
                $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
                $selectedSubName = $subs[$selectedSubIdx]
                Write-Information "Selecting the $selectedSubName subscription"
                Select-AzSubscription -SubscriptionName $selectedSubName

                az account set --subscription $selectedSubName
        }

        $resourceGroupName = Read-Host "Enter the resource group name";
        
        $userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
        
        #$global:sqlPassword = Read-Host -Prompt "Enter the SQL Administrator password you used in the deployment" -AsSecureString
        #$global:sqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($sqlPassword))

        $artifactsPath = "..\..\"
        $noteBooksPath = "..\notebooks"
        $templatesPath = "..\templates"
        $datasetsPath = "..\datasets"
        $dataflowsPath = "..\dataflows"
        $pipelinesPath = "..\pipelines"
        $sqlScriptsPath = "..\sql"
}

Write-Information "Using $resourceGroupName";

$uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$global:logindomain = (Get-AzContext).Tenant.Id;

$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asa.sql.admin"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""
$global:powerbiToken = "";

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
        PowerBI = (Get-Date -Year 1)
}

#remove need to ask for the password in script.
$sqlPasswordSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlPassword"
$sqlPassword = '';
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPasswordSecret.SecretValue)
try {
    $sqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$global:sqlPassword = $sqlPassword

Refresh-Tokens

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

Write-Information "Scale up the $($sqlPoolName) SQL pool to prepare for data import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW500c
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online

Ensure-ValidTokens $true

Write-Information "Create SQL logins in master SQL pool"

$params = @{ PASSWORD = $sqlPassword }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName "master" -FileName "01-create-logins" -Parameters $params
$result

Write-Information "Create SQL users and role assignments in $($sqlPoolName)"

$params = @{ USER_NAME = $userName }
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "02-create-users" -Parameters $params
$result

Write-Information "Create schemas in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "03-create-schemas" -Parameters $params
$result

Write-Information "Create tables in the [wwi] schema in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "04-create-tables-in-wwi-schema" -Parameters $params
$result

$dataLakeAccountKey = List-StorageAccountKeys -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName

Write-Information "Create tables in the [wwi_security] schema in $($sqlPoolName)"

$params = @{ 
        DATA_LAKE_ACCOUNT_NAME = $dataLakeAccountName  
        DATA_LAKE_ACCOUNT_KEY = $dataLakeAccountKey 
}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "06-create-tables-in-wwi-security-schema" -Parameters $params
$result

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.admin"

$linkedServiceName = $sqlPoolName.ToLower()
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                -UserName "asa.sql.admin" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.highperf"

$linkedServiceName = "$($sqlPoolName.ToLower())_highperf"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                -UserName "asa.sql.highperf" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

<# Day 1-3#>

Write-Information "Create data sets for data load in SQL pool $($sqlPoolName)"

$loadingDatasets = @{
        wwi02_date_adls = $dataLakeAccountName
                wwi02_product_adls = $dataLakeAccountName
                wwi02_sale_small_adls = $dataLakeAccountName
                wwi02_date_asa = $sqlPoolName.ToLower()
                wwi02_product_asa = $sqlPoolName.ToLower()
                wwi02_sale_small_asa = "$($sqlPoolName.ToLower())_highperf"
}

foreach ($dataset in $loadingDatasets.Keys) {
        Refresh-Tokens
        Write-Information "Creating dataset $($dataset)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $loadingDatasets[$dataset]
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Create pipeline to load the SQL pool"
Refresh-Tokens

$params = @{
        BLOB_STORAGE_LINKED_SERVICE_NAME = $blobStorageAccountName
}
$loadingPipelineName = "Setup - Load SQL Pool (global)"
$fileName = "load_sql_pool_from_data_lake"

Write-Information "Creating pipeline $($loadingPipelineName)"

$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $loadingPipelineName -FileName $fileName -Parameters $params
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Running pipeline $($loadingPipelineName)"
Refresh-Tokens

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $loadingPipelineName
$result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $result.runId
$result

Ensure-ValidTokens

Write-Information "Deleting pipeline $($loadingPipelineName)"

$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $loadingPipelineName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

foreach ($dataset in $loadingDatasets.Keys) {
        Refresh-Tokens
        Write-Information "Deleting dataset $($dataset)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $dataset
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

<# POC - Day 4 - Must be run after Day 3 content/pipeline loads#>

# Write-Information "Create wwi_poc schema and tables in $($sqlPoolName)"

# $params = @{}
# $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "16-create-poc-schema" -Parameters $params
# $result

# Write-Information "Create the [wwi_poc.Sale] table in SQL pool $($sqlPoolName)"

# $result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "17-create-wwi-poc-sale-heap" -Parameters $params
# $result

# Write-Information "Create data sets for PoC data load in SQL pool $($sqlPoolName)"

# $loadingDatasets = @{
#         wwi02_poc_customer_adls = $dataLakeAccountName
#         wwi02_poc_customer_asa = $sqlPoolName.ToLower()
# }

# foreach ($dataset in $loadingDatasets.Keys) {
#         Refresh-Tokens
#         Write-Information "Creating dataset $($dataset)"
#         $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $loadingDatasets[$dataset]
#         Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
# }

Refresh-Tokens

# Write-Information "Create pipeline to load PoC data into the SQL pool"

# $params = @{
#         BLOB_STORAGE_LINKED_SERVICE_NAME = $blobStorageAccountName
# }
# $loadingPipelineName = "Setup - Load SQL Pool"
# $fileName = "import_poc_customer_data"

# Write-Information "Creating pipeline $($loadingPipelineName)"

# $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $loadingPipelineName -FileName $fileName -Parameters $params
# Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

# Write-Information "Running pipeline $($loadingPipelineName)"

# $result = Run-Pipeline -WorkspaceName $workspaceName -Name $loadingPipelineName
# $result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $result.runId
# $result

# Write-Information "Deleting pipeline $($loadingPipelineName)"

# $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $loadingPipelineName
# Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

# foreach ($dataset in $loadingDatasets.Keys) {
#         Write-Information "Deleting dataset $($dataset)"
#         $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $dataset
#         Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
# }

Write-Information "Create tables in wwi_perf schema in SQL pool $($sqlPoolName)"

$params = @{}
$scripts = [ordered]@{
        "07-create-wwi-perf-sale-heap" = "CTAS : Sale_Heap"
}

foreach ($script in $scripts.Keys) {

        $refTime = (Get-Date).ToUniversalTime()
        Write-Information "Starting $($script) with label $($scripts[$script])"
        
        # initiate the script and wait until it finishes
        Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script -ForceReturn $true
        Wait-ForSQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Label $scripts[$script] -ReferenceTime $refTime
}

Write-Information "Scale down the $($sqlPoolName) SQL pool to DW200c after data import."

Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action scale -SKU DW200c
Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.import01"

$linkedServiceName = "$($sqlPoolName.ToLower())_import01"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                -UserName "asa.sql.import01" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.workload01"

$linkedServiceName = "$($sqlPoolName.ToLower())_workload01"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                -UserName "asa.sql.workload01" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Create linked service for SQL pool $($sqlPoolName) with user asa.sql.workload02"

$linkedServiceName = "$($sqlPoolName.ToLower())_workload02"
$result = Create-SQLPoolKeyVaultLinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $linkedServiceName -DatabaseName $sqlPoolName `
                -UserName "asa.sql.workload02" -KeyVaultLinkedServiceName $keyVaultName -SecretName $keyVaultSQLUserSecretName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId


# Write-Information "Create data sets for Lab 08"

# $datasets = @{
#         wwi02_sale_small_workload_01_asa = "$($sqlPoolName.ToLower())_workload01"
#         wwi02_sale_small_workload_02_asa = "$($sqlPoolName.ToLower())_workload02"
# }

# foreach ($dataset in $datasets.Keys) {
#         Refresh-Tokens
#         Write-Information "Creating dataset $($dataset)"
#         $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $datasets[$dataset]
#         Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
# }

# Write-Information "Create pipelines for Lab 08"

# $params = @{}
# $workloadPipelines = [ordered]@{
#         execute_business_analyst_queries = "Lab 08 - Execute Business Analyst Queries"
#         execute_data_analyst_and_ceo_queries = "Lab 08 - Execute Data Analyst and CEO Queries"
# }

# foreach ($pipeline in $workloadPipelines.Keys) {
#         Write-Information "Creating workload pipeline $($workloadPipelines[$pipeline])"
#         $result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $workloadPipelines[$pipeline] -FileName $pipeline -Parameters $params
#         Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
# }

# Write-Information "Pausing the $($sqlPoolName) SQL pool"

# $result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
# if ($result.properties.status -eq "Online") {
# Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action pause
# Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Paused
# }
