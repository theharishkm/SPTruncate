## Truncate-SPList 
## Remove all items in a SharePoint List, batched up for processing in large chunks for a quick delete process 
## NOTE: This is not a true "Truncate", as SharePoint will never reuse an Item ID so seed is not reset 
## 
## Usage: Truncate-SPList -SiteUrl http://Server/Site  -ListName List 
## 
## Author:  
##    ieDaddy  
##    web: http://iedaddy.com 
##    twitter: @ieDaddy 
##              
##          
 
Param( 
    [Parameter(Mandatory=$true)] [String] $SiteUrl, 
    [Parameter(Mandatory=$true)] [String] $ListName 
    ) 
     
Function TruncateSPList  
{ 
    ## Parameter validation 
    Try  
    {  
        ## Use Get-SPWeb get the website we want, on error don't go further 
        $spWeb = Get-SPWeb -Identity $SiteURL -ErrorAction Stop -Verbose:$false  
    }  
    Catch   
    {  
        #If Get-SPSite failed for any reason, this function will be terminated.  
        Write-Host $Error[0] 
        return $null  
    }  
    ## Get the specified list, $spList is a instance of Microsoft.SharePoint.SPList class  
    $spList = $spWeb.Lists[$ListName] 
 
     
    if ($spList -ne $null)  
    { 
        ## This looping goes through one by one, but maybe a better way? 
        #ForEach ($item in $spList.items) 
        #{ 
        #    $ItemToDelete=$splist.GetItemById($item.ID) 
        #    write-host 'Deleting : ' $ItemToDelete.ID 
        #    $ItemToDelete.Delete() 
        #} 
         
        ## Set up a do..until loop so we can batch the removals 100 records at a time     
        do  
        { 
            ## Set up our Items Collection for Batch Processing 
            $spQuery = new-object Microsoft.SharePoint.SPQuery  
            $spQuery.RowLimit = 100 
            $spQuery.Query = "" 
            ## Get collection of items to be deleted for the batch delete 
            $spListItemCollection = $spList.GetItems($spQuery) 
            $batchRemove = '<?xml version="1.0" encoding="UTF-8"?><Batch>';    
            ## The command is built out to iterate through the ItemCollection to build out batch command 
            $command = '<Method><SetList Scope="Request">' +   
                $spList.ID +'</SetList><SetVar Name="ID">{0}</SetVar>' +   
                '<SetVar Name="Cmd">Delete</SetVar></Method>';    
            foreach ($item in $spListItemCollection)   
            { 
                $batchRemove += $command -f $item.Id;   
            }   
            $batchRemove += "</Batch>";    
             
            ## Remove the list items using the batch command  
            $spList.ParentWeb.ProcessBatchData($batchRemove) | Out-Null 
 
        } until ( $spList.GetItems().Count -eq 0 ) 
    } 
    Else 
    { 
        Write-Host $Error[0] 
        return $null  
    } 
 
    ## Dispose SPWeb object, it's just good manners 
    $spWeb.Dispose()  
} 
 
$confirm = Read-Host "This script will delete all items from the list, Proceed [y/n]" 
if ($confirm -ne 'y') 
{ 
    Exit 
}     
TruncateSPList 