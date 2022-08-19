function Check-VAT_VIES {

<#
.Synopsis
VIES VAT number validation - using SOAP service or also show the result in Browser and Print the results.

.DESCRIPTION

VIES VAT number validation - using SOAP service or also show the result in Browser and Print the results.

.NOTES   
Name: Check-VAT_VIES 
Author: Adam Mnich
Created: 2017.08.17
Version: 1.2
DateUpdated: 2022.08.19

.LINK
https://amnich.github.io/Check-VAT-VIES/

.PARAMETER TIN
Country code following by VAT number

.PARAMETER CheckersTIN
Country code following by VAT number

.PARAMETER Print
Print web page with results

.PARAMETER Print
Print web page with results

.PARAMETER NoPrint
left NoPrint for compatibility - if you want to print the page you have to use now -Print and -ShowInBrowser

.PARAMETER ShowInBrowser
Show results in browser

.PARAMETER CheckOnly
left for compatibility - if you want to show it in Browser use -ShowInBrowser

.EXAMPLE
Check-VAT_VIES -TIN DE99999999999 

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True

Check TIN only.

.EXAMPLE

Check-VAT_VIES -TIN DE99999999999 -ShowInBrowser

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True

Check TIN, show web page but don't print.

#>


[CmdletBinding(DefaultParameterSetName='Default')] 
param(
	[Parameter(Mandatory=$true,Position = 0)]
	[ValidatePattern('[A-Za-z]{2}')]
    [string]$TIN,
	[Parameter(Position = 1)]
	[ValidatePattern('[A-Za-z]{2}')]
	[string]$CheckersTIN,
    [Parameter(ParameterSetName='Web')]
	[switch]$Print,
	[Parameter(ParameterSetName='Web')]
	[switch]$NoPrint, 
	[Parameter(ParameterSetName='Web',Mandatory=$true)]
	[switch]$ShowInBrowser,
	[switch]$CheckOnly #left for compatibility - if you want to show it in Browser use -ShowInBrowser
)
	$uriVatRespone = 'https://ec.europa.eu/taxation_customs/vies/vatResponse.html'
	$uriSoap = 'https://ec.europa.eu/taxation_customs/vies/services/checkVatService'
    #Example TIN DE999999999 - country code following by VAT number
	Write-Verbose "Original TIN $TIN"
	$TIN = $TIN -replace "\W",""
	Write-Verbose "Replaced TIN $TIN"
	$TIN -match "(^\D*)(\d*)" | out-null
	$country = $matches[1].ToUpper()
	Write-Verbose "Country $country"
	$vatnumber = $matches[2]
	Write-Verbose "TIN $TIN"
	
	if ($CheckersTIN){
		$CheckersTIN = $CheckersTIN  -replace "\W",""
		if ($CheckersTIN -match "(^\D*)(\d*)"){
			$countryChecker = $matches[1].ToUpper()
			Write-Verbose "Checkers Country $country"
			$vatnumberChecker = $matches[2]
			Write-Verbose "Checkers TIN $TIN"
		}
	}
	$tempFile = "$env:temp\vat.html"
	Remove-Item $tempFile -Force -ErrorAction Ignore	
	try {
		$xmlSoap = '<?xml version="1.0" encoding="UTF-8"?>
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
			<soapenv:Header/>
			<soapenv:Body>
			    <urn:checkVat>
			        <urn:countryCode>{0}</urn:countryCode>
			        <urn:vatNumber>{1}</urn:vatNumber>
			    </urn:checkVat>
			</soapenv:Body>
           </soapenv:Envelope>' -f $country, $vatnumber
		$SoapResults = Invoke-WebRequest -Method Post -Uri $uriSoap -Body $xmlSoap -ContentType "text/xml; charset=utf-8"
		try {		
		if ($ShowInBrowser){
	        #Post code with country and vat number to check		        
			$POST = "memberStateCode=$country&number=$vatnumber"
			if ($CheckersTIN){
				$POST = "$POST&requesterMemberStateCode=$countryChecker&requesterNumber=$vatNumberChecker"
			}
			$POST = "$POST&action=check"
	        #invoke-webrequest and store results in a temp file
			Invoke-WebRequest -Method Post -Body $POST -Uri $uriVatRespone -OutFile $tempFile 
			$file = Get-Content $tempFile -Encoding UTF8
	        #replace href and src to display page correctly
			$file = $file.replace('href="','href="http://ec.europa.eu') 
			$file = $file.replace('src="','src="http://ec.europa.eu')
			$file | Out-File $tempFile -Encoding UTF8
			Write-Debug "File`n$($file | out-string)"
			Write-Verbose "Open page $tempFile"
			try {
	            #create new IE com object
				Write-Verbose "Create new IE object"
				$ie = New-Object -com InternetExplorer.Application 
			    Write-Verbose "Set props"
				Write-Verbose "    AddressBar"
				$ie.AddressBar = $false
				Write-Verbose "    MenuBar"
				$ie.MenuBar = $false
				Write-Verbose "    ToolBar"
				$ie.ToolBar = $false
				Write-Verbose "    Visible"
				$ie.visible=$true
				Write-Verbose "Navigate to local page $env:temp\vat.html"
			    $ie.navigate("$env:temp\vat.html")
				Start-Sleep -Milliseconds 100
				$iewait = 0
			    while($ie.ReadyState -ne 4 -and $iewait -lt 50) {
					Write-Verbose "$(Get-Date) IE Not ready ... sleep"
					start-sleep -m 100
					$iewait++
				}
				if ($iewait -ge 50){
					throw "Wait time for IE too long."
				}
			}
			catch{
				$Error[0]
			}
		}
        }
        catch{
            $_
        }
		#create output object with results
		$obj = New-Object Pscustomobject -Property ([ordered]@{
			Date = Get-Date
			TIN = $TIN
			Result = $null
            Name = $null
            Address = $null
			User = $env:Username
		})
		#check if $SoapResults 
		if (-not ($SoapResults -as [XML]).envelope.body.checkvatresponse.valid){
			Write-Verbose "No soap results. Check text in page"
	        #check if page contains text
			if ($file -match ("Yes, valid VAT number")) { 
				$obj.Result = $true			
			}
			elseif ($file -match ("No, invalid VAT number")) { 
				$obj.Result = $false			
			}
			else{
				throw "Not expected results." 
			}
		}
		else{
			Write-Verbose "Soap results"
            $SoapBVatResponse = ($SoapResults.Content -as [XML]).envelope.body.checkvatresponse
			Write-Debug "$($SoapBVatResponse | Out-String)"
			$obj.Result = $SoapBVatResponse.valid
            $obj.Name = $SoapBVatResponse.name
            $obj.Address = $SoapBVatResponse.address
		}
		$obj			
		#automate print
		if ($Print -and $ShowInBrowser){
			try {
				$ie.execWB(6,2)
			}
			catch{
				$Error[0]
			}
		}
	}
	catch{
        $error[0]
    }
}
