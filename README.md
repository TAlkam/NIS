
# 🧠 Risk Stratification for In-Hospital Mortality in Alzheimer’s Disease

This repository contains a reproducible analysis pipeline for risk stratification of **in-hospital mortality among hospitalized patients with Alzheimer’s disease (AD)** using a **dual approach**: survey-weighted regression and explainable machine learning (**XGBoost + SHAP**). The project uses nationally representative data from the **2017 HCUP Nationwide Inpatient Sample (NIS)** and implements a leakage-safe preprocessing and evaluation framework designed for publication-quality reporting.

---

## 📌 Overview

Older adults with Alzheimer’s disease are at elevated risk of in-hospital mortality. This project aims to:

- Compare **survey-weighted logistic regression** (interpretable baseline) vs. **XGBoost** (nonlinear model).
- Identify key predictors using **adjusted odds ratios** (regression) and **SHAP values** (XGBoost).
- Evaluate discrimination and calibration using **AUROC**, **AUPRC**, **Brier score**, and **log loss**.
- Perform a **restricted-model sensitivity analysis** excluding end-of-life indicators (**DNR** and **palliative care**) to assess whether physiologic risk signals persist.
- Generate publication-ready figures and tables for clinical interpretation.

---

## 📊 Data and Methods

### Data
- **Source**: HCUP NIS 2017
- **Cohort**: Patients aged ≥60 years with Alzheimer’s disease diagnosis
- **Outcome**: In-hospital mortality (`died`)

### Features
- Demographics (e.g., age, sex)
- Comorbidities / diagnoses (binary indicators from the selected diagnosis set)
- Hospital characteristics and system-level variables
- End-of-life indicators (DNR, palliative care) for the **full** model

### Evaluation Strategy (important)
- **5-fold hospital-grouped cross-validation** using `GroupKFold` clustered by hospital identifier (e.g., `hosp_nis`)
- **Leakage-safe preprocessing**: imputation and scaling are fit **within each training fold** and applied to the held-out fold
- **Survey/HCUP discharge weights** are incorporated as **sample weights** in model fitting and evaluation

### Models
- **Survey-weighted logistic regression**
- **XGBoost (binary:logistic)** with SHAP-based explainability

---

## 🔁 Restricted-Model Sensitivity Analysis

To test robustness and clinical utility when explicit end-of-life documentation is unavailable, we re-ran the entire modeling pipeline after excluding:

- `dnr`
- `pall`

The restricted analysis is evaluated using the **same GroupKFold hospital-clustered cross-validation** and the same leakage-safe preprocessing pipeline.

---

## 📈 Key Results (GroupKFold, 5-fold)

### Full model (includes DNR + palliative care)
- **Logistic Regression**: AUROC **0.8789**, AUPRC **0.3102**, Brier **0.0372**, LogLoss **0.1375**
- **XGBoost**: AUROC **0.8866**, AUPRC **0.3238**, Brier **0.0364**, LogLoss **0.1337**

### Restricted model (excludes DNR + palliative care)
- **Logistic Regression**: AUROC **0.8059**, AUPRC **0.2056**, Brier **0.0403**, LogLoss **0.1569**
- **XGBoost**: AUROC **0.8106**, AUPRC **0.2061**, Brier **0.0403**, LogLoss **0.1563**

**Interpretation:** Removing end-of-life indicators decreases performance for both models, but the restricted model still identifies clinically meaningful physiologic risk signals (e.g., acute respiratory failure, sepsis, acute kidney injury, urinary tract infection, age), supporting risk stratification beyond terminal-care coding.

---

## 🧠 SHAP Explainability

SHAP (SHapley Additive exPlanations) is used to interpret the XGBoost model:

- **SHAP summary (beeswarm)**: direction + distribution of feature effects across admissions
- **Mean(|SHAP|) bar plot**: global feature importance ranking
- **Restricted-model SHAP bar plot**: importance after excluding DNR/palliative care

These figures help translate model behavior into clinically interpretable signals.

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/ad-mortality-risk.git
cd ad-mortality-risk


### 2. Install Dependencies

Run the following inside your Python environment (e.g., Colab or virtualenv):

```bash
pip install -r requirements.txt
```

Or, manually install:

```bash
pip install pandas pyreadstat shap scikit-learn xgboost matplotlib openpyxl
```

### 3. Open Notebook

Launch the notebook in **Google Colab** or Jupyter:

```bash
jupyter notebook Identifying_Risk_Factors_for_In_Hospital_Mortality_in_Alzheimer’s_Disease.ipynb
```

Ensure your `.dta` and `ICD-10` description files are uploaded into your working directory (or mounted to Colab).

## 📁 File Structure

```
├── Identifying_Risk_Factors_for_In_Hospital_Mortality_in_Alzheimer’s_Disease.ipynb
├── section111validicd10-jan2025_0.xlsx        # ICD-10 code descriptions
├── NIS_2017_Core_data_alz_only.dta            # Cleaned Stata file (user-provided)
├── outputs/
│   ├── shap_summary_plot.png
│   ├── shap_bar_plot.png
│   └── model_performance_table.csv
```

> ⚠️ Due to HCUP data restrictions, the dataset is **not included** in this repo. You must obtain access to NIS 2017 data from [HCUP](https://www.hcup-us.ahrq.gov/nisoverview.jsp).

## 📈 Key Results

* **Logistic Regression AUROC**: 0.8789 (Full), 0.8075 (Sensitivity)
* **XGBoost AUROC**: 0.8866 (Full), 0.8950 (Sensitivity)
* Dominant predictors: acute respiratory failure, sepsis, DNR status, palliative care, aspiration pneumonia.
* SHAP plots provided intuitive interpretation of feature importance.

## 📉 Sensitivity Analysis

DNR and palliative care were excluded to simulate non-terminal case modeling. XGBoost maintained robust performance, while logistic regression's AUROC dropped, demonstrating the nonlinear model's ability to detect latent mortality risk.

## 🧠 SHAP Explainability

SHAP (SHapley Additive exPlanations) was used to visualize feature impact:

* `shap.summary_plot()`: Direction and distribution of top predictors
* `shap.bar_plot()`: Global importance ranking

These visualizations bridge statistical modeling with clinical interpretability.

## 📄 Citation

If you use this notebook or findings in your research, please cite:

> Alkam T, et al. Identifying Risk Factors for In-Hospital Mortality in Alzheimer’s Disease: A Dual Approach Using Regression and Explainable Machine Learning. *[Journal Name]*. 2025. (Under Review)

## 🧑‍⚕️ Author

**Dr. Tursun Alkam**
MD, PhD, MBA, MSAAI (c)

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Let me know if you’d like a `requirements.txt` generated or if you'd like a `LICENSE` or `GitHub Actions` CI setup.
