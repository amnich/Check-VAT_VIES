# Check-VAT_VIES

* Check VAT number on VIES - http://ec.europa.eu/taxation_customs/vies/
* Show web page
* Return results
* Print web page

## Usage

Check TIN, show web page and print results.
```powershell
PS >  Check-VAT_VIES -TIN DE99999999999 -CheckersTIN DE99999999999

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True
```
Check TIN, show web page but don't print.
```powershell
PS >  Check-VAT_VIES -TIN DE99999999999 -NoPrint

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True
```

Check TIN only.
```powershell
PS >  Check-VAT_VIES -TIN DE99999999999 -CheckOnly

Date                TIN           User     Result
----                ---           ----     ------
2017-08-18 16:47:04 DE99999999999 user1    True
```
