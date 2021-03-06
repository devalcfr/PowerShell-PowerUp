<#
$Metadata = @{
	Title = "Get SharePoint List Files"
	Filename = "Get-SPListFiles.ps1"
	Description = ""
	Tags = "sharepoint, powershell, list, files"
	Project = ""
	Author = "Janik von Rotz"
	AuthorContact = "http://janikvonrotz.ch"
	CreateDate = "2013-10-11"
	LastEditDate = "2013-10-22"
	Version = "1.1.0"
	License = @'
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Switzerland License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ch/ or 
send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
'@
}
#>

function Get-SPListFiles{

<#
.SYNOPSIS
    Report SharePoint files.

.DESCRIPTION
	Report all SharePoint files and their metadata.

.EXAMPLE
	PS C:\> Get-SPListFiles | Out-GridView

.EXAMPLE
	PS C:\> Get-SPListFiles | Export-Csv "Report.csv" -Delimiter ";" -Encoding "UTF8" -NoTypeInformation
#>

	param(
	)
    
    Get-SPSite | %{
    
        $SPsite = $_
        
        # deleted files in site collection
        $SPsite.RecycleBin | where{$_.ItemType -eq "File"} |%{
        
            $ItemUrl = $SPsite.Url + "/" + $_.DirName + "/"+ $_.LeafName
        
            New-Object PSObject -Property @{
                ParentWebsite = $SPSite.HostName
                ParentWebsiteUrl = $SPsite.Url
                Website = $_.Web.title
                WebsiteUrl = $_.Web.Url
                List = ""
                ListUrl = ""
                FileExtension = [System.IO.Path]::GetExtension($_.LeafName)
                IsCheckedOut = $false
                IsASubversion = $false
                IsDeleted = $true                
                Item = $_.LeafName                
                ItemUrl = $ItemUrl
                Folder = $ItemUrl -replace "[^/]+$",""      
                FileSize = $_.Size / 1MB    
            }
        }
        
        $SPWebs = Get-SPWebs $_.Url 
        $SPWebs | %{

            $SPWeb = $_
            
            # deleted files on website
            $SPWeb.RecycleBin | where{$_.ItemType -eq "File"} |%{
        
                $ItemUrl = $SPsite.Url + "/" + $_.DirName + "/"+ $_.LeafName
            
                New-Object PSObject -Property @{
                    ParentWebsite = $SPWeb.ParentWeb.title
                    ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                    Website = $SPWeb.title
                    WebsiteUrl = $SPWeb.Url
                    List = ""
                    ListUrl = ""
                    FileExtension = [System.IO.Path]::GetExtension($_.LeafName)
                    IsCheckedOut = $false
                    IsASubversion = $false
                    IsDeleted = $true                
                    Item = $_.LeafName                
                    ItemUrl = $ItemUrl
                    Folder = $ItemUrl -replace "[^/]+$",""      
                    FileSize = $_.Size / 1MB    
                }
            }
                            
            Get-SPLists $_.Url -OnlyDocumentLibraries | %{
            
                $SPList = $_
                
                $SPListUrl = (Get-SPUrl $SPList).url
                
                Write-Progress -Activity "Crawl list on website" -status "$($SPWeb.Title): $($SPList.Title)" -percentComplete ([Int32](([Array]::IndexOf($SPWebs, $SPWeb)/($SPWebs.count))*100))
                
                # files in lists         
                Get-SPListItems $_.ParentWeb.Url -FilterListName $_.title | %{
                    
                    $ItemUrl = (Get-SPUrl $_).Url                    
                    
                    New-Object PSObject -Property @{
                        ParentWebsite = $SPWeb.ParentWeb.title
                        ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                        Website = $SPWeb.title
                        WebsiteUrl = $SPWeb.Url
                        List = $SPList.title
                        ListUrl = $SPListUrl
                        FileExtension = [System.IO.Path]::GetExtension($_.Url)
                        IsCheckedOut = $false
                        IsASubversion = $false
                        IsDeleted = $false              
                        Item = $_.Name                
                        ItemUrl = $ItemUrl
                        Folder = $ItemUrl -replace "[^/]+$",""      
                        FileSize = $_.file.Length / 1MB    
                    }
                    
                    $SPItem = $_
                    
                    # file subversions            
                    $_.file.versions | %{
                    
                        $ItemUrl = (Get-SPUrl $SPItem).Url  
                    
                        New-Object PSObject -Property @{
                            ParentWebsite = $SPWeb.ParentWeb.title
                            ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                            Website = $SPWeb.title
                            WebsiteUrl = $SPWeb.Url                    
                            List = $SPList.title
                            ListUrl = $SPListUrl
                            FileExtension = [System.IO.Path]::GetExtension($_.Url)
                            IsCheckedOut = $false
                            IsASubversion = $true
                            IsDeleted = $false                                
                            Item = $SPItem.Name                    
                            ItemUrl = $ItemUrl 
                            Folder = $ItemUrl -replace "[^/]+$",""                               
                            FileSize = $_.Size / 1MB
                        }
                    }            
                }
                
                # checked out files in lists
                Get-SPListItems $_.ParentWeb.Url -FilterListName $_.title -OnlyCheckedOutFiles | %{
                
                    $ItemUrl = $SPSite.url + "/" + $_.Url 
                
                    New-Object PSObject -Property @{
                        ParentWebsite = $SPWeb.ParentWeb.title
                        ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                        Website = $SPWeb.title
                        WebsiteUrl = $SPWeb.Url
                        List = $SPList.title
                        ListUrl = $SPListUrl
                        FileExtension = [System.IO.Path]::GetExtension($_.Url)
                        IsCheckedOut = $true
                        IsASubversion = $false
                        IsDeleted = $false                             
                        Item = $_.LeafName                
                        ItemUrl = $ItemUrl  
                        Folder = $ItemUrl -replace "[^/]+$",""          
                        FileSize = $_.Length / 1MB
                    }                
                }
            }
        }
    }
}