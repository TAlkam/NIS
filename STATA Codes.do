
 ##labeling and Table 2 --------------------------------------------------------------------------------------------------------------
 
 set more off

* 1) Alzheimer’s cohort (any G30.* in I10_DX1–I10_DX40), age ≥60
gen byte ad_any = 0
forvalues j = 1/40 {
    replace ad_any = 1 if substr(upper(trim(I10_DX`j')),1,3)=="G30" | ad_any
}
keep if ad_any==1
keep if AGE>=60

* 2) Convenience aliases (safe even if they already exist)
capture gen byte female = FEMALE
capture gen race = RACE

* 3) Clinical/frailty flags
gen byte dnr      = 0
gen byte pall     = 0
gen byte sepsis   = 0
gen byte arf      = 0
gen byte aki      = 0
gen byte uti      = 0
gen byte asp      = 0
gen byte malnut   = 0
gen byte dysph    = 0
gen byte pressulc = 0
gen byte chf      = 0
gen byte cad      = 0
gen byte afib     = 0
gen byte cva      = 0
gen byte anemia   = 0
gen byte hypoth   = 0

forvalues j=1/40 {
    replace dnr      = 1 if I10_DX`j'=="Z66" | dnr
    replace pall     = 1 if I10_DX`j'=="Z515" | pall
    replace sepsis   = 1 if substr(I10_DX`j',1,3)=="A41" | sepsis
    replace arf      = 1 if substr(I10_DX`j',1,3)=="J96" | arf
    replace aki      = 1 if I10_DX`j'=="N179" | aki
    replace uti      = 1 if I10_DX`j'=="N390" | uti
    replace asp      = 1 if I10_DX`j'=="J690" | asp
    replace malnut   = 1 if inlist(I10_DX`j',"E43","E44","E46") | malnut
    replace dysph    = 1 if substr(I10_DX`j',1,3)=="R13" | dysph
    replace pressulc = 1 if substr(I10_DX`j',1,3)=="L89" | pressulc
    replace chf      = 1 if substr(I10_DX`j',1,3)=="I50" | chf
    replace cad      = 1 if I10_DX`j'=="I2510" | cad
    replace afib     = 1 if substr(I10_DX`j',1,3)=="I48" | afib
    replace cva      = 1 if inlist(substr(I10_DX`j',1,3),"I63","I69") | cva
    replace anemia   = 1 if substr(I10_DX`j',1,3)=="D64" | anemia
    replace hypoth   = 1 if substr(I10_DX`j',1,3)=="E03" | hypoth
}

* 4) Survey design (try with strata; if absent, fall back)
capture svyset HOSP_NIS [pweight=DISCWT], strata(NIS_STRATUM) vce(linearized) singleunit(centered)
if _rc {
    svyset HOSP_NIS [pweight=DISCWT], vce(linearized) singleunit(centered)
}

* 5) Quick weighted descriptives
svy: mean DIED LOS TOTCHG

* 6) Build covariate list in a local (avoids line breaks)
local xvars c.AGE i.female i.race i.ZIPINC_QRTL i.HCUP_ED i.ELECTIVE i.TRAN_IN i.AWEEKEND i.HOSP_DIVISION sepsis arf aki uti asp malnut dysph pressulc chf cad afib cva anemia hypoth dnr pall

* 7) Single-line survey-weighted mortality model
svy: logit DIED `xvars'

* 8) Marginal effects
margins, dydx(*) post

 
 
 ## For Table 1 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 

version 16.0
set more off

* Load (uncomment if needed)
* use "E:\NIS 2017\NIS_2017_Core data age_over_60 new labels_alz-only for analysis.dta", clear

svyset HOSP_NIS [pweight=DISCWT], strata(NIS_STRATUM) vce(linearized) singleunit(centered)

putexcel set "E:\NIS 2017\Table1.xlsx", sheet("Table1") replace

* Header
putexcel A1 = "Table 1. Cohort characteristics (weighted)"
putexcel A3 = "Characteristic" B3 = "Level" C3 = "Value" D3 = "SE / 95% CI"
local row = 4

* ---------- AGE: mean (SE)
svy: mean AGE
local m = _b[AGE]
local s = _se[AGE]
putexcel A`row' = "Age (years)" B`row' = "Mean (SE)" C`row' = round(`m', .001) D`row' = round(`s', .001)
local ++row

* ---------- Helper: write a block of binary proportions (as % with 95% CI)
capture program drop _write_binary_block
program define _write_binary_block
    syntax varlist
    tempname tcrit
    * Run once for all vars
    svy: proportion `varlist'
    scalar `tcrit' = invttail(e(df_r), 0.025)
    local cols : colnames e(b)

    foreach c of local cols {
        local est = _b[`c']
        local se  = _se[`c']
        local lb  = `est' - `tcrit'*`se'
        local ub  = `est' + `tcrit'*`se'

        * Pretty name for the row (variable label if present, otherwise name)
        local base = "`c'"
        * For plain binary names like "female" just show the var label/name.
        * If name includes a dot (like "1.race"), we skip here (this block is only for plain binaries).
        local dotpos = strpos("`base'", ".")
        if `dotpos'==0 {
            local showname : variable label `base'
            if "`showname'"=="" local showname "`base'"

            * Convert to percent
            local pct  = round(100*`est', .01)
            local se_p = round(100*`se', .01)
            local lbp  = round(100*`lb', .01)
            local ubp  = round(100*`ub', .01)

            global TAB1_ROW = ${TAB1_ROW} + 1
            putexcel A${TAB1_ROW} = "`showname'" B${TAB1_ROW} = "Yes"
            putexcel C${TAB1_ROW} = `pct' D${TAB1_ROW} = "`lbp'%–`ubp'%" 
        }
    }
end

* Keep an external row counter usable in the program
global TAB1_ROW = `row' - 1

* Binary block: includes DIED to report overall in-hospital mortality %
_write_binary_block female ELECTIVE AWEEKEND DIED sepsis arf aki asp uti malnut dysph pressulc chf cad afib cva anemia hypoth dnr pall

local row = ${TAB1_ROW} + 2
putexcel A`row' = "" B`row' = "" C`row' = "" D`row' = ""
local ++row

* ---------- Helper: write a labeled factor distribution (all levels)
* This will print “Characteristic” and each level’s weighted % (95% CI)
capture program drop _write_factor_block
program define _write_factor_block
    syntax name(name=varname)
    tempname tcrit
    local v `varname'

    * Get label for the variable (section header)
    local vlab : variable label `v'
    if "`vlab'"=="" local vlab "`v'"

    * Run factor proportions (all levels)
    svy: proportion i.`v'
    scalar `tcrit' = invttail(e(df_r), 0.025)

    * Find the value label attached (if any), and its levels
    local vallab : value label `v'
    levelsof `v', local(levels)

    * Write section header row
    global TAB1_ROW = ${TAB1_ROW} + 1
    putexcel A${TAB1_ROW} = "`vlab'" B${TAB1_ROW} = "" C${TAB1_ROW} = "" D${TAB1_ROW} = ""

    foreach L of local levels {
        * Build the column name used by svy: proportion i.var → "L.var"
        local cname = "`L'.`v'"

        * Skip if the column isn’t in e(b) (rare, but safe)
        capture confirm matrix e(b)
        if _rc==0 {
            capture noisily display _b[`cname']
            if _rc==0 {
                local est = _b[`cname']
                local se  = _se[`cname']
                local lb  = `est' - `tcrit'*`se'
                local ub  = `est' + `tcrit'*`se'

                * Level label text
                local labtxt "`L'"
                if "`vallab'"!="" {
                    local labtxt : label (`vallab') `L'
                    if "`labtxt'"=="" local labtxt "`L'"
                }

                * Percent formatting
                local pct  = round(100*`est', .01)
                local lbp  = round(100*`lb', .01)
                local ubp  = round(100*`ub', .01)

                global TAB1_ROW = ${TAB1_ROW} + 1
                putexcel A${TAB1_ROW} = "" B${TAB1_ROW} = "`labtxt'"
                putexcel C${TAB1_ROW} = `pct' D${TAB1_ROW} = "`lbp'%–`ubp'%" 
            }
        }
    }
end

* Write factor sections in order requested
_write_factor_block race
_write_factor_block ZIPINC_QRTL
_write_factor_block TRAN_IN
_write_factor_block HOSP_DIVISION

* Formatting helpers (optional)
putexcel A3:D3, bold
