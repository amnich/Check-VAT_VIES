# Check-VAT_VIES

#### EDIT: 2022.08.19 
#### The ShowInBrowser is not working anymore as they changed the web page and i'm not using it anymore. I'm leaving it here so you can fix it :)
#### The SOAP check works after the recent changes in the service. 
#### Returning now also the name and address.

* Check VAT number on VIES - http://ec.europa.eu/taxation_customs/vies/
* Show web page
* Return results
* Print web page

## Usage

Check TIN, show web page and print results.
```powershell
PS >  Check-VAT_VIES -TIN DE99999999999 -CheckersTIN DE99999999999 -ShowInBrowser -Print

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True
```
Check TIN, show web page but don't print.
```powershell
PS >  Check-VAT_VIES -TIN DE99999999999 -ShowInBrowser

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True
```

Check TIN only.
```powershell
PS >  Check-VAT_VIES -TIN DE99999999999 

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True
```
