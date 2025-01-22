
************************INNOVATION DISPERSION***************************
import excel "Listed_Company_Patent_Classification.xlsx", firstrow clear
gen stkcd=real(Scode)
gen year=real(Year)
keep if regexm(Ftyp,"Listed Company")|regexm(Ftyp,"Subsidiary")
save temp

* Since the data volume for this patent classification number is large each year, a nested loop is used to calculate it annually
forvalues n = 2000/2022 { 
    use temp, clear
    keep if year == `n'
    
    foreach category in Inva_A Inva_B Inva_C Inva_D Inva_E Inva_F Inva_G Inva_H {
        replace `category' = subinstr(`category', ",", ";", .) 
        split `category', parse(";")
    }
	drop Inva_A Inva_B Inva_C Inva_D Inva_E Inva_F Inva_G Inva_H Inva_Anum Inva_Bnum Inva_Cnum Inva_Dnum Inva_Enum Inva_Fnum Inva_Gnum Inva_Hnum
	rename Inva_* Inva_#, addnumber
	save "`n'.dta", replace

}

* Process patents for 2000, take it as an example
forvalues i = 1/290
//"1/290" means iterating through Inva1 to Inva290. Note: The number of Inva variables varies for each year.
{
    use 2000.dta, clear
    keep stkcd year Ftyp Inva_`i' 
    rename Inva_`i' patent_classification
    save "temp_code_`i'.dta", replace
}

clear 
forvalues i = 1/290 {
    append using "temp_code_`i'.dta"
    drop if patent_classification == ""
}
save 2000.dta, replace

forvalues i = 1/290 {
    erase "temp_code_`i'.dta"
}

* Then process patents for 2001-2022 seperately

* Process patents for 2000-2022
forvalues i = 2000/2022 {
    use "`i'.dta", clear

    * Extract main group
    gen main_group = substr(patent_classification, 1, strpos(patent_classification, "/"))
    replace main_group = subinstr(main_group, "/", "", .)
    replace main_group = subinstr(main_group, "{", "", .)
    replace main_group = subinstr(main_group, "}", "", .)
    drop if main_group == ""

    * Compute number of patent classifications per firm
    bys stkcd: gen z1 = _n
    bysort stkcd: egen z = max(z1)
    bys stkcd main_group: gen order = _n
    bys stkcd main_group: egen z2 = max(order)
    keep if order == z2
    gen z3 = z2 / z
    save "`i'_processed.dta", replace
}

* Append all processed patent datasets
clear
forvalues i = 2000/2022 {
    append using "`i'_processed.dta"
}

* Calculate firm's innovation dispersion
bys stkcd year: egen z4 = sum(z3^2)
gen innovation_dispersion = 1 - z4
sort stkcd year
bysort stkcd year: gen row_num = _n
keep if row_num == 1

save "Firm_Innovation_Dispersion.dta", replace
