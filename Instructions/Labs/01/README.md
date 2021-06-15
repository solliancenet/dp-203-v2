# Module 1 - Lab environment setup

## Lab details

- [Module 1 - Lab environment setup](#module-1---lab-environment-setup)
  - [Lab details](#lab-details)
  - [Requirements](#requirements)
  - [Exercise 1: Azure setup](#exercise-1-azure-setup)
    - [Task 1: Register resource providers](#task-1-register-resource-providers)
    - [Task 2: Create a resource group in Azure](#task-2-create-a-resource-group-in-azure)
    - [Task 3: Create an Azure VM for the deployment scripts and desktop applications](#task-3-create-an-azure-vm-for-the-deployment-scripts-and-desktop-applications)
    - [Task 4: Create Azure Synapse Analytics workspace](#task-4-create-azure-synapse-analytics-workspace)
    - [Task 5: Create an Azure Databricks workspace](#task-5-create-an-azure-databricks-workspace)
    - [Task 6: Create a cluster](#task-6-create-a-cluster)
  - [Exercise 2: Setup Synapse Analytics workspace](#exercise-2-setup-synapse-analytics-workspace)
    - [Task 1: Pre-requisites](#task-1-pre-requisites)
    - [Task 2: Download artifacts and install PowerShell modules](#task-2-download-artifacts-and-install-powershell-modules)
    - [Task 3: Execute setup scripts](#task-3-execute-setup-scripts)
      - [Potential errors that you can ignore](#potential-errors-that-you-can-ignore)

## Requirements

1. An Azure Account with the ability to create an Azure Synapse Workspace

2. A Power BI Pro or Premium account to host Power BI reports

3. Install [Power BI Desktop](https://www.microsoft.com/download/details.aspx?id=58494) on your lab computer or VM

## Exercise 1: Azure setup

### Task 1: Register resource providers

In Azure, you must register specific resource providers on your subscription before you can deploy services such as Synapse Analytics and Azure Databricks.

1. Log in to the Azure portal (<https://portal.azure.com>).

2. In the search bar on top of the page, type `subscriptions` and select **Subscriptions** in the results.

    ![The Subscriptions option is highlighted.](media/search-subscriptions.png "Subscriptions search")

3. Select the Azure subscription you will use for your lab environment.

    ![The subscription is selected.](media/selected-subscription.png "Subscriptions")

4. Select **Resource providers** in the left-hand menu.

    ![Resource providers is selected.](media/select-resource-providers.png "Resource providers")

5. In the **filter**, type `databricks` to view the **Microsoft.Databricks** provider. Make sure the status is set to **Registered**.

    ![The resource provider status is Registered.](media/databricks-registered.png "Microsoft.Databricks resource provider")

    If it is **not** registered, select the **Microsoft.Databricks** resource provider, then select **Register**.

    ![The register button is highlighted.](media/register-resource-provider.png "Register")

6. In the **filter**, type `synapse` to view the **Microsoft.Synapse** provider. Make sure the status is set to **Registered**.

    ![The resource provider status is Registered.](media/synapse-registered.png "Microsoft.Synapse resource provider")

    If it is **not** registered, select the **Microsoft.Synapse** resource provider, then select **Register**.

    ![The register button is highlighted.](media/register-resource-provider.png "Register")

7. In the **filter**, type `sql` to view the **Microsoft.Sql** provider. Make sure the status is set to **Registered**.

    ![The resource provider status is Registered.](media/sql-registered.png "Microsoft.Sql resource provider")

    If it is **not** registered, select the **Microsoft.Sql** resource provider, then select **Register**.

    ![The register button is highlighted.](media/register-resource-provider.png "Register")

8. In the **filter**, type `document` to view the **Microsoft.DocumentDB** provider. Make sure the status is set to **Registered**.

    ![The resource provider status is Registered.](media/documentdb-registered.png "Microsoft.DocumentDB resource provider")

    If it is **not** registered, select the **Microsoft.DocumentDB** resource provider, then select **Register**.

    ![The register button is highlighted.](media/register-resource-provider.png "Register")

9. In the **filter**, type `stream` to view the **Microsoft.StreamAnalytics** provider. Make sure the status is set to **Registered**.

    ![The resource provider status is Registered.](media/streamanalytics-registered.png "Microsoft.StreamAnalytics resource provider")

    If it is **not** registered, select the **Microsoft.StreamAnalytics** resource provider, then select **Register**.

    ![The register button is highlighted.](media/register-resource-provider.png "Register")

10. In the **filter**, type `event` to view the **Microsoft.EventHub** provider. Make sure the status is set to **Registered**.

    ![The resource provider status is Registered.](media/eventhub-registered.png "Microsoft.EventHub resource provider")

    If it is **not** registered, select the **Microsoft.EventHub** resource provider, then select **Register**.

    ![The register button is highlighted.](media/register-resource-provider.png "Register")

### Task 2: Create a resource group in Azure

1. Log into the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, select the **Menu** button on the top-left corner **(1)**. Hover over **Resource groups (2)**, then select **+ Create (3)**.

    ![The Create button is highlighted.](media/new-resourcegroup.png "Create resource group")

3. On the **Create a resource group** screen, select your desired Subscription and Region. For Resource group, enter **`data-engineering-synapse`** (make sure the name is unique), then select the **Review + Create** button. **Copy the resource group name** and save it in Notepad or similar for later reference.

    ![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/bhol_resourcegroupform.png)

4. Select the **Create** button once validation has passed.

> **Important**: Take note of the _exact_ resource group name you provided for the steps that follow.

### Task 3: Create an Azure VM for the deployment scripts and desktop applications

We highly recommend executing the PowerShell scripts on an Azure Virtual Machine instead of from your local machine. Doing so eliminates issues due to pre-existing dependencies and more importantly, network/bandwidth-related issues while executing the scripts.

1. In the [Azure portal](https://portal.azure.com), type in "virtual machines" in the top search menu and then select **Virtual machines** from the results.

    ![In the Services search result list, Virtual machines is selected.](media/azure-create-vm-search.png "Virtual machines")

2. Select **+ Add** on the Virtual machines page and then select the **Virtual machine** option.

3. In the **Basics** tab, complete the following:

   | Field                          | Value                                              |
   | ------------------------------ | ------------------------------------------         |
   | Subscription                   | _select the appropriate subscription_              |
   | Resource group                 | _select `data-engineering-synapse` (the name of the resource group you created in the previous task)_                      |
   | Virtual machine name           | _`data-engineering-lab-vm` (or unique name if not available)_      |
   | Region                         | _select the resource group's location_             |
   | Availability options           | _select `No infrastructure redundancy required`_   |
   | Image                          | _select `Windows 10 Pro, Version 20H2 - Gen1` (or newer)_     |
   | Azure Spot instance            | _set to `Unchecked`_                                      |
   | Size                           | _select `Standard_D8s_v3`_                         |
   | Username                       | _select `labuser`_                             |
   | Password                       | _enter a password you will remember_               |
   | Public inbound ports           | _select `Allow selected ports`_                    |
   | Select inbound ports           | _select `RDP (3389)`_                              |
   | Licensing                      | _select the option to confirm that you have an  eligible Windows 10 license with multi-tenant hosting rights._ |

   ![The form fields are completed with the previously described settings.](media/azure-create-vm-1.png "Create a virtual machine")

4. Select **Review + create**. On the review screen, select **Create**. After the deployment completes, select **Go to resource** to go to the virtual machine.

    ![The Go to resource option is selected.](media/azure-create-vm-2.png "Go to resource")

5. Select **Connect** from the actions menu and choose **RDP**.

    ![The option to connect to the virtual machine via RDP is selected.](media/azure-vm-connect.png "Connect via RDP")

6. On the **Connect** tab, select **Download RDP File**.

    ![Download the RDP file to connect to the Power BI virtual machine.](media/azure-vm-connect-2.png "Download RDP File")

7. Open the RDP file and select **Connect** to access the virtual machine. When prompted for credentials, enter `labuser` for the username and the password you chose.

    ![Connect to a remote host.](media/azure-vm-connect-3.png "Connect to a remote host")

    Click Yes to connect despite security certificate errors when prompted.

    ![The Yes button is highlighted.](media/rdp-connect-certificate.png "Remote Desktop Connection")

8. Install [Power BI Desktop](https://www.microsoft.com/download/details.aspx?id=58494) on the VM.

### Task 4: Create Azure Synapse Analytics workspace

1. Deploy the workspace through the following Azure ARM template (select the button below):

    <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsolliancenet%2FDP-203T00-Data-Engineering-on-Microsoft-Azure%2Foptimizations%2FInstructions%2FLabs%2F01%2Fartifacts%2Fenvironment-setup%2fautomation%2F00-asa-workspace-core.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton" /></a>

2. On the **Custom deployment** form fill in the fields described below.

   - **Subscription**: Select your desired subscription for the deployment.
   - **Resource group**: Select the resource group you previously created.
   - **Region**: The region where your Azure Synapse environment will be created.

        > **Important**: The `Region` field under 'Parameters' will list the Azure regions where Azure Synapse Analytics is available as of November 2020. This will help you find a region where the service is available without being limited to where the resource group is defined.

   - **Unique Suffix**: This unique suffix will be used naming resources that will created as part of your deployment, such as your initials followed by the current date in YYYYMMDD format (ex. `jdh20210615`). Make sure you follow correct Azure [Resource naming](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#resource-naming) conventions.
   - **SQL Administrator Login Password**: Provide a strong password for the SQLPool that will be created as part of your deployment. [Visit here](https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver15#password-complexity) to read about password rules in place. Your password will be needed during the next steps. Make sure you have your password noted and secured.

   ![The form is configured as described.](media/synapse-arm-template.png "Deploy an Azure Synapse Analytics workspace")

3. Select the **Review + create** button, then **Create**. The provisioning of your deployment resources will take approximately 13 minutes. **Wait** until provisioning successfully completes before continuing. You will need the resources in place before running the scripts below.

    > **Note**: You may experience a deployment step failing in regards to Role Assignment. This error may safely be ignored.

### Task 5: Create an Azure Databricks workspace

1. Deploy the workspace through the following Azure ARM template (select the button below):

   <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.databricks%2Fdatabricks-workspace%2Fazuredeploy.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton" /></a>

2. Provide the required values to create your Azure Databricks workspace:

   - **Subscription**: Choose the Azure Subscription in which to deploy the workspace.
   - **Resource Group**: Select the resource group you previously created.
   - **Region**: Select a location near you for deployment. Ideally, select the same region that you used for the Synapse workspace. For the list of regions supported by Azure Databricks, see [Azure services available by region](https://azure.microsoft.com/regions/services/).
   - **Workspace Name**: Enter a unique name for your workspace.
   - **Disable Public Ip**: Set to `false`.
   - **Pricing Tier**: Ensure `standard` is selected.
   - **Location**: Leave this at the default `[resourceGroup()location]` value.

   ![The form is configured as described.](media/databricks-arm-template.png "Deploy an Azure Databricks Workspace")

3. Select **Review + create**.
4. Select **Create**.
5. The workspace creation takes a few minutes. During workspace creation, the portal displays the Submitting deployment for Azure Databricks tile on the right side. You may need to scroll right on your dashboard to see the tile. There is also a progress bar displayed near the top of the screen. You can watch either area for progress.

### Task 6: Create a cluster

1. When your Azure Databricks workspace creation is complete, select the link to go to the resource.
2. Select **Launch Workspace** to open your Databricks workspace in a new tab.
3. In the left-hand menu of your Databricks workspace, select **Compute**.
4. Select **Create Cluster** to add a new cluster.

    ![The create cluster page](media/create-a-cluster.png)

5. Enter a name for your cluster, such as `Test Cluster`.
6. Select the **Databricks RuntimeVersion**. We recommend the latest runtime and **Scala 2.12**.
7. Select the default values for the cluster configuration.
8. Check **Spot instances** to optimize costs.
9. Select **Create Cluster**.

## Exercise 2: Setup Synapse Analytics workspace

The entire script will take about 15 minutes to complete. Major steps include:

- Configure Synapse resources
- Download all data sets and files into the data lake (~5 mins)
- Execute the Cosmos DB pipeline (~10 mins)

### Task 1: Pre-requisites

Install these pre-requisites on your **deployment VM** before continuing.

- Install VC Redist: <https://aka.ms/vs/15/release/vc_redist.x64.exe>
- Install MS ODBC Driver 17 for SQL Server: <https://www.microsoft.com/download/confirmation.aspx?id=56567>
- Install SQL CMD x64: <https://go.microsoft.com/fwlink/?linkid=2082790>
- Install Microsoft Online Services Sign-In Assistant for IT Professionals RTW: <https://www.microsoft.com/download/details.aspx?id=28177>
- Install [Git client](https://git-scm.com/downloads) accepting all the default options in the setup.
- [Windows PowerShell](https://docs.microsoft.com/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-7)

### Task 2: Download artifacts and install PowerShell modules

Perform all of the steps below from your **deployment VM**:

1. Open a PowerShell Window as an administrator, run the following command to download the artifacts

    ```powershell
    mkdir c:\labfiles

    cd c:\labfiles

    git clone -b optimizations https://github.com/solliancenet/DP-203T00-Data-Engineering-on-Microsoft-Azure.git data-engineering-ilt-deployment
    ```

2. Install Azure PowerShell module

    Open Windows PowerShell as an Administrator on your desktop and execute the following:

    ```powershell
    if (Get-Module -Name AzureRM -ListAvailable) {
        Write-Warning -Message 'Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.'
        Uninstall-AzureRm -ea SilentlyContinue
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    } else {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
    }
    ```

    > [!Note]: You may be prompted to install NuGet providers, and receive a prompt that you are installing the module from an untrusted repository. Select **Yes** in both instances to proceed with the setup

3. Install `Az.CosmosDB` module

    ```powershell
    Install-Module -Name Az.CosmosDB -AllowClobber
    ```

    > [!Note]: If you receive a prompt that you are installing the module from an untrusted repository, select **Yes to All** to proceed with the setup.

4. Install `sqlserver` module

    ```powershell
    Install-Module -Name SqlServer -AllowClobber
    ```

5. Install Azure CLI

    ```powershell
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
    ```

**IMPORTANT**

- Once the last command has completed, **close the Windows PowerShell window** so you can import the newly installed Az.CosmosDB cmdlet.

### Task 3: Execute setup scripts

Perform all of the steps below from your **deployment VM**:

1. Open Windows PowerShell as an Administrator and execute the following to set the `PSGallery` as a trusted repository:

    ```powershell
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    ```

2. Execute the following to set the execution policy to Unrestricted so you can run the local PowerShell script file:

    ```powershell
    Set-ExecutionPolicy Unrestricted
    ```

    > [!Note]: If you receive a prompt that you are installing the module from an untrusted repository, select **Yes to All** to proceed with the setup.

3. Execute the following to import the `Az.CosmosDB` module:

    ```powershell
    Import-Module Az.CosmosDB
    ```

4. Change directories to the root of this repo within your local file system.

    ```powershell
    cd C:\labfiles\data-engineering-ilt-deployment\Instructions\Labs\01\artifacts\environment-setup\automation\
    ```

5. Execute `Connect-AzAccount` and sign in to your Microsoft user account when prompted.

    > [!WARNING]: You may receive the message "TenantId 'xxxxxx-xxxx-xxxx-xxxx' contains more than one active subscription. The first one will be selected for further use. You can ignore this at this point. When you execute the environment setup, you will choose the subscription in which you deployed the environment resources.

6. Execute `az login` and sign in to your Microsoft user account when prompted.

    > If you receive the following error, and have already closed and re-opened the PowerShell window, you need to restart your computer and restart the steps in this task: `The term 'az' is not recognized as the name of a cmdlet, function, script file, or operable program`.

7. Execute `.\01-environment-setup.ps1`

   1. You will be prompted to setup your Azure PowerShell and Azure CLI context.

   2. If you have more than one Azure Subscription, you will be prompted to enter the name of your desired Azure Subscription. You can copy and paste the value from the list to select one. For example:

       ![A subscription is copied and pasted into the text entry.](media/select-desired-subscription.png "Select desired subscription")

   3. Enter the name of the resource group you created at the beginning of the environment setup (such as `data-engineering-synapse`). This will make sure automation runs against the correct environment you provisioned in Azure.

       During the execution of the automation script you may be prompted to approve installations from PS-Gallery. Please approve to proceed with the automation.

       ![The Azure Cloud Shell window is displayed with a sample of the output from the preceding command.](media/untrusted-repo.png)

       > **NOTE** This script will take about 15-25 minutes to complete.

#### Potential errors that you can ignore

You may encounter a few errors and warnings during the script execution. The errors below can safely be ignored:

1. The following error may occur when creating SQL users and adding role assignments in the dedicated SQL pool, and can safely be ignored: `Principal 'xxx@xxx.com' could not be created. Only connections established with Active Directory accounts can create other Active Directory users.`

    ![Error is displayed.](media/error-cannot-create-principal.png "Cannot create principal")

2. Toward the end of the script, you may see the following error. If you do, it can be safely ignored:

    ```PowerShell
    Starting PowerBI Artifact Provisioning
    Invoke-WebRequest : The response content cannot be parsed because the Internet Explorer engine is not available, or Internet Explorer's first-launch configuration is not complete. Specify the UseBasicParsing parameter and try again.
    At C:\labfiles\data-engineering-ilt-deployment\setup\04\artifacts\environment-setup\solliance-synapse-automation\solliance-synapse-automation. char:15
    + ...   $result = Invoke-WebRequest -Uri $url -Method GET -ContentType "app ...
    +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotImplemented: (:) [Invoke-WebRequest], NotSupportedException
        + FullyQualifiedErrorId : WebCmdletIEDomNotSupportedException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand

    Cannot index into a null array.
    At C:\labfiles\data-engineering-ilt-deployment\setup\04\artifacts\environment-setup\solliance-synapse-automation\solliance-synapse-automation. char:5
    +     $homeCluster = $result.Headers["home-cluster-uri"]
    +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
        + FullyQualifiedErrorId : NullArray
    ```
