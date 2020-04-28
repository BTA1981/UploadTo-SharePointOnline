Function UploadTo-SharePointOnline {
    param (
        [Parameter(Mandatory=$True)] # SPO site url. for example "https://company.sharepoint.com/sites/clippy/" 
        [string]$SPOurl,
        [Parameter(Mandatory=$True)] # Relative path to Sharepoint folder, excluding base url. for example "/sites/clippy/office assistant/word"
        [string]$TargetFolderRelativeURL,
        [Parameter(Mandatory=$False)] # Local folder containing files you want to upload to SharePoint
        [string]$LocalFolder,
        [Parameter(Mandatory=$True)] # Path to file with encrypted credentials.
        [String]$SPOCredPath,
        [Parameter(Mandatory=$True)] # Path to file with private key to decrypt credential file
        [string]$SPOKeyFilePath
    )
    # Path to SharePoint Client Side Object Model (CSOM) libary files. 
    # You can get these files by download and installing the SharePoint Online CSOM on the server you want to execute this script from 
    Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll" 
    Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

    # Process credentials
    $SPOKey = Get-Content $SPOKeyFilePath
    $SPOcredXML = Import-Clixml $SPOCredPath
    $User = $SPOcredXML.username
    $SPOsecureStringPWD = ConvertTo-SecureString -String $SPOcredXML.Password -Key $SPOKey

    # Get the ClientContext and authenticate against this SharePoint Online tenant
    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($SPOurl) 
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($user, $SPOsecureStringPWD) 
    $clientContext.Credentials = $credentials 

    # Get the Target Folder to upload
    $Web = $clientContext.Web
    $clientContext.Load($Web)
    $TargetFolder = $Web.GetFolderByServerRelativeUrl($TargetFolderRelativeURL)
    $clientContext.Load($TargetFolder)
    $clientContext.ExecuteQuery() 
    
    Foreach ($File in (Get-ChildItem $LocalFolder)) {
        $FileStream = New-Object IO.FileStream($File.FullName,[System.IO.FileMode]::Open)
        $FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
        $FileCreationInfo.Overwrite = $True
        $FileCreationInfo.ContentStream = $FileStream
        $FileCreationInfo.URL = $File
        $Upload = $TargetFolder.Files.Add($FileCreationInfo)  
        $clientContext.Load($Upload)
        $clientContext.ExecuteQuery()
        $TargetFileURL = $TargetFolderRelativeURL+"/"+$File
        Write-Host "Succesfully uploaded file [$TargetFileURL]"
    }
    $FileStream.Close()
}

# Call function
UploadTo-SharePointOnline -SPOurl "https://company.sharepoint.com/sites/clippy/" -TargetFolderRelativeURL "/sites/clippy/office assistant/word" -LocalFolder "C:\content\tips" -SPOCredPath "C:\securefolder\Cred.xml" -SPOKeyFilePath "C:\securefolder\SPO.key"
