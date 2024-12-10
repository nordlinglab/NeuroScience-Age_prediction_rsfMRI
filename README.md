# Age Prediction Using Resting-State Functional MRI

This repository contains the code and resources associated with the research paper:

**"Age Prediction Using Resting-State Functional MRI"**  
*Jose Ramon Chang, Dr. Zai-Fu Yao, Dr. Shulan Hsieh, and Dr. Torbjörn E. M. Nordling*  
Published in **Neuroinformatics, 2024**.

---

## About the Paper

This study investigates brain aging using resting-state functional MRI (rsfMRI). By leveraging functional connectivity data and advanced feature selection algorithms, it predicts the chronological age of individuals. A unique outlier removal process identifies and analyzes subjects with abnormal brain aging, highlighting correlations with the Default Mode Network (DMN). The study achieves state-of-the-art accuracy with a leave-one-out mean absolute error (LOOMAE) of 2.48 years, providing insights into biomarkers for brain aging and abnormal brain health.  

The paper details the application of the Least Absolute Shrinkage and Selection Operator (LASSO) to identify key predictive correlations from rsfMRI data, demonstrating the importance of the Default Mode Network in understanding abnormal brain aging.  

The dataset comprises 176 healthy right-handed volunteers, aged 18-78 years, collected at the Mind Research Imaging Center (MRIC) at National Cheng Kung University (NCKU).

---

## Repository Structure

```plaintext
.
├── code/
│   ├── Algorithm_regressor_count_clean.m    # Algorithm for outlier selection and model optimization
│   └── experiments/                         # Additional scripts for exploratory and supplementary analysis
│       ├── [Experiment-related scripts...]
│       └── ...
├── data/
│   └── [Data used in analyses (restricted, placeholder for example data format)]
├── results/
│   └── [Generated outputs such as plots and metrics (example outputs included)]
└── README.md                                # Repository overview
```

## Usage

### Prerequisites
To run the code, ensure the following:
- MATLAB (R2020b or later recommended)
- Toolboxes:
  - Statistics and Machine Learning Toolbox
  - Parallel Computing Toolbox

### Running the Main Algorithm
1. Place the required data file (`FC_10mm_correlation_ltria_180702.mat`) in the `data/` directory.
2. Open the `Algorithm_regressor_count_clean.m` script in MATLAB.
3. Run the script to:
   - Execute the regressor count algorithm.
   - Identify outliers.
   - Evaluate and optimize predictive models.

### Generating Results
- **Output Files**: Results, such as figures and .mat files, are automatically saved in the `results/` directory.
- **Visualization**: Generated plots include:
  - Number of Regressors vs Leave-One-Out Mean Absolute Error (LOOMAE)
  - Number of Subjects vs Selected LOOMAE

### Experiments
The `experiments/` directory contains additional scripts for exploratory analysis and validation. These include:
- **Feature Reintegration**: Iteratively refine features using residual analysis to optimize regression performance​(feature_selection_resid…)​(residual_based_feature_…).
- **Residual-Based Feature Selection**: Leverage bootstrapping and LASSO regression to identify features that minimize prediction error while maintaining robustness against outliers​(residual_based_feature_…)​(Algo1_RegCount_contd).
- **Clustering-Based Feature Analysis**: Perform agglomerative clustering on selected features to uncover meaningful patterns and relationships between variables​(agglomerative_clusterin…).
- **Outlier Identification and Removal**: Identify and iteratively exclude subjects based on residuals and regression performance to improve model stability​(feature_selection_resid…)​(Algo1_RegCount_contd).

## Citation
```
@article{Chang2024AgePrediction,
  abstract = {The increasing lifespan and large individual differences in cognitive capability highlight the importance of comprehending the aging process of the brain. Contrary to visible signs of bodily ageing, like greying of hair and loss of muscle mass, the internal changes that occur within our brains remain less apparent until they impair function. Brain age, distinct from chronological age, reflects our brain's health status and may deviate from our actual chronological age. Notably, brain age has been associated with mortality and depression. The brain is plastic and can compensate even for severe structural damage by rewiring. Functional characterization offers insights that structural cannot provide. Contrary to the multitude of studies relying on structural magnetic resonance imaging (MRI), we utilize resting-state functional MRI (rsfMRI). We also address the issue of inclusion of subjects with abnormal brain ageing through outlier removal. In this study, we employ the Least Absolute Shrinkage and Selection Operator (LASSO) to identify the 39 most predictive correlations derived from the rsfMRI data. The data is from a cohort of 176 healthy right-handed volunteers, aged 18-78 years (95/81 male/female, mean age 48, SD 17) collected at the Mind Research Imaging Center at the National Cheng Kung University. We establish a normal reference model by excluding 68 outliers, which achieves a leave-one-out mean absolute error of 2.48 years. By asking which additional features that are needed to predict the chronological age of the outliers with a smaller error, we identify correlations predictive of abnormal aging. These are associated with the Default Mode Network (DMN). Our normal reference model has the lowest prediction error among published models evaluated on adult subjects of almost all ages and is thus a candidate for screening for abnormal brain aging that has not yet manifested in cognitive decline. This study advances our ability to predict brain aging and provides insights into potential biomarkers for assessing brain age, suggesting that the role of DMN in brain aging should be studied further.},
  annote = {We thank the Mind Research and Imaging Center (MRIC), supported by MOST, at NCKU for consultation and instru- ment availability.
  Funding This work was supported by the Ministry of Science and Technology (MOST) of Taiwan (grant number MOST 104-2410-H-006-021-MY2; MOST 106-2410-H-006-031-MY2; MOST 107-2634-F-006-009; MOST 111-2221-E-006-186), and by the National Science and Technology Council (NSTC) of Taiwan (grant number NSTC 112-2321-B-006-013; NSTC 112-2314-B-006-079).},
  author = {Chang, Jose Ramon and Yao, Zai-Fu and Hsieh, Shulan and Nordling, Torbj{\"{o}}rn E. M.},
  doi = {10.1007/s12021-024-09653-x},
  issn = {1559-0089},
  journal = {Neuroinformatics},
  keywords = {Abnormal brain aging,Brain aging,Default mode network,Feature selection,Least absolute shrinkage and selection operator,Resting-state functional MRI},
  month = {apr},
  number = {2},
  pages = {119--134},
  pmid = {38341830},
  publisher = {Springer},
  title = {{Age Prediction Using Resting-State Functional MRI.}},
  url = {https://rdcu.be/dyoIt https://link.springer.com/10.1007/s12021-024-09653-x http://www.ncbi.nlm.nih.gov/pubmed/38341830},
  volume = {22},
  year = {2024}
}
```
If you find this useful, kindly cite our paper. If you would like to collaborate on further research, kindly contact the corresponding author Dr. Nordling.
