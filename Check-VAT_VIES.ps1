function Check-VAT_VIES {
param(
    $TIN,
    [switch]$NoPrint
)
    #Example TIN DE999999999 - country code following by VAT number
	Write-Verbose "Original TIN $TIN"
	$TIN = $TIN -replace "\W",""
	Write-Verbose "Replaced TIN $TIN"
	$TIN -match "(^\D*)(\d*)" | out-null
	$country = $matches[1].ToUpper()
	Write-Verbose "Country $country"
	$vatnumber = $matches[2]
	Write-Verbose "TIN $TIN"
	$tempFile = "$env:temp\vat.html"
	Remove-Item $tempFile -Force -ErrorAction Ignore
	try {
        #Post code with country and vat number to check		        
		$POST = "memberStateCode=$country&number=$vatnumber&action=check"
        #invoke-webrequest and store results in a temp file
		Invoke-WebRequest -Method Post -Body $POST -Uri 'http://ec.europa.eu/taxation_customs/vies/vatResponse.html' -OutFile $tempFile
		
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
		#create output object with results
		$obj = New-Object Pscustomobject -Property @{
			Date = Get-Date
			NIP = $TIN
			Result = $null
			User = $env:Username
		}
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
		$obj			
		#automate print
		if (-not $NoPrint){
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